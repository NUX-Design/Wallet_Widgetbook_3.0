---
name: flutter-widget-v3-figma-to-code
description: Convert Figma or design-spec intent into a Widget V3 component using `flutter-widget-wallet-mcp` Theme V3 patterns, templates, and token mappings. Use when there is no good existing Widget V3 match or the user wants a fresh V3 implementation from design input.
---

# Flutter Widget V3 Figma To Code

Use this skill when the user provides Figma or a structured design handoff and wants a new Widget V3 implementation rather than reusing an existing one.

## Workflow

1. Read the provided design or handoff carefully.
2. Use `get_v3_figma_to_flutter_mapping` to check whether an existing Widget V3 already covers this component; if it does, prefer `flutter-widget-v3-search` + `flutter-widget-v3-install` instead of generating from scratch.
3. Map design colors to semantic tokens with `list_v3_color_tokens` / `search_v3_color_tokens` / `get_v3_color_token` — never hardcode a raw hex value that a semantic token already covers.
4. Use `get_v3_flutter_widget_template` for a V3-prefixed scaffold.
5. When local/stdio MCP is available, optionally use `generate_v3_widget_code` for first-pass implementation help.
6. Compare against `docs/v3/V3_WIDGET_CONVENTIONS.md` before finalizing.
7. Create preview coverage with `flutter-widget-v3-preview` after implementation.

## Remote-Safe Fallback

When connected through Remote MCP, use `get_v3_flutter_widget_template`, token tools, mapping, design-system information, and codebase patterns, then author the first-pass Dart source locally. Do not call `generate_v3_widget_code` or fall back to a legacy generator; validate the locally authored result with the same V3 preview, test, and audit requirements.

## MCP Tools

- `get_v3_figma_to_flutter_mapping`
- `get_v3_flutter_widget_template`
- `generate_v3_widget_code`
- `list_v3_color_tokens`
- `search_v3_color_tokens`
- `get_v3_color_token`
- `get_v3_design_system_info`
- `get_v3_codebase_patterns`

## Guardrails

- Do not assume generated code is production-ready without adapting it to the target repo's actual generated semantic tokens.
- Keep layout, API shape, and Theme V3 integration explicit; no raw `Color(...)` when a semantic token applies.
- If an existing Widget V3 is already a near match, prefer `flutter-widget-v3-search` plus `flutter-widget-v3-adapt` over generating from scratch.
