import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/practice_view_model.dart';
import '../widgets/chord_diagram.dart';

class PracticeScreen extends StatefulWidget {
  const PracticeScreen({super.key});

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final PracticeViewModel model = context.read<PracticeViewModel>();
      unawaited(model.resetAttempt());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice'),
      ),
      body: Consumer<PracticeViewModel>(
        builder: (BuildContext context, PracticeViewModel model, _) {
          final ColorScheme colorScheme = Theme.of(context).colorScheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Beginner progression',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    for (int index = 0; index < model.chords.length; index++)
                      _ChordChip(
                        chordName: model.chords[index].name,
                        unlocked: index < model.unlockedChords,
                        selected: index == model.currentChordIndex,
                        onTap: () => model.selectChord(index),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  color: colorScheme.surfaceVariant,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          model.currentChord.name,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          model.currentChord.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ChordDiagram(chord: model.currentChord),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tips',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        ...model.currentChord.tips.map(
                          (String tip) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text('•  '),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _FeedbackCard(model: model),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ChordChip extends StatelessWidget {
  const _ChordChip({
    required this.chordName,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final String chordName;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: unlocked ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? theme.colorScheme.primary
              : unlocked
                  ? theme.colorScheme.surfaceVariant
                  : theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              unlocked ? Icons.check_circle : Icons.lock,
              size: 16,
              color: selected
                  ? theme.colorScheme.onPrimary
                  : unlocked
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              chordName,
              style: theme.textTheme.bodyMedium?.copyWith(
              color: selected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.model});

  final PracticeViewModel model;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    Color statusColor = colors.surfaceVariant;
    Color foregroundColor = colors.onSurface;
    IconData statusIcon = Icons.hearing;

    if (model.lastAttemptSuccessful == true) {
      statusColor = colors.secondaryContainer;
      foregroundColor = colors.onSecondaryContainer;
      statusIcon = Icons.emoji_events;
    } else if (model.lastAttemptSuccessful == false) {
      statusColor = colors.errorContainer;
      foregroundColor = colors.onErrorContainer;
      statusIcon = Icons.refresh;
    } else if (model.isListening) {
      statusColor = colors.primaryContainer;
      foregroundColor = colors.onPrimaryContainer;
      statusIcon = Icons.graphic_eq;
    }

    return Card(
      color: statusColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(statusIcon, color: foregroundColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    model.statusMessage,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: foregroundColor,
                    ),
                  ),
                ),
              ],
            ),

            if (model.showOpenSettingsButton) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(model.openSystemSettings()),
                icon: const Icon(Icons.settings),
                label: const Text('Open Settings'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: foregroundColor,
                  side: BorderSide(color: foregroundColor.withOpacity(0.4)),
                ),
              ),
            ],

            const SizedBox(height: 16),
            if (model.latestFrequency != null)
              Text(
                'Latest frequency: ${model.latestFrequency!.toStringAsFixed(1)} Hz',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: foregroundColor,
                ),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: <Widget>[
                for (final int stringIndex in model.matchedStrings)
                  Chip(
                    avatar: const Icon(Icons.check, size: 16),
                    backgroundColor: colors.primary.withOpacity(0.12),
                    label: Text(
                      '${model.currentChord.stringLabel(stringIndex)} string ok',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      if (model.isListening) {
                        unawaited(model.stopListening());
                      } else {
                        unawaited(model.startListening());
                      }
                    },
                    icon: Icon(model.isListening ? Icons.stop : Icons.play_arrow),
                    label: Text(model.isListening ? 'Stop Listening' : 'Start Listening'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => unawaited(model.resetAttempt()),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
