import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:endoscopy_ai/pages/annotate/shapes.dart';

void main() {
  const cs = Size(100, 200);
  final shape =
      RectShape(const Offset(.1, .2), const Offset(.4, .6), Colors.blue, 1);

  test('точка внутри прямоугольника (с учётом inflate) попадает', () {
    expect(shape.hitTest(const Offset(20, 60), cs), isTrue);
  });

  test('точка снаружи не попадает', () {
    expect(shape.hitTest(const Offset(0, 0), cs), isFalse);
  });

  //сюда все равно никто не зайдет, расскажите как дела
}
