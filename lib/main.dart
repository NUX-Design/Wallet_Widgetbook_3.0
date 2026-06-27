import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/config/themes/base_theme.dart';
import 'package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart';
import 'package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart';
import 'package:mcp_test_app/widgets/announce/announcement.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:mcp_test_app/providers/theme_provider.dart';
import 'package:mcp_test_app/providers/locale_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LocaleProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  TextTheme _buildLocalizedTextTheme(Locale? locale, TextTheme baseTheme) {
    switch (locale?.languageCode) {
      case 'th':
        return GoogleFonts.notoSansThaiTextTheme(baseTheme);
      case 'my':
        return GoogleFonts.notoSansMyanmarTextTheme(baseTheme);
      default:
        return GoogleFonts.notoSansTextTheme(baseTheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, child) {
        return MaterialApp(
          onGenerateTitle: (context) {
            return AppLocalizations.of(context)!.settingTextVerAppWiWallet;
          },
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('zh'), // Chinese
            Locale('my'), // Myanmar
            Locale('ru'), // Russian
            Locale('th'), // Thai
          ],
          locale: localeProvider.locale,
          theme: ThemeData.from(
            colorScheme: BaseTheme.lightColorScheme,
            useMaterial3: true,
          ).copyWith(
            textTheme: _buildLocalizedTextTheme(
              localeProvider.locale,
              ThemeData.from(
                colorScheme: BaseTheme.lightColorScheme,
                useMaterial3: true,
              ).textTheme,
            ),
            scaffoldBackgroundColor: ThemeColors.get('light', 'fill/base/300'),
          ),
          darkTheme: ThemeData.from(
            colorScheme: BaseTheme.darkColorScheme,
            useMaterial3: true,
          ).copyWith(
            textTheme: _buildLocalizedTextTheme(
              localeProvider.locale,
              ThemeData.from(
                colorScheme: BaseTheme.darkColorScheme,
                useMaterial3: true,
              ).textTheme,
            ),
            scaffoldBackgroundColor: ThemeColors.get('dark', 'fill/base/300'),
          ),
          themeMode: themeProvider.themeMode,
          home: const HomePage(),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String _defaultAnnouncementMessage =
      'Your account has been verified successfully. All features are now fully accessible from 01/06/2022 at 8:00 AM (Thailand time).';

  static const String _myanmarAnnouncementMessage =
      'Wi Wallet မဟုတ္ေသာ အေကာင့္မ်ားမွ ေငြလႊဲျခင္းကို လက္ခံရရွိပါက ေငြလႊဲသည့္ပမာဏမွ 2.5%၊ အနည္းဆုံး 5 THB၊ အမ်ားဆုံး 15 THB ေကာက္ခံမည္ျဖစ္ပါသည္။';

  // Helper to build dropdown items with consistent style
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

  // Helper to find the current locale from the list of supported locales
  Locale _getCurrentLocale(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);
    for (var locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == currentLocale.languageCode) {
        return locale;
      }
    }
    return const Locale('en'); // Fallback to English
  }

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/300'),
      extendBody: true,
      bottomNavigationBar: NavigatorBar(),
      appBar: AppBar(
        toolbarHeight: 56.0,
        centerTitle: true,
        elevation: 0,
        titleSpacing: 0,
        title: Text(
          AppLocalizations.of(context)!.settingTextVerAppWiWallet,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ThemeColors.get(brightnessKey, 'text/base/600'),
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 0.0,
                vertical: 1.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Theme Toggle Section
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.get(brightnessKey, 'fill/base/100'),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: screenHeight * 0.25, // Responsive height
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.light_mode, size: 20),
                          const SizedBox(width: 8.0),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.settingValueMainMenuAppearLight,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: ThemeColors.get(
                                brightnessKey,
                                'text/base/600',
                              ),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          Consumer<ThemeProvider>(
                            builder: (context, themeProvider, _) {
                              return Switch(
                                value:
                                    themeProvider.themeMode == ThemeMode.dark,
                                onChanged:
                                    (value) => themeProvider.toggleTheme(),
                                thumbColor: WidgetStatePropertyAll(
                                  ThemeColors.get(
                                    brightnessKey,
                                    'fill/base/100',
                                  ),
                                ),
                                activeTrackColor: ThemeColors.get(
                                  brightnessKey,
                                  'success/400',
                                ),
                                inactiveTrackColor: ThemeColors.get(
                                  brightnessKey,
                                  'warning/400',
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8.0),
                          Text(
                            AppLocalizations.of(
                              context,
                            )!.settingValueMainMenuAppearDark,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              color: ThemeColors.get(
                                brightnessKey,
                                'text/base/600',
                              ),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          const Icon(Icons.dark_mode, size: 20),
                        ],
                      ),
                    ),
                  ),
                  // Spacing
                  const SizedBox(height: 8),
                  // Language Switcher Section
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: ThemeColors.get(brightnessKey, 'fill/base/100'),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: SizedBox(
                      height: 48,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Locale>(
                          value: _getCurrentLocale(context),
                          isExpanded: true,
                          icon: Icon(
                            Icons.language,
                            color: ThemeColors.get(
                              brightnessKey,
                              'text/base/600',
                            ),
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
                  ),

                  // Shortcut Menu Section
                  Container(
                    decoration: BoxDecoration(
                      color: ThemeColors.get(brightnessKey, 'fill/base/100'),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    height: screenHeight * 0.55, // Responsive height
                    child: Column(
                      children: [
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AnnouncementStack(
                            messages: [
                              Localizations.localeOf(context).languageCode ==
                                      'my'
                                  ? _myanmarAnnouncementMessage
                                  : _defaultAnnouncementMessage,
                              AppLocalizations.of(
                                context,
                              )!.homeAnnounceVerifyFaceToReceive(
                                '100.00',
                                'THB',
                              ),
                              'This is a very long announcement message that is intended to test the text truncation functionality of the widget. It should be long enough to exceed three lines when displayed on a standard mobile screen width. If it works correctly, you should see an ellipsis at the end of the third line.',
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: AspectRatio(
                            aspectRatio:
                                343 /
                                106, // Standard ratio based on design specs
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: ThemeColors.get(
                                  brightnessKey,
                                  'fill/base/200',
                                ),
                                borderRadius: BorderRadius.circular(16),
                                image: const DecorationImage(
                                  image: AssetImage(
                                    'lib/assets/images/Card_Banner.png',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ShortcutMenuItem(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )!.shortcutMenuHomeTransfer,
                              ),
                              const SizedBox(width: 56),
                              ShortcutMenuItem(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )!.shortcutMenuHomeWiCoin,
                              ),
                              const SizedBox(width: 56),
                              ShortcutMenuItem(
                                label:
                                    AppLocalizations.of(
                                      context,
                                    )!.shortcutMenuHomeBill,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
