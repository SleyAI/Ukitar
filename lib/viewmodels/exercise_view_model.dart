import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';
import '../services/practice_progress_repository.dart';
import '../utils/chord_match_tracker.dart';
import '../utils/string_detection.dart';
import '../utils/ukulele_prediction_confidence.dart';

class ExerciseViewModel extends ChangeNotifier {
  ExerciseViewModel(
    this._chordRecognitionService,
    this.instrument, {
    PracticeProgressRepository? progressRepository,
  })  : _progressRepository =
            progressRepository ?? SharedPreferencesPracticeProgressRepository(),
        _allChords = ChordLibrary.beginnerCourse(instrument) {
    if (_allChords.isEmpty) {
      throw StateError('No chords available for exercises.');
    }

    _availableChords = <Chord>[_allChords.first];
    currentChord = _availableChords.first;
    _detectionSubscription =
        _chordRecognitionService.detectionStream.listen(_handleDetection);
    unawaited(_initialize());
  }

  final ChordRecognitionService _chordRecognitionService;
  final PracticeProgressRepository _progressRepository;
  final List<Chord> _allChords;
  List<Chord> _availableChords = <Chord>[];
  final InstrumentType instrument;

  late final StreamSubscription<ChordDetectionFrame> _detectionSubscription;
  final Random _random = Random();

  static const Duration _attemptTimeout = Duration(milliseconds: 1500);
  static const Duration _nextChordDelay = Duration(seconds: 2);
  static const double _successRatio = 0.8;
  static const Duration _ukuleleRecognitionCooldown =
      Duration(milliseconds: 750);
  static const double _ukuleleConfidenceThreshold = 0.55;
  static const double _ukuleleMinimumEnergy = 0.2;

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
  DateTime? _lastUkuleleChordMatch;

  Future<void> _initialize() async {
    final int unlockedCount = _normalizeUnlocked(
      await _progressRepository.loadUnlockedChords(instrument),
    );
    _updateAvailableChords(unlockedCount);
    _prepareNextChord(initial: true);
  }

  int _normalizeUnlocked(int? unlocked) {
    final int value = unlocked ?? 1;
    if (value < 1) {
      return 1;
    }
    if (value > _allChords.length) {
      return _allChords.length;
    }
    return value;
  }

  void _updateAvailableChords(int unlockedCount) {
    _availableChords =
        _allChords.take(unlockedCount).toList(growable: false);
  }

  Future<void> startListening() async {
    if (isPreparingNextChord) {
      return;
    }

    lastAttemptSuccessful = null;
    statusMessage = 'Listening... Play the ${currentChord.name} chord.';
    showOpenSettingsButton = false;
    _matchTracker.reset();
    _lastUkuleleChordMatch = null;
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
    _lastUkuleleChordMatch = null;

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
    _lastUkuleleChordMatch = null;
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
    if (_availableChords.isEmpty) {
      throw StateError('No chords available for exercises.');
    }

    int nextIndex = _random.nextInt(_availableChords.length);
    final int? previousIndex = _currentChordIndex;
    if (!initial && _availableChords.length > 1 && previousIndex != null) {
      while (nextIndex == previousIndex) {
        nextIndex = _random.nextInt(_availableChords.length);
      }
    }

    _currentChordIndex = nextIndex;
    currentChord = _availableChords[nextIndex];

    _matchTracker.reset();
    lastAttemptSuccessful = null;
    isPreparingNextChord = false;
    isChordPatternVisible = false;
    statusMessage =
        'Try strumming ${currentChord.name}. Press "Start Listening" when ready.';
    _lastUkuleleChordMatch = null;

    notifyListeners();
  }

  void _handleDetection(ChordDetectionFrame frame) {
    if (!isListening) {
      return;
    }

    final Chord chord = currentChord;
    if (instrument == InstrumentType.ukulele) {
      _handleUkuleleChordDetection(chord, frame);
      return;
    }
    double chromaPeak = 0;
    for (final double value in frame.chroma) {
      if (value > chromaPeak) {
        chromaPeak = value;
      }
    }
    if (frame.energy < 0.2 || chromaPeak < 0.45) {
      return;
    }

    final Set<int> matchedStrings = identifyChordStringMatches(chord, frame);

    if (matchedStrings.isEmpty) {
      notifyListeners();
      return;
    }

    bool registeredNewMatch = false;
    int? highlightedString;

    for (final int stringIndex in matchedStrings) {
      final bool isNew = _matchTracker.registerMatch(
        stringIndex: stringIndex,
        requiredStrings: chord.requiredStringIndexes,
      );
      if (isNew) {
        registeredNewMatch = true;
        highlightedString = stringIndex;
      }
    }

    if (registeredNewMatch && highlightedString != null) {
      _restartAttemptTimer();
      final int matchedCount =
          _matchTracker.matchedCount(chord.requiredStringIndexes);
      statusMessage =
          'Heard the ${chord.stringLabel(highlightedString)} string (${chord.notes[highlightedString].noteName}) — $matchedCount/${chord.requiredStringIndexes.length} strings detected.';
    }

    if (_matchTracker.isComplete(chord.requiredStringIndexes)) {
      _registerSuccessfulAttempt();
    }

    notifyListeners();
  }

  void _handleUkuleleChordDetection(Chord chord, ChordDetectionFrame frame) {
    final String? predictedChordId = frame.predictedChordId;
    if (frame.energy < _ukuleleMinimumEnergy ||
        predictedChordId == null ||
        predictedChordId != chord.id ||
        !isConfidentUkulelePrediction(
          frame,
          highConfidenceThreshold: _ukuleleConfidenceThreshold,
        )) {
      return;
    }

    final DateTime now = DateTime.now();
    if (_lastUkuleleChordMatch != null &&
        now.difference(_lastUkuleleChordMatch!) < _ukuleleRecognitionCooldown) {
      return;
    }
    _lastUkuleleChordMatch = now;

    _attemptTimer?.cancel();
    _attemptTimer = null;
    _matchTracker.reset();

    unawaited(_registerSuccessfulAttempt());
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
