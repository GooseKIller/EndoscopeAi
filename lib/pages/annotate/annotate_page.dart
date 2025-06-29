import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import '../../backend/python_service.dart';

import 'shapes.dart';

enum Tool { pen, rect, circle, move }

class AnnotatePage extends StatefulWidget {
  const AnnotatePage({super.key, required this.imagePath});
  final String imagePath;

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  final _globalKey = GlobalKey();
  final _imgKey = GlobalKey();
  Size _imgSize = Size.zero;

  static const _palette = [
    Color(0xFF0072B2),
    Color(0xFFE69F00),
    Color(0xFF009E73),
  ];
  Color _color = _palette.first;
  Tool _tool = Tool.pen;

  double _strokeWidth = 3.0;
  final List<double> _availableWidths = [1.0, 3.0, 5.0, 8.0, 12.0];

  final _python = PythonService();

  final _elements = <Shape>[];
  Shape? _draft;
  String _notes = '';
  Shape? _selected;
  Offset? _lastRel;

  final _history = <List<Shape>>[[]];
  int _histIx = 0;
  void _commit() {
    _history.removeRange(_histIx + 1, _history.length);
    _history.add(_elements.map((e) => e.clone()).toList());
    _histIx = _history.length - 1;
  }

  Offset _toRel(Offset p) {
    final dx = (p.dx / _imgSize.width).clamp(0.0, 1.0);
    final dy = (p.dy / _imgSize.height).clamp(0.0, 1.0);
    return Offset(dx, dy);
  }

  Offset _clampLocal(Offset p) =>
      Offset(p.dx.clamp(0.0, _imgSize.width), p.dy.clamp(0.0, _imgSize.height));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Annotation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _histIx == 0 ? null : _undo,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _histIx == _history.length - 1 ? null : _redo,
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveSvg),
          IconButton(icon: const Icon(Icons.bug_report), onPressed: _runAi),
        ],
      ),
      body: Row(
        children: [
          // Скрин с фигурами
          Expanded(
            flex: 3,
            child: Column(
              children: [
                _toolbar(),
                Expanded(
                  child: Center(
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: LayoutBuilder(
                        builder: (_, __) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            final ctx = _imgKey.currentContext;
                            if (ctx != null) {
                              final sz = ctx.size ?? Size.zero;
                              if (sz != _imgSize) setState(() => _imgSize = sz);
                            }
                          });
                          return GestureDetector(
                            onPanStart: _start,
                            onPanUpdate: _update,
                            onPanEnd: _end,
                            child: ClipRect(
                              child: Stack(
                                children: [
                                  Image.file(
                                    File(widget.imagePath),
                                    key: _imgKey,
                                  ),
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _Painter(
                                        _elements,
                                        _draft,
                                        _imgSize,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Панель заметок
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Заметки',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          expands: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Напишите здесь что-нибудь...',
                          ),
                          onChanged: (val) => setState(() => _notes = val),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runAi,
        icon: const Icon(Icons.bug_report),
        label: const Text('AI анализ'),
      ),
    );
  }

  Widget _toolbar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        // Выбор цвета с выделением
        for (final c in _palette) _colorBtn(c),
        const SizedBox(width: 20),

        // Выбор толщины с выделением
        Text('Толщина: ', style: TextStyle(fontSize: 14)),
        for (final w in _availableWidths) _widthBtn(w),
        const SizedBox(width: 20),

        // Выбор инструментов с выделением
        _toolBtn(Icons.edit, Tool.pen),
        _toolBtn(Icons.crop_square, Tool.rect),
        _toolBtn(Icons.circle_outlined, Tool.circle),
        _toolBtn(Icons.open_with, Tool.move),
      ],
    ),
  );

  Widget _colorBtn(Color c) => GestureDetector(
    onTap: () => setState(() => _color = c),
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _color == c ? Colors.grey[300] : Colors.transparent,
      ),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: c,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26, width: 1),
        ),
      ),
    ),
  );

  Widget _widthBtn(double width) => GestureDetector(
    onTap: () => setState(() => _strokeWidth = width),
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _strokeWidth == width ? Colors.grey[300] : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        width.toStringAsFixed(0),
        style: TextStyle(
          fontWeight: _strokeWidth == width
              ? FontWeight.bold
              : FontWeight.normal,
        ),
      ),
    ),
  );

  Widget _toolBtn(IconData i, Tool t) => Container(
    margin: const EdgeInsets.only(right: 4),
    decoration: BoxDecoration(
      color: _tool == t ? Colors.grey[300] : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: IconButton(
      icon: Icon(
        i,
        color: _tool == t
            ? Theme.of(context).colorScheme.primary
            : Colors.black54,
      ),
      onPressed: () => setState(() => _tool = t),
    ),
  );

  // gestures
  void _start(DragStartDetails d) => setState(() {
    final pos = _clampLocal(d.localPosition);
    final rel = _toRel(pos);

    if (_tool == Tool.move) {
      for (final s in _elements.reversed) {
        if (s.hitTest(pos, _imgSize)) {
          _selected = s;
          _lastRel = rel;
          break;
        }
      }
      return;
    }

    switch (_tool) {
      case Tool.pen:
        _draft = PenShape([rel], _color, _strokeWidth);
      case Tool.rect:
        _draft = RectShape(rel, rel, _color, _strokeWidth);
      case Tool.circle:
        _draft = EllipseShape(rel, rel, _color, _strokeWidth);
      default:
        break;
    }
  });

  void _update(DragUpdateDetails d) => setState(() {
    final pos = _clampLocal(d.localPosition);
    final rel = _toRel(pos);

    if (_tool == Tool.move && _selected != null && _lastRel != null) {
      _selected!.translateRel(rel - _lastRel!);
      _lastRel = rel;
      return;
    }

    if (_draft is PenShape) {
      (_draft as PenShape).pts.add(rel);
    } else if (_draft is RectShape) {
      (_draft as RectShape).p2 = rel;
    } else if (_draft is EllipseShape) {
      (_draft as EllipseShape).b = rel;
    }
  });

  void _end(DragEndDetails d) => setState(() {
    if (_tool == Tool.move) {
      _selected = null;
      _lastRel = null;
      _commit();
      return;
    }
    if (_draft != null) {
      _elements.add(_draft!.clone());
      _draft = null;
      _commit();
    }
  });

  // undo / redo
  void _undo() {
    if (_histIx > 0) {
      setState(() {
        _histIx--;
        _elements
          ..clear()
          ..addAll(_history[_histIx].map((e) => e.clone()));
      });
    }
  }

  void _redo() {
    if (_histIx < _history.length - 1) {
      setState(() {
        _histIx++;
        _elements
          ..clear()
          ..addAll(_history[_histIx].map((e) => e.clone()));
      });
    }
  }

  Future<void> _runAi() async {
    final detections = await _python.detectImage(widget.imagePath);
    final img = await decodeImageFromList(
      File(widget.imagePath).readAsBytesSync(),
    );
    for (final d in detections) {
      final x1 = (d['x1'] as num).toDouble() / img.width;
      final y1 = (d['y1'] as num).toDouble() / img.height;
      final x2 = (d['x2'] as num).toDouble() / img.width;
      final y2 = (d['y2'] as num).toDouble() / img.height;
      _elements.add(RectShape(Offset(x1, y1), Offset(x2, y2), Colors.red, 2));
    }
    setState(() => _commit());
  }

  // save SVG
  Future<void> _saveSvg() async {
    try {
      final ui.Image img =
          await (_globalKey.currentContext!.findRenderObject()
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1.0);
      final w = img.width, h = img.height;

      final b64 = base64Encode(await File(widget.imagePath).readAsBytes());

      final shapesXml = _elements
          .map((e) => e.toSvg(Size(w.toDouble(), h.toDouble())).toXmlString())
          .join('\n  ');
      final svg =
          '''
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg"
     xmlns:xlink="http://www.w3.org/1999/xlink"
     width="$w" height="$h" viewBox="0 0 $w $h">
  <image xlink:href="data:image/png;base64,$b64"
         x="0" y="0" width="$w" height="$h" />
  $shapesXml
</svg>
''';

      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save annotation',
        fileName:
            'annotate_${p.basenameWithoutExtension(widget.imagePath)}.svg',
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (path == null) return;
      await File(path).writeAsString(svg);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved: ${p.basename(path)}')));
      }
    } catch (e) {
      debugPrint('Save SVG error: $e');
    }
  }
}

// painter
class _Painter extends CustomPainter {
  final List<Shape> shapes;
  final Shape? draft;
  final Size canvasSize;
  _Painter(this.shapes, this.draft, this.canvasSize);

  @override
  void paint(Canvas c, Size _) {
    final p = Paint();
    for (final s in shapes) {
      s.paint(c, p, canvasSize);
    }
    draft?.paint(c, p, canvasSize);
  }

  @override
  bool shouldRepaint(covariant _Painter old) =>
      old.shapes != shapes ||
      old.draft != draft ||
      old.canvasSize != canvasSize;
}
