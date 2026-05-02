import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rafiq/theme/app_colors.dart';
import 'package:rafiq/pages/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  
  // Initialize
  @override
  void initState() {
    super.initState();
    
    // Wait 3 seconds then navigate to login page
    Timer(const Duration(seconds: 3), () {
      // Replace splash screen with login page (can't go back)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    });
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Image.asset('assets/rafiq_logo.jpg'),
      ),
    );
  }
}