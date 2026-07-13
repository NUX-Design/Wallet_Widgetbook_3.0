# Receipt Widget Reference

## Source Files

- `references/receipt/AGENT.md`
- `references/receipt/FIGMA.md`
- `references/receipt/receipt_api.md`
- `references/receipt/base-receipt.md`
- `references/receipt/DESIGN.md`
- `references/receipt/receipt_component.md`
- `references/receipt/receipt_image_component.md`

## Flutter Targets

- `flutter_widgetbook_3.0/lib/widgets/receipt/receipt_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/receipt_image_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/preview_receipt_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/preview_receipt_image_component.dart`

## Key Rules

- Keep literal colors.
- Keep width responsive and height content-driven.
- Keep the background as a separate clipped SVG layer.
- Keep `Transaction confirmed` and label rows single-line where the spec requires it.
- Keep confirmation padding at `16px` horizontal and `0px` vertical.
- Keep `Scan to Verify` hidden.
