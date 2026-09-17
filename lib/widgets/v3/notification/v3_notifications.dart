import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';
import '../icon/v3_lucide_icon.dart';

enum V3NotificationState { unread, read }

/// Theme V3 notification row mapped to Figma component set
/// `Notifications` (`1140:2402`).
///
/// The row is one actionable accessibility stop. The referenced
/// `credit-card-add` and `chevron-right` icons are rendered by the shared
/// Lucide adapters so the component follows the source composition without
/// exposing icon slots that are not part of the Figma API.
class V3Notifications extends StatelessWidget {
  const V3Notifications({
    super.key,
    required this.title,
    required this.message,
    required this.timestamp,
    this.state = V3NotificationState.unread,
    this.onPressed,
    this.semanticLabel,
    this.semanticHint = 'Opens notification details',
    this.tooltip,
  });

  final String title;
  final String message;
  final String timestamp;
  final V3NotificationState state;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final String? semanticHint;
  final String? tooltip;

  static const double _width = 343;
  static const double _height = 100;
  static const double _cardRadius = 20;
  static const double _borderWidth = 1;
  static const double _iconBubbleSize = 44;
  static const double _iconSize = V3Spacing.space24;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    final surface =
        state == V3NotificationState.unread
            ? colors.backgroundWhite
            : colors.backgroundPrimary;
    final titleColor =
        state == V3NotificationState.unread
            ? colors.contentPrimary
            : colors.contentSecondary;
    final isUnread = state == V3NotificationState.unread;
    final iconBubbleOpacity = isUnread ? 1.0 : 0.5;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(_cardRadius),
      side: BorderSide(color: colors.borderPrimary, width: _borderWidth),
    );
    final stateLabel = state == V3NotificationState.unread ? 'Unread' : 'Read';

    Widget row = Material(
      color: surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(_cardRadius),
        child: SizedBox(
          key: const ValueKey('v3-notifications-surface'),
          width: _width,
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: V3Spacing.space16,
              vertical: V3Spacing.space12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Opacity(
                        key: const ValueKey('v3-notifications-icon-opacity'),
                        opacity: iconBubbleOpacity,
                        child: SizedBox.square(
                          dimension: _iconBubbleSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.backgroundBlue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: IconTheme(
                                data: IconThemeData(
                                  color: colors.contentBlue,
                                  size: _iconSize,
                                ),
                                child: const ExcludeSemantics(
                                  child: V3LucideCreditCardPlusIcon(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: V3Spacing.space16),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: V3Typography.labelSmall.copyWith(
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: V3Spacing.space4),
                            Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: V3Typography.paragraphTiny.copyWith(
                                color: colors.contentSecondary,
                              ),
                            ),
                            const SizedBox(height: V3Spacing.space4),
                            Text(
                              timestamp,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: V3Typography.paragraphTiny.copyWith(
                                color: colors.contentNeutral,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: V3Spacing.space8),
                SizedBox.square(
                  dimension: _iconSize,
                  child: IconTheme(
                    key: const ValueKey('v3-notifications-chevron-theme'),
                    data: IconThemeData(
                      color:
                          isUnread
                              ? colors.contentPrimary
                              : colors.contentSecondary,
                      size: _iconSize,
                    ),
                    child: const ExcludeSemantics(
                      child: V3LucideChevronRightIcon(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    row = Semantics(
      button: onPressed != null,
      enabled: onPressed != null,
      label: semanticLabel ?? title,
      value: '$message, $timestamp, $stateLabel',
      hint: semanticHint,
      child: ExcludeSemantics(child: row),
    );

    final effectiveTooltip = tooltip;
    return effectiveTooltip == null
        ? row
        : Tooltip(message: effectiveTooltip, child: row);
  }
}
