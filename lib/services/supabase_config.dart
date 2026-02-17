import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/pages/secrets.dart';

class SupabaseConfig {
  static Future<void> initialize() async {
    try {
      await Supabase.initialize(
        url: Secrets.supabaseUrl,
        anonKey: Secrets.supabaseAnonKey,
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