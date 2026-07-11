import 'package:flutter/material.dart';
import '../../../../config/themes/v3/v3_theme_scope.dart';

class V3TestButton extends StatelessWidget {
  const V3TestButton({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Text(label, style: TextStyle(color: colors.contentPrimary));
  }
}
