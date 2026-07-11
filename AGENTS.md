# AGENTS.md

## Purpose

Operational rules for agents working in this repository. This repo is a Flutter design-system/widget library with Widgetbook previews, localization generation, and supporting Node/MCP tooling.

## Required Read Order

1. Read `AGENTS.md` first on every task, without exception.
2. Read `MEMORY.md` next on every task, without exception.
3. Read the user request and identify the smallest relevant scope.
4. Read the nearest source-of-truth files for that scope before changing code.
5. Re-read and update `MEMORY.md` before finishing when you discover durable project knowledge that will matter in future tasks.

## Guardrails

- Treat `MEMORY.md` as mandatory context. Do not start implementation before reading it.
- Do not edit generated files unless the task explicitly requires regenerated output.
- Prefer changing source-of-truth inputs, then regenerate derived artifacts.
- Treat live source files and this repo's local agent docs as higher-trust than broad project overviews when they disagree.
- Do not hardcode colors that should come from the theme token system.
- Do not bypass localization by introducing user-facing strings directly into reusable widgets when localized text is expected.
- Do not remove or overwrite user changes outside the requested scope.
- Keep Flutter widget behavior compatible with both light and dark themes unless the component is intentionally single-theme.
- Preserve Widgetbook usability when adding or changing reusable widgets.
- When touching a widget, review whether tests and preview files also need updates.
- If you learn a stable fact about architecture, workflows, constraints, or gotchas, append/update it in `MEMORY.md` in the same task.

## Guidance

### Repo Shape

- Main Flutter app entry: `lib/main.dart`
- Widgetbook entry: `lib/widgetbook.dart`
- Widgetbook registry: `lib/widgetbook_use_cases.dart`, `lib/widgetbook.directories.g.dart`
- Standalone widget previews: `lib/widgets/**/preview_*.dart`
- Theme system: `lib/config/themes/`
- Theme V3 architecture plan: `docs/V3_THEME_MCP_SKILLS_PLAN.md`
- Theme V3 execution backlog: `task/V3_THEME_MCP_SKILLS_TASKS.md`
- Localization source: `lib/l10n/localization.json`
- Generated localization artifacts: `lib/l10n/*.arb`, `lib/generated/intl/`
- Reusable widgets: `lib/widgets/`
- Flutter tests: `test/`
- Task backlogs: `task/`
- Root documentation/schema tooling: `CODEBASE_CONTEXT.md`, `WIDGETS_GUIDE.md`, `scripts/`, `package.json`, `docs/schema.json`
- MCP helper server: `mcp-server/`

### Theme V3 Planning Boundary

- `docs/V3_THEME_MCP_SKILLS_PLAN.md` is the architecture source of truth for the planned additive Theme V3 + Widget V3 + MCP V3 tools + Skills V3 initiative.
- `task/V3_THEME_MCP_SKILLS_TASKS.md` is the execution checklist and progress source of truth for that initiative.
- Until the V3 task checklist contains verified completed work, do not claim that Theme V3, V3 MCP tools, V3 skills, or Render V3 exposure are implemented.
- The V3 initiative keeps the existing Render service and endpoint (`https://flutter-widget-wallet-mcp.onrender.com/mcp`); it does not create a second Render service.
- Legacy theme files, widgets outside `lib/widgets/v3/`, published MCP tool behavior/contracts, and existing skills are frozen boundaries for V3 work. Existing MCP integration files may be changed only additively when required to register V3 tools, with legacy regression tests as a gate.

### Trust Order For Context

When documentation conflicts, trust sources in this order:
1. `AGENTS.md`
2. `MEMORY.md`
3. live source code and build scripts
4. local widget guide/spec/context markdown next to the widget
5. root overview docs such as `README.md`, `CODEBASE_CONTEXT.md`, `WIDGETS_GUIDE.md`

Reason: repo-level overview docs may lag behind the live Flutter structure.

### File Reading Strategy

- For repo-level context, architecture overviews, and documentation/schema work, read `CODEBASE_CONTEXT.md` after `MEMORY.md` and before other broad overview docs.
- For widget work, read the widget source, its preview file, related tests, and any local guide/spec markdown next to it.
- For localization work, read `lib/l10n/localization.json`, `tool/generate_arb.dart`, and `l10n.yaml`.
- For theme/token work, read `lib/config/themes/theme_color.dart` and related theme files first.
- For Widgetbook issues, read `lib/widgetbook.dart` and `lib/widgetbook_use_cases.dart` before editing widget previews.
- For repo automation or schema tasks, inspect root `package.json`, `scripts/README.md`, `scripts/generate-schema.js`, `scripts/parser.js`, and `docs/schema.json`.

### Widget Documentation And Preview Conventions

- Reusable widget folders commonly contain:
  - implementation `.dart`
  - standalone preview `preview_*.dart`
  - local documentation such as `*_GUIDE.md`, `*_CONTEXT.md`, or `*_spec.md`
- Use the local widget markdown as the nearest documentation source-of-truth for that widget.
- Standalone previews are valid debug entrypoints and can be run directly with `flutter run -t path/to/preview_file.dart`.
- `lib/widgetbook_use_cases.dart` is the manual use-case source file for Widgetbook annotations.
- `lib/widgetbook.directories.g.dart` is generated from Widgetbook/build_runner and must not be edited manually.

### Documentation Schema Pipeline

- `docs/schema.json` is generated output. Do not edit it by hand.
- Schema generation reads:
  - `CODEBASE_CONTEXT.md`
  - `WIDGETS_GUIDE.md`
  - every markdown file under `lib/widgets/`
- The parser currently discovers widget docs using markdown structure, especially level-2 widget headings and property tables.
- If a task changes widget documentation or schema-facing docs and the downstream schema matters, regenerate with `npm run generate-schema`.

### Agent Playbooks

Use these default execution recipes unless the user explicitly asks for a different flow.

#### Widget Change Playbook

1. Read `MEMORY.md`.
2. Read the target widget `.dart`.
3. Read its local preview file.
4. Read its local guide/spec/context markdown.
5. Read related tests under `test/` if they exist.
6. Edit the widget first, then preview/tests/docs as needed.
7. Validate with the narrowest relevant command:
   - `flutter analyze`
   - targeted `flutter test`
   - direct preview run via `flutter run -t ...`
8. Update `MEMORY.md` if a new durable pattern or constraint was discovered.

#### Localization Change Playbook

1. Read `lib/l10n/localization.json`.
2. Read `tool/generate_arb.dart`.
3. Read `l10n.yaml`.
4. Edit `lib/l10n/localization.json` only.
5. Regenerate:
   - `dart run tool/generate_arb.dart`
   - `flutter gen-l10n`
6. Verify consuming widgets/tests only if the change affects runtime behavior.

#### Theme / Token Change Playbook

1. Read `lib/config/themes/theme_color.dart`.
2. Read `lib/config/themes/base_theme.dart`.
3. Read the consuming widgets.
4. Change tokens or theme primitives before changing many widgets individually.
5. Validate in both light and dark themes through preview or Widgetbook.

#### Theme V3 Change Playbook

1. Read `docs/V3_THEME_MCP_SKILLS_PLAN.md`.
2. Read `task/V3_THEME_MCP_SKILLS_TASKS.md` and select the smallest unchecked task whose dependencies are complete.
3. Preserve the legacy theme system; V3 source files belong under `lib/config/themes/v3/` and V3 widgets under `lib/widgets/v3/`.
4. Treat V3 token JSON as source input and V3 generated Dart files as derived output.
5. Use V3-prefixed paths/classes/tools/skills and do not silently fall back to legacy theme tokens.
6. Validate Light/Dark parity, alias resolution, generated output, preview/tests, and legacy regression gates appropriate to the task.
7. Update the V3 task timestamp and evidence only after verification succeeds.

#### Widgetbook Change Playbook

1. Read `lib/widgetbook.dart`.
2. Read `lib/widgetbook_use_cases.dart`.
3. Confirm whether the task touches manual use cases, generated directories, or both.
4. Edit manual sources only.
5. Regenerate `lib/widgetbook.directories.g.dart` with `dart run build_runner build --delete-conflicting-outputs` when needed.
6. Do not hand-edit `lib/widgetbook.directories.g.dart`.

#### Documentation / Schema Change Playbook

1. Identify whether the task changes:
   - widget-local docs
   - `WIDGETS_GUIDE.md`
   - `CODEBASE_CONTEXT.md`
   - agent docs such as `AGENTS.md` / `MEMORY.md`
2. Treat widget-local docs as nearest source for component behavior.
3. If schema-consuming docs changed and downstream schema matters, run `npm run generate-schema`.
4. Never hand-edit `docs/schema.json`.
5. If you discover doc drift against live code, fix or clearly encode the trust order in agent docs.

#### Task Backlog Playbook

1. Read the relevant backlog under `task/` when the user asks for roadmap, checklist, or execution tracking.
2. Treat `task/TASKS.md` as the current MCP production-ready backlog source of truth.
3. When the user asks what the latest work is, what was done most recently, or current progress, answer from `task/TASKS.md` by inspecting the latest checklist state together with the `อัปเดตล่าสุดเมื่อ` timestamp.
4. If a backlog file moves or its ownership changes, update both `AGENTS.md` and `MEMORY.md` in the same task.
5. `mcp-server/RENDER_HOSTING_PLAN.md` is the design doc for hosting the MCP remote endpoint on Render for multi-client zero-clone access, backed by a checked-in `render.yaml` Blueprint at repo root; its execution checklist lives in `task/TASKS.md` under "Phase 8: Render Hosting Pilot". This is a pilot/proposal separate from the already-closed production-ready plan — do not treat it as done until `task/TASKS.md` Phase 8 checkboxes are checked. `mcp-server/KOYEB_HOSTING_PLAN.md` is a superseded historical reference only (Koyeb closed its free tier to new users in early 2026); do not propose it as an active plan.
6. For Theme V3, Widget V3, MCP V3 tools, Skills V3, or their Render rollout, use `task/V3_THEME_MCP_SKILLS_TASKS.md` instead of appending work to `task/TASKS.md`.
7. When asked for V3 progress, inspect the V3 checklist timestamp, checkboxes, dependencies, and attached evidence; do not infer progress from the architecture plan alone.

### Change Workflow

1. Read `MEMORY.md`.
2. Inspect only the files relevant to the request.
3. Edit source files.
4. Regenerate artifacts only when needed.
5. Run the narrowest useful verification first, then broader verification if the change warrants it.
6. Update `MEMORY.md` if new durable knowledge was discovered.

### Verification Guidance

- Preferred checks:
  - `flutter analyze`
  - `flutter test`
  - `dart run build_runner build --delete-conflicting-outputs`
  - `dart run tool/generate_arb.dart`
  - `flutter gen-l10n`
  - `flutter run -t lib/widgets/.../preview_*.dart -d <device>` for standalone widget preview validation
  - `npm run generate-schema` when schema-facing docs changed
- If Flutter commands fail because of SDK/cache permissions or environment issues, report that explicitly.

## Claude Code Slash Commands Reference

- เมื่อผู้ใช้ถามเรื่อง `Claude Code slash commands` ให้ใช้อ้างอิง knowledge base ที่อยู่ที่ `/Users/Niwat.yah/Documents/Obsidian Vault/Claude-Slash/claude-code-slash-commands-cheatsheet.md`
- ใช้ไฟล์นั้นเป็น source สำหรับคำอธิบาย/คำแนะนำเกี่ยวกับ slash commands แทนการบันทึกรายการคำสั่งทั้งหมดไว้ใน `AGENTS.md`
- หากต้องการยืนยันว่าคำสั่งใดใช้ได้จริงในเครื่อง ให้ตรวจด้วย `/help` และ `/release-notes` เสมอ เพราะ availability เปลี่ยนตาม version, platform และ plan

## Render P8-01 Knowledge Base

- เมื่อผู้ใช้ถามหรือให้ทำซ้ำ workflow เรื่อง Render hosting pilot ของ `P8-01` ให้ใช้อ้างอิง knowledge base ในโฟลเดอร์ `/Users/Niwat.yah/Documents/Obsidian Vault/MCP Knowledge/`
- ใช้โฟลเดอร์นั้นเป็นที่เก็บคู่มือ step-by-step สำหรับการ deploy `flutter-widget-wallet-mcp` ขึ้น Render, การตั้งค่า env vars/secret, การตรวจ `/health` และ `/info`, และปัญหาที่เคยเจอจริงในรอบ deploy แรก
- ถ้ามีการเปลี่ยน workflow จริงของ Render pilot หรือค่า config source-of-truth ใน repo ให้ปรับ knowledge base ในโฟลเดอร์นั้นและ `MEMORY.md` ในงานเดียวกัน

## Code Conventions

### Flutter and Dart

- Follow `flutter_lints`.
- Prefer small reusable widgets and clear constructor APIs.
- Use `const` where practical.
- Keep public widget APIs explicit and predictable.
- Use `ThemeColors.get(...)` and existing theme primitives instead of raw color literals for design-system UI.
- Reuse `BaseTheme`, providers, and existing token naming patterns rather than introducing parallel theme systems.
- Exception for explicitly scoped V3 work: follow `docs/V3_THEME_MCP_SKILLS_PLAN.md`, use V3 semantic APIs under `lib/config/themes/v3/`, and keep V3 imports out of legacy widgets.
- Keep user-facing copy localization-friendly.

### Localization

- `lib/l10n/localization.json` is the editable source of truth.
- ARB files and generated localization Dart files are derived outputs.
- If adding strings, update the source JSON first, then regenerate.
- Respect the existing language mapping, including `MM -> my` in the generator.

### Widget Structure

- Keep related files grouped together: widget, preview, guide/spec, and tests.
- Maintain preview coverage for reusable components.
- Prefer theme-aware and size-aware implementations for shared widgets.

### Documentation

- Update nearby guide/spec markdown when a component API or behavior changes materially.
- When editing widget docs, remember they may feed `docs/schema.json` through the root schema generator.
- Record durable repo knowledge in `MEMORY.md`, not in ad hoc notes.

## Memory Update Policy

Update `MEMORY.md` whenever you discover:

- a stable architectural decision
- a source-of-truth rule
- a generate/build/test command that is actually used
- a repo-specific constraint or gotcha
- a directory ownership boundary
- a recurring failure mode or verification caveat

Do not add temporary task chatter, speculative notes, or one-off debugging noise.
