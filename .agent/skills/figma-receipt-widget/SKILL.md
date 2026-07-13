---
name: figma-receipt-widget
description: Generate or update the Flutter receipt widgets from the bundled receipt handoff spec and Figma reference set. Use when building or syncing receipt_component.dart, receipt_image_component.dart, preview_receipt_component.dart, or preview_receipt_image_component.dart.
---

# Figma Receipt Widget

Generate the Flutter receipt widget set from the bundled receipt handoff files inside this skill folder.

## Source Of Truth

Read these files first and treat them as authoritative:

1. `references/receipt/AGENT.md`
2. `references/receipt/FIGMA.md`
3. `references/receipt/receipt_api.md`
4. `references/receipt/base-receipt.md`
5. `references/receipt/DESIGN.md`
6. `references/receipt/receipt_component.md`
7. `references/receipt/receipt_image_component.md`
8. `references/flutter/implementation-hints.md`

## Output Targets

Update the receipt widget files in the target Flutter project:

- `flutter_widgetbook_3.0/lib/widgets/receipt/receipt_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/receipt_image_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/preview_receipt_component.dart`
- `flutter_widgetbook_3.0/lib/widgets/receipt/preview_receipt_image_component.dart`

## Workflow

1. Read the source-of-truth markdown in order.
2. Mirror the Figma and markdown contract in both widget files.
3. Keep both preview files aligned with the widget API and sample data.
4. Preserve literal colors, responsive width, content-driven height, and separate background layers.
5. Keep `ReceiptComponent` and `ReceiptImageComponent` visually distinct and do not merge their rules.
6. If the markdown contract changes, update the receipt folder docs to match.
7. When implementing the Flutter code, read `references/flutter/implementation-hints.md` for local project conventions and preview patterns.
8. When running or refreshing the local preview, read `references/flutter/preview-workflow.md`.

## Non-Negotiables

- Use the literal palette from the folder docs.
- Do not introduce theme tokens for this screen.
- Keep `Transaction confirmed` and other single-line labels from wrapping.
- Keep the confirmation section padding at `16px` horizontal and `0px` vertical.
- Keep `Scan to Verify` hidden.
- Keep the receipt background as a clipped SVG watermark behind content.
