import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';

class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel(this._chordRecognitionService, this.instrument)
      : chords = ChordLibrary.beginnerCourse(instrument) {
    _frequencySubscription =
        _chordRecognitionService.frequencyStream.listen(_handleFrequency);
    unawaited(resetAttempt());
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;
  final InstrumentType instrument;

  late final StreamSubscription<double> _frequencySubscription;


  int unlockedChords = 1;
  int currentChordIndex = 0;
  int? celebrationChordIndex;
  int celebrationEventId = 0;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  String statusMessage = 'Ready to practise';
  bool showOpenSettingsButton = false;


  double? latestFrequency;
  final Set<int> _matchedStrings = <int>{};
  Timer? _attemptTimer;

  static const Duration _attemptTimeout = Duration(milliseconds: 1500);
  static const int repetitionsRequired = 5;

  int completedRepetitions = 0;

  Chord get currentChord => chords[currentChordIndex];

  int get activeStringCount => currentChord.requiredStringIndexes.length;

  List<int> get matchedStrings => _matchedStrings.toList(growable: false);

  int get requiredRepetitions => repetitionsRequired;

  String get instrumentLabel => instrument.displayName;

  double get repetitionProgress =>
      completedRepetitions / repetitionsRequired;

  Future<void> startListening() async {
    lastAttemptSuccessful = null;
    statusMessage =
        'Listening... strum your ${currentChord.name} chord (${completedRepetitions + 1}/$repetitionsRequired)';
    _matchedStrings.clear();
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

    if (!silent && lastAttemptSuccessful == null && _matchedStrings.isNotEmpty) {
      lastAttemptSuccessful = false;
      statusMessage = 'Almost! Try strumming all strings together.';
    }

    notifyListeners();
  }

  Future<void> resetAttempt() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = null;
    statusMessage = 'Tap "Start Listening" when ready.';
    _matchedStrings.clear();
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
    _matchedStrings.clear();
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
    unawaited(_frequencySubscription.cancel());
    _attemptTimer?.cancel();
    super.dispose();
  }

  void _handleFrequency(double frequency) {
    latestFrequency = frequency;
    final int? matchedString = currentChord.matchFrequency(frequency);

    if (matchedString != null &&
        currentChord.isStringRequired(matchedString)) {
      final bool isNew = _matchedStrings.add(matchedString);
      if (isNew) {
        _restartAttemptTimer();
        statusMessage =
            'Heard ${currentChord.stringLabel(matchedString)} string (${currentChord.notes[matchedString].noteName})';
        if (_matchedStrings.length >= activeStringCount) {
          _registerSuccessfulStrum();
        }
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
      } else {
        statusMessage =
            'Amazing! You mastered every chord in the course.';
      }
    } else {
      statusMessage =
          'Great! ${chord.name}: $completedRepetitions/$repetitionsRequired clean strums.';
    }

    _matchedStrings.clear();
    latestFrequency = null;
    notifyListeners();
  }
}
