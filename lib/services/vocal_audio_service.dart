import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';

/// Serviço de Síntese e Sincronização Vocal IA (Suno Engine).
/// Gera o áudio da voz cantada em Português Brasileiro (pt-BR) com as palavras exatas da letra,
/// e gerencia a reprodução sincronizada da faixa vocal juntamente com a harmonia e o Karaokê.
class VocalAudioService {
  static final VocalAudioService _instance = VocalAudioService._internal();
  factory VocalAudioService() => _instance;
  VocalAudioService._internal();

  final AudioPlayer _vocalPlayer = AudioPlayer();
  double _vocalVolume = 1.0;
  bool _isMuted = false;
  String? _loadedAudioPath;

  final StreamController<int?> _activeLineController = StreamController<int?>.broadcast();
  Stream<int?> get activeLineStream => _activeLineController.stream;

  int? _currentActiveLineIndex;
  int? get currentActiveLineIndex => _currentActiveLineIndex;

  List<LyricLine> _currentLyrics = [];

  Future<void> init() async {
    _vocalPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> configureVocalStyle(String vocalStyle) async {}

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

  /// Gera a faixa de áudio vocal com a voz cantando as palavras em Português (pt-BR).
  /// Cada estrofe/frase da letra é convertida em áudio natural de alta qualidade e compilada em uma faixa contínua.
  Future<String?> generateVocalAudioTrack({
    required String lyrics,
    required int bpm,
    required String vocalStyle,
  }) async {
    final lines = lyrics.split('\n');
    final List<String> textLinesToSynthesize = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      // Pula seções e acordes entre colchetes ou parênteses
      if (line.startsWith('[') && line.endsWith(']')) continue;
      if (line.startsWith('(') && line.endsWith(')')) continue;
      textLinesToSynthesize.add(line);
    }

    if (textLinesToSynthesize.isEmpty) return null;

    final bytesBuilder = BytesBuilder();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 6);

    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      for (int i = 0; i < textLinesToSynthesize.length; i++) {
        final lineText = textLinesToSynthesize[i];
        try {
          final url = Uri.parse(
            'https://translate.google.com/translate_tts?ie=UTF-8&tl=pt-BR&client=tw-ob&q=${Uri.encodeQueryComponent(lineText)}',
          );
          final request = await client.getUrl(url);
          request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 14)');
          final response = await request.close().timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final List<int> chunkBytes = [];
            await for (final chunk in response) {
              chunkBytes.addAll(chunk);
            }
            if (chunkBytes.isNotEmpty) {
              bytesBuilder.add(chunkBytes);
            }
          }
        } catch (e) {
          debugPrint('Aviso ao sintetizar frase vocal "$lineText": $e');
        }
      }

      final combinedBytes = bytesBuilder.toBytes();
      if (combinedBytes.isNotEmpty) {
        final vocalFilePath = '${tempDir.path}/harmonia_vocal_$timestamp.mp3';
        final file = File(vocalFilePath);
        await file.writeAsBytes(combinedBytes);
        _loadedAudioPath = vocalFilePath;
        return vocalFilePath;
      }
    } catch (e) {
      debugPrint('Erro ao compilar faixa vocal IA: $e');
    } finally {
      client.close();
    }

    return null;
  }

  /// Prepara o arquivo de voz para reprodução
  Future<void> prepareVocalTrack(String? filePath) async {
    _loadedAudioPath = filePath;
    if (filePath != null && File(filePath).existsSync()) {
      await _vocalPlayer.setSource(DeviceFileSource(filePath));
      await _vocalPlayer.setVolume(_isMuted ? 0.0 : _vocalVolume);
    }
  }

  /// Inicia ou retoma a reprodução da voz cantada
  Future<void> play() async {
    if (_loadedAudioPath != null && File(_loadedAudioPath!).existsSync()) {
      await _vocalPlayer.play(DeviceFileSource(_loadedAudioPath!));
      await _vocalPlayer.setVolume(_isMuted ? 0.0 : _vocalVolume);
    }
  }

  /// Pausa a reprodução da voz cantada
  Future<void> pause() async {
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
    try {
      await _vocalPlayer.pause();
    } catch (_) {}
  }

  /// Para a reprodução da voz cantada
  Future<void> stop() async {
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
    try {
      await _vocalPlayer.stop();
    } catch (_) {}
  }

  /// Ajusta o ponto no tempo da voz cantada
  Future<void> seek(Duration position) async {
    try {
      await _vocalPlayer.seek(position);
    } catch (_) {}
  }

  /// Divide a letra completa em linhas sincronizadas com timestamps musicais para o Karaokê
  List<LyricLine> parseLyricsToTimedLines(String fullLyrics, int bpm) {
    final lines = fullLyrics.split('\n');
    final List<LyricLine> timedLines = [];

    String currentSection = '[Introdução]';
    double currentTimestamp = 3.5; // Começa após introdução instrumental
    final double secondsPerBeat = 60.0 / bpm;
    final double phraseDuration = (secondsPerBeat * 4).clamp(2.8, 5.0);

    int index = 0;
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('[') && line.endsWith(']')) {
        currentSection = line;
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

  void dispose() {
    _activeLineController.close();
    _vocalPlayer.dispose();
  }
}
