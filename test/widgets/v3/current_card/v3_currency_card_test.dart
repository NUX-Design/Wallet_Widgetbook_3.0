import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/widgets/v3/current_card/preview_v3_currency_card.dart';
import 'package:mcp_test_app/widgets/v3/current_card/v3_currency_card.dart';

void main() {
  Future<double> pumpCard(
    WidgetTester tester,
    CurrencyCardVariant variant,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: V3CurrencyCard(
            flag: '🇬🇧',
            currencyCode: 'GBP',
            variant: variant,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getSize(find.byType(V3CurrencyCard)).width;
  }

  for (final variant in [CurrencyCardVariant.hide, CurrencyCardVariant.error]) {
    testWidgets('$variant has a 74px minimum width', (tester) async {
      final width = await pumpCard(tester, variant);

      debugPrint('$variant runtime width: ${width.toStringAsFixed(2)}px');
      expect(width, greaterThanOrEqualTo(74));
    });
  }

  testWidgets('always renders two decimal digits', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: V3CurrencyCard(
          flag: '🇯🇵',
          currencyCode: 'JPY',
          integerPart: '1,250,000',
          decimalPart: '',
        ),
      ),
    );

    expect(find.text('.00'), findsOneWidget);
  });

  testWidgets('variant action updates the main and multiple currency cards', (
    tester,
  ) async {
    await tester.pumpWidget(const V3CurrencyCardPreviewApp());

    await tester.tap(find.text('Hide').first);
    await tester.pumpAndSettle();
    expect(find.text('.**'), findsNWidgets(5));

    await tester.tap(find.text('Error').first);
    await tester.pumpAndSettle();
    expect(find.text('-'), findsNWidgets(5));
  });

  testWidgets('tapping a currency card updates the display card and status', (
    tester,
  ) async {
    await tester.pumpWidget(const V3CurrencyCardPreviewApp());

    await tester.tap(find.text('USD').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('v3-currency-card-main')), findsOneWidget);
    expect(find.text('USD'), findsNWidgets(2));
    expect(find.text('Tapped currency: USD'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('v3-currency-card-main')),
        matching: find.text('USD'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('v3-currency-card-main')));
    await tester.pumpAndSettle();
    expect(find.text('Tapped currency: USD'), findsOneWidget);
  });
}
