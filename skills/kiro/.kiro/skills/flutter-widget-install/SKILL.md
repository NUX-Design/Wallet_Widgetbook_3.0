---
name: flutter-widget-install
description: Install or transplant a widget from `flutter-widget-wallet-mcp` into the current Flutter project, including source code, previews, and any required supporting context. Use when the user already knows which widget to reuse.
---

# Flutter Widget Install

Use this skill from Kiro by selecting the skill directly or by asking to transplant a known widget naturally.

Use this skill when the user already has a target widget in mind and wants it brought into the current repo.

## Workflow

1. Confirm the widget name or narrow it down with `flutter-widget-search`.
2. Read `get_widget_metadata` first to understand:
   - props
   - assets
   - dependencies
   - preview files
   - doc files
3. Pull the source with `get_widget_code`.
4. Pull the preview with `get_widget_preview` when available.
5. Place files into the target repo using the local folder conventions.
6. Adapt imports, theme access, localization, and asset paths.
7. Add or update tests and previews if the widget becomes reusable project code.
8. Run the narrowest useful validation.

## MCP Tools

- `get_widget_metadata`
- `get_widget_code`
- `get_widget_preview`

## Guardrails

- Do not paste source blindly. Adapt imports and dependencies for the current repo.
- Do not hardcode colors that should come from the target repo theme system.
- Do not drop required preview or example wiring when the widget is intended for reuse.
- If the widget depends on project-specific patterns that do not exist in the target repo, state the gap and either scaffold them or stop for confirmation.
