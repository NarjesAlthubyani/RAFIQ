import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'bcddc9e189e09bd6625ad4b9ba6c4750';

  Future<String?> getWeatherCondition(String city) async {
    final url ='https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // To get the weather conditions :Rain / Clear / Clouds / Thunderstorm / Fog
      return data['weather'][0]['main'];
    } else {
      return null;
    }
  }
}