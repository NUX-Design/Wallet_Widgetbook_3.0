import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import 'v3_icon_size.dart';
import 'v3_icon_stroke.dart';
import 'v3_lucide_icon.dart';

void main() => runApp(const V3LucideIconPreviewApp());

class V3LucideIconPreviewApp extends StatelessWidget {
  const V3LucideIconPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3LucideIconPreview(),
    );
  }
}

class V3LucideIconPreview extends StatefulWidget {
  const V3LucideIconPreview({super.key});

  @override
  State<V3LucideIconPreview> createState() => _V3LucideIconPreviewState();
}

class _V3LucideIconPreviewState extends State<V3LucideIconPreview> {
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
                  const _SizeStrokeMatrix(),
                  const SizedBox(height: 24),
                  const _PackageVsSvgComparison(),
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
          'Lucide Icon',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: colors.contentPrimary),
        ),
        SegmentedButton<Brightness>(
          key: const ValueKey('v3-lucide-icon-theme-toggle'),
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
  const _PreviewPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return ColoredBox(
      color: colors.backgroundPrimary,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colors.contentPrimary),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

/// [V3IconSize] rows × [V3IconStroke] columns, package renderer only.
class _SizeStrokeMatrix extends StatelessWidget {
  const _SizeStrokeMatrix();

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return _PreviewPanel(
      title: 'Sizes × Strokes (package renderer)',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Row(
            children: [
              const SizedBox(width: 60),
              for (final stroke in V3IconStroke.values)
                Expanded(
                  child: Text(
                    stroke.name,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.contentSecondary,
                    ),
                  ),
                ),
            ],
          ),
          for (final size in V3IconSize.values) _SizeRow(size: size),
        ],
      ),
    );
  }
}

class _SizeRow extends StatelessWidget {
  const _SizeRow({required this.size});

  final V3IconSize size;

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '${size.name} (${size.value.toInt()}px)',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: colors.contentSecondary),
          ),
        ),
        for (final stroke in V3IconStroke.values)
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: IconTheme(
                data: IconThemeData(color: colors.contentPrimary),
                child: V3LucideIcon(
                  LucideIcons.house,
                  size: size,
                  stroke: stroke,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Package renderer vs. the verified checked-in SVG override for
/// `LucideIcons.scanLine`, side by side at the Navigation Scan size.
class _PackageVsSvgComparison extends StatelessWidget {
  const _PackageVsSvgComparison();

  @override
  Widget build(BuildContext context) {
    final colors = V3ThemeScope.colorsOf(context);
    return _PreviewPanel(
      title: 'Package renderer vs. checked-in SVG override (scan-line)',
      child: IconTheme(
        data: IconThemeData(color: colors.contentPrimary, size: 32),
        child: Row(
          spacing: 32,
          children: [
            Column(
              spacing: 8,
              children: [
                const V3LucideIcon(
                  LucideIcons.scanLine,
                  stroke: V3IconStroke.light,
                ),
                Text(
                  'package · light',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.contentSecondary,
                  ),
                ),
              ],
            ),
            Column(
              spacing: 8,
              children: [
                const V3LucideIcon(
                  LucideIcons.scanLine,
                  svgAsset: 'lib/assets/icons/v3/lucide/scan-line.svg',
                ),
                Text(
                  'SVG override',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.contentSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
