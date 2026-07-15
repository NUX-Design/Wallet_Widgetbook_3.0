import '../../../config/themes/v3/v3_dimensions.dart';

/// Theme V3 icon size roles for [V3LucideIcon].
///
/// Values are sourced from the existing [V3Spacing] semantic dimension
/// tokens rather than raw literals, per LI-02 of
/// `task/V3_LUCIDE_ICON_TASKS.md`.
enum V3IconSize {
  /// 12px — Mini Button icon slots.
  tiny(V3Spacing.space12),

  /// 16px — compact controls.
  small(V3Spacing.space16),

  /// 24px — Navigation destination icons; documented V3 default.
  medium(V3Spacing.space24),

  /// 32px — Navigation Scan action icon.
  large(V3Spacing.space32);

  const V3IconSize(this.value);

  /// Resolved logical pixel size for this role.
  final double value;
}
