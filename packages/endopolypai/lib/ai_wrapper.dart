// ====================================================
//  Wrapper для ИИ по поиску полипов
// ====================================================

import 'package:flutter/services.dart' show rootBundle;
import 'dart:typed_data';
import 'rust/yolo/flutter_yolo.dart';

class EndoAI {
  // параметры моделт
  static const _defaultClassLabels = ['polyp', 'other'];
  static const _defaultConfidenceThreshold = 0.25;
  static const _defaultNmsThreshold = 0.7;

  late final List<String> classLabels;
  late final double confidenceThreshhold;
  late final double nmsThreshold;

  // rust handle
  final YoloHandle _handle;

  EndoAI._(
    this._handle, {
    List<String>? classLabels,
    double? confidenceThreshhold,
    double? nmsThreshold,
  }) {
    this.classLabels = classLabels ?? _defaultClassLabels;
    this.confidenceThreshhold =
        confidenceThreshhold ?? _defaultConfidenceThreshold;
    this.nmsThreshold = nmsThreshold ?? _defaultNmsThreshold;
  }

  // Поиск полипов на изображении
  // `width`, `height` - ширина и высота изображения
  // `pixels` - пиксели изображения
  Future<List<FFIDetectionResult>> predict({
    required int width,
    required int height,
    required Uint8List pixels,
  }) => yoloPredict(
    yoloHandle: _handle,
    width: width,
    height: height,
    pixels: pixels,
  );

  // Создание обертки в несоклько этапов:
  // 1) Загрузка модели в ram
  // 2) Передача байтов в rust
  // 3) Загрузка rust handle
  static Future<EndoAI> createFromAsset({
    required String assetModelPath,
  }) async {
    final byteData = await rootBundle.load(assetModelPath);
    final modelData = byteData.buffer.asUint8List();

    final handle = await yoloNewMem(
      mem: modelData,
      classLabels: classLabels,
      confidenceThreshold: confidenceThreshold,
      nmsThreshold: nmsThreshold,
    );

    return EndoAI._(handle);
  }

  // Создание обертки по пути внешнего файла
  static Future<EndoAI> createFromFile({required String modelPath}) async {
    final handle = await yoloNew(
      modelPath: modelPath,
      classLabels: classLabels,
      confidenceThreshold: confidenceThreshold,
      nmsThreshold: nmsThreshold,
    );

    return EndoAI._(handle);
  }
}
