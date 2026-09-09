import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';
import '../models/track_model.dart';
import 'studio_audio_engine.dart';
import 'synth_service.dart';

/// Motor Inteligente de Composição Musical Avançado estilo Suno AI.
/// Suporta Modo Simples, Modo Personalizado (Custom Mode), Geração Dupla de Variações (A/B),
/// Extensor de Canção (Extend Clip), Geração de Letras com Tags Estruturais e Mixagem de Stems.
class AiMusicGeneratorService {
  static final AiMusicGeneratorService _instance = AiMusicGeneratorService._internal();
  factory AiMusicGeneratorService() => _instance;
  AiMusicGeneratorService._internal();

  /// Compõe a canção com geração dupla (Versão 1 e Versão 2) a partir dos parâmetros fornecidos.
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
    await Future.delayed(const Duration(milliseconds: 1400));

    final cleanPrompt = prompt.toLowerCase();

    // 1. Detecção e Priorização de Gêneros Específicos
    String genre = selectedGenre ?? 'Gospel / Louvor';
    if (cleanPrompt.contains('gospel') || cleanPrompt.contains('louvor') || cleanPrompt.contains('adoração') || cleanPrompt.contains('deus') || cleanPrompt.contains('igreja') || cleanPrompt.contains('fé')) {
      genre = 'Gospel / Louvor';
    } else if (cleanPrompt.contains('sertanej') || cleanPrompt.contains('modão') || cleanPrompt.contains('sofrência') || cleanPrompt.contains('viola') || cleanPrompt.contains('rodeio') || cleanPrompt.contains('boteco')) {
      genre = 'Sertanejo';
    } else if (cleanPrompt.contains('romântic') || cleanPrompt.contains('amor') || cleanPrompt.contains('apaixonad') || cleanPrompt.contains('balada') || cleanPrompt.contains('coração') || cleanPrompt.contains('declaração')) {
      genre = 'Romântica / Balada';
    } else if (cleanPrompt.contains('forró') || cleanPrompt.contains('piseiro') || cleanPrompt.contains('sanfona') || cleanPrompt.contains('nordest') || cleanPrompt.contains('arrasta')) {
      genre = 'Forró / Piseiro';
    } else if (cleanPrompt.contains('mpb') || cleanPrompt.contains('violão') || cleanPrompt.contains('acústico') || cleanPrompt.contains('bossa') || cleanPrompt.contains('praia') || cleanPrompt.contains('brasil')) {
      genre = 'Acústico / MPB';
    } else if (cleanPrompt.contains('rock') || cleanPrompt.contains('guitarra') || cleanPrompt.contains('riff') || cleanPrompt.contains('pesado')) {
      genre = 'Rock / Pop Rock';
    } else if (cleanPrompt.contains('lo-fi') || cleanPrompt.contains('chill') || cleanPrompt.contains('estudo') || cleanPrompt.contains('relax')) {
      genre = 'Lo-Fi Chill';
    }

    // 2. Detecção de Clima / Mood
    String mood = selectedMood ?? 'Inspirador / Emocionante';
    if (cleanPrompt.contains('triste') || cleanPrompt.contains('melancol') || cleanPrompt.contains('saudade') || cleanPrompt.contains('sofrimento')) {
      mood = 'Melancólico & Saudade';
    } else if (cleanPrompt.contains('animad') || cleanPrompt.contains('festa') || cleanPrompt.contains('dança') || cleanPrompt.contains('alegre') || cleanPrompt.contains('balanço')) {
      mood = 'Alegre & Festivo';
    } else if (cleanPrompt.contains('emocion') || cleanPrompt.contains('inspir') || cleanPrompt.contains('profund')) {
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

    // 5. Letra (Personalizada ou Gerada com Tags Suno)
    final lyrics = (customLyrics != null && customLyrics.trim().isNotEmpty)
        ? customLyrics.trim()
        : _generateLyrics(prompt, genre, mood, isInstrumental);

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

    final versaoB = AiSongModel(
      id: 'ai_song_${DateTime.now().millisecondsSinceEpoch}_v2',
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
      variationLabel: 'Versão 2 (Arranjo Alternativo)',
      durationSeconds: 135,
    );

    final versaoA = AiSongModel(
      id: 'ai_song_${DateTime.now().millisecondsSinceEpoch}_v1',
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
      variationLabel: 'Versão 1 (Arranjo Principal)',
      variations: [versaoB],
      durationSeconds: 140,
    );

    return versaoA;
  }

  /// Gera uma letra poética completa estruturada em tags estilo Suno AI.
  String generateLyricsOnly({
    required String themePrompt,
    required String genre,
    required String mood,
  }) {
    return _generateLyrics(themePrompt, genre, mood, false);
  }

  /// Estende uma canção adicionando novas seções (Solo, Ponte, Refrão Final, Outro).
  Future<AiSongModel> extendSong({
    required AiSongModel originalSong,
    required String extensionType, // 'Ponte & Refrão Final', 'Solo Instrumental & Refrão', 'Finalização / Outro'
    String? additionalLyrics,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));

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
      // Adiciona notas do solo
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
      addedLyrics += additionalLyrics ?? '\n\n[Ponte / Bridge]\nE quando tudo parece parar,\nA Tua voz vem me renovar!\nNada pode esse amor apagar!';
    } else {
      newStructure.add(
        SongSection(
          name: '[Final / Outro Estendido]',
          chords: [newChords[0]],
          description: 'Sustentação harmônica em fade-out.',
        ),
      );
      addedLyrics += '\n\n[Final]\nDeixa o som soar... até o amanhecer.';
    }

    final fullLyrics = '${originalSong.lyrics}$addedLyrics';

    return originalSong.copyWith(
      id: 'ai_song_ext_${DateTime.now().millisecondsSinceEpoch}',
      title: '${originalSong.title} (Estendida)',
      chords: newChords,
      melody: newMelody,
      structure: newStructure,
      lyrics: fullLyrics,
      durationSeconds: originalSong.durationSeconds + 45,
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
      // Variação harmônica alternativa
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

  String _generateLyrics(String prompt, String genre, String mood, bool isInstrumental) {
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

    if (genre == 'Gospel / Louvor') {
      return '''
[Verso 1]
Em silêncio ouço Tua voz me chamar,
Tua paz invade e vem me transformar.
Em cada passo sinto Tua mão a guiar,
És minha rocha, em Ti vou descansar.

[Pré-Refrão]
Minha alma se alegra em Tua presença,
Tua graça é maior que qualquer tempestade!

[Refrão]
Te adorarei com todo o meu viver,
Tua luz em mim jamais vai se apagar!
És meu refúgio, motivo do meu ser,
Para sempre Teu amor irei cantar!

[Verso 2]
Renovo as forças ao olhar para o céu,
Tua fidelidade permanece fiel.
Harmonia divina em cada oração,
Um louvor que transborda no coração.

[Ponte / Bridge]
Mesmo nas noites escuras,
Tua presença me sustenta e me cura!

[Refrão Final]
Te adorarei com todo o meu viver,
Para sempre Teu amor irei cantar!

[Final / Outro]
Aleluia... Teu amor não tem fim.
''';
    }

    if (genre == 'Sertanejo') {
      return '''
[Verso 1]
O sol tá descendo atrás da porteira,
No peito a saudade de uma noite inteira.
Peguei meu violão, bati o primeiro acorde,
Lembrando do teu abraço que ainda me envolve.

[Pré-Refrão]
O vento sopra trazendo a recordação,
No compasso certinho dessa paixão!

[Refrão]
Ah, esse som de viola que toca na alma,
Traz o teu cheiro e de novo me acalma!
Se eu canto com força é pra você me ouvir,
Não tem outro lugar onde eu queira ir!

[Verso 2]
A poeira da estrada levanta no ar,
Mas nada no mundo me impede de te encontrar.
No som sertanejo da nossa canção,
Bate acelerado esse coração!

[Solo de Viola]
(Solo marcante de viola caipira e violão)

[Refrão Final]
Ah, esse som de viola que toca na alma,
Não tem outro lugar onde eu queira ir!

[Final / Outro]
Toca viola... até clarear.
''';
    }

    if (genre == 'Romântica / Balada') {
      return '''
[Verso 1]
Basta um olhar pra tudo mudar,
O mundo lá fora parece parar.
Em cada detalhe do teu sorriso,
Encontro a paz e o meu paraíso.

[Pré-Refrão]
O tempo não corre quando estou contigo,
Você é meu par, meu amor e meu abrigo.

[Refrão]
Eu prometo te amar em cada estação,
Ser tua melodia em cada canção!
Segurar tua mão e nunca mais soltar,
Porque o nosso amor nasceu pra durar!

[Verso 2]
As estrelas desenham a nossa história,
Guardada pra sempre na minha memória.
Um acorde perfeito que não tem fim,
O destino escreveu você pra mim.

[Final / Outro]
Pra sempre você e eu...
''';
    }

    if (genre == 'Forró / Piseiro') {
      return '''
[Verso 1]
Puxa a sanfona que a poeira vai subir,
Hoje ninguém fica parado por aqui!
O zabumba batendo no fundo do peito,
No salão arrumado não tem preconceito!

[Refrão]
Vem dançar agarradinho até o sol raiar,
No compasso do forró pra gente se alegrar!
Roda pra lá, puxa pra cá,
Esse piseiro ninguém vai segurar!

[Final / Outro]
É o forró do Harmonia Studio!
''';
    }

    // Default / MPB / Pop
    return '''
[Verso 1]
Olho pela janela e vejo o dia clarear,
O ritmo no peito começa a acelerar.
Cada nota no caminho traz uma direção,
Essa melodia nasce direto do coração.

[Refrão]
Vou cantar, vou viver, deixar o som guiar,
No compasso do tempo, até o sol raiar!
A harmonia perfeita que ecoa no ar,
É a nossa história pronta pra tocar!

[Verso 2]
Os acordes se encontram num doce acordeão,
Transformando ideias em pura vibração.
Harmonia Studio em cada criação!

[Final / Outro]
Deixa o som fluir... até o último acorde sumir.
''';
  }

  String _generateSongTitle(String prompt, String genre) {
    if (prompt.trim().isEmpty) return 'Nova Música ($genre)';
    final words = prompt.trim().split(' ');
    if (words.length <= 4) {
      return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    }
    return '${words.take(3).join(' ')} ($genre)';
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
