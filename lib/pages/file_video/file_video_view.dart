// ====================================================
//  Страница для вопроизведения зяписанного видео
//  Логика, содержащая логику, связанную с UI
// ====================================================
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:endoscopy_ai/pages/file_video/file_video_model.dart';
import 'package:endoscopy_ai/shared/widget/custom_slider.dart';
import 'package:endoscopy_ai/shared/widget/play_pause_button.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_feed.dart';
import 'package:endoscopy_ai/shared/widget/spacing.dart';

//  Логика, содержащая логику, связанную с UI
class FileVidePlayerPageStateView {
  final Function setState; // callback для обновления состояния
  final FileVideoPlayerPageStateModel _model;

  FileVidePlayerPageStateView(this.setState, this._model);

  Widget _buildVideo(BuildContext context) =>
      _createGestureRecognition(context);

  // сборка пользовательского интерфейса
  Widget build(BuildContext context) {
    if (!_model.isValidFile) return _createErrorScaffold();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Видеоплеер'),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(5),
        child: Row(
          children: [
            IconButton(
                onPressed: _model.captureShit,
                icon: Icon(Icons.breakfast_dining)),

            /// ВИДЕО
            _buildVideo(context),

            createIndention(5, 5),

            /// ЛЕНТА СКРИНШОТОВ
            ScreenshotFeed(
              onFetchScreenshots: () => _model.shots,
              onTap: _model.seekTo,
            ),
          ],
        ),
      ),
      floatingActionButton: _createScreenshotButton(),
    );
  }

  // Создание ливетирующей кнопки для скриншотов
  Widget _createScreenshotButton() {
    return FloatingActionButton(
      onPressed: _model.makeScreenshot,
      backgroundColor: const Color.fromARGB(255, 252, 232, 232),
      child: Icon(
        Icons.camera_alt,
        color: const Color.fromARGB(255, 65, 63, 63),
      ),
    );
  }

  // создание.... эээ.. чего это....
  Widget _createGestureRecognition(context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _model.showControls = !_model.showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _model.controller.value.aspectRatio,
            child: VideoPlayer(_model.controller),
          ),
          if (_model.showControls) PlayPauseButton(model: _model),
          if (_model.showControls) CustomSlider(modelVideoPlayer: _model),
        ],
      ),
    );
  }

  // открывает окно с ошибкой
  Widget _createErrorMessageBox(AsyncSnapshot snapshot) {
    return Center(child: Text('Ошибка загрузки видео: ${snapshot.error}'));
  }

  // создает штуку, где пишутся ошибки
  Widget _createErrorScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: const Center(child: Text('Не удалось открыть файл')),
    );
  }
}
