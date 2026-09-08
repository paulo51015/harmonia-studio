/// Modelo de dados para uma música e melodia geradas pela Inteligência Artificial.
class AiSongModel {
  final String id;
  final String title;
  final String prompt;
  final String genre;
  final String mood;
  final String musicalKey;
  final int bpm;
  final List<String> chords;
  final List<MelodyNote> melody;
  final List<SongSection> structure;
  final String lyrics;

  const AiSongModel({
    required this.id,
    required this.title,
    required this.prompt,
    required this.genre,
    required this.mood,
    required this.musicalKey,
    required this.bpm,
    required this.chords,
    required this.melody,
    required this.structure,
    required this.lyrics,
  });
}

class MelodyNote {
  final String note; // ex: 'C4', 'E4', 'G4'
  final double durationInBeats; // 0.5 (colcheia), 1.0 (semínima), 2.0 (mínima)
  final double frequency;

  const MelodyNote({
    required this.note,
    required this.durationInBeats,
    required this.frequency,
  });
}

class SongSection {
  final String name; // 'Introdução', 'Verso 1', 'Refrão', 'Verso 2', 'Solo', 'Final'
  final List<String> chords;
  final String description;

  const SongSection({
    required this.name,
    required this.chords,
    required this.description,
  });
}
