import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rafiq/services/supabase_config.dart'; 

class EdgeFunctionService {
  static const String _functionName = 'generate-trip';
  
  static Future<Map<String, dynamic>> generateTrip({
    required String destination,
    required DateTime fromDate,
    required DateTime toDate,
    required String budgetRange,
    required List<String> interests,
  }) async {
    
    print('🚀 Calling Edge Function for $destination...');
    
    try {
      final response = await supabase.functions.invoke(
        _functionName,
        body: {
          'destination': destination,
          'fromDate': fromDate.toIso8601String().split('T')[0],
          'toDate': toDate.toIso8601String().split('T')[0],
          'budgetRange': budgetRange,
          'interests': interests,
        },
      );

      print('✅ Edge Function response received');
      
      if (response.data == null) {
        throw Exception('No data received from edge function');
      }
      
      return Map<String, dynamic>.from(response.data);
      
    } catch (e) {
      print('❌ Edge Function error: $e');
      return _getMockResponse(destination, toDate.difference(fromDate).inDays, interests);
    }
  }
  
  static Map<String, dynamic> _getMockResponse(
    String destination, 
    int days, 
    List<String> interests
  ) {
    final now = DateTime.now();
    
    return {
      'summary': 'Experience the beautiful city of $destination with this curated itinerary.',
      'total_cost': 2500.0,
      'itinerary': List.generate(days, (index) {
        return {
          'day': index + 1,
          'date': now.add(Duration(days: index)).toIso8601String().split('T')[0],
          'activities': [
            {
              'title': 'Activity ${index + 1}',
              'description': 'Description of activity ${index + 1}',
              'category': 'General',
              'location': destination,
              'cost': 0.0,
              'duration': 2.0,
            }
          ],
          'meals': {
            'breakfast': 'Local Cafe',
            'lunch': 'Restaurant',
            'dinner': 'Fine Dining',
          },
          'accommodation': 'Hotel in $destination',
        };
      }),
      'hotels': [
        {'name': 'Hotel 1', 'price_per_night': 500.0, 'rating': 4.5},
      ],
      'restaurants': [
        {'name': 'Restaurant 1', 'cuisine': 'Local', 'price_range': 'medium'},
      ],
      'tips': [
        'Enjoy your trip!',
        'Respect local customs',
      ],
    };
  }
}