import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'v3_icon_size.dart';
import 'v3_icon_stroke.dart';

/// Theme V3 adapter around `lucide_icons_flutter` (package renderer) and an
/// optional checked-in Lucide SVG (override renderer).
///
/// This is the only file in the reusable Widget V3 catalog allowed to
/// import `lucide_icons_flutter` or `flutter_svg` for icon rendering;
/// other Widget V3 components must keep icon slots typed as `Widget` and
/// consume icons through this adapter (`V3_LUCIDE_ICON_GUIDE.md`).
///
/// Resolution priority: explicit constructor property → inherited
/// [IconTheme] → documented V3 default (`V3IconSize.medium`,
/// `V3IconStroke.regular`). Color is never an explicit parameter; it
/// always flows from the ambient [IconTheme] so callers cannot hardcode
/// raw design colors.
///
/// Render priority: [svgAsset] present → `flutter_svg`; [svgAsset] absent
/// → the `lucide_icons_flutter` package renderer with [stroke] resolved
/// to a weight-specific font family (see LI-02 evidence in
/// `task/V3_LUCIDE_ICON_TASKS.md` for why the package needs a font-family
/// swap rather than a live variable-weight parameter).
///
/// The package renderer paints the glyph directly with [RichText] instead
/// of going through [Icon]/[IconData] construction: Flutter's release-web
/// icon tree-shaker hard-fails the build on any non-constant `IconData(...)`
/// call (confirmed by a real `flutter build web --release` run while
/// implementing LI-03/LI-05 — see evidence in
/// `task/V3_LUCIDE_ICON_TASKS.md`), and picking a weight-specific font
/// family for an arbitrary caller-supplied base icon requires exactly that
/// kind of runtime construction. Painting via [RichText] with
/// `TextStyle(fontFamily: ..., package: ...)` mirrors [Icon]'s own
/// implementation (including its [Semantics]/[ExcludeSemantics] wrapping)
/// without ever invoking the `IconData` constructor, so the tree-shaker
/// never sees a call site to reject. This changes nothing observable to
/// callers; release builds can still tree-shake the package fonts, although
/// the measured reduction is more modest than Material/Cupertino fonts.
class V3LucideIcon extends StatelessWidget {
  const V3LucideIcon(
    this.icon, {
    super.key,
    this.size,
    this.stroke,
    this.svgAsset,
    this.semanticLabel,
  });

  /// Base (unsuffixed, regular-weight) Lucide icon constant, for example
  /// `LucideIcons.house`. [V3LucideIcon] resolves the correct weight-family
  /// variant internally from [stroke]; callers never reference a
  /// weight-suffixed constant (`house100`, `house600`, ...) directly.
  final IconData icon;

  /// Explicit size role. Falls back to the ambient [IconTheme] size, then
  /// to [V3IconSize.medium] when neither is set.
  final V3IconSize? size;

  /// Explicit stroke role. Has no ambient [IconTheme] equivalent to
  /// inherit from, so it falls back directly to [V3IconStroke.regular].
  final V3IconStroke? stroke;

  /// Optional checked-in Lucide SVG asset path
  /// (`lib/assets/icons/v3/lucide/...`) used only for verified Figma
  /// mismatches. When set, this takes over rendering entirely and [icon]
  /// is ignored.
  final String? svgAsset;

  /// Localized accessibility label for a standalone icon-only action.
  /// Leave `null` for decorative icons already described by a parent
  /// `Semantics` node (for example inside a labeled button), matching the
  /// Accessibility Contract's decorative-by-default rule.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final resolvedSize =
        size?.value ?? iconTheme.size ?? V3IconSize.medium.value;
    final resolvedColor = iconTheme.color;

    final asset = svgAsset;
    if (asset != null) {
      return SvgPicture.asset(
        asset,
        width: resolvedSize,
        height: resolvedSize,
        semanticsLabel: semanticLabel,
        colorFilter:
            resolvedColor == null
                ? null
                : ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      );
    }

    final textDirection = Directionality.of(context);
    Widget glyph = RichText(
      overflow: TextOverflow.visible,
      textDirection: textDirection,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          inherit: false,
          color: resolvedColor,
          fontSize: resolvedSize,
          fontFamily: _weightFamily(stroke ?? V3IconStroke.regular),
          package: icon.fontPackage,
          height: 1.0,
          leadingDistribution: TextLeadingDistribution.even,
        ),
      ),
    );
    if (icon.matchTextDirection && textDirection == TextDirection.rtl) {
      glyph = Transform(
        transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
        alignment: Alignment.center,
        transformHitTests: false,
        child: glyph,
      );
    }

    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: resolvedSize,
          height: resolvedSize,
          child: Center(child: glyph),
        ),
      ),
    );
  }

  static String _weightFamily(V3IconStroke stroke) {
    switch (stroke) {
      case V3IconStroke.thin:
        return 'Lucide100';
      case V3IconStroke.light:
        return 'Lucide300';
      case V3IconStroke.regular:
        return 'Lucide';
      case V3IconStroke.bold:
        return 'Lucide600';
    }
  }
}
