import 'package:endoscopy_ai/features/patient/record_data.dart';
import 'package:endoscopy_ai/features/storage_system/record_entry.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';

class PatientRegistrationModel {
  final String nextRoute;
  late String _name = '';
  late String _surname = '';
  late int _id = -1;
  late DateTime _time = DateTime.now();

  // Если не null, то копируем этот файл
  final String? _copyFrom;

  PatientRegistrationModel(this.nextRoute, this._copyFrom);

  // Сетты
  void setName(String newValue) => _name = newValue;
  void setSurname(String newValue) => _surname = newValue;
  void setId(String newValue) => _id = int.tryParse(newValue) ?? -1;
  void setTime(DateTime newValue) => _time = newValue;

  // Собрать сохраненные данные в RecordData
  RecordData getRecordData() =>
      RecordData(name: _name, surname: _surname, id: _id, time: _time);

  // Собирает данные и создает соответсвующие папки
  Future<RecordEntry> createRecord() async {
    final record = getRecordData();
    final entry = await StorageSystem.createRecordData(record);

    if (_copyFrom != null) {
      await copyFile(_copyFrom!, entry.videoPath);
    }

    return entry;
  }
}
