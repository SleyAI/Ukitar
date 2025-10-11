import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';
import '../services/practice_progress_repository.dart';
import '../utils/chord_match_tracker.dart';

class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel(
    this._chordRecognitionService,
    this.instrument, {
    PracticeProgressRepository? progressRepository,
  })  : chords = ChordLibrary.beginnerCourse(instrument),
        _progressRepository =
            progressRepository ?? SharedPreferencesPracticeProgressRepository() {
    _detectionSubscription =
        _chordRecognitionService.detectionStream.listen(_handleDetection);
    _initializationFuture = _initialize();
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;
  final InstrumentType instrument;
  final PracticeProgressRepository _progressRepository;
  late final Future<void> _initializationFuture;

  Future<void> get initialization => _initializationFuture;

  late final StreamSubscription<ChordDetectionFrame> _detectionSubscription;


  int unlockedChords = 1;
  int currentChordIndex = 0;
  int? celebrationChordIndex;
  int celebrationEventId = 0;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  String statusMessage = 'Ready to practise';
  bool showOpenSettingsButton = false;


  double? latestFrequency;
  Timer? _attemptTimer;

  static const Duration _attemptTimeout = Duration(milliseconds: 1500);
  static const int repetitionsRequired = 5;
  static const double _successRatio = 0.8;

  final ChordMatchTracker _matchTracker = ChordMatchTracker(
    matchWindow: _attemptTimeout,
    completionRatio: _successRatio,
  );

  int completedRepetitions = 0;

  Chord get currentChord => chords[currentChordIndex];

  int get activeStringCount => currentChord.requiredStringIndexes.length;

  List<int> get matchedStrings =>
      _matchTracker.matchedStrings(currentChord.requiredStringIndexes);

  int get requiredRepetitions => repetitionsRequired;

  String get instrumentLabel => instrument.displayName;

  double get repetitionProgress =>
      completedRepetitions / repetitionsRequired;

  Future<void> startListening() async {
    lastAttemptSuccessful = null;
    statusMessage =
        'Listening... strum your ${currentChord.name} chord (${completedRepetitions + 1}/$repetitionsRequired)';
    _matchTracker.reset();
    showOpenSettingsButton = false;
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

    final Set<int> requiredStrings = currentChord.requiredStringIndexes;
    if (!silent &&
        lastAttemptSuccessful == null &&
        _matchTracker.hasMatches(requiredStrings)) {
      lastAttemptSuccessful = false;
      statusMessage = 'Almost! Try strumming all strings together.';
    }

    _matchTracker.reset();

    notifyListeners();
  }

  Future<void> _initialize() async {
    await resetAttempt();
    final int? savedUnlocked =
        await _progressRepository.loadUnlockedChords(instrument);
    if (savedUnlocked != null) {
      final int normalized = _normalizeUnlocked(savedUnlocked);
      unlockedChords = normalized;
      currentChordIndex = normalized - 1;
      notifyListeners();
    }
  }

  int _normalizeUnlocked(int unlocked) {
    if (unlocked < 1) {
      return 1;
    }
    if (unlocked > chords.length) {
      return chords.length;
    }
    return unlocked;
  }

  Future<void> resetAttempt() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = null;
    statusMessage = 'Tap "Start Listening" when ready.';
    _matchTracker.reset();
    latestFrequency = null;
    completedRepetitions = 0;
    celebrationChordIndex = null;
    _attemptTimer?.cancel();
    _attemptTimer = null;

    showOpenSettingsButton = false;
    notifyListeners();
  }

  Future<void> openSystemSettings() async {
    final bool granted = await _chordRecognitionService.openSystemSettings();
    if (granted) {
      showOpenSettingsButton = false;
      statusMessage = 'Microphone access granted. Tap "Start Listening" to continue.';
    } else {
      statusMessage =
          'Microphone permission is still disabled. Please enable it to continue.';
    }
    notifyListeners();
  }

  void selectChord(int index) {
    if (index >= unlockedChords) {
      return;
    }

    if (isListening) {
      unawaited(stopListening(silent: true));
    }

    currentChordIndex = index;
    celebrationChordIndex = null;
    statusMessage =
        'Ready for ${currentChord.name}. Strum it $repetitionsRequired times to unlock the next chord.';
    _matchTracker.reset();
    latestFrequency = null;
    lastAttemptSuccessful = null;
    completedRepetitions = 0;
    _attemptTimer?.cancel();
    _attemptTimer = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_chordRecognitionService.dispose());
    unawaited(_detectionSubscription.cancel());
    _attemptTimer?.cancel();
    super.dispose();
  }

  void _handleDetection(ChordDetectionFrame frame) {
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

    latestFrequency = frame.fundamental;

    if (matchedString != null) {
      final bool isNew = _matchTracker.registerMatch(
        stringIndex: matchedString,
        requiredStrings: chord.requiredStringIndexes,
      );
      if (isNew) {
        _restartAttemptTimer();
        final int matchedCount =
            _matchTracker.matchedCount(chord.requiredStringIndexes);
        statusMessage =
            'Heard ${chord.stringLabel(matchedString)} string (${chord.notes[matchedString].noteName}) — $matchedCount/${chord.requiredStringIndexes.length} strings detected.';
      }

      if (_matchTracker.isComplete(chord.requiredStringIndexes)) {
        _registerSuccessfulStrum();
      }
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

  void _registerSuccessfulStrum() {
    _attemptTimer?.cancel();
    _attemptTimer = null;

    final Chord chord = currentChord;
    celebrationChordIndex = null;
    completedRepetitions++;
    lastAttemptSuccessful = true;

    if (completedRepetitions >= repetitionsRequired) {
      final bool hasMoreChords = unlockedChords < chords.length;
      unawaited(stopListening(silent: true));

      if (hasMoreChords) {
        unlockedChords++;
        currentChordIndex = unlockedChords - 1;
        celebrationChordIndex = currentChordIndex;
        celebrationEventId++;
        final String nextChordName = currentChord.name;
        completedRepetitions = 0;
        statusMessage =
            'Fantastic! You nailed $repetitionsRequired clean strums of ${chord.name}. Next up: $nextChordName. Tap "Start Listening" when ready.';
        unawaited(_progressRepository.saveUnlockedChords(
            instrument, unlockedChords));
      } else {
        statusMessage =
            'Amazing! You mastered every chord in the course.';
      }
    } else {
      statusMessage =
          'Great! ${chord.name}: $completedRepetitions/$repetitionsRequired clean strums.';
    }

    _matchTracker.reset();
    latestFrequency = null;
    notifyListeners();
  }
}
