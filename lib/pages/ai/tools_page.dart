import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../backend/python_service.dart';
import '../../shared/widget/buttons.dart';

class AiToolsPage extends StatefulWidget {
  const AiToolsPage({super.key});

  @override
  State<AiToolsPage> createState() => _AiToolsPageState();
}

class _AiToolsPageState extends State<AiToolsPage> {
  final _python = PythonService();
  String _sttResult = '';
  String _detectResult = '';
  bool _processingStt = false;
  bool _processingDetect = false;

  Future<void> _pickAudioAndTranscribe() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );
    if (result == null) return;
    setState(() => _processingStt = true);
    final path = result.files.single.path!;
    final text = await _python.transcribe(path);
    setState(() {
      _processingStt = false;
      _sttResult = text;
    });
  }
  Future<void> _pickVideoAndDetect() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.video);
    if (result == null) return;
    setState(() => _processingDetect = true);
    final input = result.files.single.path!;
    final out = p.join(p.dirname(input), 'annotated_${p.basename(input)}');
    await _python.processVideo(input, out);
    setState(() {
      _processingDetect = false;
      _detectResult = 'Saved annotated video to ${p.basename(out)}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI инструменты')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Распознавание речи',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _processingStt ? null : _pickAudioAndTranscribe,
                child: const Text('Выбрать WAV и распознать'),
              ),
              if (_processingStt)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              if (_sttResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_sttResult),
                ),
              const SizedBox(height: 24),
              Text(
                'Поиск аномалий',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _processingDetect ? null : _pickVideoAndDetect,
                    child: const Text('Анализ видео'),
                  ),
                ],
              ),
              if (_processingDetect)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              if (_detectResult.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(_detectResult),
                ),
              const SizedBox(height: 24),
              createBackHomeButton(context),
            ],
          ),
        ),
      ),
    );
  }
}
