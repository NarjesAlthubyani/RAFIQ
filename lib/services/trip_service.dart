import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/auth_service.dart';
import '../models/user.dart';
import '../models/trip_plan.dart';
import '../models/activity.dart';
import 'trip_planner.dart';

final supabase = Supabase.instance.client;

class TripService {
  static TripPlanner get _tripPlanner => TripPlanner();
  
  static Future<TripPlan> createSingleTrip({
    required AppUser user,
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
    required double budget,
    required List<String> interests,
    required List<Map<String, dynamic>> places,
    required List<Map<String, dynamic>> foodVenues,
  }) async {
    
    final tripPlan = await _tripPlanner.createTripPlan(
      user: user,
      city: city,
      fromDate: fromDate,
      toDate: toDate,
      places: places.map((p) => Activity.fromJson(p)).toList(),
      foodVenues: foodVenues.map((f) => Activity.fromJson(f)).toList(),
      interests: interests,
      budget: budget,
    );
    
    return tripPlan;
  }
  
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
    final city = preference['city'];
    final fromDate = DateTime.parse(preference['start_date']);
    final toDate = DateTime.parse(preference['end_date']);

    final places = await _fetchPlacesFromDatabase(city);
    final foodVenues = await _fetchFoodVenuesFromDatabase(city);
  
    final appUser = AppUser(
      userId: user.id,
      name: user.email?.split('@').first ?? 'User',
      email: user.email ?? '',
      password: '',
    );
    
    final tripPlan = await createSingleTrip(
      user: appUser,
      city: city,
      fromDate: fromDate,
      toDate: toDate,
      budget: budget,
      interests: selectedInterests,
      places: places,
      foodVenues: foodVenues,
    );
    
    final tripRaw = await supabase
        .from('trip_plans')
        .insert({
          'user_id': user.id,
          'preference_id': preferenceId,
          'city': city,
          'budget': budget,
          'days': preference['days'],
          'start_date': preference['start_date'],
          'end_date': preference['end_date'],
          'status': 'completed',
        })
        .select()
        .single();
    
    final tripId = tripRaw['trip_id'];
 
    await supabase.from('ai_responses').insert({
      'trip_id': tripId, 
      'user_id': user.id,
      'full_response': jsonEncode(tripPlan.toJson()),
      'summary': tripPlan.summary,
      'total_cost': tripPlan.totalEstimatedCost,
    });
    
    return {
      'preference': preference,
      'trip': tripRaw,
      'ai_plan': tripPlan.toJson(),
    };
  }
  
  static Future<List<Map<String, dynamic>>> _fetchPlacesFromDatabase(String city) async {
    final response = await supabase
        .from('saudi_places')
        .select('*')
        .eq('city', city)
        .not('category', 'ilike', 'Restaurant');
    
    return List<Map<String, dynamic>>.from(response);
  }
  
  static Future<List<Map<String, dynamic>>> _fetchFoodVenuesFromDatabase(String city) async {
    final seen = <String>{};
    final merged = <Map<String, dynamic>>[];

    void addAll(dynamic response) {
      if (response is! List) return;
      for (final row in response) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final key = '${m['id'] ?? m['place_id'] ?? m['name']}';
        if (seen.add(key)) merged.add(m);
      }
    }

    addAll(
      await supabase
          .from('saudi_places')
          .select('*')
          .eq('city', city)
          .ilike('category', '%Restaurant%'),
    );
    for (final pattern in ['%Cafe%', '%Bakery%', '%Coffee%']) {
      addAll(
        await supabase
            .from('saudi_places')
            .select('*')
            .eq('city', city)
            .ilike('category', pattern),
      );
    }
    return merged;
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

      if (tripResponse == null) {
        return null;
      }
      
      final aiResponses = await supabase
          .from('ai_responses')
          .select('*')
          .eq('trip_id', tripId)
          .order('created_at', ascending: false); 
     
      Map<String, dynamic> tripData = Map<String, dynamic>.from(tripResponse);
      tripData['ai_responses'] = aiResponses;
      
      final preferenceId = tripData['preference_id'];
      
      if (preferenceId != null) {
        final interestsResponse = await supabase
            .from('interests')
            .select('selected_interests')
            .eq('preference_id', preferenceId)
            .maybeSingle();
        
        if (interestsResponse != null) {
          tripData['interests'] = interestsResponse;
        }
      }
      
      return tripData;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteTrip(String tripId) async {
    try {
      await supabase
          .from('trip_plans')
          .delete()
          .eq('trip_id', tripId);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getImageByName(String name, String city) async {
    try {
      final place = await supabase
          .from('saudi_places')
          .select('image_url')
          .ilike('name', '%$name%')
          .eq('city', city)
          .maybeSingle();

      if (place != null && place['image_url'] != null) {
        return place['image_url'];
      }
    } catch (e) {}
    return null;
  }

  static Future<Map<String, dynamic>> getTicketInfo(String activityName) async {
    try {
      var response = await supabase
          .from('saudi_places') 
          .select('ticket_booking, ticket_link, name')
          .eq('name', activityName)
          .maybeSingle();
      
      if (response == null) {
        final allPlaces = await supabase
            .from('saudi_places')
            .select('name, ticket_booking, ticket_link');
        
        for (var place in allPlaces) {
          String placeName = place['name']?.toString() ?? '';
          if (activityName.toLowerCase().contains(placeName.toLowerCase()) ||
              placeName.toLowerCase().contains(activityName.toLowerCase())) {
            response = place;
            break;
          }
        }
      } 
      
      if (response != null) {
        String? ticketLink = response['ticket_link']?.toString();
        bool hasTicket = ticketLink != null && ticketLink.isNotEmpty;
        
        return {
          'hasTicket': hasTicket,
          'ticketLink': ticketLink,
        };
      }
      
      return {'hasTicket': false, 'ticketLink': null};
    } catch (e) {
      return {'hasTicket': false, 'ticketLink': null};
    }
  }

  static Future<bool> saveTrip({required String tripId, String? notes}) async {
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
      return false;
    }
  }
  
  static double _parseBudget(String budgetRange) {
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