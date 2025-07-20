// ====================================================
//  Инструментарий для импорта файла с помощтю системног опроводника
// ====================================================
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

// Класс для импорта/выбора файла
class FilePicker {
  static String? _filePath = '';
  static String? _fileName = '';

  static String? get filePath => _filePath;
  static String? get fileName => _fileName;

  // Проверка существования файла
  static bool checkFile() => _filePath != null;

  // Запрос системного диалогового окна для выбора файла
  // Выбранный файл будет записан в `filePath` и `fileName`
  static Future<void> pickFile() async {
    fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
      type: fp.FileType.video, // Или конкретный тип файла
    );
    print(result);

    if (result != null) {
      // Получаем путь к выбранному файлу
      FilePicker._filePath = result.files.single.path;
      FilePicker._fileName = p.basenameWithoutExtension(
        result.files.single.path.toString(),
      );
      // Обрабатываем выбранный файл (открываем, загружаем, и т.д.)
      print('Выбранный файл: $filePath');
    } else {
      print('Отменено пользователем');

      throw ErrorDescription("Операция отменена пользователем");
    }
  }
}
