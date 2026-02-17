import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/supabase_config.dart';

class AuthService {
  final SupabaseClient _supabase = supabase;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Sign Up
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );

    if (response.user != null) {
      // Create user profile in your users table
      await supabase.from('users').insert({
        'user_id': response.user!.id,
        'email': email,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    return response;
  }

  // Sign In
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign Out
  static Future<void> signOut() async {
    await supabase.auth.signOut();
  }

  // Get Current User
  static User? get currentUser => supabase.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Auth State Changes Stream
  static Stream<AuthState> get authState => supabase.auth.onAuthStateChange;

  // ✅ ADD THIS: Forgot password / Reset password
  static Future<void> resetPassword(String email) async {
    await supabase.auth.resetPasswordForEmail(email);
  }
}