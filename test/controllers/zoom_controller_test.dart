import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musically/controllers/zoom_controller.dart';

void main() {
  group('ZoomController', () {
    late ZoomController controller;

    setUp(() {
      controller = ZoomController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initializes with default values', () {
      expect(controller.zoom, equals(1.0));
      expect(controller.zoomLevel, equals(ZoomLevel.medium));
      expect(controller.minZoom, equals(0.5));
      expect(controller.maxZoom, equals(3.0));
    });

    test('initializes with custom initial zoom', () {
      final customController = ZoomController(initialZoom: 1.5);
      expect(customController.zoom, equals(1.5));
      expect(customController.zoomLevel, equals(ZoomLevel.medium));
      customController.dispose();
    });

    test('setZoom updates zoom value', () {
      controller.setZoom(1.5);
      expect(controller.zoom, equals(1.5));
      expect(controller.zoomLevel, equals(ZoomLevel.large));
    });

    test('setZoom clamps to min/max values', () {
      controller.setZoom(0.1); // Below min
      expect(controller.zoom, equals(0.5));

      controller.setZoom(5.0); // Above max
      expect(controller.zoom, equals(3.0));
    });

    test('setZoom notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);

      controller.setZoom(1.5);
      expect(notified, isTrue);
    });

    test('setZoom does not notify if value unchanged', () {
      controller.setZoom(1.0);
      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.setZoom(1.0);
      expect(notificationCount, equals(0));
    });

    test('zoomIn increases zoom by 0.1', () {
      controller.setZoom(1.0);
      controller.zoomIn();
      expect(controller.zoom, closeTo(1.1, 0.001));
    });

    test('zoomOut decreases zoom by 0.1', () {
      controller.setZoom(1.0);
      controller.zoomOut();
      expect(controller.zoom, closeTo(0.9, 0.001));
    });

    test('zoomIn respects max zoom', () {
      controller.setZoom(2.95);
      controller.zoomIn();
      expect(controller.zoom, equals(3.0));
    });

    test('zoomOut respects min zoom', () {
      controller.setZoom(0.55);
      controller.zoomOut();
      expect(controller.zoom, equals(0.5));
    });

    test('setZoomLevel changes zoom appropriately', () {
      controller.setZoomLevel(ZoomLevel.small);
      expect(controller.zoomLevel, equals(ZoomLevel.small));
      expect(controller.zoom, equals(0.8));

      controller.setZoomLevel(ZoomLevel.medium);
      expect(controller.zoom, equals(1.0));

      controller.setZoomLevel(ZoomLevel.large);
      expect(controller.zoom, equals(1.3));
    });

    test('updateScreenSize for phone portrait sets appropriate zoom', () {
      const size = Size(400, 800);
      controller.updateScreenSize(size, Orientation.portrait);

      expect(controller.screenSize, equals(size));
      expect(controller.zoom, closeTo(1.3, 0.01));
      expect(controller.zoomLevel, equals(ZoomLevel.medium));
    });

    test('updateScreenSize for phone landscape sets appropriate zoom', () {
      const size = Size(800, 400);
      controller.updateScreenSize(size, Orientation.landscape);

      expect(controller.zoom, closeTo(1.0, 0.01));
    });

    test('updateScreenSize for tablet portrait sets appropriate zoom', () {
      // Large screen (tablet size ~1024x768)
      const size = Size(1024, 768);
      controller.updateScreenSize(size, Orientation.portrait);

      expect(controller.zoom, closeTo(0.9, 0.01));
      expect(controller.zoomLevel, equals(ZoomLevel.small));
    });

    test('updateScreenSize for tablet landscape sets appropriate zoom', () {
      const size = Size(1024, 768);
      controller.updateScreenSize(size, Orientation.landscape);

      expect(controller.zoom, closeTo(0.7, 0.01));
      expect(controller.zoomLevel, equals(ZoomLevel.small));
    });

    test('updateScreenSize notifies listeners when size changes', () {
      var notified = false;
      controller.addListener(() => notified = true);

      const size = Size(400, 800);
      controller.updateScreenSize(size, Orientation.portrait);

      expect(notified, isTrue);
    });

    test('updateScreenSize does not notify if size unchanged', () {
      const size = Size(400, 800);
      controller.updateScreenSize(size, Orientation.portrait);

      var notificationCount = 0;
      controller.addListener(() => notificationCount++);

      controller.updateScreenSize(size, Orientation.portrait);
      expect(notificationCount, equals(0));
    });

    test('resetToOptimal recalculates zoom based on screen', () {
      const size = Size(400, 800);
      controller.updateScreenSize(size, Orientation.portrait);

      controller.setZoom(2.0);
      expect(controller.zoom, equals(2.0));

      controller.resetToOptimal();
      expect(controller.zoom, closeTo(1.3, 0.01));
    });

    test('getVisibleMeasureCount returns correct values', () {
      controller.setZoom(0.6);
      expect(controller.getVisibleMeasureCount(), equals(5));

      controller.setZoom(0.9);
      expect(controller.getVisibleMeasureCount(), equals(3));

      controller.setZoom(1.2);
      expect(controller.getVisibleMeasureCount(), equals(2));

      controller.setZoom(1.5);
      expect(controller.getVisibleMeasureCount(), equals(1));
    });

    test('getZoomPercentage formats correctly', () {
      controller.setZoom(1.0);
      expect(controller.getZoomPercentage(), equals('100%'));

      controller.setZoom(1.5);
      expect(controller.getZoomPercentage(), equals('150%'));

      controller.setZoom(0.75);
      expect(controller.getZoomPercentage(), equals('75%'));
    });
  });

  group('ZoomLevel', () {
    test('has correct display names', () {
      expect(ZoomLevel.small.displayName, equals('Small'));
      expect(ZoomLevel.medium.displayName, equals('Medium'));
      expect(ZoomLevel.large.displayName, equals('Large'));
    });

    test('has correct icons', () {
      expect(ZoomLevel.small.icon, equals(Icons.zoom_out));
      expect(ZoomLevel.medium.icon, equals(Icons.fit_screen));
      expect(ZoomLevel.large.icon, equals(Icons.zoom_in));
    });
  });

  group('AdaptiveZoomBuilder', () {
    testWidgets('builds with zoom value', (WidgetTester tester) async {
      final controller = ZoomController();
      double? receivedZoom;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: AdaptiveZoomBuilder(
                controller: controller,
                builder: (context, zoom) {
                  receivedZoom = zoom;
                  return Text('Zoom: $zoom');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(receivedZoom, isNotNull);
      expect(receivedZoom, equals(controller.zoom));

      controller.dispose();
    });

    testWidgets('updates when controller changes', (WidgetTester tester) async {
      final controller = ZoomController();
      final receivedZooms = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: AdaptiveZoomBuilder(
                controller: controller,
                builder: (context, zoom) {
                  receivedZooms.add(zoom);
                  return Text('Zoom: $zoom');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(receivedZooms.contains(1.0), isTrue);

      controller.setZoom(1.5);
      await tester.pump();

      expect(controller.zoom, equals(1.5));

      controller.dispose();
    });
  });

  group('ZoomControls', () {
    testWidgets('displays zoom percentage', (WidgetTester tester) async {
      final controller = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(controller: controller),
          ),
        ),
      );

      expect(find.text('100%'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      controller.dispose();
    });

    testWidgets('zoom in button works', (WidgetTester tester) async {
      final controller = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      expect(controller.zoom, closeTo(1.1, 0.001));
      expect(find.text('110%'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('zoom out button works', (WidgetTester tester) async {
      final controller = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(controller: controller),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();

      expect(controller.zoom, closeTo(0.9, 0.001));
      expect(find.text('90%'), findsOneWidget);

      controller.dispose();
    });

    testWidgets('zoom in button disabled at max zoom', (WidgetTester tester) async {
      final controller = ZoomController();
      controller.setZoom(3.0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(controller: controller),
          ),
        ),
      );

      final addButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.add),
      );
      expect(addButton.onPressed, isNull);

      controller.dispose();
    });

    testWidgets('zoom out button disabled at min zoom', (WidgetTester tester) async {
      final controller = ZoomController();
      controller.setZoom(0.5);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(controller: controller),
          ),
        ),
      );

      final removeButton = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.remove),
      );
      expect(removeButton.onPressed, isNull);

      controller.dispose();
    });

    testWidgets('can hide percentage', (WidgetTester tester) async {
      final controller = ZoomController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomControls(
              controller: controller,
              showPercentage: false,
            ),
          ),
        ),
      );

      expect(find.text('100%'), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      controller.dispose();
    });
  });
}
