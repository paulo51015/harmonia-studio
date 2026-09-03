import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

enum PitchStatus {
  idle,
  listening,
  detected,
  error,
}

class PitchData {
  final double frequency; // em Hz (ex: 440.0)
  final String noteName; // ex: 'A4', 'C#3'
  final double cents; // desvio em cents (-50 a +50)
  final double confidence; // 0.0 a 1.0
  final bool isTuned; // afinado dentro da margem de tolerância

  const PitchData({
    required this.frequency,
    required this.noteName,
    required this.cents,
    required this.confidence,
    required this.isTuned,
  });

  static const PitchData empty = PitchData(
    frequency: 0.0,
    noteName: '--',
    cents: 0.0,
    confidence: 0.0,
    isTuned: false,
  );
}

/// Serviço inteligente de Detecção de Pitch e Afinação via Microfone em tempo real.
/// Utiliza o algoritmo de Autocorrelação PCM puro em Dart para máxima precisão e compatibilidade.
class PitchService extends ChangeNotifier {
  static const int sampleRate = 44100;
  static const int bufferSize = 2048;

  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recordStreamSub;

  PitchStatus _status = PitchStatus.idle;
  PitchData _currentPitch = PitchData.empty;
  String? _errorMessage;

  PitchStatus get status => _status;
  PitchData get currentPitch => _currentPitch;
  String? get errorMessage => _errorMessage;
  bool get isListening => _status == PitchStatus.listening;

  /// Inicia a escuta contínua do microfone para análise de frequência.
  Future<bool> startListening({double? targetFrequency}) async {
    if (_status == PitchStatus.listening) return true;

    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _status = PitchStatus.error;
        _errorMessage = 'Permissão de microfone negada';
        notifyListeners();
        return false;
      }

      final audioStream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: 1,
          bitRate: 128000,
        ),
      );

      _status = PitchStatus.listening;
      _errorMessage = null;
      notifyListeners();

      List<int> sampleBuffer = [];

      _recordStreamSub = audioStream.listen(
        (data) {
          sampleBuffer.addAll(data);

          final requiredBytes = bufferSize * 2;
          while (sampleBuffer.length >= requiredBytes) {
            final chunk = Uint8List.fromList(sampleBuffer.sublist(0, requiredBytes));
            sampleBuffer = sampleBuffer.sublist(requiredBytes);

            _processPcmChunk(chunk, targetFrequency);
          }
        },
        onError: (err) {
          debugPrint('Erro no stream de áudio: $err');
          _status = PitchStatus.error;
          _errorMessage = err.toString();
          notifyListeners();
        },
      );

      return true;
    } catch (e) {
      debugPrint('Exceção ao iniciar PitchService: $e');
      _status = PitchStatus.error;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Processa o buffer PCM usando algoritmo de Autocorrelação Normalizada (YIN/ACF).
  void _processPcmChunk(Uint8List byteList, double? targetFrequency) {
    try {
      final int numSamples = byteList.length ~/ 2;
      final Float64List samples = Float64List(numSamples);

      double sumSquares = 0.0;
      for (int i = 0; i < numSamples; i++) {
        final int pcm = (byteList[i * 2] | (byteList[i * 2 + 1] << 8)).toSigned(16);
        final double val = pcm / 32768.0;
        samples[i] = val;
        sumSquares += val * val;
      }

      final double rms = math.sqrt(sumSquares / numSamples);
      if (rms < 0.02) {
        // Silêncio / ruído de fundo
        if (_currentPitch.frequency != 0) {
          _currentPitch = PitchData.empty;
          notifyListeners();
        }
        return;
      }

      // Autocorrelação para encontrar a frequência fundamental
      final int minLag = (sampleRate / 1200).round(); // ~1200 Hz
      final int maxLag = (sampleRate / 65).round(); // ~65 Hz

      double maxCorr = -1.0;
      int bestLag = -1;

      for (int lag = minLag; lag < maxLag && lag < numSamples ~/ 2; lag++) {
        double corr = 0.0;
        for (int i = 0; i < numSamples - lag; i++) {
          corr += samples[i] * samples[i + lag];
        }

        if (corr > maxCorr) {
          maxCorr = corr;
          bestLag = lag;
        }
      }

      if (bestLag > 0 && maxCorr > 0.35) {
        final double pitch = sampleRate / bestLag;

        if (pitch >= 50.0 && pitch <= 1200.0) {
          final noteInfo = frequencyToNote(pitch);

          double cents = 0.0;
          bool isTuned = false;

          if (targetFrequency != null && targetFrequency > 0) {
            cents = 1200.0 * (math.log(pitch / targetFrequency) / math.ln2);
            isTuned = cents.abs() <= 15.0;
          } else {
            final exactFreq = noteInfo.exactFrequency;
            cents = 1200.0 * (math.log(pitch / exactFreq) / math.ln2);
            isTuned = cents.abs() <= 10.0;
          }

          _currentPitch = PitchData(
            frequency: pitch,
            noteName: noteInfo.noteName,
            cents: cents.clamp(-50.0, 50.0),
            confidence: (maxCorr / sumSquares).clamp(0.0, 1.0),
            isTuned: isTuned,
          );
          notifyListeners();
          return;
        }
      }

      if (_currentPitch.frequency != 0) {
        _currentPitch = PitchData.empty;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erro no cálculo de pitch: $e');
    }
  }

  /// Converte frequência (Hz) em nome de nota musical padrão (ex: A4 = 440Hz).
  static ({String noteName, double exactFrequency, int midiNumber}) frequencyToNote(double freq) {
    const noteStrings = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

    if (freq <= 0) return (noteName: '--', exactFrequency: 0.0, midiNumber: 0);

    final midiVal = 69.0 + 12.0 * (math.log(freq / 440.0) / math.ln2);
    final midiRound = midiVal.round();
    final noteIndex = (midiRound % 12 + 12) % 12;
    final octave = (midiRound ~/ 12) - 1;

    final exactFreq = 440.0 * math.pow(2.0, (midiRound - 69) / 12.0);
    final name = '${noteStrings[noteIndex]}$octave';

    return (noteName: name, exactFrequency: exactFreq, midiNumber: midiRound);
  }

  /// Pausa ou para a escuta do microfone.
  Future<void> stopListening() async {
    try {
      await _recordStreamSub?.cancel();
      _recordStreamSub = null;

      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      _status = PitchStatus.idle;
      _currentPitch = PitchData.empty;
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao parar PitchService: $e');
    }
  }

  @override
  void dispose() {
    stopListening();
    _audioRecorder.dispose();
    super.dispose();
  }
}
