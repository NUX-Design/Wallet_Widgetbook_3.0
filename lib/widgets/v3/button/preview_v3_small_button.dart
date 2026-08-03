import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_small_button.dart';

void main() => runApp(const V3SmallButtonPreviewApp());

class V3SmallButtonPreviewApp extends StatelessWidget {
  const V3SmallButtonPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3SmallButtonPreview(),
    );
  }
}

class V3SmallButtonPreview extends StatefulWidget {
  const V3SmallButtonPreview({super.key});

  @override
  State<V3SmallButtonPreview> createState() => _V3SmallButtonPreviewState();
}

class _V3SmallButtonPreviewState extends State<V3SmallButtonPreview> {
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
                  _ThemeToolbar(
                    brightness: _brightness,
                    onChanged: (brightness) {
                      setState(() => _brightness = brightness);
                    },
                  ),
                  const SizedBox(height: 24),
                  const _FigmaSmallButtonMatrix(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ThemeToolbar extends StatelessWidget {
  const _ThemeToolbar({required this.brightness, required this.onChanged});

  final Brightness brightness;
  final ValueChanged<Brightness> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Small Button',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colors.contentPrimary),
        ),
        SegmentedButton<Brightness>(
          key: const ValueKey('v3-small-button-theme-toggle'),
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
          selected: {brightness},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => onChanged(selection.single),
          style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(colors.contentPrimary),
          ),
        ),
      ],
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return ColoredBox(
      color: colors.backgroundPrimary,
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _FigmaSmallButtonMatrix extends StatelessWidget {
  const _FigmaSmallButtonMatrix();

  @override
  Widget build(BuildContext context) {
    return _PreviewPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const _VariantLabels(),
          for (final state in V3SmallButtonState.values)
            _StateRow(state: state),
        ],
      ),
    );
  }
}

class _VariantLabels extends StatelessWidget {
  const _VariantLabels();

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      children: [
        const SizedBox(width: 60),
        for (final variant in V3SmallButtonVariant.values)
          Expanded(
            child: Text(
              variant.name,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.contentSecondary),
            ),
          ),
      ],
    );
  }
}

class _StateRow extends StatelessWidget {
  const _StateRow({required this.state});

  final V3SmallButtonState state;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            state == V3SmallButtonState.defaultState ? 'Default' : state.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colors.contentSecondary),
          ),
        ),
        for (final variant in V3SmallButtonVariant.values)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: V3SmallButton(
                label: 'Label',
                variant: variant,
                state: state,
                leadingIcon: const V3LucideIcon(LucideIcons.circle),
                trailingIcon: const V3LucideIcon(LucideIcons.circle),
                onPressed: state == V3SmallButtonState.disabled ? null : () {},
              ),
            ),
          ),
      ],
    );
  }
}
