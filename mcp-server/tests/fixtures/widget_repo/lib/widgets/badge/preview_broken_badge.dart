import 'package:flutter/material.dart';
import 'package:mcp_test_app/widgets/badge/broken_badge.dart';

class BrokenBadgePreview extends StatelessWidget {
  const BrokenBadgePreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: BrokenBadge(text: 'Oops'));
  }
}

void main() {
  runApp(const MaterialApp(home: BrokenBadgePreview()));
}
