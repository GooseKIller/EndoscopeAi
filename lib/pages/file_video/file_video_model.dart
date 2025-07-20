import 'dart:io';
import 'dart:ui';
import 'package:endoscopy_ai/features/ai/endo_ai.dart';
import 'package:endoscopy_ai/shared/utility/repeating_task_executer.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:endoscopy_ai/features/video_player/player_data.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:endoscopy_ai/shared/utility/create_folder.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart';
import 'package:image/image.dart' as img;
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;

// Модель содержащая, данные и логику
class FileVideoPlayerPageStateModel {
  final Duration _aiUpdateRate = Duration(milliseconds: 100);

  FileVideoPlayerPageStateModel(this.setState, this.recordData);
  final PlayerData _playerData;
  final Function setState;

  // Make controller nullable
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool showControls = false;
  bool _isValidFile = false;
  bool _isInitialized = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  List<ScreenshotPreviewModel> _shots = []; // список миниатюр
  Directory? _shotsDir; // директория …/screenshots

  List<FFIDetectionResult> _deetectedPolyps = [];
  List<FFIDetectionResult> get deetectedPolyps => _deetectedPolyps;

  bool get isPlaying => _isPlaying;
  bool get isValidFile => _isValidFile;
  bool get isInitialized => _isInitialized;
  List<ScreenshotPreviewModel> get shots => _shots;

  // Return nullable controller
  VideoPlayerController? get controller => _controller;

  // Public future for initialization tracking
  Future<void>? initializationFuture;

  FileVideoPlayerPageStateModel(this.setState, this._playerData);

  late final RepeatingTaskExecuter _aiExecture;
  bool get showAi => _aiExecture.isRunning;
  set showAi(bool value) => _aiExecture.isRunning = value;
  Size get videoSize => _controller.value.size;

  void initState() {
    _isValidFile = true;

    // Save this future to track initialization
    initializationFuture = _initializeController();

    loadScreenshots();
  }

  void loadScreenshots() {
    StorageSystem.loadScreenshots(_playerData.recordEntry);

    _shots = _playerData.recordEntry.screenshots
        .map((scr) => ScreenshotPreviewModel(scr, scr.time))
        .toList();
  }

  Future<void> _initializeController() async {
    try {
      _controller = VideoPlayerController.file(File(_playerData.filePath));

      await _controller!.initialize();

      _isPlaying = true;
      _controller?.play();

      // 5. Setup screenshot directory
      _shotsDir = Directory(_playerData.screenshotPath);

      // 6. Update UI and mark as initialized
      setState(() {
        totalDuration = _controller!.value.duration;
        _isInitialized = true;
      });
      _aiExecture.start();
    } catch (e) {
      debugPrint('Ошибка инициализации видео: $e');
      setState(() {
        _isValidFile = false;
      });
    }
  }

  // установить время на видео
  void seekTo(Duration pos) {
    if (!_isInitialized || _controller == null) return;

    _controller!.seekTo(pos);
    if (_isPlaying) {
      togglePlayPause();
    }
  }

  // сделать скриншот
  void makeScreenshot() async {
    // Ensure controller is initialized and ready
    if (!_isInitialized || _controller == null || _shotsDir == null) return;

    final width = videoSize.width.toInt();
    final height = videoSize.height.toInt();
    final controllerPosition = _controller!.value.position;


    final screenshotData = StorageSystem.saveScreenshot(
        _playerData.recordEntry, controllerPosition);

    final screenshotVisual = ScreenshotPreviewModel(
      screenshotData,
      controllerPosition,
      state: ScreenshotPreviewState.pending,
    );

    _shots.add(screenshotVisual);

    try {
      final pixelData = await _controller!.snapshot(
        width: width,
        height: height,
      );

      if (pixelData == null) {
        print('Ой, что-то пошло не так в сохранения снимка');
        return;
      }

      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixelData.buffer,
        numChannels: 4,
      );

      final pngBytes = await compute((im) => img.encodePng(im), image);

      final outFile = File(screenshotData.imagePath);
      await outFile.writeAsBytes(pngBytes);

      setState(() {
        screenshotVisual.state = ScreenshotPreviewState.good;
      });
      print("Сохранено $screenshotData");
    } catch (error) {
      setState(() {
        screenshotVisual.state = ScreenshotPreviewState.error;
      });
      print('ОШИБКА СОЗАДНИЯ СКРИНШОТА: $error');
    }
  }

  // смена состояния проигрывания
  void togglePlayPause() {
    if (!_isInitialized || _controller == null) return;

    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller!.play() : _controller!.pause();
    });
  }

  // освобождение ресурсов
  void dispose() {
    _aiExecture.dispose();
    _controller.dispose();
  }

  @visibleForTesting
  Future<void> get initializeFuture =>
      _initializeVideoPlayerFuture ?? Future.value();

  @visibleForTesting
  set controllerForTest(VideoPlayerController controller) {
    _controller = controller;
    _initializeVideoPlayerFuture = controller.initialize().then((_) {
      if (controller.value.isInitialized) {
        currentPosition = controller.value.position;
        totalDuration = controller.value.duration;
      }
    });
  }

  @visibleForTesting
  static Future<void> prepareTestDir(Directory dir) async {
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> aiCapture() async {
    if (!showAi) return;
    final width = videoSize.width.toInt();
    final height = videoSize.height.toInt();
    final pixelData = await _controller.snapshot(
      width: width,
      height: height,
    );

    List<FFIDetectionResult>? data;
    if (_aiExecture.isRunning) {
      data = await EndoAi.predict(
          width: width, height: height, pixels: pixelData!);
    }
    if (_aiExecture.isRunning && data != null) {
      setState(() {
        _deetectedPolyps = data!;
      });
    }

    print('FOUND ${data?.length ?? 0}');
    for (var x in data ?? []) {
      print(
          '\t\t${x.label}(${(x.confidence * 100).toInt()}%): (${x.x1}, ${x.y1})->(${x.x2}, ${x.y2})');
    }
  }
}
