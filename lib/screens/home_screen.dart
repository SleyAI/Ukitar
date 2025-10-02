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
    final String instrumentName = _selectedInstrument.displayName;
    final String instrumentNoun = _selectedInstrument.noun;
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
            const SizedBox(height: 24),
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
              'Learn your first $instrumentNoun chords with guided practice and real-time feedback.',
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
            Text(
              'Currently learning: $instrumentName',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: FilledButton(
                  onPressed: _showInstrumentPicker,
                  style: primaryButtonStyle,
                  child: const Text('Choose Instrument'),
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
                    backgroundColor: _youtubeRed,
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

  Future<void> _showInstrumentPicker() async {
    final ThemeData theme = Theme.of(context);
    final InstrumentType? result = await showDialog<InstrumentType>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Choose instrument'),
          children: <Widget>[
            for (final InstrumentType instrument in InstrumentType.values)
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(instrument),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      instrument == _selectedInstrument
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: instrument == _selectedInstrument
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            instrument.displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            instrument.description,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );

    if (!mounted || result == null || result == _selectedInstrument) {
      return;
    }

    setState(() {
      _selectedInstrument = result;
    });
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
      'images/ukulele.png',

      height: imageHeight,
      fit: BoxFit.contain,
    );
  }
}
