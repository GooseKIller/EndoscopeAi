import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';


//  BodyMapController — позволяет странице управлять картой органов

class BodyMapController extends ChangeNotifier {
  
  BodyPart? _organ;
  final List<_Marker> _markers = [];
  ScreenshotController? _shotCtrl; // инициализируется BodyMapSection
  

  
  BodyPart? get organ => _organ;
  List<_Marker> get markers => List.unmodifiable(_markers);

  void setOrgan(BodyPart? part) {
    _organ = part;
    _markers.clear();
    notifyListeners();
  }

  void setMarkers(Iterable<_Marker> m) {
    _markers
      ..clear()
      ..addAll(m);
    notifyListeners();
  }

  void addMarker(_Marker m) {
    _markers.add(m);
    notifyListeners();
  }

  void removeMarker(_Marker m) {
    _markers.remove(m);
    notifyListeners();
  }

  // Возвращает снимок текущего состояния (для undo/redo)
  BodyMapSnapshot snapshot() => BodyMapSnapshot(_organ, List<_Marker>.from(_markers));

  // Восстанавливает состояние из снапшота (undo/redo)
  void restore(BodyMapSnapshot snap) {
    _organ = snap.organ;
    _markers
      ..clear()
      ..addAll(snap.markers);
    notifyListeners();
  }

  // Сохраняет PNG в ту же папку, куда основной скриншот страницы.
  Future<void> savePng(String basePath) async {
    if (_organ == null || _shotCtrl == null) return;
    final bytes = await _shotCtrl!.capture(pixelRatio: 3);
    if (bytes == null) return;

    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}');
    if (!await dir.exists()) await dir.create(recursive: true);

    final file = File('${basePath}_${_organ!.name}.png');
    await file.writeAsBytes(bytes);
  }
}

class BodyMapSnapshot {
  BodyMapSnapshot(this.organ, this.markers);
  final BodyPart? organ;
  final List<_Marker> markers;
}

class BodyMapSection extends StatefulWidget {
  const BodyMapSection({super.key, required this.controller});
  final BodyMapController controller;

  @override
  State<BodyMapSection> createState() => _BodyMapSectionState();
}

class _BodyMapSectionState extends State<BodyMapSection> {
  final _shotCtrl = ScreenshotController();

  @override
  void initState() {
    super.initState();
    widget.controller._shotCtrl = _shotCtrl; 
    widget.controller.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() => setState(() {});

  void _handleTap(Offset localPos, Size size) {
    if (widget.controller.organ == null) return;
    final rel = Offset(localPos.dx / size.width, localPos.dy / size.height);
    widget.controller.addMarker(_Marker(rel));
  }

  
  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // toolbar
        Row(
          children: [
            DropdownButton<BodyPart?>(
              value: ctrl.organ,
              hint: const Text('Выберите орган'),
              onChanged: ctrl.setOrgan,
              items: BodyPart.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.label)))
                  .toList(),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // карта / заглушка
        Expanded(
          child: Screenshot(
            controller: _shotCtrl,
            child: ctrl.organ == null
                ? const Center(child: Text('Нет органа'))
                : LayoutBuilder(
                    builder: (ctx, constraints) {
                      final size = constraints.biggest;
                      return GestureDetector(
                        onTapUp: (d) => _handleTap(d.localPosition, size),
                        child: Stack(
                          children: [
                            SvgPicture.asset(
                              ctrl.organ!.assetPath,
                              width: size.width,
                              height: size.height,
                              fit: BoxFit.contain,
                            ),
                            ...ctrl.markers.map((m) => _buildPin(size, m)),
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

  Widget _buildPin(Size size, _Marker m) => Positioned(
        left: m.rel.dx * size.width - 12,
        top: m.rel.dy * size.height - 24,
        child: GestureDetector(
          onLongPress: () => widget.controller.removeMarker(m),
          child: const Icon(Icons.location_on, color: Colors.red, size: 32),
        ),
      );
}

enum BodyPart { oesophagus, stomach, duodenum, colon }

extension on BodyPart {
  String get assetPath => 'assets/body_maps/${name}.svg';
  String get label {
    switch (this) {
      case BodyPart.oesophagus:
        return 'Пищевод';
      case BodyPart.stomach:
        return 'Желудок';
      case BodyPart.duodenum:
        return 'ДПК';
      case BodyPart.colon:
        return 'Толстый кишечник';
    }
  }
}

class _Marker {
  _Marker(this.rel);
  final Offset rel; // 0..1, 0..1
  @override
  String toString() => 'Marker(${rel.dx.toStringAsFixed(3)}, ${rel.dy.toStringAsFixed(3)})';
}