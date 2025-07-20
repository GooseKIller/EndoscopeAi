import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:endoscopy_ai/features/storage_system/record_entry.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;

import 'shapes.dart';
import 'body_map.dart';

const _keyHistLst = 'hist';
const _keyHistIdx = 'idx';
const _keyDraft = 'draft';

enum Tool { pen, rect, circle, move }

class _AnnotationSnapshot {
  _AnnotationSnapshot(this.elements, this.mapSnap);
  final List<Shape> elements;
  final BodyMapSnapshot mapSnap;
}

class AnnotatePage extends StatefulWidget {
  const AnnotatePage({super.key, required this.screenshotData});
  final ScreenshotEntry screenshotData;

  @override
  State<AnnotatePage> createState() => _AnnotatePageState();
}

class _AnnotatePageState extends State<AnnotatePage> {
  final _globalKey = GlobalKey();
  final _imgKey = GlobalKey();
  Size _imgSize = Size.zero;
  final _controller = TextEditingController();
  late final ScreenshotEntry _screenshotData;
  final BodyMapController _mapCtrl = BodyMapController();
  BodyMapSnapshot? _lastMapSnap;

  @override
  void initState() {
    super.initState();
    _screenshotData = widget.screenshotData;
    _mapCtrl.addListener(_onMapChanged);

    // вызов отрисовки
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAnnotations();
      if (!mounted) return;
      _notes = _screenshotData.annotationText;
      _controller.text =
          _notes; // Body Map: загрузка из ScreenshotEntry.location (JSON)
      _mapCtrl.restore(_decodeLocation(_screenshotData.location));
      setState(() {});
    });
  }

  void _loadAnnotations() {
    try {
      setState(() {
        if (!mounted) return;
        _notes = _screenshotData.annotationText;
        _controller.text = _notes;

        final mapSnap = _decodeLocation(_screenshotData.location);
        _mapCtrl.restore(mapSnap); // rebuild карты
        _lastMapSnap = mapSnap;

        // загрузить данные рисования
        final rawJson = _screenshotData.drawingData as String;
        if (rawJson == '') {
          // ничего не сохранено
          _history.clear();
          _history.add([]);
          _histIx = 0;
        } else {
          // загружаем, то что сохранено
          final drawingJson = jsonDecode(rawJson) as Map<String, dynamic>;
          _histIx = drawingJson[_keyHistIdx] as int;

          final draftJson = drawingJson[_keyDraft] as String;

          _draft = (draftJson == '') ? null : Shape.fromJson(drawingJson);

          final newHist = (drawingJson[_keyHistLst] as List<dynamic>)
              .map((x) => (x as List<dynamic>)
                  .map((y) => Shape.fromJson(y as Map<String, dynamic>))
                  .toList())
              .toList();

          // восстанивить историю
          _history.clear();
          _history.addAll(newHist);

          // поставить на отрисовку
          _elements
            ..clear()
            ..addAll(_history[_histIx].map((e) => e.clone()));
        }
        _mapHistory
          ..clear()
          ..addAll(List<BodyMapSnapshot>.generate(
            _history.length,
            (_) => BodyMapSnapshot(
              mapSnap.organ,
              mapSnap.markers.map((m) => BodyMarker(m.rel)).toList(),
            ),
          ));

        // убедимся, что индекс в пределах
        if (_histIx >= _mapHistory.length) {
          _histIx = _mapHistory.length - 1;
        }
      });
    } catch (e) {
      debugPrint('Error loading annotations: $e');
    }
  }

  void _saveAnnotations() {
    if (!mounted) return;

    try {
      // Обновляем данные
      _screenshotData.annotationText = _notes;
      _screenshotData.location = _encodeLocation();

      // сохраняем осторию
      final decodedHist =
          (_history).map((x) => x.map((x) => x.toJson()).toList()).toList();
      final decodedDraft = _draft?.toJson() ?? '';
      final drawingData = {
        _keyHistLst: decodedHist,
        _keyHistIdx: _histIx,
        _keyDraft: decodedDraft,
      };
      _screenshotData.drawingData = jsonEncode(drawingData);

      // Сохраняем обратно
      StorageSystem.updateScreenshotData(_screenshotData);

      debugPrint('Annotations saved');
    } catch (e) {
      debugPrint('Error saving annotations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка сохранения: $e')),
        );
      }
    }
  }

  static const _palette = [
    Color(0xFF0072B2),
    Color(0xFFE69F00),
    Color(0xFF009E73),
  ];
  Color _color = _palette.first;
  Tool _tool = Tool.pen;

  double _strokeWidth = 3.0;
  final List<double> _availableWidths = [1.0, 3.0, 5.0, 8.0, 12.0];

  void _onMapChanged() {
    final snap = _mapCtrl.snapshot();
    if (_mapSnapEquals(_lastMapSnap, snap)) return;
    _lastMapSnap = snap;
    _commit();
  }

  @override
  void dispose() {
    _mapCtrl.removeListener(_onMapChanged);
    _saveAnnotations(); // Сохраняем перед уничтожением
    _controller.dispose(); // Не забываем освободить контроллер
    super.dispose();
  }

  BodyMapSnapshot _decodeLocation(String raw) {
    try {
      if (raw.isEmpty) return BodyMapSnapshot(null, []);
      final j = jsonDecode(raw) as Map<String, dynamic>;
      final organ = BodyPartX.fromName(j['organ'] as String?);
      final markers = ((j['markers'] ?? []) as List)
          .map((e) => BodyMarker.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return BodyMapSnapshot(organ, markers);
    } catch (_) {
      return BodyMapSnapshot(null, []);
    }
  }

  String _encodeLocation() {
    final data = {
      'organ': _mapCtrl.organ?.name ?? '',
      'markers': _mapCtrl.markers.map((m) => m.toJson()).toList(),
    };
    return jsonEncode(data);
  }

  final _elements = <Shape>[];
  Shape? _draft;
  String _notes = '';
  Shape? _selected;
  Offset? _lastRel;

  final _history = <List<Shape>>[[]];
  int _histIx = 0;
  final List<BodyMapSnapshot> _mapHistory = <BodyMapSnapshot>[];
  void _commit() {
    // режем вперёд в обоих стеках
    _history.removeRange(_histIx + 1, _history.length);
    _mapHistory.removeRange(_histIx + 1, _mapHistory.length);

    // сохраняем фигуры (как было)
    _history.add(_elements.map((e) => e.clone()).toList());

    // сохраняем снимок Body Map
    final mapSnap = _mapCtrl.snapshot();
    _mapHistory.add(mapSnap);
    _lastMapSnap = mapSnap;

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
                                    File(widget.screenshotData.imagePath),
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
                  AspectRatio(
                    aspectRatio: 1,
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: BodyMapSection(controller: _mapCtrl),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          controller: _controller,
                          textDirection: TextDirection.ltr,
                          expands: true,
                          maxLines: null,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Напишите здесь что-нибудь...',
                          ),
                          onChanged: (val) {
                            setState(() {
                              _notes = val;
                              _controller.text =
                                  val; // Синхронизируем контроллер
                            });
                            _saveAnnotations();
                          },
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
            color:
                _strokeWidth == width ? Colors.grey[300] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            width.toStringAsFixed(0),
            style: TextStyle(
              fontWeight:
                  _strokeWidth == width ? FontWeight.bold : FontWeight.normal,
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
        // восстановить карту меток
        _mapCtrl.restore(_mapHistory[_histIx]);
        _lastMapSnap = _mapHistory[_histIx];
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
        _mapCtrl.restore(_mapHistory[_histIx]);
        _lastMapSnap = _mapHistory[_histIx];
      });
    }
  }

  bool _mapSnapEquals(BodyMapSnapshot? a, BodyMapSnapshot? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.organ != b.organ) return false;
    final am = a.markers, bm = b.markers;
    if (am.length != bm.length) return false;
    for (var i = 0; i < am.length; i++) {
      // координаты в 0..1, сравним с малым допуском
      if ((am[i].rel - bm[i].rel).distance > 1e-6) return false;
    }
    return true;
  }

  // save SVG
  Future<void> _saveSvg() async {
    try {
      final ui.Image img = await (_globalKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 1.0);
      final w = img.width, h = img.height;

      final b64 = base64Encode(
          await File(widget.screenshotData.imagePath).readAsBytes());

      final shapesXml = _elements
          .map((e) => e.toSvg(Size(w.toDouble(), h.toDouble())).toXmlString())
          .join('\n  ');
      final svg = '''
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
            'annotate_${p.basenameWithoutExtension(widget.screenshotData.imagePath)}.svg',
        type: FileType.custom,
        allowedExtensions: ['svg'],
      );
      if (path == null) return;
      await File(path).writeAsString(svg);
      final basePath = p.withoutExtension(path); // тот же каталог
      await _mapCtrl.savePng(basePath);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved: ${p.basename(path)}')));
      }
    } catch (e, st) {
      debugPrint('Save SVG error: $e\n$st');
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
