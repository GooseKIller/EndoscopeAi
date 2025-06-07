/*
  Record folder structure:
  - pacient_time_hash = NAME_hash
    |-[NAME].mp4
    |-[NAME].wav
    |-[NAME]_data.json
    |-screenshot_data.json
    |-screenshots/
      |-[NAME]_time_[#].png
*/

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as pth;
import 'package:uuid/uuid.dart';

const String RECORDS_PATH =
    r"C:\Users\origi\Documents\Programming\dart\RECORDS";

class PatientInfo {
  final String id;

  PatientInfo(this.id);
}

class ScreenshotData {
  final String _path;
  Duration _time;
  final int _id;

  ScreenshotData(this._path, this._id, this._time);

  String get path => _path;
  Duration get time => _time;
  int get id => _id;

  @override
  int get hashCode => id;

  @override
  bool operator ==(Object other) {
    if (other is! ScreenshotData) return false;
    ScreenshotData data = other;
    return this._id == data._id;
  }
}

String generateNameId(PatientInfo patient, DateTime time) =>
    '${patient.id}_${time.toString().replaceAll(':', 'i')}';

class RecordData {
  final String _projectPath;
  final DateTime _time;
  final PatientInfo _patientInfo;
  Set<ScreenshotData>? _screenshots;

  RecordData(this._projectPath, this._patientInfo, this._time);

  Directory get projectDirectory => Directory(_projectPath);

  String get projectPath => _projectPath;
  DateTime get time => _time;
  PatientInfo get patient => _patientInfo;
  String get videoPath => _videoFilePath;

  String get _nameId => generateNameId(patient, time);

  // Paths
  String get _videoFilePath => pth.join(projectPath, '$_nameId.mp4');
  String get _audioFilePath => pth.join(projectPath, '$_nameId.mp3');
  String get _infoFilePath => pth.join(projectPath, '${_nameId}_info.json');
  String get _screenshotFolderPath => pth.join(projectPath, 'screenshots');
  String get _screenshotDataPath =>
      pth.join(projectPath, 'screenshots_data.json');
}

// Check if foldername is valid
bool _validRecordFolderName(String path) {
  var file = Directory(path);
  return file.existsSync(); // its exist!!!
}

List<ScreenshotData> _loadScreenshots(RecordData record) {
  final screenshotFolderPath = record._screenshotFolderPath;

  final screenshotFolder = Directory(screenshotFolderPath);

  if (!screenshotFolder.existsSync()) {
    screenshotFolder.create();
    return [];
  }

  var filesIterator = screenshotFolder
      .listSync()
      .where((entity) {
        // test if file has a valid naming
        final name = record._nameId;
        final rule = RegExp(r'\d+\.\d\d\.\d\d\.\d+_\[\d+\].png');
        final fileName = pth.basename(entity.absolute.path);

        return fileName.startsWith(name) &&
            rule.firstMatch(fileName.substring(name.length)) != null;
      })
      .map((entity) {
        // parse filename and convert it to `ScreenshotData`
        final name = record._nameId;
        final ruleNumber = RegExp(r'\[\d+\]');
        final ruleTime = RegExp(r'\d+\.\d\d\.\d\d\.\d+');
        final fileName = pth.basename(entity.absolute.path);

        final parseSubstr = fileName.substring(name.length);
        String timeString = ruleTime.firstMatch(parseSubstr)![0]!;
        List<int> timeTokens = timeString
            .split('.')
            .map((x) => int.parse(x, radix: 10))
            .toList();

        String numberString = ruleNumber.firstMatch(parseSubstr)![0]!;
        numberString = numberString.substring(1, numberString.length - 2);

        final int number = int.parse(numberString, radix: 10);
        final Duration time = Duration(
          hours: timeTokens[0],
          minutes: timeTokens[1],
          seconds: timeTokens[2],
          microseconds: timeTokens[3],
        );

        return ScreenshotData(entity.absolute.path, number, time);
      });

  return filesIterator.toList();
}

RecordData _loadSingleRecord(String projectPath) {
  DateTime time;
  String lastName;

  {
    var projectTokens = pth.basename(projectPath).split('_');

    lastName = projectTokens[0];
    time = DateTime.parse(projectTokens[1].replaceAll('i', ':'));
  }

  PatientInfo info = PatientInfo(lastName);

  return RecordData(projectPath, info, time);
}

final _uuid = Uuid();
String _createDirectoryProject(String projectName) {
  String projectFolderName;
  Directory projectDirectory;

  do {
    projectFolderName = pth.join(
      RECORDS_PATH,
      projectName + '_' + _uuid.v1().substring(0, 8),
    );
    projectDirectory = Directory(projectFolderName);
  } while (projectDirectory.existsSync());

  return projectFolderName;
}

// Load all records located in `RECORDS_PATH`
List<RecordData> loadRecords() {
  var iterator = Directory(
    RECORDS_PATH,
  ).listSync().where((path) => _validRecordFolderName(path.absolute.path));

  var records = iterator
      .map((file) => _loadSingleRecord(file.absolute.path))
      .toList(growable: false);

  return records;
}

void locateRecord(RecordData data) {
  final projectPath = data.projectPath;

  OpenFile.open(projectPath);
}

void createRecordBase(PatientInfo info, {DateTime? time}) {
  time ??= DateTime.now();

  String projectFolderName = _createDirectoryProject(
    generateNameId(info, time),
  );
  Directory projectDirectory = Directory(projectFolderName);

  projectDirectory.createSync();

  final record = RecordData(projectFolderName, info, time);

  Directory(record._screenshotFolderPath).create();
  File(record._audioFilePath).create();
  File(record._infoFilePath).create();
  File(record._screenshotDataPath).create();
  File(record._videoFilePath).create();
}

void deleteRecord(RecordData data) {
  try {
    data.projectDirectory.deleteSync(recursive: true);
  } catch (e) {
    print("ERROR: $e");
  }
}

void locateScreenshots(RecordData data) {
  data._screenshots = _loadScreenshots(data).toSet();
}

(String, int) getNextScreenshot(RecordData data, Duration durr) {
  if (data._screenshots == null) {
    locateScreenshots(data);
  }

  final datas = data._screenshots!;
  final paths = datas.map((x) => pth.basename(x._path)).toSet();

  String fname;
  int id = -1;

  do {
    id++;
    fname =
        '${data._nameId}_${durr.inHours}.${durr.inMinutes % 60}.${durr.inSeconds % 60}.${durr.inMicroseconds % (1e6).floor()}_[$id].png';
  } while (paths.contains(fname));

  return (pth.join(data._screenshotFolderPath, fname), id);
}

void addScreenshot(RecordData data, String path, int id, Duration time) {
  ScreenshotData scrh = ScreenshotData(path, id, time);

  if (data._screenshots == null) {
    locateScreenshots(data);
  }

  data._screenshots!.add(scrh);
}
