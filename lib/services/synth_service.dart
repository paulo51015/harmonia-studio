import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_song_model.dart';

/// Sintetizador de Áudio Procedural PCM em tempo real.
/// Gera timbres de piano, violão, sintetizador e percussão sem dependência de soundfonts pesadas.
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
    byteData.setUint8(0, 0x52); byteData.setUint8(1, 0x49); byteData.setUint8(2, 0x46); byteData.setUint8(3, 0x46); // RIFF
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57); byteData.setUint8(9, 0x41); byteData.setUint8(10, 0x56); byteData.setUint8(11, 0x45); // WAVE
    byteData.setUint8(12, 0x66); byteData.setUint8(13, 0x6D); byteData.setUint8(14, 0x74); byteData.setUint8(15, 0x20); // fmt
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little); // PCM
    byteData.setUint16(22, 1, Endian.little); // Mono
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint8(36, 0x64); byteData.setUint8(37, 0x61); byteData.setUint8(38, 0x74); byteData.setUint8(39, 0x61); // data
    byteData.setUint32(40, numSamples * 2, Endian.little);

    // 2. Síntese de Harmônicos com Envelope ADSR
    const double twoPi = 2.0 * math.pi;
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      double envelope = 0.0;
      if (t < 0.015) {
        envelope = t / 0.015;
      } else {
        envelope = math.exp(-3.5 * (t - 0.015));
      }

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

  /// Gera a faixa completa de melodia em WAV para a música de IA.
  Uint8List renderMelodyTrackWav(List<MelodyNote> melody, int bpm) {
    const int sampleRate = 22050;
    final double secondsPerBeat = 60.0 / bpm;

    double totalSeconds = 0.0;
    for (final n in melody) {
      totalSeconds += n.durationInBeats * secondsPerBeat;
    }
    if (totalSeconds < 1.0) totalSeconds = 4.0;

    final int numSamples = (sampleRate * totalSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

    // Header WAV
    byteData.setUint8(0, 0x52); byteData.setUint8(1, 0x49); byteData.setUint8(2, 0x46); byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57); byteData.setUint8(9, 0x41); byteData.setUint8(10, 0x56); byteData.setUint8(11, 0x45);
    byteData.setUint8(12, 0x66); byteData.setUint8(13, 0x6D); byteData.setUint8(14, 0x74); byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint8(36, 0x64); byteData.setUint8(37, 0x61); byteData.setUint8(38, 0x74); byteData.setUint8(39, 0x61);
    byteData.setUint32(40, numSamples * 2, Endian.little);

    int currentSampleOffset = 0;
    const double twoPi = 2.0 * math.pi;

    for (final note in melody) {
      final double noteDuration = note.durationInBeats * secondsPerBeat;
      final int noteSamples = (sampleRate * noteDuration).toInt();
      final double freq = note.frequency;

      for (int i = 0; i < noteSamples && (currentSampleOffset + i) < numSamples; i++) {
        final double t = i / sampleRate;
        double env = math.exp(-2.5 * t);
        if (t < 0.02) env = t / 0.02;

        final double sample = (math.sin(twoPi * freq * t) + 0.3 * math.sin(twoPi * freq * 2 * t)) * env * 0.7;
        final int pcm16 = (sample.clamp(-1.0, 1.0) * 32767).toInt();
        byteData.setInt16(44 + (currentSampleOffset + i) * 2, pcm16, Endian.little);
      }
      currentSampleOffset += noteSamples;
    }

    return byteData.buffer.asUint8List();
  }

  /// Gera a faixa de harmonia de acordes (Violão / Teclado) em WAV.
  Uint8List renderChordsTrackWav(List<String> chords, int bpm) {
    const int sampleRate = 22050;
    final double secondsPerBeat = 60.0 / bpm;
    final double beatsPerChord = 4.0; // 1 compasso por acorde
    final double totalSeconds = chords.length * beatsPerChord * secondsPerBeat;

    final int numSamples = (sampleRate * totalSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

    // Header WAV
    byteData.setUint8(0, 0x52); byteData.setUint8(1, 0x49); byteData.setUint8(2, 0x46); byteData.setUint8(3, 0x46);
    byteData.setUint32(4, 36 + numSamples * 2, Endian.little);
    byteData.setUint8(8, 0x57); byteData.setUint8(9, 0x41); byteData.setUint8(10, 0x56); byteData.setUint8(11, 0x45);
    byteData.setUint8(12, 0x66); byteData.setUint8(13, 0x6D); byteData.setUint8(14, 0x74); byteData.setUint8(15, 0x20);
    byteData.setUint32(16, 16, Endian.little);
    byteData.setUint16(20, 1, Endian.little);
    byteData.setUint16(22, 1, Endian.little);
    byteData.setUint32(24, sampleRate, Endian.little);
    byteData.setUint32(28, sampleRate * 2, Endian.little);
    byteData.setUint16(32, 2, Endian.little);
    byteData.setUint16(34, 16, Endian.little);
    byteData.setUint8(36, 0x64); byteData.setUint8(37, 0x61); byteData.setUint8(38, 0x74); byteData.setUint8(39, 0x61);
    byteData.setUint32(40, numSamples * 2, Endian.little);

    const double twoPi = 2.0 * math.pi;
    final chordDuration = beatsPerChord * secondsPerBeat;
    final chordSamples = (sampleRate * chordDuration).toInt();

    for (int c = 0; c < chords.length; c++) {
      final chordName = chords[c];
      final freqs = _getChordFrequencies(chordName);
      final offset = c * chordSamples;

      for (int i = 0; i < chordSamples && (offset + i) < numSamples; i++) {
        final double t = i / sampleRate;
        double env = math.exp(-1.5 * t);
        if (t < 0.03) env = t / 0.03;

        double sum = 0.0;
        for (final f in freqs) {
          sum += math.sin(twoPi * f * t);
        }
        final double sample = (sum / freqs.length) * env * 0.65;
        final int pcm16 = (sample.clamp(-1.0, 1.0) * 32767).toInt();
        byteData.setInt16(44 + (offset + i) * 2, pcm16, Endian.little);
      }
    }

    return byteData.buffer.asUint8List();
  }

  List<double> _getChordFrequencies(String chord) {
    final clean = chord.trim();
    if (clean.startsWith('C') && !clean.contains('m')) return [noteNameToFrequency('C3'), noteNameToFrequency('E3'), noteNameToFrequency('G3')];
    if (clean.startsWith('Dm')) return [noteNameToFrequency('D3'), noteNameToFrequency('F3'), noteNameToFrequency('A3')];
    if (clean.startsWith('Em')) return [noteNameToFrequency('E3'), noteNameToFrequency('G3'), noteNameToFrequency('B3')];
    if (clean.startsWith('F')) return [noteNameToFrequency('F3'), noteNameToFrequency('A3'), noteNameToFrequency('C4')];
    if (clean.startsWith('G')) return [noteNameToFrequency('G3'), noteNameToFrequency('B3'), noteNameToFrequency('D4')];
    if (clean.startsWith('Am')) return [noteNameToFrequency('A3'), noteNameToFrequency('C4'), noteNameToFrequency('E4')];
    return [noteNameToFrequency('C3'), noteNameToFrequency('G3'), noteNameToFrequency('C4')];
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
