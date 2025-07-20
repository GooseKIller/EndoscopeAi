// ====================================================
//  Страница для вопроизведения зяписанного видео
//  Модель, содержащая дфнные и логику, не связанную с UI
// ====================================================
import 'dart:io';
import 'dart:ui';
import 'package:endoscopy_ai/features/ai/endo_ai.dart';
import 'package:endoscopy_ai/shared/utility/repeating_task_executer.dart';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:endoscopy_ai/features/patient/record_data.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';

// Модель содержащая, данные и логику
class FileVideoPlayerPageStateModel {
  final Duration _aiUpdateRate = Duration(milliseconds: 100);

  FileVideoPlayerPageStateModel(this.setState, this.recordData);

  final RecordData recordData;
  final Function setState; // callback для обновить сосотояние
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideoPlayerFuture;
  bool _isPlaying = false;
  bool showControls = false;
  bool _isValidFile = false;
  Duration currentPosition = Duration.zero;
  Duration totalDuration = Duration.zero;
  final List<ScreenshotPreviewModel> _shots = []; // список миниатюр
  late Directory _shotsDir; // директория …/screenshots

  List<FFIDetectionResult> _deetectedPolyps = [];
  List<FFIDetectionResult> get deetectedPolyps => _deetectedPolyps;

  bool get isPlaying => _isPlaying;
  bool get isValidFile => _isValidFile;
  List<ScreenshotPreviewModel> get shots => _shots;
  VideoPlayerController get controller => _controller;

  late final RepeatingTaskExecuter _aiExecture;
  bool get showAi => _aiExecture.isRunning;
  set showAi(bool value) => _aiExecture.isRunning = value;
  Size get videoSize => _controller.value.size;

  void initState() {
    _prepareDir();
    _aiExecture =
        RepeatingTaskExecuter(refreshTime: _aiUpdateRate, task: aiCapture);
    if (FilePicker.checkFile()) {
      _isValidFile = true;
      _controller = VideoPlayerController.file(
        File(FilePicker.filePath.toString()),
      );

      _initializeVideoPlayerFuture = _controller // инициализация проигрывателя
          .initialize()
          .then((_) {
        setState(() {
          totalDuration = _controller.value.duration;
        });
        _aiExecture.start();
      }).catchError((error) {
        debugPrint('Ошибка инициализации видео: $error');
      });
    }
  }

  // подготовка папки с данными
  Future<void> _prepareDir() async {
    final base = await getApplicationDocumentsDirectory(); // path_provider
    _shotsDir = Directory('${base.path}/screenshots');
    if (!await _shotsDir.exists()) {
      await _shotsDir.create(recursive: true);
    }
  }

  // установить время на видео
  void seekTo(Duration pos) {
    _controller.seekTo(pos);
    if (_isPlaying) {
      togglePlayPause(); // если было включено - поставим на паузу
    }
  }

  // сделать скриншот
  void makeScreenshot() async {
    final width = videoSize.width.toInt();
    final height = videoSize.height.toInt();
    final controllerPosition = _controller.value.position;

    // Определяем вывод скриншота
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.png';
    final filePath = '${_shotsDir.path}/$fileName';

    final screenshotVisual = ScreenshotPreviewModel(
      filePath,
      controllerPosition,
      state: ScreenshotPreviewState.pending,
    );

    _shots.add(screenshotVisual);

    try {
      // Запрос и чтение данных из видеоконтроллера
      final pixelData = await _controller.snapshot(
        width: width,
        height: height,
      );

      if (pixelData == null) {
        print('Ой, что-то пошло не так в сохранения снимка');
        return;
      }

      // Аллокация ресурсов для изображения по ее ширине и высоте
      final image = img.Image.fromBytes(
        width: width,
        height: height,
        bytes: pixelData.buffer,
        numChannels:
            4, // По https://pub.dev/documentation/fvp/latest/fvp/FVPControllerExtensions/snapshot.html :
      );

      // Дкодировать РГБ данные в пнг в изоляте из-за сложности процесса
      final pngBytes = await compute((im) => img.encodePng(im), image);

      // Сохранить
      final outFile = File(filePath);
      await outFile.writeAsBytes(pngBytes);

      // Обновить меню для скриншотов
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
    setState(() {
      _isPlaying = !_isPlaying;
      _isPlaying ? _controller.play() : _controller.pause();
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
