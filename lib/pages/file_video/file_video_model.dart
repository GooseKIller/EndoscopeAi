import 'dart:io';

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

  bool get isPlaying => _isPlaying;
  bool get isValidFile => _isValidFile;
  bool get isInitialized => _isInitialized;
  List<ScreenshotPreviewModel> get shots => _shots;

  // Return nullable controller
  VideoPlayerController? get controller => _controller;

  // Public future for initialization tracking
  Future<void>? initializationFuture;

  FileVideoPlayerPageStateModel(this.setState, this._playerData);

  void initState() {
    _isValidFile = true;

    // Save this future to track initialization
    initializationFuture = _initializeController();

    loadScreenshots();
  }

  void loadScreenshots() {
    StorageSystem.loadScreenshots(_playerData.recordEntry);

    _shots = _playerData.recordEntry.screenshots
        .map((scr) => ScreenshotPreviewModel(scr.imagePath, scr.time))
        .toList();
  }

  Future<void> _initializeController() async {
    try {
      _controller = VideoPlayerController.file(File(_playerData.filePath));

      await _controller!.initialize();

      // 5. Setup screenshot directory
      _shotsDir = Directory(_playerData.screenshotPath);

      // 6. Update UI and mark as initialized
      setState(() {
        totalDuration = _controller!.value.duration;
        _isInitialized = true;
      });
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

    final width = _controller!.value.size.width.toInt();
    final height = _controller!.value.size.height.toInt();
    final controllerPosition = _controller!.value.position;

    final filePath = StorageSystem.saveScreenshot(
        _playerData.recordEntry, controllerPosition);

    final screenshotVisual = ScreenshotPreviewModel(
      filePath,
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

      final outFile = File(filePath);
      await outFile.writeAsBytes(pngBytes);

      setState(() {
        screenshotVisual.state = ScreenshotPreviewState.good;
      });
      print("Сохранено $filePath");
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
    _controller?.dispose();
  }
}
