import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/track_model.dart';

enum ExportFormat {
  mp3,
  wav,
}

/// Serviço de Exportação e Mixdown Estéreo 100% Nativo em Dart puro.
class AudioExportService {
  static final AudioExportService _instance = AudioExportService._internal();
  factory AudioExportService() => _instance;
  AudioExportService._internal();

  /// Renderiza o Mixdown das pistas fornecidas em um arquivo WAV estéreo final.
  Future<({bool success, String? outputPath, String? errorMessage})> exportMixdown({
    required List<TrackModel> tracks,
    ExportFormat format = ExportFormat.wav,
    String projectName = 'Harmonia_Studio_Master',
  }) async {
    try {
      final hasSolo = tracks.any((t) => t.isSolo);
      final activeTracks = tracks.where((t) {
        if (!t.hasAudio) return false;
        if (hasSolo) return t.isSolo && !t.isMuted;
        return !t.isMuted;
      }).toList();

      if (activeTracks.isEmpty) {
        return (
          success: false,
          outputPath: null,
          errorMessage: 'Nenhuma pista com áudio gravado para exportar',
        );
      }

      final tempDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = format == ExportFormat.mp3 ? 'mp3' : 'wav';
      final outputPath = '${tempDir.path}/${projectName}_$timestamp.$extension';

      if (activeTracks.length == 1) {
        final singleTrack = activeTracks.first;
        final origFile = File(singleTrack.filePath!);
        if (await origFile.exists()) {
          final destFile = await origFile.copy(outputPath);
          return (success: true, outputPath: destFile.path, errorMessage: null);
        }
      }

      final List<Uint8List> audioBuffers = [];
      for (final track in activeTracks) {
        final f = File(track.filePath!);
        if (await f.exists()) {
          final bytes = await f.readAsBytes();
          audioBuffers.add(bytes);
        }
      }

      if (audioBuffers.isEmpty) {
        return (
          success: false,
          outputPath: null,
          errorMessage: 'Arquivos de áudio não encontrados',
        );
      }

      final mixedBytes = _mixAudioBuffers(audioBuffers, activeTracks.map((t) => t.volume).toList());
      final finalFile = File(outputPath);
      await finalFile.writeAsBytes(mixedBytes);

      return (success: true, outputPath: finalFile.path, errorMessage: null);
    } catch (e) {
      debugPrint('Erro no Mixdown de Áudio: $e');
      return (
        success: false,
        outputPath: null,
        errorMessage: e.toString(),
      );
    }
  }

  Uint8List _mixAudioBuffers(List<Uint8List> buffers, List<double> volumes) {
    int maxDataLength = 0;
    for (final buf in buffers) {
      if (buf.length > maxDataLength) maxDataLength = buf.length;
    }

    const int sampleRate = 44100;
    const int numChannels = 2;
    final int numSamples = (maxDataLength / 2).floor();
    final ByteData output = ByteData(44 + numSamples * 2 * numChannels);

    output.setUint8(0, 0x52); output.setUint8(1, 0x49); output.setUint8(2, 0x46); output.setUint8(3, 0x46);
    output.setUint32(4, 36 + numSamples * 4, Endian.little);
    output.setUint8(8, 0x57); output.setUint8(9, 0x41); output.setUint8(10, 0x56); output.setUint8(11, 0x45);
    output.setUint8(12, 0x66); output.setUint8(13, 0x6D); output.setUint8(14, 0x74); output.setUint8(15, 0x20);
    output.setUint32(16, 16, Endian.little);
    output.setUint16(20, 1, Endian.little);
    output.setUint16(22, numChannels, Endian.little);
    output.setUint32(24, sampleRate, Endian.little);
    output.setUint32(28, sampleRate * numChannels * 2, Endian.little);
    output.setUint16(32, numChannels * 2, Endian.little);
    output.setUint16(34, 16, Endian.little);
    output.setUint8(36, 0x64); output.setUint8(37, 0x61); output.setUint8(38, 0x74); output.setUint8(39, 0x61);
    output.setUint32(40, numSamples * 4, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      double mixedSample = 0.0;
      for (int b = 0; b < buffers.length; b++) {
        final buf = buffers[b];
        final vol = volumes[b];
        final offset = i * 2;
        if (offset + 1 < buf.length) {
          final pcm = (buf[offset] | (buf[offset + 1] << 8)).toSigned(16);
          mixedSample += (pcm / 32768.0) * vol;
        }
      }
      final int finalPcm = (mixedSample.clamp(-1.0, 1.0) * 32767).toInt();
      output.setInt16(44 + i * 4, finalPcm, Endian.little);
      output.setInt16(44 + i * 4 + 2, finalPcm, Endian.little);
    }

    return output.buffer.asUint8List();
  }

  Future<void> shareMixdownFile(String filePath, {String title = 'Harmonia Studio - Minha Música'}) async {
    try {
      final xfile = XFile(filePath);
      await Share.shareXFiles(
        [xfile],
        subject: title,
        text: 'Ouça a música que criei e mixei no Harmonia Studio DAW! 🎵🎛️',
      );
    } catch (e) {
      debugPrint('Erro ao compartilhar arquivo: $e');
    }
  }
}
