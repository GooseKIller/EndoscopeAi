import 'dart:io';

import 'package:endoscopy_ai/shared/utility/count_files.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:endoscopy_ai/shared/utility/create_folder.dart';

class StorageSystem {
  static String _systemPath = '';
  int _id;
  DateTime _operationTime;
  String _patientPath = '';
  String _filePath = '';
  String _fileName = '';

  late Future<void> _initialization;

  static String get systemPath {
    if (_systemPath != '') {
      return _systemPath;
    } else {
      createRootFolder();
      return _systemPath;
    }
  }

  StorageSystem(this._id, this._operationTime) {
    _initialization = preparePatientFolder();
  }

  static Future<void> createRootFolder() async {
    final directory = Directory(p.join(
        (await getApplicationDocumentsDirectory()).path, 'EndoscopyAI App'));
    print(directory.path);
    _systemPath = directory.path;
    await createFolder(directory);
  }

  Future<void> preparePatientFolder() async {
    final String directoryPath = p.join(systemPath, 'id_$_id');
    final Directory directory = Directory(directoryPath);
    await createFolder(directory);
    _patientPath = directoryPath;
  }

  Future<void> prepareFilePath(String file) async {
    final String directoryPath = p.join(
        systemPath,
        'id_$_id',
        '${_operationTime.day}-${_operationTime.month}-${_operationTime.year}_${_operationTime.hour}-${_operationTime.minute}',
        file);
    _patientPath = p.join(systemPath, 'id_$_id');
    final Directory directory = Directory(directoryPath);
    await createFolder(directory);
    _filePath = directoryPath;
  }

  Future<bool> createNewFileFolder() async {
    if (_fileName != '') return true;
    await _initialization; // Ensure patient folder is ready
    int ind = await countFiles(_patientPath);
    if (ind == -1) {
      return false;
    }
    int index = 0;
    if (ind > 0) {
      while (true) {
        final path = p.join(_patientPath, 'video-$ind');
        Directory directory = Directory(path);
        if (directory.existsSync()) {
          ind++;
          continue;
        } else {
          index = ind;
          break;
        }
      }
    }
    if (index == 0) {
      _fileName = 'video';
      await prepareFilePath(_fileName);
    } else {
      _fileName = 'video-$index';
      await prepareFilePath(_fileName);
    }
    return true;
  }

  String get filePath {
    return p.join(_filePath, '$_fileName.mp4');
  }

  String get screenshotPath {
    return p.join(_filePath, 'screenshot');
  }
}