import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:xml/xml.dart';

Offset _abs(Size s, Offset rel) => Offset(rel.dx * s.width, rel.dy * s.height);
String _hx(Color c) =>
    '#${c.value.toRadixString(16).padLeft(8, '0').substring(2)}';

const _keyColor = 'color';
const _keyWidth = 'width';
const _keyShape = 'shape';

enum _keyShapeType {
  Pen('pen'),
  Rect('rect'),
  Ellipse('elliplse');

  const _keyShapeType(this.key);

  final String key;
}

abstract class Shape {
  Shape(this.color, this.strokeWidth);
  Color color;
  double strokeWidth;

  void paint(Canvas c, Paint p, Size cs);
  XmlNode toSvg(Size cs);

  bool hitTest(Offset p, Size cs);
  void translateRel(Offset dRel);
  Shape clone();
  bool compareTo(Shape other);

  Map<String, dynamic> toJson();
  factory Shape.fromJson(Map<String, dynamic> json) {
    final key = json[_keyShape] as String;

    if (key == _keyShapeType.Ellipse.key) {
      return EllipseShape.fromJson(json);
    } else if (key == _keyShapeType.Pen.key) {
      return PenShape.fromJson(json);
    } else if (key == _keyShapeType.Rect.key) {
      return RectShape.fromJson(json);
    } else {
      print("INVALID SHAPE TYPE: $key");
      return PenShape([], Colors.black, 0);
    }
  }
}

// Pen
class PenShape extends Shape {
  static const _keyPoints = 'points';

  List<Offset> pts; // relative
  PenShape(this.pts, Color col, double strokeWidth) : super(col, strokeWidth);

  @override
  void paint(Canvas c, Paint p, Size cs) {
    c.clipRect(Offset.zero & cs);
    p
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(_abs(cs, pts.first).dx, _abs(cs, pts.first).dy);
    for (final rp in pts.skip(1)) {
      final v = _abs(cs, rp);
      path.lineTo(v.dx, v.dy);
    }
    c.drawPath(path, p);
  }

  @override
  XmlNode toSvg(Size cs) => XmlElement(XmlName('polyline'), [
        XmlAttribute(
          XmlName('points'),
          pts.map((rp) => _abs(cs, rp)).map((v) => '${v.dx},${v.dy}').join(' '),
        ),
        XmlAttribute(XmlName('fill'), 'none'),
        XmlAttribute(XmlName('stroke'), _hx(color)),
        XmlAttribute(XmlName('stroke-width'), strokeWidth.toStringAsFixed(1)),
      ]);

  @override
  Map<String, dynamic> toJson() {
    return {
      _keyPoints: pts.map((x) => [x.dx, x.dy]).toList(),
      _keyColor: color.toARGB32(),
      _keyWidth: strokeWidth,
      _keyShape: _keyShapeType.Pen.key
    };
  }

  factory PenShape.fromJson(Map<String, dynamic> map) {
    Color color;
    double strokeWidth;
    List<Offset> pts; // relative

    // загружаем поинты
    pts = (map[_keyPoints] as List<dynamic>).cast<List<dynamic>>().map((y) {
      final x = y.cast<double>();
      return Offset(x[0], x[1]);
    }).toList();

    strokeWidth = map[_keyWidth] as double;

    color = Color(map[_keyColor] as int);

    return PenShape(pts, color, strokeWidth);
  }

  @override
  bool hitTest(Offset p, Size cs) =>
      pts.any((rp) => (_abs(cs, rp) - p).distance <= 8);

  @override
  void translateRel(Offset d) {
    for (var i = 0; i < pts.length; i++) {
      pts[i] += d;
    }
  }

  @override
  Shape clone() => PenShape(List.of(pts), color, strokeWidth);

  @override
  bool compareTo(Shape other) =>
      other is PenShape &&
      listEquals(other.pts, pts) &&
      other.color == color &&
      other.strokeWidth == strokeWidth;
}

// Rect
class RectShape extends Shape {
  static final _keyP1 = 'p1';
  static final _keyP2 = 'p2';

  Offset p1, p2; // relative
  RectShape(this.p1, this.p2, Color col, double strokeWidth)
      : super(col, strokeWidth);

  Rect _rect(Size cs) => Rect.fromPoints(_abs(cs, p1), _abs(cs, p2));

  @override
  void paint(Canvas c, Paint p, Size cs) {
    c.clipRect(Offset.zero & cs);
    p
      ..color = color.withOpacity(0.6)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    c.drawRect(_rect(cs), p);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      _keyP1: [p1.dx, p1.dy],
      _keyP2: [p2.dx, p2.dy],
      _keyColor: color.toARGB32(),
      _keyWidth: strokeWidth,
      _keyShape: _keyShapeType.Rect.key
    };
  }

  factory RectShape.fromJson(Map<String, dynamic> map) {
    Offset p1, p2;
    Color color;
    double strokeWidth;

    // загружаем поинты
    final m1 = (map[_keyP1] as List<dynamic>).cast<double>();
    p1 = Offset(m1[0], m1[1]);

    final m2 = (map[_keyP2] as List<dynamic>).cast<double>();
    p2 = Offset(m2[0], m2[1]);

    strokeWidth = map[_keyWidth] as double;

    color = Color(map[_keyColor] as int);

    return RectShape(p1, p2, color, strokeWidth);
  }

  @override
  XmlNode toSvg(Size cs) {
    final r = _rect(cs);
    return XmlElement(XmlName('rect'), [
      XmlAttribute(XmlName('x'), r.left.toStringAsFixed(1)),
      XmlAttribute(XmlName('y'), r.top.toStringAsFixed(1)),
      XmlAttribute(XmlName('width'), r.width.toStringAsFixed(1)),
      XmlAttribute(XmlName('height'), r.height.toStringAsFixed(1)),
      XmlAttribute(XmlName('fill'), 'none'),
      XmlAttribute(XmlName('stroke'), _hx(color)),
      XmlAttribute(XmlName('stroke-width'), strokeWidth.toStringAsFixed(1)),
    ]);
  }

  @override
  bool hitTest(Offset p, Size cs) => _rect(cs).inflate(6).contains(p);

  @override
  void translateRel(Offset d) {
    p1 += d;
    p2 += d;
  }

  @override
  Shape clone() => RectShape(p1, p2, color, strokeWidth);

  @override
  bool compareTo(Shape o) =>
      o is RectShape &&
      o.p1 == p1 &&
      o.p2 == p2 &&
      o.color == color &&
      o.strokeWidth == strokeWidth;
}

// Circle
class EllipseShape extends Shape {
  static final _keyA = 'a';
  static final _keyB = 'b';

  Offset a, b; // opposite corners (rel)
  EllipseShape(this.a, this.b, Color col, double strokeWidth)
      : super(col, strokeWidth);

  @override
  void paint(Canvas c, Paint p, Size cs) {
    c.clipRect(Offset.zero & cs);
    p
      ..color = color.withOpacity(0.6)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rect = Rect.fromPoints(_abs(cs, a), _abs(cs, b));

    c.drawOval(rect, p);

    //     c.drawCircle(rect.center, rect.shortestSide / 2, p);
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      _keyA: [a.dx, a.dy],
      _keyB: [b.dx, b.dy],
      _keyColor: color.toARGB32(),
      _keyWidth: strokeWidth,
      _keyShape: _keyShapeType.Ellipse.key
    };
  }

  factory EllipseShape.fromJson(Map<String, dynamic> map) {
    Color color;
    Offset a, b;
    double strokeWidth;

    // загружаем поинты
    final m1 = (map[_keyA] as List<dynamic>).cast<double>();
    a = Offset(m1[0], m1[1]);
    final m2 = (map[_keyB] as List<dynamic>).cast<double>();
    b = Offset(m2[0], m2[1]);

    strokeWidth = map[_keyWidth] as double;

    color = Color(map[_keyColor] as int);

    return EllipseShape(a, b, color, strokeWidth);
  }

  @override
  XmlNode toSvg(Size cs) {
    final rect = Rect.fromPoints(_abs(cs, a), _abs(cs, b));
    return XmlElement(XmlName('ellipse'), [
      XmlAttribute(XmlName('cx'), rect.center.dx.toStringAsFixed(1)),
      XmlAttribute(XmlName('cy'), rect.center.dy.toStringAsFixed(1)),
      XmlAttribute(XmlName('rx'), (rect.width / 2).toStringAsFixed(1)),
      XmlAttribute(XmlName('ry'), (rect.height / 2).toStringAsFixed(1)),
      XmlAttribute(XmlName('fill'), 'none'),
      XmlAttribute(XmlName('stroke'), _hx(color)),
      XmlAttribute(XmlName('stroke-width'), strokeWidth.toStringAsFixed(1)),
    ]);
  }

  @override
  bool hitTest(Offset p, Size cs) {
    final rect = Rect.fromPoints(_abs(cs, a), _abs(cs, b));
    return (p - rect.center).distance <= rect.shortestSide / 2 + 6;
  }

  @override
  void translateRel(Offset d) {
    a += d;
    b += d;
  }

  @override
  Shape clone() => EllipseShape(a, b, color, strokeWidth);

  @override
  bool compareTo(Shape o) =>
      o is EllipseShape &&
      o.a == a &&
      o.b == b &&
      o.color == color &&
      o.strokeWidth == strokeWidth;
}
