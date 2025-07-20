import 'dart:io';

Future<int> countFiles(String path) async {
  Directory directory = Directory(path);
  if (!directory.existsSync()) {
    return -1;
  }
  return directory.listSync(recursive: false, followLinks: true).length;
}