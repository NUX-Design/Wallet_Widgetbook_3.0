---
name: flutter-widget-audit
description: Audit a Flutter widget integration for theme, localization, preview, test, and design-system alignment issues after importing or updating code from `flutter-widget-wallet-mcp`. Use when the user wants a quality pass or review.
---

# Flutter Widget Audit

Invoke with `/flutter-widget-audit` in Claude Code, or ask for a review naturally.

Use this skill for review-style work after widget installation or adaptation.

## Workflow

1. Identify the target widget files, previews, docs, and tests.
2. Read local repo conventions and the widget's MCP metadata.
3. Check for:
   - theme token drift
   - localization bypasses
   - missing previews
   - missing or stale tests
   - props/API mismatches
   - asset path issues
4. Prioritize findings by severity and by likelihood of causing regressions.
5. If asked to fix issues, apply the smallest safe corrections first.

## MCP Tools

- `get_widget_metadata`
- `get_design_system_info`
- `get_codebase_patterns`
- `get_widget_preview`

## Guardrails

- Default to code-review mode: findings first, summary second.
- Focus on bugs, regressions, drift, and missing validation.
- If no findings exist, state that clearly and mention any residual risk such as missing visual verification.
