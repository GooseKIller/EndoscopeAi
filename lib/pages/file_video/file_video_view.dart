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

// ====================================================
//  Логика, содержащая логику, связанную с UI
// ====================================================
class FileVideoPlayerPageStateView {
  final Function setState; // callback для обновления состояния
  final FileVideoPlayerPageStateModel _model;

  FileVideoPlayerPageStateView(this.setState, this._model);

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
            /// ВИДЕО
            Expanded(child: _buildVideo(context)),

            /// ЛЕНТА СКРИНШОТОВ
            if (_model.isInitialized)
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
      onPressed: _model.isInitialized ? _model.makeScreenshot : null,
      backgroundColor: const Color.fromARGB(255, 252, 232, 232),
      child: const Icon(
        Icons.camera_alt,
        color: Color.fromARGB(255, 65, 63, 63),
      ),
    );
  }

  // создание жестового распознавания
  Widget _createGestureRecognition(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_model.isInitialized) {
          setState(() {
            _model.showControls = !_model.showControls;
          });
        }
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_model.isInitialized) 
            AspectRatio(
              aspectRatio: _model.controller!.value.aspectRatio,
              child: VideoPlayer(_model.controller!),
            )
          else
            const Center(child: CircularProgressIndicator()),
          if (_model.showControls && _model.isInitialized)
            PlayPauseButton(model: _model),
          if (_model.showControls && _model.isInitialized)
            CustomSlider(modelVideoPlayer: _model),
        ],
      ),
    );
  }

  // создает штуку, где пишутся ошибки
  Widget _createErrorScaffold() {
    return Scaffold(
      appBar: AppBar(title: const Text('Ошибка')),
      body: const Center(child: Text('Не удалось открыть файл')),
    );
  }
}
