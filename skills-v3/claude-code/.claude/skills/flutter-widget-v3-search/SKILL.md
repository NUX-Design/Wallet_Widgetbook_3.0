---
name: flutter-widget-v3-search
description: Search `flutter-widget-wallet-mcp` for the best matching Widget V3 components by category, keyword, behavior, or design intent. Use when the user knows the use case but not the exact V3 widget to reuse.
---

# Flutter Widget V3 Search

Invoke with `/flutter-widget-v3-search` in Claude Code, or describe the desired V3 widget/use case naturally.

Use this skill to identify which widgets under `lib/widgets/v3/**` in `flutter-widget-wallet-mcp` best match a requested use case.

## Use When

- the user asks what V3 widget should be used for a screen or feature
- the user describes behavior without knowing V3 widget names
- the user wants alternatives before installing anything, and wants them on Theme V3
- the user wants to actually see a V3 widget rendered live in a browser (identify it here, then hand off to `flutter-widget-v3-preview` to launch it)

## Workflow

1. Restate the use case in search terms.
2. Use `list_v3_categories` first if the request is broad.
3. Use `search_v3_widgets` with concrete intent words.
4. Use `get_v3_widget_metadata` on the top candidates to confirm `themeVersion: v3` and semantic token dependencies.
5. Summarize the best 1-3 options with tradeoffs:
   - what the widget is for
   - semantic tokens it depends on
   - preview availability
   - whether adaptation effort seems low, medium, or high

## MCP Tools

- `list_v3_categories`
- `search_v3_widgets`
- `get_v3_widget_metadata`

## Guardrails

- Only consider widgets indexed from `lib/widgets/v3/**`; never suggest migrating a legacy widget as if it were V3.
- Prefer widgets with preview coverage and lower token/dependency weight for starter recommendations.
- If no strong V3 match exists, say so and recommend `flutter-widget-v3-figma-to-code` or `flutter-widget-v3-beginner` instead of falling back to a legacy widget.
- If the request is really "show me this component running," confirm the widget name here and hand off to `flutter-widget-v3-preview`'s Live Browser Preview flow instead of trying to launch anything from this skill.
