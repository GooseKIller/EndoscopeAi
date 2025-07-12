import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// сделано на основе https://api.flutter.dev/flutter/material/TextFormField-class.html

class CustomTextFormField extends StatefulWidget {
  final GlobalKey<FormState> _formKey;
  final IconData _icon;
  final TextInputFormatter _formatter;
  final void Function(String) _onSave;
  final String _nameField;

  CustomTextFormField(this._formKey, this._nameField, this._icon,
      this._formatter, this._onSave,
      {super.key});
  
  GlobalKey get formKey => _formKey;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState(_nameField, _icon, _formatter, _onSave);
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  final TextEditingController _controller = TextEditingController();
  final IconData _icon;
  final TextInputFormatter _formatter;
  final void Function(String) _onSave;

  final String _nameField;
  String? forceErrorText;

  _CustomTextFormFieldState(this._nameField, this._icon,
      this._formatter, this._onSave);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Это поле не должно быть пустым';
    }
    if (value.length != value.replaceAll(' ', '').length) {
      return 'Поле $_nameField не должно содержать пробелы';
    }
    return null;
  }

  void onChanged(String value) {
    // Nullify forceErrorText if the input changed.
    if (forceErrorText != null) {
      setState(() {
        forceErrorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget._formKey,
      autovalidateMode: AutovalidateMode.always,
      onChanged: () {
        Form.of(primaryFocus!.context!).save();
      },
      child: SizedBox(
        width: 260,
        child: TextFormField(
            controller: _controller,
            inputFormatters: [_formatter],
            forceErrorText: forceErrorText,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color.fromARGB(255, 233, 230, 230),
              prefixIcon: Icon(_icon),
              hintText: _nameField,
              hintStyle: const TextStyle(
                fontSize: 22.0,
                height: 1,
                color: Color.fromARGB(255, 57, 56, 56),
              ),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsetsGeometry.all(5),
              counterText: '',
            ),
            maxLength: 256,
            maxLines: 1,
            minLines: 1,
            style: const TextStyle(
              fontSize: 20.0,
              height: 1,
              color: Color.fromARGB(255, 57, 56, 56),
            ),
            onChanged: onChanged,
            onSaved: (String? value) => (_onSave(value ?? '')),
            validator: _validator),
      ),
    );
  }
}
