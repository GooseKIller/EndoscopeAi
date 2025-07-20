// ====================================================
//  Страница для воспроизведения записанного видео
// ====================================================
import 'package:endoscopy_ai/features/video_player/player_data.dart';
import 'package:flutter/material.dart';
import 'file_video_model.dart';
import 'file_video_view.dart';
// для compute

// Страница с воспроизведением видео с файла
class FileVideoPlayerPage extends StatefulWidget {
  final PlayerData? _playerData;

  const FileVideoPlayerPage(this._playerData, {super.key});

  @override
  State<FileVideoPlayerPage> createState() =>
      _FileVideoPlayerPageState(_playerData!);
}

class _FileVideoPlayerPageState extends State<FileVideoPlayerPage> {
  late final FileVideoPlayerPageStateModel _model; // бэкенд логика
  late final FileVideoPlayerPageStateView _view; // фронтенд логика
  late final PlayerData _playerData;

  _FileVideoPlayerPageState(PlayerData? playerData) {
    if (playerData == null) {
      throw ErrorDescription("NULL RECORD DATA");
    }
    _playerData = playerData;
    _model = FileVideoPlayerPageStateModel(setState, playerData);
    _view = FileVideoPlayerPageStateView(setState, _model);
  }

  @override
  void initState() {
    super.initState();

    _model.initState();

    // Listen for controller initialization using the public future
    _model.initializationFuture?.then((_) {
      if (mounted && _model.isInitialized) {
        // Add listener only after controller is ready
        _model.controller?.addListener(_updateProgress);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _view.build(context);
  }

  // Освободить ресурсы
  @override
  void dispose() {
    // Remove listener if controller exists
    _model.controller?.removeListener(_updateProgress);
    _model.dispose();
    super.dispose();
  }

  // Обновить состояние videoplayer
  void _updateProgress() {
    if (mounted && _model.isInitialized) {
      setState(() {
        _model.currentPosition = _model.controller!.value.position;
        _model.totalDuration = _model.controller!.value.duration;
      });
    }
  }
}
