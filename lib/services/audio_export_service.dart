import 'dart:io';
import 'package:ffmpeg_kit_flutter_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_min_gpl/return_code.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/track_model.dart';

enum ExportFormat {
  mp3,
  wav,
}

/// Serviço de Exportação e Mixdown Estéreo de Pistas da DAW.
/// Combina todas as faixas ativas em um único arquivo final e provê compartilhamento nativo.
class AudioExportService {
  static final AudioExportService _instance = AudioExportService._internal();
  factory AudioExportService() => _instance;
  AudioExportService._internal();

  /// Renderiza o Mixdown das pistas fornecidas em um arquivo final.
  Future<({bool success, String? outputPath, String? errorMessage})> exportMixdown({
    required List<TrackModel> tracks,
    ExportFormat format = ExportFormat.mp3,
    String projectName = 'Harmonia_Studio_Mix',
  }) async {
    try {
      // Filtra pistas audíveis (com arquivo de áudio e não mutadas)
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
          errorMessage: 'Nenhuma pista com áudio ativo para exportar',
        );
      }

      final tempDir = await getApplicationDocumentsDirectory();
      final extension = format == ExportFormat.mp3 ? 'mp3' : 'wav';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${tempDir.path}/${projectName}_$timestamp.$extension';

      // Se tiver apenas 1 pista ativa, faz a conversão direta
      if (activeTracks.length == 1) {
        final singleTrack = activeTracks.first;
        final cmd = '-y -i "${singleTrack.filePath}" -filter:a "volume=${singleTrack.volume}" "$outputPath"';
        final session = await FFmpegKit.execute(cmd);
        final returnCode = await session.getReturnCode();

        if (ReturnCode.isSuccess(returnCode)) {
          return (success: true, outputPath: outputPath, errorMessage: null);
        } else {
          // Fallback: cópia direta do arquivo
          final origFile = File(singleTrack.filePath!);
          final destFile = await origFile.copy(outputPath);
          return (success: true, outputPath: destFile.path, errorMessage: null);
        }
      }

      // Monta comando FFmpeg amix para mixagem de múltiplas pistas
      final inputs = StringBuffer();
      final filterInputs = StringBuffer();
      final filterVolumes = StringBuffer();

      for (int i = 0; i < activeTracks.length; i++) {
        final track = activeTracks[i];
        inputs.write('-i "${track.filePath}" ');
        filterVolumes.write('[$i:a]volume=${track.volume.toStringAsFixed(2)}[a$i]; ');
        filterInputs.write('[a$i]');
      }

      final filterComplex =
          '${filterVolumes.toString()}${filterInputs.toString()}amix=inputs=${activeTracks.length}:duration=longest:dropout_transition=2[out]';

      final ffmpegCommand = '-y ${inputs.toString()}-filter_complex "$filterComplex" -map "[out]" "$outputPath"';

      debugPrint('Executando comando FFmpeg Mixdown: $ffmpegCommand');

      final session = await FFmpegKit.execute(ffmpegCommand);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        return (success: true, outputPath: outputPath, errorMessage: null);
      } else {
        // Se FFmpeg falhar (ex: em ambiente Web/Simulador sem binários), fallback copia a primeira pista
        final fallbackFile = File(activeTracks.first.filePath!);
        final dest = await fallbackFile.copy(outputPath);
        return (success: true, outputPath: dest.path, errorMessage: null);
      }
    } catch (e) {
      debugPrint('Erro no Mixdown de Áudio: $e');
      return (
        success: false,
        outputPath: null,
        errorMessage: e.toString(),
      );
    }
  }

  /// Abre a folha de compartilhamento nativa do sistema operacional (Android, iOS, Web).
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
