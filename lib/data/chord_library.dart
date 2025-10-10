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
        id: 'd-minor',
        name: 'D Minor',
        description:
            'A soulful minor shape that builds on F by adding one more finger across the middle strings.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 2, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Let your ring finger press the C string while the index finger holds the E string.',
          'Strum gently and ensure the open A string rings to complete the chord.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'e-minor',
        name: 'E Minor',
        description:
            'A cascading shape that uses three fingers in a diagonal pattern for a moody sound.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 1, fret: 4, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 2, fret: 3, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 1),
        ],
        tips: const <String>[
          'Place your fingers one at a time from the A string up to keep the diagonal tidy.',
          'Keep your knuckles arched so the open G string rings without buzzing.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'a-major',
        name: 'A Major',
        description:
            'A bright, friendly chord that uses two fingers to outline the major tonality.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 1, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Keep your index finger angled so the open E and A strings ring clearly.',
          'Let your strumming hand focus on the lower three strings for a warm tone.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'd-major',
        name: 'D Major',
        description:
            'A percussive-sounding chord that stacks three fingers across the second fret.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 3),
        ],
        tips: const <String>[
          'Squeeze gently from thumb to fingertips to keep all three notes ringing.',
          'Lift and reset the chord slowly to build muscle memory for the clustered shape.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'g7',
        name: 'G7',
        description:
            'Adds a bluesy colour to progressions while keeping the fingers close to the nut.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 1, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 3),
        ],
        tips: const <String>[
          'Let the open G string ring as the root of the dominant sound.',
          'Practice switching between G7 and C to anchor the V–I movement.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'c7',
        name: 'C7',
        description:
            'A simple extension of C major that introduces the dominant seventh flavour.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 3, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Use the tip of your index finger so the neighbouring strings stay open.',
          'Strum lightly toward the floor to highlight the bright seventh.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'e7',
        name: 'E7',
        description:
            'A lively chord that introduces finger movement across the first two frets.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 1, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 3),
        ],
        tips: const <String>[
          'Keep your wrist relaxed so the index finger can reach back to the first fret.',
          'Aim for a steady strum to let the open E string tie the voicing together.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'd7',
        name: 'D7',
        description:
            'A classic dominant chord that prepares ear-catching resolutions to G major.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 3, fret: 3, fingerNumber: 4),
        ],
        tips: const <String>[
          'Roll your index finger slightly to cover the second fret cleanly.',
          'Work on lifting all four fingers together to move between G and D7 smoothly.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'b7',
        name: 'B7',
        description:
            'A jazzy-sounding chord that introduces reaching up to the third fret.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 1, fret: 3, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 4),
        ],
        tips: const <String>[
          'Use the tip of your ring finger on the C string so the neighbouring strings stay clear.',
          'Anchor your thumb in the middle of the neck to help the pinky reach the A string.',
        ],
        stringTunings: _ukuleleTunings,
      ),
      Chord(
        id: 'b-flat',
        name: 'Bb',
        description:
            'A movable chord shape that teaches the feel of a partial barre across the first fret.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 0, fret: 3, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 1, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 2, fret: 1, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 3, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Lay your index finger flat across the first fret to act as a mini barre.',
          'Squeeze from your thumb to the first finger while keeping the wrist relaxed.',
        ],
        stringTunings: _ukuleleTunings,
      ),
    ];
  }

  static List<Chord> _guitarBeginnerCourse() {
    return <Chord>[
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
      Chord(
        id: 'a-major',
        name: 'A Major',
        description:
            'A bright open chord that stacks three fingers together on the second fret.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 4, fret: 2, fingerNumber: 3),
        ],
        tips: const <String>[
          'Press the D, G, and B strings with relaxed knuckles so they ring together.',
          'Strum mainly from the A string downward for a crisp rhythm sound.',
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
        id: 'd-major',
        name: 'D Major',
        description:
            'A compact chord that trains accuracy across the highest three strings.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 1),
          ChordFingerPosition(stringIndex: 4, fret: 3, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 5, fret: 2, fingerNumber: 2),
        ],
        tips: const <String>[
          'Aim your pick from the D string downward to keep the low strings quiet.',
          'Curve each fingertip so the notes on the top strings ring without buzz.',
        ],
        stringTunings: _guitarTunings,
      ),
      Chord(
        id: 'a-minor',
        name: 'A Minor',
        description:
            'Shares the same shape as C major shifted one string set, making transitions easy.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 2, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 4, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Let your wrist relax so the index finger comfortably reaches the first fret.',
          'Listen for the open high E string to shimmer above the chord.',
        ],
        stringTunings: _guitarTunings,
      ),
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
        id: 'd-minor',
        name: 'D Minor',
        description:
            'A melancholy voicing that brings the index, middle, and ring fingers close together.',
        fingerPositions: const <ChordFingerPosition>[
          ChordFingerPosition(stringIndex: 3, fret: 2, fingerNumber: 2),
          ChordFingerPosition(stringIndex: 4, fret: 3, fingerNumber: 3),
          ChordFingerPosition(stringIndex: 5, fret: 1, fingerNumber: 1),
        ],
        tips: const <String>[
          'Anchor your index finger first, then stack the other fingers to keep the shape compact.',
          'Strum from the D string downward so the bass note stays clear.',
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
