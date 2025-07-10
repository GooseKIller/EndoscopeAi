// ====================================================
//  Wrapper для ИИ по поиску полипов
// ====================================================

import 'dart:typed_data';

import 'package:endoscopy_ai/rust/yolo/flutter_yolo.dart';
import 'package:flutter/services.dart' show rootBundle;

class EndoAI {
  // путь к модели
  static const String _modelPath = "assets/models/best_yolo.onnx";

  // параметры моделт
  static const classLabels = ['polyp', 'other'];
  static const confidenceThreshold = 0.25;
  static const nmsThreshold = 0.7;

  // rust handle
  final YoloHandle _handle;

  EndoAI._(this._handle);

  // Поиск полипов на изображении
  // `width`, `height` - ширина и высота изображения
  // `pixels` - пиксели изображения
  Future<List<FFIDetectionResult>> predict(
          {required int width,
          required int height,
          required Uint8List pixels}) =>
      yoloPredict(
          yoloHandle: _handle, width: width, height: height, pixels: pixels);

  // Создание обертки в несоклько этапов:
  // 1) Загрузка модели в ram
  // 2) Передача байтов в rust
  // 3) Загрузка rust handle
  static Future<EndoAI> create() async {
    final byteData = await rootBundle.load(_modelPath);
    final modelData = byteData.buffer.asUint8List();

    final handle = await yoloNewMem(
        mem: modelData,
        classLabels: classLabels,
        confidenceThreshold: confidenceThreshold,
        nmsThreshold: nmsThreshold);

    return EndoAI._(handle);
  }
}
