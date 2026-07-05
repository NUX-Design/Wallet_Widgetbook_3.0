import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/input/full_amount_input.dart';
import 'package:mcp_test_app/widgets/input/mobile_code_input.dart';
import 'package:mcp_test_app/widgets/input/search_input.dart';

import '../../support/widget_test_harness.dart';

BoxDecoration _boxDecorationFor(WidgetTester tester, Finder rootFinder) {
  final container = tester
      .widgetList<Container>(
        find.descendant(of: rootFinder, matching: find.byType(Container)),
      )
      .firstWhere((container) => container.decoration is BoxDecoration);
  return container.decoration! as BoxDecoration;
}

Finder _clearIconFinder(Finder rootFinder) {
  return find.descendant(
    of: rootFinder,
    matching: find.byWidgetPredicate(
      (widget) => widget is SvgPicture && widget.width == 16,
    ),
  );
}

GestureDetector _svgGestureDetector(WidgetTester tester, Finder rootFinder) {
  return tester
      .widgetList<GestureDetector>(
        find.descendant(of: rootFinder, matching: find.byType(GestureDetector)),
      )
      .firstWhere((gestureDetector) => gestureDetector.child is SvgPicture);
}

void main() {
  group('FullAmountInput', () {
    testWidgets('renders, validates amount, and clears text', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final changedValues = <String>[];

      await pumpTestApp(
        tester,
        FullAmountInput(
          controller: controller,
          infoText: 'ท่านต้องฝากเงินอย่างน้อย 100 THB',
          onChanged: changedValues.add,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>['lib/assets/images/cancel-circle.svg'],
        ),
      );

      final rootFinder = find.byType(FullAmountInput);

      expect(find.text('฿'), findsOneWidget);
      expect(find.text('ท่านต้องฝากเงินอย่างน้อย 100 THB'), findsOneWidget);
      expect(_clearIconFinder(rootFinder), findsNothing);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '50');
      await tester.pump();

      expect(controller.text, '50');
      expect(changedValues, contains('50'));
      expect(
        (_boxDecorationFor(tester, rootFinder).border as Border).top.color,
        ThemeColors.get('light', 'text/base/danger'),
      );
      expect(
        tester
            .widget<Text>(find.text('ท่านต้องฝากเงินอย่างน้อย 100 THB'))
            .style
            ?.color,
        ThemeColors.get('light', 'text/base/danger'),
      );
      expect(_clearIconFinder(rootFinder), findsOneWidget);

      _svgGestureDetector(tester, rootFinder).onTap?.call();
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changedValues.last, isEmpty);
      expect(_clearIconFinder(rootFinder), findsNothing);
    });

    testWidgets('accepts decimal input and reports the typed value', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final changedValues = <String>[];

      await pumpTestApp(
        tester,
        FullAmountInput(controller: controller, onChanged: changedValues.add),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '123.45');
      await tester.pump();

      expect(controller.text, '123.45');
      expect(changedValues.last, '123.45');
      expect(find.text('123.45'), findsOneWidget);
    });

    testWidgets('uses disabled styling and hides the clear control', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const FullAmountInput(
          initialValue: '500',
          enabled: false,
          infoText: 'Disabled',
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>['lib/assets/images/cancel-circle.svg'],
        ),
      );

      final rootFinder = find.byType(FullAmountInput);
      final decoration = _boxDecorationFor(tester, rootFinder);

      expect(decoration.color, ThemeColors.get('light', 'fill/base/100'));
      expect(
        (decoration.border as Border).top.color,
        ThemeColors.get('light', 'stroke/base/200'),
      );
      expect(_clearIconFinder(rootFinder), findsNothing);
    });
  });

  group('MobileCodeInput', () {
    testWidgets('renders selector, enforces digits, and clears text', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final changedValues = <String>[];

      await pumpTestApp(
        tester,
        MobileCodeInput(
          controller: controller,
          maxLength: 8,
          onChanged: changedValues.add,
          onCountryCodeTap: () {},
        ),
        locale: const Locale('th'),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/flag_th.svg',
            'lib/assets/images/arrow-down-01.svg',
            'lib/assets/images/cancel-circle.svg',
          ],
        ),
      );

      final rootFinder = find.byType(MobileCodeInput);

      expect(find.text('+66'), findsOneWidget);
      expect(find.text('เบอร์มือถือ'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '12ab34567890');
      await tester.pump();

      expect(controller.text, '12345678');
      expect(changedValues.last, '12345678');
      expect(find.text('8/8'), findsOneWidget);
      expect(_clearIconFinder(rootFinder), findsOneWidget);

      _svgGestureDetector(tester, rootFinder).onTap?.call();
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changedValues.last, isEmpty);
      expect(find.text('0/8'), findsOneWidget);
    });

    testWidgets('shows error state and invokes country code tap', (
      WidgetTester tester,
    ) async {
      var countryCodeTapped = false;

      await pumpTestApp(
        tester,
        MobileCodeInput(
          hasError: true,
          errorText: 'เบอร์มือถือไม่ถูกต้อง',
          onCountryCodeTap: () => countryCodeTapped = true,
        ),
        locale: const Locale('th'),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/flag_th.svg',
            'lib/assets/images/arrow-down-01.svg',
            'lib/assets/images/cancel-circle.svg',
          ],
        ),
      );

      final rootFinder = find.byType(MobileCodeInput);
      final decoration = _boxDecorationFor(tester, rootFinder);

      expect(decoration.border, isNotNull);
      expect(
        (decoration.border! as Border).top.color,
        ThemeColors.get('light', 'text/base/danger'),
      );
      expect(find.text('เบอร์มือถือไม่ถูกต้อง'), findsOneWidget);
      expect(find.text('0/10'), findsOneWidget);

      tester
          .widgetList<GestureDetector>(
            find.descendant(
              of: rootFinder,
              matching: find.byType(GestureDetector),
            ),
          )
          .firstWhere((gestureDetector) => gestureDetector.child is Row)
          .onTap
          ?.call();
      await tester.pump();

      expect(countryCodeTapped, isTrue);
    });
  });

  group('SearchInput', () {
    testWidgets('renders search controls and syncs controller text', (
      WidgetTester tester,
    ) async {
      final controller = TextEditingController();
      final changedValues = <String>[];

      await pumpTestApp(
        tester,
        SearchInput(controller: controller, onChanged: changedValues.add),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/search-02.svg',
            'lib/assets/images/cancel-circle.svg',
          ],
        ),
      );

      final rootFinder = find.byType(SearchInput);

      expect(find.text('Search'), findsOneWidget);
      expect(
        find.descendant(of: rootFinder, matching: find.byType(SvgPicture)),
        findsOneWidget,
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'flutter');
      await tester.pump();

      expect(controller.text, 'flutter');
      expect(changedValues.last, 'flutter');
      expect(
        find.descendant(of: rootFinder, matching: find.byType(SvgPicture)),
        findsNWidgets(2),
      );
      expect(
        (_boxDecorationFor(tester, rootFinder).border as Border).top.color,
        ThemeColors.get('light', 'primary/400'),
      );

      _svgGestureDetector(tester, rootFinder).onTap?.call();
      await tester.pump();

      expect(controller.text, isEmpty);
      expect(changedValues.last, isEmpty);
      expect(
        find.descendant(of: rootFinder, matching: find.byType(SvgPicture)),
        findsOneWidget,
      );
    });
  });
}
