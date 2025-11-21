import 'package:flutter_test/flutter_test.dart';
import 'package:derm_assist/main.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const DermAssistApp());
    
    // Verify splash screen appears
    expect(find.text('DermAssist'), findsOneWidget);
  });
}
