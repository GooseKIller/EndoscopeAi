import 'package:endoscopy_ai/pages/patient_registration/patient_registartion_view.dart';
import 'package:endoscopy_ai/pages/patient_registration/patient_registration_model.dart';
import 'package:flutter/material.dart';

// Страница с воспроизведением видео с файла
class PatientRegistrationPage extends StatefulWidget {
  const PatientRegistrationPage({super.key});

  @override
  State<PatientRegistrationPage> createState() => _PatientRegistrationState();
}

class _PatientRegistrationState extends State<PatientRegistrationPage> {
  late final PatientRegistrationModel _model;
  late final PatientRegistrationViewState _view;

  _PatientRegistrationState() {
    _model = PatientRegistrationModel();
    _view = PatientRegistrationViewState(_model);
  }

  @override
  Widget build(BuildContext context) {
    return _view.build(context);
  }
}
