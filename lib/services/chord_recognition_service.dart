import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_fft/flutter_fft.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pytorch_lite/pytorch_lite.dart';

import '../models/instrument.dart';

/// Listens to microphone input and emits chroma-based detection frames.
class ChordRecognitionService {
  /// Default thresholds favour rejecting quiet or noisy frames so that ambient
  /// sounds do not trigger chord recognitions when the player is idle.
  ChordRecognitionService({
    this.minimumInputAmplitude = 0.085,
    this.minimumComponentMagnitude = 0.05,
    this.minimumTotalEnergy = 0.4,
    this.minimumPeakProminence = 0.48,
    this.instrument,
  });

  final FlutterFft _flutterFft = FlutterFft();
  final StreamController<ChordDetectionFrame> _analysisController =
      StreamController<ChordDetectionFrame>.broadcast();

  final InstrumentType? instrument;

  /// Frames with an input amplitude below this value are discarded. The
  /// amplitude comes directly from the `flutter_fft` plugin and remains
  /// `null` on platforms that do not expose it, in which case the gate is
  /// skipped.
  final double minimumInputAmplitude;

  /// Individual spectral components with a magnitude below this value are
  /// ignored to avoid reinforcing background noise.
  final double minimumComponentMagnitude;

  /// The aggregated energy of the spectrum must exceed this threshold for a
  /// frame to be considered.
  final double minimumTotalEnergy;

  /// The strongest peak in the spectrum must contribute at least this ratio of
  /// the overall energy (peaks are normalised to the range 0..1).
  final double minimumPeakProminence;

  Stream<ChordDetectionFrame> get detectionStream =>
      _analysisController.stream;

  bool _isRecording = false;
  StreamSubscription<dynamic>? _fftSubscription;
  _MelSpectrogramAccumulator? _melSpectrogramAccumulator;
  UkuleleChordClassifier? _ukuleleClassifier;
  bool _isClassifierLoading = false;

  Future<void> dispose() async {
    await stopListening();
    await _analysisController.close();
  }

  Future<void> startListening() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      final bool requiresSettings =
          status.isPermanentlyDenied || status.isRestricted;
      throw MicrophonePermissionException(
        requiresSettings: requiresSettings,
      );
    }

    if (_isRecording) {
      return;
    }

    await _flutterFft.startRecorder();
    _isRecording = true;

    if (_shouldUseUkuleleClassifier) {
      _melSpectrogramAccumulator ??= _MelSpectrogramAccumulator(
        nMels: 128,
        maxFrames: 100,
      );
      unawaited(_ensureClassifierLoaded());
    } else {
      _melSpectrogramAccumulator = null;
    }

    _fftSubscription =
        _flutterFft.onRecorderStateChanged.listen((dynamic data) {
      unawaited(_handleRecorderFrame(data));
    });
  }

  Future<bool> openSystemSettings() async {
    final PermissionStatus status = await Permission.microphone.request();
    return status.isGranted || status.isLimited;
  }

  Future<void> stopListening() async {
    if (!_isRecording) {
      return;
    }
    await _flutterFft.stopRecorder();
    await _fftSubscription?.cancel();
    _fftSubscription = null;
    _isRecording = false;
  }

  bool get _shouldUseUkuleleClassifier =>
      instrument == InstrumentType.ukulele;

  Future<void> _ensureClassifierLoaded() async {
    if (!_shouldUseUkuleleClassifier) {
      return;
    }
    if (_ukuleleClassifier != null || _isClassifierLoading) {
      return;
    }
    _isClassifierLoading = true;
    try {
      _ukuleleClassifier = await UkuleleChordClassifier.load();
    } catch (error, stackTrace) {
      debugPrint('Failed to load ukulele chord classifier: $error');
      debugPrint('$stackTrace');
    } finally {
      _isClassifierLoading = false;
    }
  }

  Future<void> _handleRecorderFrame(dynamic data) async {
    final _PendingFrame? pending = _toDetectionFrame(data);
    if (pending == null) {
      return;
    }

    UkuleleChordPrediction? prediction;
    final List<double>? melInput = pending.melInput;
    if (melInput != null) {
      UkuleleChordClassifier? classifier = _ukuleleClassifier;
      if (classifier == null && _shouldUseUkuleleClassifier) {
        await _ensureClassifierLoaded();
        classifier = _ukuleleClassifier;
      }
      if (classifier != null) {
        try {
          prediction = await classifier.predict(melInput);
        } catch (error, stackTrace) {
          debugPrint('Chord classifier inference failed: $error');
          debugPrint('$stackTrace');
        }
      }
    }

    final ChordDetectionFrame frame = ChordDetectionFrame(
      chroma: pending.chroma,
      fftChroma: pending.fftChroma,
      constantQChroma: pending.constantQChroma,
      energy: pending.energy,
      peaks: pending.peaks,
      fundamental: pending.fundamental,
      predictedLabel: prediction?.label,
      predictedConfidence: prediction?.confidence,
      predictedIndex: prediction?.index,
      predictedChordId: prediction?.mappedChordId,
      probabilities: prediction?.probabilities,
    );

    _analysisController.add(frame);
  }

  double? _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  _PendingFrame? _toDetectionFrame(dynamic data) {
    if (data is! List<dynamic> || data.isEmpty) {
      return null;
    }

    final double? fundamental =
        data.length > 1 ? _toDouble(data[1]) : null;
    final double? inputAmplitude = data.length > 2 ? _toDouble(data[2]) : null;
    if (inputAmplitude != null && inputAmplitude.abs() < minimumInputAmplitude) {
      return null;
    }

    final List<_FrequencyComponent> components =
        _extractComponents(data, fundamental: fundamental);
    if (components.isEmpty) {
      return null;
    }

    final Map<double, double> spectrum = <double, double>{};
    for (final _FrequencyComponent component in components) {
      final double frequency = component.frequency;
      if (frequency <= 20 || frequency > 5000) {
        continue;
      }
      final double magnitude = component.magnitude;
      if (magnitude < minimumComponentMagnitude) {
        continue;
      }
      spectrum.update(
        frequency,
        (double value) => value + magnitude,
        ifAbsent: () => magnitude,
      );
    }

    if (spectrum.isEmpty) {
      return null;
    }

    final double totalEnergy = spectrum.values.fold(
      0.0,
      (double sum, double value) => sum + value,
    );
    if (totalEnergy <= minimumTotalEnergy) {
      return null;
    }

    final List<double> fftChroma = _buildChromagram(spectrum);
    final List<double> constantQChroma = _buildConstantQChroma(spectrum);
    final List<double> combinedChroma = List<double>.generate(
      12,
      (int index) =>
          max(fftChroma[index], constantQChroma[index]),
      growable: false,
    );

    List<double>? melInput;
    final _MelSpectrogramAccumulator? accumulator = _melSpectrogramAccumulator;
    if (accumulator != null) {
      melInput = accumulator.addSpectrum(spectrum);
    }

    List<FrequencyPeak> peaks = spectrum.entries
        .map(
          (MapEntry<double, double> entry) {
            final double magnitude = entry.value / totalEnergy;
            final int pitchClass = _pitchClassFromFrequency(entry.key);
            final double constantQMagnitude = constantQChroma[pitchClass];
            return FrequencyPeak(
              frequency: entry.key,
              magnitude: magnitude,
              constantQMagnitude: constantQMagnitude,
            );
          },
        )
        .toList(growable: false)
      ..sort(
        (FrequencyPeak a, FrequencyPeak b) =>
            b.magnitude.compareTo(a.magnitude),
      );

    const int maxPeaks = 16;
    if (peaks.length > maxPeaks) {
      peaks = List<FrequencyPeak>.unmodifiable(peaks.sublist(0, maxPeaks));
    } else {
      peaks = List<FrequencyPeak>.unmodifiable(peaks);
    }

    if (peaks.isEmpty || peaks.first.magnitude < minimumPeakProminence) {
      return null;
    }

    return _PendingFrame(
      chroma: combinedChroma,
      fftChroma: fftChroma,
      constantQChroma: constantQChroma,
      fundamental: fundamental,
      energy: totalEnergy,
      peaks: peaks,
      melInput: melInput,
    );
  }

  List<_FrequencyComponent> _extractComponents(
    List<dynamic> data, {
    double? fundamental,
  }) {
    final List<_FrequencyComponent> components = <_FrequencyComponent>[];

    if (fundamental != null && fundamental > 20 && fundamental < 5000) {
      components.add(
        _FrequencyComponent(frequency: fundamental, magnitude: 1.0),
      );
      for (int harmonic = 2; harmonic <= 6; harmonic++) {
        final double harmonicFrequency = fundamental * harmonic;
        if (harmonicFrequency > 5000) {
          break;
        }
        components.add(
          _FrequencyComponent(
            frequency: harmonicFrequency,
            magnitude: 1 / (harmonic * harmonic),
          ),
        );
      }
    }

    for (final dynamic entry in data) {
      if (entry is Map<dynamic, dynamic>) {
        final double? frequency = _toDouble(entry['frequency']) ??
            _toDouble(entry['freq']) ??
            _toDouble(entry['f']);
        final double? magnitude = _toDouble(entry['magnitude']) ??
            _toDouble(entry['amplitude']) ??
            _toDouble(entry['power']) ??
            _toDouble(entry['value']);
        if (frequency != null && magnitude != null) {
          components.add(
            _FrequencyComponent(
              frequency: frequency,
              magnitude: magnitude.abs(),
            ),
          );
        }
      } else if (entry is List<dynamic>) {
        if (entry.length >= 2) {
          final double? frequency = _toDouble(entry[0]);
          final double? magnitude = _toDouble(entry[1]);
          if (frequency != null && magnitude != null) {
            components.add(
              _FrequencyComponent(
                frequency: frequency,
                magnitude: magnitude.abs(),
              ),
            );
          }
        } else if (entry.length == 1) {
          final double? frequency = _toDouble(entry[0]);
          if (frequency != null) {
            components.add(
              _FrequencyComponent(
                frequency: frequency,
                magnitude: 1.0,
              ),
            );
          }
        }
      }
    }

    return components;
  }

  List<double> _buildChromagram(Map<double, double> spectrum) {
    final List<double> chroma = List<double>.filled(12, 0);

    spectrum.forEach((double frequency, double magnitude) {
      if (frequency <= 0 || magnitude <= 0) {
        return;
      }
      final double midi = 69 + (12 * (log(frequency / 440.0) / ln2));
      double pitchClass = midi % 12;
      if (pitchClass < 0) {
        pitchClass += 12;
      }
      final int lowerIndex = pitchClass.floor();
      final double fraction = pitchClass - lowerIndex;
      final int upperIndex = (lowerIndex + 1) % 12;

      chroma[lowerIndex] += magnitude * (1 - fraction);
      chroma[upperIndex] += magnitude * fraction;
    });

    final List<double> smoothed = List<double>.filled(12, 0);
    const double smoothing = 0.2;
    for (int i = 0; i < 12; i++) {
      final double current = chroma[i];
      final double previous = chroma[(i + 11) % 12];
      final double next = chroma[(i + 1) % 12];
      final double value =
          current * (1 - (2 * smoothing)) + smoothing * (previous + next);
      smoothed[i] = value < 0 ? 0.0 : value;
    }

    double maxValue = 0;
    for (final double value in smoothed) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    if (maxValue <= 0) {
      return smoothed;
    }

    return smoothed
        .map((double value) => value <= 0 ? 0.0 : value / maxValue)
        .toList();
  }

  List<double> _buildConstantQChroma(Map<double, double> spectrum) {
    final List<double> chroma = List<double>.filled(12, 0);
    if (spectrum.isEmpty) {
      return chroma;
    }

    const int minMidi = 36; // C2
    const int maxMidi = 84; // C6
    const double binsPerOctave = 12.0;
    final double q = 1 / (pow(2, 1 / binsPerOctave) - 1);
    final List<MapEntry<double, double>> components =
        spectrum.entries.toList(growable: false);

    for (int midi = minMidi; midi <= maxMidi; midi++) {
      final double centerFrequency =
          440.0 * pow(2.0, (midi - 69) / 12.0);
      if (centerFrequency <= 0) {
        continue;
      }
      final double bandwidth = centerFrequency / q;
      final double sigma = max(
        1.0,
        bandwidth / (2 * sqrt(2 * ln2)),
      );

      double energy = 0;
      for (final MapEntry<double, double> component in components) {
        final double frequency = component.key;
        final double magnitude = component.value;
        if (frequency <= 0 || magnitude <= 0) {
          continue;
        }
        final double distance = frequency - centerFrequency;
        if (distance.abs() > bandwidth) {
          continue;
        }
        final double weight = exp(-0.5 * pow(distance / sigma, 2));
        if (weight <= 0.0001) {
          continue;
        }
        energy += magnitude * weight;
      }

      final int pitchClass = (midi % 12 + 12) % 12;
      chroma[pitchClass] += energy;
    }

    double maxValue = 0;
    for (final double value in chroma) {
      if (value > maxValue) {
        maxValue = value;
      }
    }

    if (maxValue <= 0) {
      return chroma;
    }

    return chroma
        .map((double value) => value <= 0 ? 0.0 : value / maxValue)
        .toList(growable: false);
  }

  int _pitchClassFromFrequency(double frequency) {
    if (frequency <= 0) {
      return 0;
    }
    final double midi = 69 + (12 * (log(frequency / 440.0) / ln2));
    int pitchClass = midi.round() % 12;
    if (pitchClass < 0) {
      pitchClass += 12;
    }
    return pitchClass;
  }
}

class MicrophonePermissionException implements Exception {
  MicrophonePermissionException({this.requiresSettings = false});

  final bool requiresSettings;
}

class _PendingFrame {
  _PendingFrame({
    required this.chroma,
    required this.fftChroma,
    required this.constantQChroma,
    required this.energy,
    required this.peaks,
    required this.fundamental,
    this.melInput,
  });

  final List<double> chroma;
  final List<double> fftChroma;
  final List<double> constantQChroma;
  final double energy;
  final List<FrequencyPeak> peaks;
  final double? fundamental;
  final List<double>? melInput;
}

class ChordDetectionFrame {
  ChordDetectionFrame({
    required List<double> chroma,
    required List<double> fftChroma,
    required List<double> constantQChroma,
    required this.energy,
    required List<FrequencyPeak> peaks,
    this.fundamental,
    this.predictedLabel,
    this.predictedConfidence,
    this.predictedIndex,
    this.predictedChordId,
    List<double>? probabilities,
  })  : assert(
          chroma.length == 12,
          'Chromagram must contain exactly 12 pitch-class bins.',
        ),
        assert(
          fftChroma.length == 12,
          'FFT chromagram must contain exactly 12 pitch-class bins.',
        ),
        assert(
          constantQChroma.length == 12,
          'Constant-Q chromagram must contain exactly 12 pitch-class bins.',
        ),
        chroma = List<double>.unmodifiable(chroma),
        fftChroma = List<double>.unmodifiable(fftChroma),
        constantQChroma = List<double>.unmodifiable(constantQChroma),
        peaks = List<FrequencyPeak>.unmodifiable(peaks),
        probabilities = probabilities == null
            ? null
            : List<double>.unmodifiable(probabilities);

  final List<double> chroma;
  final List<double> fftChroma;
  final List<double> constantQChroma;
  final double energy;
  final double? fundamental;
  final List<FrequencyPeak> peaks;
  final String? predictedLabel;
  final double? predictedConfidence;
  final int? predictedIndex;
  final String? predictedChordId;
  final List<double>? probabilities;
}

class FrequencyPeak {
  const FrequencyPeak({
    required this.frequency,
    required this.magnitude,
    required this.constantQMagnitude,
  });

  final double frequency;
  final double magnitude;
  final double constantQMagnitude;
}

class _MelSpectrogramAccumulator {
  _MelSpectrogramAccumulator({
    required this.nMels,
    required this.maxFrames,
    this.minFrequency = 30,
    this.maxFrequency = 5000,
  })  : _melMin = _hzToMel(minFrequency.toDouble()),
        _melMax = _hzToMel(maxFrequency.toDouble());

  final int nMels;
  final int maxFrames;
  final double minFrequency;
  final double maxFrequency;

  final double _melMin;
  final double _melMax;
  final ListQueue<List<double>> _frames = ListQueue<List<double>>();

  static double _hzToMel(double hz) {
    if (hz <= 0) {
      return 0;
    }
    return 2595.0 * log(1 + hz / 700.0) / ln10;
  }

  List<double>? addSpectrum(Map<double, double> spectrum) {
    if (spectrum.isEmpty) {
      return null;
    }

    final List<double> frame = List<double>.filled(nMels, 0);
    spectrum.forEach((double frequency, double magnitude) {
      if (frequency < minFrequency || frequency > maxFrequency) {
        return;
      }
      final double mel = _hzToMel(frequency);
      final double range = _melMax - _melMin;
      if (range <= 0) {
        return;
      }
      final double normalized = (mel - _melMin) / range;
      if (normalized.isNaN) {
        return;
      }
      int index = (normalized * nMels).floor();
      if (index < 0) {
        index = 0;
      } else if (index >= nMels) {
        index = nMels - 1;
      }
      frame[index] += magnitude.abs();
    });

    for (int i = 0; i < frame.length; i++) {
      final double energy = frame[i];
      final double db = 10 * log(energy + 1e-6) / ln10;
      final double clipped = db < -80 ? -80 : db;
      double normalized = (clipped + 80) / 80;
      if (normalized.isNaN || normalized.isInfinite) {
        normalized = 0;
      } else if (normalized < 0) {
        normalized = 0;
      } else if (normalized > 1) {
        normalized = 1;
      }
      frame[i] = normalized;
    }

    _frames.addLast(List<double>.from(frame));
    if (_frames.length > maxFrames) {
      _frames.removeFirst();
    }

    if (_frames.length < maxFrames) {
      return null;
    }

    final List<double> flattened = List<double>.filled(nMels * maxFrames, 0);
    int offset = 0;
    for (final List<double> values in _frames) {
      flattened.setAll(offset, values);
      offset += nMels;
    }
    return flattened;
  }
}

const Map<String, String> _ukuleleLabelToChordId = <String, String>{
  'A_major': 'a-major',
  'A_minor': 'a-minor',
  'C': 'c-major',
  'D_7': 'd7',
  'D_major': 'd-major',
  'D_minor': 'd-minor',
  'E_7': 'e7',
  'F': 'f-major',
  'G': 'g-major',
};

class UkuleleChordPrediction {
  UkuleleChordPrediction({
    required this.index,
    required this.label,
    required this.confidence,
    required this.probabilities,
  }) : mappedChordId = _ukuleleLabelToChordId[label];

  final int index;
  final String label;
  final double confidence;
  final List<double> probabilities;
  final String? mappedChordId;
}

class UkuleleChordClassifier {
  UkuleleChordClassifier._(this._model);

  static const List<String> _labels = <String>[
    'A_7',
    'A_major',
    'A_minor',
    'C',
    'D_7',
    'D_major',
    'D_minor',
    'E_7',
    'F',
    'G',
  ];

  final dynamic _model;

  static Future<UkuleleChordClassifier?> load() async {
    try {
      final dynamic pytorchLite = PytorchLite();
      const String path =
          'ai_models/ukulele_chord_detection/mobilenetv2_step240.pt';
      dynamic model;
      try {
        model = await pytorchLite.loadModel(modelPath: path);
      } on NoSuchMethodError {
        model = await pytorchLite.loadModel(path);
      }
      return UkuleleChordClassifier._(model);
    } catch (error, stackTrace) {
      debugPrint('Failed to initialise TorchScript model: $error');
      debugPrint('$stackTrace');
      return null;
    }
  }

  Future<UkuleleChordPrediction?> predict(List<double> input) async {
    if (_model == null) {
      return null;
    }

    final Float32List tensor = Float32List.fromList(input);

    dynamic rawOutput;
    try {
      rawOutput = await _model.getOutput(tensor);
    } catch (_) {
      try {
        rawOutput = await _model.forward(tensor);
      } catch (error, stackTrace) {
        debugPrint('TorchScript inference error: $error');
        debugPrint('$stackTrace');
        return null;
      }
    }

    List<double> logits;
    if (rawOutput is List<double>) {
      logits = rawOutput;
    } else if (rawOutput is Float32List) {
      logits = rawOutput.toList();
    } else if (rawOutput is List<dynamic>) {
      logits = rawOutput
          .map((dynamic value) => value is num ? value.toDouble() : 0.0)
          .toList(growable: false);
    } else {
      return null;
    }

    if (logits.isEmpty) {
      return null;
    }

    final List<double> probabilities = _softmax(logits);
    int bestIndex = 0;
    double bestValue = probabilities[0];
    for (int i = 1; i < probabilities.length; i++) {
      final double candidate = probabilities[i];
      if (candidate > bestValue) {
        bestIndex = i;
        bestValue = candidate;
      }
    }

    final String label =
        bestIndex < _labels.length ? _labels[bestIndex] : _labels.first;

    return UkuleleChordPrediction(
      index: bestIndex,
      label: label,
      confidence: bestValue,
      probabilities: probabilities,
    );
  }

  static List<double> _softmax(List<double> values) {
    if (values.isEmpty) {
      return <double>[];
    }
    final double maxValue = values.reduce(max);
    double sum = 0;
    final List<double> exps = List<double>.filled(values.length, 0);
    for (int i = 0; i < values.length; i++) {
      final double expValue = exp(values[i] - maxValue);
      exps[i] = expValue;
      sum += expValue;
    }
    if (sum <= 0) {
      return List<double>.filled(values.length, 0);
    }
    return exps.map((double value) => value / sum).toList(growable: false);
  }
}

class _FrequencyComponent {
  _FrequencyComponent({
    required this.frequency,
    required this.magnitude,
  });

  final double frequency;
  final double magnitude;
}

