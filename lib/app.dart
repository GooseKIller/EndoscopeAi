// ====================================================
//  Главное окно приложения, на котором производится отрисовка
// ====================================================
import 'package:endoscopy_ai/features/patient/record_data.dart';
import 'package:endoscopy_ai/pages/patient_registration/patient_registration_page.dart';

import 'routes.dart';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:endoscopy_ai/shared/camera/windows_camera_helper.dart';

import 'pages/pages.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  List<CameraDescription> cameras = [];
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  @override
  void dispose() {
    // Dispose all cameras when app is shutting down
    WindowsCameraHelper.disposeAllCameras();
    super.dispose();
  }

  // Получение списка доступных камер
  Future<void> _initializeCameras() async {
    try {
      cameras = await availableCameras();
      setState(() {
        _isCameraInitialized = true;
        _hasCameraError = cameras.isEmpty;
      });
    } catch (e) {
      print('Error initializing cameras: $e');
      setState(() {
        _hasCameraError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EncodescopeAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 90, 6, 201),
        ),
      ),
      initialRoute: Routes.root,
      routes: {
        Routes.recordings: (context) => RecordingsPage(),
        Routes.homePage: (context) => const HomePage(),
        Routes.fileVideoPlayer: (context) => FileVidePlayerPage(
            //ModalRoute.of(context)!.settings.arguments as RecordData,
            ModalRoute.of(context)!.settings.arguments as String),
        Routes.patientRegistration: (context) =>
            PatientRegistrationPage(
              ModalRoute.of(context)!.settings.arguments as String
            ),

        Routes.streamVideoPlayer: (context) {
          if (!_isCameraInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (_hasCameraError || cameras.isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text('Ошибка камеры')),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.videocam_off, size: 50),
                    const SizedBox(height: 20),
                    const Text('Камера недоступна'),
                    TextButton(
                      onPressed: _initializeCameras,
                      child: const Text('Повторить попытку'),
                    ),
                  ],
                ),
              ),
            );
          }
          return StreamPage(camera: cameras.first, ModalRoute.of(context)!.settings.arguments as RecordData);
        },
        Routes.annotate: (context) {
          final path = ModalRoute.of(context)!.settings.arguments as String;
          return AnnotatePage(imagePath: path);
        },
      },
    );
  }
}
