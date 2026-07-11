import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/widgets/visa/visa_card.dart';

void main() {
  group('VisaCard', () {
    testWidgets('matches the light-theme golden snapshot', (
      WidgetTester tester,
    ) async {
      await _pumpVisaCardGoldenApp(
        tester,
        child: const _VisaCardGoldenProbe(),
        surfaceSize: const Size(375, 220),
        themeMode: ThemeMode.light,
      );

      await tester.pump();

      await expectLater(
        find.byType(_VisaCardGoldenProbe),
        matchesGoldenFile('goldens/visa_card_light.png'),
      );
    }, skip: !Platform.isMacOS);

    testWidgets('matches the dark-theme golden snapshot', (
      WidgetTester tester,
    ) async {
      await _pumpVisaCardGoldenApp(
        tester,
        child: const _VisaCardGoldenProbe(),
        surfaceSize: const Size(375, 220),
        themeMode: ThemeMode.dark,
      );

      await tester.pump();

      await expectLater(
        find.byType(_VisaCardGoldenProbe),
        matchesGoldenFile('goldens/visa_card_dark.png'),
      );
    }, skip: !Platform.isMacOS);

    testWidgets(
      'renders the logo, expiry date, masked number, and gradient card',
      (WidgetTester tester) async {
        await _pumpVisaCardGoldenApp(
          tester,
          child: const _VisaCardGoldenProbe(),
          surfaceSize: const Size(375, 220),
          themeMode: ThemeMode.light,
        );

        await tester.pump();

        final cardContainer = tester.widget<Container>(
          find.byWidgetPredicate(
            (widget) =>
                widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).gradient is LinearGradient,
          ),
        );

        final decoration = cardContainer.decoration as BoxDecoration;
        final gradient = decoration.gradient as LinearGradient;

        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.text('12/28'), findsOneWidget);
        expect(find.text('Virtual Card'), findsOneWidget);
        expect(find.text('••••'), findsOneWidget);
        expect(find.text('1234'), findsOneWidget);
        expect(gradient.colors, const <Color>[
          Color(0xFF0F0F0F),
          Color(0xFF757575),
        ]);
      },
    );
  });
}

Future<void> _pumpVisaCardGoldenApp(
  WidgetTester tester, {
  required Widget child,
  required Size surfaceSize,
  required ThemeMode themeMode,
}) async {
  tester.view.physicalSize = surfaceSize;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: themeMode,
      home: Scaffold(body: child),
    ),
  );
}

class _VisaCardGoldenProbe extends StatelessWidget {
  const _VisaCardGoldenProbe();

  @override
  Widget build(BuildContext context) {
    return const Center(child: SizedBox(width: 343, child: VisaCard()));
  }
}
