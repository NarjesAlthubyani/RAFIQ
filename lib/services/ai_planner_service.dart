import 'dart:convert';
import 'package:http/http.dart' as http;

class AIPlannerService {

  // Backend API URL
  static const String baseUrl = 'http://10.0.2.2:8000';

  // Request AI trip plan from backend
  static Future<Map<String, dynamic>> planTrip({
    required String city,
    required int days,
    required List<String> interests,
    required double budget,
  }) async {
    try {
      // Send POST request to backend
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/trip-planner/plan'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'city': city,
              'days': days,
              'interests': interests,
              'budget': budget,
            }),
          )
          .timeout(const Duration(seconds: 120));  

      // Return parsed JSON on success
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }

      // Return empty fallback on failure
      return {
        'days': [],
        'total_cost': 0,
        'summary': 'Failed to generate trip plan. Please try again.'
      };
    } catch (e) {
      // Return connection error fallback
      return {
        'days': [],
        'total_cost': 0,
        'summary': 'Could not connect to server. Please check your connection.'
      };
    }
  }
}