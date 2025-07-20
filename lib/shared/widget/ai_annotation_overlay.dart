// ====================================================
//  Виджет для подсвечивания ИИ подсказок
// ====================================================
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:endoscopy_ai/features/ai/endo_ai.dart';

class AiAnnotationOverlay extends StatelessWidget {
  final Size videoSize;
  final List<FFIDetectionResult> foundFeatures;
  late final bool shouldPaint;

  AiAnnotationOverlay(
      {required this.videoSize,
      required this.foundFeatures,
      bool? shouldPaint,
      super.key}) {
    this.shouldPaint = shouldPaint ?? true;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      print("${constraints.maxWidth} ${constraints.maxHeight}");

      final renderSize = Size(constraints.maxWidth, constraints.maxHeight);

      return CustomPaint(
        size: renderSize,
        painter: _AnnotationPainter(
            rectangles: shouldPaint ? foundFeatures : [], videoSize: videoSize),
      );
    });
  }
}

// Рисователь аннотаций
class _AnnotationPainter extends CustomPainter {
  final List<FFIDetectionResult> rectangles;
  final Size videoSize;
  late final Color annotationColor;
  late final Color textColor;

  _AnnotationPainter({
    required this.rectangles,
    required this.videoSize,
    Color? annotationColor,
    Color? textColor,
  }) {
    this.annotationColor = annotationColor ?? Colors.green;
    this.textColor = textColor ?? const Color.fromARGB(255, 27, 10, 9);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (videoSize.width == 0 || videoSize.height == 0) return;

    // Вычисляем коэффициенты масштабирования
    final scaleX = size.width / videoSize.width;
    final scaleY = size.height / videoSize.height;

    for (var rect in rectangles) {
      // Масштабируем координаты
      final scaledRect = Rect.fromLTRB(
        rect.x1 * scaleX,
        rect.y1 * scaleY,
        rect.x2 * scaleX,
        rect.y2 * scaleY,
      );

      // Рисуем прямоугольник
      final paint = Paint()
        ..color = annotationColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawRect(scaledRect, paint);

      // Рисуем текст над прямоугольником
      final textSpan = TextSpan(
        text: "${rect.label}(${(rect.confidence * 100).toInt()}%)",
        style: TextStyle(
            color: textColor, fontSize: 12, backgroundColor: annotationColor),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      final textOffset = Offset(
        scaledRect.left,
        scaledRect.top - textPainter.height,
      );
      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Для простоты всегда перерисовываем
  }
}
