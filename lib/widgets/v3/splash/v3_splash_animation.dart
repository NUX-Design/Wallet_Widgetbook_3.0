import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';

/// Renders a Lottie splash/intro animation asset, filling the full
/// available space on any mobile device size.
///
/// This is an asset preview wrapper, not a Figma-sourced design-system
/// primitive — it exists to load and play arbitrary splash Lottie exports
/// (e.g. app intro sequences) consistently inside the V3 preview host, so it
/// intentionally does not carry the `<component>-_base.json` /
/// `<component>.md` Figma extraction pair that other `lib/widgets/v3/`
/// components require.
class V3SplashAnimation extends StatefulWidget {
  const V3SplashAnimation({
    super.key,
    required this.assetPath,
    this.autoPlay = true,
    this.repeat = false,
    this.onControllerReady,
    this.onCompleted,
  });

  final String assetPath;
  final bool autoPlay;
  final bool repeat;
  final ValueChanged<AnimationController>? onControllerReady;

  /// Fires once when the animation finishes playing forward (i.e. it is not
  /// [repeat]ing). Used to drive "splash finished, navigate onward" flows.
  final VoidCallback? onCompleted;

  @override
  State<V3SplashAnimation> createState() => _V3SplashAnimationState();
}

class _V3SplashAnimationState extends State<V3SplashAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    widget.onControllerReady?.call(_controller);
    _controller.addStatusListener(_handleStatusChanged);
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && !widget.repeat) {
      widget.onCompleted?.call();
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleStatusChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return ColoredBox(
      color: colors.backgroundPrimary,
      child: SizedBox.expand(
        child: Lottie.asset(
          widget.assetPath,
          controller: _controller,
          fit: BoxFit.cover,
          repeat: widget.repeat,
          onLoaded: (composition) {
            _controller.duration = composition.duration;
            if (widget.autoPlay) {
              _controller.forward(from: 0);
            }
          },
        ),
      ),
    );
  }
}
