import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_color_palette.dart';
import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_primitives.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';

/// Caller-owned content for one selectable [V3Navigation] destination.
class V3NavigationDestination {
  const V3NavigationDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.semanticLabel,
  });

  final String label;
  final Widget icon;
  final Widget? selectedIcon;
  final String? semanticLabel;
}

/// Theme V3 bottom navigation mapped to Figma component `110:5385`.
class V3Navigation extends StatelessWidget {
  const V3Navigation({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.scanIcon,
    required this.scanSemanticLabel,
    required this.onScanPressed,
  }) : assert(destinations.length == 4),
       assert(selectedIndex >= 0 && selectedIndex < 4);

  /// Four destinations displayed around the non-selectable Scan action.
  final List<V3NavigationDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final Widget scanIcon;
  final String scanSemanticLabel;
  final VoidCallback? onScanPressed;

  static const double _standardIconSize = V3Spacing.space24;
  static const double _scanIconSize = V3Spacing.space32;
  static const double _scanButtonSize = V3Spacing.space56;
  static const double _barHeight = V3Spacing.space96;
  static const double _destinationExtent = 48;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return SizedBox(
      height: _barHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: _NavigationSurface(colors: colors)),
          Positioned(
            top: V3Spacing.space12,
            left: V3Spacing.space24,
            right: V3Spacing.space24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _destination(context, 0, colors),
                _destination(context, 1, colors),
                const SizedBox(width: _scanButtonSize),
                _destination(context, 2, colors),
                _destination(context, 3, colors),
              ],
            ),
          ),
          Positioned(
            top: -V3Spacing.space12,
            left: 0,
            right: 0,
            child: Center(child: _scanButton(colors)),
          ),
        ],
      ),
    );
  }

  Widget _destination(BuildContext context, int index, V3ColorPalette colors) {
    final destination = destinations[index];
    final isSelected = index == selectedIndex;
    final isEnabled = onDestinationSelected != null;
    final foreground =
        isSelected ? colors.contentPrimary : colors.contentNeutral;
    final textStyle = V3Typography.labelTiny.copyWith(
      color: foreground,
      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
    );

    return Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      label: destination.semanticLabel ?? destination.label,
      child: ExcludeSemantics(
        child: TextButton(
          key: ValueKey('v3-navigation-destination-$index'),
          onPressed: isEnabled ? () => onDestinationSelected!(index) : null,
          style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(
              Size(_destinationExtent, _destinationExtent),
            ),
            maximumSize: const WidgetStatePropertyAll(
              Size(_destinationExtent, _destinationExtent),
            ),
            padding: const WidgetStatePropertyAll(EdgeInsets.zero),
            foregroundColor: WidgetStatePropertyAll(foreground),
            overlayColor: WidgetStatePropertyAll(
              colors.contentPrimary.withValues(alpha: 0.05),
            ),
            shape: const WidgetStatePropertyAll(CircleBorder()),
          ),
          child: IconTheme(
            key: ValueKey('v3-navigation-icon-theme-$index'),
            data: IconThemeData(color: foreground, size: _standardIconSize),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: V3Spacing.space4,
              children: [
                SizedBox.square(
                  dimension: _standardIconSize,
                  child: Center(
                    child:
                        isSelected
                            ? destination.selectedIcon ?? destination.icon
                            : destination.icon,
                  ),
                ),
                Text(
                  destination.label,
                  key: ValueKey('v3-navigation-label-$index'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scanButton(V3ColorPalette colors) {
    final isEnabled = onScanPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: scanSemanticLabel,
      child: ExcludeSemantics(
        child: DecoratedBox(
          key: const ValueKey('v3-navigation-scan-decoration'),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [V3PrimitiveColors.gold400, V3PrimitiveColors.gold800],
              stops: [0.061733, 0.93827],
            ),
            boxShadow: [
              BoxShadow(
                color: V3PrimitiveColors.goldAlpha30,
                offset: Offset(0, V3Spacing.space4),
                blurRadius: V3Spacing.space8,
              ),
            ],
          ),
          child: IconButton(
            key: const ValueKey('v3-navigation-scan-action'),
            onPressed: onScanPressed,
            padding: const EdgeInsets.all(V3Spacing.space12),
            constraints: const BoxConstraints.tightFor(
              width: _scanButtonSize,
              height: _scanButtonSize,
            ),
            style: ButtonStyle(
              foregroundColor: WidgetStatePropertyAll(colors.contentWhite),
              overlayColor: WidgetStatePropertyAll(
                colors.contentWhite.withValues(alpha: 0.15),
              ),
            ),
            icon: IconTheme(
              data: IconThemeData(
                color: colors.contentWhite,
                size: _scanIconSize,
              ),
              child: SizedBox.square(
                dimension: _scanIconSize,
                child: Center(child: scanIcon),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavigationSurface extends StatelessWidget {
  const _NavigationSurface({required this.colors});

  static const double _topBorderWidth = 1;

  final V3ColorPalette colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('v3-navigation-surface'),
      decoration: BoxDecoration(
        color: colors.backgroundWhite,
        // Exact component effect from Figma node 110:5385; no V3 shadow
        // primitive has the required upward offset and 18.9px blur.
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A311700),
            offset: Offset(-1, -4),
            blurRadius: 18.9,
          ),
        ],
      ),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: const SizedBox.expand(),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ColoredBox(
                key: const ValueKey('v3-navigation-top-border'),
                color: colors.borderPrimary,
                child: const SizedBox(
                  width: double.infinity,
                  height: _topBorderWidth,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
