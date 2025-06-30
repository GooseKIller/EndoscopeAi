import 'package:endoscopy_ai/src/rust/api/yolo/flutter_yolo.dart';

class EndoAI {
  static final String _modelPath = '';
  static final List<String> _classLabels = ['Polyp', 'Not polyp'];
  static final double _confidenceThreshold = 0.5;
  static final double _nmsThreshold = 0.5;

  final YoloHandle _handle;

  EndoAI._(this._handle);

  static Future<EndoAI> create() async {
    final model = await yoloNew(
      modelPath: _modelPath,
      classLabels: _classLabels,
      confidenceThreshold: _confidenceThreshold,
      nmsThreshold: _nmsThreshold,
    );
    return Future.value(EndoAI._(model));
  }

  Future<List<FFIDetectionResult>> predict({
    required int width,
    required int height,
    required List<int> pixels,
  }) => yoloPredict(
    yoloHandle: _handle,
    width: width,
    height: height,
    pixels: pixels,
  );
}
