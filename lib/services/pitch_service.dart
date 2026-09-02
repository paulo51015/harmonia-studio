import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';
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
  final bool isTuned; // afinado dentro da margem de erro

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
class PitchService extends ChangeNotifier {
  static const int sampleRate = 44100;
  static const int bufferSize = 2048;

  final AudioRecorder _audioRecorder = AudioRecorder();
  late final PitchDetector _pitchDetector;
  StreamSubscription<Uint8List>? _recordStreamSub;

  PitchStatus _status = PitchStatus.idle;
  PitchData _currentPitch = PitchData.empty;
  String? _errorMessage;

  PitchStatus get status => _status;
  PitchData get currentPitch => _currentPitch;
  String? get errorMessage => _errorMessage;
  bool get isListening => _status == PitchStatus.listening;

  PitchService() {
    _pitchDetector = PitchDetector(
      sampleRate: sampleRate.toDouble(),
      bufferSize: bufferSize,
    );
  }

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

      // Inicia stream de áudio PCM bruto (16-bit PCM mono 44.1kHz)
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

          // Processa em blocos de bufferSize samples (2 bytes por sample de 16 bits = bufferSize * 2)
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

  /// Processa os bytes PCM usando o algoritmo YIN de detecção de tom fundamental.
  void _processPcmChunk(Uint8List byteList, double? targetFrequency) {
    try {
      final result = _pitchDetector.getPitchFromBinary(byteList);
      final pitch = result.pitch;
      final probability = result.probability;

      if (pitch > 40.0 && pitch < 2000.0 && probability > 0.82) {
        final noteInfo = frequencyToNote(pitch);

        double cents = 0.0;
        bool isTuned = false;

        if (targetFrequency != null && targetFrequency > 0) {
          // Desvio relativo à nota alvo do exercício
          cents = 1200.0 * (math.log(pitch / targetFrequency) / math.ln2);
          isTuned = cents.abs() <= 15.0; // Margem de afinação tolerada (15 cents)
        } else {
          // Desvio relativo à nota musical mais próxima
          final exactNoteFreq = noteInfo.exactFrequency;
          cents = 1200.0 * (math.log(pitch / exactNoteFreq) / math.ln2);
          isTuned = cents.abs() <= 10.0;
        }

        _currentPitch = PitchData(
          frequency: pitch,
          noteName: noteInfo.noteName,
          cents: cents.clamp(-50.0, 50.0),
          confidence: probability,
          isTuned: isTuned,
        );
        _status = PitchStatus.listening;
        notifyListeners();
      } else {
        // Silêncio ou ruído de fundo sem tom definido
        if (_currentPitch.frequency != 0) {
          _currentPitch = PitchData.empty;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Erro no cálculo de pitch: $e');
    }
  }

  /// Converte frequência (Hz) no nome da nota musical padrão (ex: A4 = 440Hz).
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
