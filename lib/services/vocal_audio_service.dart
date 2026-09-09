import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/ai_song_model.dart';

/// Serviço Nativo de Síntese e Execução Vocal Cantada em Português (Android / iOS).
/// Utiliza o motor nativo Text-to-Speech com afinação musical e cadência rítmica
/// para cantar as estrofes geradas pela IA diretamente no alto-falante do celular.
class VocalAudioService {
  static final VocalAudioService _instance = VocalAudioService._internal();
  factory VocalAudioService() => _instance;
  VocalAudioService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  double _vocalVolume = 1.0;
  bool _isMuted = false;
  bool _isInitialized = false;

  final StreamController<int?> _activeLineController = StreamController<int?>.broadcast();
  Stream<int?> get activeLineStream => _activeLineController.stream;

  int? _currentActiveLineIndex;
  int? get currentActiveLineIndex => _currentActiveLineIndex;

  List<LyricLine> _currentLyrics = [];

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _flutterTts.setLanguage('pt-BR');
      await _flutterTts.setSpeechRate(0.42); // Cadência cantada suave
      await _flutterTts.setPitch(1.05); // Afinação padrão
      await _flutterTts.setVolume(_vocalVolume);
      _isInitialized = true;
    } catch (e) {
      debugPrint('Aviso ao inicializar FlutterTts: $e');
    }
  }

  void configureVocalStyle(String vocalStyle) {
    if (!_isInitialized) init();
    try {
      if (vocalStyle.contains('Feminina') || vocalStyle.contains('Romântica')) {
        _flutterTts.setPitch(1.22); // Tom agudo feminino suave
        _flutterTts.setSpeechRate(0.40);
      } else if (vocalStyle.contains('Masculina') || vocalStyle.contains('Piseiro') || vocalStyle.contains('Rock')) {
        _flutterTts.setPitch(0.85); // Tom encorpado masculino
        _flutterTts.setSpeechRate(0.45);
      } else if (vocalStyle.contains('Gospel') || vocalStyle.contains('Dueto')) {
        _flutterTts.setPitch(1.10); // Afinação vibrante de louvor
        _flutterTts.setSpeechRate(0.40);
      } else if (vocalStyle.contains('Sertaneja')) {
        _flutterTts.setPitch(0.95);
        _flutterTts.setSpeechRate(0.44);
      } else {
        _flutterTts.setPitch(1.0);
        _flutterTts.setSpeechRate(0.42);
      }
    } catch (e) {
      debugPrint('Erro ao configurar estilo vocal: $e');
    }
  }

  void setVocalVolume(double volume) {
    _vocalVolume = volume.clamp(0.0, 1.0);
    try {
      _flutterTts.setVolume(_isMuted ? 0.0 : _vocalVolume);
    } catch (e) {
      debugPrint('Erro ao ajustar volume vocal: $e');
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    setVocalVolume(_vocalVolume);
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
    // Duração média de cada frase
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

  /// Limpa pontuações que podem atrapalhar a dicção
  String _cleanTextForVoice(String text) {
    return text
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll('"', '')
        .replaceAll('*', '')
        .replaceAll('...', ', ')
        .trim();
  }

  /// Sincroniza e canta a frase correspondente ao timestamp exato da música
  void syncPlayback(Duration position, List<LyricLine> lyrics) {
    _currentLyrics = lyrics;
    final currentSec = position.inMilliseconds / 1000.0;

    int? activeIndex;
    LyricLine? activeLine;

    for (int i = 0; i < lyrics.length; i++) {
      final line = lyrics[i];
      final start = line.timestampSeconds;
      final end = line.timestampSeconds + line.durationSeconds;

      if (currentSec >= start && currentSec < end) {
        activeIndex = i;
        activeLine = line;
        break;
      }
    }

    if (activeIndex != _currentActiveLineIndex) {
      _currentActiveLineIndex = activeIndex;
      _activeLineController.add(activeIndex);

      if (activeLine != null && !_isMuted && _vocalVolume > 0.05) {
        _singPhrase(activeLine.text);
      }
    }
  }

  Future<void> _singPhrase(String text) async {
    final clean = _cleanTextForVoice(text);
    if (clean.isEmpty) return;

    try {
      await _flutterTts.stop();
      await _flutterTts.speak(clean);
    } catch (e) {
      debugPrint('Erro ao cantar frase: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  void dispose() {
    _flutterTts.stop();
    _activeLineController.close();
  }
}
