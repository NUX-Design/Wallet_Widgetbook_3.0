/// Theme V3 icon stroke roles for [V3LucideIcon].
///
/// Roles express design intent (approximate stroke width in logical
/// pixels); renderer-specific mapping (for example, which Lucide font
/// family or SVG asset satisfies a role) lives in the renderer, not here,
/// so this contract stays stable if the underlying renderer changes.
/// See LI-01/LI-02 evidence in `task/V3_LUCIDE_ICON_TASKS.md` for why the
/// package renderer only offers discrete weight buckets rather than an
/// exact continuous stroke width.
enum V3IconStroke {
  /// ~1px intent — thinnest available package weight bucket.
  thin,

  /// ~1.5px intent.
  light,

  /// ~2px intent — matches Lucide's documented upstream default stroke
  /// width exactly; documented V3 default.
  regular,

  /// ~2.5px intent — heaviest available package weight bucket.
  bold,
}
