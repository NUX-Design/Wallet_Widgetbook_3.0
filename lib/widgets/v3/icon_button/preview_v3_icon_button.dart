import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../../../config/themes/v3/v3_dimensions.dart';
import '../../../config/themes/v3/v3_typography.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_icon_button.dart';

void main() => runApp(const V3IconButtonPreviewApp());

class V3IconButtonPreviewApp extends StatelessWidget {
  const V3IconButtonPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3IconButtonPreview(),
    );
  }
}

class V3IconButtonPreview extends StatefulWidget {
  const V3IconButtonPreview({super.key});

  @override
  State<V3IconButtonPreview> createState() => _V3IconButtonPreviewState();
}

class _V3IconButtonPreviewState extends State<V3IconButtonPreview> {
  Brightness _brightness = Brightness.light;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(brightness: _brightness, useMaterial3: true),
      child: Builder(
        builder: (context) {
          final colors = V3ThemeScope.colorsOf(context);
          return Scaffold(
            backgroundColor: colors.backgroundPrimary,
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Icon Button',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: colors.contentPrimary,
                        ),
                      ),
                      SegmentedButton<Brightness>(
                        key: const ValueKey('v3-icon-button-theme-toggle'),
                        segments: const [
                          ButtonSegment(
                            value: Brightness.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: Brightness.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {_brightness},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          setState(() => _brightness = selection.single);
                        },
                        style: ButtonStyle(
                          foregroundColor: WidgetStatePropertyAll(
                            colors.contentPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const _IconButtonMatrix(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _IconButtonMatrix extends StatelessWidget {
  const _IconButtonMatrix();

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: [
        for (final state in V3IconButtonState.values)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                _stateLabel(state),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colors.contentSecondary,
                ),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final size in V3IconButtonSize.values)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        V3IconButton(
                          icon: const V3LucideIcon(LucideIcons.search),
                          semanticLabel: 'Search',
                          size: size,
                          state: state,
                          onPressed:
                              state == V3IconButtonState.disabled
                                  ? null
                                  : () {},
                        ),
                        SizedBox(height: _labelSpacer(size)),
                        Text(
                          _sizeLabel(size),
                          key: ValueKey(
                            'v3-icon-button-size-label-${size.name}',
                          ),
                          style: V3Typography.labelMedium.copyWith(
                            color: colors.contentPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  String _stateLabel(V3IconButtonState state) => switch (state) {
    V3IconButtonState.defaultState => 'Default',
    V3IconButtonState.hoverActive => 'Hover & Active',
    V3IconButtonState.disabled => 'Disabled',
  };

  String _sizeLabel(V3IconButtonSize size) => switch (size) {
    V3IconButtonSize.small => 'Small',
    V3IconButtonSize.medium => 'Medium',
    V3IconButtonSize.large => 'Large',
    V3IconButtonSize.defaultSize => 'Default',
  };

  // Small and Medium reserve extra space inside their 48px accessibility
  // target. Compensate for that inset so every visible circle keeps the same
  // 8px Figma gap to its preview label.
  double _labelSpacer(V3IconButtonSize size) => switch (size) {
    V3IconButtonSize.small => V3Spacing.space0,
    V3IconButtonSize.medium => V3Spacing.space4,
    V3IconButtonSize.large || V3IconButtonSize.defaultSize => V3Spacing.space8,
  };
}
