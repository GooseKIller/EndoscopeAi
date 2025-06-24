 // ====================================================
 //  Страница для просмотра стриммингого видео
 //  Тут имплементировано взаимодействие с логикой, не касающейся UI
 // ====================================================
 
 import 'dart:async';
 import 'dart:io';
 
 import 'package:camera/camera.dart';
 import 'package:flutter/foundation.dart';
 import 'package:path_provider/path_provider.dart';
 import 'package:endoscopy_ai/shared/widget/screenshot_preview.dart';
 import 'package:endoscopy_ai/backend/python_service.dart';
 import 'package:path_provider/path_provider.dart';
 import 'package:path/path.dart' as p;
 import 'dart:io';
 
 class StreamPageModel with ChangeNotifier {
   final CameraDescription cameraDescription; // данные о камере
   late CameraController _controller;
   bool _isInitialized = false; // инициализированная ли камера
   bool _cameraAvailable = true; // доступна ли камера
   final List<ScreenshotPreviewModel> _shots = []; // список миниатюр
   final List<String> _recordings = []; // список записанных видео
   late final Future<void> cameraInitialized; // состояние инициализации камеры
   Timer? _cameraCheckTimer; // Таймер для периодической проверки
   final PythonService _python = const PythonService();
   StreamSubscription<String>? _sttSub;
   final List<String> _transcripts = [];
   bool _isRecording = false;
   late Directory _recordDir;

   bool get isRecording => _isRecording;
   List<String> get transcripts => _transcripts; 

   // Геттеры/сеттеры
   bool get isInitialized => _isInitialized;
   bool get cameraAvailable => _cameraAvailable; // Геттер для доступности камеры
   CameraController get controller => _controller;
   List<ScreenshotPreviewModel> get shots => _shots;
   List<String> get recordings => _recordings;
   bool get isRecording => _isRecording;
 
   // `cameraDescription` -  данные о камере
   StreamPageModel({required this.cameraDescription}) {
     cameraInitialized = _initializeCamera();
     _prepareDirs();
     _startCameraCheckTimer();
   }
 
   // Инициализация контроллера камеры
   Future<void> _initializeCamera() async {
     try {
       _controller = CameraController(
         cameraDescription,
         ResolutionPreset.medium,
         enableAudio: true,
       );
 
       await _controller.initialize();
       await _prepareDir();
       _isInitialized = true;
     } catch (e) {
       if (kDebugMode) {
         print('Error initializing camera: $e');
       }
     }
   }
 
   Future<void> initialize() async {
     await _initializeCamera();
     _startCameraCheckTimer();
   }

   Future<void> _prepareDirs() async {
    final base = await getApplicationDocumentsDirectory();
    _recordDir = Directory(p.join(base.path, 'recordings'));
    if (!await _recordDir.exists()) {
      await _recordDir.create(recursive: true);
    }
  }
 
   // Метод для проверки состояния камеры
   Future<void> _checkCameraAvailability() async {
     try {
       if (!_isInitialized) {
         await _initializeCamera();
       } else {
         // Простая проверка, можно добавить более сложную логику
         _cameraAvailable = true;
         notifyListeners();
       }
     } catch (e) {
       _cameraAvailable = false;
       _isInitialized = false;
       notifyListeners();
     }
   }
 
   // Запуск таймера для периодической проверки
   void _startCameraCheckTimer() {
     _cameraCheckTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
       await _checkCameraAvailability();
     });
   }
 
   Future<void> _prepareDir() async {
     final base = await getApplicationDocumentsDirectory();
     _recordingsDir = Directory('${base.path}/recordings');
     if (!await _recordingsDir!.exists()) {
       await _recordingsDir!.create(recursive: true);
     }
   }
 
   // Сохранение кадра в файл. Возвращает путь к этому кадру
   Future<XFile?> takePicture() async {
     if (!_isInitialized) return null;
     try {
       return await _controller.takePicture();
     } catch (e) {
       if (kDebugMode) {
         print('Error taking picture: $e');
       }
       return null;
     }
   }
 
   // Функция, которая вызвается при успешном сохранении кадра
   void saveScreenshot(XFile file) {
     // Добавляем кадр в ленту
     _shots.add(
       ScreenshotPreviewModel(
         file.path,
         Duration.zero /* TODO: implement stopwatch */,
       ),
     );
   }
 
   Future<void> startVideoRecording() async {
     if (!_isInitialized || _isRecording) return;
     try {
       await _controller.prepareForVideoRecording();
       await _controller.startVideoRecording();
       _isRecording = true;
       notifyListeners();
     } catch (e) {
       if (kDebugMode) {
         print('Error starting recording: $e');
       }
     }
   }
 
   Future<XFile?> stopVideoRecording() async {
     if (!_isInitialized || !_isRecording) return null;
     try {
       final XFile file = await _controller.stopVideoRecording();
       _isRecording = false;
       final saved = await _saveRecording(file);
       _recordings.add(saved.path);
       notifyListeners();
       return saved;
     } catch (e) {
       if (kDebugMode) {
         print('Error stopping recording: $e');
       }
       return null;
     }
   }
 
   Future<XFile> _saveRecording(XFile file) async {
     final String name = '${DateTime.now().millisecondsSinceEpoch}.mp4';
     final String path = '${_recordingsDir!.path}/$name';
     final savedFile = await File(file.path).copy(path);
     return XFile(savedFile.path);
   }

   Future<void> startRecording() async {
    if (_isRecording || !_isInitialized) return;
    await _controller.startVideoRecording();
    _isRecording = true;
    _transcripts.clear();
    _sttSub = _python.listen().listen((t) {
      if (t.trim().isEmpty) return;
      _transcripts.add(t.trim());
      notifyListeners();
    });
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final file = await _controller.stopVideoRecording();
    _isRecording = false;
    _sttSub?.cancel();
    _python.stopListening();
    final out = p.join(
      _recordDir.path,
      '${DateTime.now().millisecondsSinceEpoch}.mp4',
    );
    await File(file.path).copy(out);
    notifyListeners();
    return out;
  }
 
   // Освобождение ресурсов
   void dispose() {
     print('StreamPageModel disposed');

     _sttSub?.cancel();
    _python.stopListening();
 
     if (_controller.value.isRecordingVideo) {
       _controller.stopVideoRecording();
     }
     _controller.dispose();
     _isInitialized = false;
     _cameraCheckTimer?.cancel();
   }
 }

