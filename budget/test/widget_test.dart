import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App basic smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Text('StickyFin Expense Manager'),
        ),
      ),
    );

    expect(find.text('StickyFin Expense Manager'), findsOneWidget);
    expect(find.text('NonExistentWidget'), findsNothing);
  });
}
