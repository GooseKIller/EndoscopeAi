import 'package:flutter/material.dart';
import 'package:endoscopy_ai/pages/file_video/file_video_model.dart';
import 'package:endoscopy_ai/shared/widget/markers.dart';
import 'package:endoscopy_ai/shared/widget/markers_model.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';

class CustomSliderWithMarks extends StatefulWidget {
  final Duration currentPosition;
  final Duration totalDuration;
  final List<ScreenshotPreviewModel> shots;
  final FileVideoPlayerPageStateModel modelVideoPlayer;

  const CustomSliderWithMarks({
    super.key,
    required this.currentPosition,
    required this.totalDuration,
    required this.shots,
    required this.modelVideoPlayer,
  });

  @override
  _CustomSliderWithMarksState createState() =>
      _CustomSliderWithMarksState(modelVideoPlayer: modelVideoPlayer);
}

class _CustomSliderWithMarksState extends State<CustomSliderWithMarks> {
  final GlobalKey _sliderKey = GlobalKey();
  final FileVideoPlayerPageStateModel modelVideoPlayer;

  _CustomSliderWithMarksState({required this.modelVideoPlayer});

  @override
  Widget build(BuildContext context) {
    const marksRightPadding = 24.5;
    const marksLeftPadding = marksRightPadding - 0.75;
    MarkersModel marksModel = MarkersModel(
      marksLeftPadding,
      marksRightPadding,
      sliderKey: _sliderKey,
      modelVideoPlayer: modelVideoPlayer,
    );
    return Stack(
      alignment: Alignment.center,
      children: [
        // Слой со слайдером
        getSlider(),
        // Слой с насечками (обрабатывает клики)
        Positioned(
          left: marksLeftPadding,
          right: marksRightPadding,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: marksModel.dragSlider,
            onTapDown: marksModel.seekToMarker,
            child: CustomPaint(
              size: Size(double.infinity, 60),
              painter: MarksPainter(
                shots: modelVideoPlayer.shots,
                totalDuration: modelVideoPlayer.totalDuration,
                currentPosition: modelVideoPlayer.currentPosition,
              ),
            ),
          ),
        ),
      ],
    );
  }

    StatefulWidget getSlider() {
    return Slider(
      key: _sliderKey,
      activeColor: const Color.fromARGB(255, 167, 38, 29),
      inactiveColor: Colors.grey[600],
      value: modelVideoPlayer.currentPosition.inMilliseconds.toDouble(),
      min: 0,
      max: modelVideoPlayer.totalDuration.inMilliseconds.toDouble(),
      onChanged: (value) {
        setState(() {
          modelVideoPlayer.currentPosition = Duration(
            milliseconds: value.toInt(),
          );
          modelVideoPlayer.controller!.seekTo(modelVideoPlayer.currentPosition);
        });
      },
      onChangeStart: (_) {
        if (!modelVideoPlayer.isPlaying) modelVideoPlayer.controller!.pause();
      },
      onChangeEnd: (_) {
        if (modelVideoPlayer.isPlaying) modelVideoPlayer.controller!.play();
      },
    );
  }
}
