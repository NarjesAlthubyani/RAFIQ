import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: dotenv.env['SUPABASE_URL']!, // Changed from Secrets.supabaseUrl
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!, // Changed from Secrets.supabaseAnonKey
      );
      debugPrint('Supabase initialized successfully');
    } catch (e) {
      debugPrint('Supabase initialization failed: $e');
      rethrow;
    }
  }

  static SupabaseClient get client => Supabase.instance.client;
}

final supabase = SupabaseConfig.client;