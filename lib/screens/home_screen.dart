import 'package:flutter/material.dart';
import 'package:ukitar/utils/url_opener.dart';

import '../models/instrument.dart';
import 'exercise_screen.dart';
import 'practice_screen.dart';

const Color _youtubeRed = Color(0xFFFF0000);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InstrumentType _selectedInstrument = InstrumentType.ukulele;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ButtonStyle primaryButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(48),
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 32),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Ukitar',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'by awiealissa',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const _HomeIllustration(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Learn your first chords with guided practice and real-time feedback.',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 75),
            _FeatureBullet(
              icon: Icons.auto_graph,
              title: 'Step-by-step course',
              description: 'Unlock new chords only after mastering the basics.',
            ),
            const SizedBox(height: 24),
            _FeatureBullet(
              icon: Icons.mic,
              title: 'Microphone feedback',
              description: 'Your instrument is the controller—strum to progress.',
            ),
            const Spacer(),
            _InstrumentSelection(
              selectedInstrument: _selectedInstrument,
              onInstrumentSelected: _onInstrumentSelected,
            ),
            const SizedBox(height: 24),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (BuildContext context) => PracticeScreen(
                        instrument: _selectedInstrument,
                      ),
                    ));
                  },
                  style: primaryButtonStyle,
                  child: const Text('Start Practice'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute<void>(
                      builder: (BuildContext context) => ExerciseScreen(
                        instrument: _selectedInstrument,
                      ),
                    ));
                  },
                  style: primaryButtonStyle,
                  child: const Text('Start Exercise'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FilledButton.icon(
                  onPressed: () => _openYoutubeChannel(context),
                  icon: const Icon(Icons.play_circle_fill),
                  label: const Text('Watch awiealissa on YouTube'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color.fromARGB(180, 255, 0, 0),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    textStyle: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _onInstrumentSelected(InstrumentType instrument) {
    if (_selectedInstrument == instrument) {
      return;
    }

    setState(() {
      _selectedInstrument = instrument;
    });
  }
}

class _InstrumentSelection extends StatelessWidget {
  const _InstrumentSelection({
    required this.selectedInstrument,
    required this.onInstrumentSelected,
  });

  final InstrumentType selectedInstrument;
  final ValueChanged<InstrumentType> onInstrumentSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            'Choose your instrument',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            children: <Widget>[
              for (final InstrumentType instrument in InstrumentType.values)
                _InstrumentChip(
                  instrument: instrument,
                  isSelected: instrument == selectedInstrument,
                  onSelected: onInstrumentSelected,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InstrumentChip extends StatelessWidget {
  const _InstrumentChip({
    required this.instrument,
    required this.isSelected,
    required this.onSelected,
  });

  final InstrumentType instrument;
  final bool isSelected;
  final ValueChanged<InstrumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primaryColor = theme.colorScheme.primary;
    final TextStyle? labelStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: isSelected ? primaryColor : theme.colorScheme.onSurface,
    );
    String assetPath;
    switch (instrument) {
      case InstrumentType.ukulele:
        assetPath = 'assets/icons/ukulele.png';
        break;
      case InstrumentType.guitar:
        assetPath = 'assets/icons/guitar.png';
        break;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => onSelected(instrument),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.12)
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Semantics(
              label: instrument.displayName,
              selected: isSelected,
              child: Image.asset(
                assetPath,
                width: 64,
                height: 64,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              instrument.displayName,
              style: labelStyle,
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _openYoutubeChannel(BuildContext context) async {
  const String url = 'https://www.youtube.com/@awiealissa';
  final bool opened = await openExternalUrl(url);
  if (!opened) {
    final ScaffoldMessengerState? messenger =
        ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Unable to open the YouTube channel right now.'),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeIllustration extends StatelessWidget {
  const _HomeIllustration();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double titleHeight = theme.textTheme.displaySmall?.fontSize ?? 0;
    final double subtitleHeight = theme.textTheme.titleMedium?.fontSize ?? 0;
    const double spacing = 8;
    final double computedHeight = titleHeight + subtitleHeight + spacing;
    final double imageHeight = computedHeight > 0 ? computedHeight : 120;

    return Image.asset(
      'assets/images/alissa.png',

      height: imageHeight,
      fit: BoxFit.contain,
    );
  }
}
