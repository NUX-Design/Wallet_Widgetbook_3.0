import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_dimensions.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';
import 'package:mcp_test_app/widgets/v3/icon_button/preview_v3_icon_button.dart';
import 'package:mcp_test_app/widgets/v3/icon_button/v3_icon_button.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    TestThemeVariant theme = TestThemeVariant.light,
    VoidCallback? onPressed,
    V3IconButtonSize size = V3IconButtonSize.defaultSize,
    V3IconButtonState state = V3IconButtonState.defaultState,
    String semanticLabel = 'Search',
    FocusNode? focusNode,
  }) {
    return pumpTestApp(
      tester,
      Center(
        child: V3IconButton(
          icon: const Icon(Icons.search, key: ValueKey('test-icon')),
          semanticLabel: semanticLabel,
          size: size,
          state: state,
          focusNode: focusNode,
          onPressed: onPressed,
        ),
      ),
      themeVariant: theme,
    );
  }

  ButtonStyle buttonStyle(WidgetTester tester) =>
      tester.widget<TextButton>(find.byType(TextButton)).style!;

  testWidgets('maps Light and Dark state colors to semantic tokens', (
    tester,
  ) async {
    await pumpButton(tester, onPressed: () {});
    var style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({}),
      V3ColorPalette.light.contentTertiary,
    );
    expect(
      style.foregroundColor!.resolve({}),
      V3ColorPalette.light.contentPrimary,
    );

    await pumpButton(
      tester,
      state: V3IconButtonState.hoverActive,
      onPressed: () {},
    );
    style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({}),
      V3ColorPalette.light.borderPrimary,
    );

    // Recreate the MaterialApp so its state cannot retain the previous
    // themeMode while this single test switches theme variants.
    await tester.pumpWidget(const SizedBox.shrink());
    await pumpButton(tester, theme: TestThemeVariant.dark, onPressed: () {});
    style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({}),
      V3ColorPalette.dark.contentTertiary,
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.hovered}),
      V3ColorPalette.dark.borderPrimary,
    );
    expect(
      style.foregroundColor!.resolve({}),
      V3ColorPalette.dark.contentPrimary,
    );
  });

  testWidgets('disabled state maps tokens and blocks activation', (
    tester,
  ) async {
    var presses = 0;
    await pumpButton(
      tester,
      state: V3IconButtonState.disabled,
      onPressed: () => presses++,
    );
    final style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({WidgetState.disabled}),
      V3ColorPalette.light.backgroundNeutral,
    );
    expect(
      style.foregroundColor!.resolve({WidgetState.disabled}),
      V3ColorPalette.light.contentNeutral2,
    );
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    final semantics = tester.getSemantics(find.bySemanticsLabel('Search'));
    expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isFalse);
    await tester.tap(find.byType(V3IconButton));
    expect(presses, 0);
  });

  testWidgets('matches visual, icon-host, padding, and target metrics', (
    tester,
  ) async {
    const cases = <V3IconButtonSize, (double, double, double, double)>{
      V3IconButtonSize.small: (32, 16, 4, 48),
      V3IconButtonSize.medium: (40, 16, 8, 48),
      V3IconButtonSize.large: (48, 24, 8, 48),
      V3IconButtonSize.defaultSize: (56, 24, 10, 56),
    };

    for (final entry in cases.entries) {
      await pumpButton(tester, size: entry.key, onPressed: () {});
      final (visual, icon, padding, target) = entry.value;
      expect(tester.getSize(find.byType(TextButton)), Size.square(visual));
      expect(
        tester.getSize(find.byKey(const ValueKey('v3-icon-button-icon-host'))),
        Size.square(icon),
      );
      expect(buttonStyle(tester).padding!.resolve({}), EdgeInsets.all(padding));
      expect(
        tester.getSize(find.byKey(const ValueKey('v3-icon-button-target'))),
        Size.square(target),
      );
    }
  });

  testWidgets('uses full radius and exact base shadow', (tester) async {
    await pumpButton(tester, onPressed: () {});
    final decoration =
        tester
                .widget<DecoratedBox>(
                  find.byKey(const ValueKey('v3-icon-button-decoration')),
                )
                .decoration
            as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(V3Radii.roundedFull));
    expect(decoration.boxShadow, V3PrimitiveShadows.base);
  });

  testWidgets('invokes callback and exposes one localized button semantics', (
    tester,
  ) async {
    var presses = 0;
    await pumpButton(
      tester,
      semanticLabel: 'ค้นหา',
      onPressed: () => presses++,
    );

    await tester.tap(find.byType(V3IconButton));
    expect(presses, 1);
    final semantics = tester.getSemantics(find.bySemanticsLabel('ค้นหา'));
    expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isTrue);
    expect(find.bySemanticsLabel('test-icon'), findsNothing);
  });

  testWidgets('runtime hover and keyboard focus use active token', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpButton(tester, focusNode: focusNode, onPressed: () {});
    final style = buttonStyle(tester);
    expect(
      style.backgroundColor!.resolve({WidgetState.hovered}),
      V3ColorPalette.light.borderPrimary,
    );
    expect(
      style.backgroundColor!.resolve({WidgetState.pressed}),
      V3ColorPalette.light.borderPrimary,
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    expect(
      style.backgroundColor!.resolve({WidgetState.focused}),
      V3ColorPalette.light.borderPrimary,
    );
  });

  testWidgets('keyboard activation invokes the callback', (tester) async {
    var presses = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpButton(tester, focusNode: focusNode, onPressed: () => presses++);
    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(presses, 1);
  });

  testWidgets('preview renders every size/state and toggles Dark mode', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const V3IconButtonPreview(),
      wrapWithScaffold: false,
    );
    final expectedCount =
        V3IconButtonSize.values.length * V3IconButtonState.values.length;
    expect(find.byType(V3IconButton), findsNWidgets(expectedCount));
    final firstLabel =
        find.byKey(const ValueKey('v3-icon-button-size-label-small')).first;
    final firstLabelStyle = tester.widget<Text>(firstLabel).style!;
    expect(firstLabelStyle.fontFamily, V3Typography.labelMedium.fontFamily);
    expect(firstLabelStyle.fontSize, V3Typography.labelMedium.fontSize);
    expect(firstLabelStyle.fontWeight, V3Typography.labelMedium.fontWeight);
    expect(firstLabelStyle.height, V3Typography.labelMedium.height);
    expect(
      firstLabelStyle.letterSpacing,
      V3Typography.labelMedium.letterSpacing,
    );
    expect(firstLabelStyle.color, V3ColorPalette.light.contentPrimary);
    const sizeCases = <(String, String)>[
      ('small', 'Small'),
      ('medium', 'Medium'),
      ('large', 'Large'),
      ('defaultSize', 'Default'),
    ];
    final decorations = find.byKey(const ValueKey('v3-icon-button-decoration'));
    for (var index = 0; index < sizeCases.length; index++) {
      final (sizeName, labelName) = sizeCases[index];
      final label =
          find.byKey(ValueKey('v3-icon-button-size-label-$sizeName')).first;
      expect(
        tester.getTopLeft(label).dy -
            tester.getBottomLeft(decorations.at(index)).dy,
        V3Spacing.space8,
        reason: '$labelName visual button-to-label gap',
      );
    }
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.light.backgroundPrimary,
    );

    await tester.tap(find.text('Dark'));
    await tester.pump();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.dark.backgroundPrimary,
    );
  });
}
