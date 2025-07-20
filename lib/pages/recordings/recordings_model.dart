import 'dart:async';

import 'package:endoscopy_ai/features/storage_system/record_entry.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecordingsPageModel {
  static const _recordingsKey = 'recordings';

  Future<List<RecordEntry>> getRecordings() async {
    final recordings = await StorageSystem.listRecords();

    return recordings;
  }

  Future<void> addRecording(RecordEntry recording) async {
    await Future.delayed(Duration.zero);
    print('ADD RECORDING NOT IMPLEMENTED YET');
  }

  Future<void> deleteRecordings(List<RecordEntry> toDelete) async {
    await Future.delayed(Duration.zero);
    print('DELETE RECORDING NOT IMPLEMENTED YET');
  }
}
