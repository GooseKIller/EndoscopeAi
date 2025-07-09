import 'dart:typed_data';
import 'dart:ui';

import 'package:endoscopy_ai/features/patient/record_data.dart';
import 'package:mockito/mockito.dart';
import 'package:video_player/video_player.dart';

class MockVideoPlayerController extends Mock implements VideoPlayerController {
  final VideoPlayerValue _value;

  MockVideoPlayerController({
    Duration duration = const Duration(seconds: 60),
    Size size = const Size(1920, 1080),
    bool isInitialized = true,
  }) : _value = VideoPlayerValue(
          duration: duration,
          size: size,
          isInitialized: isInitialized,
        );

  @override
  VideoPlayerValue get value => _value;

  // Remove all real implementations - let Mockito handle everything
  @override
  Future<void> initialize() => super.noSuchMethod(
        Invocation.method(#initialize, []),
        returnValue: Future.value(),
      );

  @override
  Future<void> seekTo(Duration position) => super.noSuchMethod(
        Invocation.method(#seekTo, [position]),
        returnValue: Future.value(),
      );

  @override
  Future<void> dispose() => super.noSuchMethod(
        Invocation.method(#dispose, []),
        returnValue: Future.value(),
      );

  @override
  Future<void> play() => super.noSuchMethod(
        Invocation.method(#play, []),
        returnValue: Future.value(),
      );

  @override
  Future<void> pause() => super.noSuchMethod(
        Invocation.method(#pause, []),
        returnValue: Future.value(),
      );

  @override
  Future<Uint8List?> snapshot() => super.noSuchMethod(
        Invocation.method(#snapshot, []),
        returnValue: Future.value(Uint8List(0)),
      );
}

class MockRecordData extends Mock implements RecordData {
  @override
  int get id => 1;

  @override
  String get filePath => 'test_video.mp4';

  @override
  DateTime get createdAt => DateTime.now();

  // Add any other required overrides from your RecordData class
  @override
  bool get isProcessed => false; // Example additional field

  @override
  String? get diagnosis => null; // Example additional field
}

class FakeFilePicker {
  static String? filePath = 'test_video.mp4';

  static Future<String?> pickVideo() async {
    return filePath;
  }

  static Future<bool> checkFileExists(String? path) async {
    return path != null;
  }
}
