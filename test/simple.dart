import 'dart:convert';
import 'dart:io';

void main() async {
  final flutterPath = Platform.isWindows ? 'flutter.bat' : 'flutter';

  final result = await Process.run(
    flutterPath,
    ['test', '--reporter=json', 'test/smart_alerts_integration_test.dart'],
  );

  final lines = LineSplitter.split(result.stdout.toString());

  final Set<String> testNames = {};

  for (var line in lines) {
    if (line.trim().isEmpty) continue;
    
    try {
      final data = jsonDecode(line);
      
      if (data['type'] == 'testStart') {
        final name = data['test']['name'] as String;
        
        // Skip the loading test and any test with test_interest_selection
        if (!name.contains('loading ') && !name.contains('test_interest_selection')) {
          // Extract just the last part of the test name (the actual test description)
          final parts = name.split(' ');
          final testDescription = parts.last;
          testNames.add(testDescription);
        }
      }
    } catch (e) {
      continue;
    }
  }

  for (var test in testNames) {
    print('  ✅ $test');
  }

  print('\n  ✅ Total: ${testNames.length} tests found\n');
}