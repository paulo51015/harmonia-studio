enum LessonInstrument {
  guitar,
  keyboard,
}

class NoteTarget {
  final String noteName; // e.g. 'C4', 'E2', 'A4'
  final String displayChord; // e.g. 'Dó Maior (C)', 'Sol Maior (G)'
  final double targetFrequencyHz; // e.g. 261.63, 440.0
  final double toleranceHz; // e.g. 8.0 Hz
  final String tip;
  final String tabOrKey; // e.g. 'Corda 5, Casa 3' ou 'Tecla Dó Central'

  const NoteTarget({
    required this.noteName,
    required this.displayChord,
    required this.targetFrequencyHz,
    this.toleranceHz = 8.0,
    required this.tip,
    required this.tabOrKey,
  });

  bool matchesFrequency(double detectedHz) {
    if (detectedHz <= 0) return false;
    return (detectedHz - targetFrequencyHz).abs() <= toleranceHz;
  }
}

class LessonModel {
  final String id;
  final String title;
  final String description;
  final LessonInstrument instrument;
  final String level;
  final int defaultBpm;
  final List<NoteTarget> exercises;
  final String studioGrooveName; // Sugestão para gravar no estúdio

  const LessonModel({
    required this.id,
    required this.title,
    required this.description,
    required this.instrument,
    this.level = 'Iniciante',
    this.defaultBpm = 100,
    required this.exercises,
    required this.studioGrooveName,
  });
}

class CurriculumData {
  static List<LessonModel> getLessons() {
    return [
      // AULAS DE VIOLÃO
      LessonModel(
        id: 'guitar_lesson_1',
        title: 'Primeiros Acordes Essenciais (C, G, D, Em)',
        description:
            'Aprenda a tocar as notas fundamentais dos acordes mais usados no violão popular e pop.',
        instrument: LessonInstrument.guitar,
        level: 'Iniciante',
        defaultBpm: 90,
        studioGrooveName: 'Base Acústica - Acordes Maiores',
        exercises: const [
          NoteTarget(
            noteName: 'C3',
            displayChord: 'Dó Maior (C) - Baixo',
            targetFrequencyHz: 130.81,
            toleranceHz: 6.0,
            tip: 'Pressione com o dedo 3 na 5ª corda (Lá), 3ª casa.',
            tabOrKey: '5ª Corda - Casa 3',
          ),
          NoteTarget(
            noteName: 'G2',
            displayChord: 'Sol Maior (G) - Baixo',
            targetFrequencyHz: 98.00,
            toleranceHz: 5.0,
            tip: 'Pressione com o dedo 2 ou 3 na 6ª corda (Mizão), 3ª casa.',
            tabOrKey: '6ª Corda - Casa 3',
          ),
          NoteTarget(
            noteName: 'D3',
            displayChord: 'Ré Maior (D) - Tônica',
            targetFrequencyHz: 146.83,
            toleranceHz: 6.0,
            tip: 'Toque a 4ª corda solta (Ré) com clareza.',
            tabOrKey: '4ª Corda Solta',
          ),
          NoteTarget(
            noteName: 'E2',
            displayChord: 'Mi Menor (Em) - Baixo',
            targetFrequencyHz: 82.41,
            toleranceHz: 4.5,
            tip: 'Toque a 6ª corda solta (Mizão grave).',
            tabOrKey: '6ª Corda Solta',
          ),
        ],
      ),
      LessonModel(
        id: 'guitar_lesson_2',
        title: 'Dedilhado Padrão P-I-M-A',
        description:
            'Domine o dedilhado clássico e moderno usando Polegar (baixo), Indicador (3ª), Médio (2ª) e Anelar (1ª).',
        instrument: LessonInstrument.guitar,
        level: 'Iniciante / Intermediário',
        defaultBpm: 80,
        studioGrooveName: 'Levada Dedilhada PIMA',
        exercises: const [
          NoteTarget(
            noteName: 'A2',
            displayChord: 'P - Polegar (Baixo em Lá)',
            targetFrequencyHz: 110.00,
            toleranceHz: 5.0,
            tip: 'Polegar toca a 5ª corda solta (Lá).',
            tabOrKey: '5ª Corda Solta (P)',
          ),
          NoteTarget(
            noteName: 'G3',
            displayChord: 'I - Indicador (3ª Corda Sol)',
            targetFrequencyHz: 196.00,
            toleranceHz: 7.0,
            tip: 'Indicador puxa a 3ª corda solta (Sol).',
            tabOrKey: '3ª Corda Solta (I)',
          ),
          NoteTarget(
            noteName: 'B3',
            displayChord: 'M - Médio (2ª Corda Si)',
            targetFrequencyHz: 246.94,
            toleranceHz: 8.0,
            tip: 'Médio puxa a 2ª corda solta (Si).',
            tabOrKey: '2ª Corda Solta (M)',
          ),
          NoteTarget(
            noteName: 'E4',
            displayChord: 'A - Anelar (1ª Corda Mizinha)',
            targetFrequencyHz: 329.63,
            toleranceHz: 10.0,
            tip: 'Anelar puxa a 1ª corda solta (Mi aguda).',
            tabOrKey: '1ª Corda Solta (A)',
          ),
        ],
      ),

      // AULAS DE TECLADO / PIANO
      LessonModel(
        id: 'keyboard_lesson_1',
        title: 'Primeiras Teclas & Dó Central (C4 a G4)',
        description:
            'Aprenda a localização do Dó Central, Ré, Mi, Fá e Sol com a mão direita.',
        instrument: LessonInstrument.keyboard,
        level: 'Iniciante',
        defaultBpm: 100,
        studioGrooveName: 'Melodia Pop Teclado C4-G4',
        exercises: const [
          NoteTarget(
            noteName: 'C4',
            displayChord: 'Dó Central (C4)',
            targetFrequencyHz: 261.63,
            toleranceHz: 8.0,
            tip: 'Tecla branca à esquerda do grupo de 2 teclas pretas.',
            tabOrKey: 'Dó Central (C4)',
          ),
          NoteTarget(
            noteName: 'D4',
            displayChord: 'Ré (D4)',
            targetFrequencyHz: 293.66,
            toleranceHz: 8.0,
            tip: 'Tecla branca entre as duas teclas pretas.',
            tabOrKey: 'Ré (D4)',
          ),
          NoteTarget(
            noteName: 'E4',
            displayChord: 'Mi (E4)',
            targetFrequencyHz: 329.63,
            toleranceHz: 9.0,
            tip: 'Tecla branca à direita das duas teclas pretas.',
            tabOrKey: 'Mi (E4)',
          ),
          NoteTarget(
            noteName: 'F4',
            displayChord: 'Fá (F4)',
            targetFrequencyHz: 349.23,
            toleranceHz: 9.0,
            tip: 'Tecla branca à esquerda do grupo de 3 teclas pretas.',
            tabOrKey: 'Fá (F4)',
          ),
          NoteTarget(
            noteName: 'G4',
            displayChord: 'Sol (G4)',
            targetFrequencyHz: 392.00,
            toleranceHz: 10.0,
            tip: 'Segunda tecla branca do grupo de 3 teclas pretas.',
            tabOrKey: 'Sol (G4)',
          ),
        ],
      ),
      LessonModel(
        id: 'keyboard_lesson_2',
        title: 'Escala Pentatônica & Acorde C Maior',
        description:
            'Execute a tríade de Dó Maior (Dó - Mi - Sol) e crie improvisações modernas.',
        instrument: LessonInstrument.keyboard,
        level: 'Iniciante / Intermediário',
        defaultBpm: 110,
        studioGrooveName: 'Arpejo Sintetizador Pentatônico',
        exercises: const [
          NoteTarget(
            noteName: 'C4',
            displayChord: 'Tônica - Dó (C4)',
            targetFrequencyHz: 261.63,
            toleranceHz: 8.0,
            tip: 'Polegar na tecla Dó.',
            tabOrKey: 'Dó Central',
          ),
          NoteTarget(
            noteName: 'E4',
            displayChord: 'Terça Maior - Mi (E4)',
            targetFrequencyHz: 329.63,
            toleranceHz: 9.0,
            tip: 'Dedo médio na tecla Mi.',
            tabOrKey: 'Mi (E4)',
          ),
          NoteTarget(
            noteName: 'G4',
            displayChord: 'Quinta Justa - Sol (G4)',
            targetFrequencyHz: 392.00,
            toleranceHz: 10.0,
            tip: 'Dedo mínimo na tecla Sol.',
            tabOrKey: 'Sol (G4)',
          ),
          NoteTarget(
            noteName: 'A4',
            displayChord: 'Sexta / Lá 440Hz (A4)',
            targetFrequencyHz: 440.00,
            toleranceHz: 12.0,
            tip: 'Nota padrão de afinação Lá 440 Hz.',
            tabOrKey: 'Lá (A4)',
          ),
        ],
      ),
    ];
  }
}
