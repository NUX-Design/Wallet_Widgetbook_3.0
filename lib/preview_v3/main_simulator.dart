import 'package:flutter/widgets.dart' show runApp;

import 'preview_app.dart';

/// Native debug entrypoint for the Widget V3 preview host.
///
/// Select a preview with `--dart-define=V3_PREVIEW_SLUG=<category>/<Widget>`.
void main() {
  const rawSlug = String.fromEnvironment('V3_PREVIEW_SLUG');
  runApp(const V3PreviewApp(rawSlug: rawSlug));
}
