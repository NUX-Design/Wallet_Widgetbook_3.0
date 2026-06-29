import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:mcp_test_app/widgets/loading/pre_loading.dart';

import '../../support/widget_test_harness.dart';

void main() {
  group('PreLoading', () {
    testWidgets('renders blur overlay and centered animation', (
      WidgetTester tester,
    ) async {
      final bundle = _RecordingAssetBundle(
        assetPaths: <String>[
          'lib/assets/lottie/wi_loader.json',
        ],
      );

      await pumpTestApp(
        tester,
        const SizedBox.expand(child: PreLoading()),
        wrapWithScaffold: false,
        assetStrategy: TestAssetStrategy.placeholderAssets,
        assetBundle: bundle,
      );

      await tester.pump();

      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(find.byType(Lottie), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);

      final backdropFilter = tester.widget<BackdropFilter>(
        find.byType(BackdropFilter),
      );
      final blur = backdropFilter.filter as ImageFilter;
      expect(blur, isNotNull);

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Container),
        ),
      );
      expect(container.color, const Color.fromRGBO(0, 0, 0, 0.5));

      final lottie = tester.widget<Lottie>(find.byType(Lottie));
      expect(lottie.width, 280);
      expect(lottie.height, 280);
      expect(lottie.fit, BoxFit.contain);
      expect(bundle.requestedKeys, contains('lib/assets/lottie/wi_loader.json'));
    });
  });
}

class _RecordingAssetBundle extends PlaceholderAssetBundle {
  _RecordingAssetBundle({required super.assetPaths});

  final List<String> requestedKeys = <String>[];

  @override
  Future<ByteData> load(String key) {
    requestedKeys.add(key);
    return super.load(key);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    requestedKeys.add(key);
    return super.loadString(key, cache: cache);
  }
}
