# DrawerBalanceDetail Widget

Bottom-sheet drawer for showing a balance summary and warning state.

## Figma Source

- File: `New Wi Wallet 2.0`
- Node: `7089:198920`
- Variant: `state=balance_detail`

## Current Figma-Aligned Spec

### Frame
- Width: `375`
- Max height in Flutter: `640`
- Corner radius: `16` on top corners
- Background: `fill/base/100`
- Backdrop: black overlay with blur

### Header
- Height: `24`
- Title: `Balance Detail`
- Typography: Noto Sans Thai, `15`, weight `600`
- Close icon: `24`

### Body
- Main vertical gap: `16`
- Hero image: `144 x 144`, exported from the current Figma image node into `lib/assets/images/drawer_balance_detail_coin.png`
- Balance card:
  - Background: `fill/base/300`
  - No outer border
  - Radius: `12`
  - Padding: `16`
  - Label: `Total Balance`
  - Amount color: `success/400`
  - Divider: `stroke/base/600`

### Warning
- Uses `AnnouncementWarning`
- Border radius: `12`
- Border color: `primary/500`
- Background: `warning/600`
- Text color: `text/base/warning`
- Height: dynamic according to content, not fixed in Flutter

### Footer
- CTA text: `View History`
- Button style: `primary`
- Default CTA action: treat the tap as redirect action, close the drawer, then show a toast/snackbar with `Rediect to History Page`
- Horizontal padding: `16`
- Bottom padding:
  - `40` when no safe-area inset
  - `16 + safe area` on gesture-navigation devices

## Flutter Files Kept In Sync

- Widget: `/Users/Niwat.yah/flutter_widgetbook_3.0/lib/widgets/drawer/drawer_balance_detail.dart`
- Preview: `/Users/Niwat.yah/flutter_widgetbook_3.0/lib/widgets/drawer/preview_drawer_balance_detail.dart`
- Widgetbook: `/Users/Niwat.yah/flutter_widgetbook_3.0/lib/widgetbook_use_cases.dart`
- Test: `/Users/Niwat.yah/flutter_widgetbook_3.0/test/drawer_balance_detail_test.dart`

## Preview

```bash
flutter run -d <device> -t lib/widgets/drawer/preview_drawer_balance_detail.dart
```

The preview shows a trigger button and opens the drawer with the same modal overlay flow used by the widget.
