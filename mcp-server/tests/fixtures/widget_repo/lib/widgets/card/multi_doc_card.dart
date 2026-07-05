import 'package:flutter/material.dart';

class MultiDocCard extends StatelessWidget {
  final String title;

  const MultiDocCard({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Card(child: Text(title));
  }
}
