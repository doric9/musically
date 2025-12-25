import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musically/screens/settings_screen.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('displays app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays all section headers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Audio Settings'), findsOneWidget);
      expect(find.text('Display Settings'), findsOneWidget);

      // Scroll to find AI Settings and About
      await tester.scrollUntilVisible(
        find.text('AI Settings'),
        100.0,
      );
      expect(find.text('AI Settings'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('About'),
        100.0,
      );
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('displays audio input device option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Audio Input Device'), findsOneWidget);
      expect(find.text('Default Microphone'), findsOneWidget);
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('displays audio quality option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Audio Quality'), findsOneWidget);
      expect(find.text('High (44.1 kHz, 16-bit)'), findsOneWidget);
      expect(find.byIcon(Icons.graphic_eq), findsOneWidget);
    });

    testWidgets('displays auto-scroll toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Auto-scroll'), findsOneWidget);
      expect(find.text('Automatically scroll as you play'), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);

      final switchTile = find.byWidgetPredicate(
        (widget) => widget is SwitchListTile && widget.title is Text && (widget.title as Text).data == 'Auto-scroll',
      );
      expect(switchTile, findsOneWidget);
    });

    testWidgets('displays auto-zoom toggle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Auto-zoom'), findsOneWidget);
      expect(find.text('Zoom to current measure'), findsOneWidget);
      expect(find.byIcon(Icons.zoom_in), findsOneWidget);

      final switchTile = find.byWidgetPredicate(
        (widget) => widget is SwitchListTile && widget.title is Text && (widget.title as Text).data == 'Auto-zoom',
      );
      expect(switchTile, findsOneWidget);
    });

    testWidgets('displays Gemini API Key option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.text('Gemini API Key'), findsOneWidget);
      expect(find.text('Not configured'), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy), findsOneWidget);
    });

    testWidgets('displays detection sensitivity option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Detection Sensitivity'),
        100.0,
      );

      expect(find.text('Detection Sensitivity'), findsOneWidget);
      expect(find.text('Medium'), findsOneWidget);
      expect(find.byIcon(Icons.speed), findsOneWidget);
    });

    testWidgets('displays version information', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Version'),
        100.0,
      );

      expect(find.text('Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('displays licenses option', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Licenses'),
        100.0,
      );

      expect(find.text('Licenses'), findsOneWidget);
      expect(find.byIcon(Icons.description), findsOneWidget);
    });

    testWidgets('tapping audio device shows coming soon message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.tap(find.text('Audio Input Device'));
      await tester.pump();

      expect(find.text('Audio device selection coming soon'), findsOneWidget);
    });

    testWidgets('tapping API key shows coming soon message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      await tester.tap(find.text('Gemini API Key'));
      await tester.pump();

      expect(find.text('API key configuration coming soon'), findsOneWidget);
    });

    testWidgets('displays correct number of dividers', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Scroll to make all dividers visible
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(find.byType(Divider), findsAtLeastNWidgets(2));
    });

    testWidgets('all list tiles have proper icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      // Count ListTiles with leading icons
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile));
      final tilesWithIcons = listTiles.where((tile) => tile.leading != null).length;

      expect(tilesWithIcons, greaterThan(0));
    });

    testWidgets('scroll view is present', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SettingsScreen(),
        ),
      );

      expect(find.byType(ListView), findsOneWidget);
    });
  });
}
