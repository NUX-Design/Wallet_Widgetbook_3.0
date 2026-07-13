# Flutter Implementation Hints

## Target Project

- Repo: `flutter_widgetbook_3.0`
- App/package name: `mcp_test_app`
- Receipt widgets live under `lib/widgets/receipt/`

## Widget Patterns

- Keep the receipt widgets as standalone Flutter widgets with fixed sample-data previews.
- Use `LayoutBuilder` for width-aware layout decisions.
- Use `SingleChildScrollView` in preview apps so the receipt can exceed viewport height safely.
- Keep the preview app simple: `MaterialApp -> Scaffold -> SafeArea -> ScrollView -> receipt widget`.

## Preview Files

- `preview_receipt_component.dart` should import `receipt_component.dart`.
- `preview_receipt_image_component.dart` should import `receipt_image_component.dart`.
- Keep the preview sample data aligned with the widget API.
- If the transaction detail count changes, update the preview file's sample data.
- For running or refreshing previews, see [preview-workflow.md](preview-workflow.md).

## Sample Data Conventions

- Use the same sample transaction values across previews unless a state needs different sample content.
- Include `ref2` and `ref3` when the transaction detail list is expected to show seven rows.
- Keep asset paths literal and aligned with the current pubspec asset bundle.

## Visual Conventions

- Use `google_fonts` and `flutter_svg` as the current widgets do.
- Keep the confirmation spacing, card radius, divider treatment, and background watermark behavior aligned with the Figma/spec docs.
- Keep the `ReceiptComponent` and `ReceiptImageComponent` previews visually distinct and do not share state-specific rules that conflict with the docs.
