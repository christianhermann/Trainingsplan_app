import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/core/widgets/ronnie_loading_indicator.dart';

void main() {
  group('RonnieLoadingIndicator Widget Tests', () {
    testWidgets('renders animated Ronnie badge and catchphrase pill', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RonnieLoadingIndicator(
              message: 'TEST LOADING',
            ),
          ),
        ),
      );

      // Verify widget elements exist
      expect(find.byType(RonnieLoadingIndicator), findsOneWidget);
      expect(find.text('TEST LOADING'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      // Pump 1 second of animation
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RonnieLoadingIndicator), findsOneWidget);
    });

    testWidgets('compact mode renders correctly without overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RonnieLoadingIndicator.compact(size: 32),
          ),
        ),
      );

      expect(find.byType(RonnieLoadingIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });
  });
}
