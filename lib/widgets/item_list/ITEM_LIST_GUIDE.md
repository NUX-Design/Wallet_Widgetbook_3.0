# Item List Widgets Guide

## Overview
The Item List collection consists of two primary widgets designed for different use cases: **ItemTile** for navigation and settings, and **HistoryCard** for transaction records. Both are theme-aware and follow the project's design token system.

---

## 1. ItemTile
The `ItemTile` is a versatile menu item component designed for settings screens, navigation menus, and selection lists. It features multiple "Trailing States" to handle different interaction patterns.

### Figma Code Connect
- **Figma Design**: [ItemTile Component](https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/New-Wi-Wallet-2.0?node-id=7219-1076&t=h5CMvsRbalgPC05t-4)

### Trailing States
The `ItemTile` supports three distinct trailing (right-side) configurations:
1.  **Arrow State (Default)**: Shows `arrow-right-01.svg` in `primary/400`. Used for navigation.
2.  **Text State**: Displays a `trailingText` string. Used for showing current values (e.g., "Language: English").
3.  **Radio State**: Displays a radio button. Used for selection lists (supports `isSelected` true/false).

### Design Specifications
- **Height**: 56px (fixed)
- **Padding**: 16px horizontal
- **Background**: `fill/base/300`
- **Border Radius**: 12px
- **Leading Icon**: 24x24px, default `Transaction History.svg`

---

## 2. HistoryCard
The `HistoryCard` is a specialized widget for displaying financial transactions. It is optimized for showing amounts and transaction types.

### Figma Code Connect
- **Figma Design**: [HistoryCard Component](https://www.figma.com/design/D7WVaC8n3foVLo6S3HuPn8/New-Wi-Wallet-2.0?node-id=7186-32854&t=h5CMvsRbalgPC05t-4)

### Transaction States
The `HistoryCard` handles two specific types defined via `ItemListType`:
1.  **Transaction In**: Displays `lib/assets/images/arrow-down-left-round.png` with a positive amount in `text/base/success`.
2.  **Transaction Out**: Displays `lib/assets/images/arrow-up-right-round.png` with a negative amount in `text/base/danger`.

### Design Specifications
- **Height**: 64px (min-height)
- **Padding**: 16px horizontal, 16px vertical
- **Background**: `fill/base/300`
- **Border Radius**: 12px
- **Subtitle**: Displays timestamp or transaction details in `text/base/500`.

---

## Properties & Parameters
Both widgets are currently implemented via the `ItemList` class. Below are the parameters and their logical application:

| Parameter | Type | Required | Default | Application | Description |
|-----------|------|----------|---------|-------------|-------------|
| `title` | `String` | No | `'History'` | Both | Main label text. Supports Noto Sans Thai. |
| `subtitle` | `String?` | No | `null` | HistoryCard | Secondary text (e.g., timestamp). |
| `iconPath` | `String?` | No | `null` | Both | Path to SVG asset. Fallbacks to `Transaction History.svg`. |
| `onTap` | `VoidCallback?` | No | `null` | Both | Callback function when the item is tapped. |
| `trailingText` | `String?` | No | `null` | ItemTile | Text shown at the end (Trailing State: Text). |
| `isSelected` | `bool?` | No | `null` | ItemTile | Shows Radio Button if not null (Trailing State: Radio). |
| `type` | `ItemListType` | No | `common` | Both | Enum to switch between `common`, `transactionIn`, `transactionOut`. |
| `amount` | `String?` | No | `null` | HistoryCard | The currency amount to display. |
| `amountColor` | `Color?` | No | `null` | HistoryCard | Overrides default success/danger colors. |

---

## Technical Implementation Details

### Typography
- **Font Family**: Noto Sans Thai
- **Title**: 13px, Semi-Bold (600), Line Height 16px
- **Subtitle**: 10px, Regular (400), Line Height 12px
- **Amount/Trailing**: 11px-13px, Medium (500)

### Compliance
- ✅ Uses `ThemeColors.get()` for all colors.
- ✅ Full Dark Mode / Light Mode adaptation.
- ✅ Responsive layouts with `Expanded` labels.

## File Structure
```
lib/widgets/item_list/
├── item_list.dart              # Main implementation (contains both logic)
├── preview_item_list.dart      # Visual testing for all states
└── ITEM_LIST_GUIDE.md         # This documentation
```
