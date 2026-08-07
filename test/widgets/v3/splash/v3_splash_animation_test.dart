import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mcp_test_app/widgets/v3/splash/v3_splash_animation.dart';

import '../../../support/widget_test_harness.dart';

void main() {
  group('V3SplashAnimation', () {
    testWidgets('renders the wi splash asset', (tester) async {
      await pumpTestApp(
        tester,
        const V3SplashAnimation(assetPath: 'lib/assets/lottie/wi_splash.json'),
        wrapWithScaffold: false,
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: const ['lib/assets/lottie/wi_splash.json'],
        ),
      );

      await tester.pump();

      final lottie = tester.widget<Lottie>(find.byType(Lottie));
      // Fills the full available space instead of letterboxing to a fixed
      // aspect ratio, so it stays edge-to-edge on any mobile device size.
      expect(lottie.fit, BoxFit.cover);
    });

    testWidgets('exposes the animation controller for replay', (tester) async {
      AnimationController? controller;

      await pumpTestApp(
        tester,
        V3SplashAnimation(
          assetPath: 'lib/assets/lottie/wi_splash.json',
          onControllerReady: (value) => controller = value,
        ),
        wrapWithScaffold: false,
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: const ['lib/assets/lottie/wi_splash.json'],
        ),
      );

      await tester.pump();

      expect(controller, isNotNull);
    });
  });
}
