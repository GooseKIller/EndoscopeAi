import 'package:endoscopy_ai/pages/patient_registration/patient_registration_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// Взято с https://api.flutter.dev/flutter/cupertino/CupertinoDatePicker-class.html

class CustomTimeFormField extends StatefulWidget {
    late final PatientRegistrationModel _model;
  late final String _text;
  final void Function(DateTime) _onSave;

  CustomTimeFormField(this._model, this._text, this._onSave, {super.key});

  @override
  State<CustomTimeFormField> createState() => _CustomTimeFormFieldState(_text, _onSave);
}

class _CustomTimeFormFieldState extends State<CustomTimeFormField>{
  late final String _text;
  DateTime time;
  final void Function(DateTime) _onSave;

  _CustomTimeFormFieldState(this._text, this._onSave)
      : time = DateTime.now();

  // This function displays a CupertinoModalPopup with a reasonable fixed height
  // which hosts CupertinoDatePicker.
  void _showDialog(BuildContext context, Widget child) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext context) => Container(
        height: 210,
        padding: const EdgeInsets.only(top: 6.0),
        // The Bottom margin is provided to align the popup above the system
        // navigation bar.
        margin:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        // Provide a background color for the popup.
        color: CupertinoColors.systemBackground.resolveFrom(context),
        // Use a SafeArea widget to avoid system overlaps.
        child: SafeArea(top: false, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DatePickerItem(
      children: <Widget>[
        Icon(Icons.access_time_filled_rounded),
        Text(
          _text,
          style: const TextStyle(
            fontSize: 22.0,
            height: 0,
            color: Color.fromARGB(255, 0, 0, 0),
          ),
        ),
        CupertinoButton(
          padding: EdgeInsets.only(left: 0),
          // Display a CupertinoDatePicker in time picker mode.
          onPressed: () => _showDialog(
            context,
            CupertinoDatePicker(
              initialDateTime: time,
              use24hFormat: true,
              // This is called when the user changes the time.. 
              onDateTimeChanged: (DateTime newValue) => setState(() {time = newValue; _onSave(newValue);}),
            ),
          ),
          // In this example, the time value is formatted manually.
          // You can use the intl package to format the value based on
          // the user's locale settings.
          child: Text(
            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 22.0,
              height: 0,
              color: Color.fromARGB(255, 71, 69, 69),
            ),
          ),
        ),
      ],
    );
  }
}

// This class simply decorates a row of widgets.
class _DatePickerItem extends StatelessWidget {
  const _DatePickerItem({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromARGB(255, 233, 230, 230),
        border: Border.all(width: 1),
      ),
      child: SizedBox(
        width: 250,
        child: Row(
            spacing: 10, mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
