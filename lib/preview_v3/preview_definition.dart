import 'package:flutter/widgets.dart';

/// A single routable entry in the local Widget V3 preview host.
///
/// [builder] is intentionally a [WidgetBuilder] (not a pre-built [Widget])
/// so registering a definition never constructs its preview widget tree;
/// construction only happens when the host resolves and renders that slug.
class V3PreviewDefinition {
  const V3PreviewDefinition({
    required this.category,
    required this.widgetName,
    required this.builder,
  }) : assert(category != '', 'category must not be empty'),
       assert(widgetName != '', 'widgetName must not be empty');

  final String category;
  final String widgetName;
  final WidgetBuilder builder;

  /// Canonical `<category>/<WidgetClass>` slug, e.g. `button/V3MiniButton`.
  String get slug => '$category/$widgetName';
}

/// Strips leading/trailing whitespace and slashes so route fragments like
/// `/button/V3MiniButton/` and stored slugs like `button/V3MiniButton`
/// compare equal.
String normalizeV3PreviewSlug(String raw) {
  return raw.trim().replaceAll(RegExp(r'^/+|/+$'), '');
}

/// Validates that every definition has a unique canonical slug.
///
/// Throws a [StateError] naming the offending slug on the first duplicate
/// found; returns the input list unchanged otherwise.
List<V3PreviewDefinition> ensureUniqueV3PreviewSlugs(
  List<V3PreviewDefinition> entries,
) {
  final seenSlugs = <String>{};
  for (final entry in entries) {
    if (!seenSlugs.add(entry.slug)) {
      throw StateError('Duplicate V3 preview slug: "${entry.slug}"');
    }
  }
  return entries;
}
