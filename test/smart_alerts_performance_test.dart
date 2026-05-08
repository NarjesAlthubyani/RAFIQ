import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/adapters/weather_adapter.dart';
import 'package:rafiq/models/alert_model.dart';

void main() {

  group('Smart Alerts - Performance Test', () {

    test('measure alert generation performance per case', () {

      final testCases = [
        ['Jeddah', 'Rain'],
        ['Riyadh', 'Storm'],
        ['Al_Ula', 'Fog'],
        ['Jeddah', 'Clear'],
      ];
         // print for show results
      print('\nCity       Condition     Time (ms)');
      print('------------------------------------');

      for (var testCase in testCases) {

        final city = testCase[0];
        final condition = testCase[1];

        // start measuring performance
        final stopwatch = Stopwatch()..start();
        //call business logic (adapter layer)
        final alert = WeatherAdapter.convertToAlert(
          condition,
          city,
          'test_user',
        );

        stopwatch.stop();

        final duration = stopwatch.elapsedMilliseconds;

        //print performance result per case
        print('$city     $condition       $duration');

        // correctness check (logic validation)
        if (condition == 'Clear') {
          expect(alert, isNull);
        } else {
          expect(alert, isNotNull);
          expect(alert, isA<AlertModel>());
        }
      }

    });

  });

}