import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_country_code.dart';

import 'support/widget_test_harness.dart';

List<CountryCode> _countries() => const <CountryCode>[
  CountryCode(
    name: 'Thailand',
    code: '+66',
    flagAsset: 'lib/assets/images/flag_th.svg',
  ),
  CountryCode(
    name: 'Japan',
    code: '+81',
    flagAsset: 'lib/assets/images/flag_th.svg',
  ),
  CountryCode(
    name: 'Germany',
    code: '+49',
    flagAsset: 'lib/assets/images/flag_th.svg',
  ),
];

void main() {
  testWidgets('DrawerCountryCode filters by country name and code', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      DrawerCountryCode(title: 'Country Code', countries: _countries()),
      themeVariant: TestThemeVariant.dark,
    );
    await tester.pumpAndSettle();

    expect(find.text('Thailand'), findsOneWidget);
    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Germany'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ja');
    await tester.pumpAndSettle();

    expect(find.text('Japan'), findsOneWidget);
    expect(find.text('Thailand'), findsNothing);
    expect(find.text('Germany'), findsNothing);

    await tester.enterText(find.byType(TextField), '+49');
    await tester.pumpAndSettle();

    expect(find.text('Germany'), findsOneWidget);
    expect(find.text('Japan'), findsNothing);
    expect(find.text('Thailand'), findsNothing);
  });

  testWidgets('DrawerCountryCode shows the empty state for no matches', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      DrawerCountryCode(title: 'Country Code', countries: _countries()),
      themeVariant: TestThemeVariant.dark,
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No results found'), findsOneWidget);
    expect(find.text('Please try again'), findsOneWidget);
  });

  testWidgets('DrawerCountryCode.show selects a country and closes', (
    WidgetTester tester,
  ) async {
    CountryCode? selectedCountry;
    var closeCount = 0;

    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                DrawerCountryCode.show(
                  context,
                  title: 'Country Code',
                  countries: _countries(),
                  onCountrySelected: (country) => selectedCountry = country,
                  onClose: () => closeCount += 1,
                );
              },
              child: const Text('Open country drawer'),
            ),
          );
        },
      ),
      themeVariant: TestThemeVariant.dark,
    );

    await tester.tap(find.text('Open country drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Country Code'), findsOneWidget);

    await tester.tap(find.text('Japan'));
    await tester.pumpAndSettle();

    expect(selectedCountry?.name, 'Japan');
    expect(selectedCountry?.code, '+81');
    expect(closeCount, 0);
    expect(find.text('Country Code'), findsNothing);
  });

  testWidgets('DrawerCountryCode close icon invokes onClose and dismisses', (
    WidgetTester tester,
  ) async {
    var closeCount = 0;

    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                DrawerCountryCode.show(
                  context,
                  title: 'Country Code',
                  countries: _countries(),
                  onClose: () => closeCount += 1,
                );
              },
              child: const Text('Open country drawer'),
            ),
          );
        },
      ),
      themeVariant: TestThemeVariant.dark,
    );

    await tester.tap(find.text('Open country drawer'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close).last);
    await tester.pumpAndSettle();

    expect(closeCount, 1);
    expect(find.text('Country Code'), findsNothing);
  });
}
