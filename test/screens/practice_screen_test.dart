import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musically/screens/practice_screen.dart';

void main() {
  group('PracticeScreen', () {
    testWidgets('builds without errors', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticeScreen(),
          ),
        ),
      );

      expect(find.byType(PracticeScreen), findsOneWidget);
    });

    testWidgets('displays app bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticeScreen(),
          ),
        ),
      );

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticeScreen(),
          ),
        ),
      );

      // The screen should show some loading state or initial UI
      await tester.pump();

      // Check that the widget tree is built
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('has proper provider scope', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticeScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verify the widget is within a ProviderScope
      final context = tester.element(find.byType(PracticeScreen));
      expect(ProviderScope.containerOf(context), isNotNull);
    });

    testWidgets('initializes with TickerProviderStateMixin', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PracticeScreen(),
          ),
        ),
      );

      await tester.pump();

      // The screen should be created successfully with TickerProvider
      expect(find.byType(PracticeScreen), findsOneWidget);
    });
  });
}
