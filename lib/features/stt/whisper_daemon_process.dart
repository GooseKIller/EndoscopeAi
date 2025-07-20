import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

/// Команды
enum VoiceCmd { start, stop, snapshot, unknown }

VoiceCmd parseVoiceCmd(String raw) {
  final t = raw.toLowerCase();
  bool any(List<String> ws) => ws.any((w) => t.contains(w));
  if (any(['старт записи', 'старт', 'начать', 'поехали'])) return VoiceCmd.start;
  if (any(['стоп записи', 'стоп', 'останов', 'конец'])) return VoiceCmd.stop;
  if (any(['точка', 'скрин', 'скриншот', 'снимок', 'кадр'])) return VoiceCmd.snapshot;
  return VoiceCmd.unknown;
}

/// Процесс Whisper STT: Python сам пишет микрофон и печатает текст.
/// Мы только запускаем и слушаем stdout.
class WhisperDaemonProcess {
  WhisperDaemonProcess({
    required this.onText,
    this.model = 'small', // tiny/base/small
    this.assetScriptPath = 'assets/stt/stt_daemon.py',
    this.pythonFallbacks = const ['python', 'python3', 'py'],
    this.chunkSec = 2,
    this.sampleRate = 16000,
    this.lang = 'ru',
    this.deviceIndex,
  });

  final void Function(String text) onText;
  final String model;
  final String assetScriptPath;
  final List<String> pythonFallbacks;
  final double chunkSec;
  final int sampleRate;
  final String lang;
  final int? deviceIndex; // null -> default

  Process? _proc;
  StreamSubscription<String>? _outSub;
  StreamSubscription<String>? _errSub;
  bool _started = false;

  bool get isRunning => _started && _proc != null;

  Future<void> start() async {
    if (_started) return;

    // copy python script asset to temp
    final tmpDir = await Directory.systemTemp.createTemp('stt_daemon_');
    final scriptPath = p.join(tmpDir.path, 'stt_daemon.py');
    final scriptSrc = await rootBundle.loadString(assetScriptPath);
    await File(scriptPath).writeAsString(scriptSrc);

    // find python
    final pythonPath = await _findPython();
    if (pythonPath == null) {
      debugPrint('STT: Python not found');
      return;
    }

    // env
    final env = Map<String, String>.from(Platform.environment);
    env['WHISPER_MODEL'] = model;
    env['CHUNK_SEC'] = chunkSec.toString();
    env['SAMPLE_RATE'] = sampleRate.toString();
    env['LANG'] = lang;
    if (deviceIndex != null) {
      env['DEVICE_INDEX'] = deviceIndex.toString();
    }

    // launch
    _proc = await Process.start(
      pythonPath,
      [scriptPath],
      environment: env,
      runInShell: true,
    );

    _outSub = _proc!.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen(_handleStdout);
    _errSub = _proc!.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((l) => debugPrint('STT STDERR: $l'));

    _started = true;
    debugPrint('STT daemon started pid=${_proc!.pid}');
  }

  void _handleStdout(String l) {
    if (l.startsWith('__STT_')) {
      debugPrint(l);
      return;
    }
    try {
      final j = jsonDecode(l) as Map<String, dynamic>;
      final txt = (j['text'] ?? '').toString();
      if (txt.isNotEmpty) {
        onText(txt);
      }
    } catch (_) {
      debugPrint('STT bad line: $l');
    }
  }

  Future<void> stop() async {
    await _outSub?.cancel();
    await _errSub?.cancel();
    _proc?.stdin.writeln('quit'); // politely request exit
    await _proc?.stdin.flush();
    _proc?.kill();
    _started = false;
  }

  Future<String?> _findPython() async {
    final pref = Platform.environment['PREFERRED_PYTHON'];
    if (pref != null && pref.isNotEmpty && File(pref).existsSync()) {
      return pref;
    }
    for (final name in pythonFallbacks) {
      try {
        final res = await Process.run('where', [name]);
        if (res.exitCode == 0) {
          final lines = (res.stdout as String)
              .split(RegExp(r'[\r\n]+'))
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
          for (final path in lines) {
            if (File(path).existsSync()) return path;
          }
        }
      } catch (_) {}
    }
    return null;
  }
}
