import 'package:flutter/material.dart';

class IconChip extends StatelessWidget {
  final String label;

  const IconChip({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label));
  }
}
