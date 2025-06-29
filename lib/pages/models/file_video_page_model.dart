// ====================================================
//  Страница для вопроизведения зяписанного видео
//  Модель, содержащая дфнные и логику, не связанную с UI
// ====================================================
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:fvp/fvp.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';
import 'package:endoscopy_ai/backend/python_service.dart';
import 'package:path/path.dart' as p;

// Модель содержащая, данные и логику
class FileVideoPlayerPageStateModel {
  FileVideoPlayerPageStateModel(this.setState);

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
  late Directory _recordingsDir;
  final PythonService _python = PythonService();

  bool get isPlaying => _isPlaying;
  bool get isValidFile => _isValidFile;
  List<ScreenshotPreviewModel> get shots => _shots;
  VideoPlayerController get controller => _controller;

  void initState() {
    _prepareDir();
    if (FilePicker.checkFile()) {
      _isValidFile = true;
      _controller = VideoPlayerController.file(
        File(FilePicker.filePath.toString()),
      );

      _initializeVideoPlayerFuture =
          _controller // инициализация проигрывателя
              .initialize()
              .then((_) {
                setState(() {
                  totalDuration = _controller.value.duration;
                });
              })
              .catchError((error) {
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
    _recordingsDir = Directory('${base.path}/recordings');
    if (!await _recordingsDir.exists()) {
        await _recordingsDir.create(recursive: true);
    }
  }

  // установить время на видео
  void seekTo(Duration pos) {
    // !!!!!!!!!!!!!! Проблема с неймингом
    _controller.seekTo(pos);
    if (_isPlaying) {
      togglePlayPause(); // если было включено - поставим на паузу
    }
  }

  // зделать скриншот
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

  Future<String> analyzeVideo() async {
    final input = FilePicker.filePath!;
    final out = p.join(p.dirname(input), 'annotated_${p.basename(input)}');
    await _python.processVideo(input, out);
    return out;
  }

  Future<String?> saveRecording() async {
    if (!FilePicker.checkFile()) return null;
    final src = FilePicker.filePath!;
    var dest = p.join(_recordingsDir.path, p.basename(src));
    if (await File(dest).exists()) {
      final name =
          '${DateTime.now().millisecondsSinceEpoch}_${p.basename(src)}';
      dest = p.join(_recordingsDir.path, name);
    }
    await File(src).copy(dest);
    return dest;
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
