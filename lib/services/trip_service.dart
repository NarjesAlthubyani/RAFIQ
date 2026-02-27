import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math'; // ✅ ADD THIS for sin, cos, sqrt, atan2
import 'package:flutter_dotenv/flutter_dotenv.dart';

final supabase = Supabase.instance.client;

class TripService {
  static const String _geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  // ================= TRAVEL TIME CALCULATOR USING OPENROUTESERVICE DIRECT API =================
  static Future<int> getTravelTime({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    // If coordinates are missing, return default based on city
    if (originLat == 0 || originLng == 0 || destLat == 0 || destLng == 0) {
      print('⚠️ Missing coordinates, using default 30 min');
      return 30; // Default 30 minutes
    }

    try {
      print('📍 Calculating route from ($originLat, $originLng) to ($destLat, $destLng)');
      
      final url = 'https://api.openrouteservice.org/v2/directions/driving-car/geojson';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': dotenv.env['OPENROUTE_API_KEY'] ?? '',
        },
        body: jsonEncode({
          'coordinates': [
            [originLng, originLat], // Note: OpenRouteService uses [lng, lat] order!
            [destLng, destLat]
          ]
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract duration from response
        if (data['features'] != null && 
            data['features'].isNotEmpty &&
            data['features'][0]['properties'] != null &&
            data['features'][0]['properties']['segments'] != null &&
            data['features'][0]['properties']['segments'].isNotEmpty) {
          
          double seconds = data['features'][0]['properties']['segments'][0]['duration'];
          int minutes = (seconds / 60).round();
          
          print('🚗 Travel time: $minutes minutes');
          return minutes;
        }
      } else {
        print('❌ OpenRouteService API error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ OpenRouteService error: $e');
    }
    
    // Fallback to distance-based estimation if API fails
    return _estimateTravelTimeByDistance(originLat, originLng, destLat, destLng);
  }

  // ================= FALLBACK: ESTIMATE TRAVEL TIME BY DISTANCE =================
  static int _estimateTravelTimeByDistance(
    double lat1, double lon1, double lat2, double lon2
  ) {
    // Calculate approximate distance using Haversine formula
    const double R = 6371; // Earth's radius in km
    
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    
    // ✅ FIXED: Use math functions with 'dart:math' import
    double a = pow(sin(dLat / 2), 2) +
              cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * 
              pow(sin(dLon / 2), 2);
    
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    double distanceInKm = R * c;
    
    // Assume average speed based on distance
    int speedKmPerHour = distanceInKm > 50 ? 80 : // Highway
                        distanceInKm > 20 ? 60 :  // Main roads
                        40; // City streets
    
    int minutes = (distanceInKm / speedKmPerHour * 60).round();
    minutes = minutes.clamp(5, 180); // Between 5 minutes and 3 hours
    
    print('🚗 Estimated travel time (fallback): $minutes minutes (distance: ${distanceInKm.toStringAsFixed(1)} km)');
    return minutes;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180; // ✅ FIXED: Use pi from 'dart:math'
  }

  // ================= GET COORDINATES FROM PLACE NAME =================
  static Future<Map<String, double>> getCoordinatesFromPlace(String placeName, String city) async {
    try {
      // First try to get from places table
      final places = await supabase
          .from('places')
          .select('lat, lng')
          .ilike('name', '%$placeName%')
          .eq('city', city)
          .maybeSingle();
      
      if (places != null && places['lat'] != null && places['lng'] != null) {
        return {
          'lat': (places['lat'] as num).toDouble(),
          'lng': (places['lng'] as num).toDouble(),
        };
      }
      
      // If not found, try food venues
      final food = await supabase
          .from('food_venues')
          .select('lat, lng')
          .ilike('name', '%$placeName%')
          .eq('city', city)
          .maybeSingle();
      
      if (food != null && food['lat'] != null && food['lng'] != null) {
        return {
          'lat': (food['lat'] as num).toDouble(),
          'lng': (food['lng'] as num).toDouble(),
        };
      }
    } catch (e) {
      print('❌ Error getting coordinates: $e');
    }
    
    return {'lat': 0.0, 'lng': 0.0};
  }

  // ================= FETCH FOOD VENUES FROM SUPABASE =================
  static Future<List<Map<String, dynamic>>> getFoodVenues({
    required String city,
    String? priceLevel,
    String? category,
    String? timeOfDay,
  }) async {
    try {
      var query = supabase
          .from('food_venues')
          .select('*')
          .eq('city', city);

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
      print('❌ Error fetching food venues: $e');
      return [];
    }
  }

  // ================= FETCH PLACES FROM SUPABASE =================
  static Future<List<Map<String, dynamic>>> getPlaces({
    required String city,
    List<String>? categories,
    int? maxPriceLevel,
    String? bestTime,
    String? recordType,
  }) async {
    try {
      var query = supabase
          .from('places')
          .select('*')
          .eq('city', city);

      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('category', categories);
      }

      if (maxPriceLevel != null) {
        query = query.lte('price_level', maxPriceLevel);
      }

      if (bestTime != null && bestTime.isNotEmpty) {
        query = query.eq('best_time_of_day', bestTime);
      }

      if (recordType != null) {
        query = query.eq('record_type', recordType);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error fetching places: $e');
      return [];
    }
  }

  // ================= FORMAT PLACES FOR AI PROMPT =================
  static String _formatPlacesForPrompt(List<Map<String, dynamic>> places) {
    String result = "";
    
    for (var place in places.take(30)) { // Limit to 30 to avoid token limits
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

  // ================= FORMAT FOOD VENUES FOR AI PROMPT =================
  static String _formatFoodForPrompt(List<Map<String, dynamic>> foodVenues) {
    String result = "";
    
    for (var venue in foodVenues.take(30)) { // Limit to 30
      result += "- ${venue['name']} (${venue['category']})\n";
      result += "  Price level: ${venue['price_level']}\n";
      if (venue['best_time_of_day'] != null) {
        result += "  Best for: ${venue['best_time_of_day']}\n";
      }
      result += "\n";
    }
    
    return result;
  }

  // ================= VALIDATE ITINERARY FEASIBILITY =================
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
      
      // Check number of activities
      if (activities.length > 5) {
        issues.add('Day ${dayIndex + 1} has ${activities.length} activities (max 5)');
        isValid = false;
      }
      
      // Calculate total duration with travel time
      int totalMinutes = 0;
      
      for (int i = 0; i < activities.length; i++) {
        var activity = activities[i];
        
        // Get duration from activity (default 90 min)
        int duration = activity['duration'] ?? 90;
        totalMinutes += duration;
        
        // Add travel time to next activity (except last)
        if (i < activities.length - 1) {
          var nextActivity = activities[i + 1];
          
          // Get coordinates for current and next activity
          var currentCoords = await getCoordinatesFromPlace(
            activity['title'] ?? activity['venue_name'] ?? '',
            city,
          );
          
          var nextCoords = await getCoordinatesFromPlace(
            nextActivity['title'] ?? nextActivity['venue_name'] ?? '',
            city,
          );
          
          int travelTime = 30; // Default
          
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
      
      // Max 10 hours of activities per day (600 minutes)
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

  // ================= CALL GEMINI WITH IMPROVED PROMPT =================
  static Future<Map<String, dynamic>> _callGeminiWithPrompt({
    required String city,
    required DateTime fromDate,
    required DateTime toDate,
    required double budget,
    required List<String> interests,
    required List<Map<String, dynamic>> places,
    required List<Map<String, dynamic>> foodVenues,
  }) async {
    
    final days = toDate.difference(fromDate).inDays;
    
    String prompt = """
    You are a Saudi travel expert creating a realistic ${days}-day itinerary for $city, Saudi Arabia.

    USER PREFERENCES:
    - Total Budget: SAR ${budget}
    - Interests: ${interests.join(', ')}
    - Travel Dates: ${fromDate.toIso8601String().split('T')[0]} to ${toDate.toIso8601String().split('T')[0]}

    CRITICAL TIME CONSTRAINTS:
    - Morning activities: 9:00 AM - 12:00 PM (3 hours max)
    - Lunch: 12:30 PM - 2:00 PM (1.5 hours)
    - Afternoon activities: 2:30 PM - 5:30 PM (3 hours max)
    - Dinner: 7:00 PM - 9:00 PM (2 hours)
    - Add 30 minutes travel time between different locations
    - Maximum 4-5 activities per day
    - Total activity time per day should not exceed 8-9 hours

    AVAILABLE ATTRACTIONS (USE ONLY THESE):
    ${_formatPlacesForPrompt(places)}

    AVAILABLE RESTAURANTS & CAFES (USE ONLY THESE FOR MEALS):
    ${_formatFoodForPrompt(foodVenues)}

    IMPORTANT RULES:
    1. Use EXACT names from the lists above
    2. For meals, ALWAYS pick from restaurants/cafes list
    3. Match price levels to the user's budget
    4. Group nearby attractions on same day
    5. Include a mix of free and paid activities

    Return the response in this EXACT JSON format:
    {
      "itinerary": [
        {
          "day": 1,
          "date": "${fromDate.toIso8601String().split('T')[0]}",
          "activities": [
            {
              "title": "Activity Name",
              "category": "History/Nature/Food/etc",
              "description": "Brief description",
              "location": "Area name",
              "cost": 0.0,
              "duration": 90,
              "venue_name": "Restaurant name (for meals only)"
            }
          ]
        }
      ],
      "total_cost": 0.0,
      "summary": "Brief trip summary"
    }
    """;

    print('🤖 Calling Gemini API for $city...');
    
    try {
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
            'temperature': 0.7,
            'topK': 1,
            'topP': 1,
            'maxOutputTokens': 4096,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiText = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Extract JSON from response
        final startIndex = aiText.indexOf('{');
        final endIndex = aiText.lastIndexOf('}') + 1;
        
        if (startIndex != -1 && endIndex > startIndex) {
          final jsonStr = aiText.substring(startIndex, endIndex);
          return jsonDecode(jsonStr);
        }
      } else {
        print('❌ Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Gemini API error: $e');
    }
    
    throw Exception('Failed to generate AI plan');
  }

  // ================= GENERATE AND VALIDATE PLAN (with retries) =================
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
      print('🎯 Generation attempt $attempt of $maxAttempts');
      
      try {
        // Generate plan with AI
        var plan = await _callGeminiWithPrompt(
          city: city,
          fromDate: fromDate,
          toDate: toDate,
          budget: budget,
          interests: interests,
          places: places,
          foodVenues: foodVenues,
        );
        
        // Validate the plan
        final validation = await validateItinerary(plan, city);
        
        if (validation['isValid'] == true) {
          print('✅ Plan validated successfully');
          return plan;
        } else {
          print('⚠️ Validation failed: ${validation['issues']}');
          
          // If last attempt, return with warning
          if (attempt == maxAttempts) {
            print('⚠️ Using best effort plan after $maxAttempts attempts');
            return plan;
          }
        }
      } catch (e) {
        print('❌ Generation error on attempt $attempt: $e');
      }
    }
    
    // Create fallback plan if all attempts fail
    return _createFallbackPlan(city, fromDate, toDate, places, foodVenues);
  }

  // ================= CREATE FALLBACK PLAN =================
  static Map<String, dynamic> _createFallbackPlan(
    String city,
    DateTime fromDate,
    DateTime toDate,
    List<Map<String, dynamic>> places,
    List<Map<String, dynamic>> foodVenues,
  ) {
    final days = toDate.difference(fromDate).inDays;
    List<Map<String, dynamic>> itinerary = [];
    
    // Get sample places
    final samplePlaces = places.take(6).toList();
    final restaurants = foodVenues.where((v) => 
      v['category']?.toString().toLowerCase() == 'restaurant').take(4).toList();
    final cafes = foodVenues.where((v) => 
      v['category']?.toString().toLowerCase() == 'café' || 
      v['category']?.toString().toLowerCase() == 'cafe').take(3).toList();
    
    for (int i = 1; i <= days; i++) {
      List<Map<String, dynamic>> activities = [];
      final currentDate = fromDate.add(Duration(days: i - 1));
      
      // Morning activity (History/Culture)
      if (samplePlaces.isNotEmpty) {
        final place = samplePlaces[(i - 1) % samplePlaces.length];
        activities.add({
          'title': place['name'],
          'category': place['category'] ?? 'Attraction',
          'description': place['description'] ?? 'Visit this attraction',
          'location': city,
          'cost': place['price_level'] == 0 ? 0.0 : 50.0,
          'duration': place['duration_minutes'] ?? 90,
        });
      }
      
      // Lunch
      if (restaurants.isNotEmpty) {
        final restaurant = restaurants[i % restaurants.length];
        activities.add({
          'title': 'Lunch at ${restaurant['name']}',
          'category': 'Food',
          'description': restaurant['description'] ?? 'Enjoy local cuisine',
          'location': city,
          'cost': 150.0,
          'duration': 90,
          'venue_name': restaurant['name'],
        });
      }
      
      // Afternoon activity (Nature/Adventure)
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
      
      // Dinner
      if (restaurants.length > 1) {
        final restaurant = restaurants[(i + 2) % restaurants.length];
        activities.add({
          'title': 'Dinner at ${restaurant['name']}',
          'category': 'Food',
          'description': restaurant['description'] ?? 'Fine dining experience',
          'location': city,
          'cost': 200.0,
          'duration': 120,
          'venue_name': restaurant['name'],
        });
      }
      
      // Evening coffee
      if (cafes.isNotEmpty) {
        final cafe = cafes[i % cafes.length];
        activities.add({
          'title': 'Coffee at ${cafe['name']}',
          'category': 'Food',
          'description': cafe['description'] ?? 'Relax with coffee',
          'location': city,
          'cost': 50.0,
          'duration': 60,
          'venue_name': cafe['name'],
        });
      }
      
      itinerary.add({
        'day': i,
        'date': currentDate.toIso8601String().split('T')[0],
        'activities': activities,
      });
    }
    
    // Calculate total cost
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

  // ================= MAP INTERESTS TO CATEGORIES =================
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

  // ================= STEP 2: Save Trip Details AND Generate COMPLETE Plan =================
  static Future<Map<String, dynamic>> saveTripDetails({
    required String preferenceId,
    required String budgetRange,
    required List<String> selectedInterests,
  }) async {
    final user = AuthService.currentUser;
    if (user == null) throw Exception('User not logged in');

    final double budget = _parseBudget(budgetRange);

    // Update preferences with budget
    await supabase
        .from('preferences')
        .update({'budget': budget})
        .eq('preference_id', preferenceId);

    // Save interests
    await supabase.from('interests').insert({
      'user_id': user.id,
      'preference_id': preferenceId,
      'selected_interests': selectedInterests,
    });

    // Get preference details
    final preferenceRaw = await supabase
        .from('preferences')
        .select()
        .eq('preference_id', preferenceId)
        .single();

    final preference = Map<String, dynamic>.from(preferenceRaw);
    final city = preference['city'];
    final fromDate = DateTime.parse(preference['start_date']);
    final toDate = DateTime.parse(preference['end_date']);

    // Create trip plan record
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

    // STEP 1: Fetch food venues
    print('🍽️ Fetching food venues for $city...');
    final foodVenues = await getFoodVenues(
      city: city,
      priceLevel: _mapBudgetToPriceLevel(budget),
    );
    
    // STEP 2: Fetch places based on interests
    print('🏛️ Fetching places for $city...');
    final categories = _mapInterestsToCategories(selectedInterests);
    final places = await getPlaces(
      city: city,
      categories: categories.isNotEmpty ? categories : null,
      maxPriceLevel: budget > 5000 ? 4 : 2,
    );
    
    print('✅ Found ${foodVenues.length} food venues and ${places.length} places');

    // STEP 3: Generate and validate COMPLETE AI trip plan
    print('🤖 Generating and validating COMPLETE AI trip plan...');
    final aiPlan = await generateAndValidatePlan(
      city: city,
      fromDate: fromDate,
      toDate: toDate,
      budget: budget,
      interests: selectedInterests,
      places: places,
      foodVenues: foodVenues,
    );
    print('✅ AI plan generated and validated');

    // STEP 4: Save AI response to database
    await supabase.from('ai_responses').insert({
      'trip_id': trip['trip_id'],
      'user_id': user.id,
      'full_response': aiPlan,
      'summary': aiPlan['summary'] ?? 'Trip to $city',
      'total_cost': _safeDouble(aiPlan['total_cost']),
    });

    // STEP 5: Update trip status
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

  // ================= STEP 3: Save AI Generated Trip (Legacy) =================
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
    
    // First get the trip plan
    final tripResponse = await supabase
        .from('trip_plans')
        .select('''
          *,
          preferences!inner (*)
        ''')
        .eq('trip_id', tripId)
        .maybeSingle();

    if (tripResponse == null) {
      print('❌ No trip found with ID: $tripId');
      return null;
    }

    print('✅ Trip details fetched successfully');
    
    // Get ALL ai_responses for this trip (there might be multiple)
    final aiResponses = await supabase
        .from('ai_responses')
        .select('*')
        .eq('trip_id', tripId)
        .order('created_at', ascending: false); // Get newest first
    
    print('📊 Found ${aiResponses.length} AI responses for this trip');
    
    // Add ai_responses to the trip data
    Map<String, dynamic> tripData = Map<String, dynamic>.from(tripResponse);
    tripData['ai_responses'] = aiResponses;
    
    // Get the preference_id from the response
    final preferenceId = tripData['preference_id'];
    
    if (preferenceId != null) {
      // Fetch interests separately using preference_id
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

  // ================= HELPER: Map Budget to Price Level =================
  static String _mapBudgetToPriceLevel(double budget) {
    if (budget < 1000) return 'budget';
    if (budget < 3000) return 'moderate';
    if (budget < 8000) return 'expensive';
    return 'luxury';
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