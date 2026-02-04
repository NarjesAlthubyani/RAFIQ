import 'package:flutter/material.dart';
import 'pages/splash_screen.dart';
import 'theme/app_colors.dart';

void main() => runApp(const RafiqApp());

class RafiqApp extends StatelessWidget {
  const RafiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rafiq App',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const SplashScreen(),
    );
  }
}
