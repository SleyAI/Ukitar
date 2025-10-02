import '../models/chord.dart';
import '../models/instrument.dart';

/// Provides curated chords for supported instruments.
class ChordLibrary {
  const ChordLibrary._();

  static List<Chord> beginnerCourse(InstrumentType instrument) {
    switch (instrument) {
      case InstrumentType.ukulele:
        return _ukuleleBeginnerCourse();
      case InstrumentType.guitar:
        return _guitarBeginnerCourse();
    }
  }

  static List<Chord> _ukuleleBeginnerCourse() {
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
        stringTunings: _ukuleleTunings,
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
        stringTunings: _ukuleleTunings,
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
        stringTunings: _ukuleleTunings,
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
        stringTunings: _ukuleleTunings,
      ),
    ];
  }

  static List<Chord> _guitarBeginnerCourse() {
    return <Chord>[
      Chord(
        id: 'e-minor',
        name: 'E Minor',
        description:
            'A comfortable starter chord that uses two fingers while letting the rest of the strings ring open.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 3),
        ],
        tips: const <String>[
          'Curl your fingers so the open strings ring clearly.',
          'Strum all six strings with an even motion.',
        ],
        stringTunings: _guitarTunings,
      ),
      Chord(
        id: 'g-major',
        name: 'G Major',
        description:
            'Introduces reaching across the neck with three fingers to create a rich full sound.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 3, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 5, fret: 3, fingerNumber: 3),
        ],
        tips: const <String>[
          'Let your wrist drop slightly so the fingers reach both sides of the fretboard.',
          'Keep the B string relaxed to ring open for a bright harmony.',
        ],
        stringTunings: _guitarTunings,
      ),
      Chord(
        id: 'e-major',
        name: 'E Major',
        description:
            'Builds on E minor by adding the index finger for a brighter, confident sound.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 3, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Press the first fret gently with the tip of your index finger to avoid muting the E string.',
          'Strum confidently from the low E string through the high E string.',
        ],
        stringTunings: _guitarTunings,
      ),
      Chord(
        id: 'c-major-guitar',
        name: 'C Major',
        description:
            'Practise finger independence by stretching across three frets while letting the E strings ring.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 1, fret: 3, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 4, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Angle your fingers so the open G and high E strings ring freely.',
          'Keep your thumb centred on the back of the neck for better reach.',
        ],
        stringTunings: _guitarTunings,
      ),
    ];
  }

  static const List<StringTuning> _ukuleleTunings = <StringTuning>[
    StringTuning(label: 'G', midi: 67),
    StringTuning(label: 'C', midi: 60),
    StringTuning(label: 'E', midi: 64),
    StringTuning(label: 'A', midi: 69),
  ];

  static const List<StringTuning> _guitarTunings = <StringTuning>[
    StringTuning(label: 'E', midi: 40),
    StringTuning(label: 'A', midi: 45),
    StringTuning(label: 'D', midi: 50),
    StringTuning(label: 'G', midi: 55),
    StringTuning(label: 'B', midi: 59),
    StringTuning(label: 'E', midi: 64),
  ];
}
