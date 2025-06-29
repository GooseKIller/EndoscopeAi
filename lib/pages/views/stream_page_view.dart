// ====================================================
//  Страница для просмотра стриммингого видео
//  Тут имплементировано взаимодействие с UI
// ====================================================
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:endoscopy_ai/shared/widget/screenshot_feed.dart';
import 'package:endoscopy_ai/shared/widget/spacing.dart';
import 'package:provider/provider.dart';
import 'package:endoscopy_ai/pages/models/stream_page_model.dart';
import 'package:endoscopy_ai/shared/widget/buttons.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';

//  Логика, содержащая логику, связанную с UI
class StreamPageView extends StatelessWidget {
  final StreamPageModel model;
  final CameraDescription camera; // Данные о камере

  // Ф-ия, вызываемая при нажатии на кнопку назад

  final VoidCallback onBackPressed;
  // Ф-ия, вызываемая при сохранении фотографии
  final Function(XFile) onPictureTaken;

  /*
    * `model` - модель с текущей страницы
    * `camera` - данные о камере, с которой будет браться видеопоток
    * `onBackPressed` - ф-ия, вызываемая при нажатии на кнопку назад
    * `onPictureTaken` - ф-ия вызываемая после сохрания изображения
  */
  const StreamPageView({
    Key? key,
    required this.model,
    required this.camera,
    required this.onBackPressed,
    required this.onPictureTaken,
  }) : super(key: key);

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
                  child: FutureBuilder(
                    future: model.cameraInitialized,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (model.isInitialized) {
                          return CameraPreview(model.controller);
                        }
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.videocam_off, size: 50),
                              SizedBox(height: 16),
                              Text(
                                'Камера недоступна',
                                style: TextStyle(fontSize: 18),
                              ),
                              Text(
                                'Попробуйте проверить подключение',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }
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
                    },
                  ),
                ),
                createIndention(),
                Expanded(
                  child: Column(
                    children: [
                      ScreenshotFeed(onFetchScreenshots: () => model.shots),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ListView(
                              children: [
                                for (final t in model.transcripts) Text(t),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        // Решение для FloatingActionButton:
        // Используем Builder и Consumer для условного отображения
        floatingActionButton: Builder(
          builder: (context) {
            final model = Provider.of<StreamPageModel>(context, listen: true);
            if (!model.isInitialized) return const SizedBox.shrink();
                final buttons = <Widget>[
                    FloatingActionButton(
                        heroTag: 'shot_btn',
                        onPressed: () async {
                            final image = await model.takePicture();
                            if (image != null) {
                                onPictureTaken(image);
                            }
                        },
                        child: const Icon(Icons.camera_alt),
                    ),

                ];

                void addSpace() => buttons.add(const SizedBox(height: 8));

            if (!model.recording) {
                addSpace();
                buttons.add(
                  FloatingActionButton.extended(
                    heroTag: 'start_rec_btn',
                    icon: const Icon(Icons.fiber_manual_record),
                    label: const Text('Начать видеозапись'),
                    backgroundColor: Colors.red,
                    onPressed: () async {
                      await model.startRecording();
                    },
                  ),
                );
            } else {
              addSpace();
              buttons.add(
                FloatingActionButton.extended(
                  heroTag: 'finish_rec_btn',
                  icon: const Icon(Icons.stop),
                  label: const Text('Завершить запись'),
                  backgroundColor: Colors.red,
                  onPressed: () async {
                    final recordedPath = await model.stopRecording();
                    if (recordedPath == null) return;
                    final savePath = await FilePicker.platform.saveFile(
                      dialogTitle: 'Сохранить видео',
                      // fileName: '${DateTime.now().millisecondsSinceEpoch}.mp4',
                      fileName: p.basename(recordedPath),
                      type: FileType.custom,
                      allowedExtensions: ['mp4'],
                    );
                    String finalPath = recordedPath;
                    if (savePath != null) {
                      final normalized = savePath.toLowerCase().endsWith('.mp4')
                          ? savePath
                          : '$savePath.mp4';
                      await File(recordedPath).copy(normalized);
                      finalPath = normalized;
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Сохранено в "$finalPath"'),
                        ),
                      );
                    }
                  },
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: buttons,
            );
          },
        ),
      ),
    );
  }
}
                            
