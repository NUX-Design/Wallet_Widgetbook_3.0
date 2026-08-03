import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_color_palette.dart';
import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_primitives.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';

enum V3SmallButtonVariant { primary, outline, ghost }

enum V3SmallButtonState { defaultState, active, disabled, error }

/// Theme V3 Small button mapped to Wi Design System Figma node `504:1780`
/// (`Size=Small`), sharing color/token tokens with [V3SmallButtonVariant]
/// per `button.md`'s "Color tokens are independent of size" invariant.
class V3SmallButton extends StatelessWidget {
  const V3SmallButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = V3SmallButtonVariant.primary,
    this.state = V3SmallButtonState.defaultState,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.semanticLabel,
    this.semanticHint,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final V3SmallButtonVariant variant;
  final V3SmallButtonState state;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final String? semanticLabel;
  final String? semanticHint;
  final String? tooltip;

  bool get _isEnabled =>
      onPressed != null && !isLoading && state != V3SmallButtonState.disabled;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    final metrics = _V3SmallButtonMetrics.forVariant(variant);
    final effectiveLeading =
        isLoading
            ? SizedBox.square(
              dimension: metrics.iconSize,
              child: CircularProgressIndicator(
                key: const ValueKey('v3-small-button-progress'),
                strokeWidth: 2,
                color: colors.contentNeutral2,
              ),
            )
            : leadingIcon;

    Widget button = Semantics(
      button: true,
      enabled: _isEnabled,
      toggled: state == V3SmallButtonState.active ? true : null,
      label: semanticLabel ?? label,
      hint: semanticHint,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: const ValueKey('v3-small-button-decoration'),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(V3Radii.roundedFull),
            boxShadow: _boxShadow,
          ),
          child: TextButton(
            onPressed: _isEnabled ? onPressed : null,
            style: _buttonStyle(colors, metrics),
            child: _ButtonContent(
              label: label,
              leadingIcon: effectiveLeading,
              trailingIcon: trailingIcon,
              metrics: metrics,
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
    _V3SmallButtonMetrics metrics,
  ) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, metrics.height)),
      maximumSize: WidgetStatePropertyAll(
        Size(double.infinity, metrics.height),
      ),
      padding: WidgetStatePropertyAll(metrics.padding),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(V3Radii.roundedFull),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        V3Typography.labelSmall.copyWith(
          decoration:
              variant == V3SmallButtonVariant.ghost
                  ? TextDecoration.underline
                  : TextDecoration.none,
        ),
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => _foregroundColor(colors, states),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => _backgroundColor(colors, states),
      ),
      overlayColor: const WidgetStatePropertyAll(V3PrimitiveColors.blackAlpha0),
      side: WidgetStateProperty.resolveWith(
        (states) => _borderSide(colors, states),
      ),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(V3PrimitiveColors.blackAlpha0),
    );
  }

  List<BoxShadow> get _boxShadow {
    final hasShadow =
        variant == V3SmallButtonVariant.outline &&
        _isEnabled &&
        (state == V3SmallButtonState.defaultState ||
            state == V3SmallButtonState.active);
    return hasShadow ? V3PrimitiveShadows.sm : const <BoxShadow>[];
  }

  Color _foregroundColor(V3ColorPalette colors, Set<WidgetState> states) {
    if (_isDisabled(states)) {
      return variant == V3SmallButtonVariant.ghost
          ? colors.contentNeutral
          : colors.contentNeutral2;
    }
    if (variant == V3SmallButtonVariant.primary) {
      return colors.contentWhite;
    }
    if (variant == V3SmallButtonVariant.outline) {
      return _isError ? colors.stateError : colors.contentPrimary;
    }
    if (_isError) {
      return colors.contentNeutral;
    }
    return _isActive(states)
        ? colors.borderExtensionInfo
        : colors.contentExtensionNavy;
  }

  Color _backgroundColor(V3ColorPalette colors, Set<WidgetState> states) {
    if (variant == V3SmallButtonVariant.ghost) {
      return V3PrimitiveColors.blackAlpha0;
    }
    if (_isDisabled(states)) {
      return colors.backgroundNeutral;
    }
    if (_isError) {
      return variant == V3SmallButtonVariant.primary
          ? colors.stateError
          : colors.buttonSecondary;
    }
    if (variant == V3SmallButtonVariant.outline) {
      return _isActive(states)
          ? V3PrimitiveColors.blackAlpha5
          : colors.buttonSecondary;
    }
    return _isActive(states) ? colors.borderTertiary : colors.buttonPrimary;
  }

  BorderSide _borderSide(V3ColorPalette colors, Set<WidgetState> states) {
    if (variant != V3SmallButtonVariant.outline || _isDisabled(states)) {
      return BorderSide.none;
    }
    if (_isError) {
      return BorderSide(color: colors.borderExtensionError);
    }
    return BorderSide(
      color: _isActive(states) ? colors.contentNeutral : colors.borderSlate,
    );
  }

  bool get _isError => state == V3SmallButtonState.error;

  bool _isDisabled(Set<WidgetState> states) =>
      !_isEnabled || states.contains(WidgetState.disabled);

  bool _isActive(Set<WidgetState> states) =>
      state == V3SmallButtonState.active ||
      states.contains(WidgetState.pressed) ||
      states.contains(WidgetState.focused);
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.metrics,
  });

  final String label;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final _V3SmallButtonMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(size: metrics.iconSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: metrics.gap,
        children: [
          if (leadingIcon != null) _icon(leadingIcon!),
          Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          if (trailingIcon != null) _icon(trailingIcon!),
        ],
      ),
    );
  }

  Widget _icon(Widget icon) {
    return SizedBox.square(
      dimension: metrics.iconSize,
      child: Center(child: icon),
    );
  }
}

class _V3SmallButtonMetrics {
  const _V3SmallButtonMetrics({
    required this.height,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gap,
  });

  /// `504:1780` `Size=Small` height (36px) has no bound V3 dimension token
  /// in the current Figma export (`height.token == null` for every size in
  /// `button-_base.json`); kept as a literal to stay Figma-traceable.
  factory _V3SmallButtonMetrics.forVariant(V3SmallButtonVariant variant) {
    return variant == V3SmallButtonVariant.ghost
        ? const _V3SmallButtonMetrics(
          height: V3Spacing.space20,
          horizontalPadding: V3Spacing.space0,
          verticalPadding: V3Spacing.space0,
          gap: V3Spacing.space6,
        )
        : const _V3SmallButtonMetrics(
          height: 36,
          horizontalPadding: V3Spacing.space16,
          verticalPadding: V3Spacing.space2,
          gap: V3Spacing.space6,
        );
  }

  final double height;
  final double horizontalPadding;
  final double verticalPadding;
  final double gap;
  final double iconSize = V3Spacing.space16;

  EdgeInsets get padding => EdgeInsets.symmetric(
    horizontal: horizontalPadding,
    vertical: verticalPadding,
  );
}
