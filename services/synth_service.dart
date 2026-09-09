import 'dart:math' as math;
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../models/ai_song_model.dart';

/// Sintetizador de Áudio Procedural PCM Master em tempo real.
/// Renderiza arranjos musicais completos com Harmonia (Piano/Violão), Baixo (Bassline),
/// Bateria Rítmica (Drums) e Melodia Vocal expressiva em arquivo WAV pronto para reprodução e compartilhamento.
class SynthService {
  static final SynthService _instance = SynthService._internal();
  factory SynthService() => _instance;
  SynthService._internal();

  final Map<String, Uint8List> _wavCache = {};
  final List<AudioPlayer> _playerPool = [];
  int _poolIndex = 0;
  static const int _poolSize = 4;

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

  /// Renderiza a música completa (Master Mix) com Harmonia, Baixo, Percussão e Melodia em arquivo WAV.
  Uint8List renderMasterSongWav({
    required List<String> chords,
    required List<MelodyNote> melody,
    required int bpm,
    required String genre,
    required String vocalStyle,
    bool isInstrumental = false,
  }) {
    const int sampleRate = 22050; // 22.05 kHz para síntese rápida e excelente qualidade
    final double secondsPerBeat = 60.0 / bpm;
    final double beatsPerChord = 4.0; // 1 compasso quaternário por acorde

    // Quantidade de ciclos para estruturar a música completa (Intro, Versos, Refrão, Final)
    const int numCycles = 3;
    final int totalChordsCount = chords.length * numCycles;
    final double totalSeconds = totalChordsCount * beatsPerChord * secondsPerBeat;

    final int numSamples = (sampleRate * totalSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

    // 1. Cabeçalho WAV RIFF
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

    const double twoPi = 2.0 * math.pi;
    final double chordDurationSec = beatsPerChord * secondsPerBeat;

    // Constrói linha melódica repetida para cobrir todo o arranjo
    final List<MelodyNote> fullMelody = [];
    while (fullMelody.length < (totalChordsCount * 4)) {
      fullMelody.addAll(melody);
    }

    // Calcula offsets das notas melódicas
    final List<double> melodyStartTimes = [];
    double currentMTime = 0.0;
    for (final note in fullMelody) {
      melodyStartTimes.add(currentMTime);
      currentMTime += note.durationInBeats * secondsPerBeat;
    }

    final random = math.Random(42);

    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;

      // 1. Identifica o acorde e compasso atual
      final int chordIdx = (t / chordDurationSec).floor() % chords.length;
      final String chordName = chords[chordIdx];
      final double tInChord = t % chordDurationSec;

      // 2. CAMADA DE HARMONIA (Piano / Violão Arpejado e Sustentado)
      final chordFreqs = _getChordFrequencies(chordName);
      double chordSignal = 0.0;
      final double chordEnv = math.exp(-0.8 * tInChord);

      for (int c = 0; c < chordFreqs.length; c++) {
        final f = chordFreqs[c];
        // Arpejo suave
        final double arpeggioDelay = c * 0.08;
        if (tInChord >= arpeggioDelay) {
          final double tArp = tInChord - arpeggioDelay;
          final double s = (math.sin(twoPi * f * tArp) + 0.3 * math.sin(twoPi * f * 2 * tArp)) * math.exp(-1.4 * tArp);
          chordSignal += s;
        }
      }
      chordSignal = (chordSignal / chordFreqs.length) * chordEnv * 0.35;

      // 3. CAMADA DE BAIXO (Bassline Encorpado)
      final double rootBassFreq = _getBassFrequency(chordName);
      double bassSignal = 0.0;
      final double beatInBar = (tInChord / secondsPerBeat);
      // Pulso de baixo no tempo 1 e tempo 3
      final double tInBassNote = (tInChord % (secondsPerBeat * 2));
      final double bassEnv = math.exp(-2.0 * tInBassNote);
      bassSignal = (math.sin(twoPi * rootBassFreq * t) + 0.5 * math.sin(twoPi * rootBassFreq * 2 * t)) * bassEnv * 0.40;

      // 4. CAMADA DE PERCUSSÃO / BATERIA (Drums)
      double drumSignal = 0.0;
      final double beatTime = (t % secondsPerBeat);
      final int currentBeat = ((t / secondsPerBeat).floor()) % 4; // 0, 1, 2, 3

      // Bumbo (Kick) nos tempos 0 e 2
      if (currentBeat == 0 || currentBeat == 2) {
        if (beatTime < 0.15) {
          final double kickFreq = 120.0 * math.exp(-25.0 * beatTime);
          final double kickEnv = math.exp(-18.0 * beatTime);
          drumSignal += math.sin(twoPi * kickFreq * beatTime) * kickEnv * 0.55;
        }
      }

      // Caixa / Snare nos tempos 1 e 3
      if (currentBeat == 1 || currentBeat == 3) {
        if (beatTime < 0.20) {
          final double noise = (random.nextDouble() * 2.0 - 1.0);
          final double snareTone = math.sin(twoPi * 180.0 * beatTime);
          final double snareEnv = math.exp(-16.0 * beatTime);
          drumSignal += (noise * 0.7 + snareTone * 0.3) * snareEnv * 0.45;
        }
      }

      // Chimbal (Hi-Hat) em todas as colcheias (a cada meio tempo)
      final double eighthTime = (t % (secondsPerBeat / 2));
      if (eighthTime < 0.05) {
        final double hihatNoise = (random.nextDouble() * 2.0 - 1.0);
        final double hihatEnv = math.exp(-60.0 * eighthTime);
        drumSignal += hihatNoise * hihatEnv * 0.15;
      }

      // 5. CAMADA DE MELODIA / VOCAL
      double melodySignal = 0.0;
      if (!isInstrumental) {
        // Encontra a nota ativa no tempo t
        for (int m = 0; m < melodyStartTimes.length; m++) {
          final noteStart = melodyStartTimes[m];
          final noteDur = fullMelody[m].durationInBeats * secondsPerBeat;
          if (t >= noteStart && t < (noteStart + noteDur)) {
            final double tInNote = t - noteStart;
            final double freq = fullMelody[m].frequency;
            // Vibrato expressivo (LFO 5Hz)
            final double vibrato = 1.0 + 0.015 * math.sin(twoPi * 5.0 * tInNote);
            final double modulatedFreq = freq * vibrato;

            // Envelope vocal suave
            double mEnv = 1.0;
            if (tInNote < 0.04) {
              mEnv = tInNote / 0.04;
            } else if (tInNote > (noteDur - 0.05)) {
              mEnv = (noteDur - tInNote) / 0.05;
            }

            // Síntese de formantes vocais (Harmônicos ricos)
            final double h1 = math.sin(twoPi * modulatedFreq * t);
            final double h2 = 0.45 * math.sin(twoPi * (modulatedFreq * 2) * t);
            final double h3 = 0.25 * math.sin(twoPi * (modulatedFreq * 3) * t);
            final double h4 = 0.10 * math.sin(twoPi * (modulatedFreq * 4) * t);

            melodySignal = (h1 + h2 + h3 + h4) * mEnv * 0.42;
            break;
          }
        }
      }

      // 6. MIXAGEM MASTER COM LIMITER
      final double masterMix = (chordSignal + bassSignal + drumSignal + melodySignal);
      final int pcm16 = (masterMix.clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(44 + i * 2, pcm16, Endian.little);
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
    if (clean.startsWith('D') && !clean.contains('m')) return [noteNameToFrequency('D3'), noteNameToFrequency('F#3'), noteNameToFrequency('A3')];
    if (clean.startsWith('E') && !clean.contains('m')) return [noteNameToFrequency('E3'), noteNameToFrequency('G#3'), noteNameToFrequency('B3')];
    return [noteNameToFrequency('C3'), noteNameToFrequency('G3'), noteNameToFrequency('C4')];
  }

  double _getBassFrequency(String chord) {
    final clean = chord.trim();
    if (clean.startsWith('C')) return noteNameToFrequency('C2');
    if (clean.startsWith('D')) return noteNameToFrequency('D2');
    if (clean.startsWith('E')) return noteNameToFrequency('E2');
    if (clean.startsWith('F')) return noteNameToFrequency('F2');
    if (clean.startsWith('G')) return noteNameToFrequency('G2');
    if (clean.startsWith('A')) return noteNameToFrequency('A2');
    if (clean.startsWith('B')) return noteNameToFrequency('B2');
    return noteNameToFrequency('C2');
  }

  /// Gera um arquivo WAV em memória com síntese harmônica e envelope acústico para notas individuais.
  Uint8List generatePianoPcmWav(double frequency, {double durationSeconds = 1.2}) {
    final cacheKey = '${frequency.toStringAsFixed(2)}_$durationSeconds';
    if (_wavCache.containsKey(cacheKey)) {
      return _wavCache[cacheKey]!;
    }

    const int sampleRate = 22050;
    final int numSamples = (sampleRate * durationSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

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
    for (int i = 0; i < numSamples; i++) {
      final double t = i / sampleRate;
      double envelope = t < 0.015 ? t / 0.015 : math.exp(-3.5 * (t - 0.015));

      final double s1 = math.sin(twoPi * frequency * t);
      final double s2 = 0.35 * math.sin(twoPi * (frequency * 2) * t);
      final double s3 = 0.15 * math.sin(twoPi * (frequency * 3) * t);

      final double sampleVal = (s1 + s2 + s3) * envelope * 0.8;
      final int pcm16 = (sampleVal.clamp(-1.0, 1.0) * 32767).toInt();
      byteData.setInt16(44 + i * 2, pcm16, Endian.little);
    }

    final bytes = byteData.buffer.asUint8List();
    _wavCache[cacheKey] = bytes;
    return bytes;
  }

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

  Uint8List renderChordsTrackWav(List<String> chords, int bpm) {
    const int sampleRate = 22050;
    final double secondsPerBeat = 60.0 / bpm;
    final double beatsPerChord = 4.0;
    final double totalSeconds = chords.length * beatsPerChord * secondsPerBeat;

    final int numSamples = (sampleRate * totalSeconds).toInt();
    final ByteData byteData = ByteData(44 + numSamples * 2);

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

  Future<void> playNote(String noteName) async {
    init();
    final freq = noteNameToFrequency(noteName);
    await playFrequency(freq);
  }

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
