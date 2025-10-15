import '../services/chord_recognition_service.dart';

bool isConfidentUkulelePrediction(
  ChordDetectionFrame frame, {
  double highConfidenceThreshold = 0.55,
  double minimumProbability = 0.35,
  double probabilityMargin = 0.12,
  double ratioThreshold = 1.35,
}) {
  final double? confidence = frame.predictedConfidence;
  if (confidence != null && confidence >= highConfidenceThreshold) {
    return true;
  }

  final List<double>? probabilities = frame.probabilities;
  final int? index = frame.predictedIndex;
  if (probabilities == null || index == null) {
    return false;
  }
  if (index < 0 || index >= probabilities.length) {
    return false;
  }

  final double topProbability = probabilities[index];
  if (topProbability < minimumProbability) {
    return false;
  }

  double runnerUp = 0;
  for (int i = 0; i < probabilities.length; i++) {
    if (i == index) {
      continue;
    }
    final double value = probabilities[i];
    if (value > runnerUp) {
      runnerUp = value;
    }
  }

  final double margin = topProbability - runnerUp;
  final double ratio = runnerUp <= 0 ? double.infinity : topProbability / runnerUp;

  return margin >= probabilityMargin && ratio >= ratioThreshold;
}
