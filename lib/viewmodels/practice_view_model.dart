import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/chord_library.dart';
import '../models/chord.dart';
import '../services/chord_recognition_service.dart';

class PracticeViewModel extends ChangeNotifier {
  PracticeViewModel(this._chordRecognitionService)
      : chords = ChordLibrary.beginnerCourse() {
    _frequencySub =
        _chordRecognitionService.frequencyStream.listen(_handleFrequency);
  }

  final ChordRecognitionService _chordRecognitionService;
  final List<Chord> chords;

  late final StreamSubscription<double> _frequencySub;

  int unlockedChords = 1;
  int currentChordIndex = 0;

  bool isListening = false;
  bool? lastAttemptSuccessful;
  String statusMessage = 'Ready to practise';

  double? latestFrequency;
  final Set<int> _matchedStrings = <int>{};

  Chord get currentChord => chords[currentChordIndex];

  int get activeStringCount => currentChord.notes.length;

  List<int> get matchedStrings => _matchedStrings.toList(growable: false);

  Future<void> startListening() async {
    lastAttemptSuccessful = null;
    statusMessage = 'Listening... strum your ${currentChord.name} chord';
    _matchedStrings.clear();
    notifyListeners();
    try {
      await _chordRecognitionService.startListening();
      isListening = true;
    } on MicrophonePermissionException {
      statusMessage = 'Microphone permission is required to listen.';
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
    statusMessage = 'Reset. Tap “Start Listening” when ready.';
    _matchedStrings.clear();
    latestFrequency = null;
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
    statusMessage = 'Ready for ${currentChord.name}';
    _matchedStrings.clear();
    latestFrequency = null;
    lastAttemptSuccessful = null;
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_chordRecognitionService.dispose());
    unawaited(_frequencySub.cancel());
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
          'Awesome! ${currentChord.name} is next. Tap “Start Listening”.';
    }
    _matchedStrings.clear();
    latestFrequency = null;
    notifyListeners();
  }
}
