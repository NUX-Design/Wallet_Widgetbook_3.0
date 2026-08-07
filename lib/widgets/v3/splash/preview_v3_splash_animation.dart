import 'package:flutter/material.dart';

import 'v3_splash_animation.dart';

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

/// Preview for the full "wi splash" Lottie export — real vector paths for
/// the W mark and the wi wallet logo, exported from the design tool.
///
/// Renders full-bleed with no overlay chrome (no title bar, no replay
/// control): a real app splash screen shows only the animation itself.
///
/// [onCompleted], when provided, fires once the animation finishes playing
/// forward — used by [lib/preview_v3/main_simulator.dart] to drive a
/// splash-then-destination-then-loop demo flow without this file needing to
/// know anything about that flow.
class V3SplashAnimationPreview extends StatelessWidget {
  const V3SplashAnimationPreview({super.key, this.onCompleted});

  final VoidCallback? onCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: V3SplashAnimation(
        key: const ValueKey('v3-splash-animation-wi-splash'),
        assetPath: 'lib/assets/lottie/wi_splash.json',
        onCompleted: onCompleted,
      ),
    );
  }
}
