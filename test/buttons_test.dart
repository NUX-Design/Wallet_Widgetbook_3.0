import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/button/buttons.dart';

import 'support/widget_test_harness.dart';

Future<void> _pumpButton(
  WidgetTester tester, {
  required ButtonType type,
  required bool enabled,
  required String text,
  VoidCallback? onPressed,
  TestThemeVariant themeVariant = TestThemeVariant.dark,
}) {
  return pumpTestApp(
    tester,
    Center(
      child: Buttons(
        text: text,
        type: type,
        enabled: enabled,
        onPressed: onPressed,
      ),
    ),
    themeVariant: themeVariant,
  );
}

void main() {
  testWidgets('Primary button renders the light theme style', (
    WidgetTester tester,
  ) async {
    await _pumpButton(
      tester,
      type: ButtonType.primary,
      enabled: true,
      text: 'Continue',
      themeVariant: TestThemeVariant.light,
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Buttons),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('light', 'primary/400'));
    expect(decoration.border, isNull);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Secondary button renders the dark theme bordered style', (
    WidgetTester tester,
  ) async {
    await _pumpButton(
      tester,
      type: ButtonType.secondary,
      enabled: true,
      text: 'Secondary',
      themeVariant: TestThemeVariant.dark,
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Buttons),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;
    final text = tester.widget<Text>(find.text('Secondary'));

    expect(decoration.color, ThemeColors.get('dark', 'fill/contrast/600'));
    expect(decoration.border, isNotNull);
    expect(text.style?.color, ThemeColors.get('dark', 'text/base/600'));
  });

  testWidgets(
    'Amount button strips the currency symbol and animates on press',
    (WidgetTester tester) async {
      var pressed = false;

      await _pumpButton(
        tester,
        type: ButtonType.amount,
        enabled: true,
        text: '฿1,250.00',
        onPressed: () => pressed = true,
        themeVariant: TestThemeVariant.dark,
      );

      expect(find.text('1,250.00'), findsOneWidget);
      expect(find.text('฿1,250.00'), findsNothing);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Buttons)),
      );
      await tester.pump(const Duration(milliseconds: 60));

      final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
      expect(scale.scale, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(pressed, isTrue);
    },
  );

  testWidgets('Secondary disabled button matches the Figma disabled style', (
    WidgetTester tester,
  ) async {
    await _pumpButton(
      tester,
      type: ButtonType.secondary,
      enabled: false,
      text: 'Secondary Disabled',
      themeVariant: TestThemeVariant.dark,
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(Buttons),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('dark', 'alt/base/600'));
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNotEmpty);

    final text = tester.widget<Text>(find.text('Secondary Disabled'));
    expect(text.style?.color, ThemeColors.get('dark', 'text/base/400'));
  });

  testWidgets(
    'Primary disabled button matches the light theme disabled style',
    (WidgetTester tester) async {
      await _pumpButton(
        tester,
        type: ButtonType.primary,
        enabled: false,
        text: 'Primary Disabled',
        themeVariant: TestThemeVariant.light,
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(Buttons),
          matching: find.byType(Container),
        ),
      );
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, ThemeColors.get('light', 'fill/base/300'));
      expect(decoration.border, isNotNull);

      final text = tester.widget<Text>(find.text('Primary Disabled'));
      expect(text.style?.color, ThemeColors.get('light', 'text/base/400'));
    },
  );

  testWidgets('Disabled button does not invoke onPressed', (
    WidgetTester tester,
  ) async {
    var pressed = false;

    await _pumpButton(
      tester,
      type: ButtonType.secondary,
      enabled: false,
      text: 'Secondary Disabled',
      onPressed: () => pressed = true,
    );

    await tester.tap(find.byType(Buttons));
    await tester.pumpAndSettle();

    expect(pressed, isFalse);
  });
}
