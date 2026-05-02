import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/adapters/weather_adapter.dart';
import 'package:rafiq/models/alert_model.dart';

void main() {

  group('WeatherAdapter Test', () {

    // Valid Input (Rain)
    test('should return Alert when condition is Rain', () {

      // input
      final result = WeatherAdapter.convertToAlert('Rain', 'Jeddah', 'test_user');

      // expected: should NOT be null
      expect(result, isNotNull);

      // check type
      expect(result, isA<AlertModel>());

      // check main values
      expect(result!.title, 'Weather Alert');
      expect(result.type, 'weather');
      expect(result.isRead, false);

      // description should contain Rain
      expect(result.description.contains('Rain'), true);
    });

    // Valid Input (Storm)
    test('should return Alert when condition is Storm', () {

      // input
      final result = WeatherAdapter.convertToAlert('Storm', 'Jeddah', 'test_user');

      // expected: Alert exists
      expect(result, isNotNull);
    });

    // Invalid Input (Clear)
    test('should return null when condition is Clear', () {

      // input
      final result = WeatherAdapter.convertToAlert('Clear', 'Jeddah', 'test_user');

      // expected: null (not important weather)
      expect(result, isNull);
    });

    // Invalid Input (null)
    test('should return null when condition is null', () {

      // input
      final result = WeatherAdapter.convertToAlert(null, 'Jeddah', 'test_user');

      // expected: null
      expect(result, isNull);
    });

    // Case test (uppercase)
    test('should work with uppercase condition', () {

      // input
      final result = WeatherAdapter.convertToAlert('RAIN', 'Jeddah', 'test_user');

      // expected: still returns Alert
      expect(result, isNotNull);
    });

  });
}