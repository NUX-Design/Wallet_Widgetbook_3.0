import 'package:flutter/material.dart';

import '../../../config/themes/v3/v3_theme_scope.dart';
import 'v3_currency_card.dart';

void main() => runApp(const V3CurrencyCardPreviewApp());

class V3CurrencyCardPreviewApp extends StatelessWidget {
  const V3CurrencyCardPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: V3CurrencyCardPreview(),
    );
  }
}

/// Standalone Light/Dark and variant preview for [V3CurrencyCard].
class V3CurrencyCardPreview extends StatefulWidget {
  const V3CurrencyCardPreview({super.key});

  @override
  State<V3CurrencyCardPreview> createState() => _V3CurrencyCardPreviewState();
}

class _V3CurrencyCardPreviewState extends State<V3CurrencyCardPreview> {
  Brightness _brightness = Brightness.light;
  CurrencyCardVariant _variant = CurrencyCardVariant.show;
  int _selectedCurrency = 0;
  String _statusText = 'Selected currency: GBP';

  static const _currencies = [
    (flag: '🇬🇧', code: 'GBP', integer: '9,999', decimal: '.99'),
    (flag: '🇺🇸', code: 'USD', integer: '12,500', decimal: '.00'),
    (flag: '🇨🇳', code: 'CNY', integer: '1,250,000', decimal: ''),
    (flag: '🇪🇺', code: 'EUR', integer: '8,750', decimal: '.50'),
  ];

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
                    'Currency Card',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<Brightness>(
                    key: const ValueKey('v3-currency-card-theme-toggle'),
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
                  const SizedBox(height: 16),
                  SegmentedButton<CurrencyCardVariant>(
                    key: const ValueKey('v3-currency-card-variant-toggle'),
                    segments: const [
                      ButtonSegment(
                        value: CurrencyCardVariant.show,
                        label: Text('Show'),
                      ),
                      ButtonSegment(
                        value: CurrencyCardVariant.hide,
                        label: Text('Hide'),
                      ),
                      ButtonSegment(
                        value: CurrencyCardVariant.error,
                        label: Text('Error'),
                      ),
                    ],
                    selected: {_variant},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() => _variant = selection.single);
                    },
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: _buildCurrencyCard(
                      _currencies[_selectedCurrency],
                      key: const ValueKey('v3-currency-card-main'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      _statusText,
                      style: TextStyle(
                        color: colors.contentSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Multiple currencies',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: colors.contentPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var index = 0; index < _currencies.length; index++)
                        _buildCurrencyCard(
                          _currencies[index],
                          onTap: () => _handleCurrencyTap(index),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleCurrencyTap(int index) {
    setState(() {
      _selectedCurrency = index;
      _statusText = 'Tapped currency: ${_currencies[index].code}';
    });
  }

  V3CurrencyCard _buildCurrencyCard(
    ({String flag, String code, String integer, String decimal}) currency, {
    Key? key,
    VoidCallback? onTap,
  }) {
    return V3CurrencyCard(
      key: key,
      flag: currency.flag,
      currencyCode: currency.code,
      integerPart: currency.integer,
      decimalPart: currency.decimal,
      variant: _variant,
      onTap: onTap,
    );
  }
}
