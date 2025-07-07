// ====================================================
//  Страница для вопроизведения зяписанного видео
// ====================================================
import 'package:flutter/material.dart';
import 'file_video_model.dart';
import 'file_video_view.dart';
import '../recordings/recordings_model.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:path/path.dart' as p;

// Страница с воспроизведением видео с файла
class FileVidePlayerPage extends StatefulWidget {
  //final RecordData? _recordData;
  final String _filePath;

  const FileVidePlayerPage(//this._recordData,
   this._filePath, {super.key});

  @override
  State<FileVidePlayerPage> createState() =>
      _FileVidePlayerPageState(//_recordData,
       _filePath);
}

class _FileVidePlayerPageState extends State<FileVidePlayerPage> {
  late final _model; // бэкенд логика
  late final _view; // фронтенд логика

  _FileVidePlayerPageState(//RecordData? recordData,
   String filePath) {
    //if (recordData == null) {
    //  throw ErrorDescription("NULL RECORD DATA");
    //}
    _model = FileVideoPlayerPageStateModel(setState, filePath);
    _view = FileVidePlayerPageStateView(setState, _model);
  }

  @override
  void initState() {
    super.initState();

    _model.initState();

// Перенести в model!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    // Добавляем запись в список записей, если файл валиден
    if (FilePicker.checkFile() && FilePicker.filePath != null) {
      final filePath = FilePicker.filePath!;
      final fileName = p.basename(filePath);
      RecordingsPageModel().addRecording(
        Recording(
          filePath: filePath,
          timestamp: DateTime.now(),
          fileName: fileName,
        ),
      );
    }
    // Перенести в model!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    // Обновляем позицию каждые 100 мс
    _model.controller.addListener(_updateProgress);
  }

  @override
  Widget build(BuildContext context) {
    return _view.build(context);
  }

  // Освободть ресурсы
  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Обновить состояние videoplayer
  void _updateProgress() {
    if (mounted) {
      setState(() {
        _model.currentPosition = _model.controller.value.position;
        _model.totalDuration = _model.controller.value.duration;
      });
    }
  }
}
