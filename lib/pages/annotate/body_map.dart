import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;


enum BodyPart { oesophagus, stomach, duodenum, colon }

extension BodyPartX on BodyPart {
  String get label {
    switch (this) {
      case BodyPart.oesophagus: return 'Пищевод';
      case BodyPart.stomach:    return 'Желудок';
      case BodyPart.duodenum:   return 'ДПК';
      case BodyPart.colon:      return 'Кишка';
    }
  }

  String get assetPath => 'assets/body_maps/${name}.svg';

  static BodyPart? fromName(String? s) {
    if (s == null || s.isEmpty) return null;
    return BodyPart.values.firstWhere(
      (e) => e.name == s,
      orElse: () => BodyPart.stomach,
    );
  }
}

class BodyMarker {
  BodyMarker(this.rel);
  final Offset rel; // 0..1
  Map<String, dynamic> toJson() => {'x': rel.dx, 'y': rel.dy};
  static BodyMarker fromJson(Map<String, dynamic> j) =>
      BodyMarker(Offset((j['x'] as num).toDouble(), (j['y'] as num).toDouble()));
}

class BodyMapSnapshot {
  BodyMapSnapshot(this.organ, this.markers);
  final BodyPart? organ;
  final List<BodyMarker> markers;
}


class BodyMapController extends ChangeNotifier {
  BodyPart? _organ;
  final List<BodyMarker> _markers = [];
  GlobalKey? _boundaryKey; // регистрирует BodyMapSection

  BodyPart? get organ => _organ;
  List<BodyMarker> get markers => List.unmodifiable(_markers);

  void setOrgan(BodyPart? p) {
    _organ = p;
    _markers.clear();
    notifyListeners();
  }

  void addMarker(Offset rel) {
    _markers.add(BodyMarker(rel));
    notifyListeners();
  }

  void removeMarker(BodyMarker m) {
    _markers.remove(m);
    notifyListeners();
  }

  BodyMapSnapshot snapshot() => BodyMapSnapshot(_organ, List.of(_markers));

  void restore(BodyMapSnapshot s) {
    _organ = s.organ;
    _markers
      ..clear()
      ..addAll(s.markers);
    notifyListeners();
  }

  // Регистрирует RepaintBoundary для последующего снятия PNG.
  void registerBoundary(GlobalKey key) => _boundaryKey = key;

  // Снимает PNG текущей карты. null, если орган не выбран.
  Future<Uint8List?> capturePng({double pixelRatio = 2}) async {
  if (_organ == null) return null;
  final key = _boundaryKey;
  if (key == null) return null;

  final ctx = key.currentContext;
  if (ctx == null) return null;

  final render = ctx.findRenderObject();
  if (render is! RenderRepaintBoundary) return null;

  final ui.Image img = await render.toImage(pixelRatio: pixelRatio);
  final bd = await img.toByteData(format: ui.ImageByteFormat.png);
  return bd?.buffer.asUint8List();
}

  // Сохраняет PNG карты органа в тот же каталог, что и [basePath] (без расширения).
  Future<void> savePng(String basePath) async {
    final bytes = await capturePng();
    if (bytes == null) return;
    final file = File('${basePath}_${_organ!.name}.png');
    await file.writeAsBytes(bytes);
  }
}

class BodyMapSection extends StatefulWidget {
  const BodyMapSection({super.key, required this.controller});
  final BodyMapController controller;

  @override
  State<BodyMapSection> createState() => _BodyMapSectionState();
}

class _BodyMapSectionState extends State<BodyMapSection> {
  final _repaintKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.registerBoundary(_repaintKey);
    widget.controller.addListener(_onCtrl);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCtrl);
    super.dispose();
  }

  void _onCtrl() => setState(() {});

  void _add(Size size, TapUpDetails d) {
    final rel = Offset(
      (d.localPosition.dx / size.width).clamp(0.0, 1.0),
      (d.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    widget.controller.addMarker(rel);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final organ = c.organ;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButton<BodyPart?>(
          value: organ,
          hint: const Text('Выберите орган'),
          onChanged: c.setOrgan,
          items: BodyPart.values
              .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
              .toList(),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RepaintBoundary(
            key: _repaintKey,
            child: organ == null
                ? const Center(child: Text('Нет органа'))
                : LayoutBuilder(
                    builder: (_, cons) {
                      final size = cons.biggest;
                      return GestureDetector(
                        onTapUp: (d) => _add(size, d),
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              organ.assetPath,
                              width: size.width,
                              height: size.height,
                              fit: BoxFit.contain,
                            ),
                            ...c.markers.map(
                              (m) => Positioned(
                                left: m.rel.dx * size.width - 12,
                                top: m.rel.dy * size.height - 24,
                                child: GestureDetector(
                                  onLongPress: () => c.removeMarker(m),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
