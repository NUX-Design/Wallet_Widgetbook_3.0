import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_dimensions.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_small_button.dart';
import 'package:mcp_test_app/widgets/v3/button/v3_small_button.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    TestThemeVariant theme = TestThemeVariant.light,
    VoidCallback? onPressed,
    V3SmallButtonVariant variant = V3SmallButtonVariant.primary,
    V3SmallButtonState state = V3SmallButtonState.defaultState,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
    String label = 'Label',
    String? semanticLabel,
  }) {
    return pumpTestApp(
      tester,
      Center(
        child: V3SmallButton(
          label: label,
          semanticLabel: semanticLabel,
          variant: variant,
          state: state,
          leadingIcon: leadingIcon,
          trailingIcon: trailingIcon,
          isLoading: isLoading,
          onPressed: onPressed,
        ),
      ),
      themeVariant: theme,
    );
  }

  ButtonStyle buttonStyle(WidgetTester tester) =>
      tester.widget<TextButton>(find.byType(TextButton).first).style!;

  testWidgets('maps all Primary Small states to Figma tokens', (tester) async {
    await pumpButton(tester, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.buttonPrimary,
    );

    await pumpButton(
      tester,
      state: V3SmallButtonState.active,
      onPressed: () {},
    );
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.borderTertiary,
    );

    await pumpButton(tester, state: V3SmallButtonState.disabled);
    expect(
      buttonStyle(tester).backgroundColor!.resolve({WidgetState.disabled}),
      V3ColorPalette.light.backgroundNeutral,
    );

    await pumpButton(tester, state: V3SmallButtonState.error, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.stateError,
    );
  });

  testWidgets(
    'maps all Outline Small states including dedicated error border',
    (tester) async {
      await pumpButton(
        tester,
        variant: V3SmallButtonVariant.outline,
        onPressed: () {},
      );
      var style = buttonStyle(tester);
      expect(style.side!.resolve({})?.color, V3ColorPalette.light.borderSlate);

      await pumpButton(
        tester,
        variant: V3SmallButtonVariant.outline,
        state: V3SmallButtonState.active,
        onPressed: () {},
      );
      style = buttonStyle(tester);
      expect(style.backgroundColor!.resolve({}), V3PrimitiveColors.blackAlpha5);
      expect(
        style.side!.resolve({})?.color,
        V3ColorPalette.light.contentNeutral,
      );

      await pumpButton(
        tester,
        variant: V3SmallButtonVariant.outline,
        state: V3SmallButtonState.error,
        onPressed: () {},
      );
      style = buttonStyle(tester);
      expect(
        style.side!.resolve({})?.color,
        V3ColorPalette.light.borderExtensionError,
      );
      expect(
        style.foregroundColor!.resolve({}),
        V3ColorPalette.light.stateError,
      );
    },
  );

  testWidgets('maps all Ghost Small states and underline style', (
    tester,
  ) async {
    for (final state in V3SmallButtonState.values) {
      await pumpButton(
        tester,
        variant: V3SmallButtonVariant.ghost,
        state: state,
        onPressed: state == V3SmallButtonState.disabled ? null : () {},
      );
      final style = buttonStyle(tester);
      expect(
        style.textStyle!.resolve({})?.decoration,
        TextDecoration.underline,
      );
      expect(style.padding!.resolve({}), EdgeInsets.zero);
    }
  });

  testWidgets('matches exact Small metrics and icon slots', (tester) async {
    await pumpButton(
      tester,
      leadingIcon: const Icon(Icons.add, key: ValueKey('left-icon')),
      trailingIcon: const Icon(
        Icons.arrow_forward,
        key: ValueKey('right-icon'),
      ),
      onPressed: () {},
    );
    final style = buttonStyle(tester);
    final textStyle = style.textStyle!.resolve({})!;
    expect(tester.getSize(find.byType(TextButton)).height, 36);
    expect(
      style.padding!.resolve({}),
      const EdgeInsets.symmetric(
        horizontal: V3Spacing.space16,
        vertical: V3Spacing.space2,
      ),
    );
    expect(textStyle.fontSize, V3Typography.labelSmall.fontSize);
    expect(textStyle.height, V3Typography.labelSmall.height);
    expect(textStyle.fontWeight, V3Typography.labelSmall.fontWeight);
    expect(
      tester.getSize(find.byKey(const ValueKey('left-icon'))),
      const Size.square(V3Spacing.space16),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('right-icon'))),
      const Size.square(V3Spacing.space16),
    );

    await pumpButton(
      tester,
      variant: V3SmallButtonVariant.ghost,
      onPressed: () {},
    );
    expect(tester.getSize(find.byType(TextButton)).height, V3Spacing.space20);
  });

  testWidgets('uses radius and shadow tokens for Outline Figma states', (
    tester,
  ) async {
    await pumpButton(
      tester,
      variant: V3SmallButtonVariant.outline,
      onPressed: () {},
    );
    var decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('v3-small-button-decoration')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(V3Radii.roundedFull));
    expect(decoration.boxShadow, V3PrimitiveShadows.sm);

    await pumpButton(
      tester,
      variant: V3SmallButtonVariant.outline,
      state: V3SmallButtonState.error,
      onPressed: () {},
    );
    decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('v3-small-button-decoration')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.boxShadow, isEmpty);
  });

  testWidgets('disabled and loading states do not invoke callbacks', (
    tester,
  ) async {
    var presses = 0;
    await pumpButton(
      tester,
      state: V3SmallButtonState.disabled,
      onPressed: () => presses++,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await pumpButton(tester, isLoading: true, onPressed: () => presses++);
    expect(
      find.byKey(const ValueKey('v3-small-button-progress')),
      findsOneWidget,
    );
    await tester.tap(find.byType(V3SmallButton));
    expect(presses, 0);
  });

  testWidgets('exposes localized semantics and active state', (tester) async {
    await pumpButton(
      tester,
      label: 'ดำเนินการต่อ',
      semanticLabel: 'ดำเนินการต่อไปยังขั้นตอนยืนยัน',
      state: V3SmallButtonState.active,
      onPressed: () {},
    );
    final finder = find.bySemanticsLabel('ดำเนินการต่อไปยังขั้นตอนยืนยัน');
    expect(finder, findsOneWidget);
    expect(
      tester.getSemantics(finder).hasFlag(ui.SemanticsFlag.isToggled),
      isTrue,
    );
  });

  testWidgets('selects Dark mode Small button semantics', (tester) async {
    await pumpButton(
      tester,
      theme: TestThemeVariant.dark,
      variant: V3SmallButtonVariant.outline,
      state: V3SmallButtonState.error,
      onPressed: () {},
    );
    final style = buttonStyle(tester);
    expect(style.foregroundColor!.resolve({}), V3ColorPalette.dark.stateError);
    expect(
      style.side!.resolve({})?.color,
      V3ColorPalette.dark.borderExtensionError,
    );
  });

  testWidgets('preview starts in Light and toggles the whole matrix to Dark', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const V3SmallButtonPreview(),
      wrapWithScaffold: false,
    );

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.light.backgroundPrimary,
    );
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.buttonPrimary,
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.dark.backgroundPrimary,
    );
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.dark.buttonPrimary,
    );
  });

  testWidgets(
    'preview renders V3LucideIcon at 16px for every variant and state',
    (tester) async {
      await pumpTestApp(
        tester,
        const V3SmallButtonPreview(),
        wrapWithScaffold: false,
      );

      final iconFinder = find.byType(V3LucideIcon);
      // 3 variants × 4 states × 2 icon slots (leading + trailing).
      final expectedCount =
          V3SmallButtonVariant.values.length *
          V3SmallButtonState.values.length *
          2;
      expect(iconFinder, findsNWidgets(expectedCount));

      for (var i = 0; i < expectedCount; i++) {
        expect(tester.getSize(iconFinder.at(i)), const Size.square(16));
      }
    },
  );

  testWidgets('Small label remains stable at large text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpButton(tester, label: 'Confirm', onPressed: () {});
    expect(tester.getSize(find.byType(TextButton)).height, 36);
    expect(tester.takeException(), isNull);
  });
}
