import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../services/chord_recognition_service.dart';

class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel(this._chordRecognitionService)
      : chords = ChordLibrary.beginnerCourse() {
    _frequencySubscription =
        _chordRecognitionService.frequencyStream.listen(_handleFrequency);
    _prepareNextChord(initial: true);
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;

  late final StreamSubscription<double> _frequencySubscription;
  final Random _random = Random();
  final Set<int> _matchedStrings = <int>{};

  static const Duration _attemptTimeout = Duration(milliseconds: 1500);
  static const Duration _nextChordDelay = Duration(seconds: 2);

  late Chord currentChord;
  int? _currentChordIndex;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  bool showOpenSettingsButton = false;
  bool isPreparingNextChord = false;
  bool isChordPatternVisible = false;

  String statusMessage = 'Press "Start Listening" to begin.';

  Timer? _attemptTimer;
  bool _disposed = false;

  Future<void> startListening() async {
    if (isPreparingNextChord) {
      return;
    }

    lastAttemptSuccessful = null;
    statusMessage = 'Listening... Play the ${currentChord.name} chord.';
    showOpenSettingsButton = false;
    _matchedStrings.clear();
    notifyListeners();

    try {
      await _chordRecognitionService.startListening();
      isListening = true;
    } on MicrophonePermissionException catch (error) {
      showOpenSettingsButton = error.requiresSettings;
      statusMessage = error.requiresSettings
          ? 'Microphone access is disabled. Tap below to grant permission.'
          : 'Microphone permission is required to listen.';
    } catch (error) {
      statusMessage = 'Could not access the microphone: $error';
    }

    notifyListeners();
  }

  Future<void> stopListening({bool silent = false}) async {
    await _chordRecognitionService.stopListening();
    isListening = false;
    _attemptTimer?.cancel();
    _attemptTimer = null;

    if (!silent && lastAttemptSuccessful == null && _matchedStrings.isNotEmpty) {
      lastAttemptSuccessful = false;
      statusMessage =
          'Almost! Try strumming all strings of ${currentChord.name} cleanly.';
    }

    notifyListeners();
  }

  Future<void> retryCurrentChord() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = null;
    isPreparingNextChord = false;
    isChordPatternVisible = false;
    statusMessage =
        'Ready when you are. Press "Start Listening" and strum ${currentChord.name}.';
    _matchedStrings.clear();
    notifyListeners();
  }

  Future<void> skipToNextChord() async {
    await stopListening(silent: true);
    _prepareNextChord();
  }

  void toggleChordPatternVisibility() {
    isChordPatternVisible = !isChordPatternVisible;
    notifyListeners();
  }

  Future<void> openSystemSettings() async {
    final bool granted = await _chordRecognitionService.openSystemSettings();
    if (granted) {
      showOpenSettingsButton = false;
      statusMessage =
          'Microphone access granted. Press "Start Listening" to continue.';
    } else {
      statusMessage =
          'Microphone permission is still disabled. Please enable it to continue.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_chordRecognitionService.dispose());
    unawaited(_frequencySubscription.cancel());
    _attemptTimer?.cancel();
    super.dispose();
  }

  void _prepareNextChord({bool initial = false}) {
    if (chords.isEmpty) {
      throw StateError('No chords available for exercises.');
    }

    int nextIndex = _random.nextInt(chords.length);
    final int? previousIndex = _currentChordIndex;
    if (!initial && chords.length > 1 && previousIndex != null) {
      while (nextIndex == previousIndex) {
        nextIndex = _random.nextInt(chords.length);
      }
    }

    _currentChordIndex = nextIndex;
    currentChord = chords[nextIndex];

    _matchedStrings.clear();
    lastAttemptSuccessful = null;
    isPreparingNextChord = false;
    isChordPatternVisible = false;
    statusMessage =
        'Try strumming ${currentChord.name}. Press "Start Listening" when ready.';

    notifyListeners();
  }

  void _handleFrequency(double frequency) {
    if (!isListening) {
      return;
    }

    final int? matchedString =
        currentChord.matchFrequency(frequency, toleranceCents: 35);

    if (matchedString == null) {
      return;
    }

    final bool isNew = _matchedStrings.add(matchedString);
    if (!isNew) {
      return;
    }

    _restartAttemptTimer();
    statusMessage =
        'Heard the ${currentChord.stringLabel(matchedString)} string (${currentChord.notes[matchedString].noteName}).';

    if (_matchedStrings.length >= currentChord.notes.length) {
      _registerSuccessfulAttempt();
    }

    notifyListeners();
  }

  void _restartAttemptTimer() {
    _attemptTimer?.cancel();
    _attemptTimer = Timer(_attemptTimeout, _handleAttemptTimeout);
  }

  void _handleAttemptTimeout() {
    _attemptTimer = null;
    if (_matchedStrings.isEmpty) {
      return;
    }

    _matchedStrings.clear();
    if (isListening) {
      lastAttemptSuccessful = false;
      statusMessage =
          'Almost! Try strumming the full ${currentChord.name} chord again.';
      notifyListeners();
    }
  }

  Future<void> _registerSuccessfulAttempt() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = true;
    isPreparingNextChord = true;
    statusMessage =
        'Great job! That sounded like ${currentChord.name}. Preparing the next chord...';
    notifyListeners();

    Future<void>.delayed(_nextChordDelay, () {
      if (_disposed) {
        return;
      }
      _prepareNextChord();
    });
  }
}
