import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:ukitar/models/chord.dart';
import 'package:ukitar/screens/practice_screen.dart';
import 'package:ukitar/services/chord_recognition_service.dart';
import 'package:ukitar/viewmodels/practice_view_model.dart';

void main() {
  group('PracticeScreen chord progression', () {
    testWidgets('locked chords remain unavailable until unlocked',
        (WidgetTester tester) async {
      final FakeChordRecognitionService service = FakeChordRecognitionService();
      final PracticeViewModel model = PracticeViewModel(service);

      addTearDown(() async => service.dispose());
      addTearDown(model.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PracticeViewModel>.value(
          value: model,
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(model.unlockedChords, 1);
      expect(model.currentChord.name, 'C Major');

      expect(find.text('C Major'), findsNWidgets(2));
      expect(find.text('A Minor'), findsOneWidget);
      expect(find.byIcon(Icons.lock), findsNWidgets(3));

      await tester.tap(find.text('F Major'));
      await tester.pumpAndSettle();

      expect(model.currentChord.name, 'C Major');
    });

    testWidgets('five clean strums unlock the next chord',
        (WidgetTester tester) async {
      final FakeChordRecognitionService service = FakeChordRecognitionService();
      final PracticeViewModel model = PracticeViewModel(service);

      addTearDown(() async => service.dispose());
      addTearDown(model.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<PracticeViewModel>.value(
          value: model,
          child: const MaterialApp(home: PracticeScreen()),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      await tester.runAsync(model.startListening);
      await tester.pump();

      for (int attempt = 0;
          attempt < model.requiredRepetitions;
          attempt++) {
        await _playChordOnce(tester, model, service);
      }

      await tester.pump();
      await tester.pumpAndSettle();

      expect(model.unlockedChords, 2);
      expect(model.currentChord.name, 'A Minor');
      expect(find.byIcon(Icons.lock), findsNWidgets(2));
      expect(find.text('A Minor'), findsNWidgets(2));
      expect(find.text('Clean strums: 0/${model.requiredRepetitions}'),
          findsOneWidget);
    });
  });
}

Future<void> _playChordOnce(
  WidgetTester tester,
  PracticeViewModel model,
  FakeChordRecognitionService service,
) async {
  for (final ChordNote note in model.currentChord.notes) {
    service.emitFrequency(note.frequency);
    await tester.pump();
  }
}

class FakeChordRecognitionService extends ChordRecognitionService {
  FakeChordRecognitionService();

  final StreamController<double> _controller =
      StreamController<double>.broadcast();
  bool _closed = false;
  Future<void>? _disposeFuture;

  @override
  Stream<double> get frequencyStream => _controller.stream;

  @override
  Future<void> startListening() async {}

  @override
  Future<void> stopListening() async {}

  @override
  Future<bool> openSystemSettings() async => true;

  @override
  Future<void> dispose() =>
      _disposeFuture ??= _disposeInternal();

  void emitFrequency(double frequency) {
    if (!_closed) {
      _controller.add(frequency);
    }
  }

  Future<void> _disposeInternal() async {
    await super.dispose();
    if (!_closed) {
      _closed = true;
      await _controller.close();
    }
  }
}
