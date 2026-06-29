import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/widgets/tab/horizontal_tabs.dart';

import 'support/widget_test_harness.dart';

void main() {
  testWidgets('HorizontalTabs renders selected tab and badge dot', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      HorizontalTabs(
        tabs: const [
          HorizontalTabItem(label: 'General', showDot: true),
          HorizontalTabItem(label: 'For You'),
        ],
        selectedIndex: 0,
        onTabChanged: (_) {},
      ),
    );

    expect(find.text('General'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      ),
      findsOneWidget,
    );
  });

  testWidgets('HorizontalTabs triggers callback and press animation', (
    WidgetTester tester,
  ) async {
    int? changedIndex;

    await pumpTestApp(
      tester,
      HorizontalTabs(
        tabs: const [
          HorizontalTabItem(label: 'History'),
          HorizontalTabItem(label: 'Info'),
          HorizontalTabItem(label: 'Setting'),
        ],
        selectedIndex: 1,
        onTabChanged: (index) => changedIndex = index,
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Setting')),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final pressedScale = tester
        .widgetList<AnimatedScale>(find.byType(AnimatedScale))
        .firstWhere((widget) => widget.scale < 1.0);
    expect(pressedScale.scale, lessThan(1.0));

    await gesture.up();
    await tester.pumpAndSettle();

    expect(changedIndex, 2);
  });

  testWidgets('HorizontalTabs supports two-tab and three-tab layouts', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      Column(
        children: [
          HorizontalTabs(
            tabs: const [
              HorizontalTabItem(label: 'Left'),
              HorizontalTabItem(label: 'Right'),
            ],
            selectedIndex: 1,
            onTabChanged: (_) {},
          ),
          const SizedBox(height: 16),
          HorizontalTabs(
            tabs: const [
              HorizontalTabItem(label: 'One'),
              HorizontalTabItem(label: 'Two'),
              HorizontalTabItem(label: 'Three'),
            ],
            selectedIndex: 0,
            onTabChanged: (_) {},
          ),
        ],
      ),
    );

    expect(find.text('Left'), findsOneWidget);
    expect(find.text('Right'), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('Two'), findsOneWidget);
    expect(find.text('Three'), findsOneWidget);
  });
}
