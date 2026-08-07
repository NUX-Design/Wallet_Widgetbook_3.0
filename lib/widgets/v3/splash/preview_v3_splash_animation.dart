import 'package:flutter/material.dart';

import 'v3_splash_animation.dart';
import 'v3_wi_splash_animation.dart';

void main() => runApp(const V3SplashAnimationPreviewApp());

class V3SplashAnimationPreviewApp extends StatelessWidget {
  const V3SplashAnimationPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3SplashAnimationPreview(),
    );
  }
}

/// Which implementation renders the "wi splash" intro in
/// [V3SplashAnimationPreview].
enum V3SplashRenderer {
  /// The original Lottie export (`lib/assets/lottie/wi_splash.json`),
  /// played through [V3SplashAnimation].
  lottie,

  /// The native Flutter reimplementation ported from `Splash.svg`'s static
  /// vector paths, played through [V3WiSplashAnimation].
  svg,
}

/// Preview for the full "wi splash" intro — real vector paths for the W
/// mark and the wi wallet logo, exported from the design tool.
///
/// Renders full-bleed with no overlay chrome (no title bar, no replay
/// control): a real app splash screen shows only the animation itself.
/// [renderer] selects which implementation plays; picking a renderer is the
/// caller's job — e.g. [lib/preview_v3/main_simulator.dart]'s simulator
/// debug loop exposes the choice on its destination screen, not here.
///
/// [onCompleted], when provided, fires once the animation finishes playing
/// forward — used by [lib/preview_v3/main_simulator.dart] to drive a
/// splash-then-destination-then-loop demo flow without this file needing to
/// know anything about that flow.
class V3SplashAnimationPreview extends StatelessWidget {
  const V3SplashAnimationPreview({
    super.key,
    this.renderer = V3SplashRenderer.lottie,
    this.onCompleted,
  });

  final V3SplashRenderer renderer;
  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: switch (renderer) {
        V3SplashRenderer.lottie => V3SplashAnimation(
          key: const ValueKey('v3-splash-animation-wi-splash-lottie'),
          assetPath: 'lib/assets/lottie/wi_splash.json',
          onCompleted: onCompleted,
        ),
        V3SplashRenderer.svg => V3WiSplashAnimation(
          key: const ValueKey('v3-splash-animation-wi-splash-svg'),
          onCompleted: onCompleted,
        ),
      },
    );
  }
}
