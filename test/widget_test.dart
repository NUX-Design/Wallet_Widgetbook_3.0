// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/main.dart';
import 'package:mcp_test_app/providers/theme_provider.dart';
import 'package:mcp_test_app/providers/locale_provider.dart';

void main() {
  group('App and Theme Tests', () {
    testWidgets('App should render home page', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => LocaleProvider()),
          ],
          child: const MyApp(),
        ),
      );
      // Verify that the HomePage is rendered
      expect(find.byType(HomePage), findsOneWidget);

      // Verify some text from the HomePage to ensure it's rendered correctly
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });

    testWidgets('Theme should toggle between light and dark', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider(create: (context) => LocaleProvider()),
          ],
          child: const MyApp(),
        ),
      );

      // Initial theme is dark (from main.dart)
      expect(
        Provider.of<ThemeProvider>(
          tester.element(find.byType(MyApp)),
          listen: false,
        ).themeMode,
        ThemeMode.dark,
      );

      // Tap the switch to toggle theme
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify theme is light
      expect(
        Provider.of<ThemeProvider>(
          tester.element(find.byType(MyApp)),
          listen: false,
        ).themeMode,
        ThemeMode.light,
      );

      // Tap the switch again to toggle theme back to dark
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Verify theme is dark
      expect(
        Provider.of<ThemeProvider>(
          tester.element(find.byType(MyApp)),
          listen: false,
        ).themeMode,
        ThemeMode.dark,
      );
    });
  });
}
