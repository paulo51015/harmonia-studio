import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record_mp3/record_mp3.dart';
import '../models/track_model.dart';
import 'synth_service.dart';

enum StudioTransportState {
  stopped,
  playing,
  recording,
}

/// Motor de Áudio Multi-pistas (DAW Audio Engine) para o Harmonia Studio.
/// Gerencia sincronização de playback, gravação simultânea, metrônomo e mixagem em tempo real.
class StudioAudioEngine extends ChangeNotifier {
  final List<TrackModel> _tracks = [];
  final Map<String, AudioPlayer> _trackPlayers = {};

  StudioTransportState _transportState = StudioTransportState.stopped;
  int _bpm = 120;
  bool _isMetronomeEnabled = true;
  Timer? _metronomeTimer;
  int _metronomeBeat = 0;

  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  Timer? _playbackTimer;
  String? _currentlyRecordingTrackId;
  String? _currentRecordingFilePath;

  List<TrackModel> get tracks => List.unmodifiable(_tracks);
  StudioTransportState get transportState => _transportState;
  bool get isPlaying => _transportState == StudioTransportState.playing;
  bool get isRecording => _transportState == StudioTransportState.recording;
  bool get isStopped => _transportState == StudioTransportState.stopped;
  int get bpm => _bpm;
  bool get isMetronomeEnabled => _isMetronomeEnabled;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  int get metronomeBeat => _metronomeBeat;

  StudioAudioEngine() {
    _initDefaultTracks();
  }

  /// Inicializa as 4 pistas padrão do projeto de estúdio.
  void _initDefaultTracks() {
    _tracks.addAll([
      TrackModel(
        id: 'track_1',
        name: 'Pista 1 - Violão Acústico',
        instrumentType: InstrumentType.guitar,
        isArmedForRec: true, // Primeira pista armada por padrão
      ),
      TrackModel(
        id: 'track_2',
        name: 'Pista 2 - Teclado / Synth',
        instrumentType: InstrumentType.keyboard,
      ),
      TrackModel(
        id: 'track_3',
        name: 'Pista 3 - Voz Principal',
        instrumentType: InstrumentType.vocals,
      ),
      TrackModel(
        id: 'track_4',
        name: 'Pista 4 - Bateria & Beat',
        instrumentType: InstrumentType.drums,
      ),
    ]);
    _initPlayers();
  }

  void _initPlayers() {
    for (final track in _tracks) {
      if (!_trackPlayers.containsKey(track.id)) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.stop);
        _trackPlayers[track.id] = player;
      }
    }
  }

  // --- CONTROLES DE PISTAS ---

  void addTrack({required String name, required InstrumentType type}) {
    final newTrack = TrackModel(
      id: 'track_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      instrumentType: type,
    );
    _tracks.add(newTrack);
    _trackPlayers[newTrack.id] = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    notifyListeners();
  }

  void removeTrack(String trackId) {
    _trackPlayers[trackId]?.dispose();
    _trackPlayers.remove(trackId);
    _tracks.removeWhere((t) => t.id == trackId);
    notifyListeners();
  }

  void toggleArmTrack(String trackId) {
    for (final track in _tracks) {
      if (track.id == trackId) {
        track.isArmedForRec = !track.isArmedForRec;
      } else {
        track.isArmedForRec = false;
      }
    }
    notifyListeners();
  }

  void setTrackVolume(String trackId, double volume) {
    final track = _tracks.firstWhere((t) => t.id == trackId);
    track.volume = volume.clamp(0.0, 1.0);
    _updateTrackPlayerVolume(track);
    notifyListeners();
  }

  void toggleMute(String trackId) {
    final track = _tracks.firstWhere((t) => t.id == trackId);
    track.isMuted = !track.isMuted;
    _updateAllPlayerVolumes();
    notifyListeners();
  }

  void toggleSolo(String trackId) {
    final track = _tracks.firstWhere((t) => t.id == trackId);
    track.isSolo = !track.isSolo;
    _updateAllPlayerVolumes();
    notifyListeners();
  }

  void _updateAllPlayerVolumes() {
    final hasSolo = _tracks.any((t) => t.isSolo);
    for (final track in _tracks) {
      final player = _trackPlayers[track.id];
      if (player == null) continue;

      if (hasSolo) {
        if (track.isSolo && !track.isMuted) {
          player.setVolume(track.volume);
        } else {
          player.setVolume(0.0);
        }
      } else {
        if (track.isMuted) {
          player.setVolume(0.0);
        } else {
          player.setVolume(track.volume);
        }
      }
    }
  }

  void _updateTrackPlayerVolume(TrackModel track) {
    final player = _trackPlayers[track.id];
    if (player == null) return;

    final hasSolo = _tracks.any((t) => t.isSolo);
    if (hasSolo) {
      if (track.isSolo && !track.isMuted) {
        player.setVolume(track.volume);
      } else {
        player.setVolume(0.0);
      }
    } else {
      if (track.isMuted) {
        player.setVolume(0.0);
      } else {
        player.setVolume(track.volume);
      }
    }
  }

  // --- METRÔNOMO ---

  void setBpm(int newBpm) {
    _bpm = newBpm.clamp(40, 240);
    if (_metronomeTimer != null && _metronomeTimer!.isActive) {
      _startMetronome();
    }
    notifyListeners();
  }

  void toggleMetronome() {
    _isMetronomeEnabled = !_isMetronomeEnabled;
    notifyListeners();
  }

  void _startMetronome() {
    _metronomeTimer?.cancel();
    _metronomeBeat = 0;

    final intervalMs = (60000 / _bpm).round();
    _metronomeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _metronomeBeat = (_metronomeBeat % 4) + 1;

      if (_isMetronomeEnabled) {
        final freq = _metronomeBeat == 1 ? 880.0 : 440.0;
        SynthService().playFrequency(freq);
      }
      notifyListeners();
    });
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _metronomeBeat = 0;
    notifyListeners();
  }

  // --- CONTROLES DE TRANSPORTE MASTER ---

  /// Inicia a reprodução simultânea de todas as pistas com áudio gravado.
  Future<void> masterPlay() async {
    if (_transportState == StudioTransportState.playing) return;

    await masterStop();
    _transportState = StudioTransportState.playing;
    _currentPosition = Duration.zero;

    _updateAllPlayerVolumes();

    for (final track in _tracks) {
      if (track.hasAudio) {
        final player = _trackPlayers[track.id];
        if (player != null) {
          try {
            await player.play(DeviceFileSource(track.filePath!));
          } catch (e) {
            debugPrint('Erro ao reproduzir faixa ${track.name}: $e');
          }
        }
      }
    }

    if (_isMetronomeEnabled) {
      _startMetronome();
    }

    _startPlaybackTimer();
    notifyListeners();
  }

  /// Inicia gravação master na pista armada com playback simultâneo das outras pistas.
  Future<bool> masterRecord() async {
    if (_transportState == StudioTransportState.recording) return true;

    final armedTrack = _tracks.firstWhere(
      (t) => t.isArmedForRec,
      orElse: () => _tracks.first,
    );

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        return false;
      }

      await masterStop();
      _transportState = StudioTransportState.recording;
      _currentlyRecordingTrackId = armedTrack.id;
      _currentPosition = Duration.zero;

      final tempDir = await getTemporaryDirectory();
      final fileName = 'track_${armedTrack.id}_${DateTime.now().millisecondsSinceEpoch}.mp3';
      _currentRecordingFilePath = '${tempDir.path}/$fileName';

      // Inicia gravação em MP3 de alta fidelidade
      RecordMp3.instance.start(_currentRecordingFilePath!, (type) {
        debugPrint('Erro no gravador MP3: $type');
      });

      _updateAllPlayerVolumes();

      for (final track in _tracks) {
        if (track.id != armedTrack.id && track.hasAudio) {
          final player = _trackPlayers[track.id];
          if (player != null) {
            try {
              await player.play(DeviceFileSource(track.filePath!));
            } catch (e) {
              debugPrint('Erro no playback de retorno: $e');
            }
          }
        }
      }

      if (_isMetronomeEnabled) {
        _startMetronome();
      }

      _startPlaybackTimer();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erro ao iniciar Master Record: $e');
      _transportState = StudioTransportState.stopped;
      notifyListeners();
      return false;
    }
  }

  /// Para a reprodução, gravação e metrônomo, salvando os dados gravados.
  Future<void> masterStop() async {
    _playbackTimer?.cancel();
    _stopMetronome();

    if (_transportState == StudioTransportState.recording) {
      try {
        RecordMp3.instance.stop();
        if (_currentRecordingFilePath != null && _currentlyRecordingTrackId != null) {
          final track = _tracks.firstWhere((t) => t.id == _currentlyRecordingTrackId);
          track.filePath = _currentRecordingFilePath;
          track.duration = _currentPosition;
          track.waveformSamples = _generateSimulatedWaveform();
          
          if (_currentPosition > _totalDuration) {
            _totalDuration = _currentPosition;
          }
        }
      } catch (e) {
        debugPrint('Erro ao finalizar gravação: $e');
      }
    }

    for (final player in _trackPlayers.values) {
      try {
        await player.stop();
      } catch (_) {}
    }

    _transportState = StudioTransportState.stopped;
    _currentlyRecordingTrackId = null;
    _currentRecordingFilePath = null;
    notifyListeners();
  }

  void _startPlaybackTimer() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _currentPosition += const Duration(milliseconds: 100);
      notifyListeners();
    });
  }

  /// Limpa todas as gravações do estúdio para reiniciar o projeto.
  Future<void> clearProject() async {
    await masterStop();
    for (final track in _tracks) {
      if (track.filePath != null) {
        try {
          final f = File(track.filePath!);
          if (await f.exists()) await f.delete();
        } catch (_) {}
      }
      track.filePath = null;
      track.duration = Duration.zero;
      track.waveformSamples.clear();
    }
    _totalDuration = Duration.zero;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  List<double> _generateSimulatedWaveform() {
    final rand = math.Random();
    final List<double> samples = [];
    for (int i = 0; i < 40; i++) {
      samples.add(0.2 + rand.nextDouble() * 0.8);
    }
    return samples;
  }

  @override
  void dispose() {
    masterStop();
    for (final player in _trackPlayers.values) {
      player.dispose();
    }
    _trackPlayers.clear();
    super.dispose();
  }
}
