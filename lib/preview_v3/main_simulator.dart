import 'package:flutter/material.dart';

import '../widgets/v3/button/v3_default_button.dart';
import '../widgets/v3/splash/preview_v3_splash_animation.dart';
import 'preview_app.dart';
import 'preview_definition.dart';
import 'preview_registry.dart';

/// Native debug entrypoint for the Widget V3 preview host.
///
/// Select a preview with `--dart-define=V3_PREVIEW_SLUG=<category>/<Widget>`.
///
/// Every run through this entrypoint plays the "wi splash"
/// [V3SplashAnimationPreview] first as a pre-loading screen, then redirects
/// to the requested preview (resolved the same way [V3PreviewRoute] always
/// has, via [rawSlug]). That destination screen shows a CTA button pinned to
/// the bottom which loops back to the splash screen, so the flow repeats
/// indefinitely: splash -> destination -> CTA -> splash -> ...
///
/// Exception: when [rawSlug] itself resolves to the splash preview (e.g.
/// `V3_PREVIEW_SLUG=splash/V3SplashAnimation`), the destination screen omits
/// the CTA — looping "back to splash" while already viewing
/// [V3SplashAnimationPreview] has nothing meaningful to do, and this keeps
/// that debug view identical to the raw preview file's own output. This is
/// handled in `_V3SimulatorLoopDestination`, not in
/// `preview_v3_splash_animation.dart` itself, which has no knowledge of the
/// CTA or this loop.
///
/// See `docs/v3/V3_SIMULATOR_DEBUG_PREVIEW.md` for the operational source of
/// truth on this behavior.
void main() {
  const rawSlug = String.fromEnvironment('V3_PREVIEW_SLUG');
  runApp(const V3SimulatorSplashLoopApp(rawSlug: rawSlug));
}

class V3SimulatorSplashLoopApp extends StatelessWidget {
  const V3SimulatorSplashLoopApp({super.key, required this.rawSlug});

  final String rawSlug;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget V3 Simulator Debug Preview',
      home: V3SimulatorSplashLoopHost(rawSlug: rawSlug),
    );
  }
}

/// Owns the splash <-> destination loop state so neither
/// [V3SplashAnimationPreview] nor [V3PreviewRoute] needs to know about the
/// other.
class V3SimulatorSplashLoopHost extends StatefulWidget {
  const V3SimulatorSplashLoopHost({super.key, required this.rawSlug});

  final String rawSlug;

  @override
  State<V3SimulatorSplashLoopHost> createState() =>
      _V3SimulatorSplashLoopHostState();
}

class _V3SimulatorSplashLoopHostState extends State<V3SimulatorSplashLoopHost> {
  bool _showSplash = true;

  void _goToDestination() => setState(() => _showSplash = false);

  void _loopBackToSplash() => setState(() => _showSplash = true);

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return V3SplashAnimationPreview(
        key: const ValueKey('v3-simulator-splash-loop-splash'),
        onCompleted: _goToDestination,
      );
    }
    return _V3SimulatorLoopDestination(
      key: const ValueKey('v3-simulator-splash-loop-destination'),
      rawSlug: widget.rawSlug,
      onLoopBackToSplash: _loopBackToSplash,
    );
  }
}

/// Renders the requested preview (same resolution [V3PreviewRoute] always
/// used) with a CTA pinned to the bottom that restarts the splash loop.
///
/// The CTA is omitted when the resolved destination is the splash preview
/// itself (e.g. `V3_PREVIEW_SLUG=splash/V3SplashAnimation`) — looping "back
/// to splash" while already looking at splash is meaningless, and the CTA
/// would just sit on top of the animation with nothing useful to do.
class _V3SimulatorLoopDestination extends StatelessWidget {
  const _V3SimulatorLoopDestination({
    super.key,
    required this.rawSlug,
    required this.onLoopBackToSplash,
  });

  final String rawSlug;
  final VoidCallback onLoopBackToSplash;

  bool get _resolvesToSplash {
    final normalized = normalizeV3PreviewSlug(rawSlug);
    if (normalized.isNotEmpty) {
      return V3PreviewRegistry.resolve(normalized)?.category == 'splash';
    }
    final registered = V3PreviewRegistry.all();
    return registered.isNotEmpty && registered.first.category == 'splash';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: V3PreviewRoute(rawSlug: rawSlug)),
        if (!_resolvesToSplash)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: V3DefaultButton(
                key: const ValueKey('v3-simulator-splash-loop-cta'),
                label: 'Loop back to splash',
                variant: V3DefaultButtonVariant.primary,
                state: V3DefaultButtonState.defaultState,
                onPressed: onLoopBackToSplash,
              ),
            ),
          ),
      ],
    );
  }
}
