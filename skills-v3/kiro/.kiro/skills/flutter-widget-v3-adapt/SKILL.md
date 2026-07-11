---
name: flutter-widget-v3-adapt
description: Adapt a transplanted Widget V3 component so it matches the target repo's Theme V3 semantic tokens, file structure, and Widget V3 coding patterns. Use after a V3 widget has been imported but still feels foreign to the host project.
---

# Flutter Widget V3 Adapt

Use this skill from Kiro by selecting the skill directly or by asking to adapt an imported Widget V3 component naturally.

Use this skill after code extraction when a Widget V3 component exists locally but still needs to be made native to the host repo's Theme V3.

## Workflow

1. Read the local host repo's `V3ThemeScope` / semantic token catalog first.
2. Read `get_v3_codebase_patterns` and `get_v3_design_system_info` from MCP for V3 source expectations.
3. Compare the local repo's V3 conventions against the extracted widget.
4. If a needed semantic token is unclear, use `search_v3_color_tokens` or `get_v3_color_token`.
5. Normalize imports, semantic token usage, naming, constructor shape, and preview data to match `docs/v3/V3_WIDGET_CONVENTIONS.md`.
6. Keep behavior intact while making the implementation native to the target repo's Theme V3.

## MCP Tools

- `get_v3_codebase_patterns`
- `get_v3_design_system_info`
- `get_v3_color_token`
- `search_v3_color_tokens`
- `get_v3_widget_metadata`

## Guardrails

- Adapt to the host repo's own generated V3 semantic tokens; never reuse the source repo's generated `V3PrimitiveColors`/`V3ColorPalette` values directly.
- Never fall back to legacy `ThemeColors.get()` or legacy theme files, even temporarily.
- Preserve functional behavior first, then improve style alignment.
- If the host repo lacks a semantic token the widget needs, stop and report the gap instead of inventing a raw `Color(...)`.
