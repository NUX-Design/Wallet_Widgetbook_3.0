import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/tab/horizontal_tabs.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => ThemeProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const PreviewHorizontalTabs(),
        );
      },
    );
  }
}

class PreviewHorizontalTabs extends StatefulWidget {
  const PreviewHorizontalTabs({super.key});

  @override
  State<PreviewHorizontalTabs> createState() => _PreviewHorizontalTabsState();
}

class _PreviewHorizontalTabsState extends State<PreviewHorizontalTabs> {
  int _selected2Tab = 0;
  int _selected3Tab = 0;

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/200'),
      appBar: AppBar(
        title: const Text('Horizontal Tabs Preview'),
        backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.light
                      ? Icons.dark_mode
                      : Icons.light_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: ThemeColors.get(brightnessKey, 'fill/base/100'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '2 Tabs',
                      style: TextStyle(
                        color: ThemeColors.get(brightnessKey, 'text/base/600'),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HorizontalTabs(
                      tabs: const [
                        HorizontalTabItem(label: 'General', showDot: true),
                        HorizontalTabItem(label: 'For You', showDot: true),
                      ],
                      selectedIndex: _selected2Tab,
                      onTabChanged: (i) => setState(() => _selected2Tab = i),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '3 Tabs',
                      style: TextStyle(
                        color: ThemeColors.get(brightnessKey, 'text/base/600'),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    HorizontalTabs(
                      tabs: const [
                        HorizontalTabItem(label: 'History'),
                        HorizontalTabItem(label: 'Info'),
                        HorizontalTabItem(label: 'Setting'),
                      ],
                      selectedIndex: _selected3Tab,
                      onTabChanged: (i) => setState(() => _selected3Tab = i),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
