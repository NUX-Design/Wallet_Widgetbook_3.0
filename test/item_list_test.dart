import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/item_list/item_list.dart';

import 'support/widget_test_harness.dart';

void main() {
  testWidgets('ItemList renders common item with iconPath and onTap', (
    WidgetTester tester,
  ) async {
    var tapped = false;

    await pumpTestApp(
      tester,
      ItemList(
        title: 'History',
        iconPath: 'lib/assets/images/Transaction History.svg',
        onTap: () => tapped = true,
      ),
      assetBundle: PlaceholderAssetBundle(
        assetPaths: const <String>[
          'lib/assets/images/Transaction History.svg',
          'lib/assets/images/arrow-right-01.svg',
        ],
      ),
    );

    expect(find.text('History'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(2));

    await tester.tap(find.byType(ItemList));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('ItemList renders trailing text before default arrow', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const ItemList(title: 'Language', trailingText: 'English'),
    );

    expect(find.text('English'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('ItemList renders selected and unselected radio state', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Column(
        children: [
          ItemList(title: 'Option 1', isSelected: true),
          ItemList(title: 'Option 2', isSelected: false),
        ],
      ),
      assetBundle: PlaceholderAssetBundle(
        assetPaths: const <String>[
          'lib/assets/images/radio_button_check.svg',
          'lib/assets/images/radio_button_uncheck.svg',
        ],
      ),
    );

    expect(find.text('Option 1'), findsOneWidget);
    expect(find.text('Option 2'), findsOneWidget);
    expect(find.byType(SvgPicture), findsNWidgets(4));
  });

  testWidgets('ItemList renders transaction states and amount precedence', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Column(
        children: [
          ItemList(
            type: ItemListType.transactionIn,
            title: 'Received from Victor',
            subtitle: '2025-10-06 12:00:53',
            amount: '+50,000.00 THB',
          ),
          ItemList(
            type: ItemListType.transactionOut,
            title: 'Transfer to Victor',
            subtitle: '2025-10-06 12:00:53',
            amount: '-50,000.00 THB',
          ),
          ItemList(
            type: ItemListType.transactionOut,
            title: 'Overflow case',
            trailingText: 'Should not show',
            amount: '-1.00 THB',
          ),
        ],
      ),
    );

    expect(find.text('Received from Victor'), findsOneWidget);
    expect(find.text('Transfer to Victor'), findsOneWidget);
    expect(find.text('+50,000.00 THB'), findsOneWidget);
    expect(find.text('-50,000.00 THB'), findsOneWidget);
    expect(find.text('Should not show'), findsNothing);
  });

  testWidgets('ItemList truncates long common titles with ellipsis', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const ItemList(
        title: 'A very long title that should not overflow beyond one line',
      ),
    );

    final titleText = tester.widget<Text>(
      find.textContaining('A very long title'),
    );
    expect(titleText.maxLines, 1);
    expect(titleText.overflow, TextOverflow.ellipsis);
  });
}
