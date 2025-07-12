import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:endoscopy_ai/pages/file_video/file_video_model.dart';
import '../mocks/video_player_mock.dart';

void main() {
  late FileVideoPlayerPageStateModel model;
  late MockVideoPlayerController mockController;
  late MockRecordData mockRecordData;
  bool stateUpdated = false;

  setUp(() {
    mockController = MockVideoPlayerController();
    mockRecordData = MockRecordData();
    
    model = FileVideoPlayerPageStateModel(
      (_) => stateUpdated = true,
      mockRecordData
    );

    // Proper stubbing
    when(mockController.initialize()).thenAnswer((_) async {});
    when(mockController.play()).thenAnswer((_) async {});
    when(mockController.pause()).thenAnswer((_) async {});
    // when(mockController.seekTo(argThat(isA<Duration>()))).thenAnswer((_) async {});
    when(mockController.dispose()).thenAnswer((_) async {});
  });

  test('Initialization with valid file', () async {
    FakeFilePicker.filePath = 'test_video.mp4';
    model.initState();
    await model.initializeFuture;
    expect(model.isValidFile, true);
  });

  test('Play/pause functionality', () async {
    model.controllerForTest = mockController;
    
    model.togglePlayPause();
    verify(mockController.play()).called(1);
    expect(model.isPlaying, true);
    
    model.togglePlayPause();
    verify(mockController.pause()).called(1);
    expect(model.isPlaying, false);
  });

  test('Seek functionality', () async {
    model.controllerForTest = mockController;
    const testPosition = Duration(seconds: 30);
    
    model.seekTo(testPosition);
    verify(mockController.seekTo(testPosition)).called(1);
  });

  test('Dispose releases resources', () async {
    model.controllerForTest = mockController;
    model.dispose();
    verify(mockController.dispose()).called(1);
  });
}