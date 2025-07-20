// lib/features/stt/deepgram_listener.dart
import 'dart:convert';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:record/record.dart';

enum VoiceCmd { start, stop, snapshot, unknown }

VoiceCmd parseVoiceCmd(String t) {
  t = t.toLowerCase();
  if (t.contains('start')) return VoiceCmd.start;
  if (t.contains('stop'))  return VoiceCmd.stop;
  if (t.contains('dot'))   return VoiceCmd.snapshot;
  return VoiceCmd.unknown;
}

class DeepgramListener {
  DeepgramListener(this.onCmd);
  final void Function(VoiceCmd) onCmd;

  final _rec = AudioRecorder();
  late DeepgramTranscription _dg;

  Future<void> start(String apiKey) async {
    // 1. микрофон PCM 16‑бит 16 кГц mono
    if (!await _rec.hasPermission()) throw 'no mic permission';
    await _rec.start(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    // 2. Deepgram streaming
    _dg = DeepgramTranscription(
      apiKey: apiKey,
      smartFormat: false,
      interimResults: true,
      language: 'en',
    );

    _dg.onTranscriptionResult.listen((evt) {
      final txt = evt.channel?.alternatives?.first.transcript ?? '';
      final cmd = parseVoiceCmd(txt);
      if (cmd != VoiceCmd.unknown) onCmd(cmd);
    });

    await _dg.start();

    // 3. передаём микрофонные чанки в Deepgram
    _rec.onStateChanged().listen((state) {});
    _rec.stream().listen((bytes) {
      _dg.send(bytes);             // отдаём raw PCM
    });
  }

  Future<void> stop() async {
    await _rec.stop();
    await _dg.finish();
  }
}
