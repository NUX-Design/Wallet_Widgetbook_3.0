import 'package:flutter/material.dart';
import 'package:mcp_test_app/config/themes/v3/v3_theme_scope.dart';

/// Figma component: "Currency Card"
/// Component set node: 849:3263
///
/// Displays a currency with flag emoji, currency code, and balance amount.
/// Supports three states via [CurrencyCardVariant]:
/// - [CurrencyCardVariant.show] — displays the full balance (integer + decimal)
/// - [CurrencyCardVariant.hide] — masks the balance with asterisks
/// - [CurrencyCardVariant.error] — shows a dash to indicate an error state
enum CurrencyCardVariant { show, hide, error }

class V3CurrencyCard extends StatelessWidget {
  const V3CurrencyCard({
    super.key,
    required this.flag,
    required this.currencyCode,
    this.integerPart = '9,999',
    this.decimalPart = '.99',
    this.variant = CurrencyCardVariant.show,
    this.onTap,
  });

  /// Country flag emoji (e.g. "🇬🇧")
  final String flag;

  /// ISO 4217 currency code (e.g. "GBP")
  final String currencyCode;

  /// Integer portion of the balance (e.g. "9,999")
  final String integerPart;

  /// Decimal portion of the balance (e.g. ".99")
  final String decimalPart;

  /// Controls the display state of the card
  final CurrencyCardVariant variant;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      button: onTap != null,
      enabled: onTap != null,
      onTap: onTap,
      label: '$currencyCode currency card',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minWidth: 74),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.backgroundWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.borderPrimary, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFlagRow(colors),
              const SizedBox(height: 8),
              _buildValueRow(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlagRow(dynamic colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 4),
        Text(
          currencyCode,
          style: TextStyle(
            fontFamily: 'Noto Sans',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 16 / 12,
            color: colors.contentSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildValueRow(dynamic colors) {
    final normalizedDecimalPart = _normalizeDecimalPart(decimalPart);

    switch (variant) {
      case CurrencyCardVariant.show:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              integerPart,
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: colors.contentPrimary,
              ),
            ),
            Text(
              normalizedDecimalPart,
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: colors.contentSecondary,
              ),
            ),
          ],
        );

      case CurrencyCardVariant.hide:
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '*',
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
                color: colors.contentPrimary,
              ),
            ),
            Text(
              '.**',
              style: TextStyle(
                fontFamily: 'Noto Sans',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                height: 16 / 12,
                color: colors.contentSecondary,
              ),
            ),
          ],
        );

      case CurrencyCardVariant.error:
        return Text(
          '-',
          style: TextStyle(
            fontFamily: 'Noto Sans',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
            color: colors.contentPrimary,
          ),
        );
    }
  }

  String _normalizeDecimalPart(String value) {
    final digits = value.startsWith('.') ? value.substring(1) : value;
    final normalized = digits.padRight(2, '0');
    return '.${normalized.substring(0, 2)}';
  }
}
