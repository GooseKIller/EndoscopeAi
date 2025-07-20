import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:endoscopy_ai/pages/annotate/shapes.dart';

void main() {
  test('PenShape экспортирует столько точек, сколько передано', () {
    const cs = Size(100, 100);
    final points = [
      const Offset(0, 0),
      const Offset(.5, .5),
      const Offset(1, 1),
    ];
    final shape = PenShape(points, Colors.white, 1);

    final xml = shape.toSvg(cs) as XmlElement;
    final poly = xml.getAttribute('points')!;
    expect(poly.split(' ').length, equals(points.length));
  });
}
