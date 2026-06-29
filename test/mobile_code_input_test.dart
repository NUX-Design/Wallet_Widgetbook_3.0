import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/input/mobile_code_input.dart';

import 'support/widget_test_harness.dart';

final _mobileAssets = PlaceholderAssetBundle(
  assetPaths: const <String>[
    'lib/assets/images/flag_th.svg',
    'lib/assets/images/arrow-down-01.svg',
    'lib/assets/images/cancel-circle.svg',
  ],
);

Finder _clearIconFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'lib/assets/images/cancel-circle.svg';
  });
}

void main() {
  testWidgets('MobileCodeInput renders selector, placeholder, and counter', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const MobileCodeInput(),
      locale: const Locale('en'),
      assetBundle: _mobileAssets,
    );

    expect(find.text('+66'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('0/10'), findsOneWidget);
    expect(_clearIconFinder(), findsNothing);
  });

  testWidgets('MobileCodeInput filters digits and respects maxLength', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    String? changedValue;
    bool tappedCountry = false;

    await pumpTestApp(
      tester,
      MobileCodeInput(
        controller: controller,
        maxLength: 5,
        onChanged: (value) => changedValue = value,
        onCountryCodeTap: () => tappedCountry = true,
      ),
      locale: const Locale('en'),
      assetBundle: _mobileAssets,
    );

    await tester.tap(find.text('+66'));
    expect(tappedCountry, isTrue);

    await tester.enterText(find.byType(TextField), '12a3456789');
    await tester.pump();

    expect(controller.text, '12345');
    expect(changedValue, '12345');
    expect(find.text('5/5'), findsOneWidget);
    expect(_clearIconFinder(), findsOneWidget);
  });

  testWidgets('MobileCodeInput supports focus and error state', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const MobileCodeInput(
        hasError: true,
        errorText: 'เบอร์มือถือไม่ถูกต้อง',
        initialValue: '12',
      ),
      locale: const Locale('th'),
      assetBundle: _mobileAssets,
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(MobileCodeInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(
      decoration.border!.top.color,
      ThemeColors.get('light', 'text/base/danger'),
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final focusedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(MobileCodeInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final focusedDecoration = focusedContainer.decoration! as BoxDecoration;
    expect(
      focusedDecoration.border!.top.color,
      ThemeColors.get('light', 'primary/400'),
    );
    expect(find.text('เบอร์มือถือไม่ถูกต้อง'), findsOneWidget);
  });
}
