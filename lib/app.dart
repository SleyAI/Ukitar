import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/practice_progress_repository.dart';

class UkitarApp extends StatelessWidget {
  const UkitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<PracticeProgressRepository>(
      create: (_) => SharedPreferencesPracticeProgressRepository(),
      child: MaterialApp(
        title: 'Ukitar',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0047AB),
            brightness: Brightness.light,
          ),
          scaffoldBackgroundColor: Colors.white,
          useMaterial3: true,
          textTheme: Typography.englishLike2021.apply(
            fontSizeFactor: 1.0,
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
