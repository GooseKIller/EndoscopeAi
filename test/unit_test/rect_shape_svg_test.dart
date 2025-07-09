import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:endoscopy_ai/pages/annotate/shapes.dart';

void main() {
  test('RectShape -> SVG содержит корректные координаты', () {
    // canvas 100 × 200
    const cs = Size(100, 200);
    // прямоугольник  (10,40) – (40,120)  в абсолютных px
    final shape = RectShape(
      const Offset(.1, .2), // (0.1 * 100, 0.2 * 200) = (10,40)
      const Offset(.4, .6), // (0.4 * 100, 0.6 * 200) = (40,120)
      Colors.red,
      3,
    );

    final xml = shape.toSvg(cs) as XmlElement;
    expect(xml.name.local, equals('rect'));
    expect(xml.getAttribute('x'), equals('10.0'));
    expect(xml.getAttribute('y'), equals('40.0'));
    expect(xml.getAttribute('width'), equals('30.0')); // 40-10
    expect(xml.getAttribute('height'), equals('80.0')); // 120-40
    expect(xml.getAttribute('stroke'), equals('#f44336'));
  });
}
