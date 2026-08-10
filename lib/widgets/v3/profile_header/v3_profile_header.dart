import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_color_palette.dart';
import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';
import '../icon/v3_icon_size.dart';
import '../icon/v3_lucide_icon.dart';

/// Persistent profile verification outcome. Maps to the Figma `Status` axis.
enum V3ProfileHeaderStatus { pending, error, success }

/// Compact versus scrolled layout. Maps to the Figma `State` axis.
enum V3ProfileHeaderLayoutState { defaultState, scrolled }

/// Balance visibility contract. Maps the Figma `Balance` axis (`Show`, `None`,
/// `Hide`) to an engineer-facing name. Only meaningful when [
/// V3ProfileHeaderLayoutState.scrolled] is active.
enum V3ProfileHeaderBalanceVisibility { none, visible, obscured }

/// Theme V3 profile identity header mapped to Figma component set
/// `Profile Header` (`617:235`).
///
/// Presents profile identity, verification status, an optional balance line
/// in the scrolled layout, and a trailing notification action. Light/Dark
/// colors are theme-controlled; the notification bell is the only
/// independently focusable control.
class V3ProfileHeader extends StatelessWidget {
  const V3ProfileHeader({
    super.key,
    this.status = V3ProfileHeaderStatus.success,
    this.layoutState = V3ProfileHeaderLayoutState.defaultState,
    this.balanceVisibility = V3ProfileHeaderBalanceVisibility.none,
    this.userName = '–',
    this.avatarInitials = 'CW',
    this.balanceAmount = '–',
    required this.notificationSemanticLabel,
    this.onNotificationPressed,
    this.notificationSemanticHint,
    this.notificationTooltip,
  });

  /// Persistent profile verification outcome. Selects the verification icon.
  final V3ProfileHeaderStatus status;

  /// Layout presentation. Scrolled reveals the compact balance row.
  final V3ProfileHeaderLayoutState layoutState;

  /// Balance visibility. Applies only when [layoutState] is
  /// [V3ProfileHeaderLayoutState.scrolled].
  final V3ProfileHeaderBalanceVisibility balanceVisibility;

  /// Profile display name rendered in the user-name text layer.
  final String userName;

  /// Fallback initials rendered by the avatar when no picture is supplied.
  final String avatarInitials;

  /// Formatted balance text shown when [layoutState] is
  /// [V3ProfileHeaderLayoutState.scrolled] and [balanceVisibility] is
  /// [V3ProfileHeaderBalanceVisibility.visible] or
  /// [V3ProfileHeaderBalanceVisibility.obscured]. Obscured rendering masks
  /// every digit character in this value; callers do not pass a
  /// pre-masked string.
  final String balanceAmount;

  /// Localized accessible name for the notification action. Required so
  /// this reusable widget never hardcodes user-facing copy.
  final String notificationSemanticLabel;

  final VoidCallback? onNotificationPressed;
  final String? notificationSemanticHint;
  final String? notificationTooltip;

  static const double _avatarSize = V3Spacing.space40;
  static const double _identityGap = V3Spacing.space8;
  static const double _verificationGap = V3Spacing.space8;
  static const double _balanceGap = V3Spacing.space4;
  static const double _horizontalPadding = V3Spacing.space16;
  static const double _defaultHeight = 40;
  static const double _scrolledHeight = 44;
  static const double _bellVisualSize = V3Spacing.space24;
  static const double _bellTargetSize = 48;

  bool get _isScrolled => layoutState == V3ProfileHeaderLayoutState.scrolled;

  bool get _showsBalanceRow =>
      _isScrolled && balanceVisibility != V3ProfileHeaderBalanceVisibility.none;

  double get _rowHeight => _isScrolled ? _scrolledHeight : _defaultHeight;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);

    return SizedBox(
      key: const ValueKey('v3-profile-header-root'),
      height: _rowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _Avatar(initials: avatarInitials, colors: colors),
                      const SizedBox(width: _identityGap),
                      Expanded(child: _identity(colors)),
                    ],
                  ),
                ),
                // Reserves the bell's visual footprint so the identity
                // content never overlaps it; the interactive control is
                // an overlay below sized to the 48px accessibility target.
                const SizedBox.square(dimension: _bellVisualSize),
              ],
            ),
          ),
          Positioned(
            top: (_rowHeight - _bellTargetSize) / 2,
            right:
                _horizontalPadding - ((_bellTargetSize - _bellVisualSize) / 2),
            child: _NotificationButton(
              semanticLabel: notificationSemanticLabel,
              semanticHint: notificationSemanticHint,
              tooltip: notificationTooltip,
              onPressed: onNotificationPressed,
              foregroundColor: colors.contentPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _identity(V3ColorPalette colors) {
    final nameRow = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            userName,
            key: const ValueKey('v3-profile-header-user-name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: V3Typography.labelSmall.copyWith(
              color: colors.contentPrimary,
            ),
          ),
        ),
        const SizedBox(width: _verificationGap),
        _VerificationIcon(status: status, colors: colors),
      ],
    );

    if (!_showsBalanceRow) {
      return nameRow;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameRow,
        const SizedBox(height: _balanceGap),
        Text(
          _balanceText,
          key: const ValueKey('v3-profile-header-balance'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: V3Typography.labelTiny.copyWith(color: colors.contentPrimary),
        ),
      ],
    );
  }

  String get _balanceText {
    if (balanceVisibility == V3ProfileHeaderBalanceVisibility.obscured) {
      return balanceAmount.replaceAll(RegExp(r'\d'), '*');
    }
    return balanceAmount;
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.initials, required this.colors});

  final String initials;
  final V3ColorPalette colors;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const ValueKey('v3-profile-header-avatar'),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.backgroundBlue,
      ),
      child: SizedBox.square(
        dimension: V3ProfileHeader._avatarSize,
        child: Center(
          child: Text(
            initials,
            key: const ValueKey('v3-profile-header-avatar-initials'),
            style: V3Typography.labelSmall.copyWith(
              color: colors.contentPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

class _VerificationIcon extends StatelessWidget {
  const _VerificationIcon({required this.status, required this.colors});

  final V3ProfileHeaderStatus status;
  final V3ColorPalette colors;

  @override
  Widget build(BuildContext context) {
    return IconTheme.merge(
      data: IconThemeData(color: _color, size: V3IconSize.medium.value),
      child: SizedBox.square(
        key: const ValueKey('v3-profile-header-verification-icon'),
        dimension: V3IconSize.medium.value,
        child: V3LucideIcon(_icon, size: V3IconSize.medium),
      ),
    );
  }

  Color get _color {
    switch (status) {
      case V3ProfileHeaderStatus.pending:
        return colors.stateWarning;
      case V3ProfileHeaderStatus.error:
        return colors.stateError;
      case V3ProfileHeaderStatus.success:
        return colors.stateSuccess;
    }
  }

  IconData get _icon {
    switch (status) {
      case V3ProfileHeaderStatus.pending:
        return LucideIcons.shieldAlert;
      case V3ProfileHeaderStatus.error:
        return LucideIcons.shieldBan;
      case V3ProfileHeaderStatus.success:
        return LucideIcons.shieldCheck;
    }
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.semanticLabel,
    required this.foregroundColor,
    this.semanticHint,
    this.tooltip,
    this.onPressed,
  });

  final String semanticLabel;
  final String? semanticHint;
  final String? tooltip;
  final VoidCallback? onPressed;
  final Color foregroundColor;

  static const double _iconSize = V3Spacing.space24;
  static const double _targetSize = 48;

  @override
  Widget build(BuildContext context) {
    Widget button = Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      hint: semanticHint,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const ValueKey('v3-profile-header-notification-target'),
          dimension: _targetSize,
          child: IconButton(
            key: const ValueKey('v3-profile-header-notification-control'),
            onPressed: onPressed,
            padding: const EdgeInsets.all(V3Spacing.space12),
            color: foregroundColor,
            disabledColor: foregroundColor,
            iconSize: _iconSize,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: WidgetStatePropertyAll(Size.square(_targetSize)),
              maximumSize: WidgetStatePropertyAll(Size.square(_targetSize)),
            ),
            icon: IconTheme.merge(
              data: IconThemeData(color: foregroundColor, size: _iconSize),
              child: SizedBox.square(
                key: const ValueKey('v3-profile-header-notification-icon-host'),
                dimension: _iconSize,
                child: const Center(
                  child: V3LucideIcon(
                    LucideIcons.bell,
                    size: V3IconSize.medium,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}
