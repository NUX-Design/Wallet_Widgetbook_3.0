import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_medium_button.dart';

void main() => runApp(const V3MediumButtonPreviewApp());

class V3MediumButtonPreviewApp extends StatelessWidget {
  const V3MediumButtonPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3MediumButtonPreview(),
    );
  }
}

class V3MediumButtonPreview extends StatefulWidget {
  const V3MediumButtonPreview({super.key});

  @override
  State<V3MediumButtonPreview> createState() => _V3MediumButtonPreviewState();
}

class _V3MediumButtonPreviewState extends State<V3MediumButtonPreview> {
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
                  const _FigmaMediumButtonMatrix(),
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
          'Medium Button',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colors.contentPrimary),
        ),
        SegmentedButton<Brightness>(
          key: const ValueKey('v3-medium-button-theme-toggle'),
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

class _FigmaMediumButtonMatrix extends StatelessWidget {
  const _FigmaMediumButtonMatrix();

  @override
  Widget build(BuildContext context) {
    return _PreviewPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const _VariantLabels(),
          for (final state in V3MediumButtonState.values)
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
        for (final variant in V3MediumButtonVariant.values)
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

  final V3MediumButtonState state;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            state == V3MediumButtonState.defaultState ? 'Default' : state.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colors.contentSecondary),
          ),
        ),
        for (final variant in V3MediumButtonVariant.values)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: V3MediumButton(
                label: 'Label',
                variant: variant,
                state: state,
                leadingIcon: const V3LucideIcon(LucideIcons.circle),
                trailingIcon: const V3LucideIcon(LucideIcons.circle),
                onPressed: state == V3MediumButtonState.disabled ? null : () {},
              ),
            ),
          ),
      ],
    );
  }
}
