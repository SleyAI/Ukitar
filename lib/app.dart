import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

class UkitarApp extends StatelessWidget {
  const UkitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ukitar',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF174455),
        useMaterial3: true,
        textTheme: Typography.englishLike2021.apply(
          fontSizeFactor: 1.0,
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
