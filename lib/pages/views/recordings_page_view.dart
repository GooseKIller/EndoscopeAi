// ====================================================
//  Окно просмотра записей
//  Здесь описан UI
// ====================================================
import 'package:flutter/material.dart';
import '../../shared/widget/buttons.dart';
import '../models/recordings_page_model.dart';
import 'package:path/path.dart' as p;
import '../../shared/file_choser.dart';
import '../../routes.dart';

//  Логика, содержащая логику, связанную с UI
class RecordingsPageView {
  final RecordingsPageModel _model;

  RecordingsPageView(this._model);

  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _model.initialized,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final files = _model.videos;
        return Scaffold(
          appBar: AppBar(title: const Text('Записи:')),
          body: files.isEmpty
              ? Column(
                  children: [
                    createBackHomeButton(context),
                    const Expanded(child: Center(child: Text('Нет записей'))),
                  ],
                )
              : ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, i) {
                    final f = files[i];
                    return GestureDetector(
                      onDoubleTap: () { 
                        FilePicker.open(f.path);
                        Navigator.pushNamed(context, Routes.fileVideoPlayer);
                      },
                    child: ListTile(title: Text(p.basename(f.path))),
                    );
                  },
                ),
        );
      },
    );
  }
}
