import 'dart:math';

import '../models/chord.dart';
import '../services/chord_recognition_service.dart';

/// Identifies which required strings of [chord] are currently ringing in the
/// provided [frame] by combining FFT peaks, constant-Q magnitudes, and the
/// chroma profile. The detection is intentionally tolerant so that clean
/// strums are counted even when individual analyses disagree slightly, while
/// still requiring support from multiple transforms before accepting a match.
Set<int> identifyChordStringMatches(
  Chord chord,
  ChordDetectionFrame frame, {
  double frequencyToleranceCents = 35,
}) {
  final Set<int> requiredStrings = chord.requiredStringIndexes;
  if (requiredStrings.isEmpty) {
    return <int>{};
  }

  final Map<int, List<int>> pitchClassToStrings = <int, List<int>>{};
  for (final int stringIndex in requiredStrings) {
    final int pitchClass = chord.notes[stringIndex].pitchClass;
    pitchClassToStrings.putIfAbsent(pitchClass, () => <int>[]).add(stringIndex);
  }
  final Set<int> ambiguousPitchClasses = pitchClassToStrings.entries
      .where((MapEntry<int, List<int>> entry) => entry.value.length > 1)
      .map((MapEntry<int, List<int>> entry) => entry.key)
      .toSet();

  final Map<int, double> peakEvidence = <int, double>{};
  double strongestPeakEvidence = 0;
  double strongestPeakConstantQ = 0;

  for (final FrequencyPeak peak in frame.peaks) {
    if (peak.magnitude <= 0) {
      continue;
    }
    final int? matched = chord.matchFrequency(
      peak.frequency,
      toleranceCents: frequencyToleranceCents,
    );
    if (matched == null || !requiredStrings.contains(matched)) {
      continue;
    }
    final double fftWeight = _clamp01(peak.magnitude);
    final double constantQWeight = _clamp01(peak.constantQMagnitude);
    final double combinedEvidence = (fftWeight * 0.6) + (constantQWeight * 0.4);
    final double existing = peakEvidence[matched] ?? 0;
    if (combinedEvidence > existing) {
      peakEvidence[matched] = combinedEvidence;
    }
    if (combinedEvidence > strongestPeakEvidence) {
      strongestPeakEvidence = combinedEvidence;
    }
    if (constantQWeight > strongestPeakConstantQ) {
      strongestPeakConstantQ = constantQWeight;
    }
  }

  double chromaPeak = 0;
  for (final double value in frame.chroma) {
    final double sanitized = _clamp01(value);
    if (sanitized > chromaPeak) {
      chromaPeak = sanitized;
    }
  }

  double constantQPeak = 0;
  for (final double value in frame.constantQChroma) {
    final double sanitized = _clamp01(value);
    if (sanitized > constantQPeak) {
      constantQPeak = sanitized;
    }
  }

  final double chromaFloor =
      chromaPeak > 0 ? max(0.3, chromaPeak * 0.55) : 0.3;
  final double constantQFloor =
      constantQPeak > 0 ? max(0.12, constantQPeak * 0.5) : 0.12;
  final double peakFloor = strongestPeakEvidence > 0
      ? max(0.12, strongestPeakEvidence * 0.5)
      : 0.12;

  final Set<int> matches = <int>{};
  final bool allowChromaOnlyMatches =
      peakEvidence.isNotEmpty && strongestPeakEvidence >= 0.48;

  for (final int stringIndex in requiredStrings) {
    final int pitchClass = chord.notes[stringIndex].pitchClass;
    final double chromaEnergy = _valueForPitchClass(frame.chroma, pitchClass);
    final double constantQEnergy =
        _valueForPitchClass(frame.constantQChroma, pitchClass);
    final double peakEnergy = peakEvidence[stringIndex] ?? 0;

    final bool pitchClassAmbiguous = ambiguousPitchClasses.contains(pitchClass);

    final bool chromaStrong = chromaEnergy >= chromaFloor;
    final bool constantQStrong = constantQEnergy >= constantQFloor ||
        (strongestPeakConstantQ > 0 &&
            constantQEnergy >= strongestPeakConstantQ * 0.6);
    final bool peakStrong = peakEnergy > 0 &&
        (peakEnergy >= peakFloor ||
            (strongestPeakEvidence > 0 &&
                peakEnergy >= strongestPeakEvidence * 0.65));

    final double blendedScore = (peakEnergy * 0.4) +
        (chromaEnergy * 0.35) +
        (constantQEnergy * 0.25);

    if (peakEnergy > 0) {
      if ((chromaStrong && constantQStrong) ||
          (peakStrong && (chromaStrong || constantQStrong)) ||
          blendedScore >= 0.58) {
        matches.add(stringIndex);
        continue;
      }

      final bool moderateAgreement =
          peakEnergy >= peakFloor * 0.85 &&
              chromaEnergy >= chromaFloor * 0.78 &&
              constantQEnergy >= max(0.08, constantQFloor * 0.65);

      if (moderateAgreement) {
        matches.add(stringIndex);
      }
      continue;
    }

    if (allowChromaOnlyMatches &&
        chromaStrong &&
        constantQStrong &&
        !pitchClassAmbiguous) {
      final bool chromaAgreement = blendedScore >= 0.63 &&
          chromaEnergy >= chromaFloor * 0.92 &&
          constantQEnergy >= max(0.1, constantQFloor * 0.85);
      if (chromaAgreement) {
        matches.add(stringIndex);
      }
    }
  }

  final bool allowFallback = matches.isEmpty &&
      (
          frame.energy >= 0.35 ||
          strongestPeakEvidence >= 0.2 ||
          chromaPeak >= 0.65 ||
          constantQPeak >= 0.55);

  if (allowFallback) {
    final int? fallback = chord.matchPitchClasses(
      frame.chroma,
      minEnergy: 0.38,
      fundamental: frame.fundamental,
    );
    if (fallback != null) {
      matches.add(fallback);
    }
  }

  return matches;
}

double _valueForPitchClass(List<double> values, int index) {
  if (values.isEmpty) {
    return 0;
  }
  final int normalizedIndex = ((index % values.length) + values.length) % values.length;
  if (normalizedIndex < 0 || normalizedIndex >= values.length) {
    return 0;
  }
  return _clamp01(values[normalizedIndex]);
}

double _clamp01(double value) {
  if (value.isNaN || value.isInfinite) {
    return 0;
  }
  if (value <= 0) {
    return 0;
  }
  if (value >= 1) {
    return 1;
  }
  return value;
}
