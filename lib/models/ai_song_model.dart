/// Modelo de dados avançado para canções e melodias geradas pela Inteligência Artificial estilo Suno.
class AiSongModel {
  final String id;
  final String title;
  final String prompt;
  final String genre;
  final String mood;
  final String musicalKey;
  final int bpm;
  final bool isInstrumental;
  final String vocalStyle; // 'Voz Feminina Suave', 'Voz Masculina Encorpada', 'Coral / Dueto Gospel', 'Dupla Sertaneja', 'Voz Romântica & Pop', 'Instrumental Puro'
  final List<String> chords;
  final List<MelodyNote> melody;
  final List<SongSection> structure;
  final String lyrics;
  final List<LyricLine> timedLyrics; // Linhas sincronizadas com timestamp para Karaokê e Voz Cantada
  final String? variationLabel; // 'Versão 1 (Arranjo Principal)', 'Versão 2 (Acústico / Alternativo)'
  final List<AiSongModel> variations; // Versão A e Versão B
  final int durationSeconds;
  final String? audioFilePath; // Caminho do arquivo WAV completo master gravado no disco

  const AiSongModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.genre,
    required this.mood,
    required this.musicalKey,
    required this.bpm,
    this.isInstrumental = false,
    this.vocalStyle = 'Voz Feminina Suave',
    required this.chords,
    required this.melody,
    required this.structure,
    required this.lyrics,
    this.timedLyrics = const [],
    this.variationLabel,
    this.variations = const [],
    this.durationSeconds = 120,
    this.audioFilePath,
  });

  AiSongModel copyWith({
    String? id,
    String? title,
    String? prompt,
    String? genre,
    String? mood,
    String? musicalKey,
    int? bpm,
    bool? isInstrumental,
    String? vocalStyle,
    List<String>? chords,
    List<MelodyNote>? melody,
    List<SongSection>? structure,
    String? lyrics,
    List<LyricLine>? timedLyrics,
    String? variationLabel,
    List<AiSongModel>? variations,
    int? durationSeconds,
    String? audioFilePath,
  }) {
    return AiSongModel(
      id: id ?? this.id,
      title: title ?? this.title,
      prompt: prompt ?? this.prompt,
      genre: genre ?? this.genre,
      mood: mood ?? this.mood,
      musicalKey: musicalKey ?? this.musicalKey,
      bpm: bpm ?? this.bpm,
      isInstrumental: isInstrumental ?? this.isInstrumental,
      vocalStyle: vocalStyle ?? this.vocalStyle,
      chords: chords ?? this.chords,
      melody: melody ?? this.melody,
      structure: structure ?? this.structure,
      lyrics: lyrics ?? this.lyrics,
      timedLyrics: timedLyrics ?? this.timedLyrics,
      variationLabel: variationLabel ?? this.variationLabel,
      variations: variations ?? this.variations,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
    );
  }
}

class LyricLine {
  final int index;
  final String section; // '[Verso 1]', '[Refrão]', etc.
  final String text; // Frase da letra cantada
  final double timestampSeconds; // Ponto no tempo da música
  final double durationSeconds;
  final String? audioFilePath; // Caminho do arquivo de voz cantada

  const LyricLine({
    required this.index,
    required this.section,
    required this.text,
    required this.timestampSeconds,
    this.durationSeconds = 3.5,
    this.audioFilePath,
  });

  LyricLine copyWith({
    int? index,
    String? section,
    String? text,
    double? timestampSeconds,
    double? durationSeconds,
    String? audioFilePath,
  }) {
    return LyricLine(
      index: index ?? this.index,
      section: section ?? this.section,
      text: text ?? this.text,
      timestampSeconds: timestampSeconds ?? this.timestampSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
    );
  }
}

class MelodyNote {
  final String note; // ex: 'C4', 'E4', 'G4'
  final double durationInBeats; // 0.5 (colcheia), 1.0 (semínima), 2.0 (mínima)
  final double frequency;
  final String? lyricSyllable; // Sílaba ou palavra correspondente para o modo Karaokê

  const MelodyNote({
    required this.note,
    required this.durationInBeats,
    required this.frequency,
    this.lyricSyllable,
  });
}

class SongSection {
  final String name; // '[Verso 1]', '[Pré-Refrão]', '[Refrão]', '[Verso 2]', '[Ponte]', '[Solo]', '[Final]'
  final List<String> chords;
  final String description;
  final String sectionLyrics;

  const SongSection({
    required this.name,
    required this.chords,
    required this.description,
    this.sectionLyrics = '',
  });
}
