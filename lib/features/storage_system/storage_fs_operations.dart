// ====================================================
//  Функции для работы с файловой системой
// ====================================================

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../shared/utility/strings.dart';
import '../patient/record_data.dart';

// =========================ГЕНЕРАТОРЫ ПУТЕЙ========================
// Генерирует путь по которому должены лежать данные приложения
Future<String> generateStorageRootPath() async {
  final documentsDirectory = await getApplicationDocumentsDirectory();

  return p.join(documentsDirectory.path, 'EndoscopyAIApp');
}

// Получить путь к видео по папке записи `recordFolder`
String generateVideoPath(String patientPath) =>
    p.join(patientPath, 'video.mp4');

// Получить путь к скриншотам по папке записи `recordFolder`
String generateScreenshotFolderPath(String recordFolder) =>
    p.join(recordFolder, 'screenshots');

// Получить путь к папке записи
String generateRecordPath(String rootPath, RecordData record) {
  final patientFolderName = 'id_${record.id}';
  final recordFolderName = formatDateTillMinDash(record.time);

  return p.join(rootPath, patientFolderName, recordFolderName);
}

// Получить путь к файлам фото и данныхо фото по пути к папке со скриншотами
// Возвращает пару: (путь к изображению, путь к json данным)
(String, String) generateScreenshotPaths(String screenshotPath, int id) {
  final imagePath = p.join(screenshotPath, '$id.png');
  final dataPath = p.join(screenshotPath, '$id.json');
  return (imagePath, dataPath);
}

// =========================ВЕРИФИКАЦИЯ ИМЕН========================
// Проверяет является ли имя папки именем папки пациента
bool isPatientFolderName(String folderName) {
  final folderRegex = RegExp(r'^id_\d+$');

  return folderRegex.hasMatch(folderName);
}

// Проверяет является ли имя папки именем папки записи
bool isPatientRecordFolderName(String folderName) {
  final folderRegex = RegExp(r'^\d{4}\-\d{2}\-\d{2}\-\d{2}\-\d{2}$');

  return folderRegex.hasMatch(folderName);
}

// Проверяет является ли имя файа  именем криншота
bool isScreenshotImageName(String fileName) {
  final folderRegex = RegExp(r'^\d+\.png$');

  return folderRegex.hasMatch(fileName);
}

// Проверяет является ли имя файа  именем криншота
bool isScreenshotDataName(String fileName) {
  final folderRegex = RegExp(r'^\d+\.json$');

  return folderRegex.hasMatch(fileName);
}

// =========================ОПЕРАЦИИ С ФАЙЛОВОЙ СИСТЕМОЙ===========
// Создать папку если она не существует
Future<void> createFolderIfNotExist(String directoryPath) async {
  final directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    await directory.create(
        recursive: true); // recursive: true создаст все вложенные папки
    print('Папка создана: ${directory.path}');
  }
}

// Копирование файла с одного места в другое
Future<void> copyFile(String from, String to) => File(from).copy(to);
void copyFileSync(String from, String to) => File(from).copySync(to);
