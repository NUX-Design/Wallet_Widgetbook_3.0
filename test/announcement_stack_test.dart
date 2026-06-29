import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/announce/announcement.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

import 'support/widget_test_harness.dart';

Future<void> _pumpAnnouncementStack(
  WidgetTester tester, {
  required List<String> messages,
  bool isLoading = false,
  VoidCallback? onClose,
}) async {
  await pumpTestApp(
    tester,
    AnnouncementStack(
      key: const ValueKey('announcement_stack'),
      messages: messages,
      isLoading: isLoading,
      onClose: onClose,
    ),
    assetBundle: PlaceholderAssetBundle(
      assetPaths: const <String>[
        'lib/assets/images/megaphone-01.svg',
        'lib/assets/images/cancel-01.svg',
        'lib/assets/lottie/wi_skeleton.json',
      ],
    ),
  );
  await tester.pump();
}

Finder _cancelIconFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'lib/assets/images/cancel-01.svg';
  });
}

void main() {
  testWidgets('AnnouncementStack renders the stacked cards and loading state', (
    WidgetTester tester,
  ) async {
    await _pumpAnnouncementStack(
      tester,
      messages: const ['First message', 'Second message', 'Third message'],
      isLoading: true,
    );

    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Second message'), findsOneWidget);
    expect(find.text('Third message'), findsNothing);
    expect(find.byType(LottieSkeleton), findsNWidgets(4));
    expect(_cancelIconFinder(), findsOneWidget);
  });

  testWidgets('AnnouncementStack renders two messages as the active stack', (
    WidgetTester tester,
  ) async {
    await _pumpAnnouncementStack(
      tester,
      messages: const ['First message', 'Second message'],
    );

    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Second message'), findsOneWidget);
    expect(find.byType(LottieSkeleton), findsNWidgets(4));
  });

  testWidgets(
    'AnnouncementStack rotates the queue and invokes onClose when dismissed',
    (WidgetTester tester) async {
      var closeCount = 0;

      await _pumpAnnouncementStack(
        tester,
        messages: const ['First message', 'Second message', 'Third message'],
        onClose: () => closeCount += 1,
      );

      await tester.tap(_cancelIconFinder());
      await tester.pumpAndSettle();

      expect(closeCount, 1);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('card_1')),
          matching: find.text('Second message'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('card_2')),
          matching: find.text('Third message'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AnnouncementStack hides the dismiss control for a single message',
    (WidgetTester tester) async {
      await _pumpAnnouncementStack(tester, messages: const ['Only message']);

      expect(_cancelIconFinder(), findsOneWidget);
      expect(find.text('Only message'), findsNWidgets(2));
    },
  );

  testWidgets('AnnouncementStack updates when the message list changes', (
    WidgetTester tester,
  ) async {
    await _pumpAnnouncementStack(
      tester,
      messages: const ['Old first', 'Old second'],
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card_1')),
        matching: find.text('Old first'),
      ),
      findsOneWidget,
    );

    await _pumpAnnouncementStack(
      tester,
      messages: const ['New first', 'New second', 'New third'],
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card_1')),
        matching: find.text('New first'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('card_2')),
        matching: find.text('New second'),
      ),
      findsOneWidget,
    );
    expect(find.text('Old first'), findsNothing);
  });
}
