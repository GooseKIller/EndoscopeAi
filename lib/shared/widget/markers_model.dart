import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:endoscopy_ai/pages/file_video/file_video_model.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';

class MarkersModel {
  final GlobalKey sliderKey;
  final FileVideoPlayerPageStateModel modelVideoPlayer;
  final double marksLeftPadding;
  final double marksRightPadding;

  const MarkersModel(
    this.marksLeftPadding,
    this.marksRightPadding, {
    required this.sliderKey,
    required this.modelVideoPlayer,
  });

  void dragSlider(DragUpdateDetails details) {
    final RenderBox slider =
        sliderKey.currentContext!.findRenderObject() as RenderBox;
    final localOffset = slider.globalToLocal(details.globalPosition);
    final sliderWidth =
        slider.size.width - marksLeftPadding - marksRightPadding;
    final totalMs = modelVideoPlayer.totalDuration.inMilliseconds.toDouble();
    final mousePosition = localOffset.dx - marksLeftPadding;
    final tappedMs = clampDouble(
      mousePosition * totalMs / sliderWidth,
      0,
      totalMs,
    );

    modelVideoPlayer.currentPosition = Duration(milliseconds: tappedMs.toInt());
    modelVideoPlayer.controller!.seekTo(modelVideoPlayer.currentPosition);
  }

  void seekToMarker(TapDownDetails details) {
    final RenderBox slider =
        sliderKey.currentContext!.findRenderObject() as RenderBox;
    final localOffset =
        slider.globalToLocal(details.globalPosition).dx - marksLeftPadding;
    final sliderWidth =
        slider.size.width - marksLeftPadding - marksRightPadding;
    final totalMs = modelVideoPlayer.totalDuration.inMilliseconds.toDouble();
    final tappedMs = (localOffset / sliderWidth) * totalMs;

    // Ищем ближайшую насечку в пределах 10 пикселей
    const pixelThreshold = 10.0;
    final msThreshold = (pixelThreshold / sliderWidth) * totalMs;

    ScreenshotPreviewModel? closestShot;
    double minDiff = double.infinity;

    for (var shot in modelVideoPlayer.shots) {
      final shotMs = shot.position.inMilliseconds.toDouble();
      final diff = (shotMs - tappedMs).abs();
      if (diff < minDiff && diff < msThreshold) {
        minDiff = diff;
        closestShot = shot;
      }
    }

    if (closestShot != null) {
      modelVideoPlayer.currentPosition = closestShot.position;
      modelVideoPlayer.seekTo(modelVideoPlayer.currentPosition);
    } else {
      // Если клик не на насечке, передаем управление слайдеру
      modelVideoPlayer.currentPosition = Duration(
        milliseconds: tappedMs.toInt(),
      );
      modelVideoPlayer.controller!.seekTo(modelVideoPlayer.currentPosition);
    }
  }
}
