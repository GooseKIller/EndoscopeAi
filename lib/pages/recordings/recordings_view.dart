import 'package:endoscopy_ai/features/storage_system/record_entry.dart';
import 'package:endoscopy_ai/features/storage_system/storage_system.dart';
import 'package:endoscopy_ai/features/video_player/player_data.dart';
import 'package:flutter/material.dart';
import 'recordings_model.dart';
import 'package:endoscopy_ai/routes.dart';

enum Command {
  delete,
  rename,
}

class RecordingsPageView {
  final RecordingsPageModel _model;
  final Function setState;

  RecordingsPageView(this._model, this.setState);

  bool _editMode = false;
  Set<RecordEntry> _selectedPaths = {};

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Записи:')),
      body: Column(children: [
        Expanded(
          child: FutureBuilder<List<RecordEntry>>(
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
                              print('ON PRESSED IS NOT IMPLEMENTED');
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
      ]),
    );
  }

  Widget _buildRecordingItem(BuildContext context, RecordEntry recording) {
    final displayName =
        'Запись пациента #${recording.data.id} в ${recording.data.time.toString()}';
    return ListTile(
      leading: Icon(Icons.video_library, size: 40),
      title: Text(displayName),
      subtitle: Text('${recording.data.id}'),
      trailing: PopupMenuButton<Command>(
        onSelected: (Command? command) {
          setState(() {
            print(command);
            switch (command) {
              case Command.delete:
                _model.deleteRecordings([recording]);
              case Command.rename:
                print('Rename?');
              case null:
            }
          });
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<Command>>[
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
      onTap: () => _playVideo(context, recording),
      onLongPress: () {
        setState(() {
          _editMode = true;
          _selectedPaths.add(recording);
        });
      },
    );
  }

  void _playVideo(BuildContext context, RecordEntry entry) {
    Navigator.of(context)
        .pushNamed(Routes.fileVideoPlayer, arguments: PlayerData(entry));
  }
}
