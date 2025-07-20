// ====================================================
//  Страница для вопроизведения зяписанного видео
//  Логика, содержащая логику, связанную с UI
// ====================================================
import 'package:endoscopy_ai/shared/widget/ai_annotation_overlay.dart';
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
      floatingActionButton: _createButtons(),
    );
  }

  // Создание ливетирующей кнопки для скриншотов
  Widget _createButtons() {
    return Builder(
        builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
              // вкл выкл ии
              FloatingActionButton(
                  heroTag: 'ai_btn',
                  tooltip: (_model.showAi) ? 'Выключить ИИ' : 'Включить ИИ',
                  onPressed: () => setState(() {
                        _model.showAi = !_model.showAi;
                        print('AI togge ${_model.showAi}');
                      }),
                  backgroundColor: const Color.fromARGB(255, 252, 232, 232),
                  child: Icon(
                    (_model.showAi)
                        ? Icons.tips_and_updates_rounded
                        : Icons.tips_and_updates_outlined,
                    color: const Color.fromARGB(255, 65, 63, 63),
                  )),
              // скриншотоделка
              FloatingActionButton(
                heroTag: 'scr_btn',
                //  label: Text('Make screenshot'),
                onPressed: _model.makeScreenshot,
                backgroundColor: const Color.fromARGB(255, 252, 232, 232),
                child: Icon(
                  Icons.camera_alt,
                  color: const Color.fromARGB(255, 65, 63, 63),
                ),
              )
            ]));
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
              aspectRatio: _model.controller.value.aspectRatio,
              child: Stack(children: [
                VideoPlayer(_model.controller),
                AiAnnotationOverlay(
                    videoSize: _model.videoSize,
                    foundFeatures: _model.deetectedPolyps,
                    shouldPaint: _model.showAi)
              ]))
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
