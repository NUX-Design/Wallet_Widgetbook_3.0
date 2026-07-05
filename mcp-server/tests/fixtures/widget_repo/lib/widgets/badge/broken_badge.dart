import 'package:flutter/material.dart';

class BrokenBadge extends StatelessWidget {
  final String text;
  final Color? color;

  const BrokenBadge({
    super.key,
    required this.text,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text);
  }
}
