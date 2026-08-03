import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';
import 'package:mcp_test_app/widgets/v3/header/preview_v3_header.dart';
import 'package:mcp_test_app/widgets/v3/header/v3_header.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  V3HeaderAction action(String label, {VoidCallback? onPressed}) {
    return V3HeaderAction(
      icon: const Icon(Icons.info_outline),
      semanticLabel: label,
      onPressed: onPressed,
    );
  }

  Future<void> pumpHeader(
    WidgetTester tester,
    V3Header header, {
    TestThemeVariant theme = TestThemeVariant.light,
  }) {
    return pumpTestApp(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 375, child: header),
      ),
      themeVariant: theme,
    );
  }

  BoxDecoration surfaceDecoration(WidgetTester tester) {
    return tester
            .widget<DecoratedBox>(
              find.byKey(const ValueKey('v3-header-surface')),
            )
            .decoration
        as BoxDecoration;
  }

  testWidgets('maps surface, divider, text, and shadow to V3 tokens', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3Header(title: 'Header title', subtitle: 'Subheader'),
    );

    var decoration = surfaceDecoration(tester);
    expect(decoration.color, V3ColorPalette.light.backgroundPrimary);
    expect(
      decoration.border,
      Border(
        bottom: BorderSide(
          color: V3ColorPalette.light.backgroundBlue,
          width: 1,
        ),
      ),
    );
    expect(decoration.boxShadow, V3PrimitiveShadows.sm);
    expect(
      tester.widget<Text>(find.text('Header title')).style,
      V3Typography.headingSmall.copyWith(
        color: V3ColorPalette.light.contentPrimary,
      ),
    );
    expect(
      tester.widget<Text>(find.text('Subheader')).style,
      V3Typography.paragraphSmall.copyWith(
        color: V3ColorPalette.light.contentPrimary,
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpHeader(
      tester,
      const V3Header(title: 'Header title', subtitle: 'Subheader'),
      theme: TestThemeVariant.dark,
    );
    decoration = surfaceDecoration(tester);
    expect(decoration.color, V3ColorPalette.dark.backgroundPrimary);
    expect(
      (decoration.border as Border).bottom.color,
      V3ColorPalette.dark.backgroundBlue,
    );
    expect(
      tester.widget<Text>(find.text('Header title')).style!.color,
      V3ColorPalette.dark.contentPrimary,
    );
  });

  testWidgets('full variant matches Figma layout and accessible targets', (
    tester,
  ) async {
    tester.view.padding = FakeViewPadding(
      top: 40 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    await pumpHeader(
      tester,
      V3Header(
        title: 'Header title',
        subtitle: 'Subheader',
        leadingAction: action('Go back', onPressed: () {}),
        trailingAction: action('More information', onPressed: () {}),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('v3-header-surface'))),
      const Size(375, 152),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('v3-header-action-target')).first,
      ),
      const Size.square(48),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('v3-header-action-icon-host')).first,
      ),
      const Size.square(24),
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('v3-header-title'))).dy,
      80,
    );
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('v3-header-subtitle'))).dy,
      120,
    );
  });

  testWidgets('preferredSize excludes the device top safe area', (
    tester,
  ) async {
    final cases = <V3Header, double>{
      V3Header(leadingAction: action('Back')): 36,
      V3Header(trailingAction: action('Close')): 36,
      const V3Header(title: 'Title'): 44,
      V3Header(title: 'Title', trailingAction: action('Info')): 44,
      const V3Header(title: 'Title', subtitle: 'Subtitle'): 72,
      V3Header(
            title: 'Title',
            subtitle: 'Subtitle',
            trailingAction: action('Info'),
          ):
          72,
      V3Header(title: 'Title', leadingAction: action('Back')): 84,
      V3Header(
            title: 'Title',
            leadingAction: action('Back'),
            trailingAction: action('Info'),
          ):
          84,
      V3Header(
            title: 'Title',
            subtitle: 'Subtitle',
            leadingAction: action('Back'),
          ):
          112,
      V3Header(
            title: 'Title',
            subtitle: 'Subtitle',
            leadingAction: action('Back'),
            trailingAction: action('Info'),
          ):
          112,
    };

    for (final entry in cases.entries) {
      await pumpHeader(tester, entry.key);
      expect(
        tester.getSize(find.byKey(const ValueKey('v3-header-surface'))).height,
        entry.value,
      );
      expect(entry.key.preferredSize.height, entry.value);
    }
  });

  testWidgets('can be assigned directly to Scaffold.appBar', (tester) async {
    tester.view.padding = FakeViewPadding(
      top: 59 * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetPadding);
    final header = V3Header(
      title: 'Header title',
      subtitle: 'Subheader',
      leadingAction: action('Back', onPressed: () {}),
      trailingAction: action('Information', onPressed: () {}),
    );

    await pumpTestApp(
      tester,
      Scaffold(appBar: header, body: const Text('Page content')),
      wrapWithScaffold: false,
    );

    expect(find.byType(V3Header), findsOneWidget);
    expect(header.preferredSize.height, 112);
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-header-surface'))).height,
      171,
    );
    expect(find.text('Page content'), findsOneWidget);
  });

  testWidgets('invokes enabled actions and exposes localized semantics', (
    tester,
  ) async {
    var leadingPresses = 0;
    var trailingPresses = 0;
    await pumpHeader(
      tester,
      V3Header(
        title: 'รายการ',
        leadingAction: action('ย้อนกลับ', onPressed: () => leadingPresses++),
        trailingAction: action(
          'ข้อมูลเพิ่มเติม',
          onPressed: () => trailingPresses++,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('ย้อนกลับ'));
    await tester.tap(find.bySemanticsLabel('ข้อมูลเพิ่มเติม'));
    expect(leadingPresses, 1);
    expect(trailingPresses, 1);
    final semantics = tester.getSemantics(find.bySemanticsLabel('ย้อนกลับ'));
    expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isTrue);
  });

  testWidgets('all action slots are optional, tappable, and replaceable', (
    tester,
  ) async {
    var leadingPresses = 0;
    var topTrailingPresses = 0;
    var trailingPresses = 0;

    await pumpHeader(
      tester,
      V3Header(
        title: 'Header title',
        leadingAction: V3HeaderAction(
          icon: const Icon(Icons.menu, key: ValueKey('custom-leading-icon')),
          semanticLabel: 'Leading action',
          onPressed: () => leadingPresses++,
        ),
        topTrailingAction: V3HeaderAction(
          icon: const Icon(
            Icons.favorite,
            key: ValueKey('custom-top-trailing-icon'),
          ),
          semanticLabel: 'Top trailing action',
          onPressed: () => topTrailingPresses++,
        ),
        trailingAction: V3HeaderAction(
          icon: const Icon(Icons.share, key: ValueKey('custom-trailing-icon')),
          semanticLabel: 'Trailing action',
          onPressed: () => trailingPresses++,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('custom-leading-icon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('custom-top-trailing-icon')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('custom-trailing-icon')), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Leading action'));
    await tester.tap(find.bySemanticsLabel('Top trailing action'));
    await tester.tap(find.bySemanticsLabel('Trailing action'));
    expect((leadingPresses, topTrailingPresses, trailingPresses), (1, 1, 1));

    await pumpHeader(tester, const V3Header(title: 'No actions'));
    expect(find.byType(IconButton), findsNothing);
  });

  testWidgets('null callback exposes disabled semantics and blocks action', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      V3Header(title: 'Title', trailingAction: action('Information')),
    );

    final semantics = tester.getSemantics(find.bySemanticsLabel('Information'));
    expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
    expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isFalse);
    expect(
      tester.widget<IconButton>(find.byType(IconButton)).onPressed,
      isNull,
    );
  });

  testWidgets('text scaling expands content without clipping', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpHeader(
      tester,
      const V3Header(
        title: 'A localized header title',
        subtitle: 'Supporting text remains readable.',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-header-surface'))).height,
      greaterThan(112),
    );
  });

  testWidgets('preview renders core variants and toggles Dark mode', (
    tester,
  ) async {
    await pumpTestApp(tester, const V3HeaderPreview(), wrapWithScaffold: false);
    expect(find.byType(V3Header), findsOneWidget);
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.light.backgroundPrimary,
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('v3-header-theme-toggle')))
          .width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio - 32,
    );
    final bodyBackButton = find.byKey(
      const ValueKey('v3-header-preview-inline-back'),
    );
    final closeButton = find.byKey(
      const ValueKey('v3-header-preview-inline-close'),
    );
    expect(
      tester.getCenter(bodyBackButton).dy,
      tester.getCenter(closeButton).dy,
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('v3-header-preview-context-info')),
          )
          .dy,
      tester.getTopLeft(find.text('Header title')).dy,
    );
    expect(find.text('Action: None'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('v3-header-preview-default-button')),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('Default Button'));
    await tester.pump();
    expect(find.text('Action: Default Button'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Go back'));
    await tester.pump();
    expect(find.text('Action: Go back'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Close'));
    await tester.pump();
    expect(find.text('Action: Close'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('More information'));
    await tester.pump();
    expect(find.text('Action: More information'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
      V3ColorPalette.dark.backgroundPrimary,
    );
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey('v3-header-surface')).first,
                  )
                  .decoration
              as BoxDecoration)
          .color,
      V3ColorPalette.dark.backgroundPrimary,
    );
  });
}
