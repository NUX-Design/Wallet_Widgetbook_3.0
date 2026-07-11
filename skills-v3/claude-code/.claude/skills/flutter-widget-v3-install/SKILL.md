---
name: flutter-widget-v3-install
description: Install or transplant a Widget V3 component from `flutter-widget-wallet-mcp` into the current Flutter project, including source code, previews, and V3 theme wiring. Use when the user already knows which V3 widget to reuse.
---

# Flutter Widget V3 Install

Invoke with `/flutter-widget-v3-install` in Claude Code, or ask Claude to transplant a known Widget V3 component naturally.

Use this skill when the user already has a target Widget V3 in mind and wants it brought into the current repo on Theme V3.

## Workflow

1. Confirm the widget name or narrow it down with `flutter-widget-v3-search`.
2. Read `get_v3_widget_metadata` first to understand props, semantic token dependencies, preview files, and doc files.
3. Pull the source with `get_v3_widget_code`.
4. Pull the preview with `get_v3_widget_preview` when available.
5. Place files into the target repo under `lib/widgets/v3/<category>/` and `test/widgets/v3/<category>/`, following `docs/v3/V3_WIDGET_CONVENTIONS.md`.
6. Rewire theme access to the target repo's own `V3ThemeScope.colorsOf(context)`; never point it at the source repo's generated tokens.
7. Add or refresh targeted tests and the local `V3_<WIDGET>_GUIDE.md`.
8. Run the narrowest useful validation (`flutter analyze`, targeted `flutter test`).

## MCP Tools

- `get_v3_widget_metadata`
- `get_v3_widget_code`
- `get_v3_widget_preview`

## Guardrails

- Before installing, confirm the target repo already has Theme V3 foundation (`lib/config/themes/v3/generated/`); if not, stop and recommend `flutter-widget-v3-beginner` first.
- Do not paste source blindly; re-point semantic token usage to the target repo's own `V3ThemeScope`.
- Do not drop required preview or test wiring when the widget is intended for reuse.
- Never place the installed widget outside `lib/widgets/v3/**`, and never touch legacy widgets as part of installation.
