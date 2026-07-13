import 'package:flutter/material.dart';

import 'preview_registry.dart';

/// Actionable Not Found screen shown when the requested slug has no
/// matching entry in [V3PreviewRegistry]. Never throws; lists every
/// registered slug so the caller can pick a valid one.
class V3PreviewNotFound extends StatelessWidget {
  const V3PreviewNotFound({super.key, required this.requestedSlug});

  final String requestedSlug;

  @override
  Widget build(BuildContext context) {
    final availableSlugs =
        V3PreviewRegistry.all().map((entry) => entry.slug).toList()..sort();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preview not found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    requestedSlug.isEmpty
                        ? 'No preview slug was provided in the URL fragment.'
                        : 'No preview is registered for "$requestedSlug".',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Available previews:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  if (availableSlugs.isEmpty)
                    const Text('(none registered)')
                  else
                    for (final slug in availableSlugs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: SelectableText('#/$slug'),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
