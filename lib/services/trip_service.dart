import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = Supabase.instance.client;

class TripService {
  static const String _geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  static Future<int> getTravelTime({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    if (originLat == 0 || originLng == 0 || destLat == 0 || destLng == 0) {
      return 30; 
    }

    try {
      
      final url = 'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': dotenv.env['OPENROUTE_API_KEY'] ?? '',
        },
        body: jsonEncode({
          'coordinates': [
            [originLng, originLat], 
            [destLng, destLat]
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['features'] != null && 
            data['features'].isNotEmpty &&
            data['features'][0]['properties'] != null &&
            data['features'][0]['properties']['segments'] != null &&
            data['features'][0]['properties']['segments'].isNotEmpty) {
          
          double seconds = data['features'][0]['properties']['segments'][0]['duration'];
          int minutes = (seconds / 60).round();
          
          return minutes;
        }
      } else {
      }
    } catch (e) {
    }
    return _estimateTravelTimeByDistance(originLat, originLng, destLat, destLng);
  }

  static int _estimateTravelTimeByDistance(
    double lat1, double lon1, double lat2, double lon2
  ) {
    const double R = 6371; 
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    double a = pow(sin(dLat / 2), 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
              pow(sin(dLon / 2), 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    double distanceInKm = R * c;
   
    int speedKmPerHour = distanceInKm > 50 ? 80 : 
                        distanceInKm > 20 ? 60 :  
                        40; 
    
    int minutes = (distanceInKm / speedKmPerHour * 60).round();
    minutes = minutes.clamp(5, 180); 
    
    return minutes;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180; 
  }

  static Future<Map<String, double>> getCoordinatesFromPlace(String placeName, String city) async {
    try {
      final place = await supabase
          .from('saudi_places')
          .select('lat, lng')
          .ilike('name', '%$placeName%')
          .eq('city', city)
          .maybeSingle();
      
      if (place != null && place['lat'] != null && place['lng'] != null) {
        return {
          'lat': (place['lat'] as num).toDouble(),
          'lng': (place['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
    }
    return {'lat': 0.0, 'lng': 0.0};
  }

  static Future<List<Map<String, dynamic>>> getFoodVenues({
    required String city,
    String? priceLevel,
    String? category,
    String? timeOfDay,
  }) async {
    try {
      var query = supabase
          .from('saudi_places')
          .select('*')
          .eq('city', city)
          .eq('record_type', 'restaurant'); 

      if (priceLevel != null && priceLevel.isNotEmpty) {
        query = query.eq('price_level', priceLevel);
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (timeOfDay != null && timeOfDay.isNotEmpty) {
        query = query.contains('best_time_of_day', [timeOfDay]);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPlaces({
    required String city,
    List<String>? categories,
    int? maxPriceLevel,
    String? bestTime,
  }) async {
    try {
      var query = supabase
          .from('saudi_places')
          .select('*')
          .eq('city', city)
          .neq('record_type', 'restaurant'); 

      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('category', categories);
      }

      if (maxPriceLevel != null) {
        query = query.lte('price_level', maxPriceLevel);
      }

      if (bestTime != null && bestTime.isNotEmpty) {
        query = query.eq('best_time_of_day', bestTime);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static String _formatPlacesForPrompt(List<Map<String, dynamic>> places) {
    String result = "";
    
    for (var place in places.take(30)) { 
      result += "- ${place['name']}\n";
      result += "  Category: ${place['category']}\n";
      result += "  Duration: ${place['duration_minutes'] ?? 90} minutes\n";
      result += "  Price: ${place['price_level'] == 0 ? 'Free' : place['price_level'] == 2 ? 'Budget' : 'Premium'}\n";
      if (place['best_time_of_day'] != null) {
        result += "  Best time: ${place['best_time_of_day']}\n";
      }
      result += "\n";
    }
    return result;
  }

  static String _formatFoodForPrompt(List<Map<String, dynamic>> foodVenues) {
    String result = "";
    
    for (var venue in foodVenues.take(30)) { 
      result += "- ${venue['name']} (${venue['category']})\n";
      result += "  Price level: ${venue['price_level']}\n";
      if (venue['best_time_of_day'] != null) {
        result += "  Best for: ${venue['best_time_of_day']}\n";
      }
      result += "\n";
    }
    return result;
  }

  static Future<Map<String, dynamic>> validateItinerary(
    Map<String, dynamic> itinerary,
    String city,
  ) async {
    bool isValid = true;
    List<String> issues = [];
    
    var days = itinerary['itinerary'] as List?;
    if (days == null || days.isEmpty) {
      return {'isValid': false, 'issues': ['No itinerary days']};
    }
    
    for (int dayIndex = 0; dayIndex < days.length; dayIndex++) {
      var day = days[dayIndex];
      var activities = day['activities'] as List?;
      
      if (activities == null || activities.isEmpty) {
        issues.add('Day ${dayIndex + 1} has no activities');
        isValid = false;
        continue;
      }
      
      if (activities.length > 5) {
        issues.add('Day ${dayIndex + 1} has ${activities.length} activities (max 5)');
        isValid = false;
      }
      
      int totalMinutes = 0;
      
      for (int i = 0; i < activities.length; i++) {
        var activity = activities[i];
        
        int duration = activity['duration'] ?? 90;
        totalMinutes += duration;
      
        if (i < activities.length - 1) {
          var nextActivity = activities[i + 1];
          
          var currentCoords = await getCoordinatesFromPlace(
            activity['title'] ?? '',
            city,
          );
          
          var nextCoords = await getCoordinatesFromPlace(
            nextActivity['title'] ?? '',
            city,
          );
      
          int travelTime = 30; 
          
          if (currentCoords['lat'] != 0 && nextCoords['lat'] != 0) {
            travelTime = await getTravelTime(
              originLat: currentCoords['lat']!,
              originLng: currentCoords['lng']!,
              destLat: nextCoords['lat']!,
              destLng: nextCoords['lng']!,
            );
          }
          totalMinutes += travelTime;
        }
      }
      
      if (totalMinutes > 600) {
        issues.add('Day ${dayIndex + 1} too long: ${(totalMinutes / 60).round()} hours');
        isValid = false;
      }
    }
    
    return {
      'isValid': isValid,
      'issues': issues,
    };
  }

  static List<Map<String, dynamic>> _clusterPlacesByArea(
    List<Map<String, dynamic>> places,
  ) {
    if (places.isEmpty) return [];

    places = List.from(places);
    places.sort((a, b) => (a['lat'] ?? 0).compareTo(b['lat'] ?? 0));
    return places.take(15).toList();
  }

  static List<Map<String, dynamic>> _limitFoodOptions(
    List<Map<String, dynamic>> foodVenues,
  ) {
    if (foodVenues.isEmpty) return [];
    foodVenues = List.from(foodVenues);
    return foodVenues.take(10).toList();
  }

  static bool _hasDuplicateVenues(Map<String, dynamic> itinerary) {
    final Set<String> used = {};

    final days = itinerary['itinerary'] as List?;
    if (days == null) return true;

    for (var day in days) {
      final activities = day['activities'] as List?;
      if (activities == null) continue;

      for (var act in activities) {
        final name = act['title'];
        if (name == null) continue;

        if (used.contains(name)) {
          return true;
        }
        used.add(name);
      }
    }
    return false;
  }

  static Future<Map<String, dynamic>> _callGeminiWithPrompt({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
    required double budget,
    required List<String> interests,
    required List<Map<String, dynamic>> places,
    required List<Map<String, dynamic>> foodVenues,
  }) async {

    final days = toDate.difference(fromDate).inDays + 1;

    final clusteredPlaces = _clusterPlacesByArea(places);
    final limitedFood = _limitFoodOptions(foodVenues);

    final formattedPlaces = _formatPlacesForPrompt(clusteredPlaces);
    final formattedFood = _formatFoodForPrompt(limitedFood);

    String prompt = """
You are a deterministic Saudi travel itinerary generator.

Your job is to create a realistic ${days}-day itinerary for a trip in ${city}, Saudi Arabia.

You MUST strictly follow the dataset and rules below.

=====================
HARD RULES
=====================

1. ONLY use places from the provided datasets.
2. NEVER invent locations.
3. NEVER repeat the same attraction.
4. NEVER repeat the same restaurant.
5. Attractions MUST come from AVAILABLE ATTRACTIONS.
6. Restaurants and cafes MUST come from AVAILABLE RESTAURANTS.
7. Use the EXACT "name" value from the dataset.
8. Each day may contain MAXIMUM 6 activities.
9. Daily total activity duration MUST NOT exceed 9 hours (540 minutes).
10. Add 20 minutes travel time when moving between different areas.
11. Group nearby locations (similar latitude/longitude) in the same day when possible.
12. Lunch must be scheduled after the morning attraction.
13. Dinner must be scheduled after the afternoon attraction.
14. Prefer indoor venues if best_time_of_day indicates evening.
15. Use the dataset values for:
   - duration_minutes
   - price_level
16. The total cost MUST NOT exceed SAR ${budget}.
17. Do NOT include locations from other cities.
18. Breakfast must come from AVAILABLE RESTAURANTS where category is "café" or "restaurant".
19. Breakfast must be the first activity of the day.

=====================
COST RULE
=====================

Convert price_level to SAR cost:

0 → 0 SAR  
1 → 50 SAR  
2 → 100 SAR  
3 → 200 SAR  
4 → 400 SAR

Use this mapping when calculating total_cost.

=====================
TIME STRUCTURE
=====================

Each day should follow this structure:

Morning:
- Breakfast (Cafe or Restaurant)

Late Morning:
- Attraction

Midday:
- Lunch (Restaurant)

Afternoon:
- Attraction

Evening:
- Dinner (Restaurant)

Optional:
- Coffee stop

=====================
AVAILABLE ATTRACTIONS
=====================

${formattedPlaces}

Each attraction contains:
name, category, lat, lng, duration_minutes, price_level

=====================
AVAILABLE RESTAURANTS
=====================

${formattedFood}

Each restaurant contains:
name, category, lat, lng, duration_minutes, price_level

=====================
OUTPUT FORMAT
=====================

Return ONLY valid JSON using this exact schema:

{
  "summary": "short description of the trip",
  "total_cost": number,
  "itinerary": [
    {
      "day": number,
      "date": "YYYY-MM-DD",
      "activities": [
        {
          "title": "place name",
          "category": "Attraction | Food | Cafe",
          "location": "${city}",
          "duration": number,
          "cost": number
        }
      ]
    }
  ]
}

=====================
FINAL VALIDATION
=====================

Before returning the result ensure:

✓ No duplicate attractions  
✓ No duplicate restaurants  
✓ All places exist in dataset  
✓ Daily duration ≤ 540 minutes  
✓ total_cost ≤ SAR ${budget}  
✓ JSON is valid  

Return ONLY the JSON.
""";

    final response = await http.post(
      Uri.parse('$_geminiApiUrl?key=${dotenv.env['GEMINI_API_KEY']}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3, 
          'topK': 40,
          'topP': 0.9,
          'maxOutputTokens': 4096,
        }
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Gemini API error: ${response.body}");
    }

    final data = jsonDecode(response.body);
    final aiText = data['candidates'][0]['content']['parts'][0]['text'];

    final startIndex = aiText.indexOf('{');
    final endIndex = aiText.lastIndexOf('}') + 1;

    if (startIndex != -1 && endIndex > startIndex) {
      final jsonStr = aiText.substring(startIndex, endIndex);
      return jsonDecode(jsonStr);
    }

    throw Exception('Invalid JSON from Gemini');
  }

  static Future<Map<String, dynamic>> generateAndValidatePlan({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
    required double budget,
    required List<String> interests,
    required List<Map<String, dynamic>> places,
    required List<Map<String, dynamic>> foodVenues,
  }) async {

    const int maxAttempts = 3;

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {

      try {
        final plan = await _callGeminiWithPrompt(
          city: city,
          fromDate: fromDate,
          toDate: toDate,
          budget: budget,
          interests: interests,
          places: places,
          foodVenues: foodVenues,
        );

        if (_hasDuplicateVenues(plan)) {
          continue;
        }

        final validation = await validateItinerary(plan, city);

        if (validation['isValid'] == true) {
          return plan;
        }

      } catch (e) {
      }
    }

    return _createFallbackPlan(city, fromDate, toDate, places, foodVenues);
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
  } catch (e) {
  }

  return null;
}
  static Map<String, dynamic> _createFallbackPlan(
    String city,
    DateTime fromDate,
    DateTime toDate,
    List<Map<String, dynamic>> places,
    List<Map<String, dynamic>> foodVenues,
  ) {
    final days = toDate.difference(fromDate).inDays + 1;
    List<Map<String, dynamic>> itinerary = [];
    
    final samplePlaces = places.take(6).toList();
    final restaurants = foodVenues.where((v) => 
      v['category']?.toString().toLowerCase() == 'restaurant').take(4).toList();
    final cafes = foodVenues.where((v) => 
      v['category']?.toString().toLowerCase() == 'café' || 
      v['category']?.toString().toLowerCase() == 'cafe').take(3).toList();
    
    for (int i = 1; i <= days; i++) {
      List<Map<String, dynamic>> activities = [];
      final currentDate = fromDate.add(Duration(days: i - 1));
      
      if (restaurants.isNotEmpty) {
        final restaurant = restaurants[i % restaurants.length];
        activities.add({
          'title': restaurant['name'],
          'category': 'Food',
          'description': restaurant['description'] ?? 'Enjoy local cuisine',
          'location': city,
          'cost': 150.0,
          'duration': 90,
        });
      }
      
      if (samplePlaces.length > 1) {
        final place = samplePlaces[(i + 1) % samplePlaces.length];
        activities.add({
          'title': place['name'],
          'category': place['category'] ?? 'Attraction',
          'description': place['description'] ?? 'Explore this site',
          'location': city,
          'cost': place['price_level'] == 0 ? 0.0 : 50.0,
          'duration': place['duration_minutes'] ?? 90,
        });
      }
      
      if (restaurants.length > 1) {
        final restaurant = restaurants[(i + 2) % restaurants.length];
        activities.add({
          'title': restaurant['name'],
          'category': 'Food',
          'description': restaurant['description'] ?? 'Fine dining experience',
          'location': city,
          'cost': 200.0,
          'duration': 120,
        });
      }
      
      itinerary.add({
        'day': i,
        'date': currentDate.toIso8601String().split('T')[0],
        'activities': activities,
      });
    }
    
    double totalCost = 0;
    for (var day in itinerary) {
      for (var activity in day['activities']) {
        totalCost += activity['cost'] as double;
      }
    }
    
    return {
      'itinerary': itinerary,
      'total_cost': totalCost,
      'summary': 'A $days-day trip to $city featuring top attractions and local cuisine.',
    };
  }

  static List<String> _mapInterestsToCategories(List<String> interests) {
    List<String> categories = [];
    
    for (var interest in interests) {
      switch (interest) {
        case 'History':
          categories.addAll(['History', 'Culture']);
          break;
        case 'Nature':
          categories.add('Nature');
          break;
        case 'Adventure':
          categories.add('Adventure');
          break;
        case 'Entertainment':
          categories.add('Entertainment');
          break;
        case 'Shopping':
          categories.add('Shopping');
          break;
        case 'Culture':
          categories.addAll(['Culture', 'Arts']);
          break;
      }
    }
    
    return categories.toSet().toList();
  }

  static Future<Map<String, dynamic>> saveTripRequest({
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final days = toDate.difference(fromDate).inDays + 1;

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
          'status': 'pending',
        })
        .select()
        .single();

    final trip = Map<String, dynamic>.from(tripRaw);

    final foodVenues = await getFoodVenues(
      city: city,
      priceLevel: _mapBudgetToPriceLevel(budget),
    );
    
    final categories = _mapInterestsToCategories(selectedInterests);
    final places = await getPlaces(
      city: city,
      categories: categories.isNotEmpty ? categories : null,
      maxPriceLevel: budget > 5000 ? 4 : 2,
    );
    
    final aiPlan = await generateAndValidatePlan(
      city: city,
      fromDate: fromDate,
      toDate: toDate,
      budget: budget,
      interests: selectedInterests,
      places: places,
      foodVenues: foodVenues,
    );

    await supabase.from('ai_responses').insert({
      'trip_id': trip['trip_id'],
      'user_id': user.id,
      'full_response': aiPlan,
      'summary': aiPlan['summary'] ?? 'Trip to $city',
      'total_cost': _safeDouble(aiPlan['total_cost']),
    });

    await supabase
        .from('trip_plans')
        .update({'status': 'completed'})
        .eq('trip_id', trip['trip_id']);

    return {
      'preference': preference,
      'trip': trip,
      'ai_plan': aiPlan,
      'food_venues_count': foodVenues.length,
      'places_count': places.length,
    };
  }

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
      return false;
    }
  }

  static String _mapBudgetToPriceLevel(double budget) {
    if (budget < 1000) return 'budget';
    if (budget < 3000) return 'moderate';
    if (budget < 8000) return 'expensive';
    return 'luxury';
  }

  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

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