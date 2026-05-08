import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/adapters/weather_adapter.dart';
import 'package:rafiq/models/alert_model.dart';

/// Fake DB layer (simulated persistence)
class FakeDb {
  static final List<AlertModel> alerts = [];

  static AlertModel save(AlertModel alert) {
    alerts.add(alert);
    return alert;
  }

  static void clear() {
    alerts.clear();
  }
}

void main() {

  group('Smart Alerts - Integration Test', () {

    test('should process full flow: API -> Adapter -> DB', () {

      FakeDb.clear();

      //  simulate API layer
      const condition = "rain";
      const city = "Jeddah";

      //  business logic layer
      final alert = WeatherAdapter.convertToAlert(
        condition,
        city,
        'test_user'
      );

      //  persistence layer (integration happens here)
      final savedAlert = alert != null ? FakeDb.save(alert) : null;

      // assertions (end-to-end validation)
      expect(savedAlert, isNotNull);
      expect(savedAlert, isA<AlertModel>());

      expect(FakeDb.alerts.length, 1);

      final stored = FakeDb.alerts.first;
      expect(stored.title, "Weather Alert");
      expect(stored.description.contains(city), true);
    });

    test('should NOT create alert for normal weather', () {

  FakeDb.clear();

  const condition = "clear";
  const city = "Jeddah";

  final alert = WeatherAdapter.convertToAlert(condition, city, 'test_user');

  final savedAlert = alert != null ? FakeDb.save(alert) : null;

  expect(savedAlert, isNull);
  expect(FakeDb.alerts.isEmpty, true);
});

test('should handle uppercase weather condition', () {

  FakeDb.clear();

  const condition = "RAIN";
  const city = "Jeddah";

  final alert = WeatherAdapter.convertToAlert(condition, city, 'test_user');

  final savedAlert = alert != null ? FakeDb.save(alert) : null;

  expect(savedAlert, isNotNull);
  expect(FakeDb.alerts.length, 1);
});

  });

}