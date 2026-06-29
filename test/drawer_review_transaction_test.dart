import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_review_transaction.dart';

import 'support/widget_test_harness.dart';

final _alertAssets = PlaceholderAssetBundle(
  assetPaths: const <String>['lib/assets/images/Alert Icon.svg'],
);

Widget _buildDrawer({VoidCallback? onConfirm, VoidCallback? onClose}) {
  return DrawerReviewTransaction(
    warningTitle: 'Recheck transaction details',
    warningDescription:
        'Please verify the recipient and the amount before continuing.',
    totalAmount: '5,000.00 THB',
    feeAmount: 'Fee 0.00 THB',
    fromLabel: 'From',
    fromValue: 'Your Wallet',
    mobileLabel: 'Mobile Number',
    mobileValue: '081-141-1234',
    toLabel: 'To',
    toValue: 'Siam Commercial Bank',
    accountNameLabel: 'Account Name',
    accountNameValue: 'Victor Von Doom',
    accountNumberLabel: 'Account Number',
    accountNumberValue: '1234567890',
    objectLabel: 'Object',
    objectValue: 'Personal expenses for the month',
    dateLabel: 'Date & Time',
    dateValue: '06 Oct 2025 12:00',
    confirmButtonText: 'Confirm transfer',
    onConfirm: onConfirm,
    onClose: onClose,
  );
}

void main() {
  testWidgets('DrawerReviewTransaction renders the transaction summary', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      _buildDrawer(),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Recheck transaction details'), findsOneWidget);
    expect(find.text('5,000.00 THB'), findsOneWidget);
    expect(find.text('Personal expenses for the month'), findsOneWidget);
    expect(find.text('Confirm transfer'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
  });

  testWidgets('DrawerReviewTransaction confirm button invokes callback', (
    WidgetTester tester,
  ) async {
    var confirmed = false;

    await pumpTestApp(
      tester,
      _buildDrawer(onConfirm: () => confirmed = true),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm transfer'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
  });

  testWidgets('DrawerReviewTransaction close button invokes callback', (
    WidgetTester tester,
  ) async {
    var closed = false;

    await pumpTestApp(
      tester,
      _buildDrawer(onClose: () => closed = true),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('DrawerReviewTransaction.show opens and closes the drawer', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      Builder(
        builder: (context) {
          return Center(
            child: ElevatedButton(
              onPressed: () {
                DrawerReviewTransaction.show(
                  context,
                  warningTitle: 'Recheck transaction details',
                  warningDescription:
                      'Please verify the recipient and the amount before continuing.',
                  totalAmount: '5,000.00 THB',
                  feeAmount: 'Fee 0.00 THB',
                  fromLabel: 'From',
                  fromValue: 'Your Wallet',
                  mobileLabel: 'Mobile Number',
                  mobileValue: '081-141-1234',
                  toLabel: 'To',
                  toValue: 'Siam Commercial Bank',
                  accountNameLabel: 'Account Name',
                  accountNameValue: 'Victor Von Doom',
                  accountNumberLabel: 'Account Number',
                  accountNumberValue: '1234567890',
                  objectLabel: 'Object',
                  objectValue: 'Personal expenses for the month',
                  dateLabel: 'Date & Time',
                  dateValue: '06 Oct 2025 12:00',
                  confirmButtonText: 'Confirm transfer',
                );
              },
              child: const Text('Open review drawer'),
            ),
          );
        },
      ),
      themeVariant: TestThemeVariant.dark,
      assetBundle: _alertAssets,
    );

    await tester.tap(find.text('Open review drawer'));
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Review'), findsNothing);
  });
}
