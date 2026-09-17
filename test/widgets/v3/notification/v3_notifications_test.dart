import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';
import 'package:mcp_test_app/widgets/v3/notification/v3_notifications.dart';

void main() {
  Widget buildSubject({
    V3NotificationState state = V3NotificationState.unread,
    VoidCallback? onPressed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: V3Notifications(
          key: const ValueKey('notification'),
          state: state,
          title: 'Top-up successful',
          message: '1,000.00 THB successfully added to your wallet',
          timestamp: '2026-05-12 00:00',
          onPressed: onPressed,
        ),
      ),
    );
  }

  testWidgets('matches the measured 343x100 root geometry', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(
      tester.getSize(find.byKey(const ValueKey('notification'))),
      const Size(343, 100),
    );
    expect(find.text('Top-up successful'), findsOneWidget);
    expect(
      find.text('1,000.00 THB successfully added to your wallet'),
      findsOneWidget,
    );
    expect(find.text('2026-05-12 00:00'), findsOneWidget);
  });

  testWidgets('exposes one actionable semantics node and invokes callback', (
    tester,
  ) async {
    var pressed = false;
    await tester.pumpWidget(buildSubject(onPressed: () => pressed = true));

    expect(find.bySemanticsLabel('Top-up successful'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('notification')));
    expect(pressed, isTrue);
  });

  testWidgets('supports the read state without changing geometry', (
    tester,
  ) async {
    await tester.pumpWidget(buildSubject(state: V3NotificationState.read));

    expect(
      tester.getSize(find.byKey(const ValueKey('notification'))),
      const Size(343, 100),
    );
    expect(find.bySemanticsLabel('Top-up successful'), findsOneWidget);
  });

  testWidgets('matches Figma state-specific icon treatment', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('v3-notifications-icon-opacity')),
          )
          .opacity,
      1,
    );
    expect(
      tester
          .widget<IconTheme>(
            find.byKey(const ValueKey('v3-notifications-chevron-theme')),
          )
          .data
          .color,
      const Color(0xFF0F172A),
    );

    await tester.pumpWidget(buildSubject(state: V3NotificationState.read));

    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('v3-notifications-icon-opacity')),
          )
          .opacity,
      0.5,
    );
    expect(
      tester
          .widget<IconTheme>(
            find.byKey(const ValueKey('v3-notifications-chevron-theme')),
          )
          .data
          .color,
      const Color(0xFF64748B),
    );
  });

  testWidgets('truncates long content without overflow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: V3Notifications(
            title: 'A very long notification title that should truncate',
            message:
                'A very long notification message that should wrap and truncate safely without overflowing the fixed card width.',
            timestamp: '2026-05-12 00:00:00 +07:00',
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('owns the documented Lucide icon composition', (tester) async {
    await tester.pumpWidget(buildSubject());

    expect(find.byType(V3LucideCreditCardPlusIcon), findsOneWidget);
    expect(find.byType(V3LucideChevronRightIcon), findsOneWidget);
  });
}
