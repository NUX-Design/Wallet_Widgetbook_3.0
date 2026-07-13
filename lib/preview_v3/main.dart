import 'package:flutter/widgets.dart' show runApp;
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'preview_app.dart';

void main() {
  // The preview host owns the URL fragment manually (see V3PreviewRoute in
  // preview_app.dart). Without this, MaterialApp's implicit Navigator/Router
  // reports its own route ("/") back to the browser on first frame and
  // silently strips whatever slug was in the fragment, breaking
  // refresh/deep-link routing.
  setUrlStrategy(null);
  runApp(V3PreviewApp(rawSlug: Uri.base.fragment));
}
