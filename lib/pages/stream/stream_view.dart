// ====================================================
//  Страница для просмотра стриммингого видео
//  Тут имплементировано взаимодействие с UI
// ====================================================

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_feed.dart';
import 'package:provider/provider.dart';
import 'package:endoscopy_ai/pages/stream/stream_model.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

//  Логика, содержащая логику, связанную с UI
class StreamPageView extends StatelessWidget {
  final StreamPageModel model;
  final CameraDescription camera; // Данные о камере

  // Ф-ия, вызываемая при нажатии на кнопку назад

  final VoidCallback onBackPressed;

  /*
    * `model` - модель с текущей страницы
    * `camera` - данные о камере, с которой будет браться видеопоток
    * `onBackPressed` - ф-ия, вызываемая при нажатии на кнопку назад
    * `onPictureTaken` - ф-ия вызываемая после сохрания изображения
  */
  const StreamPageView({
    super.key,
    required this.model,
    required this.camera,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: model,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Поток с камеры'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBackPressed,
          ),
        ),
        body: Consumer<StreamPageModel>(
          builder: (context, model, child) {
            return Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      if (model.isInitialized && model.controller != null) {
                        return CameraPreview(model.controller!);
                      } else if (!model.cameraAvailable) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.videocam_off, size: 50),
                              const SizedBox(height: 16),
                              const Text(
                                'Камера недоступна',
                                style: TextStyle(fontSize: 18),
                              ),
                              const Text(
                                'Попробуйте проверить подключение',
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  await model.reinitializeCamera();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Повторить попытку'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Инициализация камеры...'),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
                      ScreenshotFeed(onFetchScreenshots: () => model.shots),
                      const SizedBox(height: 8),
              ],
            );
          },
        ),
        // Решение для FloatingActionButton:
        // Используем Builder и Consumer для условного отображения
        floatingActionButton: FloatingActionButton(
                heroTag: 'shot_btn',
                onPressed: () {
                  model.makeScreenshot();
                },
                child: const Icon(Icons.camera_alt),
              ),

        ),
      );
  }
}
