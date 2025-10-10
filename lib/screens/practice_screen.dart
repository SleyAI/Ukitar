import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/instrument.dart';
import '../services/chord_recognition_service.dart';
import '../services/practice_progress_repository.dart';
import '../utils/url_opener.dart';
import '../viewmodels/practice_view_model.dart';
import '../widgets/chord_diagram.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key, required this.instrument});

  final InstrumentType instrument;

  @override
  Widget build(BuildContext context) {
    final PracticeViewModel? existingModel = _maybeReadExistingModel(context);
    if (existingModel != null) {
      return const _PracticeView();
    }

    final PracticeProgressRepository progressRepository =
        _resolveProgressRepository(context);

    return ChangeNotifierProvider<PracticeViewModel>(
      create: (_) => PracticeViewModel(
        ChordRecognitionService(),
        instrument,
        progressRepository: progressRepository,
      ),
      child: const _PracticeView(),
    );
  }

  PracticeViewModel? _maybeReadExistingModel(BuildContext context) {
    try {
      return Provider.of<PracticeViewModel>(context, listen: false);
    } on ProviderNotFoundException {
      return null;
    }
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

class _PracticeView extends StatelessWidget {
  const _PracticeView();

  @override
  Widget build(BuildContext context) {
    return Consumer<PracticeViewModel>(
      builder: (BuildContext context, PracticeViewModel model, _) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme colorScheme = theme.colorScheme;
        final TextTheme textTheme = theme.textTheme;
        final Color primaryTextColor = colorScheme.onSurface;
        final Color secondaryTextColor = colorScheme.onSurfaceVariant;

        return Scaffold(
          appBar: AppBar(
            title: Text('Practice • ${model.instrumentLabel}'),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        'Beginner progression',
                        style: textTheme.titleMedium?.copyWith(
                          color: primaryTextColor,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(model.instrumentLabel),
                      backgroundColor: colorScheme.primaryContainer,
                      labelStyle: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: model.chords.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (BuildContext context, int index) {
                      final bool isUnlocked = index < model.unlockedChords;
                      return _ChordChip(
                        chordName: model.chords[index].name,
                        unlocked: isUnlocked,
                        selected: index == model.currentChordIndex,
                        celebrationEventId: index == model.celebrationChordIndex
                            ? model.celebrationEventId
                            : null,
                        onTap: () => model.selectChord(index),
                      );
                    },
                  ),
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
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          model.currentChord.description,
                          style: textTheme.bodyMedium?.copyWith(
                            color: secondaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: ChordDiagram(chord: model.currentChord),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tips',
                          style: textTheme.titleMedium?.copyWith(
                            color: primaryTextColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...model.currentChord.tips.map(
                          (String tip) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '•  ',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: secondaryTextColor,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: textTheme.bodyMedium?.copyWith(
                                      height: 1.4,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                '•  ',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: secondaryTextColor,
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        'Do you need additional help? Check out the explanation by awiealissa',
                                        style: textTheme.bodyMedium?.copyWith(
                                          height: 1.4,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Watch on YouTube',
                                      onPressed: () {
                                        unawaited(
                                          openExternalUrl(
                                            'https://www.youtube.com/watch?v=MLuYBcEVlYs',
                                          ),
                                        );
                                      },
                                      icon: Icon(
                                        Icons.ondemand_video,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
          ),
        );
      },
    );
  }
}

class _ChordChip extends StatefulWidget {
  const _ChordChip({
    required this.chordName,
    required this.unlocked,
    required this.selected,
    required this.onTap,
    this.celebrationEventId,
  });

  final String chordName;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;
  final int? celebrationEventId;

  @override
  State<_ChordChip> createState() => _ChordChipState();
}

class _ChordChipState extends State<_ChordChip>
    with TickerProviderStateMixin {
  late final AnimationController _celebrationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        _celebrationController.stop();
        _celebrationController.value = 0;
        if (mounted) {
          setState(() {
            _showCelebration = false;
          });
        }
      }
    });

  bool _showCelebration = false;
  late final List<_ConfettiParticle> _particles = _ConfettiParticle.generate();

  @override
  void didUpdateWidget(covariant _ChordChip oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.celebrationEventId != null &&
        widget.celebrationEventId != oldWidget.celebrationEventId) {
      _triggerCelebration();
    }

  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  void _triggerCelebration() {
    setState(() {
      _showCelebration = true;
    });
    _celebrationController
      ..stop()
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLocked = !widget.unlocked;

    final Color backgroundColor = widget.selected
        ? theme.colorScheme.primary
        : widget.unlocked
            ? theme.colorScheme.surfaceVariant
            : theme.colorScheme.surfaceVariant.withOpacity(0.6);

    final Color foregroundColor = widget.selected
        ? theme.colorScheme.onPrimary
        : widget.unlocked
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant;

    final Widget chipContent = GestureDetector(
      onTap: widget.unlocked ? widget.onTap : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: backgroundColor,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    widget.unlocked ? Icons.check_circle : Icons.music_note,
                    size: 18,
                    color: widget.selected
                        ? theme.colorScheme.onPrimary
                        : widget.unlocked
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.chordName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (isLocked)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            theme.colorScheme.surfaceVariant
                                .withOpacity(0.65),
                            theme.colorScheme.surfaceVariant
                                .withOpacity(0.45),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (isLocked)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.lock_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    if (!_showCelebration) {
      return chipContent;
    }

    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (BuildContext context, Widget? child) {
        final double progress = _celebrationController.value;
        final double glowStrength = (1 - Curves.easeOutQuad.transform(progress))
            .clamp(0, 1)
            .toDouble();
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: theme.colorScheme.primary
                    .withOpacity(0.3 * glowStrength),
                blurRadius: 24 * glowStrength,
                spreadRadius: 4 * glowStrength,
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              child!,
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ConfettiPainter(
                      progress: progress,
                      particles: _particles,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: chipContent,
    );
  }
}

class _ConfettiParticle {
  const _ConfettiParticle({
    required this.start,
    required this.velocity,
    required this.size,
    required this.rotation,
    required this.colorShift,
  });

  final Offset start;
  final Offset velocity;
  final double size;
  final double rotation;
  final double colorShift;

  static List<_ConfettiParticle> generate() {
    final List<_ConfettiParticle> particles = <_ConfettiParticle>[];
    for (int index = 0; index < 10; index++) {
      final double dx = (index.isEven ? -1.0 : 1.0) * (6 + index).toDouble();
      final double dy = (12 + index * 3).toDouble();

      final double size = 4 + (index % 3) * 1.5;
      final double rotation = (index.isEven ? 1 : -1) * 1.2;
      final double colorShift = index / 12;
      particles.add(
        _ConfettiParticle(
          start: Offset(0, -4 * index.toDouble()),
          velocity: Offset(dx, dy),
          size: size,
          rotation: rotation,
          colorShift: colorShift,
        ),
      );
    }
    return particles;
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.progress,
    required this.particles,
    required this.color,
  });

  final double progress;
  final List<_ConfettiParticle> particles;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint();
    for (final _ConfettiParticle particle in particles) {
      final double t = Curves.easeOut.transform(progress);
      final Offset position = Offset(
        size.width / 2 + particle.start.dx + particle.velocity.dx * t,
        size.height / 2 + particle.start.dy + particle.velocity.dy * t,
      );
      final double opacity = (1 - progress).clamp(0.0, 1.0);
      paint.color = Color.lerp(
            color,
            color.withOpacity(0.2),
            (particle.colorShift + progress).clamp(0.0, 1.0),
          )!
          .withOpacity(opacity);

      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotation * t);
      final Rect rect = Rect.fromCenter(
        center: Offset.zero,
        width: particle.size,
        height: particle.size * 0.6,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.particles != particles ||
        oldDelegate.color != color;
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

    final double progress =
        model.repetitionProgress.clamp(0.0, 1.0).toDouble();

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

            const SizedBox(height: 12),
            Text(
              'Clean strums: ${model.completedRepetitions}/${model.requiredRepetitions}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: foregroundColor.withOpacity(0.2),
                color: colors.primary,
              ),
            ),

            if (model.showOpenSettingsButton) ...<Widget>[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(model.openSystemSettings()),
                icon: const Icon(Icons.mic),
                label: const Text('Grant Microphone Access'),
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
