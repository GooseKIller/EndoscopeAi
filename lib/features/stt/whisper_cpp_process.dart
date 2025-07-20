import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

enum VoiceCmd { start, stop, snapshot, unknown }

VoiceCmd parseVoiceCmd(String raw) {
  final t = raw.toLowerCase();
  if (t.contains('start')) return VoiceCmd.start;
  if (t.contains('stop'))  return VoiceCmd.stop;
  if (t.contains('dot'))   return VoiceCmd.snapshot;
  return VoiceCmd.unknown;
}

class WhisperCppProcess {
  WhisperCppProcess({
    required this.exePath,
    required this.modelPath,
    required this.onCmd,
    this.captureId = 0,
    this.threads   = 8,
  });

  final String exePath;
  final String modelPath;
  final void Function(VoiceCmd) onCmd;
  final int captureId;
  final int threads;

  Process?                _proc;
  StreamSubscription<String>? _outSub;

  bool get isRunning => _proc != null;

  /* ────────────────────────── public ────────────────────────── */

  Future<void> start() async {
    // sanity‑check путей
    if (!File(exePath).existsSync()) {
      debugPrint('[STT] exe NOT found: $exePath');
      return;
    }
    if (!File(modelPath).existsSync()) {
      debugPrint('[STT] model NOT found: $modelPath');
      return;
    }

    final cmdFile = _ensureCmdFile();
    final args = [
      '-m', modelPath,
      '-l', 'ru',
      '-t', '$threads',
      '-c', '$captureId',
      '--commands', cmdFile,
      '--output-json',          // вместо устаревшего -oj
    ];

    _proc = await Process.start(exePath, args, runInShell: false);
    debugPrint('[STT] started pid=${_proc!.pid}');

    // читаем stdout -> JSON
    _outSub = _proc!.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine);
  }

  Future<void> stop() async {
    await _outSub?.cancel();
    _proc?.kill();
    _proc = null;
    debugPrint('[STT] stopped');
  }

  /* ────────────────────────── private ───────────────────────── */

  void _onLine(String l) {
    // whisper‑command с --output-json печатает {"text":"...", ...}
    Map<String, dynamic>? j;
    try {
      j = jsonDecode(l) as Map<String, dynamic>;
    } catch (_) {
      return; // не JSON – пропускаем
    }

    final txt = (j['text'] ?? '').toString().trim();
    if (txt.isEmpty) return;

    final cmd = parseVoiceCmd(txt);
    if (cmd != VoiceCmd.unknown) onCmd(cmd);
    // debugPrint('[STT] heard: $txt  →  $cmd');
  }

  String _ensureCmdFile() {
    // создаём temp‑файл со словами «start / stop / dot» (англ.)
    final f = File(p.join(Directory.systemTemp.path, 'ru_cmd.txt'));
    if (!f.existsSync()) {
      f.writeAsStringSync('start\nstop\ndot\n', flush: true);
    }
    return f.path;
  }
}
