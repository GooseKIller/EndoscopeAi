// ====================================================
//  Wrapper для ИИ по поиску полипов
// ====================================================

import 'dart:typed_data';

import 'package:endoscopy_ai/rust/yolo/flutter_yolo.dart';
import 'package:flutter/services.dart' show rootBundle;

class EndoAI {
  static const String _modelPath = "assets/models/best_yolo.onnx";

  final YoloHandle _handle;

  EndoAI._(this._handle);

  Future predict(
          {required int width,
          required int height,
          required Uint8List pixels}) =>
      yoloPredict(
          yoloHandle: _handle, width: width, height: height, pixels: pixels);

  static Future<EndoAI> create() async {
    final byteData = await rootBundle.load(_modelPath);
    final modelData = byteData.buffer.asUint8List();
    final handle = await yoloNewMem(
        mem: modelData,
        classLabels: ['polyp', 'other'],
        confidenceThreshold: 0.25,
        nmsThreshold: 0.7);

    return EndoAI._(handle);
  }
}
