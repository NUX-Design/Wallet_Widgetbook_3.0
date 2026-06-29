import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/snack_bar/snack_bar.dart';

import '../../support/widget_test_harness.dart';

void main() {
  group('SnackBarWidget UI Tests', () {
    testWidgets('renders Success SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const SnackBarWidget(
          title: 'Success Message',
          type: SnackBarType.success,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/checkmark-circle-01.svg',
            'lib/assets/images/Alert Icon.svg',
            'lib/assets/images/outline-cancel-circle.svg',
          ],
        ),
      );

      expect(find.text('Success Message'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SnackBarWidget),
          matching: find.byType(Container),
        ).first,
      );
      final decoration = container.decoration as BoxDecoration;
      final icon = tester.widget<SvgPicture>(find.byType(SvgPicture));

      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(decoration.color, ThemeColors.get('light', 'success/300'));
      expect(icon.width, 24);
    });

    testWidgets('renders Warning SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const SnackBarWidget(
          title: 'Warning Message',
          type: SnackBarType.warning,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/checkmark-circle-01.svg',
            'lib/assets/images/Alert Icon.svg',
            'lib/assets/images/outline-cancel-circle.svg',
          ],
        ),
      );

      expect(find.text('Warning Message'), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
    });

    testWidgets('renders Error SnackBar correctly', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const SnackBarWidget(
          title: 'Error Message',
          type: SnackBarType.error,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/checkmark-circle-01.svg',
            'lib/assets/images/Alert Icon.svg',
            'lib/assets/images/outline-cancel-circle.svg',
          ],
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
      await pumpTestApp(
        tester,
        Builder(
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
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/checkmark-circle-01.svg',
            'lib/assets/images/Alert Icon.svg',
            'lib/assets/images/outline-cancel-circle.svg',
          ],
        ),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(SnackBarWidget), findsOneWidget);
      expect(find.text('Integration Test'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, Colors.transparent);
      expect(snackBar.padding, EdgeInsets.zero);
      expect(snackBar.duration, const Duration(seconds: 6));

      await tester.pumpAndSettle();
    });
  });
}
