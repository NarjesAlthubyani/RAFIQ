import '../models/alert_model.dart';
import '../services/auth_service.dart';
// WeatherAdapter is responsible for converting raw weather conditions
// into structured AlertModel objects used by the application.
class WeatherAdapter {
// WeatherAdapter is responsible for converting raw weather conditions
// into structured AlertModel objects used by the application.
  static AlertModel? convertToAlert(String? condition, String city, String userId) {
    if (condition == null) return null;

    // Turn it into an Alert only if the weather is important
    final c = condition.toLowerCase();

    if (c.contains('rain') ||
        c.contains('storm') ||
        c.contains('dust') ||
        c.contains('sand') ||
        c.contains('fog')) {
      // Create a structured alert object for storage and display
      return AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        title: "Weather Alert",
        description: "Bad weather expected: $condition in $city",
        type: "weather",
        isRead: false,
        createdAt: DateTime.now(),
      );
    }

    return null;
  }
}