// ====================================================
//  Обертка с настройками вокург ИИ пакета
// ====================================================

import 'package:endopolypai/endopolypai.dart' as epi;
import 'package:endopolypai/rust/yolo/flutter_yolo.dart';
import 'package:flutter/foundation.dart';
export 'package:endopolypai/endopolypai.dart' show FFIDetectionResult;

// Ошибка, выбраемая ИИ
class AiError extends ErrorDescription {
  AiError(String message) : super('AI ERROR: $message');
}

class EndoAi {
  static EndoAi? _instance = null;
  // путь к модели в ассетах
  static const String _modelPath = 'assets/models/best_optimized.onnx';

  final epi.EndoAI _model;

  EndoAi._(this._model);

  static bool get inialized => _instance != null;

  // Ищет полипы в изображении, где `width`, `height` - высота и ширена изображения
  static Future<List<epi.FFIDetectionResult>> predict({
    required int width,
    required int height,
    required Uint8List pixels,
  }) =>
      _instance!._model.predict(width: width, height: height, pixels: pixels);

  // инициализиайия модели, может быть долго
  static Future<void> initialize(void Function(String s) stageCallback) async {
    if (_instance != null) throw AiError('EndoAi is already inialized');
    stageCallback('Инициализация системы ИИ... (может занять пару минут)');
    await epi.RustLib.init();
    stageCallback('Загрузка ИИ модели... (может занять пару минут)');
    final model = await epi.EndoAI.createFromAsset(
        assetModelPath: _modelPath, classLabels: ["Полип", "Другое"]);
    stageCallback('Модель загружена!');

    _instance = EndoAi._(model);
  }
}
