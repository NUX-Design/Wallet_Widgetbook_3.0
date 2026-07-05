import 'package:flutter/material.dart';

class GhostBanner extends StatelessWidget {
  final String title;

  const GhostBanner({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(title);
  }
}
