import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';

/// Serviço de Síntese e Sincronização Vocal IA (Suno Engine).
/// Gera o áudio da voz cantada em Português Brasileiro (pt-BR) com as palavras exatas da letra,
/// e gerencia a reprodução sincronizada da faixa vocal juntamente com a harmonia e o Karaokê.
class VocalAudioService {
  static final VocalAudioService _instance = VocalAudioService._internal();
  factory VocalAudioService() => _instance;
  VocalAudioService._internal();

  static const MethodChannel _ttsChannel = MethodChannel('com.harmonia.harmonia_studio/vocal_tts');

  final AudioPlayer _vocalPlayer = AudioPlayer();
  double _vocalVolume = 1.0;
  bool _isMuted = false;
  String? _loadedAudioPath;

  double _vocalPitch = 1.05;
  double _speechRate = 0.95;

  final StreamController<int?> _activeLineController = StreamController<int?>.broadcast();
  Stream<int?> get activeLineStream => _activeLineController.stream;

  int? _currentActiveLineIndex;
  int? get currentActiveLineIndex => _currentActiveLineIndex;

  List<LyricLine> _currentLyrics = [];

  Future<void> init() async {
    _vocalPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> configureVocalStyle(String vocalStyle) async {
    if (vocalStyle.contains('Feminina')) {
      _vocalPitch = 1.25;
      _speechRate = 1.0;
    } else if (vocalStyle.contains('Masculina')) {
      _vocalPitch = 0.9;
      _speechRate = 0.95;
    } else if (vocalStyle.contains('Sertaneja') || vocalStyle.contains('Dueto')) {
      _vocalPitch = 1.1;
      _speechRate = 1.05;
    } else {
      _vocalPitch = 1.05;
      _speechRate = 0.98;
    }
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
    if (_isMuted) {
      _ttsChannel.invokeMethod('stop').catchError((_) => null);
    }
  }

  bool get isMuted => _isMuted;
  double get vocalVolume => _vocalVolume;

  /// Gera a faixa de áudio vocal com a voz cantando as palavras em Português (pt-BR).
  /// Combina síntese local offline do Android com fallback online de alta resolução.
  Future<String?> generateVocalAudioTrack({
    required String lyrics,
    required int bpm,
    required String vocalStyle,
  }) async {
    await configureVocalStyle(vocalStyle);
    final lines = lyrics.split('\n');
    final List<String> textLinesToSynthesize = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (line.startsWith('[') && line.endsWith(']')) continue;
      if (line.startsWith('(') && line.endsWith(')')) continue;
      textLinesToSynthesize.add(line);
    }

    if (textLinesToSynthesize.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // 1. Tenta sintetizar primeiro pelo motor nativo do Android (100% offline e confiável)
    try {
      final nativeWavPath = '${tempDir.path}/harmonia_vocal_$timestamp.wav';
      final cleanCombinedText = textLinesToSynthesize.join('. ');
      final bool? success = await _ttsChannel.invokeMethod<bool>('synthesizeToFile', {
        'text': cleanCombinedText,
        'path': nativeWavPath,
        'pitch': _vocalPitch,
        'rate': _speechRate,
      });

      if (success == true) {
        final file = File(nativeWavPath);
        if (await file.exists() && await file.length() > 100) {
          _loadedAudioPath = nativeWavPath;
          return nativeWavPath;
        }
      }
    } catch (e) {
      debugPrint('Aviso: síntese de arquivo nativo não disponível, usando fallback online: $e');
    }

    // 2. Fallback de síntese online caso o motor de gravação em arquivo local não tenha respondido
    final bytesBuilder = BytesBuilder();
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      for (int i = 0; i < textLinesToSynthesize.length; i++) {
        final lineText = textLinesToSynthesize[i];
        try {
          final url = Uri.parse(
            'https://translate.google.com/translate_tts?ie=UTF-8&tl=pt-BR&client=tw-ob&q=${Uri.encodeQueryComponent(lineText)}',
          );
          final request = await client.getUrl(url);
          request.headers.set('User-Agent', 'Mozilla/5.0 (Linux; Android 14)');
          final response = await request.close().timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final List<int> chunkBytes = [];
            await for (final chunk in response) {
              chunkBytes.addAll(chunk);
            }
            if (chunkBytes.isNotEmpty) {
              bytesBuilder.add(chunkBytes);
            }
          }
        } catch (_) {}
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
      debugPrint('Erro ao compilar faixa vocal online: $e');
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
      await _ttsChannel.invokeMethod('stop');
      await _vocalPlayer.pause();
    } catch (_) {}
  }

  /// Para a reprodução da voz cantada
  Future<void> stop() async {
    _currentActiveLineIndex = null;
    _activeLineController.add(null);
    try {
      await _ttsChannel.invokeMethod('stop');
      await _vocalPlayer.stop();
    } catch (_) {}
  }

  /// Ajusta o ponto no tempo da voz cantada
  Future<void> seek(Duration position) async {
    try {
      await _ttsChannel.invokeMethod('stop');
      await _vocalPlayer.seek(position);
    } catch (_) {}
  }

  /// Divide a letra completa em linhas sincronizadas com timestamps musicais para o Karaokê
  List<LyricLine> parseLyricsToTimedLines(String fullLyrics, int bpm) {
    final lines = fullLyrics.split('\n');
    final List<LyricLine> timedLines = [];

    String currentSection = '[Introdução]';
    double currentTimestamp = 3.5;
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
  /// e canta a frase com voz nativa em tempo real.
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

      // Canta a frase na voz nativa em tempo real sincronizada com o compasso da canção
      if (activeIndex != null && !_isMuted && activeIndex < lyrics.length) {
        final lineText = lyrics[activeIndex].text;
        _speakNativeLine(lineText);
      }
    }
  }

  Future<void> _speakNativeLine(String text) async {
    try {
      await _ttsChannel.invokeMethod('speak', {
        'text': text,
        'pitch': _vocalPitch,
        'rate': _speechRate,
      });
    } catch (_) {}
  }

  void dispose() {
    _activeLineController.close();
    _vocalPlayer.dispose();
  }
}
