import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import '../icon/v3_icon_size.dart';
import '../icon/v3_lucide_icon.dart';
import 'v3_balance_card.dart';

void main() => runApp(const V3BalanceCardPreviewApp());

class V3BalanceCardPreviewApp extends StatelessWidget {
  const V3BalanceCardPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3BalanceCardPreview(),
    );
  }
}

/// Standalone preview for [V3BalanceCard].
class V3BalanceCardPreview extends StatefulWidget {
  const V3BalanceCardPreview({super.key});

  @override
  State<V3BalanceCardPreview> createState() => _V3BalanceCardPreviewState();
}

class _V3BalanceCardPreviewState extends State<V3BalanceCardPreview> {
  Brightness _brightness = Brightness.light;
  bool _isVisible = false;
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
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: SegmentedButton<Brightness>(
                      key: const ValueKey('v3-balance-card-theme-toggle'),
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
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: V3BalanceCard(
                      label: 'Available balance',
                      amount: '10,000,000.00',
                      currency: 'THB',
                      isBalanceVisible: _isVisible,
                      onToggleVisibility: () {
                        setState(() => _isVisible = !_isVisible);
                        _recordAction(
                          _isVisible ? 'Show balance' : 'Hide balance',
                        );
                      },
                      visibilityIcon: V3LucideIcon(
                        _isVisible ? LucideIcons.eye : LucideIcons.eyeOff,
                        size: V3IconSize.medium,
                      ),
                      onInfoTap: () => _recordAction('Balance info'),
                      infoIcon: const V3LucideIcon(
                        LucideIcons.circleAlert,
                        size: V3IconSize.small,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          'Action: $_lastAction',
                          key: const ValueKey(
                            'v3-balance-card-action-feedback',
                          ),
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
