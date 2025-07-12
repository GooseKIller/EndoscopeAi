// ====================================================
//  Сиситема сохранения-загрузки данных о записях с диска
// ====================================================
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:endoscopy_ai/shared/utility/create_folder.dart';
import '../patient/record_data.dart';
import 'record_entry.dart';
import 'storage_fs_operations.dart' as sfs;
export 'storage_fs_operations.dart' show copyFile;

class StorageSystem {
  final String _storageRootFolder;

  StorageSystem._(this._storageRootFolder);

  // =========================SINGELTON===========
  static StorageSystem? _instance = null;

  // Инициализация системы:
  // инициализация папки для данных,
  //
  static Future<void> initialize() async {
    final rootPath = await sfs.generateStorageRootPath();
    await sfs.createFolderIfNotExist(rootPath);

    _instance = StorageSystem._(rootPath);
  }

  // =========================GETTERS===========
  // Возвращает путь к папке с данными приложения
  static String get storateRootPath => _instance!._storageRootFolder;
  // Возвращает папу к папке с данными приложения
  static Directory get storateRootDirecotry =>
      Directory(_instance!._storageRootFolder);

  // =========================METHODS===========
  // -------------------------CREATION----------
  // Создает папку с записями (если нужно), и возвращает RecordEntry
  static Future<RecordEntry> createRecordData(RecordData data) async {
    final recordPath = sfs.generateRecordPath(storateRootPath, data);
    await sfs.createFolderIfNotExist(recordPath);

    final recordDirectory = Directory(recordPath);
    final entry = RecordEntry(data: data, recordDirectory: recordDirectory);

    await sfs.createFolderIfNotExist(entry.screenshotFolder);

    return entry;
  }

  // Перезаписывает данные в $id.json , данные: время скиншота, аннотации
  static void updateScreenshotData(ScreenshotEntry entry) {
    final json = jsonEncode(entry.toJson());
    final data = File(entry.dataPath);

    data.writeAsStringSync(json);
  }

  // Генерирует путь к скриншоту и создает json файл где пишет его время
  static String saveScreenshot(RecordEntry entry, Duration time) {
    final screenshot = ScreenshotEntry.create(
        screenshotFolder: entry.screenshotFolder,
        imageId: entry.getNextId(),
        time: time);
    entry.addScreenshot(screenshot);
    updateScreenshotData(screenshot);
    return screenshot.imagePath;
  }

  // -------------------------LOADING-----------

  // Загружает один скриншот
  // Возвращает null если нет соответствующего json файла
  static ScreenshotEntry? loadSingleScreenshot(RecordEntry entry, int id) {
    final (image, data) =
        sfs.generateScreenshotPaths(entry.screenshotFolder, id);

    final file = File(data);
    if (!file.existsSync()) {
      print('ERROR: SCREENSHOT WITH ID $id have not data file, skipping!!!!');
      return null;
    }

    final json = jsonDecode(file.readAsStringSync());

    return ScreenshotEntry.fromJson(
        screenshotFolder: entry.screenshotFolder, imageId: id, json: json);
  }

  // Загрузка скриншотов
  static void loadScreenshots(RecordEntry entry) {
    final files =
        Directory(entry.screenshotFolder).listSync(followLinks: false);
    final image = files
        .where((entry) => sfs.isScreenshotImageName(p.basename(entry.path)))
        .map((entry) => entry.path)
        .toList();

    List<ScreenshotEntry> screenshots = [];
    for (final imgPath in image) {
      final id =
          int.parse(RegExp(r'^\d+').firstMatch(p.basename(imgPath))!.group(0)!);

      final scr = loadSingleScreenshot(entry, id);
      if (scr != null) {
        screenshots.add(scr);
      }
    }

    entry.setScreenshots(screenshots);
  }

  // Проходится по папкам и получение записей
  static Future<List<RecordEntry>> listRecords() async {
    final rootDirectory = storateRootDirecotry;
    final entries = <RecordEntry>[];

    // все пациенты
    final patients = (await rootDirectory.list(followLinks: false).toList())
        .where(
          (entry) =>
              sfs.isPatientFolderName(p.basename(entry.path)) &&
              Directory(entry.path).existsSync(),
        )
        .toList();

    // проход по всем пациентам
    for (final patientDir in patients) {
      // парсинг id
      final folderName = p.basename(patientDir.path);
      final patientId = int.parse(
        RegExp(r'\d+$').firstMatch(folderName)!.group(0)!,
      );

      // все записи пациента
      final records =
          (await Directory(patientDir.path).list(followLinks: false).toList())
              .where(
                (entry) =>
                    sfs.isPatientRecordFolderName(p.basename(entry.path)) &&
                    Directory(entry.path).existsSync(),
              )
              .toList();

      // проход по всем записям пациента
      for (final recordDir in records) {
        // парсинг даты (нет блин нетя)
        final recordDirectory = Directory(recordDir.path);
        final String recordFolderName = p.basename(recordDir.path);
        final tokens = recordFolderName.split('-').map(int.parse).toList();
        final date = DateTime(
          tokens[0],
          tokens[1],
          tokens[2],
          tokens[3],
          tokens[4],
        );

        entries.add(
          RecordEntry(
              data: RecordData(id: patientId, time: date),
              recordDirectory: recordDirectory),
        );
      }
    }

    entries.sort((a, b) => a.data.time.compareTo(b.data.time));
    return entries;
  }

  // -------------------------OTHER-------------
}
