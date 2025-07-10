// ====================================================
//  Файл содержит ui для отображения скриншота
// ====================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:endoscopy_ai/routes.dart'; // для навигации
import 'package:endoscopy_ai/shared/utility/strings.dart';

// Состояние, определяющее степень загрузки миниатюры
enum ScreenshotPreviewState { good, pending, error }

// Модель с данными о превьюшке кадра
class ScreenshotPreviewModel {
  final String path; // путь к PNG
  final Duration position; // время, где сделан кадр
  ScreenshotPreviewState state; // состояние загрузки

  ScreenshotPreviewModel(
    this.path,
    this.position, {
    this.state = ScreenshotPreviewState.good,
  });
}

// UI-превьюшка миниатюры скриншота
class ScreenshotPreviewView extends StatelessWidget {
  /* 
   * `model` - модель с данными о миниатюре
   * `onTap`  - действие при обычном нажатии (перемотка видео)
  */
  const ScreenshotPreviewView({
    super.key,
    required this.model,
    required this.onTap,
  });

  final ScreenshotPreviewModel model;
  final void Function(Duration) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        elevation: 1, // лёгкая «тень» карточки
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias, // обрезаем по радиусу
        child: InkWell(
          onTap: () => onTap(model.position), // перемотка видео
          onDoubleTap: () {
            // Переход по двойному нажатию
            Navigator.pushNamed(
              context,
              Routes.annotate,
              arguments: model.path,
            );
          },
          child: _createMinimalisticPreview(),
        ),
      ),
    );
  }

  // Создать миниатюру
  Widget _createMinimalisticPreview() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // миниатюра
        AspectRatio(
          aspectRatio: 16 / 9, // фиксированное соотношение сторон (16:9)
          child: _createPreview(),
        ),
        // лёгкий градиент для читаемости текста
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.60), Colors.transparent],
              ),
            ),
          ),
        ),
        // тайм-код
        Padding(
          padding: const EdgeInsets.all(6),
          child: Text(
            formatDuration(model.position),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 1, offset: Offset(0, 0))],
            ),
          ),
        ),
      ],
    );
  }

  // Создать изображение
  Widget _createPreview() {
    switch (model.state) {
      case ScreenshotPreviewState.good: // изображение успешно загружено
        return Image.file(
          File(model.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 320, // Кэшируем уменьшенную версию для списка
          cacheHeight: 180,
        );
      case ScreenshotPreviewState.pending: // изображение ещё загружается
        return const Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case ScreenshotPreviewState.error: // ошибка загрузки
        return const Center(
          child: Icon(Icons.error, color: Colors.red),
        );
    }
  }
}
