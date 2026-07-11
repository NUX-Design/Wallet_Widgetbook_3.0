import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_mini_button.dart';
import 'package:mcp_test_app/widgets/v3/button/v3_mini_button.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    TestThemeVariant theme = TestThemeVariant.light,
    VoidCallback? onPressed,
    V3MiniButtonVariant variant = V3MiniButtonVariant.primary,
    V3MiniButtonState state = V3MiniButtonState.defaultState,
    Widget? leadingIcon,
    Widget? trailingIcon,
    bool isLoading = false,
    String label = 'Label',
    String? semanticLabel,
  }) {
    return pumpTestApp(
      tester,
      Center(
        child: V3MiniButton(
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

  testWidgets('maps all Primary Mini states to Figma tokens', (tester) async {
    await pumpButton(tester, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.buttonPrimary,
    );

    await pumpButton(tester, state: V3MiniButtonState.active, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.borderTertiary,
    );

    await pumpButton(tester, state: V3MiniButtonState.disabled);
    expect(
      buttonStyle(tester).backgroundColor!.resolve({WidgetState.disabled}),
      V3ColorPalette.light.backgroundNeutral,
    );

    await pumpButton(tester, state: V3MiniButtonState.error, onPressed: () {});
    expect(
      buttonStyle(tester).backgroundColor!.resolve({}),
      V3ColorPalette.light.stateError,
    );
  });

  testWidgets('maps all Outline Mini states including dedicated error border', (
    tester,
  ) async {
    await pumpButton(
      tester,
      variant: V3MiniButtonVariant.outline,
      onPressed: () {},
    );
    var style = buttonStyle(tester);
    expect(style.side!.resolve({})?.color, V3ColorPalette.light.borderSlate);

    await pumpButton(
      tester,
      variant: V3MiniButtonVariant.outline,
      state: V3MiniButtonState.active,
      onPressed: () {},
    );
    style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({}),
      V3ColorPalette.light.black.withValues(alpha: 0.05),
    );
    expect(style.side!.resolve({})?.color, V3ColorPalette.light.contentNeutral);

    await pumpButton(
      tester,
      variant: V3MiniButtonVariant.outline,
      state: V3MiniButtonState.error,
      onPressed: () {},
    );
    style = buttonStyle(tester);
    expect(
      style.side!.resolve({})?.color,
      V3ColorPalette.light.borderExtensionError,
    );
    expect(style.foregroundColor!.resolve({}), V3ColorPalette.light.stateError);
  });

  testWidgets('maps all Ghost Mini states and underline style', (tester) async {
    for (final state in V3MiniButtonState.values) {
      await pumpButton(
        tester,
        variant: V3MiniButtonVariant.ghost,
        state: state,
        onPressed: state == V3MiniButtonState.disabled ? null : () {},
      );
      final style = buttonStyle(tester);
      expect(
        style.textStyle!.resolve({})?.decoration,
        TextDecoration.underline,
      );
      expect(style.padding!.resolve({}), EdgeInsets.zero);
    }
  });

  testWidgets('matches exact Mini metrics and icon slots', (tester) async {
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
    expect(tester.getSize(find.byType(TextButton)).height, 24);
    expect(
      style.padding!.resolve({}),
      const EdgeInsets.symmetric(horizontal: 8),
    );
    expect(textStyle.fontSize, 12);
    expect(textStyle.height! * textStyle.fontSize!, 16);
    expect(textStyle.fontWeight, FontWeight.w500);
    expect(
      tester.getSize(find.byKey(const ValueKey('left-icon'))),
      const Size(12, 12),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('right-icon'))),
      const Size(12, 12),
    );

    await pumpButton(
      tester,
      variant: V3MiniButtonVariant.ghost,
      onPressed: () {},
    );
    expect(tester.getSize(find.byType(TextButton)).height, 16);
  });

  testWidgets('disabled and loading states do not invoke callbacks', (
    tester,
  ) async {
    var presses = 0;
    await pumpButton(
      tester,
      state: V3MiniButtonState.disabled,
      onPressed: () => presses++,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );

    await pumpButton(tester, isLoading: true, onPressed: () => presses++);
    expect(
      find.byKey(const ValueKey('v3-mini-button-progress')),
      findsOneWidget,
    );
    await tester.tap(find.byType(V3MiniButton));
    expect(presses, 0);
  });

  testWidgets('exposes localized semantics and active state', (tester) async {
    await pumpButton(
      tester,
      label: 'ดำเนินการต่อ',
      semanticLabel: 'ดำเนินการต่อไปยังขั้นตอนยืนยัน',
      state: V3MiniButtonState.active,
      onPressed: () {},
    );
    final finder = find.bySemanticsLabel('ดำเนินการต่อไปยังขั้นตอนยืนยัน');
    expect(finder, findsOneWidget);
    expect(
      tester.getSemantics(finder).hasFlag(ui.SemanticsFlag.isToggled),
      isTrue,
    );
  });

  testWidgets('selects Dark mode Mini button semantics', (tester) async {
    await pumpButton(
      tester,
      theme: TestThemeVariant.dark,
      variant: V3MiniButtonVariant.outline,
      state: V3MiniButtonState.error,
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
      const V3MiniButtonPreview(),
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

  testWidgets('Mini label remains stable at large text scale', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpButton(tester, label: 'Confirm', onPressed: () {});
    expect(tester.getSize(find.byType(TextButton)).height, 24);
    expect(tester.takeException(), isNull);
  });
}
