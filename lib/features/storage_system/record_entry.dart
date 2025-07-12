// ====================================================
//  Примитивы для сохранения данных о записи и скриншота
// ====================================================
import 'dart:io';
import 'dart:math';

import '../patient/record_data.dart';
import 'storage_fs_operations.dart' as sfs;
import 'package:path/path.dart' as p;
import 'package:endoscopy_ai/features/patient/record_data.dart';

// Перевод времени в вид читаемый json
List<int> _durationToList(Duration durr) => <int>[
      durr.inHours,
      durr.inMinutes % 60,
      durr.inSeconds % 60,
      durr.inMicroseconds % 1000000
    ];

Duration _listToDuration(List<dynamic> dylist) {
  final list = dylist.map((x) => x as int).toList();
  return Duration(
      hours: list[0],
      minutes: list[1],
      seconds: list[2],
      microseconds: list[3]);
}

// id_$data.id
// |-- $data.date
// |   |-- video_$videoid.mp4
// |   |-- screenshots
// |       |-- s_$stime_($sid).png
// | ...

// Содержит данные о записи
class RecordEntry {
  final RecordData data;
  final Directory recordDirectory;
  late final String videoPath;
  late final String screenshotFolder;
  List<ScreenshotEntry>? _screenshots;

  bool get isScreenshotLoaded => _screenshots != null;
  List<ScreenshotEntry> get screenshots => _screenshots ?? [];

  RecordEntry(
      {required this.data,
      required this.recordDirectory,
      List<ScreenshotEntry>? screenshots}) {
    final recordFolder = recordDirectory.absolute.path;
    videoPath = sfs.generateVideoPath(recordFolder);
    screenshotFolder = sfs.generateScreenshotFolderPath(recordFolder);

    _screenshots = screenshots;
  }

  void setScreenshots(List<ScreenshotEntry> screenshots) {
    _screenshots = screenshots;
  }

  void addScreenshot(ScreenshotEntry entry) {
    if (_screenshots == null) _screenshots = [];
    _screenshots!.add(entry);
  }

  int getNextId() {
    if (_screenshots == null || _screenshots!.isEmpty) return 1;
    int nextId = _screenshots!.map((x) => x.imageId).reduce(max) + 1;
    return nextId;
  }
}

// Содержит данные о скриншоте
class ScreenshotEntry {
  static const _jsonTextKey = 'text';
  static const _jsonDrawingKey = 'draw';
  static const _jsonTimeKey = 'time';

  final int imageId;
  late final String imagePath;
  late final String dataPath;
  final Duration time;
  final String annotationText;
  final String drawingData;

  ScreenshotEntry._({
    required String screenshotFolder,
    required this.imageId,
    required this.time,
    required this.annotationText,
    required this.drawingData,
  }) {
    final gen = sfs.generateScreenshotPaths(screenshotFolder, imageId);
    imagePath = gen.$1;
    dataPath = gen.$2;
  }

  Map<String, dynamic> toJson() => {
        _jsonTimeKey: _durationToList(time),
        _jsonTextKey: annotationText,
        _jsonDrawingKey: drawingData,
      };
  factory ScreenshotEntry.fromJson(
      {required String screenshotFolder,
      required int imageId,
      required Map<String, dynamic> json}) {
    if (!json.containsKey(_jsonTextKey)) json[_jsonTextKey] = '';
    if (!json.containsKey(_jsonDrawingKey)) json[_jsonDrawingKey] = '';
    if (!json.containsKey(_jsonTimeKey)) {
      json[_jsonTimeKey] = Duration(days: 0);
    } else {
      json[_jsonTimeKey] = _listToDuration(json[_jsonTimeKey] as List<dynamic>);
    }

    return ScreenshotEntry._(
        screenshotFolder: screenshotFolder,
        imageId: imageId,
        time: json[_jsonTimeKey],
        annotationText: json[_jsonTextKey],
        drawingData: json[_jsonDrawingKey]);
  }

  factory ScreenshotEntry.create({
    required String screenshotFolder,
    required int imageId,
    required Duration time,
  }) =>
      ScreenshotEntry._(
          screenshotFolder: screenshotFolder,
          imageId: imageId,
          time: time,
          annotationText: '',
          drawingData: '');
}
