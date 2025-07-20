import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:endoscopy_ai/pages/patient_registration/patient_registartion_view.dart';
import 'package:endoscopy_ai/pages/patient_registration/patient_registration_model.dart';
import 'package:flutter/material.dart';

// Страница с воспроизведением видео с файла
class PatientRegistrationPage extends StatefulWidget {
  final String _nextRoute;

  // Если не null, то копируем этот файл
  final String? copyFrom;
  const PatientRegistrationPage(this._nextRoute, {super.key, this.copyFrom});

  @override
  State<PatientRegistrationPage> createState() =>
      _PatientRegistrationState(_nextRoute, copyFrom);
}

class _PatientRegistrationState extends State<PatientRegistrationPage> {
  late final PatientRegistrationModel _model;
  late final PatientRegistrationViewState _view;

  _PatientRegistrationState(String nextRoute, String? copyFrom) {
    _model = PatientRegistrationModel(nextRoute, copyFrom);
    _view = PatientRegistrationViewState(_model, setState);
  }

  @override
  Widget build(BuildContext context) {
    return _view.build(context);
  }
}
