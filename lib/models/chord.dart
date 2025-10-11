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
    _stringClassifier = _ChromagramStringClassifier(
      notes: _notes,
      requiredStringIndexes: this.requiredStringIndexes,
    );
  }

  final String id;
  final String name;
  final String description;
  final List<ChordFingerPosition> fingerPositions;
  final List<String> tips;
  final List<StringTuning> stringTunings;
  final Set<int> requiredStringIndexes;

  late final List<ChordNote> _notes;
  late final _ChromagramStringClassifier _stringClassifier;

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

  /// Estimates which required string was played by analysing the provided
  /// chromagram with a lightweight logistic model.
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

    final _ChromagramPrediction? prediction = _stringClassifier.predict(
      chroma,
      neighborWeight: neighborWeight,
    );

    if (prediction != null && prediction.confidence >= minEnergy) {
      return prediction.stringIndex;
    }

    if (fundamental != null) {
      final int? matched = matchFrequency(
        fundamental,
        toleranceCents: fallbackToleranceCents,
      );
      if (matched != null) {
        return matched;
      }
    }

    final int? dominantMatch = _matchDominantPitchClass(
      chroma,
      requiredStrings: requiredStringIndexes,
    );
    if (dominantMatch != null) {
      return dominantMatch;
    }

    if (prediction != null &&
        prediction.confidence >= minEnergy * 0.6 &&
        requiredStringIndexes.contains(prediction.stringIndex)) {
      return prediction.stringIndex;
    }

    return null;
  }

  String stringLabel(int index) => stringTunings[index].label;

  int? _matchDominantPitchClass(
    List<double> chroma, {
    required Set<int> requiredStrings,
  }) {
    int? bestPitchClass;
    double bestValue = 0;
    double runnerUpValue = 0;

    for (int index = 0; index < chroma.length; index++) {
      final double value = chroma[index];
      if (value.isNaN || value.isInfinite || value <= 0) {
        continue;
      }
      if (value > bestValue) {
        runnerUpValue = bestValue;
        bestValue = value;
        bestPitchClass = index;
      } else if (value > runnerUpValue) {
        runnerUpValue = value;
      }
    }

    if (bestPitchClass == null || bestValue < 0.3) {
      return null;
    }

    if (bestValue - runnerUpValue < 0.12 &&
        (runnerUpValue / bestValue) > 0.55) {
      return null;
    }

    final List<int> candidates = <int>[];
    for (final ChordNote note in _notes) {
      if (!requiredStrings.contains(note.stringIndex)) {
        continue;
      }
      if (note.pitchClass == bestPitchClass) {
        candidates.add(note.stringIndex);
      }
    }

    if (candidates.length == 1) {
      return candidates.first;
    }

    return null;
  }

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

class _ChromagramStringClassifier {
  _ChromagramStringClassifier({
    required List<ChordNote> notes,
    required Set<int> requiredStringIndexes,
  })  : _requiredPitchClasses = notes
            .where(
                (ChordNote note) => requiredStringIndexes.contains(note.stringIndex))
            .map((ChordNote note) => note.pitchClass)
            .toSet(),
        _stringModels = <_StringModel>[],
        _nonChordPitchClasses = <int>{} {
    final Set<int> chordPitchClasses = _requiredPitchClasses;
    _stringModels.addAll(
      notes
          .where((ChordNote note) =>
              requiredStringIndexes.contains(note.stringIndex))
          .map(
            (ChordNote note) => _StringModel(
              note: note,
              chordPitchClasses: chordPitchClasses,
            ),
          ),
    );
    _nonChordPitchClasses.addAll(
      List<int>.generate(12, (int index) => index)
          .where((int pitchClass) => !chordPitchClasses.contains(pitchClass)),
    );
  }

  final Set<int> _requiredPitchClasses;
  final Set<int> _nonChordPitchClasses;
  final List<_StringModel> _stringModels;

  _ChromagramPrediction? predict(
    List<double> chroma, {
    double neighborWeight = 0.25,
  }) {
    if (chroma.length != 12 || _stringModels.isEmpty) {
      return null;
    }

    final double clampedNeighborWeight =
        neighborWeight.clamp(0.0, 1.0).toDouble();

    final List<double> sanitized = List<double>.generate(
      12,
      (int index) {
        final double value = chroma[index];
        if (value.isNaN || value.isInfinite) {
          return 0.0;
        }
        return max(0.0, value);
      },
      growable: false,
    );

    final double totalEnergy = sanitized.fold<double>(
      0,
      (double sum, double value) => sum + value,
    );
    if (totalEnergy <= 0.001) {
      return null;
    }

    final double peak = sanitized.reduce(max);
    final double noiseFloor = _estimateNoiseFloor(sanitized);

    final double chordAverage = _averageEnergy(
      sanitized,
      _requiredPitchClasses,
    );
    final double nonChordAverage = _averageEnergy(
      sanitized,
      _nonChordPitchClasses,
    );

    _ChromagramPrediction? bestPrediction;
    for (final _StringModel model in _stringModels) {
      final double confidence = model.evaluate(
        sanitized,
        chordAverage: chordAverage,
        nonChordAverage: nonChordAverage,
        noiseFloor: noiseFloor,
        peak: peak,
        totalEnergy: totalEnergy,
        neighborWeight: clampedNeighborWeight,
      );
      if (confidence.isNaN) {
        continue;
      }
      if (bestPrediction == null || confidence > bestPrediction.confidence) {
        bestPrediction = _ChromagramPrediction(
          model.stringIndex,
          confidence,
        );
      }
    }

    return bestPrediction;
  }

  double _estimateNoiseFloor(List<double> chroma) {
    final List<double> sorted = chroma.where((double value) => value > 0).toList()
      ..sort();
    if (sorted.isEmpty) {
      return 0.01;
    }
    final int lowerIndex = max(0, (sorted.length * 0.25).floor() - 1);
    final int upperIndex = max(0, (sorted.length * 0.5).floor() - 1);
    return max(0.01, (sorted[lowerIndex] + sorted[upperIndex]) / 2);
  }

  double _averageEnergy(List<double> chroma, Iterable<int> pitchClasses) {
    double sum = 0;
    int count = 0;
    for (final int pitchClass in pitchClasses) {
      sum += chroma[pitchClass];
      count++;
    }
    if (count == 0) {
      return 0;
    }
    return sum / count;
  }
}

class _StringModel {
  _StringModel({
    required this.note,
    required Set<int> chordPitchClasses,
  })  : stringIndex = note.stringIndex,
        pitchClass = note.pitchClass,
        _otherPitchClasses = chordPitchClasses
            .where((int pitchClass) => pitchClass != note.pitchClass)
            .toList(growable: false);

  final ChordNote note;
  final int stringIndex;
  final int pitchClass;
  final List<int> _otherPitchClasses;

  double evaluate(
    List<double> chroma, {
    required double chordAverage,
    required double nonChordAverage,
    required double noiseFloor,
    required double peak,
    required double totalEnergy,
    required double neighborWeight,
  }) {
    final double main = chroma[pitchClass];
    final double prev = chroma[(pitchClass + 11) % 12];
    final double next = chroma[(pitchClass + 1) % 12];
    final double neighborSupport = (prev + next) / 2;
    final double localBlend =
        (main * (1 - neighborWeight)) + (neighborSupport * neighborWeight);

    double otherSupport = 0;
    if (_otherPitchClasses.isNotEmpty) {
      for (final int pitch in _otherPitchClasses) {
        otherSupport += chroma[pitch];
      }
      otherSupport /= _otherPitchClasses.length;
    } else {
      otherSupport = chordAverage;
    }

    final double prominence = peak <= 0 ? 0 : main / peak;
    final double noiseDelta = max(0.0, main - noiseFloor);
    final double safeDenominator = max(
      1e-6,
      (nonChordAverage * 0.6) + (noiseFloor * 0.4),
    );
    final double ratio = (main + 1e-6) / safeDenominator;
    final double limitedRatio = ratio.clamp(0.1, 25.0).toDouble();
    final double spread =
        (neighborSupport - nonChordAverage).clamp(0.0, 1.0).toDouble();

    double activation = -1.35;
    activation += main * 5.0;
    activation += neighborSupport * 1.8;
    activation += localBlend * 1.5;
    activation += otherSupport * 1.2;
    activation += log(limitedRatio) * 1.4;
    activation += noiseDelta * 3.0;
    activation += prominence * 1.7;
    activation += spread * 1.1;
    activation += chordAverage * 1.0;
    activation += (totalEnergy / (totalEnergy + 1.2)) * 0.7;

    final double probability = 1 / (1 + exp(-activation));
    if (probability.isNaN || probability.isInfinite) {
      return 0;
    }
    return probability.clamp(0.0, 1.0).toDouble();
  }
}

class _ChromagramPrediction {
  _ChromagramPrediction(this.stringIndex, this.confidence);

  final int stringIndex;
  final double confidence;
}
