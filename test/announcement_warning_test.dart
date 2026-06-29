import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/announce/announcement_danger.dart';
import 'package:mcp_test_app/widgets/announce/announcement_warning.dart';

import 'support/widget_test_harness.dart';

final _alertAssets = PlaceholderAssetBundle(
  assetPaths: const <String>['lib/assets/images/Alert Icon.svg'],
);

Finder _alertIconFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'lib/assets/images/Alert Icon.svg';
  });
}

void main() {
  testWidgets('AnnouncementWarning renders warning state and rich text', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const AnnouncementWarning(
        title: 'Please review',
        description: 'This should not be used when spans are present.',
        descriptionSpans: <TextSpan>[
          TextSpan(
            text: '*Hold Amount',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' means funds are not available yet.'),
        ],
      ),
      themeVariant: TestThemeVariant.light,
      assetBundle: _alertAssets,
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AnnouncementWarning),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('light', 'warning/600'));
    expect(find.text('Please review'), findsOneWidget);
    expect(_alertIconFinder(), findsOneWidget);

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('*Hold Amount'),
      ),
    );
    final span = richText.text as TextSpan;
    expect(span.children, isNotNull);
    expect((span.children as List<InlineSpan>).length, 2);
    expect(
      ((span.children as List<InlineSpan>).first as TextSpan).text,
      '*Hold Amount',
    );
  });

  testWidgets('AnnouncementWarning hides title when empty', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const AnnouncementWarning(title: '', description: 'Only description'),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );

    expect(find.text('Only description'), findsOneWidget);
    expect(find.text('Please review'), findsNothing);
  });

  testWidgets('AnnouncementWarning supports danger state', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const AnnouncementWarning(
        title: 'Danger',
        description: 'Be careful',
        state: AnnouncementState.danger,
      ),
      themeVariant: TestThemeVariant.light,
      assetBundle: _alertAssets,
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AnnouncementWarning),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('light', 'danger/600'));
    expect(find.text('Danger'), findsOneWidget);
  });

  testWidgets('AnnouncementDanger uses danger colors and optional title', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const AnnouncementDanger(
        title: 'Critical error',
        description: 'Please stop and resolve the issue.',
      ),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(AnnouncementDanger),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('dark', 'danger/600'));
    expect(find.text('Critical error'), findsOneWidget);
    expect(_alertIconFinder(), findsOneWidget);
  });

  testWidgets('AnnouncementDanger supports description spans without title', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const AnnouncementDanger(
        title: '',
        description: '',
        descriptionSpans: <TextSpan>[
          TextSpan(
            text: 'Critical',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: ' issue detected'),
        ],
      ),
      themeVariant: TestThemeVariant.light,
      assetBundle: _alertAssets,
    );

    final richText = tester.widget<RichText>(
      find.byWidgetPredicate(
        (widget) =>
            widget is RichText &&
            widget.text.toPlainText().contains('Critical issue detected'),
      ),
    );
    final span = richText.text as TextSpan;
    expect(span.children, isNotNull);
    expect((span.children as List<InlineSpan>).length, 2);
  });
}
