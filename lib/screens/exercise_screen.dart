import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';
import '../services/practice_progress_repository.dart';
import '../viewmodels/exercise_view_model.dart';
import '../widgets/chord_diagram.dart';

class ExerciseScreen extends StatelessWidget {
  const ExerciseScreen({super.key, required this.instrument});

  final InstrumentType instrument;

  @override
  Widget build(BuildContext context) {
    final PracticeProgressRepository progressRepository =
        _resolveProgressRepository(context);

    return ChangeNotifierProvider<ExerciseViewModel>(
      create: (_) => ExerciseViewModel(
        ChordRecognitionService(instrument: instrument),
        instrument,
        progressRepository: progressRepository,
      ),
      child: const _ExerciseView(),
    );
  }

  PracticeProgressRepository _resolveProgressRepository(
      BuildContext context) {
    try {
      return Provider.of<PracticeProgressRepository>(context, listen: false);
    } on ProviderNotFoundException {
      return SharedPreferencesPracticeProgressRepository();
    }
  }
}

class _ExerciseView extends StatelessWidget {
  const _ExerciseView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Exercises • ${context.watch<ExerciseViewModel>().instrumentLabel}'),
      ),
      body: Consumer<ExerciseViewModel>(
        builder: (BuildContext context, ExerciseViewModel model, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Play along with the microphone to get immediate feedback.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                _ChordCard(model: model),
                const SizedBox(height: 24),
                _StatusBanner(model: model),
                const SizedBox(height: 24),
                if (model.showOpenSettingsButton)
                  FilledButton.icon(
                    onPressed: model.openSystemSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Open Settings'),
                  )
                else
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          onPressed: model.isListening
                              ? model.stopListening
                              : model.startListening,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: Text(model.isListening
                              ? 'Stop Listening'
                              : 'Start Listening'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: model.isPreparingNextChord
                              ? null
                              : model.skipToNextChord,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                          ),
                          child: const Text('Next Chord'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                if (!model.showOpenSettingsButton)
                  TextButton.icon(
                    onPressed: model.isPreparingNextChord
                        ? null
                        : model.retryCurrentChord,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChordCard extends StatelessWidget {
  const _ChordCard({required this.model});

  final ExerciseViewModel model;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceVariant,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              model.currentChord.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Strum this chord cleanly when listening starts to score a success.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            if (model.isChordPatternVisible) ...<Widget>[
              Center(child: ChordDiagram(chord: model.currentChord)),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: model.toggleChordPatternVisibility,
                  icon: const Icon(Icons.visibility_off),
                  label: const Text('Hide Chord Pattern'),
                ),
              ),
            ] else
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: model.toggleChordPatternVisibility,
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Chord Pattern'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.model});

  final ExerciseViewModel model;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    final IconData icon;
    final Color backgroundColor;
    final Color foregroundColor;

    if (model.lastAttemptSuccessful == true) {
      icon = Icons.check_circle;
      backgroundColor = colorScheme.primaryContainer;
      foregroundColor = colorScheme.onPrimaryContainer;
    } else if (model.lastAttemptSuccessful == false) {
      icon = Icons.error_outline;
      backgroundColor = colorScheme.errorContainer;
      foregroundColor = colorScheme.onErrorContainer;
    } else if (model.isListening) {
      icon = Icons.hearing;
      backgroundColor = colorScheme.secondaryContainer;
      foregroundColor = colorScheme.onSecondaryContainer;
    } else {
      icon = Icons.music_note;
      backgroundColor = colorScheme.surfaceVariant;
      foregroundColor = colorScheme.onSurfaceVariant;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: foregroundColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              model.statusMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: foregroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
