import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endoscopy_ai/shared/widget/markers_model.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';
import 'package:endoscopy_ai/pages/models/file_video_page_model.dart';
import 'package:video_player/video_player.dart';

class FakeVideoPlayerController extends VideoPlayerController {
  FakeVideoPlayerController() : super.network('');

  Duration? lastPosition;

  @override
  Future<void> seekTo(Duration position) async {
    lastPosition = position;
  }

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}
}

class FakeVideoPlayerModel extends FileVideoPlayerPageStateModel {
  FakeVideoPlayerModel(this.shotsList)
    : controllerFake = FakeVideoPlayerController(),
      super(() {});

  final FakeVideoPlayerController controllerFake;
  final List<ScreenshotPreviewModel> shotsList;

  @override
  VideoPlayerController get controller => controllerFake;

  @override
  List<ScreenshotPreviewModel> get shots => shotsList;

  @override
  void seekTo(Duration pos) {
    // Override to use our fake controller directly and avoid _controller access
    controllerFake.seekTo(pos);
    currentPosition = pos;
    if (isPlaying) {
      togglePlayPause(); // if was playing - pause it
    }
  }

  @override
  Future<void> makeScreenshot() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('slider and screenshot synced', (tester) async {
    final key = GlobalKey();
    final shot = ScreenshotPreviewModel('path', const Duration(seconds: 5));
    final model = FakeVideoPlayerModel([shot])
      ..totalDuration = const Duration(seconds: 10);

    final markers = MarkersModel(0, 0, sliderKey: key, modelVideoPlayer: model);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 100, height: 20, key: key),
      ),
    );

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final sliderWidth = box.size.width;
    final totalMs = model.totalDuration.inMilliseconds.toDouble();
    final tapX = (shot.position.inMilliseconds / totalMs) * sliderWidth;
    final global = box.localToGlobal(Offset(tapX, 1));

    markers.seekToMarker(TapDownDetails(globalPosition: global));

    expect(model.currentPosition, equals(shot.position));
    expect(model.controllerFake.lastPosition, equals(shot.position));
  });
}
