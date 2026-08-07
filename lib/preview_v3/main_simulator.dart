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
///
/// Simulator-only default: when `V3_PREVIEW_SLUG` is not passed, this
/// entrypoint opens [_defaultSimulatorPreviewSlug] instead of falling back to
/// the registry's first entry (what [V3PreviewRoute] does when `main.dart`
/// Web or `preview_app.dart` are used with an empty slug). This keeps the
/// Simulator debug flow landing on a stable, chosen destination across runs
/// without touching the shared Web-facing default.
const _defaultSimulatorPreviewSlug = 'header/V3Header';

void main() {
  const rawSlug = String.fromEnvironment('V3_PREVIEW_SLUG');
  final effectiveSlug =
      rawSlug.trim().isEmpty ? _defaultSimulatorPreviewSlug : rawSlug;
  runApp(V3SimulatorSplashLoopApp(rawSlug: effectiveSlug));
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
  V3SplashRenderer _splashRenderer = V3SplashRenderer.lottie;

  void _goToDestination() => setState(() => _showSplash = false);

  void _loopBackToSplash() => setState(() => _showSplash = true);

  void _selectSplashRenderer(V3SplashRenderer renderer) {
    if (renderer == _splashRenderer) return;
    setState(() => _splashRenderer = renderer);
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return V3SplashAnimationPreview(
        key: const ValueKey('v3-simulator-splash-loop-splash'),
        renderer: _splashRenderer,
        onCompleted: _goToDestination,
      );
    }
    return _V3SimulatorLoopDestination(
      key: const ValueKey('v3-simulator-splash-loop-destination'),
      rawSlug: widget.rawSlug,
      splashRenderer: _splashRenderer,
      onSplashRendererChanged: _selectSplashRenderer,
      onLoopBackToSplash: _loopBackToSplash,
    );
  }
}

/// Renders the requested preview (same resolution [V3PreviewRoute] always
/// used) with a CTA pinned to the bottom that restarts the splash loop, and
/// a small "Lottie / SVG" renderer picker floated over the middle of the
/// screen that chooses which [V3SplashAnimationPreview] implementation the
/// *next* splash play uses — kept here instead of on the splash screen
/// itself so the splash stays full-bleed with no chrome, matching a real
/// app splash screen. The picker sits away from both the bottom CTA and an
/// arbitrary destination preview's own top-of-screen chrome (e.g.
/// `header/V3Header`'s close/info icons).
///
/// Both the CTA and the renderer picker are omitted when the resolved
/// destination is the splash preview itself (e.g.
/// `V3_PREVIEW_SLUG=splash/V3SplashAnimation`) — looping "back to splash"
/// while already looking at splash is meaningless, and either control would
/// just sit on top of the animation with nothing useful to do.
class _V3SimulatorLoopDestination extends StatelessWidget {
  const _V3SimulatorLoopDestination({
    super.key,
    required this.rawSlug,
    required this.splashRenderer,
    required this.onSplashRendererChanged,
    required this.onLoopBackToSplash,
  });

  final String rawSlug;
  final V3SplashRenderer splashRenderer;
  final ValueChanged<V3SplashRenderer> onSplashRendererChanged;
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
        if (!_resolvesToSplash) ...[
          Align(
            alignment: const Alignment(0, -0.2),
            child: _V3SplashRendererPicker(
              key: const ValueKey('v3-simulator-splash-renderer-picker'),
              value: splashRenderer,
              onChanged: onSplashRendererChanged,
            ),
          ),
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
      ],
    );
  }
}

/// Chooses which [V3SplashAnimationPreview] implementation the next splash
/// play uses. Styled as an overlay chip since it floats on top of an
/// arbitrary destination preview, not a themed host screen.
class _V3SplashRendererPicker extends StatelessWidget {
  const _V3SplashRendererPicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final V3SplashRenderer value;
  final ValueChanged<V3SplashRenderer> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(20),
      child: SegmentedButton<V3SplashRenderer>(
        segments: const [
          ButtonSegment(value: V3SplashRenderer.lottie, label: Text('Lottie')),
          ButtonSegment(value: V3SplashRenderer.svg, label: Text('SVG')),
        ],
        selected: {value},
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          foregroundColor: Colors.white,
          selectedForegroundColor: Colors.white,
          selectedBackgroundColor: Colors.white.withValues(alpha: 0.25),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
        ),
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}
