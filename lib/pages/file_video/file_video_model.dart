// ====================================================
//  Страница для вопроизведения зяписанного видео
//  Модель, содержащая дфнные и логику, не связанную с UI
// ====================================================
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:fvp/fvp.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';


// Модель содержащая, данные и логику
class FileVideoPlayerPageStateModel {
  final String? _file;

  FileVideoPlayerPageStateModel(
      this.setState, this._file);

  //final RecordData recordData;
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

  bool get isPlaying => _isPlaying;
  bool get isValidFile => _isValidFile;
  List<ScreenshotPreviewModel> get shots => _shots;
  VideoPlayerController get controller => _controller;

  void initState() {
    _prepareDir();
    if (_file != null) {
      _isValidFile = true;
      _controller = VideoPlayerController.file(
        File(_file),
      );

      _initializeVideoPlayerFuture = _controller // инициализация проигрывателя
          .initialize()
          .then((_) {
        setState(() {
          totalDuration = _controller.value.duration;
        });
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
    final width = _controller.value.size.width.toInt();
    final height = _controller.value.size.height.toInt();
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
    _controller.dispose();
  }
}
