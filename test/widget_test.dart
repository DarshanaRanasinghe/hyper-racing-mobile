import 'package:flutter_test/flutter_test.dart';
import 'package:hyper_racing/main.dart';

void main() {
  testWidgets('App loads login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const HyperRacingApp());

    // Login button exists
    expect(find.text('Login'), findsOneWidget);

    // Register text exists
    expect(find.text('Register'), findsOneWidget);

    // Email field hint exists
    expect(find.text('Email'), findsOneWidget);
  });
}
