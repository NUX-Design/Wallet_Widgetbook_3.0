import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mcp_test_app/config/themes/base_theme.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';

/// Default locales used across widget tests.
const List<Locale> kTestSupportedLocales = <Locale>[
  Locale('en'),
  Locale('th'),
  Locale('zh'),
  Locale('ru'),
  Locale('my'),
];

/// Theme mode shortcuts for test scenarios.
enum TestThemeVariant { light, dark }

/// Strategy for loading assets in tests.
enum TestAssetStrategy { realAssets, placeholderAssets }

ThemeData buildTestTheme(
  TestThemeVariant variant, {
  Locale? locale,
}) {
  // Keep widget tests deterministic and offline-friendly.
  GoogleFonts.config.allowRuntimeFetching = false;

  final brightness =
      variant == TestThemeVariant.light ? Brightness.light : Brightness.dark;
  final colorScheme =
      brightness == Brightness.light
          ? BaseTheme.lightColorScheme
          : BaseTheme.darkColorScheme;
  final baseTheme = ThemeData.from(colorScheme: colorScheme, useMaterial3: true);
  final textTheme = _buildLocalizedTextTheme(locale, baseTheme.textTheme);

  return baseTheme.copyWith(
    textTheme: textTheme,
    scaffoldBackgroundColor:
        brightness == Brightness.light
            ? ThemeColors.get('light', 'fill/base/300')
            : ThemeColors.get('dark', 'fill/base/300'),
  );
}

Widget buildTestApp({
  required Widget child,
  TestThemeVariant themeVariant = TestThemeVariant.light,
  Locale locale = const Locale('en'),
  Iterable<Locale> supportedLocales = kTestSupportedLocales,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  bool wrapWithScaffold = true,
  TestAssetStrategy assetStrategy = TestAssetStrategy.realAssets,
  AssetBundle? assetBundle,
}) {
  final effectiveAssetBundle =
      assetBundle ??
      (assetStrategy == TestAssetStrategy.placeholderAssets
          ? PlaceholderAssetBundle()
          : null);

  Widget app = MaterialApp(
    theme: buildTestTheme(TestThemeVariant.light, locale: locale),
    darkTheme: buildTestTheme(TestThemeVariant.dark, locale: locale),
    themeMode:
        themeVariant == TestThemeVariant.light
            ? ThemeMode.light
            : ThemeMode.dark,
    locale: locale,
    supportedLocales: supportedLocales.toList(growable: false),
    localizationsDelegates:
        localizationsDelegates?.toList(growable: false) ??
        AppLocalizations.localizationsDelegates,
    home: wrapWithScaffold ? Scaffold(body: child) : child,
  );

  if (effectiveAssetBundle != null) {
    app = DefaultAssetBundle(bundle: effectiveAssetBundle, child: app);
  }

  return app;
}

Future<void> pumpTestApp(
  WidgetTester tester,
  Widget child, {
  TestThemeVariant themeVariant = TestThemeVariant.light,
  Locale locale = const Locale('en'),
  Iterable<Locale> supportedLocales = kTestSupportedLocales,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  bool wrapWithScaffold = true,
  TestAssetStrategy assetStrategy = TestAssetStrategy.realAssets,
  AssetBundle? assetBundle,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      child: child,
      themeVariant: themeVariant,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: localizationsDelegates,
      wrapWithScaffold: wrapWithScaffold,
      assetStrategy: assetStrategy,
      assetBundle: assetBundle,
    ),
  );
}

Future<void> pumpModalBottomSheetHost(
  WidgetTester tester, {
  required Widget child,
  TestThemeVariant themeVariant = TestThemeVariant.light,
  Locale locale = const Locale('en'),
  Iterable<Locale> supportedLocales = kTestSupportedLocales,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  TestAssetStrategy assetStrategy = TestAssetStrategy.realAssets,
  AssetBundle? assetBundle,
}) async {
  await pumpTestApp(
    tester,
    child,
    themeVariant: themeVariant,
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegates,
    wrapWithScaffold: true,
    assetStrategy: assetStrategy,
    assetBundle: assetBundle,
  );
}

Future<void> pumpSnackBarHost(
  WidgetTester tester, {
  required Widget child,
  TestThemeVariant themeVariant = TestThemeVariant.light,
  Locale locale = const Locale('en'),
  Iterable<Locale> supportedLocales = kTestSupportedLocales,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  TestAssetStrategy assetStrategy = TestAssetStrategy.realAssets,
  AssetBundle? assetBundle,
}) async {
  await pumpTestApp(
    tester,
    child,
    themeVariant: themeVariant,
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegates,
    wrapWithScaffold: true,
    assetStrategy: assetStrategy,
    assetBundle: assetBundle,
  );
}

Future<void> pumpGoldenTestApp(
  WidgetTester tester, {
  required Widget child,
  Size surfaceSize = const Size(390, 844),
  double devicePixelRatio = 1.0,
  TestThemeVariant themeVariant = TestThemeVariant.light,
  Locale locale = const Locale('en'),
  Iterable<Locale> supportedLocales = kTestSupportedLocales,
  Iterable<LocalizationsDelegate<dynamic>>? localizationsDelegates,
  TestAssetStrategy assetStrategy = TestAssetStrategy.realAssets,
  AssetBundle? assetBundle,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = devicePixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await pumpTestApp(
    tester,
    child,
    themeVariant: themeVariant,
    locale: locale,
    supportedLocales: supportedLocales,
    localizationsDelegates: localizationsDelegates,
    wrapWithScaffold: true,
    assetStrategy: assetStrategy,
    assetBundle: assetBundle,
  );
}

Future<void> settleWidgetTester(
  WidgetTester tester, {
  Duration duration = const Duration(milliseconds: 16),
}) async {
  await tester.pumpAndSettle(duration);
}

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

/// Asset bundle that returns safe placeholder content for asset-heavy widget tests.
///
/// The bundle emits a minimal `AssetManifest.json` for the provided asset paths,
/// then serves simple SVG/PNG/Lottie content so widget tests can exercise
/// `SvgPicture.asset`, `Image.asset`, and `Lottie.asset` branches without
/// depending on production files.
class PlaceholderAssetBundle extends CachingAssetBundle {
  PlaceholderAssetBundle({this.assetPaths = const <String>[]});

  final List<String> assetPaths;

  static const String _placeholderSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"></svg>';
  static const String _placeholderLottie =
      '{"v":"5.7.4","fr":30,"ip":0,"op":30,"w":1,"h":1,"nm":"placeholder","ddd":0,"assets":[],"layers":[]}';
  static final Uint8List _placeholderPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO5V3YkAAAAASUVORK5CYII=',
  );

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.json') {
      return ByteData.view(
        Uint8List.fromList(utf8.encode(_manifestJson)).buffer,
      );
    }

    if (_isSvg(key) || _isLottie(key)) {
      return ByteData.view(
        Uint8List.fromList(utf8.encode(_placeholderSvgOrLottie(key))).buffer,
      );
    }

    if (_isRaster(key)) {
      return ByteData.view(_placeholderPng.buffer);
    }

    throw FlutterError('PlaceholderAssetBundle has no asset for "$key".');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key == 'AssetManifest.json') {
      return _manifestJson;
    }

    if (_isSvg(key) || _isLottie(key)) {
      return _placeholderSvgOrLottie(key);
    }

    if (_isRaster(key)) {
      throw FlutterError(
        'PlaceholderAssetBundle does not expose raster asset "$key" as a string. '
        'Use load() through Image.asset instead.',
      );
    }

    return super.loadString(key, cache: cache);
  }

  String get _manifestJson {
    final manifest = <String, List<String>>{
      for (final path in assetPaths) path: <String>[path],
    };
    return jsonEncode(manifest);
  }

  static bool _isSvg(String key) => key.toLowerCase().endsWith('.svg');

  static bool _isRaster(String key) =>
      key.toLowerCase().endsWith('.png') ||
      key.toLowerCase().endsWith('.jpg') ||
      key.toLowerCase().endsWith('.jpeg');

  static bool _isLottie(String key) => key.toLowerCase().endsWith('.json');

  static String _placeholderSvgOrLottie(String key) {
    return _isSvg(key) ? _placeholderSvg : _placeholderLottie;
  }
}
