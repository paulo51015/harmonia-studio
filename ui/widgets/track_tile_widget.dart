import 'package:flutter/material.dart';
import '../../models/track_model.dart';
import '../../theme/app_theme.dart';

class TrackTileWidget extends StatelessWidget {
  final TrackModel track;
  final bool isRecordingThisTrack;
  final VoidCallback onToggleArmRec;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSolo;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback? onDeleteTrack;

  const TrackTileWidget({
    super.key,
    required this.track,
    required this.isRecordingThisTrack,
    required this.onToggleArmRec,
    required this.onToggleMute,
    required this.onToggleSolo,
    required this.onVolumeChanged,
    this.onDeleteTrack,
  });

  @override
  Widget build(BuildContext context) {
    final hasAudio = track.hasAudio;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: track.isArmedForRec
              ? AppTheme.recRed
              : (track.isSolo ? AppTheme.soloYellow : AppTheme.dividerColor),
          width: track.isArmedForRec || track.isSolo ? 1.5 : 1,
        ),
        boxShadow: [
          if (track.isArmedForRec)
            BoxShadow(
              color: AppTheme.recRed.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Column(
        children: [
          // 1. Cabeçalho da Pista (Nome, Ícone, REC Arm, Mute, Solo)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                // Ícone do Instrumento com cor identificadora
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: track.trackColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    track.icon,
                    color: track.trackColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),

                // Nome da Pista
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        hasAudio
                            ? 'Áudio gravado (${track.duration.inSeconds}s)'
                            : (track.isArmedForRec ? 'Pronta para gravar' : 'Pista vazia'),
                        style: TextStyle(
                          fontSize: 11,
                          color: track.isArmedForRec
                              ? AppTheme.recRed
                              : (hasAudio ? AppTheme.cyan : AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão ARM REC (Armar gravação)
                IconButton(
                  tooltip: 'Armar Pista para Gravação',
                  onPressed: onToggleArmRec,
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: track.isArmedForRec ? AppTheme.recRed : AppTheme.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: track.isArmedForRec ? Colors.white : AppTheme.recRed.withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: track.isArmedForRec ? Colors.white : AppTheme.recRed,
                      size: 14,
                    ),
                  ),
                ),

                // Botão MUTE (M)
                InkWell(
                  onTap: onToggleMute,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: track.isMuted ? const Color(0xFFE65100) : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: track.isMuted ? Colors.orangeAccent : AppTheme.dividerColor,
                      ),
                    ),
                    child: Text(
                      'M',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: track.isMuted ? Colors.white : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Botão SOLO (S)
                InkWell(
                  onTap: onToggleSolo,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: track.isSolo ? AppTheme.soloYellow : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: track.isSolo ? Colors.black : AppTheme.dividerColor,
                      ),
                    ),
                    child: Text(
                      'S',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: track.isSolo ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Visualização de Timeline / Forma de Onda (Waveform Preview)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.dividerColor.withOpacity(0.5)),
            ),
            child: hasAudio
                ? CustomPaint(
                    painter: _WaveformPainter(
                      samples: track.waveformSamples,
                      waveColor: track.trackColor,
                    ),
                    child: Container(),
                  )
                : Center(
                    child: Text(
                      isRecordingThisTrack
                          ? '🔴 GRAVANDO NESTA PISTA...'
                          : (track.isArmedForRec
                              ? 'Armada: Toque no REC Master para gravar'
                              : 'Sem áudio na pista'),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isRecordingThisTrack ? FontWeight.bold : FontWeight.normal,
                        color: isRecordingThisTrack
                            ? AppTheme.recRed
                            : (track.isArmedForRec ? AppTheme.cyan : AppTheme.textSecondary),
                      ),
                    ),
                  ),
          ),

          // 3. Fader de Volume da Pista
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                const Icon(Icons.volume_down, size: 16, color: AppTheme.textSecondary),
                Expanded(
                  child: Slider(
                    value: track.volume,
                    min: 0.0,
                    max: 1.0,
                    activeColor: track.trackColor,
                    inactiveColor: AppTheme.surfaceLight,
                    onChanged: onVolumeChanged,
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(track.volume * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> samples;
  final Color waveColor;

  _WaveformPainter({required this.samples, required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;

    final paint = Paint()
      ..color = waveColor.withOpacity(0.85)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double step = size.width / (samples.length + 1);
    final double centerY = size.height / 2;

    for (int i = 0; i < samples.length; i++) {
      final double x = (i + 1) * step;
      final double height = (samples[i] * (size.height * 0.75)).clamp(4.0, size.height - 4);
      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
