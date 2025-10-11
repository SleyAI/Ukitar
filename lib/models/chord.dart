import 'dart:math';

/// Represents a chord with its diagram information and expected notes.
class Chord {
  Chord({
    required this.id,
    required this.name,
    required this.description,
    required this.fingerPositions,
    required this.tips,
    required List<StringTuning> stringTunings,
    Set<int>? requiredStringIndexes,
  })  : stringTunings = List<StringTuning>.unmodifiable(stringTunings),
        requiredStringIndexes = _normalizeRequiredIndexes(
          stringTunings,
          requiredStringIndexes,
        ) {
    assert(this.requiredStringIndexes.isNotEmpty,
        'Chord must require at least one string to ring.');
    _notes = _buildNotes();
  }

  final String id;
  final String name;
  final String description;
  final List<ChordFingerPosition> fingerPositions;
  final List<String> tips;
  final List<StringTuning> stringTunings;
  final Set<int> requiredStringIndexes;

  late final List<ChordNote> _notes;

  int get stringCount => stringTunings.length;

  /// Returns the strings (0-3) to fret mapping for this chord.
  List<int> get stringFrets {
    final List<int> frets = List<int>.filled(stringTunings.length, 0);
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
  int? matchFrequency(
    double frequency, {
    double toleranceCents = 45,
    int harmonicDepth = 4,
  }) {
    if (frequency <= 0) {
      return null;
    }

    int? bestMatch;
    double smallestDelta = toleranceCents + 1;

    final Set<double> candidates = <double>{frequency};
    for (int factor = 2; factor <= harmonicDepth; factor++) {
      candidates.add(frequency / factor);
      candidates.add(frequency * factor);
    }

    for (final double candidate in candidates) {
      if (candidate <= 0 || candidate > 5000) {
        continue;
      }
      for (final ChordNote note in notes) {
        if (!requiredStringIndexes.contains(note.stringIndex)) {
          continue;
        }
        final double cents = 1200 * (log(candidate / note.frequency) / ln2);
        final double difference = cents.abs();
        if (difference < smallestDelta) {
          smallestDelta = difference;
          bestMatch = note.stringIndex;
        }
      }
    }

    if (bestMatch != null && smallestDelta <= toleranceCents) {
      return bestMatch;
    }
    return null;
  }

  int? matchPitchClasses(
    List<double> chroma, {
    double minEnergy = 0.3,
    double neighborWeight = 0.25,
    double fallbackToleranceCents = 35,
    double? fundamental,
  }) {
    if (chroma.length != 12) {
      throw ArgumentError('Chromagram must contain exactly 12 bins.');
    }

    double bestScore = minEnergy;
    int? bestMatch;

    for (final ChordNote note in notes) {
      if (!requiredStringIndexes.contains(note.stringIndex)) {
        continue;
      }
      final int pitchClass = note.pitchClass;
      final double baseEnergy = chroma[pitchClass];
      final double neighborEnergy =
          (chroma[(pitchClass + 11) % 12] + chroma[(pitchClass + 1) % 12]) / 2;
      final double score =
          baseEnergy * (1 - neighborWeight) + neighborEnergy * neighborWeight;
      if (score > bestScore) {
        bestScore = score;
        bestMatch = note.stringIndex;
      }
    }

    if (bestMatch != null) {
      return bestMatch;
    }

    if (fundamental != null) {
      return matchFrequency(
        fundamental,
        toleranceCents: fallbackToleranceCents,
      );
    }

    return null;
  }

  String stringLabel(int index) => stringTunings[index].label;

  ChordNote _buildNoteForString(int stringIndex, int fret) {
    final StringTuning tuning = stringTunings[stringIndex];
    final int midi = tuning.midi + fret;
    final double frequency = 440.0 * pow(2, (midi - 69) / 12).toDouble();

    return ChordNote(
      stringIndex: stringIndex,
      midi: midi,
      noteName: _noteNameFromMidi(midi),
      pitchClass: midi % 12,
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

  bool isStringRequired(int index) => requiredStringIndexes.contains(index);

  static Set<int> _normalizeRequiredIndexes(
    List<StringTuning> tunings,
    Set<int>? overrides,
  ) {
    final Iterable<int> indexes =
        overrides ?? List<int>.generate(tunings.length, (int index) => index);
    final Set<int> normalized = indexes
        .where((int index) => index >= 0 && index < tunings.length)
        .toSet();
    assert(normalized.isNotEmpty,
        'Chord must require at least one string to ring.');
    return Set<int>.unmodifiable(normalized);
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

  /// Zero-based index of the string (0 = lowest pitch string).
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
    required this.pitchClass,
    required this.frequency,
  });

  final int stringIndex;
  final int midi;
  final String noteName;
  final int pitchClass;
  final double frequency;
}

class StringTuning {
  const StringTuning({required this.label, required this.midi});

  final String label;
  final int midi;
}
