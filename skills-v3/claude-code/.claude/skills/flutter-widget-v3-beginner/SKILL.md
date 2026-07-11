---
name: flutter-widget-v3-beginner
description: Scan the current workspace for Theme V3 foundation and Widget V3 coverage, then bootstrap or extend Widget V3 using `flutter-widget-wallet-mcp`. Use when a workspace may or may not already have Theme V3 / Widget V3 and the user wants guided setup with explicit scope questions before any edits.
---

# Flutter Widget V3 Beginner

Invoke with `/flutter-widget-v3-beginner` in Claude Code, or ask Claude to scan and bootstrap Theme V3 / Widget V3 usage naturally.

Use this skill when the user wants to start using Theme V3 / Widget V3 tools from `flutter-widget-wallet-mcp` in a workspace that may already have Theme V3 foundation, may only have legacy theme/widgets, or may need a brand-new Widget V3 added.

This skill only touches `lib/widgets/v3/**` and `test/widgets/v3/**`. It never edits legacy theme or legacy widgets, and it never creates a new Theme V3 foundation on its own.

## Mandatory Flow

Always run in this order:

1. Ask discovery questions.
2. Scan the workspace.
3. Summarize what exists and what is missing.
4. Ask for confirmation on the execution plan.
5. Execute only the confirmed scope.

Never edit the repo before the question flow completes.

## Discovery Questions

### 1. Goal

Question: `รอบนี้ต้องการให้ flutter-widget-v3-beginner ทำอะไร`

Options:

- `scan-only` — analyze existing Theme V3 / Widget V3 state only, create nothing, edit nothing, return a gap report.
- `bootstrap-existing` — the workspace already has Theme V3 foundation (`lib/config/themes/v3/generated/`); add a new Widget V3 or fill in missing preview/test/guide for an existing one.
- `bootstrap-new` — if no Theme V3 foundation exists at all, stop here. This skill does not create Theme V3 foundation; it only adds widgets on top of an existing one. Recommend the Theme V3 generator workflow in `docs/V3_THEME_MCP_SKILLS_PLAN.md` (Phase 2-3) instead.

### 2. Workspace State Preference

Question: `สภาพ workspace ตอนนี้เป็นแบบไหน หรืออยากให้ skill ตีความแบบไหน`

Options: `existing-v3-foundation`, `no-v3-foundation-yet`, `auto-detect` (safest default; let the scan decide).

### 3. Target Widget Scope

Question: `ต้องการเพิ่ม/แก้ widget V3 ตัวไหน`

Options: an explicit widget name, or `auto` to let the skill pick from `search_v3_widgets` / `list_v3_widgets`, preferring a widget not yet present in the target repo's `lib/widgets/v3/**`.

### 4. Change Policy

Question: `ให้ skill แตะ repo ได้ระดับไหน`

Options: `additive-only`, `allow-structure-setup`, `ask-before-overwrite` — same meaning as the legacy skill, scoped only to `lib/widgets/v3/**` and `test/widgets/v3/**`.

## Workspace Scan

Inspect at least:

- `lib/config/themes/v3/generated/` (Theme V3 foundation readiness)
- `lib/widgets/v3/**` existing widgets and their category/pattern
- `test/widgets/v3/**` and `preview_v3_*.dart` coverage
- whether the target widget already exists (if so, prefer `flutter-widget-v3-upgrade` or `flutter-widget-v3-adapt` instead)

## Summary And Confirmation

Summarize before editing: whether Theme V3 foundation exists, what Widget V3 already exists, what will be created/edited, and any risk (most commonly: missing Theme V3 foundation). Then ask:

Question: `จากสิ่งที่สแกนพบ จะให้ดำเนินการตามแผนนี้หรือไม่`

Options: `proceed`, `revise-scope`, `stop-after-scan`.

## Execute

- If the target widget already exists in the MCP V3 catalog: use `get_v3_widget_metadata`, `get_v3_widget_code`, and `get_v3_widget_preview`.
- If it does not exist yet: use `get_v3_flutter_widget_template` to scaffold. When local/stdio MCP is available, `generate_v3_widgetbook_use_case` may optionally produce preview wiring.
- Follow `docs/v3/V3_WIDGET_CONVENTIONS.md` for file layout, naming, and the required `V3 Metadata` guide section.

## Remote-Safe Fallback

When connected through Remote MCP, keep using the remotely exposed `get_v3_flutter_widget_template`, metadata, token, code, and preview tools. Author the Widgetbook use case or standalone preview locally from those read-only results and the target repo conventions; do not call `generate_v3_widgetbook_use_case`, silently switch to a legacy tool, or stop an otherwise valid workflow.

## MCP Tools

- `get_v3_design_system_info`
- `get_v3_codebase_patterns`
- `list_v3_categories`
- `search_v3_widgets`
- `get_v3_widget_metadata`
- `get_v3_widget_code`
- `get_v3_widget_preview`
- `get_v3_flutter_widget_template`
- `generate_v3_widgetbook_use_case`

## Guardrails

- Never assume Theme V3 foundation exists without scanning for `lib/config/themes/v3/generated/`.
- Never create Theme V3 foundation as a side effect of this skill; that is a separate, explicitly-scoped task.
- Never touch widgets or theme files outside `lib/widgets/v3/**` / `test/widgets/v3/**`.
- Never fall back to legacy MCP tools or `ThemeColors.get()` when V3 data is missing; report the gap instead.
- If the repo has no Flutter project at all, stop and say so — this skill assumes an existing Flutter app with room for Theme V3 already in place or explicitly out of scope.
