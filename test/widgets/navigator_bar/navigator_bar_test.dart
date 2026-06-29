import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart';

import '../../support/widget_test_harness.dart';

BoxDecoration _navigatorBarDecoration(WidgetTester tester) {
  final containers =
      tester.widgetList<Container>(find.descendant(
        of: find.byType(NavigatorBar),
        matching: find.byType(Container),
      )).toList();

  final decoratedContainer = containers.firstWhere(
    (container) =>
        container.decoration is BoxDecoration &&
        (container.decoration! as BoxDecoration).border != null,
  );
  return decoratedContainer.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renders localized labels and the scan action', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: SizedBox.shrink(),
        bottomNavigationBar: NavigatorBar(),
      ),
      assetStrategy: TestAssetStrategy.placeholderAssets,
      assetBundle: PlaceholderAssetBundle(
        assetPaths: <String>[
          'lib/assets/images/home-09.svg',
          'lib/assets/images/wallet-add-02.svg',
          'lib/assets/images/exchange-03.svg',
          'lib/assets/images/list-setting.svg',
          'lib/assets/images/iris-scan.svg',
        ],
      ),
      locale: const Locale('en'),
      themeVariant: TestThemeVariant.light,
      wrapWithScaffold: false,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    final decoration = _navigatorBarDecoration(tester);
    expect(
      decoration.color,
      ThemeColors.get('light', 'fill/base/300').withValues(alpha: 0.9),
    );
  });

  testWidgets('uses the dark theme and reserves the safe-area spacer', (
    WidgetTester tester,
  ) async {
    tester.view.viewPadding = const FakeViewPadding(bottom: 20);
    addTearDown(tester.view.resetViewPadding);

    await pumpTestApp(
      tester,
      const Scaffold(
        body: SizedBox.shrink(),
        bottomNavigationBar: NavigatorBar(),
      ),
      assetStrategy: TestAssetStrategy.placeholderAssets,
      assetBundle: PlaceholderAssetBundle(
        assetPaths: <String>[
          'lib/assets/images/home-09.svg',
          'lib/assets/images/wallet-add-02.svg',
          'lib/assets/images/exchange-03.svg',
          'lib/assets/images/list-setting.svg',
          'lib/assets/images/iris-scan.svg',
        ],
      ),
      locale: const Locale('th'),
      themeVariant: TestThemeVariant.dark,
      wrapWithScaffold: false,
    );

    expect(find.text('หน้าหลัก'), findsOneWidget);
    expect(find.text('ฝากเงิน'), findsOneWidget);
    expect(find.text('แปลงเงิน'), findsOneWidget);
    expect(find.text('ตั้งค่า'), findsOneWidget);

    final containers =
        tester.widgetList<Container>(find.descendant(
          of: find.byType(NavigatorBar),
          matching: find.byType(Container),
        )).toList();
    final bottomSpacer = containers.firstWhere(
      (container) => container.color != null && container.decoration == null,
    );

    expect(
      tester.getSize(find.byWidget(bottomSpacer)).height,
      closeTo(20 / tester.view.devicePixelRatio, 0.001),
    );
    expect(
      bottomSpacer.color,
      ThemeColors.get('dark', 'fill/base/300').withValues(alpha: 0.9),
    );
  });

  testWidgets('applies custom opacity to the main bar background', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Scaffold(
        body: SizedBox.shrink(),
        bottomNavigationBar: NavigatorBar(opacity: 0.5),
      ),
      assetStrategy: TestAssetStrategy.placeholderAssets,
      assetBundle: PlaceholderAssetBundle(
        assetPaths: <String>[
          'lib/assets/images/home-09.svg',
          'lib/assets/images/wallet-add-02.svg',
          'lib/assets/images/exchange-03.svg',
          'lib/assets/images/list-setting.svg',
          'lib/assets/images/iris-scan.svg',
        ],
      ),
      locale: const Locale('en'),
      themeVariant: TestThemeVariant.light,
      wrapWithScaffold: false,
    );

    final decoration = _navigatorBarDecoration(tester);
    expect(decoration.color?.alpha, 128);
  });
}
