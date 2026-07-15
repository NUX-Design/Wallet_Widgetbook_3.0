import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_dimensions.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';
import 'package:mcp_test_app/widgets/v3/navigation/preview_v3_navigation.dart';
import 'package:mcp_test_app/widgets/v3/navigation/v3_navigation.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  const destinations = [
    V3NavigationDestination(label: 'Home', icon: Icon(Icons.home_outlined)),
    V3NavigationDestination(
      label: 'Card',
      icon: Icon(Icons.credit_card_outlined),
    ),
    V3NavigationDestination(
      label: 'Services',
      icon: Icon(Icons.grid_view_outlined),
    ),
    V3NavigationDestination(label: 'Menu', icon: Icon(Icons.tune_outlined)),
  ];

  Future<void> pumpNavigation(
    WidgetTester tester, {
    TestThemeVariant theme = TestThemeVariant.light,
    int selectedIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    VoidCallback? onScanPressed,
  }) {
    return pumpTestApp(
      tester,
      Align(
        alignment: Alignment.bottomCenter,
        child: V3Navigation(
          destinations: destinations,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          scanIcon: const Icon(Icons.center_focus_strong),
          scanSemanticLabel: 'Scan QR code',
          onScanPressed: onScanPressed,
        ),
      ),
      themeVariant: theme,
    );
  }

  testWidgets('maps selected and unselected destinations to semantic colors', (
    tester,
  ) async {
    await pumpNavigation(
      tester,
      selectedIndex: 1,
      onDestinationSelected: (_) {},
    );

    final selectedTheme = tester.widget<IconTheme>(
      find.byKey(const ValueKey('v3-navigation-icon-theme-1')),
    );
    final inactiveTheme = tester.widget<IconTheme>(
      find.byKey(const ValueKey('v3-navigation-icon-theme-0')),
    );
    expect(selectedTheme.data.color, V3ColorPalette.light.contentPrimary);
    expect(inactiveTheme.data.color, V3ColorPalette.light.contentNeutral);

    final selectedLabel = tester.widget<Text>(
      find.byKey(const ValueKey('v3-navigation-label-1')),
    );
    expect(selectedLabel.style?.fontWeight, FontWeight.w700);
    expect(selectedLabel.style?.fontSize, 12);
  });

  testWidgets('uses dark semantic palette', (tester) async {
    await pumpNavigation(
      tester,
      theme: TestThemeVariant.dark,
      selectedIndex: 2,
      onDestinationSelected: (_) {},
    );
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('v3-navigation-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;
    expect(decoration.color, V3ColorPalette.dark.backgroundWhite);
    final topBorderFinder = find.byKey(
      const ValueKey('v3-navigation-top-border'),
    );
    final topBorder = tester.widget<ColoredBox>(topBorderFinder);
    expect(topBorder.color, V3ColorPalette.dark.borderPrimary);
    expect(tester.getSize(topBorderFinder).height, 1);
  });

  testWidgets('matches Figma bar, icon, and Scan metrics', (tester) async {
    await pumpNavigation(
      tester,
      onDestinationSelected: (_) {},
      onScanPressed: () {},
    );
    expect(tester.getSize(find.byType(V3Navigation)).height, V3Spacing.space96);
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-navigation-destination-0'))),
      const Size.square(48),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-navigation-scan-action'))),
      const Size.square(V3Spacing.space56),
    );

    final scanDecoration = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('v3-navigation-scan-decoration')),
    );
    final decoration = scanDecoration.decoration as BoxDecoration;
    final gradient = decoration.gradient! as LinearGradient;
    expect(gradient.colors, [
      V3PrimitiveColors.gold400,
      V3PrimitiveColors.gold800,
    ]);
  });

  testWidgets('invokes destination and Scan callbacks independently', (
    tester,
  ) async {
    int? selected;
    var scans = 0;
    await pumpNavigation(
      tester,
      onDestinationSelected: (index) => selected = index,
      onScanPressed: () => scans++,
    );
    await tester.tap(find.byKey(const ValueKey('v3-navigation-destination-3')));
    await tester.tap(find.byKey(const ValueKey('v3-navigation-scan-action')));
    expect(selected, 3);
    expect(scans, 1);
  });

  testWidgets('disabled callbacks cannot be invoked', (tester) async {
    await pumpNavigation(tester);
    for (var index = 0; index < 4; index++) {
      expect(
        tester
            .widget<TextButton>(
              find.byKey(ValueKey('v3-navigation-destination-$index')),
            )
            .onPressed,
        isNull,
      );
    }
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('v3-navigation-scan-action')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('exposes localized selected and Scan semantics', (tester) async {
    await pumpNavigation(
      tester,
      selectedIndex: 1,
      onDestinationSelected: (_) {},
      onScanPressed: () {},
    );
    final selected = find.bySemanticsLabel('Card');
    expect(selected, findsOneWidget);
    expect(
      tester.getSemantics(selected).hasFlag(ui.SemanticsFlag.isSelected),
      isTrue,
    );
    expect(find.bySemanticsLabel('Scan QR code'), findsOneWidget);
  });

  testWidgets('preview toggles the whole navigation to dark mode', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const V3NavigationPreview(),
      wrapWithScaffold: false,
    );
    await tester.tap(find.text('Dark'));
    await tester.pump();
    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('v3-navigation-surface')),
    );
    expect(
      (surface.decoration as BoxDecoration).color,
      V3ColorPalette.dark.backgroundWhite,
    );
  });

  testWidgets(
    'Lucide pilot renders destinations at 24px, Scan at 32px, and bolds the selected icon',
    (tester) async {
      await pumpTestApp(
        tester,
        const V3NavigationPreview(),
        wrapWithScaffold: false,
      );

      final destination0IconTheme = find.byKey(
        const ValueKey('v3-navigation-icon-theme-0'),
      );
      expect(
        tester.getSize(
          find.descendant(
            of: destination0IconTheme,
            matching: find.byType(V3LucideIcon),
          ),
        ),
        const Size.square(V3Spacing.space24),
      );

      final scanAction = find.byKey(
        const ValueKey('v3-navigation-scan-action'),
      );
      expect(
        tester.getSize(
          find.descendant(of: scanAction, matching: find.byType(V3LucideIcon)),
        ),
        const Size.square(V3Spacing.space32),
      );

      TextStyle glyphStyleFor(Finder iconThemeFinder) {
        final iconFinder = find.descendant(
          of: iconThemeFinder,
          matching: find.byType(V3LucideIcon),
        );
        final richText = tester.widget<RichText>(
          find.descendant(of: iconFinder, matching: find.byType(RichText)),
        );
        return (richText.text as TextSpan).style!;
      }

      // Destination 0 (Home) starts selected in the preview's initial state.
      final selectedStyle = glyphStyleFor(destination0IconTheme);
      final inactiveStyle = glyphStyleFor(
        find.byKey(const ValueKey('v3-navigation-icon-theme-1')),
      );
      expect(
        selectedStyle.fontFamily,
        'packages/lucide_icons_flutter/Lucide600',
      );
      expect(inactiveStyle.fontFamily, 'packages/lucide_icons_flutter/Lucide');
    },
  );
}
