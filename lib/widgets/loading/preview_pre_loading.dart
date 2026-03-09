import 'package:flutter/material.dart';
import 'package:mcp_test_app/widgets/loading/pre_loading.dart';
import 'package:mcp_test_app/widgets/item_list/item_list.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:provider/provider.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/providers/theme_provider.dart';
import 'package:mcp_test_app/providers/locale_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
      ],
      child: const PreviewPreLoadingApp(),
    ),
  );
}

class PreviewPreLoadingApp extends StatelessWidget {
  const PreviewPreLoadingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LocaleProvider>(
      builder: (context, themeProvider, localeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: localeProvider.locale,
          theme: ThemeData.light().copyWith(
            textTheme:
                localeProvider.locale?.languageCode == 'th'
                    ? GoogleFonts.notoSansThaiTextTheme()
                    : GoogleFonts.notoSansTextTheme(),
          ),
          darkTheme: ThemeData.dark().copyWith(
            textTheme:
                localeProvider.locale?.languageCode == 'th'
                    ? GoogleFonts.notoSansThaiTextTheme()
                    : GoogleFonts.notoSansTextTheme(),
          ),
          themeMode: themeProvider.themeMode,
          home: const PreviewPreLoadingPage(),
        );
      },
    );
  }
}

class PreviewPreLoadingPage extends StatefulWidget {
  const PreviewPreLoadingPage({super.key});

  @override
  State<PreviewPreLoadingPage> createState() => _PreviewPreLoadingPageState();
}

class _PreviewPreLoadingPageState extends State<PreviewPreLoadingPage> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';
    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
      appBar: AppBar(
        title: Text(
          'PreLoading Preview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: ThemeColors.get(brightnessKey, 'text/base/600'),
            fontSize: 20.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return IconButton(
                icon: Icon(
                  themeProvider.themeMode == ThemeMode.dark
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  color: ThemeColors.get(brightnessKey, 'text/base/600'),
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Content to demonstrate blur
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 20,
            itemBuilder: (context, index) {
              final isNegative = index % 2 == 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ItemList(
                  type:
                      isNegative
                          ? ItemListType.transactionOut
                          : ItemListType.transactionIn,
                  title:
                      isNegative
                          ? 'Victor Von Doom ${index + 1}'
                          : 'Transfer from ${index + 1}',
                  subtitle: '2025-10-06 12:00:53',
                  amount: isNegative ? '-50,000.00 THB' : '+50,000.00 THB',
                  amountColor: ThemeColors.get(
                    brightnessKey,
                    isNegative ? 'text/base/danger' : 'text/base/success',
                  ),
                  onTap: () {},
                ),
              );
            },
          ),

          // PreLoading Overlay
          if (_isLoading) const PreLoading(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isLoading = !_isLoading;
          });
        },
        child: Icon(_isLoading ? Icons.stop : Icons.play_arrow),
      ),
    );
  }
}
