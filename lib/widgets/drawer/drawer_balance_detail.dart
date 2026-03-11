import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart' as theme;
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/announce/announcement_warning.dart';
import 'package:mcp_test_app/widgets/button/buttons.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

class DrawerBalanceDetail extends StatelessWidget {
  static const double _maxDrawerHeight = 640;

  final String totalBalanceAmount;
  final String totalBalanceLabel;
  final String currency;
  final String holdAmountLabel;
  final String holdAmountValue;
  final String ledgerBalanceLabel;
  final String ledgerBalanceValue;
  final String warningText;
  final String buttonText;
  final VoidCallback? onClose;
  final VoidCallback? onViewHistory;
  final String historyToastMessage;
  final bool isLoading;
  final bool showButton;

  const DrawerBalanceDetail({
    super.key,
    required this.totalBalanceAmount,
    this.totalBalanceLabel = 'Total Balance',
    this.currency = 'THB',
    required this.holdAmountLabel,
    required this.holdAmountValue,
    required this.ledgerBalanceLabel,
    required this.ledgerBalanceValue,
    required this.warningText,
    this.buttonText = 'View History',
    this.onClose,
    this.onViewHistory,
    this.historyToastMessage = 'Rediect to History Page',
    this.isLoading = false,
    this.showButton = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String totalBalanceAmount,
    String totalBalanceLabel = 'Total Balance',
    String currency = 'THB',
    required String holdAmountLabel,
    required String holdAmountValue,
    required String ledgerBalanceLabel,
    required String ledgerBalanceValue,
    required String warningText,
    String buttonText = 'View History',
    VoidCallback? onViewHistory,
    String historyToastMessage = 'Rediect to History Page',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      barrierColor: const Color.fromRGBO(0, 0, 0, 0.55),
      builder:
          (context) => BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: DrawerBalanceDetail(
              totalBalanceAmount: totalBalanceAmount,
              totalBalanceLabel: totalBalanceLabel,
              currency: currency,
              holdAmountLabel: holdAmountLabel,
              holdAmountValue: holdAmountValue,
              ledgerBalanceLabel: ledgerBalanceLabel,
              ledgerBalanceValue: ledgerBalanceValue,
              warningText: warningText,
              buttonText: buttonText,
              onClose: () => Navigator.pop(context),
              onViewHistory: onViewHistory,
              historyToastMessage: historyToastMessage,
            ),
          ),
    );
  }

  static void _handleDefaultViewHistory(BuildContext context, String message) {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.hideCurrentSnackBar();

    if (navigator.canPop()) {
      navigator.pop();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding =
        mediaQuery.viewPadding.bottom > 0
            ? mediaQuery.viewPadding.bottom
            : mediaQuery.padding.bottom;
    final drawerHeight = math.min(
      mediaQuery.size.height * 0.80,
      _maxDrawerHeight,
    );
    final holdAmountTitle = holdAmountLabel.replaceAll('*', '').trim();
    final warningPrefix = '*$holdAmountTitle';
    final warningSuffix =
        warningText.startsWith(warningPrefix)
            ? warningText.substring(warningPrefix.length).trimLeft()
            : warningText.trim();

    return Container(
      height: drawerHeight,
      decoration: BoxDecoration(
        color: theme.ThemeColors.get(brightnessKey, 'fill/base/100'),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 24,
                    child: Row(
                      children: [
                        const SizedBox(width: 24, height: 24),
                        Expanded(
                          child: LottieSkeleton(
                            isLoading: isLoading,
                            borderRadius: BorderRadius.circular(8),
                            child: Text(
                              l10n.homeDrawerHeaderTitleBalanceDetail,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.notoSansThai(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                height: 1.6,
                                color: theme.ThemeColors.get(
                                  brightnessKey,
                                  'text/base/600',
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onClose,
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: Icon(
                              Icons.close,
                              size: 24,
                              color: theme.ThemeColors.get(
                                brightnessKey,
                                'text/base/600',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          LottieSkeleton(
                            isLoading: isLoading,
                            borderRadius: BorderRadius.circular(72),
                            child: Image.asset(
                              'lib/assets/images/drawer_balance_detail_coin.png',
                              width: 144,
                              height: 144,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => Container(
                                    width: 144,
                                    height: 144,
                                    color: theme.ThemeColors.get(
                                      brightnessKey,
                                      'fill/base/300',
                                    ),
                                  ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(minHeight: 165),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: theme.ThemeColors.get(
                                brightnessKey,
                                'fill/base/300',
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                LottieSkeleton(
                                  isLoading: isLoading,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Text(
                                    totalBalanceLabel,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.51,
                                      color: theme.ThemeColors.get(
                                        brightnessKey,
                                        'text/base/600',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                LottieSkeleton(
                                  isLoading: isLoading,
                                  borderRadius: BorderRadius.circular(4),
                                  child: Text(
                                    '$totalBalanceAmount $currency',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.notoSansThai(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      height: 1.27,
                                      color: theme.ThemeColors.get(
                                        brightnessKey,
                                        'success/400',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  height: 1,
                                  color: theme.ThemeColors.get(
                                    brightnessKey,
                                    'stroke/base/600',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _DetailRow(
                                  label: holdAmountTitle,
                                  value: holdAmountValue,
                                  currency: currency,
                                  brightnessKey: brightnessKey,
                                  isLoading: isLoading,
                                  highlightAsterisk: true,
                                ),
                                const SizedBox(height: 16),
                                _DetailRow(
                                  label: ledgerBalanceLabel,
                                  value: ledgerBalanceValue,
                                  currency: currency,
                                  brightnessKey: brightnessKey,
                                  isLoading: isLoading,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.ThemeColors.get(
                                  brightnessKey,
                                  'primary/500',
                                ),
                              ),
                            ),
                            child: LottieSkeleton(
                              isLoading: isLoading,
                              borderRadius: BorderRadius.circular(12),
                              child: Builder(
                                builder: (context) {
                                  final textColor = theme.ThemeColors.get(
                                    brightnessKey,
                                    'text/base/warning',
                                  );
                                  return AnnouncementWarning(
                                    title: '',
                                    description: '',
                                    descriptionSpans: [
                                      TextSpan(
                                        text: warningPrefix,
                                        style: TextStyle(
                                          color: textColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' $warningSuffix',
                                        style: TextStyle(color: textColor),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showButton)
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                bottomPadding > 0 ? 16 : 40,
              ),
              child: LottieSkeleton(
                isLoading: isLoading,
                borderRadius: BorderRadius.circular(24),
                child: Buttons(
                  text: buttonText,
                  type: ButtonType.primary,
                  onPressed:
                      onViewHistory ??
                      () => _handleDefaultViewHistory(
                        context,
                        historyToastMessage,
                      ),
                ),
              ),
            ),
          if (bottomPadding > 0)
            Container(
              height: bottomPadding,
              color: theme.ThemeColors.get(brightnessKey, 'fill/base/100'),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.currency,
    required this.brightnessKey,
    required this.isLoading,
    this.highlightAsterisk = false,
  });

  final String label;
  final String value;
  final String currency;
  final String brightnessKey;
  final bool isLoading;
  final bool highlightAsterisk;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LottieSkeleton(
          isLoading: isLoading,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Text(
                label,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.23,
                  color: theme.ThemeColors.get(brightnessKey, 'text/base/400'),
                ),
              ),
              if (highlightAsterisk)
                Text(
                  '*',
                  style: GoogleFonts.notoSansThai(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.23,
                    color: theme.ThemeColors.get(brightnessKey, 'danger/500'),
                  ),
                ),
            ],
          ),
        ),
        LottieSkeleton(
          isLoading: isLoading,
          borderRadius: BorderRadius.circular(4),
          child: Row(
            children: [
              Text(
                value,
                textAlign: TextAlign.right,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.23,
                  color: theme.ThemeColors.get(brightnessKey, 'text/base/600'),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                currency,
                style: GoogleFonts.notoSansThai(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.23,
                  color: theme.ThemeColors.get(brightnessKey, 'text/base/600'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
