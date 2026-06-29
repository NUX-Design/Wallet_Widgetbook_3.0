import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/card/card_review_transaction.dart';

import 'support/widget_test_harness.dart';

void main() {
  testWidgets('CardReviewTransaction renders rows and divider spacing', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const CardReviewTransaction(
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
        dateLabel: 'Date',
        dateValue: '06 Oct 2025 12:00',
      ),
      themeVariant: TestThemeVariant.light,
    );

    expect(find.text('Total'), findsOneWidget);
    expect(find.text('5,000.00 THB'), findsOneWidget);
    expect(find.text('Fee 0.00 THB'), findsOneWidget);
    expect(find.text('From'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Siam Commercial Bank'), findsOneWidget);
    expect(find.text('Account Name'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.text('Date'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.constraints is BoxConstraints &&
            (widget.constraints as BoxConstraints).minHeight == 1 &&
            (widget.constraints as BoxConstraints).maxHeight == 1,
      ),
      findsExactly(2),
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(CardReviewTransaction),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;
    expect(decoration.color, ThemeColors.get('light', 'fill/base/300'));
  });

  testWidgets('CardReviewTransaction uses dark theme tokens', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const CardReviewTransaction(
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
        dateLabel: 'Date',
        dateValue: '06 Oct 2025 12:00',
      ),
      themeVariant: TestThemeVariant.dark,
    );

    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(CardReviewTransaction),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = container.decoration! as BoxDecoration;

    expect(decoration.color, ThemeColors.get('dark', 'fill/base/300'));
    expect(find.text('5,000.00 THB'), findsOneWidget);
  });

  testWidgets('CardReviewTransaction keeps long values readable', (
    WidgetTester tester,
  ) async {
    await pumpTestApp(
      tester,
      const CardReviewTransaction(
        totalAmount: '123,456,789.00 THB',
        feeAmount: 'Fee 15.00 THB',
        fromLabel: 'From',
        fromValue: 'A very long wallet name that should wrap cleanly',
        mobileLabel: 'Mobile Number',
        mobileValue: '081-141-1234',
        toLabel: 'To',
        toValue: 'A very long recipient bank name that should wrap cleanly',
        accountNameLabel: 'Account Name',
        accountNameValue: 'A very long account holder name that should wrap',
        accountNumberLabel: 'Account Number',
        accountNumberValue: '12345678901234567890',
        dateLabel: 'Date',
        dateValue: '06 Oct 2025 12:00',
      ),
      themeVariant: TestThemeVariant.dark,
    );

    expect(find.text('123,456,789.00 THB'), findsOneWidget);
    expect(
      find.text('A very long recipient bank name that should wrap cleanly'),
      findsOneWidget,
    );
  });
}
