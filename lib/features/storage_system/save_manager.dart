import 'dart:io';

import 'package:endoscopy_ai/features/video_player/player_data.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';


class SaveManager {
  final PlayerData _data;
  late final StorageSystem _storageSystem;

  SaveManager(this._data) {
    _storageSystem = StorageSystem(_data.recordData.id, _data.recordData.time);
  }

  Future<bool> saveVideo(String file) async {
    try {
      bool result = await _storageSystem.createNewFileFolder();
      await copyFile(file, _storageSystem.filePath);
      return result;
    } catch (e) {
      print('Ошибка при сохранении файла: $e');
      return false;
    }
  }

  String get filePath => _storageSystem.filePath;

  String get screenshotPath => _storageSystem.screenshotPath;

  Future<void> prepareFolder() async => _storageSystem.createNewFileFolder();

  Future<void> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      await sourceFile.copy(destinationPath);
      print('Файл успешно скопирован из $sourcePath в $destinationPath');
    } catch (e) {
      print('Ошибка при копировании файла: $e');
    }
  }
}