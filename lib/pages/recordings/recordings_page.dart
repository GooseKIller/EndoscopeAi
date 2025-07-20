import 'package:flutter/material.dart';
import 'recordings_view.dart';
import 'recordings_model.dart';

class RecordingsPage extends StatefulWidget {

  @override
  _RecordingsPageState createState() => _RecordingsPageState();
}

class _RecordingsPageState extends State<RecordingsPage> {
  late final _model;
  late final _view;

  @override
  void initState() {
    _model = RecordingsPageModel();
    _view = RecordingsPageView(_model, setState);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _view.build(context);
  }
}
