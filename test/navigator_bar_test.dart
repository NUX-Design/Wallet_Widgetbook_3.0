import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart';

import 'support/widget_test_harness.dart';

final _navAssets = PlaceholderAssetBundle(
  assetPaths: const <String>[
    'lib/assets/images/home-09.svg',
    'lib/assets/images/wallet-add-02.svg',
    'lib/assets/images/exchange-03.svg',
    'lib/assets/images/list-setting.svg',
    'lib/assets/images/iris-scan.svg',
  ],
);

Finder _svgAsset(String assetPath) {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName == assetPath;
  });
}

void main() {
  testWidgets('NavigatorBar renders the five navigation targets', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const Scaffold(bottomNavigationBar: NavigatorBar()),
      themeVariant: TestThemeVariant.light,
      locale: const Locale('en'),
      assetBundle: _navAssets,
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Deposit'), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/home-09.svg'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/wallet-add-02.svg'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/exchange-03.svg'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/list-setting.svg'), findsOneWidget);
    expect(_svgAsset('lib/assets/images/iris-scan.svg'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);

    final scanButtonRect = tester.getRect(find.byType(ElevatedButton));
    final viewportWidth =
        tester.view.physicalSize.width / tester.view.devicePixelRatio;
    expect(scanButtonRect.center.dx, closeTo(viewportWidth / 2, 20));
  });

  testWidgets(
    'NavigatorBar switches labels by locale and keeps safe area padding',
    (WidgetTester tester) async {
      await pumpTestApp(
        tester,
        MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
          child: const Scaffold(
            bottomNavigationBar: NavigatorBar(opacity: 0.5),
          ),
        ),
        themeVariant: TestThemeVariant.dark,
        locale: const Locale('th'),
        assetBundle: _navAssets,
      );

      expect(find.text('หน้าหลัก'), findsOneWidget);
      expect(find.text('ฝากเงิน'), findsOneWidget);
      expect(find.text('แปลงเงิน'), findsOneWidget);
      expect(find.text('ตั้งค่า'), findsOneWidget);

      final opacityContainer = tester.widget<Container>(
        find.byWidgetPredicate((widget) {
          return widget is Container &&
              widget.decoration is BoxDecoration &&
              ((widget.decoration as BoxDecoration).border is Border);
        }),
      );
      final decoration = opacityContainer.decoration! as BoxDecoration;
      expect(decoration.color?.opacity, closeTo(0.5, 0.01));

      final bottomPaddingContainer = find.byWidgetPredicate((widget) {
        return widget is Container &&
            widget.constraints is BoxConstraints &&
            (widget.constraints as BoxConstraints).minHeight == 24 &&
            (widget.constraints as BoxConstraints).maxHeight == 24 &&
            widget.color != null;
      });
      expect(bottomPaddingContainer, findsOneWidget);
    },
  );
}
