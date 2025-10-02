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
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFB),
        useMaterial3: true,
        textTheme: Typography.englishLike2021.apply(fontSizeFactor: 1.0),
      ),
      home: const HomeScreen(),
    );
  }
}
