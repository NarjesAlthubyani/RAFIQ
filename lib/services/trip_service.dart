import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/auth_service.dart';

final supabase = Supabase.instance.client;

class TripService {

  // ================= STEP 1: Save Trip Request =================
  static Future<Map<String, dynamic>> saveTripRequest({
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final days = toDate.difference(fromDate).inDays;

    final response = await supabase
        .from('preferences')
        .insert({
          'user_id': user.id,
          'city': destination,
          'start_date': fromDate.toIso8601String(),
          'end_date': toDate.toIso8601String(),
          'days': days,
          'budget': 0,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  // ================= STEP 2: Save Trip Details =================
  static Future<Map<String, dynamic>> saveTripDetails({
    required String preferenceId,
    required String budgetRange,
    required List<String> selectedInterests,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final double budget = _parseBudget(budgetRange);

    await supabase
        .from('preferences')
        .update({'budget': budget})
        .eq('preference_id', preferenceId);

    await supabase.from('interests').insert({
      'user_id': user.id,
      'preference_id': preferenceId,
      'selected_interests': selectedInterests,
    });

    final preferenceRaw = await supabase
        .from('preferences')
        .select()
        .eq('preference_id', preferenceId)
        .single();

    final preference = Map<String, dynamic>.from(preferenceRaw);

    final tripRaw = await supabase
        .from('trip_plans')
        .insert({
          'user_id': user.id,
          'preference_id': preferenceId,
          'city': preference['city'],
          'budget': budget,
          'days': preference['days'],
          'start_date': preference['start_date'],
          'end_date': preference['end_date'],
          'status': 'pending',
        })
        .select()
        .single();

    final trip = Map<String, dynamic>.from(tripRaw);

    return {
      'preference': preference,
      'trip': trip,
    };
  }

  // ================= STEP 3: Save AI Generated Trip =================
  static Future<void> saveAIGeneratedTrip({
    required String tripId,
    required dynamic aiResponse,
    required dynamic totalCost,
    required String summary,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final double finalCost = _safeDouble(totalCost);

    await supabase.from('ai_responses').insert({
      'trip_id': tripId,
      'user_id': user.id,
      'full_response': aiResponse,
      'summary': summary,
      'total_cost': finalCost,
    });

    await supabase
        .from('trip_plans')
        .update({'status': 'completed'})
        .eq('trip_id', tripId);
  }

  // ================= STEP 4: Get User Trips =================
  static Future<List<Map<String, dynamic>>> getUserTrips() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('trip_plans')
        .select('''
          *,
          ai_responses (
            summary,
            total_cost,
            created_at
          )
        ''')
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ================= STEP 5: Get Single Trip - FIXED =================
  static Future<Map<String, dynamic>?> getTripDetails(String tripId) async {
    try {
      print('🔍 Fetching trip details for ID: $tripId');
      
      final response = await supabase
          .from('trip_plans')
          .select('''
            *,
            preferences!inner (*),
            ai_responses (*)
          ''')
          .eq('trip_id', tripId)
          .maybeSingle();

      if (response == null) {
        print('❌ No trip found with ID: $tripId');
        return null;
      }

      print('✅ Trip details fetched successfully');
      
      // Get the preference_id from the response
      final preferenceId = response['preference_id'];
      
      if (preferenceId != null) {
        // Fetch interests separately using preference_id
        final interestsResponse = await supabase
            .from('interests')
            .select('selected_interests')
            .eq('preference_id', preferenceId)
            .maybeSingle();
        
        if (interestsResponse != null) {
          // Add interests to the response
          response['interests'] = interestsResponse;
        }
      }
      
      return Map<String, dynamic>.from(response);
    } catch (e) {
      print('❌ Error in getTripDetails: $e');
      return null;
    }
  }

  // ================= STEP 6: Delete Trip =================
  static Future<bool> deleteTrip(String tripId) async {
    try {
      await supabase
          .from('trip_plans')
          .delete()
          .eq('trip_id', tripId);
      return true;
    } catch (e) {
      print('❌ Error deleting trip: $e');
      return false;
    }
  }

  // ================= STEP 7: Get Saved Trips =================
  static Future<List<Map<String, dynamic>>> getSavedTrips() async {
    final user = AuthService.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('saved_trips')
        .select('''
          *,
          trip_plans!inner (
            *,
            preferences!inner (*),
            ai_responses (*)
          )
        ''')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }

  // ================= STEP 8: Save Trip (Bookmark) =================
  static Future<bool> saveTrip({
    required String tripId,
    String? notes,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) return false;

    try {
      await supabase.from('saved_trips').insert({
        'user_id': user.id,
        'trip_id': tripId,
        'notes': notes,
        'saved_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('❌ Error saving trip: $e');
      return false;
    }
  }

  // ================= HELPER: Safe Double =================
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // ================= HELPER: Parse Budget =================
  static double _parseBudget(String budgetRange) {
    if (budgetRange == '10000+') return 10000.0;

    final parts = budgetRange.split(' - ');
    if (parts.length == 2) {
      final min = double.tryParse(parts[0]) ?? 0.0;
      final max = double.tryParse(parts[1]) ?? 0.0;
      return (min + max) / 2;
    }

    return double.tryParse(budgetRange) ?? 0.0;
  }
}