import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIAdapter {
  static const String _geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent';
  
  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];

  Future<List<Map<String, dynamic>>> selectActivities({
    required String city,
    required List<String> interests,
    required double budget,
    required int days,
    required List<Map<String, dynamic>> availablePlaces,
    required List<Map<String, dynamic>> availableFoodVenues,
  }) async {
    final topPlaces = availablePlaces.take(25).toList();
    final topFood = availableFoodVenues.take(10).toList();
     
    final prompt = '''
You are a travel planner for $city, Saudi Arabia.

USER PREFERENCES:
- Interests: ${interests.join(', ')}
- Budget: $budget SAR
- Trip duration: $days days

AVAILABLE ATTRACTIONS:
${topPlaces.map((p) => "- ${p['name']} (${p['category']}) | Price level: ${p['price_level'] ?? 2} | Duration: ${p['duration'] ?? 90} min").join('\n')}

AVAILABLE RESTAURANTS & CAFES:
${topFood.map((f) => "- ${f['name']} (${f['category']}) | Price level: ${f['price_level'] ?? 2}").join('\n')}

TASK: Select activities for a $days-day trip.

RULES:
- Select 2-3 attractions per day (total ${days * 2} to ${days * 3} attractions)
- Select 1 breakfast place (cafe/bakery) per day
- Select 1 lunch restaurant per day  
- Select 1 dinner restaurant per day
- DO NOT repeat the same place
- Match user interests when possible

Return ONLY valid JSON. No extra text:
{
  "selected": [
    {"name": "place name", "type": "attraction", "day": 1},
    {"name": "cafe name", "type": "breakfast", "day": 1},
    {"name": "restaurant name", "type": "lunch", "day": 1},
    {"name": "restaurant name", "type": "dinner", "day": 1}
  ]
}
''';

    final response = await _sendPrompt(prompt);
    
    return _parseAIResponse(response);
  }

  Future<List<String>> reorderActivities(
    List<String> activityNames,
    String city,
  ) async {
    if (activityNames.length <= 1) return activityNames;
    
    final prompt = '''
Order these places in $city by best visiting time:

${activityNames.join(', ')}

Return ONLY JSON array: ["place1", "place2", "place3"]
''';

    final response = await _sendPrompt(prompt);
    
    try {
      final startIndex = response.indexOf('[');
      final endIndex = response.lastIndexOf(']') + 1;
      if (startIndex != -1 && endIndex > startIndex) {
        final jsonStr = response.substring(startIndex, endIndex);
        return List<String>.from(jsonDecode(jsonStr));
      }
    } catch (e) {
    }
    
    return activityNames;
  }

  Future<String> generateTripSummary(
    String city,
    List<String> interests,
    int days,
  ) async {
    final prompt = "Write one sentence (max 20 words) summarizing a $days-day trip to $city for ${interests.join(', ')} fans.";
    final response = await _sendPrompt(prompt);
    return response.isEmpty ? 'An amazing $days-day trip to $city!' : response;
  }

  Future<String> _sendPrompt(String prompt) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return '';
    }
    
    final url = '$_geminiApiUrl?key=${_apiKey}';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{
            'parts': [{'text': prompt}]
          }],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 1500,
          }
        }),
      );
      
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      } else {
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  List<Map<String, dynamic>> _parseAIResponse(String response) {
    try {
      final startIndex = response.indexOf('{');
      final endIndex = response.lastIndexOf('}') + 1;
      
      if (startIndex != -1 && endIndex > startIndex) {
        final jsonStr = response.substring(startIndex, endIndex);
        final data = jsonDecode(jsonStr);
        
        if (data['selected'] != null) {
          return List<Map<String, dynamic>>.from(data['selected']);
        }
      }
    } catch (e) {
    }
    return [];
  }
}