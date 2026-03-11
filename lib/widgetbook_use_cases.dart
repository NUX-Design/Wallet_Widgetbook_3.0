import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:mcp_test_app/widgets/item_list/item_list.dart';
import 'package:mcp_test_app/config/themes/theme_color.dart';
import 'package:mcp_test_app/widgets/announce/announcement.dart';
import 'package:mcp_test_app/widgets/announce/announcement_warning.dart';
import 'package:mcp_test_app/widgets/button/buttons.dart';
import 'package:mcp_test_app/widgets/card/card_review_transaction.dart';
import 'package:mcp_test_app/widgets/input/full_amount_input.dart';
import 'package:mcp_test_app/widgets/input/mobile_code_input.dart';
import 'package:mcp_test_app/widgets/input/search_input.dart';
import 'package:mcp_test_app/widgets/shortcut_menu/shortcut_menu.dart';
import 'package:mcp_test_app/widgets/visa/visa_card.dart';
import 'package:mcp_test_app/widgets/navigator_bar/navigator_bar.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_balance_detail.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_country_code.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_deposit_channel.dart';
import 'package:mcp_test_app/widgets/drawer/drawer_review_transaction.dart';
import 'package:mcp_test_app/widgets/snack_bar/snack_bar.dart';
import 'package:mcp_test_app/generated/intl/app_localizations.dart';
import 'package:mcp_test_app/widgets/image_carousel/image_carousel.dart';
import 'package:mcp_test_app/widgets/skeleton/lottie_skeleton.dart';
import 'package:mcp_test_app/widgets/avatar/preview_avatar.dart'; // ignore: unused_import
import 'package:mcp_test_app/widgets/loading/pre_loading.dart';

// ItemList
@widgetbook.UseCase(name: 'Default', type: ItemList)
Widget buildItemList(BuildContext context) {
  return ItemList(title: 'Transaction History', onTap: () {});
}
// ... (skipping unchanged parts) ...

// Image Carousel
@widgetbook.UseCase(name: 'Default', type: ImageCarousel)
Widget buildImageCarousel(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ImageCarousel(
      pages: [
        Image.asset('lib/assets/images/test-banner.png', fit: BoxFit.cover),
        Image.asset('lib/assets/images/test-banner2.png', fit: BoxFit.cover),
        Image.asset('lib/assets/images/test-banner3.png', fit: BoxFit.cover),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'Auto Play', type: ImageCarousel)
Widget buildImageCarouselAutoPlay(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: ImageCarousel(
      autoPlay: true,
      pages: [
        Image.asset('lib/assets/images/test-banner.png', fit: BoxFit.cover),
        Image.asset('lib/assets/images/test-banner2.png', fit: BoxFit.cover),
        Image.asset('lib/assets/images/test-banner3.png', fit: BoxFit.cover),
      ],
    ),
  );
}

@widgetbook.UseCase(name: 'With Trailing Text', type: ItemList)
Widget buildItemListWithText(BuildContext context) {
  return ItemList(title: 'Language', trailingText: 'English', onTap: () {});
}

@widgetbook.UseCase(name: 'With Radio Button (Selected)', type: ItemList)
Widget buildItemListSelected(BuildContext context) {
  return ItemList(title: 'English', isSelected: true, onTap: () {});
}

@widgetbook.UseCase(name: 'With Radio Button (Unselected)', type: ItemList)
Widget buildItemListUnselected(BuildContext context) {
  return ItemList(title: 'Thai', isSelected: false, onTap: () {});
}

@widgetbook.UseCase(name: 'Transaction In Type', type: ItemList)
Widget buildItemListTransactionIn(BuildContext context) {
  return ItemList(
    type: ItemListType.transactionIn,
    title: 'Received from Victor Von Doom',
    subtitle: '2025-10-06 12:00:53',
    amount: '+50,000.00 THB',
    onTap: () {},
  );
}

@widgetbook.UseCase(name: 'Transaction Out Type', type: ItemList)
Widget buildItemListTransactionOut(BuildContext context) {
  return ItemList(
    type: ItemListType.transactionOut,
    title: 'Transfer to Victor Von Doom',
    subtitle: '2025-10-06 12:00:53',
    amount: '-50,000.00 THB',
    onTap: () {},
  );
}

// Announcement
@widgetbook.UseCase(name: 'Default', type: AnnouncementStack)
Widget buildAnnouncementStack(BuildContext context) {
  return Localizations(
    delegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    child: Builder(
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: AnnouncementStack(
              messages: [
                'Your account has been verified successfully. All features are now fully accessible from 01/06/2022 at 8:00 AM (Thailand time).',
                AppLocalizations.of(
                  context,
                )!.homeAnnounceVerifyFaceToReceive('100.00', 'THB'),
                'This is a very long announcement message that is intended to test the text truncation functionality of the widget. It should be long enough to exceed three lines when displayed on a standard mobile screen width.',
              ],
            ),
          ),
    ),
  );
}

@widgetbook.UseCase(name: 'Loading', type: AnnouncementStack)
Widget buildAnnouncementStackLoading(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: AnnouncementStack(isLoading: true),
  );
}

@widgetbook.UseCase(name: 'Default', type: AnnouncementWarning)
Widget buildAnnouncementWarning(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: AnnouncementWarning(
      title: 'Please recheck information before proceeding',
      description:
          'To prevent wrong account transfers or fraudulent activities. It cannot be changed once confirmed.',
    ),
  );
}

// Buttons
@widgetbook.UseCase(name: 'Primary', type: Buttons)
Widget buildButtonPrimary(BuildContext context) {
  return Buttons(
    text: 'Primary Button',
    type: ButtonType.primary,
    onPressed: () {},
  );
}

@widgetbook.UseCase(name: 'Secondary', type: Buttons)
Widget buildButtonSecondary(BuildContext context) {
  return Buttons(
    text: 'Secondary Button',
    type: ButtonType.secondary,
    onPressed: () {},
  );
}

@widgetbook.UseCase(name: 'Amount', type: Buttons)
Widget buildButtonAmount(BuildContext context) {
  return Buttons(text: '100', type: ButtonType.amount, onPressed: () {});
}

@widgetbook.UseCase(name: 'Disabled', type: Buttons)
Widget buildButtonDisabled(BuildContext context) {
  return const Buttons(text: 'Disabled Button', enabled: false);
}

// Card
@widgetbook.UseCase(name: 'Default', type: CardReviewTransaction)
Widget buildCardReviewTransaction(BuildContext context) {
  return const CardReviewTransaction(
    totalAmount: '100.00 THB',
    feeAmount: 'Fee 0.00 THB',
    fromLabel: 'From',
    fromValue: 'John Doe',
    mobileLabel: 'Mobile',
    mobileValue: '0812345678',
    toLabel: 'To',
    toValue: 'Jane Smith',
    accountNameLabel: 'Account Name',
    accountNameValue: 'Jane Smith',
    accountNumberLabel: 'Account Number',
    accountNumberValue: '123-4-56789-0',
    dateLabel: 'Date&Time',
    dateValue: '06 Oct 2025 12:00',
  );
}

// Input
@widgetbook.UseCase(name: 'Default', type: FullAmountInput)
Widget buildFullAmountInput(BuildContext context) {
  return const FullAmountInput();
}

@widgetbook.UseCase(name: 'Default', type: MobileCodeInput)
Widget buildMobileCodeInput(BuildContext context) {
  return Localizations(
    delegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    child: Builder(
      builder:
          (context) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: MobileCodeInput(onCountryCodeTap: () {}),
            ),
          ),
    ),
  );
}

@widgetbook.UseCase(name: 'Default', type: SearchInput)
Widget buildSearchInput(BuildContext context) {
  return const SearchInput();
}

// Shortcut Menu
@widgetbook.UseCase(name: 'Default', type: ShortcutMenuItem)
Widget buildShortcutMenu(BuildContext context) {
  return const ShortcutMenuItem(label: 'Transfer');
}

// Visa Card
@widgetbook.UseCase(name: 'Default', type: VisaCard)
Widget buildVisaCard(BuildContext context) {
  return const VisaCard();
}

// Navigator Bar
@widgetbook.UseCase(name: 'Default', type: NavigatorBar)
Widget buildNavigatorBar(BuildContext context) {
  return Localizations(
    delegates: AppLocalizations.localizationsDelegates,
    locale: const Locale('en'),
    child: Builder(
      builder:
          (context) => const Scaffold(
            extendBody: true,
            body: Center(child: Text('Navigator Bar Preview')),
            bottomNavigationBar: NavigatorBar(),
          ),
    ),
  );
}

// Drawer
@widgetbook.UseCase(name: 'Balance Detail', type: DrawerBalanceDetail)
Widget buildDrawerBalanceDetail(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {},
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.55)),
          ),
        ),
      ),
      const Align(
        alignment: Alignment.bottomCenter,
        child: DrawerBalanceDetail(
          totalBalanceAmount: '100,000,000,000.00',
          totalBalanceLabel: 'Total Balance',
          holdAmountLabel: 'Hold Amount',
          holdAmountValue: '5,030.20',
          ledgerBalanceLabel: 'Ledger Balance',
          ledgerBalanceValue: '15,030.20',
          warningText:
              '*Hold Amount means they aren\'t immediately available for use. Please contact our customer support team for more details and to process the next steps.',
          buttonText: 'View History',
        ),
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Country Code', type: DrawerCountryCode)
Widget buildDrawerCountryCode(BuildContext context) {
  return const DrawerCountryCode(
    title: 'Select Country',
    countries: [
      CountryCode(
        name: 'Thailand',
        code: '+66',
        flagAsset: 'lib/assets/images/flag_th.svg',
      ),
      CountryCode(
        name: 'United States',
        code: '+1',
        flagAsset: 'lib/assets/images/flag_us.svg',
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Deposit Channel', type: DrawerDepositChannel)
Widget buildDrawerDepositChannel(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {},
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
      const Align(
        alignment: Alignment.bottomCenter,
        child: DrawerDepositChannel(),
      ),
    ],
  );
}

@widgetbook.UseCase(name: 'Review Transaction', type: DrawerReviewTransaction)
Widget buildDrawerReviewTransaction(BuildContext context) {
  return Stack(
    children: [
      Positioned.fill(
        child: GestureDetector(
          onTap: () {},
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
      const Align(
        alignment: Alignment.bottomCenter,
        child: DrawerReviewTransaction(
          warningTitle: 'Warning',
          warningDescription: 'Please review your transaction.',
          totalAmount: '100.00 THB',
          feeAmount: 'Fee 0.00 THB',
          fromLabel: 'From',
          fromValue: 'John Doe',
          mobileLabel: 'Mobile',
          mobileValue: '0812345678',
          toLabel: 'To',
          toValue: 'Jane Smith',
          accountNameLabel: 'Account Name',
          accountNameValue: 'Jane Smith',
          accountNumberLabel: 'Account Number',
          accountNumberValue: '123-4-56789-0',
          objectLabel: 'Note',
          objectValue: 'Payment for services',
          dateLabel: 'Date&Time',
          dateValue: '06 Oct 2025 12:00',
        ),
      ),
    ],
  );
}

// SnackBar
@widgetbook.UseCase(name: 'Success', type: SnackBarWidget)
Widget buildSnackBarSuccess(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: SnackBarWidget(title: 'Success', type: SnackBarType.success),
  );
}

@widgetbook.UseCase(name: 'Warning', type: SnackBarWidget)
Widget buildSnackBarWarning(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: SnackBarWidget(title: 'Warning', type: SnackBarType.warning),
  );
}

@widgetbook.UseCase(name: 'Error', type: SnackBarWidget)
Widget buildSnackBarError(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(16.0),
    child: SnackBarWidget(title: 'Error', type: SnackBarType.error),
  );
}

// Skeleton
@widgetbook.UseCase(name: 'Default', type: LottieSkeleton)
Widget buildLottieSkeleton(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Card Skeleton'),
        const SizedBox(height: 8),
        LottieSkeleton(
          isLoading: true,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text('Avatar Skeleton'),
        const SizedBox(height: 8),
        LottieSkeleton(
          isLoading: true,
          borderRadius: BorderRadius.circular(40),
          child: const CircleAvatar(radius: 40),
        ),
        const SizedBox(height: 24),
        const Text('Button Skeleton'),
        const SizedBox(height: 8),
        LottieSkeleton(
          isLoading: true,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Button'),
            ),
          ),
        ),
      ],
    ),
  );
}

// Loading
@widgetbook.UseCase(name: 'Default', type: PreLoading)
Widget buildPreLoading(BuildContext context) {
  return Stack(
    children: [
      Center(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 20,
          itemBuilder: (context, index) {
            final isNegative = index % 2 == 0;
            final brightnessKey =
                Theme.of(context).brightness == Brightness.light
                    ? 'light'
                    : 'dark';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ItemList(
                type:
                    isNegative
                        ? ItemListType.transactionOut
                        : ItemListType.transactionIn,
                title:
                    isNegative
                        ? 'Victor Von Doom ${index + 1}'
                        : 'Transfer from ${index + 1}',
                subtitle: '2025-10-06 12:00:53',
                amount: isNegative ? '-50,000.00 THB' : '+50,000.00 THB',
                amountColor: ThemeColors.get(
                  brightnessKey,
                  isNegative ? 'text/base/danger' : 'text/base/success',
                ),
                onTap: () {},
              ),
            );
          },
        ),
      ),
      const PreLoading(),
    ],
  );
}
