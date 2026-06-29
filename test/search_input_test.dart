import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/input/search_input.dart';

import 'support/widget_test_harness.dart';

final _searchAssets = PlaceholderAssetBundle(
  assetPaths: const <String>[
    'lib/assets/images/search-02.svg',
    'lib/assets/images/cancel-circle.svg',
  ],
);

Finder _assetFinder(String assetPath) {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName == assetPath;
  });
}

void main() {
  testWidgets('SearchInput renders placeholder and icon state', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(tester, const SearchInput(), assetBundle: _searchAssets);

    expect(find.text('Search'), findsOneWidget);
    expect(_assetFinder('lib/assets/images/search-02.svg'), findsOneWidget);
    expect(_assetFinder('lib/assets/images/cancel-circle.svg'), findsNothing);
  });

  testWidgets('SearchInput changes border on focus and clears text', (
    WidgetTester tester,
  ) async {
    String? changedValue;

    await pumpTestApp(
      tester,
      SearchInput(onChanged: (value) => changedValue = value),
      assetBundle: _searchAssets,
    );

    await tester.tap(find.byType(TextField));
    await tester.pump();

    final focusedContainer = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(SearchInput),
            matching: find.byType(Container),
          )
          .at(0),
    );
    final focusedDecoration = focusedContainer.decoration! as BoxDecoration;
    expect(
      focusedDecoration.border!.top.color,
      ThemeColors.get('light', 'primary/400'),
    );

    await tester.enterText(find.byType(TextField), 'wallet');
    await tester.pump();

    expect(changedValue, 'wallet');
    expect(_assetFinder('lib/assets/images/cancel-circle.svg'), findsOneWidget);

    final clearGesture = tester.widget<GestureDetector>(
      find.ancestor(
        of: _assetFinder('lib/assets/images/cancel-circle.svg'),
        matching: find.byType(GestureDetector),
      ),
    );
    clearGesture.onTap?.call();
    await tester.pump();

    expect(changedValue, '');
    expect(find.text('wallet'), findsNothing);
  });

  testWidgets('SearchInput syncs with controller updates', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController(text: 'hello');

    await pumpTestApp(
      tester,
      SearchInput(controller: controller),
      assetBundle: _searchAssets,
    );

    expect(find.text('hello'), findsOneWidget);
    expect(_assetFinder('lib/assets/images/cancel-circle.svg'), findsOneWidget);

    controller.text = 'world';
    await tester.pump();

    expect(find.text('world'), findsOneWidget);
  });
}
