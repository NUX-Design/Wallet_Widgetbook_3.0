import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_deposit_channel.dart';

Finder _cancelIconFinder() {
  return find.byWidgetPredicate((widget) {
    return widget is SvgPicture &&
        widget.bytesLoader is SvgAssetLoader &&
        (widget.bytesLoader as SvgAssetLoader).assetName ==
            'lib/assets/images/cancel-01.svg';
  });
}

void main() {
  Future<void> pumpDrawer(
    WidgetTester tester, {
    Function(BankType)? onBankSelected,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(375, 640);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 375,
              height: 640,
              child: DrawerDepositChannel(onBankSelected: onBankSelected),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders four Figma bank logos and names', (tester) async {
    await pumpDrawer(tester);

    expect(find.text('Deposit Channel'), findsOneWidget);
    expect(find.text('Mobile Banking'), findsOneWidget);
    expect(find.text('Siam Commercial Bank'), findsOneWidget);
    expect(find.text('Bangkok Bank Mobile Banking'), findsOneWidget);
    expect(find.text('Bank of Ayudhya'), findsOneWidget);
    expect(find.text('Kasikorn Bank'), findsOneWidget);

    final images =
        tester.widgetList<SvgPicture>(find.byType(SvgPicture)).toList();
    final logoImages =
        images
            .map((image) => image.bytesLoader)
            .whereType<SvgAssetLoader>()
            .where(
              (image) =>
                  image.assetName.startsWith('lib/assets/images/figma_banks/'),
            )
            .toList();

    expect(logoImages, hasLength(4));
    expect(
      logoImages.map((image) => image.assetName),
      containsAll(<String>[
        'lib/assets/images/figma_banks/scb.svg',
        'lib/assets/images/figma_banks/bbl.svg',
        'lib/assets/images/figma_banks/krungsri.svg',
        'lib/assets/images/figma_banks/kbank.svg',
      ]),
    );
  });

  testWidgets('calls onBankSelected when a bank row is tapped', (tester) async {
    BankType? selectedBank;

    await pumpDrawer(tester, onBankSelected: (bank) => selectedBank = bank);

    await tester.tap(find.text('Kasikorn Bank'));
    await tester.pump();

    expect(selectedBank, BankType.kbank);
  });

  testWidgets('show helper opens the drawer and the close icon dismisses it', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    DrawerDepositChannel.show(context, onBankSelected: (_) {});
                  },
                  child: const Text('Open'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Deposit Channel'), findsOneWidget);

    await tester.tap(_cancelIconFinder());
    await tester.pumpAndSettle();

    expect(find.text('Deposit Channel'), findsNothing);
  });

  testWidgets('close callback is invoked when the drawer is dismissed', (
    tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: DrawerDepositChannel(onClose: () => closed = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_cancelIconFinder());
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });
}
