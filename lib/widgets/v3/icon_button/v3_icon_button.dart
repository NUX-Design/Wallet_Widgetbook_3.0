import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_color_palette.dart';
import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_primitives.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';

enum V3IconButtonSize { small, medium, large, defaultSize }

enum V3IconButtonState { defaultState, hoverActive, disabled }

/// Theme V3 circular icon-only action mapped to Figma node `24:9246`.
class V3IconButton extends StatelessWidget {
  const V3IconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.size = V3IconButtonSize.defaultSize,
    this.state = V3IconButtonState.defaultState,
    this.semanticHint,
    this.tooltip,
    this.focusNode,
    this.autofocus = false,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final V3IconButtonSize size;
  final V3IconButtonState state;
  final String? semanticHint;
  final String? tooltip;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get _isEnabled =>
      onPressed != null && state != V3IconButtonState.disabled;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    final metrics = _V3IconButtonMetrics.forSize(size);

    Widget button = Semantics(
      button: true,
      enabled: _isEnabled,
      label: semanticLabel,
      hint: semanticHint,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const ValueKey('v3-icon-button-target'),
          dimension: metrics.targetSize,
          child: Center(
            child: DecoratedBox(
              key: const ValueKey('v3-icon-button-decoration'),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(V3Radii.roundedFull),
                boxShadow: V3PrimitiveShadows.base,
              ),
              child: SizedBox.square(
                dimension: metrics.visualSize,
                child: TextButton(
                  key: const ValueKey('v3-icon-button-control'),
                  onPressed: _isEnabled ? onPressed : null,
                  focusNode: focusNode,
                  autofocus: autofocus,
                  style: _buttonStyle(colors, metrics),
                  child: IconTheme.merge(
                    data: IconThemeData(size: metrics.iconSize),
                    child: SizedBox.square(
                      key: const ValueKey('v3-icon-button-icon-host'),
                      dimension: metrics.iconSize,
                      child: Center(child: icon),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }

  ButtonStyle _buttonStyle(
    V3ColorPalette colors,
    _V3IconButtonMetrics metrics,
  ) {
    return ButtonStyle(
      fixedSize: WidgetStatePropertyAll(Size.square(metrics.visualSize)),
      minimumSize: WidgetStatePropertyAll(Size.square(metrics.visualSize)),
      maximumSize: WidgetStatePropertyAll(Size.square(metrics.visualSize)),
      padding: WidgetStatePropertyAll(EdgeInsets.all(metrics.padding)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(V3Radii.roundedFull),
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => _isDisabled(states)
            ? colors.contentNeutral2
            : colors.contentPrimary,
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (_isDisabled(states)) {
          return colors.backgroundNeutral;
        }
        return _isActive(states)
            ? colors.borderPrimary
            : colors.contentTertiary;
      }),
      overlayColor: const WidgetStatePropertyAll(V3PrimitiveColors.blackAlpha0),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(V3PrimitiveColors.blackAlpha0),
    );
  }

  bool _isDisabled(Set<WidgetState> states) =>
      !_isEnabled || states.contains(WidgetState.disabled);

  bool _isActive(Set<WidgetState> states) =>
      state == V3IconButtonState.hoverActive ||
      states.contains(WidgetState.hovered) ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.focused);
}

class _V3IconButtonMetrics {
  const _V3IconButtonMetrics({
    required this.visualSize,
    required this.padding,
    required this.iconSize,
  });

  factory _V3IconButtonMetrics.forSize(V3IconButtonSize size) {
    switch (size) {
      case V3IconButtonSize.small:
        return const _V3IconButtonMetrics(
          visualSize: V3Spacing.space32,
          padding: V3Spacing.space4,
          iconSize: V3Spacing.space16,
        );
      case V3IconButtonSize.medium:
        return const _V3IconButtonMetrics(
          visualSize: V3Spacing.space40,
          padding: V3Spacing.space8,
          iconSize: V3Spacing.space16,
        );
      case V3IconButtonSize.large:
        return const _V3IconButtonMetrics(
          visualSize: 48,
          padding: V3Spacing.space8,
          iconSize: V3Spacing.space24,
        );
      case V3IconButtonSize.defaultSize:
        return const _V3IconButtonMetrics(
          visualSize: V3Spacing.space56,
          padding: 10,
          iconSize: V3Spacing.space24,
        );
    }
  }

  final double visualSize;
  final double padding;
  final double iconSize;

  double get targetSize => visualSize < 48 ? 48 : visualSize;
}
