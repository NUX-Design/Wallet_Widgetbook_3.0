import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/widgets/receipt/receipt_image_component.dart';

void main() {
  const googleFontsAssetManifest = <String, List<String>>{
    'google_fonts/NotoSansThai-Regular.ttf': <String>[
      'google_fonts/NotoSansThai-Regular.ttf',
    ],
    'google_fonts/NotoSansThai-Medium.ttf': <String>[
      'google_fonts/NotoSansThai-Medium.ttf',
    ],
    'google_fonts/NotoSansThai-SemiBold.ttf': <String>[
      'google_fonts/NotoSansThai-SemiBold.ttf',
    ],
    'google_fonts/NotoSansThai-Bold.ttf': <String>[
      'google_fonts/NotoSansThai-Bold.ttf',
    ],
  };

  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final fontBytes = _testFontFile().readAsBytesSync();

  setUp(() {
    binding.defaultBinaryMessenger.setMockMessageHandler('flutter/assets', (
      ByteData? message,
    ) async {
      final requestedKey = utf8.decode(message!.buffer.asUint8List());
      if (requestedKey == 'AssetManifest.json') {
        return ByteData.view(
          Uint8List.fromList(
            utf8.encode(jsonEncode(googleFontsAssetManifest)),
          ).buffer,
        );
      }

      if (requestedKey.startsWith('google_fonts/NotoSansThai-') &&
          (requestedKey.endsWith('.ttf') || requestedKey.endsWith('.otf'))) {
        return ByteData.view(fontBytes.buffer);
      }

      return null;
    });
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/assets',
      null,
    );
  });

  group('ReceiptImageComponent', () {
    testWidgets('matches the golden snapshot', (WidgetTester tester) async {
      await _pumpReceiptImageApp(
        tester,
        child: const _ReceiptImageGoldenProbe(),
        assetPaths: const <String>[
          'lib/assets/images/receipt/check.svg',
          'lib/assets/images/brands=SCB.svg',
          'lib/assets/images/receipt/qr.png',
          'lib/assets/images/receipt/receipt_background.svg',
          'lib/assets/images/receipt/wiwallet-logo.svg',
        ],
      );

      await tester.pump();

      await expectLater(
        find.byType(_ReceiptImageGoldenProbe),
        matchesGoldenFile('goldens/receipt_image_component_light.png'),
      );
    }, skip: !Platform.isMacOS);

    testWidgets(
      'renders header logo fallback, background fallback, and detail rows',
      (WidgetTester tester) async {
        await _pumpReceiptImageApp(
          tester,
          child: const _ReceiptImageFallbackProbe(),
          assetPaths: const <String>[],
        );

        await tester.pump();

        expect(find.text('Payment'), findsOneWidget);
        expect(find.text('wi wallet'), findsOneWidget);
        expect(find.text('Date&Time:'), findsOneWidget);
        expect(find.text('Transaction ID:'), findsOneWidget);
        expect(find.text('Merchant Ref ID:'), findsOneWidget);
        expect(find.text('Biller ID:'), findsOneWidget);
        expect(find.text('Ref 1:'), findsOneWidget);
        expect(find.text('Ref 2:'), findsNothing);
        expect(find.byType(CustomPaint), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('keeps long text within max lines', (
      WidgetTester tester,
    ) async {
      const longMerchantName =
          'Merchant with an intentionally long display name that should truncate';

      await _pumpReceiptImageApp(
        tester,
        child: const _ReceiptImageLongTextProbe(merchantName: longMerchantName),
        assetPaths: const <String>[],
        surfaceSize: const Size(320, 1200),
      );

      await tester.pump();

      final merchantParagraph = tester.renderObject<RenderParagraph>(
        find.text(longMerchantName),
      );
      expect(merchantParagraph.didExceedMaxLines, isTrue);
      expect(tester.takeException(), isNull);
    });
  });
}

File _testFontFile() {
  final systemFont = File('/System/Library/Fonts/SFNS.ttf');
  if (systemFont.existsSync()) return systemFont;

  final dartExecutable = File(Platform.resolvedExecutable);
  final flutterRoot = dartExecutable.parent.parent.parent.parent.parent;
  return File(
    '${flutterRoot.path}/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
  );
}

Future<void> _pumpReceiptImageApp(
  WidgetTester tester, {
  required Widget child,
  required List<String> assetPaths,
  Size surfaceSize = const Size(390, 1200),
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _ReceiptAssetBundle(assetPaths: assetPaths),
      child: MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    ),
  );
}

class _ReceiptImageGoldenProbe extends StatelessWidget {
  const _ReceiptImageGoldenProbe();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 343,
        child: ReceiptImageComponent(
          amount: '500,000,000.00 THB',
          fee: 'Fees 5.00 THB',
          senderName: 'Victor Von Doom',
          senderAccount: 'x-1234',
          merchantName: 'Merchant 1',
          dateTime: '2025-10-06 12:00:53',
          transactionId: 'WP12345678901234567890',
          merchantRefId: 'WP12345678901234567890',
          billerId: 'WP12345678901234567890',
          ref1: 'WP12345678901234567890',
          ref2: 'WP12345678901234567891',
          ref3: 'WP12345678901234567892',
          footerNoteOne:
              'Please verify the information and keep the slip for evidence.',
          footerNoteTwo:
              'Customer service contact 02-026-6679 operates 24 hours daily.',
          transactionDetailRowCount: 7,
        ),
      ),
    );
  }
}

class _ReceiptImageFallbackProbe extends StatelessWidget {
  const _ReceiptImageFallbackProbe();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 343,
        child: ReceiptImageComponent(
          amount: '500,000,000.00 THB',
          fee: 'Fees 5.00 THB',
          senderName: 'Victor Von Doom',
          senderAccount: 'x-1234',
          merchantName: 'Merchant 1',
          dateTime: '2025-10-06 12:00:53',
          transactionId: 'WP12345678901234567890',
          merchantRefId: 'WP12345678901234567890',
          billerId: 'WP12345678901234567890',
          ref1: 'WP12345678901234567890',
          ref2: 'WP12345678901234567891',
          ref3: 'WP12345678901234567892',
          footerNoteOne:
              'Please verify the information and keep the slip for evidence.',
          footerNoteTwo:
              'Customer service contact 02-026-6679 operates 24 hours daily.',
          transactionDetailRowCount: 5,
          senderLogoAssetPath: null,
          qrAssetPath: null,
          backgroundSvgAssetPath: null,
          backgroundImageUrl: null,
          headerLogoAssetPath: null,
        ),
      ),
    );
  }
}

class _ReceiptImageLongTextProbe extends StatelessWidget {
  const _ReceiptImageLongTextProbe({required this.merchantName});

  final String merchantName;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 280,
        child: ReceiptImageComponent(
          amount: '500,000,000.00 THB',
          fee: 'Fees 5.00 THB',
          senderName:
              'Victor Von Doom with an intentionally long sender name for truncation',
          senderAccount: 'x-1234-5678-9012-3456-7890-1234-5678-9012-3456',
          merchantName: merchantName,
          dateTime: '2025-10-06 12:00:53',
          transactionId:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          merchantRefId:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          billerId:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          ref1:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          ref2:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          ref3:
              'WP12345678901234567890-WP12345678901234567890-WP12345678901234567890',
          footerNoteOne:
              'Please verify the information and keep the slip for evidence.',
          footerNoteTwo:
              'Customer service contact 02-026-6679 operates 24 hours daily.',
          transactionDetailRowCount: 7,
          senderLogoAssetPath: null,
          qrAssetPath: null,
          backgroundSvgAssetPath: null,
          backgroundImageUrl: null,
          headerLogoAssetPath: null,
        ),
      ),
    );
  }
}

class _ReceiptAssetBundle extends CachingAssetBundle {
  _ReceiptAssetBundle({required this.assetPaths});

  final List<String> assetPaths;

  @override
  Future<ByteData> load(String key) async {
    if (_isRegisteredAsset(key)) {
      return ByteData.view(File(key).readAsBytesSync().buffer);
    }

    if (key == 'AssetManifest.json') {
      return ByteData.view(
        Uint8List.fromList(utf8.encode(_manifestJson)).buffer,
      );
    }

    throw FlutterError('No asset registered for "$key".');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (_isRegisteredAsset(key)) {
      return File(key).readAsStringSync();
    }

    if (key == 'AssetManifest.json') {
      return _manifestJson;
    }

    return super.loadString(key, cache: cache);
  }

  @override
  Future<T> loadStructuredBinaryData<T>(
    String key,
    FutureOr<T> Function(ByteData data) parser,
  ) {
    if (key == 'AssetManifest.bin') {
      final manifestData =
          const StandardMessageCodec().encodeMessage(
            <String, List<Map<String, dynamic>>>{
              for (final path in assetPaths)
                path: <Map<String, dynamic>>[
                  <String, dynamic>{'asset': path},
                ],
            },
          )!;
      return Future<T>.value(parser(manifestData));
    }

    return super.loadStructuredBinaryData<T>(key, parser);
  }

  bool _isRegisteredAsset(String key) => assetPaths.contains(key);

  String get _manifestJson {
    return jsonEncode({
      for (final path in assetPaths) path: <String>[path],
    });
  }
}
