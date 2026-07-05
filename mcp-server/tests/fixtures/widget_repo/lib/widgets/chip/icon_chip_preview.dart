import 'package:flutter/material.dart';
import 'package:mcp_test_app/widgets/chip/icon_chip.dart';

class IconChipPreview extends StatelessWidget {
  const IconChipPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: IconChip(label: 'Gift card'));
  }
}

void main() {
  runApp(const MaterialApp(home: IconChipPreview()));
}
