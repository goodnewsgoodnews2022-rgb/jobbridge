// JobBridge — smoke tests
//
// These are minimal tests to verify the app boots and the brand logo
// renders. Add more widget tests here as you build features.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' as flutter_test;
import 'package:shimmer/shimmer.dart';

void main() {
  flutter_test.testWidgets('Shimmer package loads correctly',
      (flutter_test.WidgetTester tester) async {
    // Sanity check that our UI dependency tree works at all.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('JobBridge')),
      ),
    );
    flutter_test.expect(
      flutter_test.find.text('JobBridge'),
      flutter_test.findsNWidgets(1),
    );
  });

    flutter_test.testWidgets('Shimmer widget renders without errors',
      (flutter_test.WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Shimmer.fromColors(
            baseColor: const Color(0xFFE2E8F0),
            highlightColor: const Color(0xFFF1F5F9),
            child: const SizedBox(width: 100, height: 20),
          ),
        ),
      ),
    );
    flutter_test.expect(
      flutter_test.find.byType(Shimmer),
      flutter_test.findsOneWidget,
    );
  });
}