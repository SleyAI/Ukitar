import 'dart:async';

import 'package:flutter_fft/flutter_fft.dart';
import 'package:permission_handler/permission_handler.dart';

/// Listens to microphone input and emits detected dominant frequencies.
class ChordRecognitionService {
  final FlutterFft _flutterFft = FlutterFft();
  final StreamController<double> _frequencyController =
      StreamController<double>.broadcast();

  Stream<double> get frequencyStream => _frequencyController.stream;

  bool _isRecording = false;
  StreamSubscription<dynamic>? _fftSubscription;

  Future<void> dispose() async {
    await stopListening();
    await _frequencyController.close();
  }

  Future<void> startListening() async {
    final PermissionStatus status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw MicrophonePermissionException();
    }

    if (_isRecording) {
      return;
    }

    await _flutterFft.startRecorder();
    _isRecording = true;

    _fftSubscription = _flutterFft.onRecorderStateChanged.listen((dynamic data) {
      if (data is! List<dynamic> || data.length < 2) {
        return;
      }
      final dynamic rawFrequency = data[1];
      final double? frequency = _toDouble(rawFrequency);
      if (frequency != null && frequency > 20 && frequency < 2000) {
        _frequencyController.add(frequency);
      }
    });
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
}

class MicrophonePermissionException implements Exception {}
