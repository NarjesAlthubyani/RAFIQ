import '../models/alert_model.dart';
import '../services/auth_service.dart';

class WeatherAdapter {
  static AlertModel? convertToAlert(String? condition, String city) {
    if (condition == null) return null;

    // Turn it into an Alert only if the weather is important
    if (condition == 'Rain' ||
        condition == 'Thunderstorm' ||
        condition == 'Dust' ||
        condition == 'Sand' ||
        condition == 'Fog') {

      return AlertModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: AuthService.currentUser!.id,
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