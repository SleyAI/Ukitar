import 'dart:math';

/// Represents a ukulele chord with its diagram information and expected notes.
class Chord {
  Chord({
    required this.id,
    required this.name,
    required this.description,
    required this.fingerPositions,
    required this.tips,
  }) {
    _notes = _buildNotes();
  }

  final String id;
  final String name;
  final String description;
  final List<ChordFingerPosition> fingerPositions;
  final List<String> tips;

  late final List<ChordNote> _notes;

  /// Standard tuning for ukulele strings: G, C, E, A.
  static const List<_StringTuning> _stringTunings = <_StringTuning>[
    _StringTuning(label: 'G', midi: 67),
    _StringTuning(label: 'C', midi: 60),
    _StringTuning(label: 'E', midi: 64),
    _StringTuning(label: 'A', midi: 69),
  ];

  /// Returns the strings (0-3) to fret mapping for this chord.
  List<int> get stringFrets {
    final List<int> frets = List<int>.filled(_stringTunings.length, 0);
    for (final ChordFingerPosition finger in fingerPositions) {
      frets[finger.stringIndex] = max(frets[finger.stringIndex], finger.fret);
    }
    return frets;
  }

  /// Maximum fret used for diagram scaling.
  int get maxFret => stringFrets.reduce(max);

  /// Expected notes for each string (including open strings).
  List<ChordNote> get notes => _notes;

  /// Helper to translate a detected frequency to a matching string index.
  /// Returns `null` if the frequency does not match any expected note.
  int? matchFrequency(double frequency, {double toleranceCents = 35}) {
    for (final ChordNote note in notes) {
      final double cents = 1200 * (log(frequency / note.frequency) / ln2);
      if (cents.abs() <= toleranceCents) {
        return note.stringIndex;
      }
    }
    return null;
  }

  String stringLabel(int index) => _stringTunings[index].label;

  ChordNote _buildNoteForString(int stringIndex, int fret) {
    final _StringTuning tuning = _stringTunings[stringIndex];
    final int midi = tuning.midi + fret;
    final double frequency = 440.0 * pow(2, (midi - 69) / 12).toDouble();


    return ChordNote(
      stringIndex: stringIndex,
      midi: midi,
      noteName: _noteNameFromMidi(midi),
      frequency: frequency,
    );
  }

  List<ChordNote> _buildNotes() {
    final List<int> frets = stringFrets;
    return List<ChordNote>.generate(
      frets.length,
      (int index) => _buildNoteForString(index, frets[index]),
    );
  }

  static String _noteNameFromMidi(int midi) {
    const List<String> pitchNames = <String>[
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#',
      'A',
      'A#',
      'B',
    ];
    final String name = pitchNames[midi % 12];
    final int octave = (midi ~/ 12) - 1;
    return '$name$octave';
  }
}

class ChordFingerPosition {
  const ChordFingerPosition({
    required this.stringIndex,
    required this.fret,
    required this.fingerNumber,
  });

  /// Zero-based index of the string (0 = G string, 3 = A string).
  final int stringIndex;

  /// Fret number (0 indicates an open string).
  final int fret;

  /// Finger number recommendation (1 = index, 2 = middle, ...).
  final int fingerNumber;
}

class ChordNote {
  const ChordNote({
    required this.stringIndex,
    required this.midi,
    required this.noteName,
    required this.frequency,
  });

  final int stringIndex;
  final int midi;
  final String noteName;
  final double frequency;
}

class _StringTuning {
  const _StringTuning({required this.label, required this.midi});

  final String label;
  final int midi;
}
