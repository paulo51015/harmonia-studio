import 'package:flutter/material.dart';
import '../../services/studio_audio_engine.dart';
import '../../theme/app_theme.dart';

class MetronomeDialog extends StatefulWidget {
  final StudioAudioEngine audioEngine;

  const MetronomeDialog({super.key, required this.audioEngine});

  @override
  State<MetronomeDialog> createState() => _MetronomeDialogState();
}

class _MetronomeDialogState extends State<MetronomeDialog> {
  final List<DateTime> _tapTimes = [];

  void _onTapTempo() {
    final now = DateTime.now();
    _tapTimes.add(now);
    if (_tapTimes.length > 4) {
      _tapTimes.removeAt(0);
    }

    if (_tapTimes.length >= 2) {
      int totalMs = 0;
      for (int i = 1; i < _tapTimes.length; i++) {
        totalMs += _tapTimes[i].difference(_tapTimes[i - 1]).inMilliseconds;
      }
      final avgMs = totalMs / (_tapTimes.length - 1);
      if (avgMs > 0) {
        final calculatedBpm = (60000 / avgMs).round();
        widget.audioEngine.setBpm(calculatedBpm);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.audioEngine,
      builder: (context, _) {
        final currentBpm = widget.audioEngine.bpm;
        final isEnabled = widget.audioEngine.isMetronomeEnabled;
        final currentBeat = widget.audioEngine.metronomeBeat;

        return AlertDialog(
          backgroundColor: AppTheme.surface,
          title: Row(
            children: const [
              Icon(Icons.av_timer, color: AppTheme.cyan),
              SizedBox(width: 10),
              Text(
                'Metrônomo & Andamento',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mostrador Principal de BPM
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.dividerColor),
                ),
                child: Column(
                  children: [
                    Text(
                      '$currentBpm',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.cyan,
                      ),
                    ),
                    const Text(
                      'BATIDAS POR MINUTO (BPM)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Visualizador de Batidas (1, 2, 3, 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final beatNum = index + 1;
                  final isActive = currentBeat == beatNum;
                  final isFirstBeat = beatNum == 1;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive
                          ? (isFirstBeat ? AppTheme.recRed : AppTheme.cyan)
                          : AppTheme.surfaceLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.white : AppTheme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$beatNum',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isActive ? Colors.black : AppTheme.textSecondary,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              // Slider de BPM
              Slider(
                value: currentBpm.toDouble(),
                min: 40,
                max: 240,
                divisions: 200,
                activeColor: AppTheme.cyan,
                label: '$currentBpm BPM',
                onChanged: (val) => widget.audioEngine.setBpm(val.round()),
              ),

              // Botões de Ajuste Fino (- / +) e Tap Tempo
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton.filledTonal(
                    onPressed: () => widget.audioEngine.setBpm(currentBpm - 1),
                    icon: const Icon(Icons.remove),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceLight,
                      foregroundColor: AppTheme.textPrimary,
                    ),
                    onPressed: _onTapTempo,
                    icon: const Icon(Icons.touch_app, size: 16),
                    label: const Text('Tap Tempo'),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => widget.audioEngine.setBpm(currentBpm + 1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Toggle de Som do Metrônomo
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Sons de Clique do Metrônomo',
                  style: TextStyle(fontSize: 14),
                ),
                value: isEnabled,
                activeColor: AppTheme.cyan,
                onChanged: (_) => widget.audioEngine.toggleMetronome(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Concluído', style: TextStyle(color: AppTheme.cyan)),
            ),
          ],
        );
      },
    );
  }
}
