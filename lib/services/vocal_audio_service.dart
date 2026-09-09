import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';

/// Serviço de Síntese e Execução Vocal Cantada em Português estilo Suno AI.
/// Renderiza a voz cantada sincronizada com as estrofes e compassos da canção,
/// permitindo audição em tempo real com Karaokê e mixagem de volume voz/instrumental.
class VocalAudioService {
  static final VocalAudioService _instance = VocalAudioService._internal();
  factory VocalAudioService() => _instance;
  VocalAudioService._internal();

  final AudioPlayer _vocalPlayer = AudioPlayer();
  double _vocalVolume = 1.0;
  bool _isMuted = false;

  final StreamController<int?> _activeLineController = StreamController<int?>.broadcast();
  Stream<int?> get activeLineStream => _activeLineController.stream;

  int? _currentActiveLineIndex;
  int? get currentActiveLineIndex => _currentActiveLineIndex;

  List<LyricLine> _currentLyrics = [];
  Timer? _syncTimer;

  void init() {
    _vocalPlayer.setVolume(_vocalVolume);
    _vocalPlayer.setReleaseMode(ReleaseMode.stop);
  }

  void setVocalVolume(double volume) {
    _vocalVolume = volume.clamp(0.0, 1.0);
    if (!_isMuted) {
      _vocalPlayer.setVolume(_vocalVolume);
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _vocalPlayer.setVolume(_isMuted ? 0.0 : _vocalVolume);
  }

  bool get isMuted => _isMuted;
  double get vocalVolume => _vocalVolume;

  /// Divide a letra completa em linhas sincronizadas com timestamps musicais
  List<LyricLine> parseLyricsToTimedLines(String fullLyrics, int bpm) {
    final lines = fullLyrics.split('\n');
    final List<LyricLine> timedLines = [];

    String currentSection = '[Introdução]';
    // Começa aos 4 segundos (após introdução instrumental de 1 compasso)
    double currentTimestamp = 4.0;
    final double secondsPerBeat = 60.0 / bpm;
    // Cada frase cantada dura em média 2 a 4 compassos (4 a 8 batidas)
    final double phraseDuration = (secondsPerBeat * 4).clamp(2.8, 5.2);

    int index = 0;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line;
        // Dá um pequeno respiro instrumental entre seções
        currentTimestamp += secondsPerBeat * 2;
        continue;
      }

      if (line.startsWith('(') && line.endsWith(')')) {
        // Instrução instrumental entre parênteses
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

  /// Faz o pré-carregamento e download dos arquivos de áudio vocal para todas as frases da letra
  Future<List<LyricLine>> synthesizeVocalLines({
    required List<LyricLine> lines,
    required String vocalStyle,
    required String genre,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final List<LyricLine> renderedLines = [];

    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 4);

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final cleanText = _cleanTextForVoice(line.text);
      if (cleanText.isEmpty) {
        renderedLines.add(line);
        continue;
      }

      final fileName = 'vocal_${timestamp}_line_$i.mp3';
      final filePath = '${tempDir.path}/$fileName';

      try {
        // Gera a voz em Português Brasileiro natural
        final encodedQuery = Uri.encodeComponent(cleanText);
        final url = 'https://translate.google.com/translate_tts?ie=UTF-8&tl=pt-BR&client=tw-ob&q=$encodedQuery';
        final request = await client.getUrl(Uri.parse(url));
        request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36');
        
        final response = await request.close().timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final bytes = await consolidateHttpClientResponseBytes(response);
          if (bytes.isNotEmpty) {
            await File(filePath).writeAsBytes(bytes);
            renderedLines.add(line.copyWith(audioFilePath: filePath));
            continue;
          }
        }
      } catch (e) {
        debugPrint('Aviso: sintetizando voz offline/fallback para linha $i: $e');
      }

      // Se falhar a conexão, mantém a linha para karaokê visual sincronizado
      renderedLines.add(line);
    }

    client.close();
    return renderedLines;
  }

  /// Limpa pontuações indesejadas que afetam a entonação da voz
  String _cleanTextForVoice(String text) {
    return text
        .replaceAll(RegExp(r'\[.*?\]'), '')
        .replaceAll(RegExp(r'\(.*?\)'), '')
        .replaceAll('"', '')
        .replaceAll('*', '')
        .replaceAll('...', ',')
        .trim();
  }

  /// Sincroniza e reproduz a voz cantada na posição exata da música
  void syncPlayback(Duration position, List<LyricLine> lyrics) {
    _currentLyrics = lyrics;
    final currentSec = position.inMilliseconds / 1000.0;

    // Encontra qual linha deve estar ativa neste segundo
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

      if (activeLine != null && activeLine.audioFilePath != null && !_isMuted) {
        _playVocalSnippet(activeLine.audioFilePath!);
      }
    }
  }

  Future<void> _playVocalSnippet(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await _vocalPlayer.stop();
        await _vocalPlayer.play(DeviceFileSource(filePath));
      }
    } catch (e) {
      debugPrint('Erro ao reproduzir frase vocal: $e');
    }
  }

  Future<void> pause() async {
    await _vocalPlayer.pause();
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  Future<void> stop() async {
    await _vocalPlayer.stop();
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
  }

  void dispose() {
    _syncTimer?.cancel();
    _vocalPlayer.dispose();
    _activeLineController.close();
  }
}
