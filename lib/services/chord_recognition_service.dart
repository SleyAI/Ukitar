import 'dart:async';
import 'dart:math';

import 'package:flutter_fft/flutter_fft.dart';
import 'package:permission_handler/permission_handler.dart';

/// Listens to microphone input and emits chroma-based detection frames.
class ChordRecognitionService {
  ChordRecognitionService({
    this.minimumInputAmplitude = 0.02,
    this.minimumComponentMagnitude = 0.015,
    this.minimumTotalEnergy = 0.12,
    this.minimumPeakProminence = 0.2,
  });

  final FlutterFft _flutterFft = FlutterFft();
  final StreamController<ChordDetectionFrame> _analysisController =
      StreamController<ChordDetectionFrame>.broadcast();

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

    _fftSubscription =
        _flutterFft.onRecorderStateChanged.listen((dynamic data) {
      final ChordDetectionFrame? frame = _toDetectionFrame(data);
      if (frame != null) {
        _analysisController.add(frame);
      }
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

  ChordDetectionFrame? _toDetectionFrame(dynamic data) {
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

    return ChordDetectionFrame(
      chroma: combinedChroma,
      fftChroma: fftChroma,
      constantQChroma: constantQChroma,
      fundamental: fundamental,
      energy: totalEnergy,
      peaks: peaks,
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

class ChordDetectionFrame {
  ChordDetectionFrame({
    required List<double> chroma,
    required List<double> fftChroma,
    required List<double> constantQChroma,
    required this.energy,
    required List<FrequencyPeak> peaks,
    this.fundamental,
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
        peaks = List<FrequencyPeak>.unmodifiable(peaks);

  final List<double> chroma;
  final List<double> fftChroma;
  final List<double> constantQChroma;
  final double energy;
  final double? fundamental;
  final List<FrequencyPeak> peaks;
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

class _FrequencyComponent {
  _FrequencyComponent({
    required this.frequency,
    required this.magnitude,
  });

  final double frequency;
  final double magnitude;
}

