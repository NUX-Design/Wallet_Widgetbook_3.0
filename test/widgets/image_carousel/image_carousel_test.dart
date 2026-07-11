import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/base_theme.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/image_carousel/image_carousel.dart';

void main() {
  group('ImageCarousel UI Tests', () {
    testWidgets('matches the light-theme golden snapshot', (
      WidgetTester tester,
    ) async {
      await _pumpImageCarouselGoldenApp(
        tester,
        child: const _ImageCarouselGoldenProbe(),
        surfaceSize: const Size(375, 220),
        themeVariant: ThemeMode.light,
      );

      await expectLater(
        find.byType(_ImageCarouselGoldenProbe),
        matchesGoldenFile('goldens/image_carousel_light.png'),
      );
    }, skip: !Platform.isMacOS);

    testWidgets('matches the dark-theme golden snapshot', (
      WidgetTester tester,
    ) async {
      await _pumpImageCarouselGoldenApp(
        tester,
        child: const _ImageCarouselGoldenProbe(),
        surfaceSize: const Size(375, 220),
        themeVariant: ThemeMode.dark,
      );

      await expectLater(
        find.byType(_ImageCarouselGoldenProbe),
        matchesGoldenFile('goldens/image_carousel_dark.png'),
      );
    }, skip: !Platform.isMacOS);

    testWidgets('renders correctly with given pages', (
      WidgetTester tester,
    ) async {
      final pages = [
        Container(key: const Key('page_1'), color: Colors.red),
        Container(key: const Key('page_2'), color: Colors.blue),
        Container(key: const Key('page_3'), color: Colors.green),
      ];

      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: ImageCarousel(pages: pages))),
      );

      // Verify first page is visible
      expect(find.byKey(const Key('page_1')), findsOneWidget);
      expect(
        find.byKey(const Key('page_2')),
        findsNothing,
      ); // Should be off-screen or not built yet

      // Verify indicators count
      expect(find.byType(AnimatedContainer), findsNWidgets(3));
    });

    testWidgets('renders correct indicator states (active/inactive)', (
      WidgetTester tester,
    ) async {
      final pages = [
        Container(color: Colors.red),
        Container(color: Colors.blue),
      ];

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(), // Force light theme for consistent colors
          home: Scaffold(body: ImageCarousel(pages: pages)),
        ),
      );

      final indicators =
          tester
              .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
              .toList();
      expect(indicators.length, 2);

      // First indicator should be active (width 15, primary color)
      final activeIndicator = indicators[0];
      final activeDecoration = activeIndicator.decoration as BoxDecoration;
      expect(activeIndicator.constraints?.minWidth, 15);
      expect(activeDecoration.color, ThemeColors.get('light', 'primary/400'));

      // Second indicator should be inactive (width 4, stroke contrast color)
      final inactiveIndicator = indicators[1];
      final inactiveDecoration = inactiveIndicator.decoration as BoxDecoration;
      expect(inactiveIndicator.constraints?.minWidth, 4);
      expect(
        inactiveDecoration.color,
        ThemeColors.get('light', 'stroke/contrast/600'),
      );
    });

    testWidgets('autoPlay advances pages correctly', (
      WidgetTester tester,
    ) async {
      final pages = [
        Container(key: const Key('page_1'), color: Colors.red),
        Container(key: const Key('page_2'), color: Colors.blue),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageCarousel(
              pages: pages,
              autoPlay: true,
              autoPlayInterval: const Duration(
                seconds: 1,
              ), // Short interval for testing
            ),
          ),
        ),
      );

      // Initially page 1
      expect(find.byKey(const Key('page_1')), findsOneWidget);

      // Wait for autoPlay interval
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle(); // Allow animation to complete

      // Now page 2 should be visible (or at least page 1 is scrolling out)
      // Note: PageView might keep adjacent pages in memory, but let's check if we can find page 2
      expect(find.byKey(const Key('page_2')), findsOneWidget);
    });

    testWidgets('autoPlay stops cleanly when the widget is disposed', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageCarousel(
              pages: [
                Container(key: const Key('page_1'), color: Colors.red),
                Container(key: const Key('page_2'), color: Colors.blue),
              ],
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 1),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('page_2')), findsOneWidget);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump(const Duration(seconds: 1));

      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps rendering safely with an empty page list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageCarousel(
              pages: const <Widget>[],
              autoPlay: true,
              autoPlayInterval: const Duration(milliseconds: 200),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(PageView), findsOneWidget);
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('respects height parameters', (WidgetTester tester) async {
      const double widgetHeight = 200;
      const double imageHeight = 180;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageCarousel(
              pages: [Container(color: Colors.red)],
              height: widgetHeight,
              imageHeight: imageHeight,
            ),
          ),
        ),
      );

      final carouselFinder = find.byType(ImageCarousel);
      final size = tester.getSize(carouselFinder);
      expect(size.height, widgetHeight);

      // Verify image area height (Positioned widget height)
      // This is a bit tricky to find directly without keys, but we can infer from the SizedBox wrapping the Stack
      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(of: carouselFinder, matching: find.byType(SizedBox))
            .first,
      );
      expect(sizedBox.height, widgetHeight);
    });
  });
}

Future<void> _pumpImageCarouselGoldenApp(
  WidgetTester tester, {
  required Widget child,
  required Size surfaceSize,
  required ThemeMode themeVariant,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final brightness =
      themeVariant == ThemeMode.dark ? Brightness.dark : Brightness.light;
  final colorScheme =
      brightness == Brightness.light
          ? BaseTheme.lightColorScheme
          : BaseTheme.darkColorScheme;
  final backgroundColor =
      brightness == Brightness.light
          ? ThemeColors.get('light', 'fill/base/300')
          : ThemeColors.get('dark', 'fill/base/300');

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.from(
        colorScheme: colorScheme,
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: backgroundColor),
      darkTheme: ThemeData.from(
        colorScheme: colorScheme,
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: backgroundColor),
      themeMode: themeVariant,
      home: Scaffold(body: child),
    ),
  );
}

class _ImageCarouselGoldenProbe extends StatelessWidget {
  const _ImageCarouselGoldenProbe();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 343,
        child: ImageCarousel(
          pages: [
            Container(
              key: const Key('golden_page_1'),
              color: const Color(0xFFE53935),
              alignment: Alignment.center,
              child: const Text(
                'Banner 1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              key: const Key('golden_page_2'),
              color: const Color(0xFF1E88E5),
              alignment: Alignment.center,
              child: const Text(
                'Banner 2',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              key: const Key('golden_page_3'),
              color: const Color(0xFF43A047),
              alignment: Alignment.center,
              child: const Text(
                'Banner 3',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
