import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_primitives.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_typography.dart';

/// One icon-only action rendered by [V3Header].
class V3HeaderAction {
  const V3HeaderAction({
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.semanticHint,
    this.tooltip,
  });

  final Widget icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? semanticHint;
  final String? tooltip;
}

/// Theme V3 page header mapped to Figma component set `Header` (`372:297`).
///
/// Assign this widget directly to [Scaffold.appBar]. All action slots are
/// optional, accept caller-owned icons, and expose no built-in side effects.
/// The full variant is Figma node `568:1322`.
class V3Header extends StatelessWidget implements PreferredSizeWidget {
  const V3Header({
    super.key,
    this.title,
    this.subtitle,
    this.leadingAction,
    this.trailingAction,
    this.topTrailingAction,
  }) : assert(
         title != null || subtitle == null,
         'A subtitle requires a title.',
       ),
       assert(
         title != null ||
             leadingAction != null ||
             trailingAction != null ||
             topTrailingAction != null,
         'V3Header requires content or an action.',
       );

  /// Localized primary page title.
  final String? title;

  /// Localized supporting text. Requires [title].
  final String? subtitle;

  /// Optional action at the start of the top action row.
  final V3HeaderAction? leadingAction;

  /// Optional contextual action aligned with the title row.
  final V3HeaderAction? trailingAction;

  /// Optional action at the end of the top action row.
  final V3HeaderAction? topTrailingAction;

  static const double _horizontalPadding = V3Spacing.space16;
  static const double _topPadding = V3Spacing.space12;
  static const double _bottomPadding = V3Spacing.space12;
  static const double _iconSize = V3Spacing.space24;
  static const double _actionTargetSize = 48;
  static const double _leadingContentGap = V3Spacing.space16;
  static const double _titleSubtitleGap = V3Spacing.space8;
  static const double _dividerWidth = 1;

  bool get _hasText => title != null;

  /// Baseline height used when this header is assigned to [Scaffold.appBar].
  ///
  /// This excludes the device's top safe-area inset. [Scaffold] adds that
  /// inset to its app-bar extent, while the widget consumes it with [SafeArea].
  @override
  Size get preferredSize =>
      Size.fromHeight(_topPadding + _contentHeight + _bottomPadding);

  double get _contentHeight {
    if (!_hasText) {
      return _iconSize;
    }

    final textHeight =
        (V3Typography.headingSmall.fontSize! *
                V3Typography.headingSmall.height!)
            .roundToDouble() +
        (subtitle == null
            ? 0
            : _titleSubtitleGap +
                (V3Typography.paragraphSmall.fontSize! *
                        V3Typography.paragraphSmall.height!)
                    .roundToDouble());
    return textHeight +
        (leadingAction == null ? 0 : _iconSize + _leadingContentGap);
  }

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);

    return DecoratedBox(
      key: const ValueKey('v3-header-surface'),
      decoration: BoxDecoration(
        color: colors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(
            color: colors.backgroundBlue,
            width: _dividerWidth,
          ),
        ),
        boxShadow: V3PrimitiveShadows.sm,
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _horizontalPadding,
                _topPadding,
                _horizontalPadding,
                _bottomPadding,
              ),
              child: _content(colors.contentPrimary),
            ),
            if (leadingAction != null)
              Positioned(
                top: _topPadding - ((_actionTargetSize - _iconSize) / 2),
                left:
                    _horizontalPadding - ((_actionTargetSize - _iconSize) / 2),
                child: _HeaderActionButton(
                  key: const ValueKey('v3-header-leading-action'),
                  action: leadingAction!,
                  foregroundColor: colors.contentPrimary,
                ),
              ),
            if (topTrailingAction != null)
              Positioned(
                top: _topPadding - ((_actionTargetSize - _iconSize) / 2),
                right:
                    _horizontalPadding - ((_actionTargetSize - _iconSize) / 2),
                child: _HeaderActionButton(
                  key: const ValueKey('v3-header-top-trailing-action'),
                  action: topTrailingAction!,
                  foregroundColor: colors.contentPrimary,
                ),
              ),
            if (trailingAction != null)
              Positioned(
                top:
                    _topPadding +
                    (_hasText
                        ? (leadingAction == null
                            ? 0
                            : _iconSize + _leadingContentGap)
                        : 0) -
                    ((_actionTargetSize - _iconSize) / 2),
                right:
                    _horizontalPadding - ((_actionTargetSize - _iconSize) / 2),
                child: _HeaderActionButton(
                  key: const ValueKey('v3-header-trailing-action'),
                  action: trailingAction!,
                  foregroundColor: colors.contentPrimary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(Color foregroundColor) {
    if (!_hasText) {
      return SizedBox(
        height: _iconSize,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (leadingAction != null)
              const SizedBox.square(dimension: _iconSize),
            if (trailingAction != null || topTrailingAction != null)
              const SizedBox.square(dimension: _iconSize),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (leadingAction != null) ...[
          const SizedBox.square(dimension: _iconSize),
          const SizedBox(height: _leadingContentGap),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title!,
                key: const ValueKey('v3-header-title'),
                style: V3Typography.headingSmall.copyWith(
                  color: foregroundColor,
                ),
              ),
            ),
            if (trailingAction != null) ...[
              const SizedBox(width: V3Spacing.space8),
              const SizedBox.square(dimension: _iconSize),
            ],
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: _titleSubtitleGap),
          Text(
            subtitle!,
            key: const ValueKey('v3-header-subtitle'),
            style: V3Typography.paragraphSmall.copyWith(color: foregroundColor),
          ),
        ],
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    super.key,
    required this.action,
    required this.foregroundColor,
  });

  final V3HeaderAction action;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    Widget button = Semantics(
      button: true,
      enabled: action.onPressed != null,
      label: action.semanticLabel,
      hint: action.semanticHint,
      child: ExcludeSemantics(
        child: SizedBox.square(
          key: const ValueKey('v3-header-action-target'),
          dimension: V3Header._actionTargetSize,
          child: IconButton(
            key: const ValueKey('v3-header-action-control'),
            onPressed: action.onPressed,
            padding: const EdgeInsets.all(V3Spacing.space12),
            color: foregroundColor,
            disabledColor: foregroundColor,
            iconSize: V3Header._iconSize,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              minimumSize: WidgetStatePropertyAll(
                Size.square(V3Header._actionTargetSize),
              ),
              maximumSize: WidgetStatePropertyAll(
                Size.square(V3Header._actionTargetSize),
              ),
            ),
            icon: IconTheme.merge(
              data: IconThemeData(
                color: foregroundColor,
                size: V3Header._iconSize,
              ),
              child: SizedBox.square(
                key: const ValueKey('v3-header-action-icon-host'),
                dimension: V3Header._iconSize,
                child: Center(child: action.icon),
              ),
            ),
          ),
        ),
      ),
    );

    if (action.tooltip != null) {
      button = Tooltip(message: action.tooltip!, child: button);
    }
    return button;
  }
}
