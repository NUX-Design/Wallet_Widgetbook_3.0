import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/tab/horizontal_tabs.dart';

import '../../support/widget_test_harness.dart';

BoxDecoration _tabsDecoration(WidgetTester tester) {
  final container = tester.widget<Container>(
    find.descendant(
      of: find.byType(HorizontalTabs),
      matching: find.byType(Container),
    ).first,
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('renders 2-tab and 3-tab layouts with the right states', (
    WidgetTester tester,
  ) async {
    var selectedIndex = 1;

    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HorizontalTabs(
                tabs: const [
                  HorizontalTabItem(label: 'General', showDot: true),
                  HorizontalTabItem(label: 'For You', showDot: true),
                ],
                selectedIndex: selectedIndex,
                onTabChanged: (index) {
                  setState(() => selectedIndex = index);
                },
              ),
              const SizedBox(height: 16),
              HorizontalTabs(
                tabs: const [
                  HorizontalTabItem(label: 'History'),
                  HorizontalTabItem(label: 'Info'),
                  HorizontalTabItem(label: 'Setting'),
                ],
                selectedIndex: 0,
                onTabChanged: (_) {},
              ),
            ],
          );
        },
      ),
    );

    expect(find.byType(HorizontalTabs), findsNWidgets(2));
    expect(find.text('General'), findsOneWidget);
    expect(find.text('For You'), findsOneWidget);
    expect(find.text('History'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Setting'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(HorizontalTabs),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle,
        ),
      ),
      findsNWidgets(2),
    );

    final selectedText = tester.widget<Text>(find.text('For You'));
    final unselectedText = tester.widget<Text>(find.text('General'));
    expect(selectedText.style?.color, ThemeColors.get('light', 'fill/contrast/600'));
    expect(unselectedText.style?.color, ThemeColors.get('light', 'text/base/500'));

    final decoration = _tabsDecoration(tester);
    expect(decoration.color, ThemeColors.get('light', 'fill/base/300'));
  });

  testWidgets('tapping a tab updates the selected index', (
    WidgetTester tester,
  ) async {
    var selectedIndex = 0;

    await pumpTestApp(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          return HorizontalTabs(
            tabs: const [
              HorizontalTabItem(label: 'One'),
              HorizontalTabItem(label: 'Two'),
            ],
            selectedIndex: selectedIndex,
            onTabChanged: (index) {
              setState(() => selectedIndex = index);
            },
          );
        },
      ),
    );

    await tester.tap(find.text('Two'));
    await tester.pump();

    expect(selectedIndex, 1);
    expect(
      tester.widget<Text>(find.text('Two')).style?.color,
      ThemeColors.get('light', 'fill/contrast/600'),
    );
  });
}
