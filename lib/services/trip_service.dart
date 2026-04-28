import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../models/trip_plan.dart';
import '../models/activity.dart';

final supabase = Supabase.instance.client;

class TripService {
  
  static Future<Map<String, dynamic>> saveTripRequest({
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final userId = AuthService.currentUserId;
    if (userId == null) throw Exception('User not logged in');

    final days = toDate.difference(fromDate).inDays + 1;
    
    final response = await supabase
        .from('preferences')
        .insert({
          'user_id': userId,
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

  static Future<Map<String, dynamic>> saveTripDetails({
    required String preferenceId,
    required String budgetRange,
    required List<String> selectedInterests,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final double budget = parseBudget(budgetRange);

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
    
    return {
      'preference': preference,
      'trip': tripRaw,
    };
  }

  static Future<void> saveAIPlan({
  required String tripId,
  required Map<String, dynamic> plan,
}) async {
  final user = AuthService.currentUser;
  if (user == null) throw Exception('User not logged in');
  
  try {
    await supabase.from('ai_responses').upsert({
      'trip_id': tripId,
      'user_id': user.id,
      'full_response': jsonEncode(plan),
      'summary': plan['summary'] ?? 'Trip plan generated',
      'total_cost': (plan['total_cost'] ?? 0).toDouble(),
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'trip_id');
    
    await supabase
        .from('trip_plans')
        .update({'status': 'completed'})
        .eq('trip_id', tripId);
  } catch (e) {
    rethrow;
  }
  
}

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

  static Future<Map<String, dynamic>?> getTripDetails(String tripId) async {
    try {
      final tripResponse = await supabase
          .from('trip_plans')
          .select('''
            *,
            preferences!inner (*)
          ''')
          .eq('trip_id', tripId)
          .maybeSingle();

      if (tripResponse == null) return null;
      
      final aiResponses = await supabase
          .from('ai_responses')
          .select('*')
          .eq('trip_id', tripId)
          .order('created_at', ascending: false); 
     
      Map<String, dynamic> tripData = Map<String, dynamic>.from(tripResponse);
      tripData['ai_responses'] = aiResponses;
      
      return tripData;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteTrip(String tripId) async {
    try {
      await supabase.from('trip_plans').delete().eq('trip_id', tripId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> getTicketInfo(String activityName) async {
    try {
      var response = await supabase
          .from('saudi_places') 
          .select('ticket_booking, ticket_link, name')
          .eq('name', activityName)
          .maybeSingle();
      
      if (response != null && response['ticket_link'] != null) {
        return {
          'hasTicket': true,
          'ticketLink': response['ticket_link'],
        };
      }
      return {'hasTicket': false, 'ticketLink': null};
    } catch (e) {
      return {'hasTicket': false, 'ticketLink': null};
    }
  }

  static Future<void> updateAiResponse(String tripId, Map<String, dynamic> updatedPlan) async {
    try {
      await supabase
          .from('ai_responses')
          .update({
            'full_response': jsonEncode(updatedPlan),
            'summary': updatedPlan['summary'] ?? 'Trip plan updated',
            'total_cost': updatedPlan['total_cost'] ?? 0,
          })
          .eq('trip_id', tripId);
    } catch (e) {
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getAiResponse(String tripId) async {
    try {
      final response = await supabase
          .from('ai_responses')
          .select()
          .eq('trip_id', tripId)
          .maybeSingle();
      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }
  static Future<void> updateTripPlan(String tripId, Map<String, dynamic> updatedPlan) async {
  try {
    final existingResponse = await supabase
        .from('ai_responses')
        .select()
        .eq('trip_id', tripId)
        .maybeSingle();
    
    if (existingResponse != null) {
      await supabase
          .from('ai_responses')
          .update({
            'full_response': jsonEncode(updatedPlan),
            'summary': updatedPlan['summary'],
            'total_cost': updatedPlan['total_cost'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('trip_id', tripId);
    } else {
      final user = AuthService.currentUser;
      if (user != null) {
        await supabase.from('ai_responses').insert({
          'trip_id': tripId,
          'user_id': user.id,
          'full_response': jsonEncode(updatedPlan),
          'summary': updatedPlan['summary'],
          'total_cost': updatedPlan['total_cost'],
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  } catch (e) {
    rethrow;
  }
}

  static double parseBudget(String budgetRange) {
    if (budgetRange == '10000+') return 10000.0;
    if (budgetRange == '5000+') return 5000.0;
    if (budgetRange == '3000+') return 3000.0;
    if (budgetRange == '1000+') return 1000.0;

    final parts = budgetRange.split(' - ');
    if (parts.length == 2) {
      final min = double.tryParse(parts[0]) ?? 0.0;
      final max = double.tryParse(parts[1]) ?? 0.0;
      return (min + max) / 2;
    }
    return double.tryParse(budgetRange) ?? 0.0;
  }
}