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
    final bool isWide = MediaQuery.of(context).size.width >= 900;
    final ButtonStyle primaryButtonStyle =
        (theme.filledButtonTheme.style ?? const ButtonStyle()).copyWith(
      minimumSize: const MaterialStatePropertyAll<Size>(Size.fromHeight(52)),
    );

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Color(0xFF090B10),
              Color(0xFF0F141D),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isWide ? 64 : 24,
              vertical: isWide ? 48 : 32,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(isWide ? 40 : 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.82),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x40121624),
                    blurRadius: 40,
                    offset: Offset(0, 20),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
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
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'by awiealissa',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Learn your first $instrumentNoun chords with guided practice and real-time feedback.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isWide) ...<Widget>[
                        const SizedBox(width: 32),
                        const _HomeIllustration(),
                      ],
                    ],
                  ),
                  if (!isWide) ...<Widget>[
                    const SizedBox(height: 32),
                    const _HomeIllustration(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 48),
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool compact = constraints.maxWidth < 680;
                return Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  children: <Widget>[
                    SizedBox(
                      width: compact ? constraints.maxWidth : (constraints.maxWidth - 20) / 2,
                      child: const _FeatureBullet(
                        icon: Icons.auto_graph,
                        title: 'Step-by-step course',
                        description: 'Unlock new chords only after mastering the basics.',
                      ),
                    ),
                    SizedBox(
                      width: compact ? constraints.maxWidth : (constraints.maxWidth - 20) / 2,
                      child: const _FeatureBullet(
                        icon: Icons.mic,
                        title: 'Microphone feedback',
                        description: 'Your instrument is the controller—strum to progress.',
                      ),
                    ),
                    SizedBox(
                      width: compact ? constraints.maxWidth : (constraints.maxWidth - 20) / 2,
                      child: const _FeatureBullet(
                        icon: Icons.auto_awesome,
                        title: 'Adaptive guidance',
                        description: 'Personalised tips keep you motivated and on tempo.',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 48),
            Container(
              padding: EdgeInsets.all(isWide ? 36 : 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.88),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Currently learning: $instrumentName',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Switch instruments or jump straight into a focused session.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: _showInstrumentPicker,
                    style: primaryButtonStyle,
                    child: const Text('Choose Instrument'),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
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
                  const SizedBox(height: 16),
                  FilledButton(
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _openYoutubeChannel(context),
                    icon: const Icon(Icons.play_circle_fill),
                    label: const Text('Watch awiealissa on YouTube'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: _youtubeRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
              ),
            ),
          ),
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
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.76),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
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
            ),
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
