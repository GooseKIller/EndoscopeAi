import 'package:flutter_test/flutter_test.dart';
import 'package:endoscopy_ai/shared/utility/strings.dart';

void main() {
  test('formatDuration without hours', () {
    final d = const Duration(minutes: 2, seconds: 5);
    expect(formatDuration(d), equals('02:05'));
  });

  test('formatDuration with hours', () {
    final d = const Duration(hours: 1, minutes: 2, seconds: 3);
    expect(formatDuration(d), equals('01:02:03'));
  });
}
