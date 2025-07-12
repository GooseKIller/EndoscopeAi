// ====================================================
//  Страница для просмотра стриммингого видео
// ====================================================

import 'package:camera/camera.dart';
import 'package:endoscopy_ai/features/video_player/player_data.dart';
import 'package:flutter/material.dart';
import 'stream_model.dart';
import 'stream_view.dart';

// Страница просмотра потокового видео с камеры
class StreamPage extends StatefulWidget {
  final CameraDescription camera; // Данные о камере
  final PlayerData _playerData;

  // `camera` - данные о камеры, с которой будет браться видеопоток
  const StreamPage(this._playerData, {super.key, required this.camera});

  @override
  State<StreamPage> createState() => _StreamPageState(_playerData);
}

class _StreamPageState extends State<StreamPage> {
  late final StreamPageModel _model;
  late final StreamPageView _view;
  bool _isModelInitialized = false;
  late final PlayerData _playerData;

  _StreamPageState(PlayerData? playerData) {
    if (playerData == null) {
      throw ErrorDescription("NULL RECORD DATA");
    }
    _playerData = playerData;
  }

  // Инициализация ресурсов
  @override
  void initState() {
    super.initState();
    _model = StreamPageModel(
      _playerData,
      widget.camera,
      setState,
    ); // создание модели
    _view = StreamPageView(
      // создание визуальной части
      model: _model,
      camera: widget.camera,
      onBackPressed: () async {
        await _model.stopRecording();
        Navigator.pop(context);
      },
    );

    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _model.initialize();
      setState(() {
        _isModelInitialized = true;
      });
    } catch (e) {
      debugPrint('Model initialization error: $e');
      // Можно добавить обработку ошибки
    }
  }

  // Освобождение ресурсов
  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // // Обработка сохраненного скриншота по пути `image`
  // void _handlePictureTaken(XFile image) {
  //   setState(
  //     () => _model.makeScreenshot(image),
  //   ); // добавляем в ленту скриншотов новую фотографию

  //   // Navigator.pushNamed(
  //   //   context,
  //   //   Routes.annotate,
  //   //   arguments: image.path,
  //   // );
  // }

  @override
  Widget build(BuildContext context) {
    if (!_isModelInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _view.build(context);
  }
}
