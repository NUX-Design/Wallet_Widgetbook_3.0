import 'package:flutter/material.dart';
import '../../../config/themes/v3/v3_theme_scope.dart';
import 'v3_notifications.dart';

void main() => runApp(const V3NotificationsPreviewApp());

class V3NotificationsPreviewApp extends StatelessWidget {
  const V3NotificationsPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3NotificationsPreview(),
    );
  }
}

class V3NotificationsPreview extends StatefulWidget {
  const V3NotificationsPreview({super.key});

  @override
  State<V3NotificationsPreview> createState() => _V3NotificationsPreviewState();
}

class _V3NotificationsPreviewState extends State<V3NotificationsPreview> {
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
            body: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Brightness>(
                    key: const ValueKey('v3-notifications-theme-toggle'),
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
                  const SizedBox(height: 24),
                  _NotificationStateLabel(
                    label: 'Unread',
                    color: colors.contentPrimary,
                  ),
                  const SizedBox(height: 8),
                  V3Notifications(
                    state: V3NotificationState.unread,
                    title: 'Top-up successful',
                    message: '1,000.00 THB successfully added to your wallet',
                    timestamp: '2026-05-12 00:00',
                    onPressed: () => _recordAction('Unread notification'),
                  ),
                  const SizedBox(height: 24),
                  _NotificationStateLabel(
                    label: 'Read',
                    color: colors.contentSecondary,
                  ),
                  const SizedBox(height: 8),
                  V3Notifications(
                    state: V3NotificationState.read,
                    title: 'Top-up successful',
                    message: '1,000.00 THB successfully added to your wallet',
                    timestamp: '2026-05-12 00:00',
                    onPressed: () => _recordAction('Read notification'),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Action: $_lastAction',
                      key: const ValueKey('v3-notifications-action-feedback'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colors.contentPrimary,
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

class _NotificationStateLabel extends StatelessWidget {
  const _NotificationStateLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
    );
  }
}
