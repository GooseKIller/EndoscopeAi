import 'package:endopolypai/endopolypai.dart' as epi;
import 'package:endopolypai/rust/yolo/flutter_yolo.dart';
import 'package:flutter/foundation.dart';
export 'package:endopolypai/endopolypai.dart' show FFIDetectionResult;

class AiError extends ErrorDescription {
  AiError(String message) : super('AI ERROR: $message');
}

class EndoAi {
  static EndoAi? _instance = null;
  static const String _modelPath = 'assets/models/best_yolo.onnx';

  final epi.EndoAI _model;

  EndoAi._(this._model);

  static Future<List<epi.FFIDetectionResult>> predict({
    required int width,
    required int height,
    required Uint8List pixels,
  }) =>
      _instance!._model.predict(width: width, height: height, pixels: pixels);

  static Future<void> initialize() async {
    if (_instance != null) throw AiError('EndoAi is already inialized');
    print('Initializing endopolypai backend...');
    await epi.RustLib.init();
    print('Succesfully initialized endopolypai backend!');
    print('Initializing endopolypai model...');
    final model = await epi.EndoAI.createFromAsset(
        assetModelPath: _modelPath, classLabels: ["Полип", "Другое"]);
    print('Succesfully initialized endopolypai model!');

    _instance = EndoAi._(model);
  }
}
