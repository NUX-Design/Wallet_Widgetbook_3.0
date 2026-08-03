import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_default_button.dart';

void main() => runApp(const V3DefaultButtonPreviewApp());

class V3DefaultButtonPreviewApp extends StatelessWidget {
  const V3DefaultButtonPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3DefaultButtonPreview(),
    );
  }
}

class V3DefaultButtonPreview extends StatefulWidget {
  const V3DefaultButtonPreview({super.key});

  @override
  State<V3DefaultButtonPreview> createState() => _V3DefaultButtonPreviewState();
}

class _V3DefaultButtonPreviewState extends State<V3DefaultButtonPreview> {
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
                  const _FigmaDefaultButtonMatrix(),
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
          'Default Button',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colors.contentPrimary),
        ),
        SegmentedButton<Brightness>(
          key: const ValueKey('v3-default-button-theme-toggle'),
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

class _FigmaDefaultButtonMatrix extends StatelessWidget {
  const _FigmaDefaultButtonMatrix();

  @override
  Widget build(BuildContext context) {
    return _PreviewPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          const _VariantLabels(),
          for (final state in V3DefaultButtonState.values)
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
        for (final variant in V3DefaultButtonVariant.values)
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

  final V3DefaultButtonState state;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            state == V3DefaultButtonState.defaultState ? 'Default' : state.name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colors.contentSecondary),
          ),
        ),
        for (final variant in V3DefaultButtonVariant.values)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: V3DefaultButton(
                label: 'Label',
                variant: variant,
                state: state,
                leadingIcon: const V3LucideIcon(LucideIcons.circle),
                trailingIcon: const V3LucideIcon(LucideIcons.circle),
                onPressed:
                    state == V3DefaultButtonState.disabled ? null : () {},
              ),
            ),
          ),
      ],
    );
  }
}
