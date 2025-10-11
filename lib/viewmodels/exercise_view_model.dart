import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';
import '../utils/chord_match_tracker.dart';

class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel(this._chordRecognitionService, this.instrument)
      : chords = ChordLibrary.beginnerCourse(instrument) {
    _detectionSubscription =
        _chordRecognitionService.detectionStream.listen(_handleDetection);
    _prepareNextChord(initial: true);
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;
  final InstrumentType instrument;

  late final StreamSubscription<ChordDetectionFrame> _detectionSubscription;
  final Random _random = Random();

  static const Duration _attemptTimeout = Duration(milliseconds: 1500);
  static const Duration _nextChordDelay = Duration(seconds: 2);
  static const double _successRatio = 0.8;

  final ChordMatchTracker _matchTracker = ChordMatchTracker(
    matchWindow: _attemptTimeout,
    completionRatio: _successRatio,
  );

  late Chord currentChord;
  int? _currentChordIndex;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  bool showOpenSettingsButton = false;
  bool isPreparingNextChord = false;
  bool isChordPatternVisible = false;

  String statusMessage = 'Press "Start Listening" to begin.';

  String get instrumentLabel => instrument.displayName;

  Timer? _attemptTimer;
  bool _disposed = false;

  Future<void> startListening() async {
    if (isPreparingNextChord) {
      return;
    }

    lastAttemptSuccessful = null;
    statusMessage = 'Listening... Play the ${currentChord.name} chord.';
    showOpenSettingsButton = false;
    _matchTracker.reset();
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

    if (!silent &&
        lastAttemptSuccessful == null &&
        _matchTracker.hasMatches(currentChord.requiredStringIndexes)) {
      lastAttemptSuccessful = false;
      statusMessage =
          'Almost! Try strumming all strings of ${currentChord.name} cleanly.';
    }

    _matchTracker.reset();

    notifyListeners();
  }

  Future<void> retryCurrentChord() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = null;
    isPreparingNextChord = false;
    isChordPatternVisible = false;
    statusMessage =
        'Ready when you are. Press "Start Listening" and strum ${currentChord.name}.';
    _matchTracker.reset();
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
    unawaited(_detectionSubscription.cancel());
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

    _matchTracker.reset();
    lastAttemptSuccessful = null;
    isPreparingNextChord = false;
    isChordPatternVisible = false;
    statusMessage =
        'Try strumming ${currentChord.name}. Press "Start Listening" when ready.';

    notifyListeners();
  }

  void _handleDetection(ChordDetectionFrame frame) {
    if (!isListening) {
      return;
    }

    final Chord chord = currentChord;
    double peak = 0;
    for (final double value in frame.chroma) {
      if (value > peak) {
        peak = value;
      }
    }
    if (frame.energy < 0.2 || peak < 0.45) {
      return;
    }

    final int? matchedString = chord.matchPitchClasses(
      frame.chroma,
      fundamental: frame.fundamental,
    );

    if (matchedString == null) {
      return;
    }

    final bool isNew = _matchTracker.registerMatch(
      stringIndex: matchedString,
      requiredStrings: chord.requiredStringIndexes,
    );
    if (isNew) {
      _restartAttemptTimer();
      final int matchedCount =
          _matchTracker.matchedCount(chord.requiredStringIndexes);
      statusMessage =
          'Heard the ${chord.stringLabel(matchedString)} string (${chord.notes[matchedString].noteName}) — $matchedCount/${chord.requiredStringIndexes.length} strings detected.';
    }

    if (_matchTracker.isComplete(chord.requiredStringIndexes)) {
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
    if (!_matchTracker.hasMatches(currentChord.requiredStringIndexes)) {
      return;
    }

    _matchTracker.reset();
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
