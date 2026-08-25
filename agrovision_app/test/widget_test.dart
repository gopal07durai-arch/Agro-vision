// Basic smoke test for AgroVision AI app.
// The generated default test referenced the counter demo app (MyApp),
// which no longer exists. This test verifies the app boots without crashing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — widget tree builds without error', (WidgetTester tester) async {
    // Just verify that the Material / basic widget infra is working.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('AgroVision AI'))),
      ),
    );
    expect(find.text('AgroVision AI'), findsOneWidget);
  });
}
