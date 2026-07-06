---
name: flutter-widget-preview
description: Create or refresh preview entrypoints and Widgetbook use cases for a Flutter widget integrated from `flutter-widget-wallet-mcp`. Use when a widget exists but is not yet easy to run or inspect in isolation.
---

# Flutter Widget Preview

Use this skill from Kiro by selecting the skill directly or by asking to create or refresh previews naturally.

Use this skill to make widgets easy to inspect and validate visually.

## Workflow

1. Inspect how the current repo handles previews:
   - standalone `preview_*.dart`
   - Widgetbook
   - custom demo pages
2. Pull preview examples from MCP with `get_widget_preview` when available.
3. If the repo uses Widgetbook, generate or update use cases with `generate_widgetbook_use_case`.
4. If the repo uses standalone previews, create or refresh the local preview entrypoint.
5. Keep preview sample data aligned with the widget API.
6. Prefer both light and dark sanity coverage when relevant.

## MCP Tools

- `get_widget_preview`
- `generate_widgetbook_use_case`
- `get_widget_metadata`

## Guardrails

- Do not hand-edit generated Widgetbook directory files.
- Preserve the host repo's preview style rather than copying the source repo verbatim.
- Keep preview data realistic enough to exercise the main states of the widget.
