import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:record/record.dart';

typedef OnVoiceChunk = Future<void> Function(Uint8List bytes);

/// Пишет аудио в WAV чанки длительностью [chunkSec], передаёт каждый chunk в [onChunk].
class VoiceChunker {
  VoiceChunker({
    required this.onChunk,
    this.chunkSec = 2,
    this.sampleRate = 16000,
  });

  final OnVoiceChunk onChunk;
  final int chunkSec;
  final int sampleRate;

  final _rec = AudioRecorder();
  Timer? _timer;
  bool _running = false;
  String? _currPath;

  Future<void> start() async {
    if (_running) return;
    if (!await _rec.hasPermission()) return;
    _running = true;
    await _rolloverStart();
  }

  Future<void> _rolloverStart() async {
    if (!_running) return;
    _currPath = p.join(
      Directory.systemTemp.path,
      'stt_${DateTime.now().millisecondsSinceEpoch}.wav',
      
    );
    final path = p.join(
      Directory.systemTemp.path,
      'stt_${DateTime.now().millisecondsSinceEpoch}.wav',
    );
    _currPath = path;
    await _rec.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: sampleRate,
        bitRate: 128000,
      ),
      path: path,
    );
    _timer?.cancel();
    _timer = Timer(Duration(seconds: chunkSec), _rolloverStop);
  }

  Future<void> _rolloverStop() async {
    final path = await _rec.stop();
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        await onChunk(bytes);
        await f.delete().catchError((_) {});
      }
    }
    if (_running) {
      await _rolloverStart();
    }
  }

  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    _timer?.cancel();
    final path = await _rec.stop();
    if (path != null) {
      final f = File(path);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        await onChunk(bytes);
        await f.delete().catchError((_) {});
      }
    }
  }

  Future<void> dispose() async {
    await stop();
    await _rec.dispose();
  }
}
