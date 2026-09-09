import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ai_song_model.dart';

/// Serviço de Sincronização Vocal e Karaokê em Tempo Real.
/// Coordena a exibição das frases da letra em sincronia com os compassos da canção,
/// fornecendo o stream de linha ativa para iluminação dourada e controle de volume vocal.
class VocalAudioService {
  static final VocalAudioService _instance = VocalAudioService._internal();
  factory VocalAudioService() => _instance;
  VocalAudioService._internal();

  double _vocalVolume = 1.0;
  bool _isMuted = false;

  final StreamController<int?> _activeLineController = StreamController<int?>.broadcast();
  Stream<int?> get activeLineStream => _activeLineController.stream;

  int? _currentActiveLineIndex;
  int? get currentActiveLineIndex => _currentActiveLineIndex;

  List<LyricLine> _currentLyrics = [];

  Future<void> init() async {}

  Future<void> configureVocalStyle(String vocalStyle) async {}

  void setVocalVolume(double volume) {
    _vocalVolume = volume.clamp(0.0, 1.0);
  }

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  bool get isMuted => _isMuted;
  double get vocalVolume => _vocalVolume;

  /// Divide a letra completa em linhas sincronizadas com timestamps musicais
  List<LyricLine> parseLyricsToTimedLines(String fullLyrics, int bpm) {
    final lines = fullLyrics.split('\n');
    final List<LyricLine> timedLines = [];

    String currentSection = '[Introdução]';
    // Começa aos 3.5 segundos (após introdução instrumental de 1 compasso)
    double currentTimestamp = 3.5;
    final double secondsPerBeat = 60.0 / bpm;
    // Duração média de cada frase cantada
    final double phraseDuration = (secondsPerBeat * 4).clamp(2.8, 5.0);

    int index = 0;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line;
        // Intervalo harmônico entre seções
        currentTimestamp += secondsPerBeat * 2;
        continue;
      }

      if (line.startsWith('(') && line.endsWith(')')) {
        continue;
      }

      timedLines.add(
        LyricLine(
          index: index,
          section: currentSection,
          text: line,
          timestampSeconds: currentTimestamp,
          durationSeconds: phraseDuration,
        ),
      );

      index++;
      currentTimestamp += phraseDuration;
    }

    return timedLines;
  }

  /// Sincroniza e ilumina a frase de Karaokê correspondente ao timestamp exato da música
  void syncPlayback(Duration position, List<LyricLine> lyrics) {
    _currentLyrics = lyrics;
    final currentSec = position.inMilliseconds / 1000.0;

    int? activeIndex;

    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      final start = line.timestampSeconds;
      final end = line.timestampSeconds + line.durationSeconds;

      if (currentSec >= start && currentSec < end) {
        activeIndex = i;
        break;
      }
    }

    if (activeIndex != _currentActiveLineIndex) {
      _currentActiveLineIndex = activeIndex;
      _activeLineController.add(activeIndex);
    }
  }

  Future<void> pause() async {
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  Future<void> stop() async {
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  void dispose() {
    _activeLineController.close();
  }
}
