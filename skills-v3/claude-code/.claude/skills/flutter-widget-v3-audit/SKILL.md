---
name: flutter-widget-v3-audit
description: Audit a Widget V3 integration for legacy theme leakage, raw colors, missing V3ThemeScope usage, preview, and design-system alignment issues after importing or updating a component from `flutter-widget-wallet-mcp`. Use when the user wants a Theme V3 quality pass or review.
---

# Flutter Widget V3 Audit

Invoke with `/flutter-widget-v3-audit` in Claude Code, or ask for a Widget V3 quality review naturally.

Use this skill for review-style work after Widget V3 installation or adaptation.

## Workflow

1. Identify the target Widget V3 files, preview, docs, and tests under `lib/widgets/v3/**` / `test/widgets/v3/**`.
2. Run `audit_v3_widget` to check for legacy theme imports, raw `Color(...)` literals, missing `V3ThemeScope` usage, missing preview, and missing semantic-token metadata.
3. Read `get_v3_widget_metadata`, `get_v3_design_system_info`, and `get_v3_codebase_patterns` to compare against convention.
4. Check `get_v3_widget_preview` still renders and covers Light/Dark.
5. Prioritize findings by severity and by likelihood of causing visual or theme-consistency regressions.
6. If asked to fix issues, apply the smallest safe corrections first and stay inside `lib/widgets/v3/**`.

## MCP Tools

- `audit_v3_widget`
- `get_v3_widget_metadata`
- `get_v3_design_system_info`
- `get_v3_codebase_patterns`
- `get_v3_widget_preview`

## Guardrails

- Default to code-review mode: findings first, summary second.
- Focus on Theme V3 drift, legacy leakage, missing previews/tests, and props/API mismatches.
- If no findings exist, state that clearly and mention any residual risk such as missing visual verification.
- Never "fix" a finding by reintroducing legacy theme access; fixes must stay on `V3ThemeScope.colorsOf(context)`.
