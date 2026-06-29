import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/announce/announcement_warning.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_balance_detail.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';

Widget _buildSubject({
  VoidCallback? onClose,
  VoidCallback? onViewHistory,
  String buttonText = 'View History',
  bool showButton = true,
  String warningText =
      '*Hold Amount means they aren\'t immediately available for use. Please contact our customer support team for more details and to process the next steps.',
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData.dark(),
    home: Scaffold(
      body: DrawerBalanceDetail(
        totalBalanceAmount: '100,000,000,000.00',
        totalBalanceLabel: 'Total Balance',
        holdAmountLabel: 'Hold Amount',
        holdAmountValue: '5,030.20',
        ledgerBalanceLabel: 'Ledger Balance',
        ledgerBalanceValue: '15,030.20',
        warningText: warningText,
        buttonText: buttonText,
        onClose: onClose,
        onViewHistory: onViewHistory,
        showButton: showButton,
      ),
    ),
  );
}

void main() {
  testWidgets('DrawerBalanceDetail renders the Figma-aligned content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildSubject());

    expect(find.text('Balance Detail'), findsOneWidget);
    expect(find.text('Total Balance'), findsOneWidget);
    expect(find.text('100,000,000,000.00 THB'), findsOneWidget);
    expect(find.text('View History'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('DrawerBalanceDetail close icon triggers callback', (
    WidgetTester tester,
  ) async {
    var closed = false;

    await tester.pumpWidget(_buildSubject(onClose: () => closed = true));
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('DrawerBalanceDetail primary button shows redirect toast', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildSubject());
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(find.text('Rediect to History Page'), findsOneWidget);
  });

  testWidgets('DrawerBalanceDetail supports custom View History callback', (
    WidgetTester tester,
  ) async {
    var redirected = false;

    await tester.pumpWidget(
      _buildSubject(onViewHistory: () => redirected = true),
    );
    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(redirected, isTrue);
  });

  testWidgets('DrawerBalanceDetail hides the CTA when showButton is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_buildSubject(showButton: false));

    expect(find.text('View History'), findsNothing);
  });

  testWidgets('DrawerBalanceDetail.show closes the drawer then shows snackbar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed:
                    () => DrawerBalanceDetail.show(
                      context,
                      totalBalanceAmount: '100,000,000,000.00',
                      totalBalanceLabel: 'Total Balance',
                      holdAmountLabel: 'Hold Amount',
                      holdAmountValue: '5,030.20',
                      ledgerBalanceLabel: 'Ledger Balance',
                      ledgerBalanceValue: '15,030.20',
                      warningText:
                          '*Hold Amount means they aren\'t immediately available for use. Please contact our customer support team for more details and to process the next steps.',
                    ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Balance Detail'), findsOneWidget);

    await tester.tap(find.text('View History'));
    await tester.pumpAndSettle();

    expect(find.text('Balance Detail'), findsNothing);
    expect(find.text('Rediect to History Page'), findsOneWidget);
  });

  testWidgets('DrawerBalanceDetail announcement grows with longer content', (
    WidgetTester tester,
  ) async {
    const shortWarning =
        '*Hold Amount means they aren\'t immediately available for use.';
    const longWarning =
        '*Hold Amount means they aren\'t immediately available for use. Please contact our customer support team for more details and to process the next steps. This balance status can remain until the transaction lifecycle is fully completed and verified by the destination bank.';

    await tester.pumpWidget(_buildSubject(warningText: shortWarning));
    final shortHeight = tester.getSize(find.byType(AnnouncementWarning)).height;

    await tester.pumpWidget(_buildSubject(warningText: longWarning));
    await tester.pumpAndSettle();
    final longHeight = tester.getSize(find.byType(AnnouncementWarning)).height;

    expect(longHeight, greaterThan(shortHeight));
  });

  testWidgets('DrawerBalanceDetail supports loading state and safe area bottom', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(padding: EdgeInsets.only(bottom: 24)),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData.dark(),
          home: Scaffold(
            body: DrawerBalanceDetail(
              totalBalanceAmount: '100,000,000,000.00',
              holdAmountLabel: 'Hold Amount',
              holdAmountValue: '5,030.20',
              ledgerBalanceLabel: 'Ledger Balance',
              ledgerBalanceValue: '15,030.20',
              warningText:
                  '*Hold Amount means they aren\'t immediately available for use.',
              isLoading: true,
              showButton: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LottieSkeleton), findsWidgets);
    expect(find.text('View History'), findsNothing);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints is BoxConstraints &&
            (widget.constraints as BoxConstraints).minHeight == 24 &&
            (widget.constraints as BoxConstraints).maxHeight == 24 &&
            widget.decoration == null,
      ),
      findsOneWidget,
    );
  });
}
