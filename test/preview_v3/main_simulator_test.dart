import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/preview_v3/main_simulator.dart';
import 'package:mcp_test_app/widgets/v3/button/preview_v3_mini_button.dart';
import 'package:mcp_test_app/widgets/v3/splash/preview_v3_splash_animation.dart';

void main() {
  group('V3SimulatorSplashLoopHost', () {
    testWidgets(
      'plays the splash first, then shows the destination with a CTA, '
      'then loops back to the splash when the CTA is tapped',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: V3SimulatorSplashLoopHost(rawSlug: 'button/V3MiniButton'),
          ),
        );

        expect(find.byType(V3SplashAnimationPreview), findsOneWidget);
        expect(find.byType(V3MiniButtonPreview), findsNothing);

        // Let the asset load (async) before the controller can even start,
        // then advance past wi_splash.json's ~3s duration (181 frames @
        // 60fps) so the animation completes and the host swaps to the
        // destination.
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(find.byType(V3SplashAnimationPreview), findsNothing);
        expect(find.byType(V3MiniButtonPreview), findsOneWidget);
        final ctaFinder = find.byKey(
          const ValueKey('v3-simulator-splash-loop-cta'),
        );
        expect(ctaFinder, findsOneWidget);

        await tester.tap(ctaFinder);
        await tester.pump();

        expect(find.byType(V3SplashAnimationPreview), findsOneWidget);
        expect(find.byType(V3MiniButtonPreview), findsNothing);
      },
    );

    testWidgets(
      'omits the loop-back CTA when the destination is the splash preview '
      'itself',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: V3SimulatorSplashLoopHost(
              rawSlug: 'splash/V3SplashAnimation',
            ),
          ),
        );

        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 100));

        expect(
          find.byKey(const ValueKey('v3-simulator-splash-loop-destination')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('v3-simulator-splash-loop-cta')),
          findsNothing,
        );
      },
    );
  });
}
