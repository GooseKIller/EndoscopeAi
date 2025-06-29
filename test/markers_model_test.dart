import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endoscopy_ai/shared/widget/markers_model.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';

// Reuse the fake video model from the widget test file
import 'timecode_sync_test.dart' show FakeVideoPlayerModel;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('seekToMarker selects nearest shot', (tester) async {
    final key = GlobalKey();
    final shots = [
      ScreenshotPreviewModel('one', const Duration(seconds: 2)),
      ScreenshotPreviewModel('two', const Duration(seconds: 8)),
    ];
    final model = FakeVideoPlayerModel(shots)
      ..totalDuration = const Duration(seconds: 10);

    final markers = MarkersModel(
      0,
      0,
      sliderKey: key,
      modelVideoPlayer: model,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(width: 100, height: 20, key: key),
      ),
    );

    final box = key.currentContext!.findRenderObject() as RenderBox;
    final sliderWidth = box.size.width;
    final totalMs = model.totalDuration.inMilliseconds.toDouble();
    // Tap very close to the 8-second marker (within threshold)
    final tapX = (Duration(seconds: 8, milliseconds: 50).inMilliseconds / totalMs) * sliderWidth;
    final global = box.localToGlobal(Offset(tapX, 1));

    markers.seekToMarker(TapDownDetails(globalPosition: global));

    expect(model.currentPosition, equals(shots[1].position));
    expect(model.controllerFake.lastPosition, equals(shots[1].position));
  });
}
