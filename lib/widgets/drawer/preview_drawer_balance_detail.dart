import 'package:flutter/material.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_balance_detail.dart';
import 'package:provider/provider.dart';

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
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.themeMode,
          home: const DrawerBalanceDetailPreview(),
        );
      },
    );
  }
}

class DrawerBalanceDetailPreview extends StatelessWidget {
  const DrawerBalanceDetailPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final brightnessKey =
        Theme.of(context).brightness == Brightness.light ? 'light' : 'dark';

    return Scaffold(
      backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
      appBar: AppBar(
        title: const Text('Drawer Balance Detail'),
        backgroundColor: ThemeColors.get(brightnessKey, 'fill/base/100'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) {
                  return FilledButton.tonal(
                    onPressed: themeProvider.toggleTheme,
                    child: Text(
                      themeProvider.themeMode == ThemeMode.dark
                          ? 'Light'
                          : 'Dark',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed:
              () => DrawerBalanceDetail.show(
                context,
                totalBalanceAmount: '100,000,000,000.00',
                totalBalanceLabel: 'Total Balance',
                currency: 'THB',
                holdAmountLabel: 'Hold Amount',
                holdAmountValue: '5,030.20',
                ledgerBalanceLabel: 'Ledger Balance',
                ledgerBalanceValue: '15,030.20',
                warningText:
                    '*Hold Amount means they aren\'t immediately available for use. Please contact our customer support team for more details and to process the next steps.',
                buttonText: 'View History',
              ),
          child: const Text('Show Balance Detail Drawer'),
        ),
      ),
    );
  }
}
