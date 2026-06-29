import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/input/full_amount_input.dart';

import 'support/widget_test_harness.dart';

final _amountAssets = PlaceholderAssetBundle(
  assetPaths: const <String>['lib/assets/images/cancel-circle.svg'],
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
  testWidgets('FullAmountInput renders the default state', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const FullAmountInput(),
      assetBundle: _amountAssets,
    );

    expect(find.text('฿'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('ท่านต้องฝากเงินอย่างน้อย 100 THB'), findsOneWidget);
    expect(_clearIconFinder(), findsNothing);

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FullAmountInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, ThemeColors.get('light', 'fill/base/300'));
    expect(decoration.border, isNotNull);
  });

  testWidgets('FullAmountInput shows error and clear button below minimum', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    String? changedValue;

    await pumpTestApp(
      tester,
      FullAmountInput(
        controller: controller,
        onChanged: (value) => changedValue = value,
      ),
      assetBundle: _amountAssets,
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '50');
    await tester.pump();

    expect(controller.text, '50');
    expect(changedValue, '50');
    expect(_clearIconFinder(), findsOneWidget);

    final infoText = tester.widget<Text>(
      find.text('ท่านต้องฝากเงินอย่างน้อย 100 THB'),
    );
    expect(infoText.style?.color, ThemeColors.get('light', 'text/base/danger'));

    final clearGesture = tester.widget<GestureDetector>(
      find.ancestor(
        of: _clearIconFinder(),
        matching: find.byType(GestureDetector),
      ),
    );
    clearGesture.onTap?.call();
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(changedValue, '');
    expect(_clearIconFinder(), findsNothing);
  });

  testWidgets('FullAmountInput handles success, focus, and disabled states', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const FullAmountInput(initialValue: '150'),
      assetBundle: _amountAssets,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final focusedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FullAmountInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final focusedDecoration = focusedContainer.decoration! as BoxDecoration;
    expect(
      focusedDecoration.border!.top.color,
      ThemeColors.get('light', 'primary/400'),
    );

    final successInfo = tester.widget<Text>(
      find.text('ท่านต้องฝากเงินอย่างน้อย 100 THB'),
    );
    expect(
      successInfo.style?.color,
      ThemeColors.get('light', 'text/base/success'),
    );

    await pumpTestApp(
      tester,
      const FullAmountInput(enabled: false, initialValue: '150'),
      assetBundle: _amountAssets,
    );
    await tester.pump();

    final disabledContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(FullAmountInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final disabledDecoration = disabledContainer.decoration! as BoxDecoration;
    expect(disabledDecoration.color, ThemeColors.get('light', 'fill/base/100'));
    expect(_clearIconFinder(), findsNothing);
  });
}
