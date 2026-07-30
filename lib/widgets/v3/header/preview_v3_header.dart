import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_icon_stroke.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_header.dart';

void main() => runApp(const V3HeaderPreviewApp());

class V3HeaderPreviewApp extends StatelessWidget {
  const V3HeaderPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3HeaderPreview(),
    );
  }
}

class V3HeaderPreview extends StatefulWidget {
  const V3HeaderPreview({super.key});

  @override
  State<V3HeaderPreview> createState() => _V3HeaderPreviewState();
}

class _V3HeaderPreviewState extends State<V3HeaderPreview> {
  Brightness _brightness = Brightness.light;
  String _lastAction = 'None';

  void _recordAction(String action) {
    setState(() => _lastAction = action);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(brightness: _brightness, useMaterial3: true),
      child: Builder(
        builder: (context) {
          final colors = V3ThemeScope.colorsOf(context);
          return Scaffold(
            backgroundColor: colors.backgroundPrimary,
            appBar: V3Header(
              title: 'Header title',
              subtitle: 'Subheader',
              leadingAction: V3HeaderAction(
                icon: const V3LucideIcon(
                  key: ValueKey('v3-header-preview-inline-back'),
                  LucideIcons.arrowLeft,
                  stroke: V3IconStroke.light,
                ),
                semanticLabel: 'Go back',
                onPressed: () => _recordAction('Go back'),
              ),
              trailingAction: V3HeaderAction(
                icon: const V3LucideIcon(
                  key: ValueKey('v3-header-preview-context-info'),
                  LucideIcons.info,
                  stroke: V3IconStroke.light,
                ),
                semanticLabel: 'More information',
                onPressed: () => _recordAction('More information'),
              ),
              topTrailingAction: V3HeaderAction(
                icon: const V3LucideIcon(
                  key: ValueKey('v3-header-preview-inline-close'),
                  LucideIcons.x,
                  stroke: V3IconStroke.light,
                ),
                semanticLabel: 'Close',
                onPressed: () => _recordAction('Close'),
              ),
            ),
            body: SafeArea(
              top: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: SegmentedButton<Brightness>(
                      key: const ValueKey('v3-header-theme-toggle'),
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
                  ),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          'Action: $_lastAction',
                          key: const ValueKey('v3-header-action-feedback'),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: colors.contentPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
