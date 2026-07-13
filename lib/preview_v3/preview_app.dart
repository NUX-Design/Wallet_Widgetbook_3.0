import 'package:flutter/material.dart';

import 'preview_definition.dart';
import 'preview_not_found.dart';
import 'preview_registry.dart';

/// Root widget for the local Widget V3 preview host.
///
/// Reads the requested slug once from [Uri.base.fragment] at startup;
/// a full page reload re-reads the fragment, so refreshing preserves route.
class V3PreviewApp extends StatelessWidget {
  const V3PreviewApp({super.key, required this.rawSlug});

  final String rawSlug;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Widget V3 Local Preview',
      home: V3PreviewRoute(rawSlug: rawSlug),
    );
  }
}

/// Resolves [rawSlug] against [V3PreviewRegistry] and renders the matching
/// preview lazily. An empty fragment (root `/`) redirects to the first
/// registered preview; an unresolvable slug renders [V3PreviewNotFound]
/// instead of crashing.
class V3PreviewRoute extends StatelessWidget {
  const V3PreviewRoute({super.key, required this.rawSlug});

  final String rawSlug;

  @override
  Widget build(BuildContext context) {
    final normalized = normalizeV3PreviewSlug(rawSlug);

    if (normalized.isEmpty) {
      final registered = V3PreviewRegistry.all();
      if (registered.isEmpty) {
        return const V3PreviewNotFound(requestedSlug: '');
      }
      return Builder(builder: registered.first.builder);
    }

    final definition = V3PreviewRegistry.resolve(normalized);
    if (definition == null) {
      return V3PreviewNotFound(requestedSlug: normalized);
    }
    return Builder(builder: definition.builder);
  }
}
