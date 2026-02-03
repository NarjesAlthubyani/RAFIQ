import 'package:flutter_test/flutter_test.dart';
import 'package:rafiq/main.dart';

void main() {
  testWidgets('App builds', (WidgetTester tester) async {
    await tester.pumpWidget(const RafiqApp());
    expect(find.byType(RafiqApp), findsOneWidget);
  });
}
