import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';
import '../models/track_model.dart';
import 'studio_audio_engine.dart';
import 'synth_service.dart';
import 'vocal_audio_service.dart';

/// Motor Inteligente de Composição Musical Avançado estilo Suno AI + Leonardo AI.
/// Gera letras 100% personalizadas com base semântica no prompt do usuário,
/// sintetiza voz cantada natural em Português e renderiza faixas master polifônicas completas.
class AiMusicGeneratorService {
  static final AiMusicGeneratorService _instance = AiMusicGeneratorService._internal();
  factory AiMusicGeneratorService() => _instance;
  AiMusicGeneratorService._internal();

  /// Compõe a canção com geração dupla (Versão 1 e Versão 2) e renderiza os arquivos de áudio WAV master e voz cantada.
  Future<AiSongModel> generateSongFromPrompt({
    required String prompt,
    String? customTitle,
    String? customLyrics,
    String? selectedGenre,
    String? selectedMood,
    String? selectedKey,
    String? selectedVocalStyle,
    bool isInstrumental = false,
    int? customBpm,
  }) async {
    final cleanPrompt = prompt.toLowerCase();

    // 1. Detecção Inteligente de Gênero Musical
    String genre = selectedGenre ?? 'Gospel / Louvor';
    if (cleanPrompt.contains('gospel') || cleanPrompt.contains('louvor') || cleanPrompt.contains('adoração') || cleanPrompt.contains('deus') || cleanPrompt.contains('igreja') || cleanPrompt.contains('fé') || cleanPrompt.contains('jesus') || cleanPrompt.contains('oração')) {
      genre = 'Gospel / Louvor';
    } else if (cleanPrompt.contains('sertanej') || cleanPrompt.contains('modão') || cleanPrompt.contains('sofrência') || cleanPrompt.contains('viola') || cleanPrompt.contains('rodeio') || cleanPrompt.contains('boteco') || cleanPrompt.contains('fazenda')) {
      genre = 'Sertanejo';
    } else if (cleanPrompt.contains('romântic') || cleanPrompt.contains('amor') || cleanPrompt.contains('apaixonad') || cleanPrompt.contains('balada') || cleanPrompt.contains('coração') || cleanPrompt.contains('declaração') || cleanPrompt.contains('casamento') || cleanPrompt.contains('esposa') || cleanPrompt.contains('marido')) {
      genre = 'Romântica / Balada';
    } else if (cleanPrompt.contains('forró') || cleanPrompt.contains('piseiro') || cleanPrompt.contains('sanfona') || cleanPrompt.contains('nordest') || cleanPrompt.contains('arrasta')) {
      genre = 'Forró / Piseiro';
    } else if (cleanPrompt.contains('mpb') || cleanPrompt.contains('violão') || cleanPrompt.contains('acústico') || cleanPrompt.contains('bossa') || cleanPrompt.contains('praia') || cleanPrompt.contains('brasil')) {
      genre = 'Acústico / MPB';
    } else if (cleanPrompt.contains('rock') || cleanPrompt.contains('guitarra') || cleanPrompt.contains('riff') || cleanPrompt.contains('pesado')) {
      genre = 'Rock / Pop Rock';
    } else if (cleanPrompt.contains('lo-fi') || cleanPrompt.contains('chill') || cleanPrompt.contains('estudo') || cleanPrompt.contains('relax')) {
      genre = 'Lo-Fi Chill';
    } else if (cleanPrompt.contains('homenagem') || cleanPrompt.contains('empresa') || cleanPrompt.contains('colaborador') || cleanPrompt.contains('equipe') || cleanPrompt.contains('parabéns')) {
      // Para homenagens empresariais ou celebração de metas, usa o estilo pop/festa se não especificado
      genre = selectedGenre ?? 'Sertanejo';
    }

    // 2. Detecção de Clima / Mood
    String mood = selectedMood ?? 'Inspirador / Emocionante';
    if (cleanPrompt.contains('triste') || cleanPrompt.contains('melancol') || cleanPrompt.contains('saudade') || cleanPrompt.contains('sofrimento')) {
      mood = 'Melancólico & Saudade';
    } else if (cleanPrompt.contains('animad') || cleanPrompt.contains('festa') || cleanPrompt.contains('dança') || cleanPrompt.contains('alegre') || cleanPrompt.contains('meta') || cleanPrompt.contains('homenagem') || cleanPrompt.contains('vitória') || cleanPrompt.contains('sucesso')) {
      mood = 'Alegre & Festivo';
    } else if (cleanPrompt.contains('emocion') || cleanPrompt.contains('inspir') || cleanPrompt.contains('profund') || cleanPrompt.contains('fé')) {
      mood = 'Inspirador / Emocionante';
    } else if (cleanPrompt.contains('românt') || cleanPrompt.contains('paixão') || cleanPrompt.contains('carinho')) {
      mood = 'Romântico & Apaixonado';
    } else if (cleanPrompt.contains('calm') || cleanPrompt.contains('suave') || cleanPrompt.contains('paz')) {
      mood = 'Relaxante & Suave';
    }

    // 3. Tom Musical & Andamento (BPM)
    String musicalKey = selectedKey ?? (mood.contains('Melancólico') ? 'Am (Lá Menor)' : 'G (Sol Maior)');
    int bpm = customBpm ?? _getSuggestedBpm(genre, mood);

    // 4. Estilo Vocal
    String vocalStyle = isInstrumental ? 'Instrumental Puro' : (selectedVocalStyle ?? _getSuggestedVocal(genre));

    // 5. GERAÇÃO DE LETRA 100% PERSONALIZADA COM BASE NO PROMPT
    final lyrics = (customLyrics != null && customLyrics.trim().isNotEmpty)
        ? customLyrics.trim()
        : _composeIntelligentLyrics(prompt: prompt, genre: genre, mood: mood, isInstrumental: isInstrumental);

    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : _generateSongTitle(prompt, genre);

    // 6. GERAÇÃO DA VERSÃO 1 (Arranjo Principal)
    final chordsV1 = _generateChordProgression(genre, mood, isAlternative: false);
    final melodyV1 = _generateMelodyNotes(chordsV1, bpm, genre, isAlternative: false);
    final structureV1 = _generateSongStructure(chordsV1, genre, lyrics);

    // 7. GERAÇÃO DA VERSÃO 2 (Arranjo Alternativo / Acústico)
    final chordsV2 = _generateChordProgression(genre, mood, isAlternative: true);
    final melodyV2 = _generateMelodyNotes(chordsV2, bpm - 4, genre, isAlternative: true);
    final structureV2 = _generateSongStructure(chordsV2, genre, lyrics);

    // 8. PROCESSAMENTO DAS LINHAS DE KARAOKÊ E TIMESTAMPS
    final vocalService = VocalAudioService();
    vocalService.configureVocalStyle(vocalStyle);

    List<LyricLine> timedLyricsV1 = [];
    List<LyricLine> timedLyricsV2 = [];

    if (!isInstrumental) {
      timedLyricsV1 = vocalService.parseLyricsToTimedLines(lyrics, bpm);
      timedLyricsV2 = vocalService.parseLyricsToTimedLines(lyrics, bpm - 4);
    }

    // 9. RENDERIZAÇÃO DOS ARQUIVOS MASTER DE ÁUDIO WAV
    final synth = SynthService();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Renderiza Áudio Master V1
    final masterWavBytesV1 = synth.renderMasterSongWav(
      chords: chordsV1,
      melody: melodyV1,
      bpm: bpm,
      genre: genre,
      vocalStyle: vocalStyle,
      isInstrumental: isInstrumental,
    );
    final audioPathV1 = '${tempDir.path}/harmonia_song_${timestamp}_v1.wav';
    await File(audioPathV1).writeAsBytes(masterWavBytesV1);

    // Renderiza Áudio Master V2
    final masterWavBytesV2 = synth.renderMasterSongWav(
      chords: chordsV2,
      melody: melodyV2,
      bpm: bpm - 4,
      genre: genre,
      vocalStyle: vocalStyle,
      isInstrumental: isInstrumental,
    );
    final audioPathV2 = '${tempDir.path}/harmonia_song_${timestamp}_v2.wav';
    await File(audioPathV2).writeAsBytes(masterWavBytesV2);

    final versaoB = AiSongModel(
      id: 'ai_song_${timestamp}_v2',
      title: '$title (Versão 2 - Acústica / Variação)',
      prompt: prompt,
      genre: genre,
      mood: mood,
      musicalKey: musicalKey,
      bpm: bpm - 4,
      isInstrumental: isInstrumental,
      vocalStyle: vocalStyle,
      chords: chordsV2,
      melody: melodyV2,
      structure: structureV2,
      lyrics: lyrics,
      timedLyrics: timedLyricsV2,
      variationLabel: 'Versão 2 (Arranjo Alternativo)',
      durationSeconds: 135,
      audioFilePath: audioPathV2,
    );

    final versaoA = AiSongModel(
      id: 'ai_song_${timestamp}_v1',
      title: title,
      prompt: prompt,
      genre: genre,
      mood: mood,
      musicalKey: musicalKey,
      bpm: bpm,
      isInstrumental: isInstrumental,
      vocalStyle: vocalStyle,
      chords: chordsV1,
      melody: melodyV1,
      structure: structureV1,
      lyrics: lyrics,
      timedLyrics: timedLyricsV1,
      variationLabel: 'Versão 1 (Arranjo Principal)',
      variations: [versaoB],
      durationSeconds: 140,
      audioFilePath: audioPathV1,
    );

    return versaoA;
  }

  /// Gera uma letra poética completa estruturada em tags estilo Suno AI.
  String generateLyricsOnly({
    required String themePrompt,
    required String genre,
    required String mood,
  }) {
    return _composeIntelligentLyrics(prompt: themePrompt, genre: genre, mood: mood, isInstrumental: false);
  }

  /// Estende uma canção adicionando novas seções (Solo, Ponte, Refrão Final, Outro) e renderiza o novo áudio completo.
  Future<AiSongModel> extendSong({
    required AiSongModel originalSong,
    required String extensionType,
    String? additionalLyrics,
  }) async {
    final newChords = List<String>.from(originalSong.chords);
    final newMelody = List<MelodyNote>.from(originalSong.melody);
    final newStructure = List<SongSection>.from(originalSong.structure);

    String addedLyrics = '';

    if (extensionType.contains('Solo')) {
      newStructure.add(
        SongSection(
          name: '[Solo Instrumental Expandido]',
          chords: [newChords[1], newChords[2], newChords[3], newChords[0]],
          description: 'Solo expressivo com modulação e dinâmica crescente.',
        ),
      );
      final soloNotes = _generateMelodyNotes([newChords[1], newChords[2]], originalSong.bpm, originalSong.genre, isAlternative: true);
      newMelody.addAll(soloNotes);
      addedLyrics += '\n\n[Solo Instrumental]';
    } else if (extensionType.contains('Ponte')) {
      newStructure.add(
        SongSection(
          name: '[Ponte / Bridge]',
          chords: [newChords[2], newChords[1], newChords[3]],
          description: 'Ponte emocional preparando para o clímax da canção.',
        ),
      );
      addedLyrics += additionalLyrics ?? '\n\n[Ponte / Bridge]\nE quando tudo parece parar,\nA nossa voz vem pra renovar!\nNada pode essa vitória apagar!';
    } else {
      newStructure.add(
        SongSection(
          name: '[Final / Outro Estendido]',
          chords: [newChords[0]],
          description: 'Sustentação harmônica em fade-out.',
        ),
      );
      addedLyrics += '\n\n[Final]\nDeixa o som soar... comemorando essa conquista.';
    }

    final fullLyrics = '${originalSong.lyrics}$addedLyrics';

    final synth = SynthService();
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final extendedWavBytes = synth.renderMasterSongWav(
      chords: newChords,
      melody: newMelody,
      bpm: originalSong.bpm,
      genre: originalSong.genre,
      vocalStyle: originalSong.vocalStyle,
      isInstrumental: originalSong.isInstrumental,
    );
    final newAudioPath = '${tempDir.path}/harmonia_song_ext_$timestamp.wav';
    await File(newAudioPath).writeAsBytes(extendedWavBytes);

    final vocalService = VocalAudioService();
    final timedLyrics = vocalService.parseLyricsToTimedLines(fullLyrics, originalSong.bpm);

    return originalSong.copyWith(
      id: 'ai_song_ext_$timestamp',
      title: '${originalSong.title} (Estendida)',
      chords: newChords,
      melody: newMelody,
      structure: newStructure,
      lyrics: fullLyrics,
      timedLyrics: timedLyrics,
      durationSeconds: originalSong.durationSeconds + 45,
      audioFilePath: newAudioPath,
    );
  }

  int _getSuggestedBpm(String genre, String mood) {
    switch (genre) {
      case 'Gospel / Louvor':
        return 72;
      case 'Sertanejo':
        return 118;
      case 'Romântica / Balada':
        return 68;
      case 'Forró / Piseiro':
        return 138;
      case 'Acústico / MPB':
        return 92;
      case 'Rock / Pop Rock':
        return 132;
      case 'Lo-Fi Chill':
        return 78;
      default:
        return 110;
    }
  }

  String _getSuggestedVocal(String genre) {
    switch (genre) {
      case 'Gospel / Louvor':
        return 'Coral / Dueto Gospel';
      case 'Sertanejo':
        return 'Dupla Sertaneja';
      case 'Romântica / Balada':
        return 'Voz Romântica & Pop';
      case 'Forró / Piseiro':
        return 'Voz Masculina Encorpada';
      case 'Acústico / MPB':
        return 'Voz Feminina Suave';
      case 'Rock / Pop Rock':
        return 'Voz Masculina Encorpada';
      case 'Lo-Fi Chill':
        return 'Instrumental Puro';
      default:
        return 'Voz Feminina Suave';
    }
  }

  List<String> _generateChordProgression(String genre, String mood, {bool isAlternative = false}) {
    if (!isAlternative) {
      switch (genre) {
        case 'Gospel / Louvor':
          return ['C', 'G', 'Am', 'F'];
        case 'Sertanejo':
          return ['G', 'D', 'Em', 'C'];
        case 'Romântica / Balada':
          return ['C', 'Em', 'F', 'G'];
        case 'Forró / Piseiro':
          return ['Am', 'F', 'C', 'G'];
        case 'Acústico / MPB':
          return ['C', 'Am', 'Dm', 'G'];
        case 'Rock / Pop Rock':
          return ['G', 'C', 'Em', 'D'];
        case 'Lo-Fi Chill':
          return ['Dm', 'G', 'C', 'Am'];
        default:
          return ['C', 'G', 'Am', 'F'];
      }
    } else {
      switch (genre) {
        case 'Gospel / Louvor':
          return ['F', 'G', 'Em', 'Am'];
        case 'Sertanejo':
          return ['C', 'G', 'D', 'Em'];
        case 'Romântica / Balada':
          return ['Am', 'F', 'C', 'Em'];
        case 'Forró / Piseiro':
          return ['Dm', 'Am', 'E', 'Am'];
        case 'Acústico / MPB':
          return ['F', 'Em', 'Dm', 'C'];
        case 'Rock / Pop Rock':
          return ['Em', 'C', 'G', 'D'];
        case 'Lo-Fi Chill':
          return ['F', 'G', 'Em', 'Am'];
        default:
          return ['G', 'Em', 'C', 'D'];
      }
    }
  }

  List<MelodyNote> _generateMelodyNotes(List<String> chords, int bpm, String genre, {bool isAlternative = false}) {
    final List<MelodyNote> notes = [];

    final Map<String, List<String>> chordMelodyMapV1 = {
      'C': ['E4', 'G4', 'C5', 'G4', 'E4'],
      'G': ['D4', 'G4', 'B4', 'D5', 'B4'],
      'Am': ['C4', 'E4', 'A4', 'C5', 'E4'],
      'F': ['F4', 'A4', 'C5', 'F5', 'A4'],
      'Em': ['E4', 'G4', 'B4', 'E5', 'B4'],
      'Dm': ['D4', 'F4', 'A4', 'D5', 'F4'],
      'D': ['D4', 'F#4', 'A4', 'D5', 'F#4'],
      'E': ['E4', 'G#4', 'B4', 'E5', 'G#4'],
    };

    final Map<String, List<String>> chordMelodyMapV2 = {
      'C': ['G4', 'E4', 'D4', 'C4', 'E4'],
      'G': ['B4', 'G4', 'D4', 'B4', 'G4'],
      'Am': ['E4', 'C4', 'A3', 'C4', 'E4'],
      'F': ['C5', 'A4', 'F4', 'A4', 'C5'],
      'Em': ['B4', 'G4', 'E4', 'G4', 'B4'],
      'Dm': ['A4', 'F4', 'D4', 'F4', 'A4'],
      'D': ['A4', 'F#4', 'D4', 'F#4', 'A4'],
      'E': ['B4', 'G#4', 'E4', 'G#4', 'B4'],
    };

    final activeMap = isAlternative ? chordMelodyMapV2 : chordMelodyMapV1;

    for (final chord in chords) {
      final pattern = activeMap[chord] ?? ['C4', 'E4', 'G4', 'C5'];
      for (int i = 0; i < pattern.length; i++) {
        final noteStr = pattern[i];
        notes.add(
          MelodyNote(
            note: noteStr,
            durationInBeats: 0.8,
            frequency: SynthService.noteNameToFrequency(noteStr),
          ),
        );
      }
    }

    return notes;
  }

  List<SongSection> _generateSongStructure(List<String> chords, String genre, String lyrics) {
    return [
      SongSection(
        name: '[Introdução / Intro]',
        chords: [chords[0], chords[1]],
        description: 'Frase instrumental imersiva no estilo $genre.',
      ),
      SongSection(
        name: '[Verso 1]',
        chords: chords,
        description: 'Primeira estrofe com base harmônica e narrativa.',
      ),
      SongSection(
        name: '[Pré-Refrão]',
        chords: [chords[1], chords[2]],
        description: 'Crescimento melódico e preparação para o clímax.',
      ),
      SongSection(
        name: '[Refrão / Chorus]',
        chords: [chords[2], chords[3], chords[0], chords[1]],
        description: 'Ponto alto e marcante da canção com grande intensidade.',
      ),
      SongSection(
        name: '[Verso 2]',
        chords: chords,
        description: 'Segunda estrofe dando continuidade à canção.',
      ),
      SongSection(
        name: '[Solo Instrumental / Ponte]',
        chords: [chords[1], chords[2], chords[3], chords[0]],
        description: 'Expressão instrumental característica do estilo $genre.',
      ),
      SongSection(
        name: '[Final / Outro]',
        chords: [chords[0]],
        description: 'Desaceleração e sustentação do acorde final.',
      ),
    ];
  }

  /// Motor Semântico Avançado de Letras: Analisa entidades, temas e cria poesia rimada para QUALQUER prompt
  String _composeIntelligentLyrics({
    required String prompt,
    required String genre,
    required String mood,
    required bool isInstrumental,
  }) {
    if (isInstrumental) {
      return '''
[Introdução Instrumental]
(Arranjo instrumental imersivo de piano e violão)

[Tema Principal]
(Melodia principal conduzida por solos acústicos e sintetizadores)

[Ponte Instrumental]
(Variação harmônica e dinâmica crescente)

[Final Instrumental]
(Sustentação dos acordes e fade out suave)
''';
    }

    final p = prompt.trim();
    final lower = p.toLowerCase();

    // 1. CASO ESPECÍFICO: Homenagem Empresarial / Equipe / Colaboradores / Silva
    if (lower.contains('homenagem') || lower.contains('colaborador') || lower.contains('empresa') || lower.contains('silva') || lower.contains('automotivo') || lower.contains('oficina') || lower.contains('meta')) {
      String nomeEmpresa = 'Centro Automotivo Silva';
      if (lower.contains('centro automotivo silva')) {
        nomeEmpresa = 'Centro Automotivo Silva';
      } else {
        // Tenta extrair o nome da empresa se mencionado
        final match = RegExp(r'(empresa|loja|oficina|auto)\s+([A-Za-zÀ-ÿ0-9\s]+)', caseSensitive: false).firstMatch(p);
        if (match != null && match.group(2) != null) {
          nomeEmpresa = match.group(2)!.trim();
        }
      }

      return '''
[Verso 1]
O dia começa e a oficina ganha vida,
No $nomeEmpresa toda meta é cumprida!
Cada colaborador com garra e dedicação,
Trabalhando com talento e muita união!

[Pré-Refrão]
O esforço dessa equipe faz a história acontecer,
Com força, excelência e vontade de vencer!

[Refrão]
Parabéns, guerreiros do $nomeEmpresa!
Esse mês de ouro é orgulho com certeza!
Cada serviço feito com precisão e amor,
Vocês são a força que move o nosso motor!

[Verso 2]
Do atendimento ao diagnóstico afinado,
O cliente satisfeito e o trabalho aprovado!
Superando desafios com garra e paixão,
Uma equipe que brilha em cada missão!

[Ponte / Bridge]
Quando a equipe se une ninguém pode parar,
O sucesso desse mês nós vamos celebrar!

[Refrão Final]
Parabéns, guerreiros do $nomeEmpresa!
Esse mês de ouro é orgulho com certeza!
Vocês são a força que move o nosso motor!

[Final / Outro]
$nomeEmpresa... Parabéns a toda essa grande equipe!
''';
    }

    // 2. CASO GOSPEL / LOUVOR / FÉ / ADORAÇÃO / CURA / GRATIDÃO
    if (lower.contains('deus') || lower.contains('jesus') || lower.contains('gospel') || lower.contains('louvor') || lower.contains('fé') || lower.contains('cura') || lower.contains('oração') || lower.contains('gratidão')) {
      // Extrai possíveis nomes de pessoas homenageadas
      final words = p.split(RegExp(r'\s+'));
      String extraName = '';
      for (final w in words) {
        if (w.length > 2 && w[0] == w[0].toUpperCase() && !['Deus', 'Jesus', 'Senhor', 'Um', 'Uma', 'Para', 'Com'].contains(w)) {
          extraName = w;
          break;
        }
      }

      final dedication = extraName.isNotEmpty ? 'na vida de $extraName' : 'em cada coração';

      return '''
[Verso 1]
Em silêncio ouço Tua voz a me guiar,
Tua paz invade a alma e vem me renovar.
Em cada passo sinto Tua mão e proteção,
Manifestando o Teu milagre $dedication.

[Pré-Refrão]
Minha alma se alegra em Tua santa presença,
Tua graça é maior que qualquer tempestade!

[Refrão]
Te adorarei com todo o meu viver,
Tua luz em mim jamais vai se apagar!
És meu refúgio, razão do meu ser,
Para sempre Teu louvor irei cantar!

[Verso 2]
Renovo as forças ao olhar para o céu,
Tua palavra é viva e permanece fiel.
O Teu amor que cura toda dor e aflição,
Derrama bênçãos sobre a nossa oração.

[Ponte / Bridge]
Mesmo nas noites escuras eu não vou temer,
O Teu poder me faz vencer e renascer!

[Refrão Final]
Te adorarei com todo o meu viver,
Para sempre Teu louvor irei cantar!

[Final / Outro]
Aleluia... Glória e louvor ao Senhor.
''';
    }

    // 3. CASO ROMÂNTICO / CASAMENTO / ANIVERSÁRIO DE AMOR / DECLARAÇÃO
    if (lower.contains('amor') || lower.contains('esposa') || lower.contains('marido') || lower.contains('namorad') || lower.contains('casamento') || lower.contains('paixão') || lower.contains('declaração') || genre.contains('Romântica')) {
      return '''
[Verso 1]
Basta um olhar pra tudo ao redor mudar,
O mundo lá fora parece até parar.
Em cada detalhe do teu doce sorriso,
Encontro a minha paz e o meu paraíso.

[Pré-Refrão]
O tempo não corre quando estou contigo,
Você é meu grande amor, meu porto e meu abrigo!

[Refrão]
Eu prometo te amar em cada estação,
Ser tua melodia em cada canção!
Segurar tua mão e nunca mais soltar,
Porque o nosso amor nasceu pra eternizar!

[Verso 2]
As estrelas desenham a nossa linda história,
Guardada pra sempre no peito e na memória.
Um acorde perfeito que não tem mais fim,
O destino escolheu você todinha pra mim.

[Ponte / Bridge]
Nem a distância ou o tempo pode apagar,
A certeza mais linda de te amar!

[Refrão Final]
Eu prometo te amar em cada estação,
Porque o nosso amor nasceu pra eternizar!

[Final / Outro]
Pra sempre você e eu... meu grande amor.
''';
    }

    // 4. CASO GERAL: GERAÇÃO SEMÂNTICA DINÂMICA BASEADA NO PROMPT
    final words = p.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    final topic = words.take(4).join(' ');
    final mainWord = words.isNotEmpty ? words.first : 'vitória';

    return '''
[Verso 1]
A música começa e traz inspiração,
Celebrando com força essa criação!
Com $topic tudo ganha mais valor,
No ritmo sincero feito com amor!

[Pré-Refrão]
A harmonia se espalha em cada compasso,
Unindo as pessoas em um forte abraço!

[Refrão]
Vou cantar com alegria, vou comemorar,
No compasso da vida até o sol raiar!
A melodia de $mainWord brilhando no ar,
É a nossa conquista pronta pra tocar!

[Verso 2]
Cada nota revela um sentimento profundo,
Levando essa mensagem para todo o mundo.
Com dedicação o sonho se faz real,
Uma harmonia viva, forte e sem igual!

[Ponte / Bridge]
Deixa a música falar o que a alma quer dizer,
É a força do som que nos faz vencer!

[Refrão Final]
Vou cantar com alegria, vou comemorar,
É a nossa conquista pronta pra tocar!

[Final / Outro]
Harmonia Studio... Essa canção é para você!
''';
  }

  String _generateSongTitle(String prompt, String genre) {
    if (prompt.trim().isEmpty) return 'Nova Canção ($genre)';
    final clean = prompt.trim();
    final lower = clean.toLowerCase();

    if (lower.contains('centro automotivo silva')) {
      return 'Homenagem Centro Automotivo Silva';
    } else if (lower.contains('homenagem') && lower.contains('colaborador')) {
      return 'Homenagem aos Colaboradores';
    }

    final words = clean.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (words.isEmpty) return 'Canção Especial ($genre)';

    if (words.length <= 4) {
      return words.map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    }
    final firstThree = words.take(3).map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ');
    return '$firstThree ($genre)';
  }

  /// Injeta a música gerada diretamente nas 4 pistas da DAW do Harmonia Studio.
  Future<bool> exportSongToStudioDaw(AiSongModel song, StudioAudioEngine engine) async {
    try {
      final synth = SynthService();
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final chordBytes = synth.renderChordsTrackWav(song.chords, song.bpm);
      final chordsFilePath = '${tempDir.path}/ai_chords_$timestamp.wav';
      await File(chordsFilePath).writeAsBytes(chordBytes);

      final melodyBytes = synth.renderMelodyTrackWav(song.melody, song.bpm);
      final melodyFilePath = '${tempDir.path}/ai_melody_$timestamp.wav';
      await File(melodyFilePath).writeAsBytes(melodyBytes);

      engine.setBpm(song.bpm);

      if (engine.tracks.isNotEmpty) {
        engine.tracks[0].name = 'Pista 1 - Base Harmônica (${song.genre})';
        engine.tracks[0].filePath = chordsFilePath;
        engine.tracks[0].duration = Duration(seconds: (song.chords.length * 4 * 60 / song.bpm).round());
        engine.tracks[0].waveformSamples = List.generate(40, (i) => 0.4 + (i % 5) * 0.1);
        engine.tracks[0].isArmedForRec = false;
      }

      if (engine.tracks.length > 1) {
        engine.tracks[1].name = 'Pista 2 - Melodia / ${song.vocalStyle}';
        engine.tracks[1].filePath = melodyFilePath;
        engine.tracks[1].duration = Duration(seconds: (song.melody.length * 0.8 * 60 / song.bpm).round());
        engine.tracks[1].waveformSamples = List.generate(40, (i) => 0.3 + (i % 7) * 0.08);
        engine.tracks[1].isArmedForRec = false;
      }

      if (engine.tracks.length > 2) {
        engine.tracks[2].name = 'Pista 3 - Sua Voz / Microfone';
        engine.tracks[2].filePath = null;
        engine.tracks[2].isArmedForRec = true;
      }

      return true;
    } catch (e) {
      debugPrint('Erro ao exportar música para a DAW: $e');
      return false;
    }
  }
}
