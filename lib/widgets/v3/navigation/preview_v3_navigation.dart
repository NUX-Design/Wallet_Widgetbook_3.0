import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_icon_stroke.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_navigation.dart';

void main() => runApp(const V3NavigationPreviewApp());

class V3NavigationPreviewApp extends StatelessWidget {
  const V3NavigationPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3NavigationPreview(),
    );
  }
}

class V3NavigationPreview extends StatefulWidget {
  const V3NavigationPreview({super.key});

  @override
  State<V3NavigationPreview> createState() => _V3NavigationPreviewState();
}

class _V3NavigationPreviewState extends State<V3NavigationPreview> {
  Brightness _brightness = Brightness.light;
  int _selectedIndex = 0;

  // Lucide has no filled/outline icon pairs (stroke-only icon set), so the
  // selected/inactive distinction mirrors the label's existing Bold/Medium
  // pairing (see V3_NAVIGATION_GUIDE.md): selected destinations render at
  // V3IconStroke.bold, inactive destinations at the V3IconStroke.regular
  // default. Mapping recorded in V3_NAVIGATION_GUIDE.md's Figma-to-Lucide
  // table.
  static const _destinations = [
    V3NavigationDestination(
      label: 'Home',
      icon: V3LucideIcon(LucideIcons.house),
      selectedIcon: V3LucideIcon(LucideIcons.house, stroke: V3IconStroke.bold),
    ),
    V3NavigationDestination(
      label: 'Card',
      icon: V3LucideIcon(LucideIcons.creditCard),
      selectedIcon: V3LucideIcon(
        LucideIcons.creditCard,
        stroke: V3IconStroke.bold,
      ),
    ),
    V3NavigationDestination(
      label: 'Services',
      icon: V3LucideIcon(LucideIcons.layoutGrid),
      selectedIcon: V3LucideIcon(
        LucideIcons.layoutGrid,
        stroke: V3IconStroke.bold,
      ),
    ),
    V3NavigationDestination(
      label: 'Menu',
      icon: V3LucideIcon(LucideIcons.menu),
      selectedIcon: V3LucideIcon(LucideIcons.menu, stroke: V3IconStroke.bold),
    ),
  ];

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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Navigation',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: colors.contentPrimary),
                        ),
                        SegmentedButton<Brightness>(
                          key: const ValueKey('v3-navigation-theme-toggle'),
                          segments: const [
                            ButtonSegment(
                              value: Brightness.light,
                              label: Text('Light'),
                            ),
                            ButtonSegment(
                              value: Brightness.dark,
                              label: Text('Dark'),
                            ),
                          ],
                          selected: {_brightness},
                          showSelectedIcon: false,
                          onSelectionChanged: (selection) {
                            setState(() => _brightness = selection.single);
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Selected: ${_destinations[_selectedIndex].label}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.contentPrimary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            bottomNavigationBar: V3Navigation(
              destinations: _destinations,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() => _selectedIndex = index);
              },
              scanIcon: const V3LucideIcon(
                LucideIcons.scanLine,
                svgAsset: 'lib/assets/icons/v3/lucide/scan-line.svg',
              ),
              scanSemanticLabel: 'Scan QR code',
              onScanPressed: () {},
            ),
          );
        },
      ),
    );
  }
}
