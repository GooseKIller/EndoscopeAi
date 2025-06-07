import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:path/path.dart' as p;

class FilePicker {
  static String? filePath;
  static String? fileName;

  static bool checkFile() {
    if (filePath == null) {
      return false;
    }
    return true;
  }

  static Future<void> pickFile() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.video, // Или конкретный тип файла
    );
    print(result);

    if (result != null) {
      // Получаем путь к выбранному файлу
      FilePicker.filePath = result.files.single.path;
      FilePicker.fileName = p.basenameWithoutExtension(
        result.files.single.path.toString(),
      );
      // Обрабатываем выбранный файл (открываем, загружаем, и т.д.)
      print('Выбранный файл: $filePath');
    } else {
      print('Отменено пользователем');
    }
  }
}
