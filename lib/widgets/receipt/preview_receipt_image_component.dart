import 'package:flutter/material.dart';
import 'package:mcp_test_app/widgets/receipt/receipt_image_component.dart';

const _kPreviewBackground = Color(0xFFF3F3F3);
const _kPreviewAppBarBg = Color(0xFFF7F7F7);
const _kPreviewAppBarFg = Color(0xFF1F1F1F);

void main() {
  runApp(const ReceiptImageComponentPreviewApp());
}

class ReceiptImageComponentPreviewApp extends StatelessWidget {
  const ReceiptImageComponentPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReceiptImageComponentPreviewPage(),
    );
  }
}

class ReceiptImageComponentPreviewPage extends StatelessWidget {
  const ReceiptImageComponentPreviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kPreviewBackground,
      appBar: AppBar(
        title: const Text('Receipt Image Preview'),
        backgroundColor: _kPreviewAppBarBg,
        foregroundColor: _kPreviewAppBarFg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: const ReceiptImageComponent(
            amount: '500,000,000.00 THB',
            fee: 'Fees 5.00 THB',
            senderName: 'Victor Von Doom',
            senderAccount: 'x-1234',
            merchantName: 'Merchant 1',
            dateTime: '2025-10-06 12:00:53',
            transactionId: 'WP12345678901234567890',
            merchantRefId: 'WP12345678901234567890',
            billerId: 'WP12345678901234567890',
            ref1: 'WP12345678901234567890',
            footerNoteOne:
                'Please verify the information and keep the slip for evidence.',
            footerNoteTwo:
                'Customer service contact 02-026-6679 operates 24 hours daily.',
            transactionDetailRowCount: 5,
            backgroundSvgAssetPath:
                'lib/assets/images/receipt/receipt_background.svg',
            headerLogoAssetPath: 'lib/assets/images/receipt/wiwallet-logo.svg',
          ),
        ),
      ),
    );
  }
}
