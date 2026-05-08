// dart format width=80
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_import, prefer_relative_imports, directives_ordering

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AppGenerator
// **************************************************************************

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:mcp_test_app/widgetbook_use_cases.dart'
    as _mcp_test_app_widgetbook_use_cases;
import 'package:widgetbook/widgetbook.dart' as _widgetbook;

final directories = <_widgetbook.WidgetbookNode>[
  _widgetbook.WidgetbookFolder(
    name: 'widgets',
    children: [
      _widgetbook.WidgetbookFolder(
        name: 'announce',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'AnnouncementDanger',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildAnnouncementDanger,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'AnnouncementStack',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildAnnouncementStack,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Loading',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildAnnouncementStackLoading,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'AnnouncementWarning',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildAnnouncementWarning,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'button',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'Buttons',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Amount',
                builder: _mcp_test_app_widgetbook_use_cases.buildButtonAmount,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Disabled',
                builder: _mcp_test_app_widgetbook_use_cases.buildButtonDisabled,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Primary',
                builder: _mcp_test_app_widgetbook_use_cases.buildButtonPrimary,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Secondary',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildButtonSecondary,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'card',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'CardReviewTransaction',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildCardReviewTransaction,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'drawer',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'DrawerBalanceDetail',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Balance Detail',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildDrawerBalanceDetail,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'DrawerCountryCode',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Country Code',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildDrawerCountryCode,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'DrawerDepositChannel',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Deposit Channel',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildDrawerDepositChannel,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'DrawerReviewTransaction',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Review Transaction',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildDrawerReviewTransaction,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'image_carousel',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ImageCarousel',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Auto Play',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildImageCarouselAutoPlay,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildImageCarousel,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'input',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'FullAmountInput',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildFullAmountInput,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'MobileCodeInput',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildMobileCodeInput,
              ),
            ],
          ),
          _widgetbook.WidgetbookComponent(
            name: 'SearchInput',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildSearchInput,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'item_list',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ItemList',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildItemList,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Transaction In Type',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildItemListTransactionIn,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Transaction Out Type',
                builder:
                    _mcp_test_app_widgetbook_use_cases
                        .buildItemListTransactionOut,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With Radio Button (Selected)',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildItemListSelected,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With Radio Button (Unselected)',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildItemListUnselected,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'With Trailing Text',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildItemListWithText,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'loading',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'PreLoading',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildPreLoading,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'navigator_bar',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'NavigatorBar',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildNavigatorBar,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'receipt',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ReceiptComponent',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildReceiptComponent,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'shortcut_menu',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'ShortcutMenuItem',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildShortcutMenu,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'skeleton',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'LottieSkeleton',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildLottieSkeleton,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'snack_bar',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'SnackBarWidget',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Error',
                builder: _mcp_test_app_widgetbook_use_cases.buildSnackBarError,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Success',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildSnackBarSuccess,
              ),
              _widgetbook.WidgetbookUseCase(
                name: 'Warning',
                builder:
                    _mcp_test_app_widgetbook_use_cases.buildSnackBarWarning,
              ),
            ],
          ),
        ],
      ),
      _widgetbook.WidgetbookFolder(
        name: 'visa',
        children: [
          _widgetbook.WidgetbookComponent(
            name: 'VisaCard',
            useCases: [
              _widgetbook.WidgetbookUseCase(
                name: 'Default',
                builder: _mcp_test_app_widgetbook_use_cases.buildVisaCard,
              ),
            ],
          ),
        ],
      ),
    ],
  ),
];
