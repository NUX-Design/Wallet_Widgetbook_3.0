import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/config/themes/base_theme.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_country_code.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
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
          theme: ThemeData.from(
            colorScheme: BaseTheme.lightColorScheme,
            useMaterial3: true,
          ).copyWith(
            scaffoldBackgroundColor: ThemeColors.get('light', 'fill/base/300'),
          ),
          darkTheme: ThemeData.from(
            colorScheme: BaseTheme.darkColorScheme,
            useMaterial3: true,
          ).copyWith(
            scaffoldBackgroundColor: ThemeColors.get('dark', 'fill/base/300'),
          ),
          themeMode: themeProvider.themeMode,
          home: const PreviewDrawerCountryCode(),
        );
      },
    );
  }
}

class PreviewDrawerCountryCode extends StatelessWidget {
  const PreviewDrawerCountryCode({super.key});

  static final List<CountryCode> _mockCountries = [
    CountryCode(name: 'Afghanistan', code: '+93', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Albania', code: '+355', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Algeria', code: '+213', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Argentina', code: '+54', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Australia', code: '+61', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Austria', code: '+43', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Bangladesh', code: '+880', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Belgium', code: '+32', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Brazil', code: '+55', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Cambodia', code: '+855', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Canada', code: '+1', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'China', code: '+86', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Denmark', code: '+45', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Egypt', code: '+20', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Finland', code: '+358', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'France', code: '+33', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Germany', code: '+49', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Greece', code: '+30', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Hong Kong', code: '+852', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'India', code: '+91', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Indonesia', code: '+62', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Ireland', code: '+353', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Italy', code: '+39', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Japan', code: '+81', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Laos', code: '+856', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Malaysia', code: '+60', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Mexico', code: '+52', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Myanmar', code: '+95', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Netherlands', code: '+31', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'New Zealand', code: '+64', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Norway', code: '+47', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Pakistan', code: '+92', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Philippines', code: '+63', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Poland', code: '+48', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Portugal', code: '+351', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Russia', code: '+7', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Saudi Arabia', code: '+966', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Singapore', code: '+65', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'South Africa', code: '+27', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'South Korea', code: '+82', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Spain', code: '+34', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Sweden', code: '+46', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Switzerland', code: '+41', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Taiwan', code: '+886', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Thailand', code: '+66', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Turkey', code: '+90', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'United Arab Emirates', code: '+971', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'United Kingdom', code: '+44', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'United States', code: '+1', flagAsset: 'lib/assets/images/flag_th.svg'),
    CountryCode(name: 'Vietnam', code: '+84', flagAsset: 'lib/assets/images/flag_th.svg'),
  ];

  @override
  Widget build(BuildContext context) {
    final brightnessKey = Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    
    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/300'),
      appBar: AppBar(
        title: const Text('Country Code Drawer'),
        backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  DrawerCountryCode.show(
                    context,
                    title: 'Mobile Number',
                    countries: _mockCountries,
                    onCountrySelected: (country) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selected: ${country.name} ${country.code}')),
                      );
                    },
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  backgroundColor: ThemeColors.get(brightnessKey, 'primary/400'),
                  foregroundColor: ThemeColors.get(brightnessKey, 'fill/contrast/600'),
                ),
                child: const Text('Show Country Code Drawer'),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap the button to open the drawer',
                style: TextStyle(
                  color: ThemeColors.get(brightnessKey, 'text/base/600'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
