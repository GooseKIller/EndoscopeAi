// ====================================================
//  Страница для просмотра стриммингого видео
// ====================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'models/stream_page_model.dart';
import 'views/stream_page_view.dart';
import 'package:endoscopy_ai/shared/widget/buttons.dart';

// Страница просмотра потокового видео с камеры
class StreamPage extends StatefulWidget {
  final CameraDescription camera; // Данные о камере

  // `camera` - данные о камеры, с которой будет браться видеопоток
  const StreamPage({Key? key, required this.camera}) : super(key: key);

  @override
  State<StreamPage> createState() => _StreamPageState();
}

class _StreamPageState extends State<StreamPage> {
  late final StreamPageModel _model;
  late final StreamPageView _view;
  bool _isModelInitialized = false;

  // Инициализация ресурсов
  @override
  void initState() {
    super.initState();

    _model = StreamPageModel(
      cameraDescription: widget.camera,
    ); // создание модели
    _view = StreamPageView(
      // создание визуальной части
      model: _model,
      camera: widget.camera,
      onBackPressed: () => Navigator.pop(context),
      onPictureTaken: _handlePictureTaken,
    );
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    try {
      await _model.cameraInitialized;
      if (mounted) {
        setState(() {
          _isModelInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Model initialization error: $e');
      if (mounted) {
        setState(() {
          _isModelInitialized = false;
        });
        // Показать ошибку пользователю
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка инициализации камеры: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  // Освобождение ресурсов
  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // Обработка сохраненного скриншота по пути `image`
  void _handlePictureTaken(XFile image) {
    setState(
      () => _model.saveScreenshot(image),
    ); // добавляем в ленту скриншотов новую фотографию

    // Navigator.pushNamed(
    //   context,
    //   Routes.annotate,
    //   arguments: image.path,
    // );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _view.build(context);
  }
}
