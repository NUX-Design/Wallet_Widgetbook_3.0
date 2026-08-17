import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_typography.dart';
import 'package:mcp_test_app/widgets/v3/card/preview_v3_balance_card.dart';
import 'package:mcp_test_app/widgets/v3/card/v3_balance_card.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_icon_size.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Widget visibilityIcon(bool visible) {
    return V3LucideIcon(
      visible ? LucideIcons.eye : LucideIcons.eyeOff,
      size: V3IconSize.medium,
    );
  }

  const infoIcon = V3LucideIcon(
    LucideIcons.circleAlert,
    size: V3IconSize.small,
  );

  Future<void> pumpCard(
    WidgetTester tester,
    V3BalanceCard card, {
    TestThemeVariant theme = TestThemeVariant.light,
  }) {
    return pumpTestApp(
      tester,
      Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 375, child: card),
      ),
      themeVariant: theme,
    );
  }

  BoxDecoration surfaceDecoration(WidgetTester tester) {
    return tester
            .widget<Container>(
              find.byKey(const ValueKey('v3-balance-card-surface')),
            )
            .decoration
        as BoxDecoration;
  }

  testWidgets('masks the amount and shows eye-off when hidden', (tester) async {
    await pumpCard(
      tester,
      V3BalanceCard(
        label: 'Available balance',
        amount: '10,000,000.00',
        currency: 'THB',
        isBalanceVisible: false,
        onToggleVisibility: () {},
        visibilityIcon: visibilityIcon(false),
      ),
    );

    expect(find.text('**.**'), findsOneWidget);
    expect(find.text('10,000,000.00'), findsNothing);
    expect(
      tester.widget<V3LucideIcon>(find.byType(V3LucideIcon)).icon,
      LucideIcons.eyeOff,
    );
  });

  testWidgets('reveals the amount and shows eye when visible', (tester) async {
    await pumpCard(
      tester,
      V3BalanceCard(
        label: 'Available balance',
        amount: '10,000,000.00',
        currency: 'THB',
        isBalanceVisible: true,
        onToggleVisibility: () {},
        visibilityIcon: visibilityIcon(true),
      ),
    );

    expect(find.text('10,000,000.00'), findsOneWidget);
    expect(find.text('**.**'), findsNothing);
    expect(
      tester.widget<V3LucideIcon>(find.byType(V3LucideIcon)).icon,
      LucideIcons.eye,
    );
  });

  testWidgets('maps border and text colors to V3 tokens in Light and Dark', (
    tester,
  ) async {
    await pumpCard(
      tester,
      V3BalanceCard(
        label: 'Available balance',
        amount: '10,000,000.00',
        currency: 'THB',
        isBalanceVisible: true,
        onToggleVisibility: _noop,
        visibilityIcon: visibilityIcon(true),
      ),
    );

    var decoration = surfaceDecoration(tester);
    expect(
      decoration.border,
      Border(
        left: BorderSide(color: V3ColorPalette.light.borderPrimary),
        right: BorderSide(color: V3ColorPalette.light.borderPrimary),
        bottom: BorderSide(color: V3ColorPalette.light.borderPrimary),
      ),
    );
    expect(decoration.boxShadow, V3PrimitiveShadows.md);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('v3-balance-card-amount')))
          .style,
      V3Typography.headingLarge.copyWith(
        color: V3ColorPalette.light.contentPrimary,
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('v3-balance-card-label')))
          .style,
      V3Typography.paragraphTiny.copyWith(
        color: V3ColorPalette.light.contentSecondary,
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('v3-balance-card-currency')))
          .style,
      V3Typography.paragraphMedium.copyWith(
        color: V3ColorPalette.light.contentSecondary,
      ),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await pumpCard(
      tester,
      V3BalanceCard(
        label: 'Available balance',
        amount: '10,000,000.00',
        currency: 'THB',
        isBalanceVisible: true,
        onToggleVisibility: _noop,
        visibilityIcon: visibilityIcon(true),
      ),
      theme: TestThemeVariant.dark,
    );
    decoration = surfaceDecoration(tester);
    expect(
      decoration.border,
      Border(
        left: BorderSide(color: V3ColorPalette.dark.borderPrimary),
        right: BorderSide(color: V3ColorPalette.dark.borderPrimary),
        bottom: BorderSide(color: V3ColorPalette.dark.borderPrimary),
      ),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('v3-balance-card-amount')))
          .style!
          .color,
      V3ColorPalette.dark.contentPrimary,
    );
  });

  testWidgets(
    'shows the info icon only when both onInfoTap and infoIcon are provided',
    (tester) async {
      await pumpCard(
        tester,
        V3BalanceCard(
          label: 'Available balance',
          amount: '10,000,000.00',
          currency: 'THB',
          isBalanceVisible: true,
          onToggleVisibility: () {},
          visibilityIcon: visibilityIcon(true),
        ),
      );
      expect(find.byType(V3LucideIcon), findsOneWidget);

      await pumpCard(
        tester,
        V3BalanceCard(
          label: 'Available balance',
          amount: '10,000,000.00',
          currency: 'THB',
          isBalanceVisible: true,
          onToggleVisibility: () {},
          visibilityIcon: visibilityIcon(true),
          onInfoTap: () {},
          infoIcon: infoIcon,
        ),
      );
      expect(find.byType(V3LucideIcon), findsNWidgets(2));
      expect(
        tester
            .widgetList<V3LucideIcon>(find.byType(V3LucideIcon))
            .map((w) => w.icon),
        contains(LucideIcons.circleAlert),
      );
    },
  );

  testWidgets('invokes callbacks and exposes composed + toggle semantics', (
    tester,
  ) async {
    var togglePresses = 0;
    var infoTaps = 0;
    await pumpCard(
      tester,
      V3BalanceCard(
        label: 'Available balance',
        amount: '10,000,000.00',
        currency: 'THB',
        isBalanceVisible: false,
        onToggleVisibility: () => togglePresses++,
        visibilityIcon: visibilityIcon(false),
        onInfoTap: () => infoTaps++,
        infoIcon: infoIcon,
      ),
    );

    expect(find.bySemanticsLabel('Available balance: Hidden'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Show balance'));
    await tester.tap(find.bySemanticsLabel('Balance info'));
    expect(togglePresses, 1);
    expect(infoTaps, 1);
  });

  testWidgets('preview renders the card and toggles Dark mode', (tester) async {
    await pumpTestApp(
      tester,
      const V3BalanceCardPreview(),
      wrapWithScaffold: false,
    );
    expect(find.byType(V3BalanceCard), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Show balance'));
    await tester.pump();
    expect(find.text('Action: Show balance'), findsOneWidget);

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      (tester
                  .widget<Container>(
                    find.byKey(const ValueKey('v3-balance-card-surface')),
                  )
                  .decoration
              as BoxDecoration)
          .border,
      Border(
        left: BorderSide(color: V3ColorPalette.dark.borderPrimary),
        right: BorderSide(color: V3ColorPalette.dark.borderPrimary),
        bottom: BorderSide(color: V3ColorPalette.dark.borderPrimary),
      ),
    );
  });
}

void _noop() {}
