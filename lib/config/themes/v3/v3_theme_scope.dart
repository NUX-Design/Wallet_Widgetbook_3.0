import 'package:flutter/material.dart';

import 'v3_color_palette.dart';

abstract final class V3ThemeScope {
  static V3ColorPalette colorsOf(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? V3ColorPalette.dark
        : V3ColorPalette.light;
  }
}
