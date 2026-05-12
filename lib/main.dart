import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import 'package:rafiq/services/supabase_config.dart';
import 'package:rafiq/pages/splash_screen.dart';
import 'package:rafiq/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env file
  await dotenv.load();
  await SupabaseConfig.initialize();
  runApp(const RafiqApp());
}

class RafiqApp extends StatelessWidget {
  const RafiqApp({Key? key}) : super(key: key);

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