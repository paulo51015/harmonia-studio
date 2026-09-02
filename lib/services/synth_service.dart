import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Sintetizador de Áudio Procedural PCM em tempo real.
/// Gera timbres de piano/sintetizador com harmônicos e envelope ADSR sem necessidade de soundfonts pesadas.
class SynthService {
  static final SynthService _instance = SynthService._internal();
  factory SynthService() => _instance;
  SynthService._internal();

  final Map<String, Uint8List> _wavCache = {};
  final List<AudioPlayer> _playerPool = [];
  int _poolIndex = 0;
  static const int _poolSize = 8; // Polifonia de até 8 vozes simultâneas

  void init() {
    if (_playerPool.isEmpty) {
      for (int i = 0; i < _poolSize; i++) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        _playerPool.add(player);
      }
    }
  }

  /// Converte o nome da nota (ex: 'C4', 'A4', 'F#4') em frequência (Hz).
  static double noteNameToFrequency(String note) {
    final noteMap = {
      'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'D#': 3, 'Eb': 3,
      'E': 4, 'F': 5, 'F#': 6, 'Gb': 6, 'G': 7, 'G#': 8,
      'Ab': 8, 'A': 9, 'A#': 10, 'Bb': 10, 'B': 11,
    };

    final reg = RegExp(r'^([A-Ga-g][#b]?)([0-8])$');
    final match = reg.firstMatch(note.trim());
    if (match != null) {
      final pitch = match.group(1)!.toUpperCase();
      final octave = int.parse(match.group(2)!);
      final semitone = noteMap[pitch] ?? 9;
      final midiNumber = (octave + 1) * 12 + semitone;
      return 440.0 * math.pow(2.0, (midiNumber - 69) / 12.0);
    }
    return 440.0;
  }

  /// Gera um arquivo WAV em memória com síntese harmônica e envelope acústico.
  Uint8List generatePianoPcmWav(double frequency, {double durationSeconds = 1.2}) {
    final cacheKey = '${frequency.toStringAsFixed(2)}_$durationSeconds';
    if (_wavCache.containsKey(cacheKey)) {
      return _wavCache[cacheKey]!;
    }

    const int sampleRate = 22050; // Otimizado para baixa latência
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

    // 1. Cabeçalho RIFF/WAVE
    // ChunkID "RIFF"
    byteData.setUint8(0, 0x52);
    byteData.setUint8(1, 0x49);
    byteData.setUint8(2, 0x46);
    byteData.setUint8(3, 0x46);
    // ChunkSize (36 + SubChunk2Size)
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    // Format "WAVE"
    byteData.setUint8(8, 0x57);
    byteData.setUint8(9, 0x41);
    byteData.setUint8(10, 0x56);
    byteData.setUint8(11, 0x45);

    // SubChunk1ID "fmt "
    byteData.setUint8(12, 0x66);
    byteData.setUint8(13, 0x6D);
    byteData.setUint8(14, 0x74);
    byteData.setUint8(15, 0x20);
    // SubChunk1Size (16 para PCM)
    byteData.setUint32(16, 16, Endian.little);
    // AudioFormat (1 = PCM)
    byteData.setUint16(20, 1, Endian.little);
    // NumChannels (1 = Mono)
    byteData.setUint16(22, 1, Endian.little);
    // SampleRate
    byteData.setUint32(24, sampleRate, Endian.little);
    // ByteRate (SampleRate * NumChannels * BitsPerSample/8)
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    // BlockAlign (NumChannels * BitsPerSample/8)
    byteData.setUint16(32, 2, Endian.little);
    // BitsPerSample (16 bits)
    byteData.setUint16(34, 16, Endian.little);

    // SubChunk2ID "data"
    byteData.setUint8(36, 0x64);
    byteData.setUint8(37, 0x61);
    byteData.setUint8(38, 0x74);
    byteData.setUint8(39, 0x61);
    // SubChunk2Size
    byteData.setUint32(40, numSamples * 2, Endian.little);

    // 2. Síntese de Harmônicos com Envelope ADSR
    const double twoPi = 2.0 * math.pi;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      // Envelope ADSR (Attack rápido + Decay exponencial simulando corda de piano)
      double envelope = 0.0;
      if (t < 0.015) {
        envelope = t / 0.015; // Attack
      } else {
        envelope = math.exp(-3.5 * (t - 0.015)); // Decay/Release
      }

      // Adição de Harmônicos (Fundamental + 2º + 3º + 4º harmônico)
      final double s1 = math.sin(twoPi * frequency * t);
      final double s2 = 0.35 * math.sin(twoPi * (frequency * 2) * t);
      final double s3 = 0.15 * math.sin(twoPi * (frequency * 3) * t);
      final double s4 = 0.05 * math.sin(twoPi * (frequency * 4) * t);

      final double sampleVal = (s1 + s2 + s3 + s4) * envelope * 0.8;
      final int pcm16 = (sampleVal.clamp(-1.0, 1.0) * 32767).toInt();

      byteData.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    final bytes = byteData.buffer.asUint8List();
    _wavCache[cacheKey] = bytes;
    return bytes;
  }

  /// Toca a nota no sintetizador imediatamente.
  Future<void> playNote(String noteName) async {
    init();
    final freq = noteNameToFrequency(noteName);
    await playFrequency(freq);
  }

  /// Toca uma frequência específica em Hz.
  Future<void> playFrequency(double frequency) async {
    init();
    try {
      final wavBytes = generatePianoPcmWav(frequency);
      final player = _playerPool[_poolIndex];
      _poolIndex = (_poolIndex + 1) % _playerPool.length;

      await player.stop();
      await player.play(BytesSource(wavBytes));
    } catch (e) {
      debugPrint('Erro ao reproduzir sintetizador: $e');
    }
  }

  void dispose() {
    for (final player in _playerPool) {
      player.dispose();
    }
    _playerPool.clear();
    _wavCache.clear();
  }
}
