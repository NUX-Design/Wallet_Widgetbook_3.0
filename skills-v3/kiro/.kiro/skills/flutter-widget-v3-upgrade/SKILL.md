---
name: flutter-widget-v3-upgrade
description: Compare a local Widget V3 implementation against the current `flutter-widget-wallet-mcp` V3 source-of-truth and upgrade it safely. Use when a repo already contains a Widget V3 component derived from the library but may have drifted behind the latest V3 source.
---

# Flutter Widget V3 Upgrade

Use this skill from Kiro by selecting the skill directly or by asking to upgrade a local Widget V3 component naturally.

Use this skill when the current repo already contains a Widget V3 component that came from or resembles `flutter-widget-wallet-mcp`, and the user wants it refreshed.

## Workflow

1. Identify the local Widget V3 component and its related preview and tests.
2. Fetch the latest V3 source-of-truth from MCP: `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`.
3. If unsure whether a newer/renamed equivalent exists, use `search_v3_widgets` first.
4. Diff local behavior against the MCP V3 source behavior.
5. Separate: local intentional customizations, upstream V3 improvements worth taking, and risky breaking changes.
6. Upgrade in small steps, preserving local business-specific customizations where possible.
7. Refresh previews and tests if the public API or major states changed.

## MCP Tools

- `get_v3_widget_metadata`
- `get_v3_widget_code`
- `get_v3_widget_preview`
- `search_v3_widgets`

## Guardrails

- Do not overwrite local intentional customizations without calling them out.
- Prefer selective sync over wholesale replacement.
- If the drift is too large, recommend `flutter-widget-v3-install` plus `flutter-widget-v3-adapt` instead of an in-place upgrade.
- Never use the upgrade path to introduce legacy theme access or move the widget outside `lib/widgets/v3/**`.
