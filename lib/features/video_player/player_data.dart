import 'package:endoscopy_ai/features/storage_system/record_entry.dart';

class PlayerData {
  final RecordEntry recordEntry;
  String get filePath => recordEntry.videoPath;
  String get screenshotPath => recordEntry.screenshotFolder;

  PlayerData(this.recordEntry);
}
