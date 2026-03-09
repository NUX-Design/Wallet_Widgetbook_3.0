import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';

enum ItemListType { common, transactionIn, transactionOut }

class ItemList extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? iconPath;
  final VoidCallback? onTap;
  final String? trailingText;
  final bool?
  isSelected; // If not null, shows radio button. true = checked, false = unchecked.
  final ItemListType type;
  final String? amount;
  final Color? amountColor;

  const ItemList({
    super.key,
    this.title = 'History',
    this.subtitle,
    this.iconPath,
    this.onTap,
    this.trailingText,
    this.isSelected,
    this.type = ItemListType.common,
    this.amount,
    this.amountColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeMode =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    final isTransactionType = _isTransactionType;
    final horizontalPadding = isTransactionType ? 16.0 : 16.0;
    final verticalPadding = isTransactionType ? 16.0 : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints:
            isTransactionType
                ? const BoxConstraints(minHeight: 64)
                : const BoxConstraints.tightFor(height: 56),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        decoration: BoxDecoration(
          color: ThemeColors.get(themeMode, 'fill/base/300'),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildLeadingIcon(themeMode),
            SizedBox(width: isTransactionType ? 16 : 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Noto Sans Thai',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 16 / 13,
                      color: ThemeColors.get(themeMode, 'text/base/600'),
                    ),
                  ),
                  if (subtitle != null && isTransactionType) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontFamily: 'Noto Sans Thai',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        height: 12 / 10,
                        color: ThemeColors.get(themeMode, 'text/base/500'),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            _buildTrailingWidget(context, themeMode),
          ],
        ),
      ),
    );
  }

  bool get _isTransactionType =>
      type == ItemListType.transactionIn || type == ItemListType.transactionOut;

  String get _transactionIconPath {
    switch (type) {
      case ItemListType.transactionIn:
        return 'lib/assets/images/arrow-down-left-round.png';
      case ItemListType.transactionOut:
        return 'lib/assets/images/arrow-up-right-round.png';
      case ItemListType.common:
        return '';
    }
  }

  Widget _buildLeadingIcon(String themeMode) {
    if (_isTransactionType) {
      return SizedBox(
        width: 24,
        height: 24,
        child: Image.asset(_transactionIconPath, width: 24, height: 24),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child:
          iconPath != null
              ? SvgPicture.asset(iconPath!, width: 24, height: 24)
              : _buildPlaceholderIcon(themeMode),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, String themeMode) {
    if (_isTransactionType && amount != null) {
      return Text(
        amount!,
        style: TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 11,
          fontWeight: FontWeight.w500,
          height: 14 / 11,
          color: amountColor ?? _defaultAmountColor(themeMode),
        ),
      );
    } else if (isSelected != null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          isSelected!
              ? 'lib/assets/images/radio_button_check.svg'
              : 'lib/assets/images/radio_button_uncheck.svg',
          width: 24,
          height: 24,
          fit: BoxFit.contain,
          colorFilter:
              isSelected!
                  ? null
                  : ColorFilter.mode(
                    ThemeColors.get(themeMode, 'text/base/600'),
                    BlendMode.srcIn,
                  ),
        ),
      );
    } else if (trailingText != null) {
      return Text(
        trailingText!,
        style: TextStyle(
          fontFamily: 'Noto Sans Thai',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 16 / 13,
          color: ThemeColors.get(themeMode, 'text/base/600'),
        ),
      );
    } else {
      return SizedBox(
        width: 24,
        height: 24,
        child: SvgPicture.asset(
          'lib/assets/images/arrow-right-01.svg',
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(
            ThemeColors.get(themeMode, 'primary/400'),
            BlendMode.srcIn,
          ),
        ),
      );
    }
  }

  Color _defaultAmountColor(String themeMode) {
    if (type == ItemListType.transactionOut) {
      return ThemeColors.get(themeMode, 'text/base/danger');
    }
    return ThemeColors.get(themeMode, 'text/base/success');
  }

  Widget _buildPlaceholderIcon(String themeMode) {
    return SvgPicture.asset(
      'lib/assets/images/Transaction History.svg',
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        ThemeColors.get(themeMode, 'text/base/600'),
        BlendMode.srcIn,
      ),
    );
  }
}
