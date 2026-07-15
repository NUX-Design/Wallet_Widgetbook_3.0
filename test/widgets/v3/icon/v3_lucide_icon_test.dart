import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_icon_size.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_icon_stroke.dart';
import 'package:mcp_test_app/widgets/v3/icon/v3_lucide_icon.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  TextStyle glyphStyle(WidgetTester tester) {
    final richText = tester.widget<RichText>(find.byType(RichText));
    return (richText.text as TextSpan).style!;
  }

  String glyphText(WidgetTester tester) {
    final richText = tester.widget<RichText>(find.byType(RichText));
    return (richText.text as TextSpan).text!;
  }

  testWidgets('defaults to medium size and regular weight family', (
    tester,
  ) async {
    await pumpTestApp(tester, const V3LucideIcon(LucideIcons.house));

    expect(tester.getSize(find.byType(V3LucideIcon)), const Size.square(24));
    expect(
      glyphStyle(tester).fontFamily,
      'packages/lucide_icons_flutter/Lucide',
    );
    expect(glyphText(tester), String.fromCharCode(LucideIcons.house.codePoint));
  });

  testWidgets('explicit size wins over ambient IconTheme', (tester) async {
    await pumpTestApp(
      tester,
      IconTheme(
        data: const IconThemeData(size: 32),
        child: const V3LucideIcon(LucideIcons.house, size: V3IconSize.tiny),
      ),
    );

    expect(
      tester.getSize(find.byType(V3LucideIcon)),
      Size.square(V3IconSize.tiny.value),
    );
    expect(glyphStyle(tester).fontSize, V3IconSize.tiny.value);
  });

  testWidgets('falls back to ambient IconTheme size when unset', (
    tester,
  ) async {
    await pumpTestApp(
      tester,
      const IconTheme(
        data: IconThemeData(size: 32),
        child: V3LucideIcon(LucideIcons.house),
      ),
    );

    expect(tester.getSize(find.byType(V3LucideIcon)), const Size.square(32));
  });

  testWidgets('color always flows from ambient IconTheme', (tester) async {
    await pumpTestApp(
      tester,
      const IconTheme(
        data: IconThemeData(color: Colors.red),
        child: V3LucideIcon(LucideIcons.house),
      ),
    );

    expect(glyphStyle(tester).color, Colors.red);
  });

  testWidgets('maps every stroke role to its documented weight family', (
    tester,
  ) async {
    const package = 'packages/lucide_icons_flutter';
    final expected = <V3IconStroke, String>{
      V3IconStroke.thin: '$package/Lucide100',
      V3IconStroke.light: '$package/Lucide300',
      V3IconStroke.regular: '$package/Lucide',
      V3IconStroke.bold: '$package/Lucide600',
    };

    for (final entry in expected.entries) {
      await pumpTestApp(
        tester,
        V3LucideIcon(LucideIcons.house, stroke: entry.key),
      );
      expect(
        glyphStyle(tester).fontFamily,
        entry.value,
        reason: entry.key.name,
      );
      expect(
        glyphText(tester),
        String.fromCharCode(LucideIcons.house.codePoint),
        reason: entry.key.name,
      );
    }
  });

  testWidgets('is decorative by default and exposes explicit semantic label', (
    tester,
  ) async {
    await pumpTestApp(tester, const V3LucideIcon(LucideIcons.house));
    expect(find.bySemanticsLabel('หน้าแรก'), findsNothing);

    await pumpTestApp(
      tester,
      const V3LucideIcon(LucideIcons.house, semanticLabel: 'หน้าแรก'),
    );
    expect(find.bySemanticsLabel('หน้าแรก'), findsOneWidget);
  });

  testWidgets(
    'svgAsset present renders SvgPicture instead of the package font',
    (tester) async {
      const assetPath = 'lib/assets/icons/v3/lucide/house.svg';
      await pumpTestApp(
        tester,
        const IconTheme(
          data: IconThemeData(color: Colors.blue, size: 20),
          child: V3LucideIcon(LucideIcons.house, svgAsset: assetPath),
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(assetPaths: const [assetPath]),
      );

      expect(find.byType(RichText), findsNothing);
      final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(svg.width, 20);
      expect(svg.height, 20);
    },
  );

  group('package renderer vs checked-in SVG override parity (real asset)', () {
    const verifiedOverride = 'lib/assets/icons/v3/lucide/scan-line.svg';

    testWidgets(
      'both renderers occupy the same size under the same IconTheme',
      (tester) async {
        await pumpTestApp(
          tester,
          IconTheme(
            data: IconThemeData(
              color: Colors.teal,
              size: V3IconSize.large.value,
            ),
            child: const V3LucideIcon(LucideIcons.scanLine),
          ),
        );
        final packageSize = tester.getSize(find.byType(V3LucideIcon));

        await pumpTestApp(
          tester,
          IconTheme(
            data: IconThemeData(
              color: Colors.teal,
              size: V3IconSize.large.value,
            ),
            child: const V3LucideIcon(
              LucideIcons.scanLine,
              svgAsset: verifiedOverride,
            ),
          ),
        );
        final svgSize = tester.getSize(find.byType(V3LucideIcon));

        expect(svgSize, packageSize);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'SVG override loads and renders the real checked-in asset offline',
      (tester) async {
        await pumpTestApp(
          tester,
          const IconTheme(
            data: IconThemeData(color: Colors.teal, size: 32),
            child: V3LucideIcon(
              LucideIcons.scanLine,
              svgAsset: verifiedOverride,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
