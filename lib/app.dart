import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class UkitarApp extends StatelessWidget {
  const UkitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color background = Color(0xFF080A0F);
    const Color surface = Color(0xFF10131B);
    const Color surfaceVariant = Color(0xFF1B1F2A);
    const Color primary = Color(0xFF4FF0C9);

    final ColorScheme colorScheme = const ColorScheme(
      brightness: Brightness.dark,
      primary: primary,
      onPrimary: Color(0xFF00291F),
      primaryContainer: Color(0xFF1A7460),
      onPrimaryContainer: Color(0xFFCCFFF2),
      secondary: Color(0xFF8AA1C2),
      onSecondary: Color(0xFF0D1623),
      secondaryContainer: Color(0xFF1E2B3F),
      onSecondaryContainer: Color(0xFFD7E3FF),
      tertiary: Color(0xFFBAC2FF),
      onTertiary: Color(0xFF141A39),
      tertiaryContainer: Color(0xFF2C3260),
      onTertiaryContainer: Color(0xFFE1E4FF),
      error: Color(0xFFFFB4A9),
      onError: Color(0xFF680003),
      errorContainer: Color(0xFF930006),
      onErrorContainer: Color(0xFFFFDAD4),
      background: background,
      onBackground: Color(0xFFE5E7EB),
      surface: surface,
      onSurface: Color(0xFFF4F6FA),
      surfaceVariant: surfaceVariant,
      onSurfaceVariant: Color(0xFF9CA8C2),
      outline: Color(0xFF2E3543),
      outlineVariant: Color(0xFF394051),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: Color(0xFFE4E7EB),
      onInverseSurface: Color(0xFF11131A),
      inversePrimary: Color(0xFF0C8466),
    );

    return MaterialApp(
      title: 'Ukitar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: background,
        textTheme: Typography.englishLike2021.merge(
          const TextTheme(
            displaySmall: TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            headlineMedium: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
            titleLarge: TextStyle(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.25,
            ),
            bodyLarge: TextStyle(
              letterSpacing: 0.2,
              height: 1.5,
            ),
            bodyMedium: TextStyle(
              letterSpacing: 0.2,
              height: 1.5,
            ),
          ),
        ).apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: ButtonStyle(
            padding: const MaterialStatePropertyAll<EdgeInsets>(
              EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            textStyle: MaterialStatePropertyAll(
              Typography.englishLike2021.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titleTextStyle: Typography.englishLike2021.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
          ),
          contentTextStyle: Typography.englishLike2021.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        dividerColor: colorScheme.outline,
        cardTheme: CardTheme(
          color: surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
