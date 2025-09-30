import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/home_screen.dart';
import 'services/chord_recognition_service.dart';
import 'viewmodels/practice_view_model.dart';

class UkitarApp extends StatelessWidget {
  const UkitarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PracticeViewModel>(
      create: (_) => PracticeViewModel(ChordRecognitionService()),
      child: MaterialApp(
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
      ),
    );
  }
}
