import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/track_model.dart';
import '../../services/audio_export_service.dart';
import '../../services/studio_audio_engine.dart';
import '../../theme/app_theme.dart';
import '../widgets/metronome_dialog.dart';
import '../widgets/track_tile_widget.dart';

class StudioScreen extends StatefulWidget {
  final StudioAudioEngine audioEngine;

  const StudioScreen({super.key, required this.audioEngine});

  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  bool _isExporting = false;
  String? _exportedFilePath;

  void _showMetronomeDialog() {
    showDialog(
      context: context,
      builder: (_) => MetronomeDialog(audioEngine: widget.audioEngine),
    );
  }

  void _showAddTrackDialog() {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    InstrumentType selectedType = InstrumentType.guitar;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              title: Text(loc.translate('daw_add_track')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nome da Pista (ex: Solo de Guitarra)',
                      prefixIcon: Icon(Icons.label_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<InstrumentType>(
                    value: selectedType,
                    dropdownColor: AppTheme.surface,
                    decoration: const InputDecoration(labelText: 'Tipo de Instrumento'),
                    items: const [
                      DropdownMenuItem(value: InstrumentType.guitar, child: Text('🎸 Violão / Guitarra')),
                      DropdownMenuItem(value: InstrumentType.keyboard, child: Text('🎹 Teclado / Synth')),
                      DropdownMenuItem(value: InstrumentType.vocals, child: Text('🎤 Voz')),
                      DropdownMenuItem(value: InstrumentType.drums, child: Text('🥁 Bateria / Beat')),
                      DropdownMenuItem(value: InstrumentType.bass, child: Text('🎸 Contrabaixo')),
                      DropdownMenuItem(value: InstrumentType.other, child: Text('🎵 Outro')),
                    ],
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedType = val);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(loc.translate('cancel'), style: const TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim().isEmpty
                        ? 'Nova Pista ${widget.audioEngine.tracks.length + 1}'
                        : nameController.text.trim();
                    widget.audioEngine.addTrack(name: name, type: selectedType);
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(loc.translate('confirm')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleExportMixdown() async {
    final loc = AppLocalizations.of(context);
    final tracks = widget.audioEngine.tracks;

    final hasAudio = tracks.any((t) => t.hasAudio);
    if (!hasAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.recRed,
          content: Text(loc.translate('daw_no_tracks_to_export')),
        ),
      );
      return;
    }

    setState(() {
      _isExporting = true;
      _exportedFilePath = null;
    });

    final result = await AudioExportService().exportMixdown(
      tracks: tracks,
      format: ExportFormat.mp3,
      projectName: 'Harmonia_Studio_Master',
    );

    if (!mounted) return;

    setState(() {
      _isExporting = false;
      _exportedFilePath = result.outputPath;
    });

    if (result.success && result.outputPath != null) {
      _showExportSuccessDialog(result.outputPath!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.recRed,
          content: Text(result.errorMessage ?? loc.translate('error')),
        ),
      );
    }
  }

  void _showExportSuccessDialog(String path) {
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppTheme.successGreen),
              SizedBox(width: 10),
              Text('Mixdown Renderizado!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.translate('daw_export_success'),
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  path.split('/').last.split('\\').last,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.cyan,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(loc.translate('close'), style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.share, size: 18),
              label: Text(loc.translate('daw_share_audio')),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                AudioExportService().shareMixdownFile(path);
              },
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final centiseconds = (d.inMilliseconds.remainder(1000) ~/ 10).toString().padLeft(2, '0');
    return '$minutes:$seconds.$centiseconds';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: widget.audioEngine,
      builder: (context, _) {
        final state = widget.audioEngine.transportState;
        final isPlaying = widget.audioEngine.isPlaying;
        final isRecording = widget.audioEngine.isRecording;
        final tracks = widget.audioEngine.tracks;
        final currentPos = widget.audioEngine.currentPosition;
        final bpm = widget.audioEngine.bpm;

        return Scaffold(
          body: Column(
            children: [
              // 1. CONSOLE DE TRANSPORTE PRINCIPAL DA DAW (Transport Bar)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.backgroundSecondary,
                  border: Border(bottom: BorderSide(color: AppTheme.dividerColor, width: 1.5)),
                  boxShadow: [
                    BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  children: [
                    // Linha Superior: Display de Tempo, BPM & Metrônomo, Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Contador Digital de Tempo
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 14, color: AppTheme.cyan),
                              const SizedBox(width: 6),
                              Text(
                                _formatDuration(currentPos),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.cyan,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isRecording
                                ? AppTheme.recRed.withOpacity(0.2)
                                : (isPlaying ? AppTheme.cyan.withOpacity(0.2) : AppTheme.surfaceLight),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isRecording ? AppTheme.recRed : (isPlaying ? AppTheme.cyan : AppTheme.dividerColor),
                            ),
                          ),
                          child: Text(
                            isRecording
                                ? loc.translate('daw_recording')
                                : (isPlaying ? loc.translate('daw_playing') : loc.translate('daw_stopped')),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isRecording
                                  ? AppTheme.recRed
                                  : (isPlaying ? AppTheme.cyan : AppTheme.textSecondary),
                            ),
                          ),
                        ),

                        // Botão BPM / Metrônomo
                        InkWell(
                          onTap: _showMetronomeDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: widget.audioEngine.isMetronomeEnabled
                                  ? AppTheme.cyan.withOpacity(0.15)
                                  : AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: widget.audioEngine.isMetronomeEnabled ? AppTheme.cyan : AppTheme.dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.av_timer,
                                  size: 16,
                                  color: widget.audioEngine.isMetronomeEnabled ? AppTheme.cyan : AppTheme.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$bpm BPM',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.audioEngine.isMetronomeEnabled ? AppTheme.cyan : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Linha Inferior: Botões de Transporte (Play, Stop, REC Master, Mixdown)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Botão STOP
                        IconButton.filledTonal(
                          tooltip: loc.translate('daw_stop'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLight,
                            padding: const EdgeInsets.all(12),
                          ),
                          onPressed: state != StudioTransportState.stopped
                              ? () => widget.audioEngine.masterStop()
                              : null,
                          icon: const Icon(Icons.stop, color: Colors.white, size: 24),
                        ),

                        // Botão MASTER PLAY
                        IconButton.filled(
                          tooltip: loc.translate('daw_play'),
                          style: IconButton.styleFrom(
                            backgroundColor: isPlaying ? AppTheme.cyan : AppTheme.surfaceLight,
                            padding: const EdgeInsets.all(14),
                          ),
                          onPressed: () => widget.audioEngine.masterPlay(),
                          icon: Icon(
                            Icons.play_arrow,
                            color: isPlaying ? Colors.black : Colors.white,
                            size: 28,
                          ),
                        ),

                        // Botão MASTER REC (Gravação Multi-Track)
                        IconButton.filled(
                          tooltip: loc.translate('daw_master_rec'),
                          style: IconButton.styleFrom(
                            backgroundColor: isRecording ? AppTheme.recRed : AppTheme.surfaceLight,
                            padding: const EdgeInsets.all(14),
                            shadowColor: isRecording ? AppTheme.recRed : null,
                            elevation: isRecording ? 10 : 0,
                          ),
                          onPressed: () async {
                            if (isRecording) {
                              await widget.audioEngine.masterStop();
                            } else {
                              final ok = await widget.audioEngine.masterRecord();
                              if (!ok && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppTheme.recRed,
                                    content: Text(loc.translate('lesson_mic_permission_needed')),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.fiber_manual_record,
                            color: isRecording ? Colors.white : AppTheme.recRed,
                            size: 28,
                          ),
                        ),

                        // Botão Mixdown / Export
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.surfaceLight,
                            foregroundColor: AppTheme.cyan,
                            side: const BorderSide(color: AppTheme.cyan),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onPressed: _isExporting ? null : _handleExportMixdown,
                          icon: _isExporting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: AppTheme.cyan, strokeWidth: 2),
                                )
                              : const Icon(Icons.ios_share, size: 18),
                          label: Text(
                            _isExporting ? loc.translate('daw_exporting') : loc.translate('daw_export_mixdown'),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. CABEÇALHO DA LISTA DE PISTAS & BOTÃO ADICIONAR
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.queue_music, size: 18, color: AppTheme.cyan),
                        const SizedBox(width: 8),
                        Text(
                          '${loc.translate('daw_tracks')} (${tracks.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => widget.audioEngine.clearProject(),
                          icon: const Icon(Icons.refresh, size: 16, color: AppTheme.textSecondary),
                          label: Text(
                            loc.translate('daw_clear_all'),
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: loc.translate('daw_add_track'),
                          style: IconButton.styleFrom(backgroundColor: AppTheme.surfaceLight),
                          onPressed: _showAddTrackDialog,
                          icon: const Icon(Icons.add, color: AppTheme.cyan, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. LISTA DE PISTAS (Tracks Manager)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    final isThisRecording = isRecording && track.isArmedForRec;

                    return TrackTileWidget(
                      track: track,
                      isRecordingThisTrack: isThisRecording,
                      onToggleArmRec: () => widget.audioEngine.toggleArmTrack(track.id),
                      onToggleMute: () => widget.audioEngine.toggleMute(track.id),
                      onToggleSolo: () => widget.audioEngine.toggleSolo(track.id),
                      onVolumeChanged: (vol) => widget.audioEngine.setTrackVolume(track.id, vol),
                      onDeleteTrack: tracks.length > 1
                          ? () => widget.audioEngine.removeTrack(track.id)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
