import 'package:flutter/material.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';

class MarksPainter extends CustomPainter {
  final List<ScreenshotPreviewModel> shots;
  final Duration totalDuration;
  final Duration currentPosition;

  MarksPainter({
    required this.shots,
    required this.totalDuration,
    required this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color.fromARGB(255, 224, 221, 221)
      ..strokeWidth = 5;

    final activePaint = Paint()
      ..color = const Color.fromARGB(255, 219, 38, 25)
      ..strokeWidth = 5;

    for (var shot in shots) {
      final positionMs = shot.position.inMilliseconds.toDouble();
      final totalMs = totalDuration.inMilliseconds.toDouble();
      final x = (positionMs / totalMs) * size.width;

      final isActive =
          (positionMs - currentPosition.inMilliseconds).abs() < 100;

      canvas.drawLine(
        Offset(x, size.height / 2 + 15),
        Offset(x, size.height / 2 - 5),
        isActive ? activePaint : paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
