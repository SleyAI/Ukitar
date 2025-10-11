import 'dart:async';
import 'dart:math';

import 'package:flutter_fft/flutter_fft.dart';
import 'package:permission_handler/permission_handler.dart';

/// Listens to microphone input and emits chroma-based detection frames.
class ChordRecognitionService {
  final FlutterFft _flutterFft = FlutterFft();
  final StreamController<ChordDetectionFrame> _analysisController =
      StreamController<ChordDetectionFrame>.broadcast();

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
      if (magnitude <= 0) {
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
    if (totalEnergy <= 0) {
      return null;
    }

    final List<double> chroma = _buildChromagram(spectrum);
    return ChordDetectionFrame(
      chroma: chroma,
      fundamental: fundamental,
      energy: totalEnergy,
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
      smoothed[i] = value < 0 ? 0 : value;
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
        .map((double value) => value <= 0 ? 0 : value / maxValue)
        .toList();
  }
}

class MicrophonePermissionException implements Exception {
  MicrophonePermissionException({this.requiresSettings = false});

  final bool requiresSettings;
}

class ChordDetectionFrame {
  ChordDetectionFrame({
    required this.chroma,
    required this.energy,
    this.fundamental,
  }) : assert(
          chroma.length == 12,
          'Chromagram must contain exactly 12 pitch-class bins.',
        );

  final List<double> chroma;
  final double energy;
  final double? fundamental;
}

class _FrequencyComponent {
  _FrequencyComponent({
    required this.frequency,
    required this.magnitude,
  });

  final double frequency;
  final double magnitude;
}

