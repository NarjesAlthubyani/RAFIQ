import 'package:flutter/material.dart';
import '../pages/splash_screen.dart';
import '../pages/main_page.dart';
import '../pages/my_trip_page.dart';
import '../pages/nearby_page.dart';
import '../pages/scan_page.dart';
import '../pages/profile_page.dart';

void main() => runApp(const RafiqApp());

class RafiqApp extends StatefulWidget {
  const RafiqApp({super.key});

  static _RafiqAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_RafiqAppState>()!;

  @override
  State<RafiqApp> createState() => _RafiqAppState();
}

class _RafiqAppState extends State<RafiqApp> {
  bool isDark = false;

  void toggleTheme(bool value) {
    setState(() => isDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rafiq App',

      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

      home: const SplashScreen(),

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
