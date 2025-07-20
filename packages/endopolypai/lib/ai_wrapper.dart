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

  // rust handle
  final YoloHandle _handle;

  EndoAI._(this._handle);

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
    List<String>? classLabels,
    double? confidenceThreshold,
    double? nmsThreshold,
  }) async {
    final byteData = await rootBundle.load(assetModelPath);
    final modelData = byteData.buffer.asUint8List();

    final handle = await yoloNewMem(
      mem: modelData,
      classLabels: classLabels ?? _defaultClassLabels,
      confidenceThreshold: confidenceThreshold ?? _defaultConfidenceThreshold,
      nmsThreshold: nmsThreshold ?? _defaultNmsThreshold,
    );

    return EndoAI._(handle);
  }

  // Создание обертки
  static Future<EndoAI> createFromMem({
    required Uint8List modelData,
    List<String>? classLabels,
    double? confidenceThreshold,
    double? nmsThreshold,
  }) async {
    final handle = await yoloNewMem(
      mem: modelData,
      classLabels: classLabels ?? _defaultClassLabels,
      confidenceThreshold: confidenceThreshold ?? _defaultConfidenceThreshold,
      nmsThreshold: nmsThreshold ?? _defaultNmsThreshold,
    );

    return EndoAI._(handle);
  }

  // Создание обертки по пути внешнего файла
  static Future<EndoAI> createFromFile({
    required String modelPath,
    List<String>? classLabels,
    double? confidenceThreshold,
    double? nmsThreshold,
  }) async {
    final handle = await yoloNew(
      modelPath: modelPath,
      classLabels: classLabels ?? _defaultClassLabels,
      confidenceThreshold: confidenceThreshold ?? _defaultConfidenceThreshold,
      nmsThreshold: nmsThreshold ?? _defaultNmsThreshold,
    );

    return EndoAI._(handle);
  }
}
