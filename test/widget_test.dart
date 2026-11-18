import 'package:flutter_test/flutter_test.dart';
import 'package:healthx/main.dart';

void main() {
  testWidgets('HealthXApp renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HealthXApp());
    expect(find.text('HealthX'), findsWidgets);
  });
}
