---
name: flutter-widget-adapt
description: Adapt a transplanted widget so it matches the target Flutter repo's theme, tokens, localization, file structure, and coding patterns. Use after a widget has been imported but still feels foreign to the host project.
---

# Flutter Widget Adapt

Use this skill after code extraction when the widget exists locally but still needs to be made native to the host repo.

## Workflow

1. Read the local host repo patterns first:
   - theme structure
   - localization strategy
   - folder conventions
   - preview or Widgetbook patterns
2. Read `get_codebase_patterns` and `get_design_system_info` from MCP for source expectations.
3. Compare the local repo patterns against the extracted widget.
4. Normalize:
   - imports
   - token usage
   - naming
   - constructor shape
   - preview data
   - localized strings
5. Keep behavior intact while making the implementation look native to the target repo.

## MCP Tools

- `get_codebase_patterns`
- `get_design_system_info`
- `get_color_token`
- `get_widget_metadata`

## Guardrails

- Adapt to the host repo's source-of-truth tokens; do not force the source repo's theme system where it does not belong.
- Preserve functional behavior first, then improve style alignment.
- When the host repo already has a better local primitive, prefer wrapping or translating into it rather than duplicating a parallel system.
