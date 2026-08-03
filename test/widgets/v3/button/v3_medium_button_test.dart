import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_dimensions.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_medium_button.dart';
import 'package:mcp_test_app/widgets/v3/button/v3_medium_button.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    TestThemeVariant theme = TestThemeVariant.light,
    VoidCallback? onPressed,
    V3MediumButtonVariant variant = V3MediumButtonVariant.primary,
    V3MediumButtonState state = V3MediumButtonState.defaultState,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
    String label = 'Label',
    String? semanticLabel,
  }) {
    return pumpTestApp(
      tester,
      Center(
        child: V3MediumButton(
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

  testWidgets('maps all Primary Medium states to Figma tokens', (tester) async {
    await pumpButton(tester, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.buttonPrimary,
    );

    await pumpButton(
      tester,
      state: V3MediumButtonState.active,
      onPressed: () {},
    );
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.borderTertiary,
    );

    await pumpButton(tester, state: V3MediumButtonState.disabled);
    expect(
      buttonStyle(tester).backgroundColor!.resolve({WidgetState.disabled}),
      V3ColorPalette.light.backgroundNeutral,
    );

    await pumpButton(
      tester,
      state: V3MediumButtonState.error,
      onPressed: () {},
    );
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.stateError,
    );
  });

  testWidgets(
    'maps all Outline Medium states including dedicated error border',
    (tester) async {
      await pumpButton(
        tester,
        variant: V3MediumButtonVariant.outline,
        onPressed: () {},
      );
      var style = buttonStyle(tester);
      expect(style.side!.resolve({})?.color, V3ColorPalette.light.borderSlate);

      await pumpButton(
        tester,
        variant: V3MediumButtonVariant.outline,
        state: V3MediumButtonState.active,
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
        variant: V3MediumButtonVariant.outline,
        state: V3MediumButtonState.error,
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

  testWidgets('maps all Ghost Medium states and underline style', (
    tester,
  ) async {
    for (final state in V3MediumButtonState.values) {
      await pumpButton(
        tester,
        variant: V3MediumButtonVariant.ghost,
        state: state,
        onPressed: state == V3MediumButtonState.disabled ? null : () {},
      );
      final style = buttonStyle(tester);
      expect(
        style.textStyle!.resolve({})?.decoration,
        TextDecoration.underline,
      );
      expect(style.padding!.resolve({}), EdgeInsets.zero);
    }
  });

  testWidgets('matches exact Medium metrics and icon slots', (tester) async {
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
    expect(tester.getSize(find.byType(TextButton)).height, V3Spacing.space40);
    expect(
      style.padding!.resolve({}),
      const EdgeInsets.symmetric(
        horizontal: V3Spacing.space24,
        vertical: V3Spacing.space8,
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
      variant: V3MediumButtonVariant.ghost,
      onPressed: () {},
    );
    expect(tester.getSize(find.byType(TextButton)).height, V3Spacing.space20);
  });

  testWidgets('uses radius and shadow tokens for Outline Figma states', (
    tester,
  ) async {
    await pumpButton(
      tester,
      variant: V3MediumButtonVariant.outline,
      onPressed: () {},
    );
    var decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('v3-medium-button-decoration')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(V3Radii.roundedFull));
    expect(decoration.boxShadow, V3PrimitiveShadows.sm);

    await pumpButton(
      tester,
      variant: V3MediumButtonVariant.outline,
      state: V3MediumButtonState.error,
      onPressed: () {},
    );
    decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('v3-medium-button-decoration')),
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
      state: V3MediumButtonState.disabled,
      onPressed: () => presses++,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await pumpButton(tester, isLoading: true, onPressed: () => presses++);
    expect(
      find.byKey(const ValueKey('v3-medium-button-progress')),
      findsOneWidget,
    );
    await tester.tap(find.byType(V3MediumButton));
    expect(presses, 0);
  });

  testWidgets('exposes localized semantics and active state', (tester) async {
    await pumpButton(
      tester,
      label: 'ดำเนินการต่อ',
      semanticLabel: 'ดำเนินการต่อไปยังขั้นตอนยืนยัน',
      state: V3MediumButtonState.active,
      onPressed: () {},
    );
    final finder = find.bySemanticsLabel('ดำเนินการต่อไปยังขั้นตอนยืนยัน');
    expect(finder, findsOneWidget);
    expect(
      tester.getSemantics(finder).hasFlag(ui.SemanticsFlag.isToggled),
      isTrue,
    );
  });

  testWidgets('selects Dark mode Medium button semantics', (tester) async {
    await pumpButton(
      tester,
      theme: TestThemeVariant.dark,
      variant: V3MediumButtonVariant.outline,
      state: V3MediumButtonState.error,
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
      const V3MediumButtonPreview(),
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
        const V3MediumButtonPreview(),
        wrapWithScaffold: false,
      );

      final iconFinder = find.byType(V3LucideIcon);
      // 3 variants × 4 states × 2 icon slots (leading + trailing).
      final expectedCount =
          V3MediumButtonVariant.values.length *
          V3MediumButtonState.values.length *
          2;
      expect(iconFinder, findsNWidgets(expectedCount));

      for (var i = 0; i < expectedCount; i++) {
        expect(tester.getSize(iconFinder.at(i)), const Size.square(16));
      }
    },
  );

  testWidgets('Medium label remains stable at large text scale', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpButton(tester, label: 'Confirm', onPressed: () {});
    expect(tester.getSize(find.byType(TextButton)).height, V3Spacing.space40);
    expect(tester.takeException(), isNull);
  });
}
