import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:endoscopy_ai/pages/recordings/recordings_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Recordings Page Tests', () {
    // Мокируем SharedPreferences
    late SharedPreferences prefs;

    setUp(() async {
      // Подготовка тестовых данных
      SharedPreferences.setMockInitialValues({
        'recordings': [
          '/path/to/video1.mp4|2023-10-01T12:00:00.000Z|video1.mp4',
          '/path/to/video2.mp4|2023-10-02T12:00:00.000Z|video2.mp4',
        ],
      });
      prefs = await SharedPreferences.getInstance();
    });

    testWidgets('Displays loaded recordings', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(home: RecordingsPage()));

      // Ждем загрузки данных
      await tester.pumpAndSettle();

      // Проверяем, что записи отображаются
      expect(find.text('video1.mp4'), findsOneWidget);
      expect(find.text('video2.mp4'), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsNWidgets(2));
    });
  });
}