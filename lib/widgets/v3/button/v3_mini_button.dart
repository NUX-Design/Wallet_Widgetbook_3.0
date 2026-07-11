import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../config/themes/v3/v3_color_palette.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';

enum V3MiniButtonVariant { primary, outline, ghost }

enum V3MiniButtonState { defaultState, active, disabled, error }

/// Theme V3 Mini button mapped to Wi Design System Figma nodes `241:*`.
class V3MiniButton extends StatelessWidget {
  const V3MiniButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = V3MiniButtonVariant.primary,
    this.state = V3MiniButtonState.defaultState,
    this.leadingIcon,
    this.trailingIcon,
    this.isLoading = false,
    this.semanticLabel,
    this.semanticHint,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final V3MiniButtonVariant variant;
  final V3MiniButtonState state;
  final Widget? leadingIcon;
  final Widget? trailingIcon;
  final bool isLoading;
  final String? semanticLabel;
  final String? semanticHint;
  final String? tooltip;

  bool get _isEnabled =>
      onPressed != null && !isLoading && state != V3MiniButtonState.disabled;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    final metrics = _V3MiniButtonMetrics.forVariant(variant);
    final effectiveLeading =
        isLoading
            ? SizedBox.square(
              dimension: metrics.iconSize,
              child: CircularProgressIndicator(
                key: const ValueKey('v3-mini-button-progress'),
                strokeWidth: 2,
                color: colors.contentNeutral2,
              ),
            )
            : leadingIcon;

    Widget button = Semantics(
      button: true,
      enabled: _isEnabled,
      toggled: state == V3MiniButtonState.active ? true : null,
      label: semanticLabel ?? label,
      hint: semanticHint,
      child: ExcludeSemantics(
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
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }

  ButtonStyle _buttonStyle(
    V3ColorPalette colors,
    _V3MiniButtonMetrics metrics,
  ) {
    return ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(0, metrics.height)),
      maximumSize: WidgetStatePropertyAll(
        Size(double.infinity, metrics.height),
      ),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: const WidgetStatePropertyAll(StadiumBorder()),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.notoSans(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          decoration:
              variant == V3MiniButtonVariant.ghost
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
      overlayColor: WidgetStatePropertyAll(colors.black.withValues(alpha: 0)),
      side: WidgetStateProperty.resolveWith(
        (states) => _borderSide(colors, states),
      ),
      elevation: WidgetStatePropertyAll(
        variant == V3MiniButtonVariant.outline && _isEnabled ? 1 : 0,
      ),
      shadowColor: WidgetStatePropertyAll(colors.black.withValues(alpha: 0.05)),
    );
  }

  Color _foregroundColor(V3ColorPalette colors, Set<WidgetState> states) {
    if (_isDisabled(states)) {
      return variant == V3MiniButtonVariant.ghost
          ? colors.contentNeutral
          : colors.contentNeutral2;
    }
    if (variant == V3MiniButtonVariant.primary) {
      return colors.contentWhite;
    }
    if (variant == V3MiniButtonVariant.outline) {
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
    if (variant == V3MiniButtonVariant.ghost) {
      return colors.black.withValues(alpha: 0);
    }
    if (_isDisabled(states)) {
      return colors.backgroundNeutral;
    }
    if (_isError) {
      return variant == V3MiniButtonVariant.primary
          ? colors.stateError
          : colors.buttonSecondary;
    }
    if (variant == V3MiniButtonVariant.outline) {
      return _isActive(states)
          ? colors.black.withValues(alpha: 0.05)
          : colors.buttonSecondary;
    }
    return _isActive(states) ? colors.borderTertiary : colors.buttonPrimary;
  }

  BorderSide _borderSide(V3ColorPalette colors, Set<WidgetState> states) {
    if (variant != V3MiniButtonVariant.outline || _isDisabled(states)) {
      return BorderSide.none;
    }
    if (_isError) {
      return BorderSide(color: colors.borderExtensionError);
    }
    return BorderSide(
      color: _isActive(states) ? colors.contentNeutral : colors.borderSlate,
    );
  }

  bool get _isError => state == V3MiniButtonState.error;

  bool _isDisabled(Set<WidgetState> states) =>
      !_isEnabled || states.contains(WidgetState.disabled);

  bool _isActive(Set<WidgetState> states) =>
      state == V3MiniButtonState.active ||
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
  final _V3MiniButtonMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(size: metrics.iconSize),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
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

class _V3MiniButtonMetrics {
  const _V3MiniButtonMetrics({
    required this.height,
    required this.horizontalPadding,
  });

  factory _V3MiniButtonMetrics.forVariant(V3MiniButtonVariant variant) {
    return variant == V3MiniButtonVariant.ghost
        ? const _V3MiniButtonMetrics(height: 16, horizontalPadding: 0)
        : const _V3MiniButtonMetrics(height: 24, horizontalPadding: 8);
  }

  final double height;
  final double horizontalPadding;
  final double iconSize = 12;
}
