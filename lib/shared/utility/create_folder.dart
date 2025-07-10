import 'dart:io';

Future<void> createFolder(Directory directory) async {
  if (!directory.existsSync()) {
    await directory.create(
        recursive: true); // recursive: true создаст все вложенные папки
    print('Папка создана: ${directory.path}');
  }
}