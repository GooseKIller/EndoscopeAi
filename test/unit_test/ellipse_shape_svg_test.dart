import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';
import 'package:endoscopy_ai/pages/annotate/shapes.dart';

void main() {
  test('EllipseShape -> SVG содержит корректный центр', () {
    const cs = Size(100, 100);
    final shape =
        EllipseShape(const Offset(0, 0), const Offset(1, 1), Colors.yellow, 4);

    final xml = shape.toSvg(cs) as XmlElement;
    expect(xml.name.local, equals('ellipse'));
    expect(xml.getAttribute('cx'), equals('50.0')); // центр канваса
    expect(xml.getAttribute('cy'), equals('50.0')); //как же я устала
  });
}
