import 'preview_definition.dart';
import 'preview_registry.g.dart';

/// Registry of every routable Widget V3 preview.
///
/// Entries come from the generated `preview_registry.g.dart`, produced by
/// `dart run tool/generate_v3_preview_registry.dart` from every
/// `lib/widgets/v3/**/preview_v3_*.dart` file. Do not hand-edit the
/// generated file; add/rename a preview file and regenerate instead.
class V3PreviewRegistry {
  const V3PreviewRegistry._();

  static final List<V3PreviewDefinition> _entries = ensureUniqueV3PreviewSlugs(
    generatedV3PreviewEntries,
  );

  /// All registered preview definitions, in slug order.
  static List<V3PreviewDefinition> all() => List.unmodifiable(_entries);

  /// Resolves [rawSlug] (normalized) to its registered definition, or
  /// `null` when no preview is registered under that slug.
  static V3PreviewDefinition? resolve(String rawSlug) {
    final normalized = normalizeV3PreviewSlug(rawSlug);
    if (normalized.isEmpty) return null;
    for (final entry in _entries) {
      if (entry.slug == normalized) return entry;
    }
    return null;
  }
}
