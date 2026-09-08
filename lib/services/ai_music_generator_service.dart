import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ai_song_model.dart';
import '../models/track_model.dart';
import 'studio_audio_engine.dart';
import 'synth_service.dart';

/// Motor Inteligente de Composição Musical com Suporte Especializado a Estilos (Gospel, Sertanejo, Romântica, MPB, Pop, Rock, etc.)
class AiMusicGeneratorService {
  static final AiMusicGeneratorService _instance = AiMusicGeneratorService._internal();
  factory AiMusicGeneratorService() => _instance;
  AiMusicGeneratorService._internal();

  /// Analisa o prompt e parâmetros para compor uma nova música e melodia completas.
  Future<AiSongModel> generateSongFromPrompt({
    required String prompt,
    String? selectedGenre,
    String? selectedMood,
    String? selectedKey,
    int? customBpm,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1200));

    final cleanPrompt = prompt.toLowerCase();

    // 1. Detecção e Priorização de Gêneros Específicos
    String genre = selectedGenre ?? 'Gospel / Louvor';
    if (cleanPrompt.contains('gospel') || cleanPrompt.contains('louvor') || cleanPrompt.contains('adoração') || cleanPrompt.contains('deus') || cleanPrompt.contains('igreja')) {
      genre = 'Gospel / Louvor';
    } else if (cleanPrompt.contains('sertanej') || cleanPrompt.contains('modão') || cleanPrompt.contains('sofrência') || cleanPrompt.contains('viola') || cleanPrompt.contains('rodeio')) {
      genre = 'Sertanejo';
    } else if (cleanPrompt.contains('romântic') || cleanPrompt.contains('amor') || cleanPrompt.contains('apaixonad') || cleanPrompt.contains('balada') || cleanPrompt.contains('coração')) {
      genre = 'Romântica / Balada';
    } else if (cleanPrompt.contains('forró') || cleanPrompt.contains('piseiro') || cleanPrompt.contains('sanfona') || cleanPrompt.contains('nordest')) {
      genre = 'Forró / Piseiro';
    } else if (cleanPrompt.contains('mpb') || cleanPrompt.contains('violão') || cleanPrompt.contains('acústico') || cleanPrompt.contains('bossa') || cleanPrompt.contains('praia')) {
      genre = 'Acústico / MPB';
    } else if (cleanPrompt.contains('rock') || cleanPrompt.contains('guitarra') || cleanPrompt.contains('riff')) {
      genre = 'Rock / Pop Rock';
    } else if (cleanPrompt.contains('lo-fi') || cleanPrompt.contains('chill') || cleanPrompt.contains('estudo')) {
      genre = 'Lo-Fi Chill';
    }

    // 2. Detecção de Clima / Mood
    String mood = selectedMood ?? 'Inspirador';
    if (cleanPrompt.contains('triste') || cleanPrompt.contains('melancol') || cleanPrompt.contains('saudade') || cleanPrompt.contains('sofrimento')) {
      mood = 'Melancólico';
    } else if (cleanPrompt.contains('animad') || cleanPrompt.contains('festa') || cleanPrompt.contains('dança') || cleanPrompt.contains('alegre')) {
      mood = 'Alegre & Festivo';
    } else if (cleanPrompt.contains('emocion') || cleanPrompt.contains('inspir') || cleanPrompt.contains('fé') || cleanPrompt.contains('profund')) {
      mood = 'Inspirador / Emocionante';
    } else if (cleanPrompt.contains('calm') || cleanPrompt.contains('suave') || cleanPrompt.contains('paz') || cleanPrompt.contains('relax')) {
      mood = 'Relaxante & Suave';
    }

    // 3. Tom Musical & Andamento (BPM)
    String musicalKey = selectedKey ?? (mood == 'Melancólico' ? 'Am (Lá Menor)' : 'G (Sol Maior)');
    int bpm = customBpm ?? _getSuggestedBpm(genre, mood);

    // 4. Progressão Harmônica de Acordes
    final chords = _generateChordProgression(genre, mood);

    // 5. Linha Melódica (Notas musicais com durações rítmicas)
    final melody = _generateMelodyNotes(chords, bpm, genre);

    // 6. Estrutura da Canção
    final structure = _generateSongStructure(chords, genre);

    // 7. Letra Sugerida Temática
    final lyrics = _generateLyrics(prompt, genre, mood);

    final title = _generateSongTitle(prompt, genre);

    return AiSongModel(
      id: 'ai_song_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      prompt: prompt,
      genre: genre,
      mood: mood,
      musicalKey: musicalKey,
      bpm: bpm,
      chords: chords,
      melody: melody,
      structure: structure,
      lyrics: lyrics,
    );
  }

  int _getSuggestedBpm(String genre, String mood) {
    switch (genre) {
      case 'Gospel / Louvor':
        return 72; // Andamento de adoração solene e emocionante
      case 'Sertanejo':
        return 118; // Sertanejo moderno / balanço
      case 'Romântica / Balada':
        return 68; // Balada lenta e expressiva
      case 'Forró / Piseiro':
        return 138; // Ritmo dançante e enérgico
      case 'Acústico / MPB':
        return 92; // Swing e balanço acústico
      case 'Rock / Pop Rock':
        return 132;
      case 'Lo-Fi Chill':
        return 78;
      default:
        return 110;
    }
  }

  List<String> _generateChordProgression(String genre, String mood) {
    switch (genre) {
      case 'Gospel / Louvor':
        return ['C', 'G', 'Am', 'F']; // Clássica progressão de louvor I - V - vi - IV
      case 'Sertanejo':
        return ['G', 'D', 'Em', 'C']; // Progressão sertaneja romântica de violão
      case 'Romântica / Balada':
        return ['C', 'Em', 'F', 'G']; // Balada apaixonada I - iii - IV - V
      case 'Forró / Piseiro':
        return ['Am', 'F', 'C', 'G']; // Cadência marcante de forró
      case 'Acústico / MPB':
        return ['C', 'Am', 'Dm', 'G']; // Cadência tradicional I - vi - ii - V
      case 'Rock / Pop Rock':
        return ['G', 'C', 'Em', 'D'];
      case 'Lo-Fi Chill':
        return ['Dm', 'G', 'C', 'Am'];
      default:
        return ['C', 'G', 'Am', 'F'];
    }
  }

  List<MelodyNote> _generateMelodyNotes(List<String> chords, int bpm, String genre) {
    final List<MelodyNote> notes = [];

    // Mapeamento melódico temático
    final Map<String, List<String>> chordMelodyMap = {
      'C': ['E4', 'G4', 'C5', 'G4', 'E4'],
      'G': ['D4', 'G4', 'B4', 'D5', 'B4'],
      'Am': ['C4', 'E4', 'A4', 'C5', 'E4'],
      'F': ['F4', 'A4', 'C5', 'F5', 'A4'],
      'Em': ['E4', 'G4', 'B4', 'E5', 'B4'],
      'Dm': ['D4', 'F4', 'A4', 'D5', 'F4'],
      'D': ['D4', 'F#4', 'A4', 'D5', 'F#4'],
    };

    for (final chord in chords) {
      final pattern = chordMelodyMap[chord] ?? ['C4', 'E4', 'G4', 'C5'];
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

  List<SongSection> _generateSongStructure(List<String> chords, String genre) {
    return [
      SongSection(
        name: 'Introdução (Intro)',
        chords: [chords[0], chords[1]],
        description: 'Frase instrumental suave estabelecendo o estilo $genre.',
      ),
      SongSection(
        name: 'Verso 1',
        chords: chords,
        description: 'Primeira estrofe com a narrativa principal e arranjo de base.',
      ),
      SongSection(
        name: 'Pré-Refrão',
        chords: [chords[1], chords[2]],
        description: 'Crescimento de dinâmica preparando para o refrão.',
      ),
      SongSection(
        name: 'Refrão (Chorus)',
        chords: [chords[2], chords[3], chords[0], chords[1]],
        description: 'Ponto alto e marcante da canção com grande intensidade.',
      ),
      SongSection(
        name: 'Verso 2',
        chords: chords,
        description: 'Segunda estrofe com continuação da mensagem e harmonia.',
      ),
      SongSection(
        name: 'Solo Instrumental / Ponte',
        chords: [chords[1], chords[2], chords[3], chords[0]],
        description: 'Solo expressivo característico do gênero $genre.',
      ),
      SongSection(
        name: 'Final (Outro)',
        chords: [chords[0]],
        description: 'Desaceleração e sustentação do acorde final.',
      ),
    ];
  }

  String _generateLyrics(String prompt, String genre, String mood) {
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

[Final]
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
O compasso certinho dessa paixão!

[Refrão]
Ah, esse som de viola que toca na alma,
Traz o teu cheiro e de novo me acalma!
Se eu canto com força é pra você me ouvir,
Não tem outro lugar onde eu queira ir!

[Verso 2]
A poeira da estrada levanta no ar,
Mas nada me impede de te encontrar.
No som sertanejo da nossa canção,
Bate mais forte esse meu coração!

[Final]
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

[Final]
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

[Final]
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
        engine.tracks[0].name = 'Pista 1 - Base (${song.genre})';
        engine.tracks[0].filePath = chordsFilePath;
        engine.tracks[0].duration = Duration(seconds: (song.chords.length * 4 * 60 / song.bpm).round());
        engine.tracks[0].waveformSamples = List.generate(40, (i) => 0.4 + (i % 5) * 0.1);
        engine.tracks[0].isArmedForRec = false;
      }

      if (engine.tracks.length > 1) {
        engine.tracks[1].name = 'Pista 2 - Melodia (${song.genre})';
        engine.tracks[1].filePath = melodyFilePath;
        engine.tracks[1].duration = Duration(seconds: (song.melody.length * 0.8 * 60 / song.bpm).round());
        engine.tracks[1].waveformSamples = List.generate(40, (i) => 0.3 + (i % 7) * 0.08);
        engine.tracks[1].isArmedForRec = false;
      }

      if (engine.tracks.length > 2) {
        engine.tracks[2].name = 'Pista 3 - Sua Voz / Gravação';
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
