import 'package:flutter_test/flutter_test.dart';

import 'package:ukitar/models/chord.dart';

void main() {
  group('Chromagram AI chord detection', () {
    late Chord chord;

    setUp(() {
      chord = Chord(
        id: 'test',
        name: 'Test',
        description: 'Test chord',
        fingerPositions: const <ChordFingerPosition>[],
        tips: const <String>[],
        stringTunings: const <StringTuning>[
          StringTuning(label: 'C', midi: 60),
          StringTuning(label: 'E', midi: 64),
          StringTuning(label: 'G', midi: 67),
        ],
      );
    });

    test('high chroma energy on a chord tone yields a confident match', () {
      final List<double> chroma = List<double>.filled(12, 0.02);
      chroma[0] = 0.92; // C
      chroma[1] = 0.12; // neighbour support
      chroma[11] = 0.08;
      chroma[4] = 0.25; // other chord tones
      chroma[7] = 0.2;

      final int? match = chord.matchPitchClasses(chroma, minEnergy: 0.45);

      expect(match, isNotNull);
      expect(chord.notes[match!].pitchClass, equals(0));
    });

    test('low chroma energy does not trigger a detection', () {
      final List<double> chroma = List<double>.filled(12, 0.01);

      final int? match = chord.matchPitchClasses(chroma, minEnergy: 0.9);

      expect(match, isNull);
    });
  });
}
