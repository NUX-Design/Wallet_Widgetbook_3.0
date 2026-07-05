import 'package:flutter/material.dart';
import 'package:mcp_test_app/widgets/button/primary_button.dart';

class PrimaryButtonPreview extends StatelessWidget {
  const PrimaryButtonPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: PrimaryButton(label: 'Pay now'));
  }
}

void main() {
  runApp(const MaterialApp(home: PrimaryButtonPreview()));
}
