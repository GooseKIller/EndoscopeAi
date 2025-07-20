import 'package:flutter/material.dart';
import 'package:endoscopy_ai/pages/file_video/file_video_model.dart';
import 'package:endoscopy_ai/shared/widget/slider.dart';
import 'package:endoscopy_ai/shared/utility/strings.dart';

class CustomSlider extends StatelessWidget {
  final FileVideoPlayerPageStateModel modelVideoPlayer;

  const CustomSlider({required this.modelVideoPlayer});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 2,
      left: 3,
      right: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                const Color.fromARGB(255, 0, 0, 0).withOpacity(0.80),
                const Color.fromARGB(0, 61, 60, 60),
              ],
            ),
          ),
          child: Row(
            children: [
              Padding(padding: EdgeInsetsGeometry.only(left: 5),
              child: Text(
                formatDuration(modelVideoPlayer.currentPosition),
                style: TextStyle(
                  color: const Color.fromARGB(255, 236, 232, 232),
                ),
              ),),
              Expanded(
                child: getSlider()),
              Padding(padding: EdgeInsetsGeometry.only(right: 5),
              child: Text(
                formatDuration(modelVideoPlayer.totalDuration),
                style: TextStyle(
                  color: const Color.fromARGB(255, 221, 215, 215),
                ),
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StatefulWidget getSlider() {
    return CustomSliderWithMarks(
      currentPosition: modelVideoPlayer.currentPosition,
      totalDuration: modelVideoPlayer.totalDuration,
      shots: modelVideoPlayer.shots,
      modelVideoPlayer: modelVideoPlayer,
    );
  }
}
