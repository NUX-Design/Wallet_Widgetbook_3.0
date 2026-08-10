import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import 'v3_profile_header.dart';

void main() => runApp(const V3ProfileHeaderPreviewApp());

class V3ProfileHeaderPreviewApp extends StatelessWidget {
  const V3ProfileHeaderPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3ProfileHeaderPreview(),
    );
  }
}

class V3ProfileHeaderPreview extends StatefulWidget {
  const V3ProfileHeaderPreview({super.key});

  @override
  State<V3ProfileHeaderPreview> createState() => _V3ProfileHeaderPreviewState();
}

class _V3ProfileHeaderPreviewState extends State<V3ProfileHeaderPreview> {
  Brightness _brightness = Brightness.light;
  int _notificationPresses = 0;
  String _lastNotificationAction = 'None';

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: SegmentedButton<Brightness>(
                        key: const ValueKey('v3-profile-header-theme-toggle'),
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
                    const SizedBox(height: 24),
                    _section(
                      'Default · Success',
                      V3ProfileHeader(
                        key: const ValueKey(
                          'v3-profile-header-preview-default',
                        ),
                        userName: 'Cameron Brooklyn Williamson',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () =>
                                _handleNotificationPressed('Default · Success'),
                      ),
                    ),
                    _section(
                      'Default · Pending',
                      V3ProfileHeader(
                        status: V3ProfileHeaderStatus.pending,
                        userName: 'Amelia Chen',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () =>
                                _handleNotificationPressed('Default · Pending'),
                      ),
                    ),
                    _section(
                      'Default · Error',
                      V3ProfileHeader(
                        status: V3ProfileHeaderStatus.error,
                        userName: 'Jordan Vega',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () => _handleNotificationPressed('Default · Error'),
                      ),
                    ),
                    _section(
                      'Scrolled · Balance visible',
                      V3ProfileHeader(
                        layoutState: V3ProfileHeaderLayoutState.scrolled,
                        balanceVisibility:
                            V3ProfileHeaderBalanceVisibility.visible,
                        userName: 'Cameron Brooklyn Williamson',
                        balanceAmount: '9,999.99 THB',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () => _handleNotificationPressed(
                              'Scrolled · Balance visible',
                            ),
                      ),
                    ),
                    _section(
                      'Scrolled · Balance obscured',
                      V3ProfileHeader(
                        layoutState: V3ProfileHeaderLayoutState.scrolled,
                        balanceVisibility:
                            V3ProfileHeaderBalanceVisibility.obscured,
                        status: V3ProfileHeaderStatus.error,
                        userName: 'Cameron Brooklyn Williamson',
                        balanceAmount: '9,999.99 THB',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () => _handleNotificationPressed(
                              'Scrolled · Balance obscured',
                            ),
                      ),
                    ),
                    _section(
                      'Scrolled · No balance row',
                      V3ProfileHeader(
                        layoutState: V3ProfileHeaderLayoutState.scrolled,
                        userName: 'Cameron Brooklyn Williamson',
                        notificationSemanticLabel: 'Notifications',
                        onNotificationPressed:
                            () => _handleNotificationPressed(
                              'Scrolled · No balance row',
                            ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Notification action: $_lastNotificationAction '
                        '($_notificationPresses)',
                        key: const ValueKey(
                          'v3-profile-header-preview-notification-feedback',
                        ),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: colors.contentPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleNotificationPressed(String variantLabel) {
    setState(() {
      _notificationPresses++;
      _lastNotificationAction = variantLabel;
    });
  }

  Widget _section(String label, Widget child) {
    return Builder(
      builder: (context) {
        final colors = V3ThemeScope.colorsOf(context);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(
                  label,
                  key: const ValueKey(
                    'v3-profile-header-preview-section-label',
                  ),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.contentSecondary,
                  ),
                ),
              ),
              child,
              const SizedBox(height: 16),
              Divider(
                key: const ValueKey('v3-profile-header-preview-divider'),
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: colors.borderSecondary,
              ),
            ],
          ),
        );
      },
    );
  }
}
