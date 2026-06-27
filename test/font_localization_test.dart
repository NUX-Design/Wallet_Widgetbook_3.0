import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/main.dart';
import 'package:mcp_test_app/providers/theme_provider.dart';
import 'package:mcp_test_app/providers/locale_provider.dart'; // Import your main.dart where MyApp and providers are defined

void main() {
  group('Font Localization Tests', () {
    testWidgets('Noto Sans Thai is used for Thai locale', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final localeProvider = LocaleProvider();
      localeProvider.setLocale(const Locale('th'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Get the TextTheme from the MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final textTheme = materialApp.theme?.textTheme;

      // Verify that a specific text style (e.g., bodyMedium) uses Noto Sans Thai
      expect(textTheme?.bodyMedium?.fontFamily, startsWith('NotoSansThai'));
      expect(textTheme?.headlineMedium?.fontFamily, startsWith('NotoSansThai'));
      expect(textTheme?.titleLarge?.fontFamily, startsWith('NotoSansThai'));
    });

    testWidgets('Noto Sans is used for English locale', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final localeProvider = LocaleProvider();
      localeProvider.setLocale(const Locale('en'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Get the TextTheme from the MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final textTheme = materialApp.theme?.textTheme;

      // Verify that a specific text style (e.g., bodyMedium) uses Noto Sans
      expect(textTheme?.bodyMedium?.fontFamily, startsWith('NotoSans'));
      expect(textTheme?.headlineMedium?.fontFamily, startsWith('NotoSans'));
      expect(textTheme?.titleLarge?.fontFamily, startsWith('NotoSans'));
      expect(
        textTheme?.bodyMedium?.fontFamily,
        isNot(startsWith('NotoSansThai')),
      );
    });

    testWidgets('Noto Sans Myanmar is used for Myanmar locale', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final localeProvider = LocaleProvider();
      localeProvider.setLocale(const Locale('my'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (context) => ThemeProvider()),
            ChangeNotifierProvider.value(value: localeProvider),
          ],
          child: const MyApp(),
        ),
      );

      await tester.pumpAndSettle();

      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      final textTheme = materialApp.theme?.textTheme;

      expect(textTheme?.bodyMedium?.fontFamily, startsWith('NotoSansMyanmar'));
      expect(
        textTheme?.headlineMedium?.fontFamily,
        startsWith('NotoSansMyanmar'),
      );
      expect(textTheme?.titleLarge?.fontFamily, startsWith('NotoSansMyanmar'));
    });
  });
}
