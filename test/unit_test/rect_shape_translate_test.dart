import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:endoscopy_ai/pages/annotate/shapes.dart';

void main() {
  test('RectShape.translateRel сдвигает обе точки', () {
    final shape = RectShape(
      const Offset(.2, .3),
      const Offset(.4, .5),
      const Color(0xFF00FF00),
      2,
    );

    shape.translateRel(const Offset(.1, .1));
    expect(shape.p1.dx, closeTo(.3, 1e-9));
    expect(shape.p1.dy, closeTo(.4, 1e-9));
    expect(shape.p2.dx, closeTo(.5, 1e-9));
    expect(shape.p2.dy, closeTo(.6, 1e-9));
  });
}
