import 'package:flutter/material.dart';
import '../pages/splash_screen.dart';
import '../pages/main_page.dart';
import '../pages/my_trip_page.dart';
import '../pages/nearby_page.dart';
import '../pages/scan_page.dart';
import '../pages/profile_page.dart';

void main() => runApp(const RafiqApp());

class RafiqApp extends StatelessWidget {
  const RafiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rafiq App',
      home: SplashScreen(),
      routes: {
        '/home': (context) => const MainPage(),
        '/nearby': (context) => const NearbyPage(),
        '/scan': (context) => const ScanPage(),
        '/mytrip': (context) => const MyTripPage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}
