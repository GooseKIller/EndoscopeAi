// ====================================================
//  Главное окно для выбора режима: запись, просмотр, импорт
// ====================================================
import 'package:flutter/material.dart';
import 'package:endoscopy_ai/routes.dart';
import 'package:endoscopy_ai/shared/file_choser.dart';
import 'package:endoscopy_ai/shared/widget/buttons.dart';
import 'package:endoscopy_ai/shared/widget/spacing.dart';

// Страница начального окна
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _disableControls = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Главная страница')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _createStreamVideoPlayerButton(context),
            createIndention(20, 15),
            _createVideoPlayerButton(context),
            createIndention(20, 15),
            _createRecordingsButton(context),
          ],
        ),
      ),
    );
  }

  // Импорт
  Widget _createVideoPlayerButton(context) {
    return ElevatedButton(
      onPressed: _disableControls
          ? null
          : () async {
              try {
                setState(() {
                  _disableControls = true;
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Открываем меню...')));
                }
                await FilePicker.pickFile();

                Navigator.pushNamed(context, Routes.patientRegistration,
                    arguments: Routes.fileVideoPlayer);
              } catch (error) {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Ошибка открытия файла'),
                    content: Text('$error'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Ok'),
                      ),
                    ],
                  ),
                );
              }

              setState(() {
                _disableControls = false;
              });
            },
      child: const Text('Открыть видеозапись'),
    );
  }

  // Запись
  Widget _createRecordingsButton(context) {
    return createRedirectButton(
      context,
      'Открыть видеоплеер',
      Routes.recordings,
      disable: _disableControls,
    );
  }

  // Просмотр
  Widget _createStreamVideoPlayerButton(context) {
    return createRedirectButton(
      context,
      'Открыть стриминговый плеер',
      Routes.patientRegistration,
      disable: _disableControls,
      arguments: Routes.streamVideoPlayer,
    );
  }
}
