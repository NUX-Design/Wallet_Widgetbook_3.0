import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

const _kReceiptSurface = Color(0xFFFFFFFF);
const _kReceiptPrimaryText = Color(0xFF242424);
const _kReceiptSecondaryText = Color(0x730F0F0F);
const _kReceiptMerchantText = Color(0xFF16303E);
const _kReceiptDivider = Color(0x14000000);
const _kReceiptMutedOverlay = 0.85;
const _kReceiptLogoGold = Color(0xFFDDAD51);
const _kReceiptLogoBorder = Color(0xFFE4E4E4);
const _kReceiptWatermarkColor = Color(0x0F000000);
const _kReceiptMerchantIconColor = Color(0xFF2B5D77);
const _kReceiptContentPadding = 16.0;
const _kReceiptSectionGap = 16.0;
const _kReceiptLabelGap = 8.0;
const _kReceiptInnerGap = 12.0;
const _kReceiptMaxDetailRows = 5;

class ReceiptImageComponent extends StatelessWidget {
  final String amount;
  final String fee;
  final String senderName;
  final String senderAccount;
  final String merchantName;
  final String dateTime;
  final String transactionId;
  final String merchantRefId;
  final String billerId;
  final String ref1;
  final String footerNoteOne;
  final String footerNoteTwo;
  final int transactionDetailRowCount;
  final String? senderLogoAssetPath;
  final String? qrAssetPath;
  final String? backgroundSvgAssetPath;
  final String? backgroundImageUrl;
  final String? headerLogoAssetPath;

  const ReceiptImageComponent({
    super.key,
    required this.amount,
    required this.fee,
    required this.senderName,
    required this.senderAccount,
    required this.merchantName,
    required this.dateTime,
    required this.transactionId,
    required this.merchantRefId,
    required this.billerId,
    required this.ref1,
    required this.footerNoteOne,
    required this.footerNoteTwo,
    this.transactionDetailRowCount = _kReceiptMaxDetailRows,
    this.senderLogoAssetPath = 'lib/assets/images/brands=SCB.svg',
    this.qrAssetPath = 'lib/assets/images/receipt/qr.png',
    this.backgroundSvgAssetPath =
        'lib/assets/images/receipt/receipt_background.svg',
    this.backgroundImageUrl,
    this.headerLogoAssetPath = 'lib/assets/images/receipt/wiwallet-logo.svg',
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          decoration: BoxDecoration(color: _kReceiptSurface),
          child: Stack(
            children: [
              Positioned.fill(
                child: _ReceiptBackground(
                  backgroundSvgAssetPath: backgroundSvgAssetPath,
                  backgroundImageUrl: backgroundImageUrl,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(_kReceiptContentPadding),
                child: Opacity(
                  opacity: _kReceiptMutedOverlay,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildDivider(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildFromInfo(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildToInfo(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildDivider(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildAmountAndQrSection(constraints.maxWidth),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildDivider(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildTransactionDetails(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildDivider(),
                      const SizedBox(height: _kReceiptSectionGap),
                      _buildFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            'Payment',
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: GoogleFonts.notoSansThai(
              fontSize: 15,
              height: 20 / 15,
              fontWeight: FontWeight.w700,
              color: _kReceiptPrimaryText,
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildHeaderLogo(),
      ],
    );
  }

  Widget _buildHeaderLogo() {
    final assetPath = headerLogoAssetPath;
    if (assetPath != null) {
      return SizedBox(
        width: 86,
        height: 20,
        child: SvgPicture.asset(assetPath, fit: BoxFit.contain),
      );
    }

    return Container(
      height: 20,
      alignment: Alignment.centerRight,
      child: Text(
        'wi wallet',
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: GoogleFonts.notoSansThai(
          fontSize: 14,
          height: 1,
          fontWeight: FontWeight.w600,
          color: _kReceiptMerchantIconColor,
        ),
      ),
    );
  }

  Widget _buildFromInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(
            'From',
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _kReceiptSecondaryText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              _buildSenderLogo(),
              const SizedBox(width: _kReceiptInnerGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      senderName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 12,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: _kReceiptPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      senderAccount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.notoSansThai(
                        fontSize: 10,
                        height: 1.2,
                        fontWeight: FontWeight.w400,
                        color: _kReceiptSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToInfo() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Text(
            'To',
            style: GoogleFonts.notoSansThai(
              fontSize: 10,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: _kReceiptSecondaryText,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              _buildMerchantLogo(),
              const SizedBox(width: _kReceiptInnerGap),
              Expanded(
                child: Text(
                  merchantName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.notoSansThai(
                    fontSize: 10,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _kReceiptMerchantText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmountAndQrSection(double availableWidth) {
    final useColumnLayout = availableWidth < 340;

    final amountBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansThai(
            fontSize: 22,
            height: 1.27,
            fontWeight: FontWeight.w700,
            color: _kReceiptPrimaryText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fee,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.notoSansThai(
            fontSize: 11,
            height: 1.27,
            fontWeight: FontWeight.w400,
            color: _kReceiptSecondaryText,
          ),
        ),
      ],
    );

    final qrBlock = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [_buildQrCode()],
    );

    if (useColumnLayout) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          amountBlock,
          const SizedBox(height: 16),
          Align(alignment: Alignment.centerRight, child: qrBlock),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: amountBlock),
        const SizedBox(width: 16),
        qrBlock,
      ],
    );
  }

  Widget _buildQrCode() {
    final assetPath = qrAssetPath;
    if (assetPath != null) {
      return SizedBox(
        width: 78,
        height: 78,
        child: Image.asset(assetPath, fit: BoxFit.cover),
      );
    }

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kReceiptLogoBorder),
      ),
      child: const _PseudoQrCode(),
    );
  }

  Widget _buildTransactionDetails() {
    final rows = <Widget>[
      _buildDetailRow('Date&Time:', dateTime),
      _buildDetailRow('Transaction ID:', transactionId),
      _buildDetailRow('Merchant Ref ID:', merchantRefId),
      _buildDetailRow('Biller ID:', billerId),
      _buildDetailRow('Ref 1:', ref1),
    ];

    final visibleRowCount = transactionDetailRowCount.clamp(0, rows.length);
    final visibleRows = rows.take(visibleRowCount).toList();

    if (visibleRows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < visibleRows.length; i++) ...[
          visibleRows[i],
          if (i != visibleRows.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    const labelWidth = 108.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              height: 1.27,
              fontWeight: FontWeight.w400,
              color: _kReceiptSecondaryText,
            ),
          ),
        ),
        const SizedBox(width: _kReceiptLabelGap),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              height: 1.27,
              fontWeight: FontWeight.w400,
              color: _kReceiptSecondaryText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    const color = _kReceiptSecondaryText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletLine(footerNoteOne, color),
        const SizedBox(height: 4),
        _buildBulletLine(footerNoteTwo, color),
      ],
    );
  }

  Widget _buildBulletLine(String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: GoogleFonts.notoSansThai(
            fontSize: 11,
            height: 1.27,
            fontWeight: FontWeight.w400,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.notoSansThai(
              fontSize: 11,
              height: 1.27,
              fontWeight: FontWeight.w400,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(color: _kReceiptDivider),
    );
  }

  Widget _buildSenderLogo() {
    final assetPath = senderLogoAssetPath;
    if (assetPath != null) {
      return ClipOval(
        child: SizedBox(
          width: 48,
          height: 48,
          child: SvgPicture.asset(assetPath, fit: BoxFit.cover),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: _kReceiptLogoGold,
      ),
      alignment: Alignment.center,
      child: Text(
        'W',
        style: GoogleFonts.notoSansThai(
          fontSize: 22,
          height: 1,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMerchantLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: _kReceiptLogoBorder),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.storefront_outlined,
        size: 24,
        color: _kReceiptMerchantIconColor,
      ),
    );
  }
}

class _ReceiptWatermarkBackground extends StatelessWidget {
  const _ReceiptWatermarkBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ReceiptWatermarkPainter(color: _kReceiptWatermarkColor),
      child: const SizedBox.expand(),
    );
  }
}

class _ReceiptBackground extends StatelessWidget {
  final String? backgroundSvgAssetPath;
  final String? backgroundImageUrl;

  const _ReceiptBackground({
    required this.backgroundSvgAssetPath,
    required this.backgroundImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final background = _buildBackground();
    return ClipRect(child: SizedBox.expand(child: background));
  }

  Widget _buildBackground() {
    if (backgroundImageUrl != null && backgroundImageUrl!.isNotEmpty) {
      return Image.network(
        backgroundImageUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }

    if (backgroundSvgAssetPath != null && backgroundSvgAssetPath!.isNotEmpty) {
      return SvgPicture.asset(
        backgroundSvgAssetPath!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
      );
    }

    return const _ReceiptWatermarkBackground();
  }
}

class _ReceiptWatermarkPainter extends CustomPainter {
  final Color color;

  const _ReceiptWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.max(size.width, size.height) * 0.9;

    for (var i = 1; i <= 10; i++) {
      canvas.drawCircle(center, (maxRadius / 10) * i, paint);
    }

    final verticalSpacing = size.height / 7;
    final horizontalSpacing = size.width / 7;
    for (var i = 1; i < 7; i++) {
      canvas.drawLine(
        Offset(0, verticalSpacing * i),
        Offset(size.width, verticalSpacing * i),
        paint,
      );
      canvas.drawLine(
        Offset(horizontalSpacing * i, 0),
        Offset(horizontalSpacing * i, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ReceiptWatermarkPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _PseudoQrCode extends StatelessWidget {
  const _PseudoQrCode();

  @override
  Widget build(BuildContext context) {
    const pattern = <List<bool>>[
      [true, true, true, false, true, true, false],
      [true, false, true, false, false, true, true],
      [true, true, true, true, true, false, true],
      [false, false, true, false, true, false, false],
      [true, true, false, true, false, true, true],
      [true, false, false, true, true, false, true],
      [false, true, true, false, true, true, true],
    ];

    return Padding(
      padding: const EdgeInsets.all(6),
      child: CustomPaint(
        painter: _PseudoQrPainter(pattern),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PseudoQrPainter extends CustomPainter {
  final List<List<bool>> pattern;

  const _PseudoQrPainter(this.pattern);

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / pattern.first.length;
    final cellHeight = size.height / pattern.length;
    final paint = Paint()..color = const Color(0xFF242424);

    for (var row = 0; row < pattern.length; row++) {
      for (var col = 0; col < pattern[row].length; col++) {
        if (!pattern[row][col]) {
          continue;
        }
        final rect = Rect.fromLTWH(
          col * cellWidth,
          row * cellHeight,
          cellWidth,
          cellHeight,
        );
        canvas.drawRect(rect.deflate(1), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PseudoQrPainter oldDelegate) {
    return false;
  }
}
