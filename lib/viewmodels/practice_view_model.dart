import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../services/chord_recognition_service.dart';

class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel(this._chordRecognitionService)
      : chords = ChordLibrary.beginnerCourse() {
    _frequencySubscription =
        _chordRecognitionService.frequencyStream.listen(_handleFrequency);
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;

  late final StreamSubscription<double> _frequencySubscription;


  int unlockedChords = 1;
  int currentChordIndex = 0;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  String statusMessage = 'Ready to practise';
  bool showOpenSettingsButton = false;


  double? latestFrequency;
  final Set<int> _matchedStrings = <int>{};

  Chord get currentChord => chords[currentChordIndex];

  int get activeStringCount => currentChord.notes.length;

  List<int> get matchedStrings => _matchedStrings.toList(growable: false);

  Future<void> startListening() async {
    lastAttemptSuccessful = null;
    statusMessage = 'Listening... strum your ${currentChord.name} chord';
    _matchedStrings.clear();
    showOpenSettingsButton = false;
    notifyListeners();

    try {
      await _chordRecognitionService.startListening();
      isListening = true;
    } on MicrophonePermissionException catch (error) {
      showOpenSettingsButton = error.requiresSettings;
      statusMessage = error.requiresSettings
          ? 'Microphone access is disabled. Enable it in Settings to continue.'
          : 'Microphone permission is required to listen.';
    } catch (error) {
      statusMessage = 'Could not access the microphone: $error';
    }

    notifyListeners();
  }

  Future<void> stopListening({bool silent = false}) async {
    await _chordRecognitionService.stopListening();
    isListening = false;

    if (!silent && lastAttemptSuccessful == null && _matchedStrings.isNotEmpty) {
      lastAttemptSuccessful = false;
      statusMessage = 'Almost! Try strumming again.';
    }

    notifyListeners();
  }

  Future<void> resetAttempt() async {
    await stopListening(silent: true);
    lastAttemptSuccessful = null;
    statusMessage = 'Reset. Tap "Start Listening" when ready.';
    _matchedStrings.clear();
    latestFrequency = null;

    showOpenSettingsButton = false;
    notifyListeners();
  }

  Future<void> openSystemSettings() async {
    final bool opened = await _chordRecognitionService.openSystemSettings();
    if (!opened) {
      statusMessage =
          'Unable to open Settings. Please enable the microphone manually.';
      notifyListeners();
    }
  }

  void selectChord(int index) {
    if (index >= unlockedChords) {
      return;
    }

    if (isListening) {
      unawaited(stopListening(silent: true));
    }

    currentChordIndex = index;
    statusMessage = 'Ready for ${currentChord.name}';
    _matchedStrings.clear();
    latestFrequency = null;
    lastAttemptSuccessful = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_chordRecognitionService.dispose());
    unawaited(_frequencySubscription.cancel());
    super.dispose();
  }

  void _handleFrequency(double frequency) {
    latestFrequency = frequency;
    final int? matchedString = currentChord.matchFrequency(frequency);

    if (matchedString != null) {
      final bool isNew = _matchedStrings.add(matchedString);
      if (isNew) {
        statusMessage =
            'Heard ${currentChord.stringLabel(matchedString)} string (${currentChord.notes[matchedString].noteName})';
        if (_matchedStrings.length >= activeStringCount) {
          _completeChord();
        }
      }
    }

    notifyListeners();
  }

  Future<void> _completeChord() async {
    lastAttemptSuccessful = true;
    statusMessage = 'Beautiful! ${currentChord.name} unlocked.';
    await stopListening(silent: true);

    if (unlockedChords < chords.length) {
      unlockedChords++;
      currentChordIndex = unlockedChords - 1;
      statusMessage =
          'Awesome! ${currentChord.name} is next. Tap "Start Listening".';
    }


    _matchedStrings.clear();
    latestFrequency = null;
    notifyListeners();
  }
}
