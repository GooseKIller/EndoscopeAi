import 'package:endoscopy_ai/pages/patient_registration/patient_registration_model.dart';
import 'package:endoscopy_ai/routes.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:endoscopy_ai/shared/widget/text_field.dart';
import 'package:endoscopy_ai/shared/widget/time_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PatientRegistrationViewState {
  late final PatientRegistrationModel _model;

  PatientRegistrationViewState(this._model);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Страница регестрации пациента')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color.fromARGB(255, 194, 199, 191),
          ),
          padding: EdgeInsets.all(10),
          child: SingleChildScrollView(
              child: Padding(
                  padding: EdgeInsetsGeometry.all(10),
                  child: Shortcuts(
                    shortcuts: const <ShortcutActivator, Intent>{
                      //При нажатии на "Enter" переходим к следующему полю ввода
                      SingleActivator(LogicalKeyboardKey.enter):
                          NextFocusIntent(),
                    },
                    child: Column(
                      spacing: 20,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Данные пациента:",
                            style: const TextStyle(
                              fontSize: 23.0,
                              height: 1,
                              color: Color.fromARGB(255, 0, 0, 0),
                              fontWeight: FontWeight.bold,
                            )),
                        Form(
                            autovalidateMode: AutovalidateMode.always,
                            onChanged: () {
                              Form.of(primaryFocus!.context!).save();
                            },
                            child: Column(spacing: 10, children: [
                              CustomTextFormField(
                                  _model,
                                  "Введите id",
                                  Icons.assignment,
                                  FilteringTextInputFormatter.digitsOnly,
                                  _model.setId),
                              CustomTextFormField(
                                  _model,
                                  "Введите имя",
                                  Icons.person_rounded,
                                  FilteringTextInputFormatter.deny('/t'),
                                  _model.setName),
                              CustomTextFormField(
                                  _model,
                                  "Введите фамилию",
                                  Icons.person_rounded,
                                  FilteringTextInputFormatter.deny('/t'),
                                  _model.setSurname),
                              CustomTimeFormField(
                                  _model, "Время приёма", _model.setTime)
                            ])),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          onPressed: () {
                            //переход на страницу плеера
                            Navigator.of(context).popAndPushNamed(
                                _model.nextRoute,
                                //arguments: _model.getRecordData()
                                arguments: FilePicker.filePath
                                );
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "Далее",
                              style: const TextStyle(
                                fontSize: 20.0,
                                height: 1,
                                color: Color.fromARGB(255, 255, 255, 255),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))),
        ),
      ),
    );
  }
}
