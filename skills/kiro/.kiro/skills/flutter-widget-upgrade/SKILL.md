---
name: flutter-widget-upgrade
description: Compare a local widget implementation against the current `flutter-widget-wallet-mcp` source-of-truth and upgrade it safely. Use when a repo already contains a widget derived from the library but may have drifted behind the latest source.
---

# Flutter Widget Upgrade

Use this skill from Kiro by selecting the skill directly or by asking to refresh a drifted local widget naturally.

Use this skill when the current repo already contains a widget that came from or resembles `flutter-widget-wallet-mcp`, and the user wants it refreshed.

## Workflow

1. Identify the local widget and its related preview and tests.
2. Fetch the latest source-of-truth data from MCP:
   - metadata
   - source code
   - preview code
3. Diff local behavior against MCP source behavior.
4. Separate:
   - local intentional customizations
   - upstream improvements worth taking
   - risky breaking changes
5. Upgrade in small steps, preserving local business-specific customizations where possible.
6. Refresh previews and tests if the public API or major states changed.

## MCP Tools

- `get_widget_metadata`
- `get_widget_code`
- `get_widget_preview`
- `search_widgets`

## Guardrails

- Do not overwrite local intentional customizations without calling them out.
- Prefer selective sync over wholesale replacement.
- If the drift is too large, recommend a reinstall-plus-adapt path instead of an in-place upgrade.
