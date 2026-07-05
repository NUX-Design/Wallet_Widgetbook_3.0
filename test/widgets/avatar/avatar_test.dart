import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mcp_test_app/widgets/avatar/avatar.dart';

import '../../support/widget_test_harness.dart';

void main() {
  group('Avatar', () {
    testWidgets('renders fallback icon and status badges', (
      WidgetTester tester,
    ) async {
      await pumpTestApp(
        tester,
        const Avatar(
          name: 'New User',
          handle: '@new.user',
          status: AvatarStatus.danger,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/user-add-01.svg',
            'lib/assets/images/statusdanger.svg',
            'lib/assets/images/statuswarning.svg',
          ],
        ),
      );

      expect(find.text('New User'), findsOneWidget);
      expect(find.text('@new.user'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(CircleAvatar),
          matching: find.byType(SvgPicture),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is SvgPicture && widget.width == 18,
        ),
        findsOneWidget,
      );

      await pumpTestApp(
        tester,
        const Avatar(
          name: 'New User',
          handle: '@new.user',
          status: AvatarStatus.warning,
        ),
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: PlaceholderAssetBundle(
          assetPaths: <String>[
            'lib/assets/images/user-add-01.svg',
            'lib/assets/images/statusdanger.svg',
            'lib/assets/images/statuswarning.svg',
          ],
        ),
      );

      expect(
        find.byWidgetPredicate(
          (widget) => widget is SvgPicture && widget.width == 18,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'prefers network images over assets and respects loading state',
      (WidgetTester tester) async {
        await HttpOverrides.runZoned(() async {
          await pumpTestApp(
            tester,
            const Avatar(
              imageUrl: 'https://example.com/avatar.png',
              assetPath: 'lib/assets/images/avatar-demo.png',
              name: 'Tony Stark',
              handle: '@ironman',
              radius: 32,
            ),
            assetStrategy: TestAssetStrategy.placeholderAssets,
            assetBundle: PlaceholderAssetBundle(
              assetPaths: <String>[
                'lib/assets/images/avatar-demo.png',
                'lib/assets/images/user-add-01.svg',
                'lib/assets/lottie/wi_skeleton.json',
              ],
            ),
          );
        }, createHttpClient: (_) => _FakeHttpClient(_kPngBytes));

        final circleAvatar = tester.widget<CircleAvatar>(
          find.byType(CircleAvatar),
        );
        expect(circleAvatar.radius, 32);
        expect(circleAvatar.backgroundImage, isA<NetworkImage>());

        await pumpTestApp(
          tester,
          const Avatar(
            name: 'Loading User',
            handle: '@loading.user',
            isLoading: true,
          ),
          assetStrategy: TestAssetStrategy.placeholderAssets,
          assetBundle: PlaceholderAssetBundle(
            assetPaths: <String>[
              'lib/assets/images/user-add-01.svg',
              'lib/assets/lottie/wi_skeleton.json',
            ],
          ),
        );

        expect(find.byType(Lottie), findsWidgets);
        expect(find.byType(Opacity), findsWidgets);
      },
    );
  });
}

final Uint8List _kPngBytes = Uint8List.fromList(<int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x63,
  0x00,
  0x01,
  0x00,
  0x00,
  0x05,
  0x00,
  0x01,
  0x0D,
  0x0A,
  0x2D,
  0xB4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

class _FakeHttpClient implements HttpClient {
  _FakeHttpClient(this.bytes);

  final Uint8List bytes;

  @override
  bool autoUncompress = false;

  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return _FakeHttpClientRequest(bytes);
  }

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return _FakeHttpClientRequest(bytes);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientRequest implements HttpClientRequest {
  _FakeHttpClientRequest(this.bytes);

  final Uint8List bytes;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  Future<HttpClientResponse> close() async {
    return _FakeHttpClientResponse(bytes);
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpClientResponse extends StreamView<List<int>>
    implements HttpClientResponse {
  _FakeHttpClientResponse(Uint8List bytes)
    : _bytes = bytes,
      super(Stream<List<int>>.value(bytes));

  final Uint8List _bytes;

  @override
  int get statusCode => HttpStatus.ok;

  @override
  int get contentLength => _bytes.length;

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  HttpHeaders get headers => _FakeHttpHeaders();

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => 'OK';

  @override
  bool get isRedirect => false;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpHeaders implements HttpHeaders {
  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
