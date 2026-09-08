import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ai_song_model.dart';
import '../../services/ai_music_generator_service.dart';
import '../../services/studio_audio_engine.dart';
import '../../services/synth_service.dart';
import '../../theme/app_theme.dart';

class AiComposerScreen extends StatefulWidget {
  final StudioAudioEngine studioEngine;
  final VoidCallback? onNavigateToStudio;

  const AiComposerScreen({
    super.key,
    required this.studioEngine,
    this.onNavigateToStudio,
  });

  @override
  State<AiComposerScreen> createState() => _AiComposerScreenState();
}

class _AiComposerScreenState extends State<AiComposerScreen> {
  final TextEditingController _promptController = TextEditingController();
  final AiMusicGeneratorService _generatorService = AiMusicGeneratorService();

  String _selectedGenre = 'Gospel / Louvor';
  String _selectedMood = 'Inspirador / Emocionante';
  String _selectedKey = 'G (Sol Maior)';
  int _selectedBpm = 72;

  bool _isGenerating = false;
  bool _isPlayingPreview = false;
  AiSongModel? _generatedSong;

  // Lista Rica de Estilos Musicais
  final List<({String name, String icon, String example})> _genresWithDetails = [
    (name: 'Gospel / Louvor', icon: '🙏', example: 'Um louvor de adoração suave e emocionante sobre fé e gratidão'),
    (name: 'Sertanejo', icon: '🤠', example: 'Um modão sertanejo romântico com arpejo de violão e refrão marcante'),
    (name: 'Romântica / Balada', icon: '❤️', example: 'Uma balada romântica apaixonada no piano sobre declaração de amor'),
    (name: 'Acústico / MPB', icon: '🎸', example: 'Uma levada suave de violão estilo MPB sobre um fim de tarde'),
    (name: 'Forró / Piseiro', icon: '🪗', example: 'Um forró animado e dançante com ritmo de sanfona e festa'),
    (name: 'Rock / Pop Rock', icon: '⚡', example: 'Um pop rock enérgico com riff de guitarra e bateria contagiante'),
    (name: 'Lo-Fi Chill', icon: '☕', example: 'Uma melodia relaxante de piano lo-fi para estudar e descansar'),
  ];

  final List<String> _moods = [
    'Inspirador / Emocionante',
    'Romântico & Apaixonado',
    'Alegre & Festivo',
    'Melancólico & Saudade',
    'Relaxante & Suave',
  ];

  final List<String> _keys = [
    'G (Sol Maior)',
    'C (Dó Maior)',
    'Am (Lá Menor)',
    'D (Ré Maior)',
    'Em (Mi Menor)',
    'F (Fá Maior)',
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _onGenreSelected(String genre, String examplePrompt) {
    setState(() {
      _selectedGenre = genre;
      if (_promptController.text.trim().isEmpty) {
        _promptController.text = examplePrompt;
      }
      switch (genre) {
        case 'Gospel / Louvor':
          _selectedBpm = 72;
          _selectedMood = 'Inspirador / Emocionante';
          _selectedKey = 'C (Dó Maior)';
          break;
        case 'Sertanejo':
          _selectedBpm = 118;
          _selectedMood = 'Romântico & Apaixonado';
          _selectedKey = 'G (Sol Maior)';
          break;
        case 'Romântica / Balada':
          _selectedBpm = 68;
          _selectedMood = 'Romântico & Apaixonado';
          _selectedKey = 'C (Dó Maior)';
          break;
        case 'Forró / Piseiro':
          _selectedBpm = 138;
          _selectedMood = 'Alegre & Festivo';
          _selectedKey = 'Am (Lá Menor)';
          break;
        case 'Acústico / MPB':
          _selectedBpm = 92;
          _selectedMood = 'Relaxante & Suave';
          _selectedKey = 'C (Dó Maior)';
          break;
        case 'Rock / Pop Rock':
          _selectedBpm = 132;
          _selectedMood = 'Alegre & Festivo';
          _selectedKey = 'G (Sol Maior)';
          break;
        case 'Lo-Fi Chill':
          _selectedBpm = 78;
          _selectedMood = 'Relaxante & Suave';
          _selectedKey = 'Am (Lá Menor)';
          break;
      }
    });
  }

  Future<void> _handleGenerateSong() async {
    final promptText = _promptController.text.trim();
    if (promptText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite sua ideia ou escolha um estilo musical abaixo!'),
          backgroundColor: AppTheme.recRed,
        ),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _isPlayingPreview = false;
    });

    try {
      final song = await _generatorService.generateSongFromPrompt(
        prompt: promptText,
        selectedGenre: _selectedGenre,
        selectedMood: _selectedMood,
        selectedKey: _selectedKey,
        customBpm: _selectedBpm,
      );

      setState(() {
        _generatedSong = song;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compor música: $e'), backgroundColor: AppTheme.recRed),
        );
      }
    }
  }

  Future<void> _togglePlayPreview() async {
    if (_generatedSong == null) return;

    if (_isPlayingPreview) {
      setState(() => _isPlayingPreview = false);
      return;
    }

    setState(() => _isPlayingPreview = true);

    for (final note in _generatedSong!.melody) {
      if (!_isPlayingPreview || !mounted) break;
      SynthService().playNote(note.note);
      final delayMs = (note.durationInBeats * (60000 / _generatedSong!.bpm)).round();
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    if (mounted) {
      setState(() => _isPlayingPreview = false);
    }
  }

  Future<void> _exportToStudio() async {
    if (_generatedSong == null) return;

    final l10n = AppLocalizations.of(context);
    final success = await _generatorService.exportSongToStudioDaw(_generatedSong!, widget.studioEngine);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('composer_exported_success')),
            backgroundColor: AppTheme.successGreen,
            duration: const Duration(seconds: 4),
          ),
        );
        widget.onNavigateToStudio?.call();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('error')),
            backgroundColor: AppTheme.recRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: AppTheme.cyan),
            const SizedBox(width: 10),
            Text(l10n.translate('composer_title')),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Seletor Visual de Estilos Musicais (Gospel, Sertanejo, Romântica, etc.)
            const Text(
              'Escolha o Estilo Musical:',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _genresWithDetails.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final g = _genresWithDetails[index];
                  final isSelected = _selectedGenre == g.name;

                  return FilterChip(
                    avatar: Text(g.icon, style: const TextStyle(fontSize: 16)),
                    label: Text(
                      g.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.black : AppTheme.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.cyan,
                    backgroundColor: AppTheme.surfaceLight,
                    side: BorderSide(
                      color: isSelected ? AppTheme.cyan : AppTheme.dividerColor,
                      width: isSelected ? 1.5 : 1,
                    ),
                    onSelected: (_) => _onGenreSelected(g.name, g.example),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 2. Campo de Entrada da Ideia / Descrição
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, color: AppTheme.soloYellow, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          l10n.translate('composer_prompt_label'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _promptController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Descreva a sua ideia (ex: Letra sobre fé e esperança no violão...)',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _promptController.clear(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // 3. Ajustes de Clima, Tom e Andamento
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Clima / Mood
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.translate('composer_mood'), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedMood,
                                isExpanded: true,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) => setState(() => _selectedMood = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Tom Musical
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.translate('composer_key'), style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: _selectedKey,
                                isExpanded: true,
                                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                items: _keys.map((k) => DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontSize: 12)))).toList(),
                                onChanged: (v) => setState(() => _selectedKey = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Andamento: $_selectedBpm BPM', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Expanded(
                          child: Slider(
                            value: _selectedBpm.toDouble(),
                            min: 50,
                            max: 160,
                            divisions: 22,
                            label: '$_selectedBpm BPM',
                            onChanged: (v) => setState(() => _selectedBpm = v.round()),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. Botão de Composição
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerateSong,
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(
                _isGenerating ? l10n.translate('composer_generating') : 'Compor Música $_selectedGenre ✨',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ).animate(target: _isGenerating ? 1 : 0).shimmer(duration: 1200.ms),

            const SizedBox(height: 20),

            // 5. Card com a Música Gerada
            if (_generatedSong != null) ...[
              Card(
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.cyan, width: 1.5),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.library_music, color: AppTheme.cyan, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _generatedSong!.title,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${_generatedSong!.genre} • ${_generatedSong!.mood} • ${_generatedSong!.bpm} BPM',
                                  style: const TextStyle(color: AppTheme.cyan, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.dividerColor, height: 24),

                      // Player de Prévia Sonora
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            IconButton.filled(
                              icon: Icon(_isPlayingPreview ? Icons.pause : Icons.play_arrow),
                              color: Colors.black,
                              style: IconButton.styleFrom(backgroundColor: AppTheme.cyan),
                              onPressed: _togglePlayPreview,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.translate('composer_preview_audio'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  Text(
                                    _isPlayingPreview ? 'Reproduzindo melodia gerada...' : 'Toque no Play para ouvir a melodia',
                                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Acordes
                      Text(
                        l10n.translate('composer_chords'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        children: _generatedSong!.chords.map((chord) {
                          return Chip(
                            backgroundColor: AppTheme.surfaceLight,
                            label: Text(
                              chord,
                              style: const TextStyle(
                                color: AppTheme.cyan,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            side: const BorderSide(color: AppTheme.cyan, width: 0.8),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Estrutura
                      Text(
                        l10n.translate('composer_structure'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      ..._generatedSong!.structure.map((sec) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppTheme.purple, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(sec.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '(${sec.chords.join(' - ')}) • ${sec.description}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 14),

                      // Letra Gerada
                      Text(
                        l10n.translate('composer_lyrics'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _generatedSong!.lyrics,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppTheme.textPrimary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Botão de Exportação para o Estúdio DAW
                      ElevatedButton.icon(
                        onPressed: _exportToStudio,
                        icon: const Icon(Icons.mic, color: Colors.white),
                        label: Text(
                          l10n.translate('composer_export_daw'),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
            ],
          ],
        ),
      ),
    );
  }
}
