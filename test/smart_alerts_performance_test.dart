import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/adapters/weather_adapter.dart';
import 'package:rafiq/models/alert_model.dart';

void main() {

  group('Smart Alerts - Performance Test', () {

    test('measure average alert generation time', () {

      // test cases (city + weather condition)
      final testCases = [
        ['Jeddah', 'Rain'],
        ['Riyadh', 'Storm'],
        ['Al_Ula', 'Fog'],
      ];

      // number of repetitions per case
      const repeatCount = 5;

      double overallTotal = 0;

      print('\n------------------------------------------');
      print('City       Average Response Time (µs)');
      print('------------------------------------------');

      for (var testCase in testCases) {

        final city = testCase[0];
        final condition = testCase[1];

        int totalTime = 0;

        // repeat test 
        for (int i = 0; i < repeatCount; i++) {

          // start performance measurement
          final stopwatch = Stopwatch()..start();

          // call alert generation logic
          final alert = WeatherAdapter.convertToAlert(
            condition,
            city,
            'test_user',
          );

          stopwatch.stop();

          // add execution time
          totalTime += stopwatch.elapsedMicroseconds;

          // validation check
          expect(alert, isNotNull);
          expect(alert, isA<AlertModel>());
        }

        // calculate average time
        final averageTime = totalTime / repeatCount;

        overallTotal += averageTime;

        // print result per city
        print('$city          ${averageTime.toStringAsFixed(2)}');
      }

      // overall average
      final overallAverage = overallTotal / testCases.length;

      print('------------------------------------------');
      print(
        'Overall Average Response Time: '
        '${overallAverage.toStringAsFixed(2)} µs'
      );
      print('------------------------------------------');

    });

  });

}