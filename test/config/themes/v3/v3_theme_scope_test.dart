import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/v3/v3_color_palette.dart';
import 'package:mcp_test_app/config/themes/v3/v3_primitives.dart';
import 'package:mcp_test_app/config/themes/v3/v3_theme_scope.dart';

void main() {
  test('maps State/error to the Figma primitive in each mode', () {
    expect(V3ColorPalette.light.stateError, V3PrimitiveColors.red600);
    expect(V3ColorPalette.dark.stateError, V3PrimitiveColors.red500);
  });

  testWidgets('selects Light palette from Theme brightness', (tester) async {
    V3ColorPalette? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.light),
        home: Builder(
          builder: (context) {
            selected = V3ThemeScope.colorsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(identical(selected, V3ColorPalette.light), isTrue);
  });

  testWidgets('selects Dark palette from Theme brightness', (tester) async {
    V3ColorPalette? selected;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Builder(
          builder: (context) {
            selected = V3ThemeScope.colorsOf(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(identical(selected, V3ColorPalette.dark), isTrue);
  });
}
