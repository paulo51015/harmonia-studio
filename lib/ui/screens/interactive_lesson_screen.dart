import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/lesson_model.dart';
import '../../models/track_model.dart';
import '../../services/pitch_service.dart';
import '../../services/studio_audio_engine.dart';
import '../../services/synth_service.dart';
import '../../theme/app_theme.dart';
import '../widgets/pitch_visualizer_widget.dart';
import '../widgets/virtual_piano.dart';

class InteractiveLessonScreen extends StatefulWidget {
  final PitchService pitchService;
  final StudioAudioEngine audioEngine;
  final VoidCallback onNavigateToStudio;

  const InteractiveLessonScreen({
    super.key,
    required this.pitchService,
    required this.audioEngine,
    required this.onNavigateToStudio,
  });

  @override
  State<InteractiveLessonScreen> createState() => _InteractiveLessonScreenState();
}

class _InteractiveLessonScreenState extends State<InteractiveLessonScreen> {
  final List<LessonModel> _allLessons = CurriculumData.getLessons();
  LessonInstrument _selectedInstrument = LessonInstrument.guitar;
  late LessonModel _currentLesson;
  int _currentExerciseIndex = 0;
  bool _hasCompletedExercise = false;

  @override
  void initState() {
    super.initState();
    _currentLesson = _allLessons.firstWhere((l) => l.instrument == _selectedInstrument);
    _startTunerForCurrentExercise();
  }

  void _startTunerForCurrentExercise() {
    final currentTarget = _currentLesson.exercises[_currentExerciseIndex];
    widget.pitchService.startListening(targetFrequency: currentTarget.targetFrequencyHz);
  }

  void _onSelectInstrument(LessonInstrument instrument) {
    setState(() {
      _selectedInstrument = instrument;
      _currentLesson = _allLessons.firstWhere((l) => l.instrument == instrument);
      _currentExerciseIndex = 0;
      _hasCompletedExercise = false;
    });
    _startTunerForCurrentExercise();
  }

  void _onSelectLesson(LessonModel lesson) {
    setState(() {
      _currentLesson = lesson;
      _currentExerciseIndex = 0;
      _hasCompletedExercise = false;
    });
    _startTunerForCurrentExercise();
  }

  void _onNextStep() {
    if (_currentExerciseIndex < _currentLesson.exercises.length - 1) {
      setState(() {
        _currentExerciseIndex++;
        _hasCompletedExercise = false;
      });
      _startTunerForCurrentExercise();
    } else {
      setState(() {
        _hasCompletedExercise = true;
      });
    }
  }

  void _onRecordInStudio() {
    // 1. Configura BPM da aula na DAW
    widget.audioEngine.setBpm(_currentLesson.defaultBpm);

    // 2. Arma a pista correspondente
    final targetInstrumentType = _currentLesson.instrument == LessonInstrument.guitar
        ? InstrumentType.guitar
        : InstrumentType.keyboard;

    final targetTrack = widget.audioEngine.tracks.firstWhere(
      (t) => t.instrumentType == targetInstrumentType,
      orElse: () => widget.audioEngine.tracks.first,
    );

    widget.audioEngine.toggleArmTrack(targetTrack.id);

    // 3. Pausa o afinador de microfone para liberar áudio para a DAW
    widget.pitchService.stopListening();

    // 4. Navega para a aba do Estúdio DAW
    widget.onNavigateToStudio();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final currentTarget = _currentLesson.exercises[_currentExerciseIndex];

    return ListenableBuilder(
      listenable: widget.pitchService,
      builder: (context, _) {
        final pitchData = widget.pitchService.currentPitch;
        final isListening = widget.pitchService.isListening;

        // Verifica se a nota detectada atingiu o alvo com precisão
        final isTargetAchieved = currentTarget.matchesFrequency(pitchData.frequency) ||
            (pitchData.isTuned && pitchData.noteName == currentTarget.noteName);

        return Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. SELETOR DE INSTRUMENTO (Violão vs Teclado)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _onSelectInstrument(LessonInstrument.guitar),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedInstrument == LessonInstrument.guitar
                                  ? const Color(0xFFFF9500).withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedInstrument == LessonInstrument.guitar
                                    ? const Color(0xFFFF9500)
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.music_note, color: Color(0xFFFF9500), size: 18),
                                SizedBox(width: 8),
                                Text(
                                  '🎸 Violão Acústico',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _onSelectInstrument(LessonInstrument.keyboard),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _selectedInstrument == LessonInstrument.keyboard
                                  ? AppTheme.cyan.withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _selectedInstrument == LessonInstrument.keyboard
                                    ? AppTheme.cyan
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.piano, color: AppTheme.cyan, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  '🎹 Teclado / Piano',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 2. SELETOR DE AULAS DO INSTRUMENTO ATUAL
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _allLessons
                        .where((l) => l.instrument == _selectedInstrument)
                        .map((lesson) {
                      final isSelected = lesson.id == _currentLesson.id;

                      return GestureDetector(
                        onTap: () => _onSelectLesson(lesson),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.surfaceLight : AppTheme.cardColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppTheme.cyan : AppTheme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected ? AppTheme.cyan : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lesson.level} • ${lesson.defaultBpm} BPM',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. CARTÃO DO EXERCÍCIO ATUAL & NOTA ALVO
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Exercício ${_currentExerciseIndex + 1} de ${_currentLesson.exercises.length}',
                            style: const TextStyle(
                              color: AppTheme.cyan,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Andamento: ${_currentLesson.defaultBpm} BPM',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentTarget.displayChord,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currentTarget.tip,
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.touch_app, size: 16, color: AppTheme.cyan),
                            const SizedBox(width: 8),
                            Text(
                              'Posicionamento: ${currentTarget.tabOrKey}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. VISUALIZADOR DE AFINAÇÃO E DETECÇÃO DE PITCH VIA MICROFONE
                PitchVisualizerWidget(
                  pitchData: pitchData,
                  targetNote: currentTarget.noteName,
                  targetFrequency: currentTarget.targetFrequencyHz,
                  isListening: isListening,
                ),
                const SizedBox(height: 12),

                // Botão de Ativação / Pausa do Afinador
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        if (isListening) {
                          widget.pitchService.stopListening();
                        } else {
                          _startTunerForCurrentExercise();
                        }
                      },
                      icon: Icon(
                        isListening ? Icons.mic_off : Icons.mic,
                        size: 18,
                        color: isListening ? AppTheme.recRed : AppTheme.cyan,
                      ),
                      label: Text(
                        isListening ? loc.translate('lesson_stop_mic') : loc.translate('lesson_start_mic'),
                        style: TextStyle(
                          color: isListening ? AppTheme.recRed : AppTheme.cyan,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. TECLADO VIRTUAL TOUCH INTERATIVO
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('lesson_virtual_piano'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Ouvir nota alvo no sintetizador',
                          icon: const Icon(Icons.volume_up, color: AppTheme.cyan, size: 20),
                          onPressed: () {
                            SynthService().playFrequency(currentTarget.targetFrequencyHz);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    VirtualPiano(
                      highlightedNote: currentTarget.noteName,
                      onNotePressed: (note) {
                        // Verifica se tocou a nota correta no teclado virtual
                        if (note == currentTarget.noteName) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(milliseconds: 900),
                              backgroundColor: AppTheme.successGreen,
                              content: Text(
                                '🎉 Nota correta tocada no teclado virtual!',
                                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 6. BOTÃO DE PROGRESSÃO & BOTÃO "GRAVAR ESTA LEVADA NO ESTÚDIO"
                if (isTargetAchieved || _hasCompletedExercise) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.successGreen),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.stars, color: AppTheme.successGreen, size: 24),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Excelente execução! Você dominou esta nota / acorde!',
                            style: TextStyle(
                              color: AppTheme.successGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                Row(
                  children: [
                    if (_currentExerciseIndex < _currentLesson.exercises.length - 1)
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.cyan),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _onNextStep,
                          icon: const Icon(Icons.arrow_forward, color: AppTheme.cyan),
                          label: Text(
                            loc.translate('lesson_next_step'),
                            style: const TextStyle(color: AppTheme.cyan, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // BOTÃO DE TRANSIÇÃO DIRETA PARA O ESTÚDIO DAW
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                  ),
                  onPressed: _onRecordInStudio,
                  icon: const Icon(Icons.album, size: 20),
                  label: Text(
                    loc.translate('lesson_record_in_studio_btn'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    widget.pitchService.stopListening();
    super.dispose();
  }
}
