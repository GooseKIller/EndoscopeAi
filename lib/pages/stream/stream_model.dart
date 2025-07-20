// ====================================================
//  Страница для просмотра стриммингого видео
//  Тут имплементировано взаимодействие с логикой, не касающейся UI
// ====================================================

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';
import 'package:endoscopy_ai/shared/camera/windows_camera_helper.dart';
import 'package:path/path.dart' as p;
import 'package:endoscopy_ai/pages/recordings/recordings_model.dart';

class StreamPageModel with ChangeNotifier {
  final CameraDescription cameraDescription; // данные о камере
  CameraController? _controller;
  bool _isInitialized = false; // инициализированная ли камера
  bool _cameraAvailable = true; // доступна ли камера
  final List<ScreenshotPreviewModel> _shots = []; // список миниатюр
  Future<void>? _cameraInitializationFuture; // состояние инициализации камеры
  Timer? _cameraCheckTimer; // Таймер для периодической проверки
  StreamSubscription<String>? _sttSub;
  final List<String> _transcripts = [];
  bool _isRecording = false;
  bool _isPaused = false;
  late final Directory _recordingsDir;
  bool _isDisposed = false; // Флаг для предотвращения операций после dispose

  bool get recording => _isRecording;
  bool get paused => _isPaused;
  List<String> get transcripts => _transcripts;

  // Геттеры/сеттеры
  bool get isInitialized => _isInitialized;
  bool get cameraAvailable => _cameraAvailable; // Геттер для доступности камеры
  CameraController? get controller => _controller;
  List<ScreenshotPreviewModel> get shots => _shots;

  // `cameraDescription` -  данные о камере
  StreamPageModel({required this.cameraDescription}) {
    _prepareDirs();
    // Не инициализируем камеру в конструкторе, только в initialize()
  }

  // Инициализация контроллера камеры с Windows-специфичными фиксами
  Future<void> _initializeCamera() async {
    if (_isDisposed) return;

    // Если уже инициализируемся, ждем завершения
    if (_cameraInitializationFuture != null) {
      await _cameraInitializationFuture;
      return;
    }

    // Создаем новую Future для инициализации
    _cameraInitializationFuture = _performCameraInitialization();

    try {
      await _cameraInitializationFuture;
    } finally {
      _cameraInitializationFuture = null;
    }
  }

  Future<void> _performCameraInitialization() async {
    if (_isDisposed) return;

    try {
      // Полная очистка предыдущего контроллера
      await _disposeCamera();
      _controller = null;

      // Используем Windows-специфичный хелпер для инициализации
      _controller = await WindowsCameraHelper.initializeCamera(
        cameraDescription,
        resolution: ResolutionPreset.medium,
        enableAudio: true,
      );

      if (_isDisposed) {
        await _disposeCamera();
        return;
      }

      _isInitialized = true;
      _cameraAvailable = true;

      // Уведомляем слушателей на главном потоке
      if (!_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });
      }
    } catch (e) {
      final errorDescription =
          WindowsCameraHelper.getWindowsCameraErrorDescription(e);

      if (kDebugMode) {
        print('Error initializing camera: $errorDescription');
        print('Original error: $e');
      }

      _isInitialized = false;
      _cameraAvailable = false;
      await _disposeCamera();
      _controller = null;

      // Уведомляем слушателей на главном потоке
      if (!_isDisposed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_isDisposed) {
            notifyListeners();
          }
        });
      }

      // Переобертываем ошибку с понятным описанием
      throw Exception(errorDescription);
    }
  }

  Future<void> initialize() async {
    if (_isDisposed) return;
    await _initializeCamera();
    if (!_isDisposed) {
      _startCameraCheckTimer();
    }
  }

  Future<void> _prepareDirs() async {
    final base = await getApplicationDocumentsDirectory();
    _recordingsDir = Directory(p.join(base.path, 'recordings'));
    if (!await _recordingsDir.exists()) {
      await _recordingsDir.create(recursive: true);
    }
  }

  // Метод для проверки состояния камеры
  Future<void> _checkCameraAvailability() async {
    if (_isDisposed) return;

    try {
      if (!_isInitialized || _controller == null) {
        // Check if camera is available before trying to initialize
        final isAvailable = await WindowsCameraHelper.isCameraAvailable(
          cameraDescription,
        );
        if (!isAvailable) {
          _cameraAvailable = false;
          _isInitialized = false;
          notifyListeners();
          return;
        }

        await _initializeCamera();
      } else {
        // Простая проверка, можно добавить более сложную логику
        _cameraAvailable = true;
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    } catch (e) {
      _cameraAvailable = false;
      _isInitialized = false;
      if (!_isDisposed) {
        notifyListeners();
      }
    }
  }

  // Метод для принудительной переинициализации камеры
  Future<void> reinitializeCamera() async {
    if (_isDisposed) return;

    try {
      _isInitialized = false;
      _cameraAvailable = false;
      notifyListeners();

      await _disposeCamera();
      await _initializeCamera();
    } catch (e) {
      if (kDebugMode) {
        print('Error reinitializing camera: $e');
      }
      _cameraAvailable = false;
      _isInitialized = false;
      notifyListeners();
    }
  }

  // Запуск таймера для периодической проверки
  void _startCameraCheckTimer() {
    if (_isDisposed) return;

    _cameraCheckTimer?.cancel();
    _cameraCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      await _checkCameraAvailability();
    });
  }

  // Сохранение кадра в файл. Возвращает путь к этому кадру
  Future<XFile?> takePicture() async {
    if (!_isInitialized || _controller == null || _isDisposed) return null;
    try {
      return await _controller!.takePicture();
    } catch (e) {
      if (kDebugMode) {
        print('Error taking picture: $e');
      }
      return null;
    }
  }

  // Функция, которая вызвается при успешном сохранении кадра
  void saveScreenshot(XFile file) {
    if (_isDisposed) return;

    // Добавляем кадр в ленту
    _shots.add(
      ScreenshotPreviewModel(
        file.path,
        Duration.zero /* TODO: implement stopwatch */,
      ),
    );
  }

  Future<void> startRecording() async {
    if (_isRecording || !_isInitialized || _controller == null || _isDisposed) {
      return;
    }
    await _controller!.startVideoRecording();
    _isRecording = true;
    _isPaused = false;
    _transcripts.clear();
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<String?> stopRecording({String? savePath}) async {
    if (!_isRecording || _controller == null || _isDisposed) return null;
    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      _isPaused = false;
      _sttSub?.cancel();

      final outFileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
      final recordingsOut = p.join(_recordingsDir.path, outFileName);
      await File(file.path).copy(recordingsOut);
      String finalPath = recordingsOut;

      if (savePath != null) {
        await File(recordingsOut).copy(savePath);
        finalPath = savePath;
      }
      if (!_isDisposed) {
        notifyListeners();
      }
      // Автоматически добавляем запись в список записей
      await RecordingsPageModel().addRecording(
        Recording(
          filePath: finalPath,
          timestamp: DateTime.now(),
          fileName: p.basename(finalPath),
        ),
      );
      return finalPath;
    } catch (e) {
      if (kDebugMode) {
        print('Error during stopRecording: $e');
      }
      return null;
    }
  }

  // Освобождение ресурсов
  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    print('StreamPageModel disposed');

    _sttSub?.cancel();
    _cameraCheckTimer?.cancel();

    // Асинхронное освобождение ресурсов камеры
    _disposeCamera();

    _isInitialized = false;
    _isPaused = false;
    _isRecording = false;

    super.dispose();
  }

  // Безопасное освобождение ресурсов камеры
  Future<void> _disposeCamera() async {
    if (_controller == null) return;

    try {
      await WindowsCameraHelper.disposeCamera(_controller);
    } catch (e) {
      if (kDebugMode) {
        print('Error disposing camera: $e');
      }
    } finally {
      _controller = null;
    }
  }
}
