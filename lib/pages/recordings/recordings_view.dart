import 'package:flutter/material.dart';
import 'recordings_model.dart';
import 'package:endoscopy_ai/routes.dart';

enum Command{
  delete,
  rename,
}

class RecordingsPageView {
  final RecordingsPageModel _model;
  final Function setState;

  RecordingsPageView(this._model, this.setState);

  bool _editMode = false;
  Set<String> _selectedPaths = {};

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Записи:')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Recording>>(
      future: _model.getRecordings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Ошибка загрузки записей'));
        }

        final recordings = snapshot.data ?? [];

        return Column(
          children: [
            Expanded(
              child: recordings.isEmpty
                  ? Center(child: Text('Нет записей'))
                  : ListView.builder(
                      itemCount: recordings.length,
                      itemBuilder: (context, index) =>
                          _buildRecordingItem(context, recordings[index]),
                    ),
            ),
            if (_editMode && _selectedPaths.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: Icon(Icons.delete),
                      label: Text('Удалить выбранные'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onPressed: () async {
                        final toDelete = recordings
                            .where((r) => _selectedPaths.contains(r.filePath))
                            .toList();
                        await _model.deleteRecordings(toDelete);
                        setState(() {
                          _selectedPaths.clear();
                          _editMode = false;
                        });
                        setState();
                      },
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    ),
          ),
        ]
      ),
    );
  }

  Widget _buildRecordingItem(BuildContext context, Recording recording) {
    final displayName =
        (recording.fileName.isNotEmpty)
            ? recording.fileName
            : 'Запись ${recording.timestamp.toString()}';
    return ListTile(
      leading: Icon(Icons.video_library, size: 40),
      title: Text(displayName),
      subtitle: Text(recording.filePath),
      trailing: PopupMenuButton<Command>(
              onSelected: (Command? command) {
                setState(() {
                  print(command);
                  switch (command){
                    case Command.delete:
                      _model.deleteRecordings([recording]);
                    case Command.rename:
                      print('Rename?');
                    case null:
                  }
                });
              },
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<Command>>[
                    PopupMenuItem<Command>(
                      value: Command.rename,
                      child: const Text('Переименовать'),
                    ),
                    PopupMenuItem<Command>(
                      value: Command.delete,
                      child: const Text('Удалить'),
                    ),
                  ],
            ),
      onTap: () => _playVideo(context, recording.filePath),
      onLongPress: () {
        setState(() {
          _editMode = true;
          _selectedPaths.add(recording.filePath);
        });
      },
    );
  }

  void _playVideo(BuildContext context, String filePath) {
    Navigator.of(context).pushNamed(
      Routes.fileVideoPlayer,
      arguments: filePath
      );
  }

}
