import 'package:flutter/material.dart';
import '../../services/pitch_service.dart';
import '../../theme/app_theme.dart';

class PitchVisualizerWidget extends StatelessWidget {
  final PitchData pitchData;
  final String? targetNote;
  final double? targetFrequency;
  final bool isListening;

  const PitchVisualizerWidget({
    super.key,
    required this.pitchData,
    this.targetNote,
    this.targetFrequency,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasPitch = pitchData.frequency > 0 && isListening;
    final bool isTuned = pitchData.isTuned && hasPitch;
    final double cents = pitchData.cents;

    Color stateColor;
    String statusText;

    if (!isListening) {
      stateColor = AppTheme.muteGray;
      statusText = 'Afinador Desativado';
    } else if (!hasPitch) {
      stateColor = AppTheme.cyan;
      statusText = 'Ouvindo microfone... Toque seu instrumento';
    } else if (isTuned) {
      stateColor = AppTheme.successGreen;
      statusText = '🎉 AFINADO! NOTA CORRETA';
    } else if (cents < -10) {
      stateColor = AppTheme.soloYellow;
      statusText = 'Tom Baixo (Flat) - Aumente a afinação ⬆️';
    } else {
      stateColor = AppTheme.recRed;
      statusText = 'Tom Alto (Sharp) - Diminua a afinação ⬇️';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTuned ? AppTheme.successGreen : AppTheme.dividerColor,
          width: isTuned ? 2 : 1,
        ),
        boxShadow: [
          if (isTuned)
            BoxShadow(
              color: AppTheme.successGreen.withOpacity(0.25),
              blurRadius: 16,
              spreadRadius: 2,
            ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Cabeçalho de Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: stateColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: stateColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              if (targetFrequency != null)
                Text(
                  'Alvo: ${targetFrequency!.toStringAsFixed(1)} Hz',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Mostrador Principal de Nota (Target vs Detected)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Nota Alvo
              if (targetNote != null)
                Column(
                  children: [
                    const Text(
                      'ALVO',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.cyan.withOpacity(0.5)),
                      ),
                      child: Text(
                        targetNote!,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.cyan,
                        ),
                      ),
                    ),
                  ],
                ),

              // Nota Detectada
              Column(
                children: [
                  const Text(
                    'DETECTADO',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: hasPitch ? stateColor.withOpacity(0.15) : AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: hasPitch ? stateColor : AppTheme.dividerColor,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      hasPitch ? pitchData.noteName : '--',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: hasPitch ? stateColor : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              // Frequência em Hz
              Column(
                children: [
                  const Text(
                    'FREQ (HZ)',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      hasPitch ? '${pitchData.frequency.toStringAsFixed(1)}' : '0.0',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 3. Medidor Gráfico de Desvio em Cents (-50 a +50)
          LayoutBuilder(
            builder: (context, constraints) {
              final double width = constraints.maxWidth;
              // Normaliza cents (-50 a +50) para offset (0.0 a 1.0)
              final double normalizedOffset = hasPitch
                  ? ((cents + 50.0) / 100.0).clamp(0.0, 1.0)
                  : 0.5;

              return Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Barra de Fundo com gradiente de afinação
                      Container(
                        height: 12,
                        width: width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              AppTheme.soloYellow, // Flat
                              AppTheme.successGreen, // Centro Afinado
                              AppTheme.recRed, // Sharp
                            ],
                          ),
                        ),
                      ),
                      // Linha central de afinação exata
                      Container(
                        width: 3,
                        height: 20,
                        color: Colors.white,
                      ),
                      // Agulha / Indicador deslizante
                      Positioned(
                        left: (normalizedOffset * (width - 16)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 80),
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isTuned ? AppTheme.successGreen : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.black, width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black45,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('-50 cents (b)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                      Text('0 cents (Afinado)', style: TextStyle(fontSize: 10, color: AppTheme.successGreen, fontWeight: FontWeight.bold)),
                      Text('+50 cents (#)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
