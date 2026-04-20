import 'dart:convert';
import 'package:http/http.dart' as http;

// Service responsible for fetching real-time weather data from OpenWeather API
class WeatherService {
  final String apiKey = 'bcddc9e189e09bd6625ad4b9ba6c4750'; // API key for authenticating requests with OpenWeather API

// Fetches the main weather condition for a given city
// Returns weather type (e.g., Rain, Clear, Clouds) or null if request fails
  Future<String?> getWeatherCondition(String city) async {
    final url ='https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // To get the weather conditions :Rain / Clear / Clouds / storm / Fog
      return data['weather'][0]['main'];
    } else {
      return null;
    }
  }
}