import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/adapters/weather_adapter.dart';
import 'package:rafiq/models/alert_model.dart';

void main() {

  group('Smart Alerts Integration Test', () {

    /// Test 1: Full flow (severe weather → alert created)
    test('should generate alert from weather condition flow', () {

      // Step 1: simulate weather condition (represents API layer)
      const condition = "rain";
      const city = "Jeddah";

      // Step 2: pass data to WeatherAdapter (business logic layer)
      final alert = WeatherAdapter.convertToAlert(condition, city, 'test_user');

      // Step 3: verify AlertModel is created (data layer)
      expect(alert, isNotNull);
      expect(alert, isA<AlertModel>());

      // Step 4: verify data correctness inside the model
      expect(alert!.type, "weather");
      expect(alert.title, "Weather Alert");
      expect(alert.description.contains(city), true);

    });

    /// Test 2: Normal weather → no alert
    test('should not generate alert for normal weather', () {

      // Step 1: simulate non-critical weather condition
      const condition = "sunny";
      const city = "Jeddah";

      // Step 2: process through adapter
      final alert = WeatherAdapter.convertToAlert(condition, city, 'test_user');

      // Step 3: verify no alert is created
      expect(alert, isNull);

    });

    /// Test 3: Case insensitive handling
    test('should handle uppercase weather condition correctly', () {

      // Step 1: simulate uppercase input
      const condition = "STORM";
      const city = "Jeddah";

      // Step 2: pass through adapter
      final alert = WeatherAdapter.convertToAlert(condition, city, 'test_user');

      // Step 3: verify alert still created
      expect(alert, isNotNull);
      expect(alert!.description.contains("STORM"), true);

    });

  });

}