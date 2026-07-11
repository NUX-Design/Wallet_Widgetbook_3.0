---
name: flutter-widget-v3-preview
description: Create or refresh standalone previews and Widgetbook use cases for a Widget V3 component integrated from `flutter-widget-wallet-mcp`. Use when a V3 widget exists but is not yet easy to run or inspect in isolation.
---

# Flutter Widget V3 Preview

Use this skill to make Widget V3 components easy to inspect and validate visually in Light and Dark.

## Workflow

1. Inspect how the current repo handles Widget V3 previews: standalone `preview_v3_*.dart` or Widgetbook.
2. Pull preview examples from MCP with `get_v3_widget_preview` when available.
3. If the repo uses Widgetbook and local/stdio MCP is available, optionally generate use cases with `generate_v3_widgetbook_use_case`.
4. If the repo uses standalone previews, create or refresh the local `preview_v3_<widget>.dart` entrypoint with a Light/Dark toggle, mirroring the `V3MiniButton` pilot pattern.
5. Keep preview sample data aligned with the widget's public API and semantic token metadata.
6. Confirm both Light and Dark render correctly before finishing.

## Remote-Safe Fallback

When connected through Remote MCP, use `get_v3_widget_preview` and `get_v3_widget_metadata`, then author the local standalone preview or Widgetbook use case directly from those read-only results and the host repo conventions. Do not call `generate_v3_widgetbook_use_case` or fall back to a legacy generation tool.

## MCP Tools

- `get_v3_widget_preview`
- `generate_v3_widgetbook_use_case`
- `get_v3_widget_metadata`

## Guardrails

- Do not hand-edit `lib/widgetbook.directories.g.dart`; regenerate it with the project's build_runner command instead.
- Preserve the host repo's preview style rather than copying the source repo verbatim.
- Keep preview data realistic enough to exercise the widget's main states (default, interactive, disabled/error where applicable).
