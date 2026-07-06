---
name: flutter-widget-search
description: Search `flutter-widget-wallet-mcp` for the best matching Flutter widgets by category, keyword, behavior, or design intent. Use when the user knows the use case but not the exact widget to reuse.
---

# Flutter Widget Search

Use this skill to identify which widgets in `flutter-widget-wallet-mcp` best match a requested use case.

## Use When

- the user asks what widget should be used for a screen or feature
- the user describes behavior without knowing widget names
- the user wants alternatives before installing anything

## Workflow

1. Restate the use case in search terms.
2. Use `list_categories` first if the request is broad.
3. Use `search_widgets` with concrete intent words such as `button`, `search`, `drawer`, `avatar`, `receipt`, or `tabs`.
4. Use `get_widget_metadata` on the top candidates.
5. Summarize the best 1-3 options with tradeoffs:
   - what the widget is for
   - required dependencies or assets
   - preview availability
   - whether adaptation effort seems low, medium, or high

## MCP Tools

- `list_categories`
- `search_widgets`
- `get_widget_metadata`

## Guardrails

- Do not jump straight to code extraction when the user is still choosing.
- Prefer widgets with preview coverage and lower dependency weight for starter recommendations.
- If no strong match exists, say so and recommend `flutter-widget-figma-to-code` or `flutter-widget-install` with adaptation.
