import '../models/chord.dart';

/// Provides curated ukulele chords for the beginner course.
class ChordLibrary {
  const ChordLibrary._();

  static List<Chord> beginnerCourse() {
    return <Chord>[
      Chord(
        id: 'c-major',
        name: 'C Major',
        description:
            'The classic entry point chord. Use your ring finger on the A string, third fret.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 3, fret: 3, fingerNumber: 3),
        ],
        tips: const <String>[
          'Keep your wrist relaxed so the ring finger arches cleanly.',
          'Strum slowly to let every string ring out.',
        ],
      ),
      Chord(
        id: 'a-minor',
        name: 'A Minor',
        description:
            'A gentle minor chord that uses only one finger on the A string.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 2),
        ],
        tips: const <String>[
          'Press the second fret with your middle finger and keep other strings open.',
          'Make sure the fingertip stays vertical to avoid muting neighbouring strings.',
        ],
      ),
      Chord(
        id: 'f-major',
        name: 'F Major',
        description:
            'Adds a second finger for a brighter sound. Great for practising finger independence.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Let your middle finger reach over to the second fret of the G string.',
          'Keep your thumb behind the neck to reduce tension.',
        ],
      ),
      Chord(
        id: 'g-major',
        name: 'G Major',
        description:
            'A fuller chord that introduces three fingers. Perfect to practise chord transitions.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 3, fret: 3, fingerNumber: 4),
        ],
        tips: const <String>[
          'Form a loose triangle shape with your fingers.',
          'Check that each string rings clearly before strumming.',
        ],
      ),
    ];
  }
}
