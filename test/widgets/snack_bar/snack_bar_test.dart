import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/snack_bar/snack_bar.dart';

void main() {
  group('SnackBarWidget UI Tests', () {
    testWidgets('renders Success SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SnackBarWidget(
              title: 'Success Message',
              type: SnackBarType.success,
            ),
          ),
        ),
      );

      // Verify Title
      expect(find.text('Success Message'), findsOneWidget);

      // Verify Icon
      final svgFinder = find.byWidgetPredicate((widget) {
        return widget is SvgPicture &&
            widget.bytesLoader is SvgAssetLoader &&
            (widget.bytesLoader as SvgAssetLoader).assetName ==
                'lib/assets/images/checkmark-circle-01.svg';
      });
      expect(svgFinder, findsOneWidget);

      // Verify Container Decoration (Background Color & Border Radius)
      final containerFinder = find.descendant(
        of: find.byType(SnackBarWidget),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration;

      // Check Border Radius
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.color, ThemeColors.get('light', 'success/300'));

      final text = tester.widget<Text>(find.text('Success Message'));
      expect(text.style?.color, ThemeColors.get('light', 'text/base/success'));
    });

    testWidgets('renders Warning SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SnackBarWidget(
              title: 'Warning Message',
              type: SnackBarType.warning,
            ),
          ),
        ),
      );

      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders Error SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SnackBarWidget(
              title: 'Error Message',
              type: SnackBarType.error,
            ),
          ),
        ),
      );

      expect(find.text('Error Message'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });
  });

  group('SnackBarWidget Integration Tests', () {
    testWidgets('SnackBarWidget.show displays SnackBar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder:
                  (context) => ElevatedButton(
                    onPressed: () {
                      SnackBarWidget.show(
                        context,
                        title: 'Integration Test',
                        type: SnackBarType.success,
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
            ),
          ),
        ),
      );

      // Tap the button
      await tester.tap(find.text('Show SnackBar'));
      await tester.pump(); // Start animation

      // Verify SnackBar appears
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, Colors.transparent);
      expect(find.byType(SnackBarWidget), findsOneWidget);
      expect(find.text('Integration Test'), findsOneWidget);

      // Wait for animation to finish (optional, but good practice if checking disappearance)
      await tester.pumpAndSettle();
    });
  });
}
