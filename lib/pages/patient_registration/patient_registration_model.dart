import 'package:endoscopy_ai/features/patient/record_data.dart';

class PatientRegistrationModel {
  final String nextRoute;
  late String _name = '';
  late String _surname = '';
  late int _id = -1;
  late DateTime _time = DateTime.now();

  PatientRegistrationModel(this.nextRoute);

  void setName(String newValue) => _name = newValue;
  void setSurname(String newValue) => _surname = newValue;
  void setId(String newValue) => _id = int.tryParse(newValue) ?? -1;
  void setTime(DateTime newValue) => _time = newValue;

  RecordData getRecordData() =>
      RecordData(name: _name, surname: _surname, id: _id, time: _time);
}
