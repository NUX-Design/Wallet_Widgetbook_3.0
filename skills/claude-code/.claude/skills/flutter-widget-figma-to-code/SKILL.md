---
name: flutter-widget-figma-to-code
description: Convert Figma or design-spec intent into a Flutter widget using `flutter-widget-wallet-mcp` patterns, templates, and mappings. Use when there is no good existing widget match or the user wants a fresh implementation from design input.
---

# Flutter Widget Figma To Code

Invoke with `/flutter-widget-figma-to-code` in Claude Code, or describe the design-to-code task naturally.

Use this skill when the user provides Figma or a structured design handoff and wants a new widget implementation rather than reusing an existing one.

## Workflow

1. Read the provided design or handoff carefully.
2. Use `get_figma_to_flutter_mapping` to map design concepts into Flutter structures.
3. Use `get_flutter_widget_template` when a scaffold is needed.
4. Use `generate_widget_code` for first-pass implementation help.
5. Compare against current repo conventions before finalizing the code.
6. Create preview coverage after implementation.

## MCP Tools

- `get_figma_to_flutter_mapping`
- `get_flutter_widget_template`
- `generate_widget_code`
- `get_design_system_info`
- `get_codebase_patterns`

## Guardrails

- Do not assume the generated code is production-ready without adapting it to the target repo.
- Keep layout, API shape, theme integration, and localization explicit.
- If an existing widget is already a near match, prefer `flutter-widget-search` plus `flutter-widget-adapt` over generating from scratch.
