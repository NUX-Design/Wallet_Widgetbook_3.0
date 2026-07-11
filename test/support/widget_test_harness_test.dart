import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';

import 'widget_test_harness.dart';

void main() {
  testWidgets('buildTestApp wires theme, scaffold, and locale', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Theme.of(context).brightness == Brightness.dark
                    ? 'dark'
                    : 'light',
              ),
              Text(Localizations.localeOf(context).languageCode),
              Text(AppLocalizations.of(context)!.navigatorHome),
            ],
          );
        },
      ),
      themeVariant: TestThemeVariant.dark,
      locale: const Locale('th'),
    );

    expect(find.text('dark'), findsOneWidget);
    expect(find.text('th'), findsOneWidget);
    expect(find.text('หน้าหลัก'), findsOneWidget);
  });

  testWidgets('PlaceholderAssetBundle serves svg, png, and lottie content', (
    WidgetTester tester,
  ) async {
    final bundle = PlaceholderAssetBundle(
      assetPaths: <String>[
        'lib/assets/images/placeholder.svg',
        'lib/assets/images/placeholder.png',
        'lib/assets/lottie/placeholder.json',
      ],
    );

    await pumpTestApp(
      tester,
      const _AssetProbe(),
      assetStrategy: TestAssetStrategy.placeholderAssets,
      assetBundle: bundle,
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(Lottie), findsOneWidget);

    final binaryManifest =
        const StandardMessageCodec().decodeMessage(
              await bundle.load('AssetManifest.bin'),
            )
            as Map<Object?, Object?>;
    expect(binaryManifest['lib/assets/images/placeholder.png'], <Object?>[
      <Object?, Object?>{'asset': 'lib/assets/images/placeholder.png'},
    ]);

    expect(
      await bundle.loadString('AssetManifest.json'),
      contains('lib/assets/images/placeholder.svg'),
    );
    expect(
      await bundle.loadString('lib/assets/images/placeholder.svg'),
      allOf(startsWith('<svg'), contains('</svg>')),
    );
    final lottieJson =
        jsonDecode(
              await bundle.loadString('lib/assets/lottie/placeholder.json'),
            )
            as Map<String, dynamic>;
    expect(lottieJson['v'], '5.7.4');
    expect(lottieJson['layers'], isEmpty);
  });

  testWidgets('Snack bar host can show a snackbar', (
    WidgetTester tester,
  ) async {
    await pumpSnackBarHost(
      tester,
      child: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('hello snack bar')),
                );
              },
              child: const Text('show'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('show'));
    await tester.pump();
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('hello snack bar'), findsOneWidget);
  });

  testWidgets('Modal bottom sheet host can open a sheet', (
    WidgetTester tester,
  ) async {
    await pumpModalBottomSheetHost(
      tester,
      child: Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  builder: (context) {
                    return const SizedBox(
                      height: 120,
                      child: Center(child: Text('bottom sheet')),
                    );
                  },
                );
              },
              child: const Text('open sheet'),
            ),
          );
        },
      ),
    );

    await tester.tap(find.text('open sheet'));
    await tester.pumpAndSettle();
    expect(find.text('bottom sheet'), findsOneWidget);
  });

  testWidgets('settleWidgetTester completes transient animation frames', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(tester, const _AnimatedProbe(), wrapWithScaffold: false);

    await settleWidgetTester(tester);
    expect(find.text('animated'), findsOneWidget);
  });

  testWidgets('pumpGoldenTestApp fixes the viewport for snapshots', (
    WidgetTester tester,
  ) async {
    await pumpGoldenTestApp(
      tester,
      child: const _SizeProbe(),
      surfaceSize: const Size(320, 640),
      devicePixelRatio: 2.0,
    );

    expect(tester.view.physicalSize, const Size(320, 640));
    expect(tester.view.devicePixelRatio, 2.0);
  });
}

class _AssetProbe extends StatelessWidget {
  const _AssetProbe();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset('lib/assets/images/placeholder.svg'),
        Image.asset('lib/assets/images/placeholder.png'),
        Lottie.asset('lib/assets/lottie/placeholder.json'),
      ],
    );
  }
}

class _AnimatedProbe extends StatefulWidget {
  const _AnimatedProbe();

  @override
  State<_AnimatedProbe> createState() => _AnimatedProbeState();
}

class _AnimatedProbeState extends State<_AnimatedProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 100),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return const Text('animated');
      },
    );
  }
}

class _SizeProbe extends StatelessWidget {
  const _SizeProbe();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(width: 100, height: 100);
  }
}
