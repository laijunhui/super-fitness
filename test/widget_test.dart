// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:super_fitness/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SuperFitnessApp());

    // Verify that the app loads without errors
    await tester.pump();
  });
}
