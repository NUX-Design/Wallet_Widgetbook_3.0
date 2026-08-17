import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_primitives.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';

/// Theme V3 balance card mapped to Figma component set `Balance card` (`613:700`).
///
/// Displays an account balance with a gradient background, brand watermark,
/// and a visibility toggle. Supports Light/Dark themes and masked/revealed states.
///
/// Variants:
///   - Theme: Light, Dark
///   - Show balance: True (revealed), False (masked as "**.**")
///   - Error: No (reserved for future error states)
///
/// [visibilityIcon] and [infoIcon] are caller-owned `Widget` slots (see
/// `V3_BALANCE_CARD_GUIDE.md`) — this component never imports an icon
/// library directly. The Figma-referenced glyphs (`eye`/`eye-off`,
/// `circle-alert`) are Lucide icons; pass `V3LucideIcon(...)` from the
/// caller to reproduce them exactly.
class V3BalanceCard extends StatelessWidget {
  const V3BalanceCard({
    super.key,
    required this.label,
    required this.amount,
    required this.currency,
    required this.isBalanceVisible,
    required this.onToggleVisibility,
    required this.visibilityIcon,
    this.onInfoTap,
    this.infoIcon,
    this.hasError = false,
  });

  /// Localized label text, e.g. "Available balance".
  final String label;

  /// Formatted balance amount, e.g. "10,000,000.00".
  /// When [isBalanceVisible] is false, the widget masks this as "**.**".
  final String amount;

  /// Currency code, e.g. "THB".
  final String currency;

  /// Whether the balance amount is revealed or masked.
  final bool isBalanceVisible;

  /// Called when the user taps the visibility toggle icon.
  final VoidCallback onToggleVisibility;

  /// Caller-owned visibility toggle glyph. Figma swaps this between the
  /// `eye` and `eye-off` Lucide icons as [isBalanceVisible] changes; the
  /// caller (which already owns that boolean) is responsible for passing
  /// the matching icon.
  final Widget visibilityIcon;

  /// Optional callback for the info icon next to the label.
  final VoidCallback? onInfoTap;

  /// Caller-owned info glyph, shown only when both this and [onInfoTap]
  /// are non-null. Figma references the `circle-alert` Lucide icon here.
  final Widget? infoIcon;

  /// Reserved for future error state display.
  final bool hasError;

  // ── Layout constants (Figma node 613:700, default variant) ──
  static const double _cardHeight = 147.0;
  static const double _borderRadius = V3Radii.rounded3xl;
  static const double _contentPadding = V3Spacing.space24;
  static const double _labelIconGap = V3Spacing.space4;
  static const double _valuesGap = V3Spacing.space4;
  static const double _labelToValuesGap = V3Spacing.space8;
  static const double _iconSize = 16.0;
  static const double _visibilityIconSize = 24.0;
  static const double _dividerHeight = 1.0;
  static const double _borderWidth = 1.0;

  /// Checked-in export of Figma `water_mark_logo` (`613:385`); the source
  /// vector already bakes in the Figma-measured 10% opacity.
  static const _watermarkAsset =
      'lib/assets/images/v3_balance_card_watermark.svg';

  // ── Gradient colors (measured via Figma `get_design_context` on 613:383) ──
  static const _lightGradientStart = Color(0xFFEFF6FF);
  static const _lightGradientEnd = Color(0xFF2563EB);
  static const _darkGradientStart = Color(0xFF3B82F6);
  static const _darkGradientEnd = Color(0xFF172554);
  static const _goldDividerColor = Color(0xFFDFAD51);

  /// Card surface gradient direction, converted from the measured CSS
  /// `linear-gradient(111.15138154978987deg, ...)` angle (0deg = to top,
  /// clockwise) into a Flutter `Alignment` begin/end pair.
  static const _gradientBegin = Alignment(-1.0, -0.3869);
  static const _gradientEnd = Alignment(1.0, 0.3869);

  /// Radial glow (`613:384`) 5-stop gradient, measured via `get_design_context`.
  /// The whole layer also carries a Figma `opacity-20` (20%) that is not
  /// baked into these stop colors — see the `Opacity` wrapper below.
  static const _radialGlowStops = <double>[0.0, 0.175, 0.35, 0.525, 0.7];
  static const _radialGlowColors = <Color>[
    Color(0xFF4C6EF5),
    Color(0xBF3953B8),
    Color(0x8026377B),
    Color(0x40131C3D),
    Color(0x00000000),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final labelColor = colors.contentSecondary;
    final amountColor = colors.contentPrimary;
    final borderColor = colors.borderPrimary;
    final gradientStart = isDark ? _darkGradientStart : _lightGradientStart;
    final gradientEnd = isDark ? _darkGradientEnd : _lightGradientEnd;

    return Semantics(
      label: '$label: ${isBalanceVisible ? "$amount $currency" : "Hidden"}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Gold divider bar ──
          _buildGoldDivider(),

          // ── Main card body ──
          _buildCardBody(
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
            borderColor: borderColor,
            labelColor: labelColor,
            amountColor: amountColor,
          ),
        ],
      ),
    );
  }

  /// 1px gold gradient divider at the top.
  Widget _buildGoldDivider() {
    return Container(
      height: _dividerHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _goldDividerColor, Colors.transparent],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
    );
  }

  /// The main gradient card with radial glow, watermark, and content.
  Widget _buildCardBody({
    required Color gradientStart,
    required Color gradientEnd,
    required Color borderColor,
    required Color labelColor,
    required Color amountColor,
  }) {
    return Container(
      key: const ValueKey('v3-balance-card-surface'),
      constraints: const BoxConstraints(minHeight: _cardHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        // Figma strokeWeight is 0 on the top edge (the gold divider sits
        // there instead) and 1 on left/right/bottom.
        border: Border(
          left: BorderSide(color: borderColor, width: _borderWidth),
          right: BorderSide(color: borderColor, width: _borderWidth),
          bottom: BorderSide(color: borderColor, width: _borderWidth),
        ),
        gradient: LinearGradient(
          begin: _gradientBegin,
          end: _gradientEnd,
          colors: [gradientStart, gradientEnd],
        ),
        boxShadow: V3PrimitiveShadows.md,
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Radial glow (top-right; measured left:179/top:-140 on the
          // reference 343px-wide card, converted to right:-166 so it stays
          // anchored to the top-right corner as the card stretches wider) ──
          Positioned(
            right: -166,
            top: -140,
            child: Opacity(
              opacity: 0.2,
              child: Container(
                width: 330,
                height: 330,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _radialGlowColors,
                    stops: _radialGlowStops,
                  ),
                ),
              ),
            ),
          ),

          // ── Brand watermark logo (top-right) ──
          Positioned(
            right: -22,
            top: -12,
            child: ExcludeSemantics(
              child: SvgPicture.asset(_watermarkAsset, width: 174, height: 158),
            ),
          ),

          // ── Card content ──
          Padding(
            padding: const EdgeInsets.all(_contentPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Balance info (left)
                Expanded(
                  child: _buildBalanceInfo(
                    labelColor: labelColor,
                    amountColor: amountColor,
                  ),
                ),

                // Visibility toggle (right)
                const SizedBox(width: V3Spacing.space8),
                _buildVisibilityToggle(amountColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Label + amount + currency column.
  Widget _buildBalanceInfo({
    required Color labelColor,
    required Color amountColor,
  }) {
    final displayAmount = isBalanceVisible ? amount : '**.**';
    final infoGlyph = infoIcon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Label row with info icon ──
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(
              child: Text(
                label,
                key: const ValueKey('v3-balance-card-label'),
                style: V3Typography.paragraphTiny.copyWith(color: labelColor),
              ),
            ),
            if (onInfoTap != null && infoGlyph != null) ...[
              const SizedBox(width: _labelIconGap),
              GestureDetector(
                onTap: onInfoTap,
                child: Semantics(
                  button: true,
                  label: 'Balance info',
                  child: ExcludeSemantics(
                    child: IconTheme.merge(
                      data: IconThemeData(size: _iconSize, color: labelColor),
                      child: infoGlyph,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: _labelToValuesGap),

        // ── Balance amount ──
        ExcludeSemantics(
          child: Text(
            displayAmount,
            key: const ValueKey('v3-balance-card-amount'),
            style: V3Typography.headingLarge.copyWith(color: amountColor),
          ),
        ),

        const SizedBox(height: _valuesGap),

        // ── Currency ──
        ExcludeSemantics(
          child: Text(
            currency,
            key: const ValueKey('v3-balance-card-currency'),
            style: V3Typography.paragraphMedium.copyWith(color: labelColor),
          ),
        ),
      ],
    );
  }

  /// Visibility toggle button; glyph is caller-owned via [visibilityIcon].
  Widget _buildVisibilityToggle(Color iconColor) {
    return Semantics(
      button: true,
      label: isBalanceVisible ? 'Hide balance' : 'Show balance',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onToggleVisibility,
          child: SizedBox.square(
            dimension: _visibilityIconSize,
            child: IconTheme.merge(
              data: IconThemeData(size: _visibilityIconSize, color: iconColor),
              child: visibilityIcon,
            ),
          ),
        ),
      ),
    );
  }
}
