import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

import '../../support/widget_test_harness.dart';

void main() {
  group('LottieSkeleton', () {
    testWidgets('returns the child directly when loading is disabled', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const LottieSkeleton(
          isLoading: false,
          child: Text('Loaded content'),
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
      );

      expect(find.text('Loaded content'), findsOneWidget);
      expect(find.byType(Lottie), findsNothing);
      expect(find.byType(Opacity), findsNothing);
    });

    testWidgets('renders the skeleton overlay with custom border radius', (
      WidgetTester tester,
    ) async {
      final bundle = PlaceholderAssetBundle(
        assetPaths: <String>[
          'lib/assets/lottie/wi_loader.json',
        ],
      );

      await pumpTestApp(
        tester,
        const Center(
          child: SizedBox(
            width: 160,
            height: 56,
            child: LottieSkeleton(
              isLoading: true,
              lottieAsset: 'lib/assets/lottie/wi_loader.json',
              borderRadius: BorderRadius.all(Radius.circular(12)),
              child: Text('Loaded content'),
            ),
          ),
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: bundle,
      );

      await tester.pump();

      expect(find.text('Loaded content'), findsOneWidget);
      expect(find.byType(Opacity), findsOneWidget);
      expect(find.byType(Lottie), findsOneWidget);

      final opacity = tester.widget<Opacity>(find.byType(Opacity));
      expect(opacity.opacity, 0);

      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(
        clipRRect.borderRadius,
        const BorderRadius.all(Radius.circular(12)),
      );
    });
  });
}
