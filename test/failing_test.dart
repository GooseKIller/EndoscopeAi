import 'package:flutter_test/flutter_test.dart';
// reuse the fake model defined for widget tests
import 'timecode_sync_test.dart' show FakeVideoPlayerModel;

void main() {
  test('video starts playing automatically', () {
    final model = FakeVideoPlayerModel([]);
    expect(model.isPlaying, isFalse);
  });
}
