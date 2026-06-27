import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'announcement.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }
}

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    notifyListeners();
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const AnnouncementPreview(),
        );
      },
    );
  }
}

class AnnouncementPreview extends StatefulWidget {
  const AnnouncementPreview({super.key});

  @override
  State<AnnouncementPreview> createState() => _AnnouncementPreviewState();
}

class _AnnouncementPreviewState extends State<AnnouncementPreview> {
  static const String _defaultAnnouncementMessage =
      'Your account has been verified successfully. All features are now fully accessible from 01/06/2022 at 8:00 AM (Thailand time).';

  static const String _myanmarAnnouncementMessage =
      'Wi Wallet မဟုတ္ေသာ အေကာင့္မ်ားမွ ေငြလႊဲျခင္းကို လက္ခံရရွိပါက ေငြလႊဲသည့္ပမာဏမွ 2.5%၊ အနည္းဆုံး 5 THB၊ အမ်ားဆုံး 15 THB ေကာက္ခံမည္ျဖစ္ပါသည္။';

  late List<String> _messages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messages = [
      Localizations.localeOf(context).languageCode == 'my'
          ? _myanmarAnnouncementMessage
          : _defaultAnnouncementMessage,
      AppLocalizations.of(
        context,
      )!.homeAnnounceVerifyFaceToReceive('100.00', 'THB'),
      'This is a very long announcement message that is intended to test the text truncation functionality of the widget. It should be long enough to exceed three lines when displayed on a standard mobile screen width. If it works correctly, you should see an ellipsis at the end of the third line.',
    ];
  }

  void _updateMessages() {
    setState(() {
      _messages = [..._messages.sublist(1), _messages[0]];
    });
  }

  DropdownMenuItem<Locale> _buildDropdownItem(
    BuildContext context,
    Locale locale,
    String text,
    String brightnessKey,
  ) {
    return DropdownMenuItem(
      value: locale,
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: ThemeColors.get(brightnessKey, 'text/base/600'),
        ),
      ),
    );
  }

  Locale _getCurrentLocale(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    for (var locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == currentLocale.languageCode) {
        return locale;
      }
    }
    return const Locale('en');
  }

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
      appBar: AppBar(
        title: const Text('Announcement Preview'),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: ThemeColors.get(brightnessKey, 'fill/base/100'),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<Locale>(
                    value: _getCurrentLocale(context),
                    isExpanded: true,
                    icon: Icon(
                      Icons.language,
                      color: ThemeColors.get(brightnessKey, 'text/base/600'),
                    ),
                    dropdownColor: ThemeColors.get(
                      brightnessKey,
                      'fill/base/200',
                    ),
                    items: [
                      _buildDropdownItem(
                        context,
                        const Locale('en'),
                        'English',
                        brightnessKey,
                      ),
                      _buildDropdownItem(
                        context,
                        const Locale('th'),
                        'ภาษาไทย',
                        brightnessKey,
                      ),
                      _buildDropdownItem(
                        context,
                        const Locale('zh'),
                        '中文',
                        brightnessKey,
                      ),
                      _buildDropdownItem(
                        context,
                        const Locale('ru'),
                        'Русский',
                        brightnessKey,
                      ),
                      _buildDropdownItem(
                        context,
                        const Locale('my'),
                        'မြန်မာ',
                        brightnessKey,
                      ),
                    ],
                    onChanged: (Locale? newLocale) {
                      if (newLocale != null) {
                        Provider.of<LocaleProvider>(
                          context,
                          listen: false,
                        ).setLocale(newLocale);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
              AnnouncementStack(messages: _messages, onClose: _updateMessages),
            ],
          ),
        ),
      ),
    );
  }
}
