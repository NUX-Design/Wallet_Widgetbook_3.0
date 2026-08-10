import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/widgets/v3/profile_header/preview_v3_profile_header.dart';
import 'package:mcp_test_app/widgets/v3/profile_header/v3_profile_header.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  Future<void> pumpHeader(
    WidgetTester tester,
    V3ProfileHeader header, {
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

  testWidgets('default layout sizes the root to 40 and shows no balance row', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(
        userName: 'Cameron Brooklyn Williamson',
        notificationSemanticLabel: 'Notifications',
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('v3-profile-header-root'))),
      const Size(375, 40),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('v3-profile-header-avatar'))),
      const Size.square(40),
    );
    expect(
      find.byKey(const ValueKey('v3-profile-header-balance')),
      findsNothing,
    );
  });

  testWidgets(
    'scrolled layout sizes the root to 44 and reveals the balance row',
    (tester) async {
      await pumpHeader(
        tester,
        const V3ProfileHeader(
          layoutState: V3ProfileHeaderLayoutState.scrolled,
          balanceVisibility: V3ProfileHeaderBalanceVisibility.visible,
          userName: 'Cameron Brooklyn Williamson',
          balanceAmount: '9,999.99 THB',
          notificationSemanticLabel: 'Notifications',
        ),
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('v3-profile-header-root'))),
        const Size(375, 44),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('v3-profile-header-balance')),
            )
            .data,
        '9,999.99 THB',
      );
    },
  );

  testWidgets('scrolled + none balance visibility hides the balance row', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(
        layoutState: V3ProfileHeaderLayoutState.scrolled,
        userName: 'Cameron Brooklyn Williamson',
        notificationSemanticLabel: 'Notifications',
      ),
    );

    expect(
      find.byKey(const ValueKey('v3-profile-header-balance')),
      findsNothing,
    );
  });

  testWidgets('obscured balance visibility masks every digit', (tester) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(
        layoutState: V3ProfileHeaderLayoutState.scrolled,
        balanceVisibility: V3ProfileHeaderBalanceVisibility.obscured,
        userName: 'Cameron Brooklyn Williamson',
        balanceAmount: '9,999.99 THB',
        notificationSemanticLabel: 'Notifications',
      ),
    );

    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('v3-profile-header-balance')))
          .data,
      '*,***.** THB',
    );
  });

  testWidgets('maps status to the matching semantic state color', (
    tester,
  ) async {
    Future<Color> resolvedColor(V3ProfileHeaderStatus status) async {
      await pumpHeader(
        tester,
        V3ProfileHeader(
          status: status,
          notificationSemanticLabel: 'Notifications',
        ),
      );
      return tester
          .widget<IconTheme>(
            find
                .ancestor(
                  of: find.byKey(
                    const ValueKey('v3-profile-header-verification-icon'),
                  ),
                  matching: find.byType(IconTheme),
                )
                .first,
          )
          .data
          .color!;
    }

    expect(
      await resolvedColor(V3ProfileHeaderStatus.pending),
      V3ColorPalette.light.stateWarning,
    );
    expect(
      await resolvedColor(V3ProfileHeaderStatus.error),
      V3ColorPalette.light.stateError,
    );
    expect(
      await resolvedColor(V3ProfileHeaderStatus.success),
      V3ColorPalette.light.stateSuccess,
    );
  });

  testWidgets('resolves avatar, name, and notification colors per theme', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(
        userName: 'Cameron Brooklyn Williamson',
        notificationSemanticLabel: 'Notifications',
      ),
      theme: TestThemeVariant.dark,
    );

    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(const ValueKey('v3-profile-header-avatar')),
                  )
                  .decoration
              as BoxDecoration)
          .color,
      V3ColorPalette.dark.backgroundBlue,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('v3-profile-header-user-name')),
          )
          .style!
          .color,
      V3ColorPalette.dark.contentPrimary,
    );
  });

  testWidgets(
    'notification action exposes localized semantics and invokes callback',
    (tester) async {
      var presses = 0;
      await pumpHeader(
        tester,
        V3ProfileHeader(
          notificationSemanticLabel: 'การแจ้งเตือน',
          onNotificationPressed: () => presses++,
        ),
      );

      expect(
        tester.getSize(
          find.byKey(const ValueKey('v3-profile-header-notification-target')),
        ),
        const Size.square(48),
      );

      await tester.tap(find.bySemanticsLabel('การแจ้งเตือน'));
      expect(presses, 1);

      final semantics = tester.getSemantics(
        find.bySemanticsLabel('การแจ้งเตือน'),
      );
      expect(semantics.hasFlag(ui.SemanticsFlag.isButton), isTrue);
      expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isTrue);
    },
  );

  testWidgets('null notification callback exposes disabled semantics', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(notificationSemanticLabel: 'Notifications'),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Notifications'),
    );
    expect(semantics.hasFlag(ui.SemanticsFlag.isEnabled), isFalse);
  });

  testWidgets('long user names ellipsize without pushing the bell offscreen', (
    tester,
  ) async {
    await pumpHeader(
      tester,
      const V3ProfileHeader(
        userName:
            'An extremely long profile display name that should never overflow',
        notificationSemanticLabel: 'Notifications',
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('v3-profile-header-user-name')),
          )
          .overflow,
      TextOverflow.ellipsis,
    );
    expect(
      find.byKey(const ValueKey('v3-profile-header-notification-target')),
      findsOneWidget,
    );
  });

  testWidgets('verification icon follows the rendered name with an 8px gap', (
    tester,
  ) async {
    Future<double> verificationGapFor(String userName) async {
      await pumpHeader(
        tester,
        V3ProfileHeader(
          userName: userName,
          notificationSemanticLabel: 'Notifications',
        ),
      );

      final nameRect = tester.getRect(
        find.byKey(const ValueKey('v3-profile-header-user-name')),
      );
      final verificationRect = tester.getRect(
        find.byKey(const ValueKey('v3-profile-header-verification-icon')),
      );
      return verificationRect.left - nameRect.right;
    }

    expect(await verificationGapFor('Amy'), 8);
    expect(await verificationGapFor('Cameron Brooklyn Williamson'), 8);
  });

  testWidgets(
    'preview renders every documented variant and toggles Dark mode',
    (tester) async {
      await pumpTestApp(
        tester,
        const V3ProfileHeaderPreview(),
        wrapWithScaffold: false,
      );

      expect(find.byType(V3ProfileHeader), findsWidgets);
      expect(
        find.byKey(const ValueKey('v3-profile-header-preview-divider')),
        findsNWidgets(6),
      );
      expect(find.text('Notification action: None (0)'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find
                  .byKey(
                    const ValueKey('v3-profile-header-preview-section-label'),
                  )
                  .first,
            )
            .style!
            .color,
        V3ColorPalette.light.contentSecondary,
      );

      await tester.tap(
        find.byKey(const ValueKey('v3-profile-header-preview-default')),
        warnIfMissed: false,
      );
      await tester.tap(find.bySemanticsLabel('Notifications').first);
      await tester.pump();
      expect(
        find.text('Notification action: Default · Success (1)'),
        findsOneWidget,
      );

      final lastNotification = find.bySemanticsLabel('Notifications').last;
      await tester.ensureVisible(lastNotification);
      await tester.tap(lastNotification);
      await tester.pump();
      expect(
        find.text('Notification action: Scrolled · No balance row (2)'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Dark'));
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor,
        V3ColorPalette.dark.backgroundPrimary,
      );
      expect(
        tester
            .widget<Text>(
              find
                  .byKey(
                    const ValueKey('v3-profile-header-preview-section-label'),
                  )
                  .first,
            )
            .style!
            .color,
        V3ColorPalette.dark.contentSecondary,
      );
    },
  );
}
