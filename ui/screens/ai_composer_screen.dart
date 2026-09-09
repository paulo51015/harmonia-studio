import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ai_song_model.dart';
import '../../services/ai_music_generator_service.dart';
import '../../services/studio_audio_engine.dart';
import '../../services/vocal_audio_service.dart';
import '../../theme/app_theme.dart';

/// Tela de Composição IA estilo Suno com Player Master, Melodia e Arranjo Completos,
/// Síntese de Voz Cantada em Português, Karaokê Sincronizado e Compartilhamento Nativo.
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
  final TextEditingController _customLyricsController = TextEditingController();
  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _stylePromptController = TextEditingController();

  final ScrollController _lyricsScrollController = ScrollController();

  final AiMusicGeneratorService _generatorService = AiMusicGeneratorService();
  final VocalAudioService _vocalAudioService = VocalAudioService();
  final AudioPlayer _audioPlayer = AudioPlayer();

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _activeLineSubscription;

  bool _isCustomMode = false;
  bool _isInstrumental = false;

  String _selectedGenre = 'Gospel / Louvor';
  String _selectedMood = 'Inspirador / Emocionante';
  String _selectedKey = 'G (Sol Maior)';
  String _selectedVocalStyle = 'Coral / Dueto Gospel';
  int _selectedBpm = 72;

  double _vocalVolume = 1.0;
  double _instrumentalVolume = 0.85;

  bool _isGenerating = false;
  String _generatingStatus = '';
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = const Duration(seconds: 140);

  AiSongModel? _songV1;
  AiSongModel? _songV2;
  int _selectedVariationIndex = 0; // 0 = Versão 1, 1 = Versão 2
  int? _activeLyricLineIndex;

  final List<({String name, String icon, String example, String defaultVocal})> _genresWithDetails = [
    (name: 'Gospel / Louvor', icon: '🙏', example: 'Um louvor de adoração suave e emocionante sobre fé e gratidão a Deus com piano acústico', defaultVocal: 'Coral / Dueto Gospel'),
    (name: 'Sertanejo', icon: '🤠', example: 'Um modão sertanejo romântico com arpejo de violão e refrão marcante', defaultVocal: 'Dupla Sertaneja'),
    (name: 'Romântica / Balada', icon: '❤️', example: 'Uma balada romântica apaixonada no piano sobre declaração de amor', defaultVocal: 'Voz Romântica & Pop'),
    (name: 'Acústico / MPB', icon: '🎸', example: 'Uma levada suave de violão estilo MPB sobre um fim de tarde', defaultVocal: 'Voz Feminina Suave'),
    (name: 'Forró / Piseiro', icon: '🪗', example: 'Um forró animado e dançante com ritmo de sanfona e festa', defaultVocal: 'Voz Masculina Encorpada'),
    (name: 'Rock / Pop Rock', icon: '⚡', example: 'Um pop rock enérgico com riff de guitarra e bateria contagiante', defaultVocal: 'Voz Masculina Encorpada'),
    (name: 'Lo-Fi Chill', icon: '☕', example: 'Uma melodia relaxante de piano lo-fi para estudar e descansar', defaultVocal: 'Instrumental Puro'),
  ];

  final List<String> _vocalStyles = [
    'Voz Feminina Suave',
    'Voz Masculina Encorpada',
    'Coral / Dueto Gospel',
    'Dupla Sertaneja',
    'Voz Romântica & Pop',
    'Instrumental Puro',
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
  void initState() {
    super.initState();
    _vocalAudioService.init();
    _initAudioPlayer();
  }

  void _initAudioPlayer() {
    _audioPlayer.setVolume(_instrumentalVolume);

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _playerState = state);
        if (state == PlayerState.paused) {
          _vocalAudioService.pause();
        } else if (state == PlayerState.stopped || state == PlayerState.completed) {
          _vocalAudioService.stop();
        }
      }
    });

    _positionSubscription = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
        final song = _currentSong;
        if (song != null && song.timedLyrics.isNotEmpty && _playerState == PlayerState.playing) {
          _vocalAudioService.syncPlayback(pos, song.timedLyrics);
        }
      }
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((dur) {
      if (mounted && dur.inSeconds > 0) setState(() => _duration = dur);
    });

    _activeLineSubscription = _vocalAudioService.activeLineStream.listen((lineIndex) {
      if (mounted && _activeLyricLineIndex != lineIndex) {
        setState(() => _activeLyricLineIndex = lineIndex);
        _scrollToActiveLine(lineIndex);
      }
    });
  }

  void _scrollToActiveLine(int? index) {
    if (index == null || !_lyricsScrollController.hasClients) return;
    final targetOffset = (index * 42.0).clamp(0.0, _lyricsScrollController.position.maxScrollExtent);
    _lyricsScrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    _activeLineSubscription?.cancel();
    _audioPlayer.dispose();
    _vocalAudioService.dispose();
    _promptController.dispose();
    _customLyricsController.dispose();
    _customTitleController.dispose();
    _stylePromptController.dispose();
    _lyricsScrollController.dispose();
    super.dispose();
  }

  AiSongModel? get _currentSong {
    if (_selectedVariationIndex == 1 && _songV2 != null) return _songV2;
    return _songV1;
  }

  void _onGenreSelected(String genre, String examplePrompt, String defaultVocal) {
    setState(() {
      _selectedGenre = genre;
      _selectedVocalStyle = defaultVocal;
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

  void _insertStructureTag(String tag) {
    final text = _customLyricsController.text;
    final selection = _customLyricsController.selection;
    final newText = text.replaceRange(selection.start, selection.end, '\n$tag\n');
    _customLyricsController.text = newText;
    _customLyricsController.selection = TextSelection.collapsed(offset: selection.start + tag.length + 2);
  }

  void _gerarLetraAutomatica() {
    final tema = _promptController.text.trim().isNotEmpty ? _promptController.text : _selectedGenre;
    final lyrics = _generatorService.generateLyricsOnly(
      themePrompt: tema,
      genre: _selectedGenre,
      mood: _selectedMood,
    );
    setState(() {
      _customLyricsController.text = lyrics;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Letra poética gerada com sucesso com tags de estrutura! ✨'),
        backgroundColor: AppTheme.successGreen,
      ),
    );
  }

  Future<void> _handleGenerateSong() async {
    final promptText = _isCustomMode
        ? (_stylePromptController.text.trim().isNotEmpty ? _stylePromptController.text : _selectedGenre)
        : _promptController.text.trim();

    if (promptText.isEmpty && !_isCustomMode) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite sua ideia ou escolha um estilo musical abaixo!'),
          backgroundColor: AppTheme.recRed,
        ),
      );
      return;
    }

    await _audioPlayer.stop();
    await _vocalAudioService.stop();

    setState(() {
      _isGenerating = true;
      _generatingStatus = '1/3 - Compondo harmonia e letra poética...';
      _selectedVariationIndex = 0;
      _position = Duration.zero;
      _activeLyricLineIndex = null;
    });

    try {
      setState(() => _generatingStatus = '2/3 - Sintetizando voz cantada em Português...');
      final songV1 = await _generatorService.generateSongFromPrompt(
        prompt: promptText,
        customTitle: _isCustomMode ? _customTitleController.text : null,
        customLyrics: _isCustomMode ? _customLyricsController.text : null,
        selectedGenre: _selectedGenre,
        selectedMood: _selectedMood,
        selectedKey: _selectedKey,
        selectedVocalStyle: _selectedVocalStyle,
        isInstrumental: _isInstrumental,
        customBpm: _selectedBpm,
      );

      setState(() {
        _generatingStatus = '3/3 - Finalizando master e faixas duplas...';
        _songV1 = songV1;
        _songV2 = songV1.variations.isNotEmpty ? songV1.variations.first : null;
        _isGenerating = false;
      });

      // Carrega o áudio gerado no player
      if (songV1.audioFilePath != null) {
        await _audioPlayer.setSource(DeviceFileSource(songV1.audioFilePath!));
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao compor música: $e'), backgroundColor: AppTheme.recRed),
        );
      }
    }
  }

  Future<void> _togglePlayMaster() async {
    final song = _currentSong;
    if (song == null || song.audioFilePath == null) return;

    if (_playerState == PlayerState.playing) {
      await _audioPlayer.pause();
      await _vocalAudioService.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(song.audioFilePath!));
      if (song.timedLyrics.isNotEmpty) {
        _vocalAudioService.syncPlayback(_position, song.timedLyrics);
      }
    }
  }

  Future<void> _trocarVariacao(int index) async {
    await _audioPlayer.stop();
    await _vocalAudioService.stop();

    setState(() {
      _selectedVariationIndex = index;
      _position = Duration.zero;
      _activeLyricLineIndex = null;
    });

    final song = _currentSong;
    if (song?.audioFilePath != null) {
      await _audioPlayer.setSource(DeviceFileSource(song!.audioFilePath!));
      await _audioPlayer.play(DeviceFileSource(song.audioFilePath!));
    }
  }

  Future<void> _compartilharAudioEletra() async {
    final song = _currentSong;
    if (song == null) return;

    final shareText = '''
🎵 *${song.title}*
Estilo: ${song.genre} | Voz: ${song.vocalStyle} | Tom: ${song.musicalKey} | ${song.bpm} BPM

🎶 *Acordes:* ${song.chords.join(' - ')}

📜 *Letra:*
${song.lyrics}

✨ Criado com Harmonia Studio AI (Suno Engine)
''';

    if (song.audioFilePath != null) {
      final file = XFile(song.audioFilePath!);
      await Share.shareXFiles(
        [file],
        text: shareText,
        subject: 'Música Criada - ${song.title}',
      );
    } else {
      await Share.share(shareText, subject: 'Música Criada - ${song.title}');
    }
  }

  void _abrirModalEstender() {
    final song = _currentSong;
    if (song == null) return;

    String tipoExtensao = 'Solo Instrumental & Refrão';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Row(
            children: [
              Icon(Icons.more_time, color: AppTheme.cyan),
              SizedBox(width: 8),
              Text('Estender Canção (Extend Clip)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Escolha como deseja continuar e expandir a música:',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              RadioListTile<String>(
                value: 'Solo Instrumental & Refrão',
                groupValue: tipoExtensao,
                title: const Text('Solo Instrumental & Refrão Épico', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.cyan,
                dense: true,
                onChanged: (v) => setModalState(() => tipoExtensao = v!),
              ),
              RadioListTile<String>(
                value: 'Ponte & Refrão Final',
                groupValue: tipoExtensao,
                title: const Text('Ponte Emocionante & Refrão Final', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.cyan,
                dense: true,
                onChanged: (v) => setModalState(() => tipoExtensao = v!),
              ),
              RadioListTile<String>(
                value: 'Finalização / Outro',
                groupValue: tipoExtensao,
                title: const Text('Finalização / Fade Out Suave', style: TextStyle(fontSize: 13)),
                activeColor: AppTheme.cyan,
                dense: true,
                onChanged: (v) => setModalState(() => tipoExtensao = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _audioPlayer.stop();
                await _vocalAudioService.stop();
                setState(() {
                  _isGenerating = true;
                  _generatingStatus = 'Estendendo seções e arranjo...';
                });
                final extended = await _generatorService.extendSong(
                  originalSong: song,
                  extensionType: tipoExtensao,
                );
                setState(() {
                  _songV1 = extended;
                  _isGenerating = false;
                });
                if (extended.audioFilePath != null) {
                  await _audioPlayer.setSource(DeviceFileSource(extended.audioFilePath!));
                  await _audioPlayer.play(DeviceFileSource(extended.audioFilePath!));
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Música estendida com novas seções com sucesso! 🎶'), backgroundColor: AppTheme.successGreen),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.cyan, foregroundColor: Colors.black),
              child: const Text('ESTENDER AGORA'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportToStudio() async {
    final song = _currentSong;
    if (song == null) return;

    await _audioPlayer.stop();
    await _vocalAudioService.stop();
    final l10n = AppLocalizations.of(context);
    final success = await _generatorService.exportSongToStudioDaw(song, widget.studioEngine);

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

  void _copiarCifraEletra() {
    final song = _currentSong;
    if (song == null) return;

    final text = '''
🎵 ${song.title}
Estilo: ${song.genre} | Tom: ${song.musicalKey} | Andamento: ${song.bpm} BPM | Voz: ${song.vocalStyle}

Acordes da Canção: ${song.chords.join(' - ')}

${song.lyrics}

Criado com Harmonia Studio AI (Suno Engine)
''';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cifra e letra copiadas para a área de transferência! 📋'), backgroundColor: AppTheme.successGreen),
    );
  }

  String _formatDuration(Duration d) {
    final min = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  @override
  Widget build(BuildContext context) {
    final song = _currentSong;
    final isPlaying = _playerState == PlayerState.playing;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: AppTheme.cyan),
            SizedBox(width: 8),
            Text('Compositor IA'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Alternador de Modo: Simples vs Custom (Suno)
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.dividerColor),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCustomMode = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isCustomMode ? AppTheme.cyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.flash_on, size: 16, color: !_isCustomMode ? Colors.black : Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'Modo Simples',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: !_isCustomMode ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCustomMode = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCustomMode ? AppTheme.cyan : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.tune, size: 16, color: _isCustomMode ? Colors.black : Colors.white70),
                            const SizedBox(width: 6),
                            Text(
                              'Modo Custom (Suno)',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: _isCustomMode ? Colors.black : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Seletor Claro: Com Voz Cantada vs Apenas Instrumental
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !_isInstrumental ? AppTheme.cyan.withOpacity(0.4) : AppTheme.dividerColor,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    !_isInstrumental ? Icons.record_voice_over : Icons.music_note,
                    color: !_isInstrumental ? AppTheme.cyan : AppTheme.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !_isInstrumental ? 'Música com Voz Cantada & Letra' : 'Apenas Instrumental (Sem Voz)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          !_isInstrumental ? 'Sintetiza melodia vocal em Português' : 'Gera apenas o playback instrumental',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: !_isInstrumental,
                    activeColor: AppTheme.cyan,
                    onChanged: (hasVoice) => setState(() => _isInstrumental = !hasVoice),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. CONTEÚDO DO MODO SIMPLES
            if (!_isCustomMode) ...[
              const Text(
                'Escolha o Estilo Musical:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _genresWithDetails.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final g = _genresWithDetails[index];
                    final isSelected = _selectedGenre == g.name;

                    return FilterChip(
                      avatar: Text(g.icon, style: const TextStyle(fontSize: 15)),
                      label: Text(
                        g.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.black : AppTheme.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppTheme.cyan,
                      backgroundColor: AppTheme.surfaceLight,
                      onSelected: (_) => _onGenreSelected(g.name, g.example, g.defaultVocal),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline, color: AppTheme.soloYellow, size: 18),
                          SizedBox(width: 8),
                          Text('Descrição da Música / Ideia:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _promptController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Descreva sua canção (ex: Um louvor de adoração sobre gratidão a Deus com piano acústico e melodia suave...)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // 3. CONTEÚDO DO MODO CUSTOM (SUNO)
            if (_isCustomMode) ...[
              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.lyrics, color: AppTheme.cyan, size: 18),
                              SizedBox(width: 8),
                              Text('Letra da Música (Custom Lyrics):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _gerarLetraAutomatica,
                            icon: const Icon(Icons.auto_awesome, size: 14, color: AppTheme.cyan),
                            label: const Text('Gerar Letra IA', style: TextStyle(fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTagButton('[Verso 1]'),
                            _buildTagButton('[Pré-Refrão]'),
                            _buildTagButton('[Refrão]'),
                            _buildTagButton('[Verso 2]'),
                            _buildTagButton('[Ponte]'),
                            _buildTagButton('[Solo]'),
                            _buildTagButton('[Final]'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customLyricsController,
                        maxLines: 6,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                        decoration: const InputDecoration(
                          hintText: 'Escreva ou cole sua letra aqui...',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              Card(
                color: AppTheme.surface,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _customTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Título da Canção (Opcional)',
                          prefixIcon: Icon(Icons.title, color: AppTheme.cyan),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _stylePromptController,
                        decoration: const InputDecoration(
                          labelText: 'Estilo de Música (Tags / Style Prompt)',
                          hintText: 'ex: acoustic gospel, warm piano, 72 bpm, female vocals',
                          prefixIcon: Icon(Icons.music_note, color: AppTheme.cyan),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: _selectedVocalStyle,
                        decoration: const InputDecoration(
                          labelText: 'Estilo Vocal / Tipo de Voz',
                          prefixIcon: Icon(Icons.record_voice_over, color: AppTheme.cyan),
                        ),
                        items: _vocalStyles.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 13)))).toList(),
                        onChanged: (v) => setState(() => _selectedVocalStyle = v!),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),

            // 4. Painel de Ajustes Harmônicos
            Card(
              color: AppTheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedMood,
                            decoration: const InputDecoration(labelText: 'Clima / Mood'),
                            items: _moods.map((m) => DropdownMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setState(() => _selectedMood = v!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedKey,
                            decoration: const InputDecoration(labelText: 'Tom Musical'),
                            items: _keys.map((k) => DropdownMenuItem(value: k, child: Text(k, style: const TextStyle(fontSize: 11)))).toList(),
                            onChanged: (v) => setState(() => _selectedKey = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Andamento: $_selectedBpm BPM', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Slider(
                            value: _selectedBpm.toDouble(),
                            min: 50,
                            max: 160,
                            divisions: 22,
                            activeColor: AppTheme.cyan,
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

            // 5. Botão de Composição
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _handleGenerateSong,
              icon: _isGenerating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : const Icon(Icons.auto_awesome, color: Colors.black),
              label: Text(
                _isGenerating ? _generatingStatus : 'Criar Canção com Voz e Melodia (Versões 1 e 2) ✨',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.cyan,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ).animate(target: _isGenerating ? 1 : 0).shimmer(duration: 1200.ms),

            const SizedBox(height: 20),

            // 6. PLAYER MASTER COM VOZ CANTADA E KARAOKÊ
            if (song != null) ...[
              // Seletor de Variações Suno (Versão 1 vs Versão 2)
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.music_video, size: 14),
                          SizedBox(width: 6),
                          Text('Versão 1 (Principal)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      selected: _selectedVariationIndex == 0,
                      selectedColor: AppTheme.cyan,
                      backgroundColor: AppTheme.surfaceLight,
                      labelStyle: TextStyle(color: _selectedVariationIndex == 0 ? Colors.black : Colors.white),
                      onSelected: (_) => _trocarVariacao(0),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.alt_route, size: 14),
                          SizedBox(width: 6),
                          Text('Versão 2 (Acústica)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                      selected: _selectedVariationIndex == 1,
                      selectedColor: AppTheme.purple,
                      backgroundColor: AppTheme.surfaceLight,
                      labelStyle: const TextStyle(color: Colors.white),
                      onSelected: (_) => _trocarVariacao(1),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Card(
                color: AppTheme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: _selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple,
                    width: 1.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cabeçalho da Canção
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.black, size: 26),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  song.title,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${song.genre} • ${song.vocalStyle} • ${song.bpm} BPM • Tom ${song.musicalKey}',
                                  style: TextStyle(
                                    color: _selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppTheme.dividerColor, height: 20),

                      // Player Master com Seekbar e Ondas Sonoras
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            // Botão Play/Pause e Visualizador
                            Row(
                              children: [
                                IconButton.filled(
                                  icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, size: 28),
                                  color: Colors.black,
                                  style: IconButton.styleFrom(
                                    backgroundColor: _selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple,
                                    padding: const EdgeInsets.all(12),
                                  ),
                                  onPressed: _togglePlayMaster,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isPlaying ? 'Tocando: Voz Cantada + Arranjo 🎶' : 'Toque no Play para ouvir com voz e melodia',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 6),
                                      // Visualizador de Ondas Sonoras
                                      Row(
                                        children: List.generate(28, (i) {
                                          final posSec = _position.inSeconds;
                                          final isCurrent = isPlaying && ((posSec + i) % 7 == 0);
                                          final barHeight = 8.0 + ((i * 5 + posSec * 3) % 22);

                                          return Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                              height: isCurrent ? barHeight * 1.4 : barHeight,
                                              decoration: BoxDecoration(
                                                color: isCurrent
                                                    ? AppTheme.soloYellow
                                                    : (_selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple).withOpacity(0.7),
                                                borderRadius: BorderRadius.circular(2),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Seekbar / Slider de Progresso
                            Slider(
                              value: _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                              min: 0.0,
                              max: _duration.inSeconds > 0 ? _duration.inSeconds.toDouble() : 140.0,
                              activeColor: _selectedVariationIndex == 0 ? AppTheme.cyan : AppTheme.purple,
                              onChanged: (val) async {
                                final newPos = Duration(seconds: val.round());
                                await _audioPlayer.seek(newPos);
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_formatDuration(_position), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                  Text(_formatDuration(_duration), style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ],
                              ),
                            ),

                            // Controles de Volume (Voz e Arranjo)
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.mic, size: 16, color: AppTheme.cyan),
                                  const SizedBox(width: 4),
                                  const Text('Voz:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Slider(
                                      value: _vocalVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: AppTheme.cyan,
                                      onChanged: (v) {
                                        setState(() => _vocalVolume = v);
                                        _vocalAudioService.setVocalVolume(v);
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.music_note, size: 16, color: AppTheme.purple),
                                  const SizedBox(width: 4),
                                  const Text('Base:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  Expanded(
                                    child: Slider(
                                      value: _instrumentalVolume,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: AppTheme.purple,
                                      onChanged: (v) {
                                        setState(() => _instrumentalVolume = v);
                                        _audioPlayer.setVolume(v);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Botão Destaque: COMPARTILHAR MÚSICA & LETRA NO WHATSAPP
                      ElevatedButton.icon(
                        onPressed: _compartilharAudioEletra,
                        icon: const Icon(Icons.share, color: Colors.black, size: 20),
                        label: const Text(
                          'COMPARTILHAR MÚSICA & LETRA (WhatsApp / Redes)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Acordes
                      Row(
                        children: [
                          const Text('Acordes:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textSecondary)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              children: song.chords.map((c) => Chip(
                                label: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
                                backgroundColor: AppTheme.surfaceLight,
                                side: const BorderSide(color: AppTheme.cyan, width: 0.8),
                                padding: EdgeInsets.zero,
                              )).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // VISUALIZADOR DE LETRA SINCRONIZADA EM KARAOKÊ
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Letra & Karaokê Sincronizado:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimary),
                          ),
                          Text(
                            isPlaying ? 'Cantando agora... 🎤' : 'Acompanhe a letra',
                            style: const TextStyle(fontSize: 11, color: AppTheme.soloYellow, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      Container(
                        height: 240,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isPlaying ? AppTheme.cyan.withOpacity(0.5) : AppTheme.dividerColor,
                          ),
                        ),
                        child: song.timedLyrics.isNotEmpty
                            ? ListView.builder(
                                controller: _lyricsScrollController,
                                itemCount: song.timedLyrics.length,
                                itemBuilder: (context, index) {
                                  final line = song.timedLyrics[index];
                                  final isActive = _activeLyricLineIndex == index;

                                  return GestureDetector(
                                    onTap: () async {
                                      final targetPos = Duration(milliseconds: (line.timestampSeconds * 1000).toInt());
                                      await _audioPlayer.seek(targetPos);
                                      if (_playerState != PlayerState.playing) {
                                        await _audioPlayer.play(DeviceFileSource(song.audioFilePath!));
                                      }
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 250),
                                      margin: const EdgeInsets.symmetric(vertical: 3),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isActive ? AppTheme.cyan.withOpacity(0.18) : Colors.transparent,
                                        borderRadius: BorderRadius.circular(8),
                                        border: isActive ? Border.all(color: AppTheme.cyan, width: 1.2) : null,
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (isActive)
                                            const Padding(
                                              padding: EdgeInsets.only(right: 6, top: 2),
                                              child: Icon(Icons.music_note, size: 14, color: AppTheme.soloYellow),
                                            ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                if (index == 0 || song.timedLyrics[index - 1].section != line.section)
                                                  Padding(
                                                    padding: const EdgeInsets.only(bottom: 2),
                                                    child: Text(
                                                      line.section,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isActive ? AppTheme.cyan : AppTheme.textSecondary,
                                                      ),
                                                    ),
                                                  ),
                                                Text(
                                                  line.text,
                                                  style: TextStyle(
                                                    fontSize: isActive ? 14 : 12,
                                                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                                    color: isActive ? AppTheme.soloYellow : AppTheme.textPrimary,
                                                    height: 1.4,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : SingleChildScrollView(
                                child: Text(
                                  song.lyrics,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    height: 1.6,
                                    color: AppTheme.textPrimary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),

                      // Botões de Ações (Estender, Cifra, DAW)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _abrirModalEstender,
                              icon: const Icon(Icons.more_time, size: 16, color: AppTheme.cyan),
                              label: const Text('Estender', style: TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.cyan)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _copiarCifraEletra,
                              icon: const Icon(Icons.copy, size: 16, color: AppTheme.soloYellow),
                              label: const Text('Cifra / Letra', style: TextStyle(color: AppTheme.soloYellow, fontSize: 12, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.soloYellow)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      ElevatedButton.icon(
                        onPressed: _exportToStudio,
                        icon: const Icon(Icons.mic, color: Colors.white),
                        label: const Text('GRAVAR VOZ NO ESTÚDIO (4 PISTAS)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTagButton(String tag) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(tag, style: const TextStyle(fontSize: 10, color: AppTheme.cyan, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surfaceLight,
        side: const BorderSide(color: AppTheme.cyan, width: 0.8),
        padding: EdgeInsets.zero,
        onPressed: () => _insertStructureTag(tag),
      ),
    );
  }
}
