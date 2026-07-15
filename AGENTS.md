# AGENTS.md

## Purpose

Operational rules for agents working in this repository. This repo is a Flutter design-system/widget library with standalone widget previews (a local Flutter Web preview host for Widget V3), localization generation, and supporting Node/MCP tooling.

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
- Preserve standalone preview usability (and, for Widget V3, that `dart run tool/generate_v3_preview_registry.dart` picks up the preview) when adding or changing reusable widgets.
- When touching a widget, review whether tests and preview files also need updates.
- If you learn a stable fact about architecture, workflows, constraints, or gotchas, append/update it in `MEMORY.md` in the same task.

## Guidance

### Repo Shape

- Main Flutter app entry: `lib/main.dart`
- Standalone widget previews: `lib/widgets/**/preview_*.dart`
- Widget V3 local web preview host entry: `lib/preview_v3/main.dart` (routing/testable classes in `lib/preview_v3/preview_app.dart`, registry in `lib/preview_v3/preview_registry.dart`)
- Theme system: `lib/config/themes/`
- V3 design-system reference: `DESIGN.md`
- Theme V3 architecture plan: `docs/V3_THEME_MCP_SKILLS_PLAN.md`
- Theme V3 execution backlog: `task/V3_THEME_MCP_SKILLS_TASKS.md`
- Widget V3 local web preview plan: `docs/V3_WEB_PREVIEW_PLAN.md`
- Widget V3 local web preview backlog: `task/V3_WEB_PREVIEW_TASKS.md`
- Widget V3 zero-Flutter consumer preview successor plan: `docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md`
- Widget V3 zero-Flutter consumer preview backlog: `task/V3_ZERO_FLUTTER_PREVIEW_TASKS.md`
- Widget V3 Lucide icon adapter plan: `docs/V3_LUCIDE_ICON_PLAN.md`
- Widget V3 Lucide icon adapter backlog: `task/V3_LUCIDE_ICON_TASKS.md`
- Widget V3 zero-Flutter preview frozen contract: `mcp-server/v3/bundle_contract.js` (machine) + `docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md` (human); rollout/rollback: `docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`
- Widget V3 preview publishing/scale guide: `docs/v3/V3_WIDGET_PREVIEW_PUBLISHING_GUIDE.md` — canonical operational workflow for making a new Widget V3 discoverable by the local host, hosted MCP, preview bundle, and `flutter-widget-v3-preview` skill.
- Widget V3 zero-Flutter preview tooling: `scripts/v3-preview-bundle/` (`pack-v3-preview-bundle.mjs` packer, `launch-v3-preview.mjs` repo-independent launcher, `zero-flutter-acceptance.mjs` + `browser-verify.mjs` verifiers); CI `.github/workflows/v3-preview-bundle.yml`; MCP delivery in `mcp-server/v3/bundle_store.js` + `bundle_catalog.js` + `http-server.js` route `/v3/preview-bundle/*`. Generated bundle output `dist/` is gitignored.
- Localization source: `lib/l10n/localization.json`
- Generated localization artifacts: `lib/l10n/*.arb`, `lib/generated/intl/`
- Reusable widgets: `lib/widgets/`
- Flutter tests: `test/`
- Task backlogs: `task/`
- Root documentation/schema tooling: `CODEBASE_CONTEXT.md`, `WIDGETS_GUIDE.md`, `scripts/`, `package.json`, `docs/schema.json`
- MCP helper server: `mcp-server/`

### V3 Design System Context

- Root `DESIGN.md` is the mandatory visual specification for **Wi Design System — DesignBridge** and must be loaded before every Theme V3, Widget V3, V3 preview, or V3-facing UI task.
- It defines V3 design language and intent across Light/Dark colors, typography, spacing/sizing, radius, letter spacing, shadows/effects, component structures, variants, states, responsive behavior, and accessibility-oriented design rules.
- Treat its `Design Rules — Mandatory for AI Agents` section as binding for visual decisions: do not invent colors, typography metrics, arbitrary spacing/radius/shadows, component variants, or undefined states.
- In Flutter code, translate the design intent through the existing Theme V3 APIs. Do not copy CSS custom properties or raw hex values from `DESIGN.md` into widgets when a semantic V3 token/API exists.
- Source ownership is split deliberately:
  1. `DESIGN.md` — normative V3 visual intent and design rules.
  2. Figma node/spec and the widget-local guide — component-specific scope and verified node details.
  3. `lib/config/themes/v3/tokens/**` — editable Flutter implementation inputs.
  4. `lib/config/themes/v3/generated/**` — derived output; never edit manually.
- If these sources disagree, do not silently choose one, approximate a value, or fall back to legacy theme. Record the mismatch, reconcile the editable source with the verified design, regenerate, and validate Light/Dark plus affected previews/tests.

### Theme V3 Planning Boundary

- `docs/V3_THEME_MCP_SKILLS_PLAN.md` is the architecture source of truth for the planned additive Theme V3 + Widget V3 + MCP V3 tools + Skills V3 initiative.
- `task/V3_THEME_MCP_SKILLS_TASKS.md` is the execution checklist and progress source of truth for that initiative.
- Until the V3 task checklist contains verified completed work, do not claim that Theme V3, V3 MCP tools, V3 skills, or Render V3 exposure are implemented.
- The V3 initiative keeps the existing Render service and endpoint (`https://flutter-widget-wallet-mcp.onrender.com/mcp`); it does not create a second Render service.
- Legacy theme files, widgets outside `lib/widgets/v3/`, published MCP tool behavior/contracts, and existing skills are frozen boundaries for V3 work. Existing MCP integration files may be changed only additively when required to register V3 tools, with legacy regression tests as a gate.

### Widget V3 Local Web Preview Planning Boundary

- `docs/V3_WEB_PREVIEW_PLAN.md` is the architecture source of truth for the local Flutter Web preview host that replaced Widgetbook.
- `task/V3_WEB_PREVIEW_TASKS.md` is the execution checklist and progress source of truth for that migration.
- VP-01 through VP-10 are verified complete: the local route works end-to-end, Widgetbook runtime/tooling was removed, MCP V3 returns additive preview route metadata, all three Skills V3 preview packs use the readiness-gated local web flow, and the generated registry supports scaling by convention. Use the checklist evidence rather than inferring completion from this summary.
- The scope remains local-only; do not add online hosting or a second Render service.
- `build/web/**` is generated output and must not be committed.
- `docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md` and `task/V3_ZERO_FLUTTER_PREVIEW_TASKS.md` own the successor work for opening a source-repo Widget V3 preview from a consumer repo that has no Flutter SDK/project/files. Do not reopen or rewrite the completed VP-01 through VP-10 evidence for that work.

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
- For Theme V3 or Widget V3 work, read root `DESIGN.md` before selecting visual rules, component variants, typography, spacing, effects, or semantic token intent; use V3 token JSON/generator/runtime files as the implementation source of truth and reconcile any drift instead of hardcoding around it.
- For Widget V3 local web preview issues, read `lib/preview_v3/main.dart`, `lib/preview_v3/preview_app.dart`, and `lib/preview_v3/preview_registry.dart` before editing preview routing.
- For repo automation or schema tasks, inspect root `package.json`, `scripts/README.md`, `scripts/generate-schema.js`, `scripts/parser.js`, and `docs/schema.json`.

### Widget Documentation And Preview Conventions

- Reusable widget folders commonly contain:
  - implementation `.dart`
  - standalone preview `preview_*.dart`
  - local documentation such as `*_GUIDE.md`, `*_CONTEXT.md`, or `*_spec.md`
- Use the local widget markdown as the nearest documentation source-of-truth for that widget.
- Standalone previews are valid debug entrypoints and can be run directly with `flutter run -t path/to/preview_file.dart`.
- Widget V3 previews are auto-discovered by `dart run tool/generate_v3_preview_registry.dart`, which scans `lib/widgets/v3/**/preview_v3_*.dart` and regenerates `lib/preview_v3/preview_registry.g.dart` so they are reachable through the local web preview host at `http://127.0.0.1:8090/#/<category>/<WidgetClass>`. It derives the class name from the filename (`preview_v3_<widget>.dart` -> `class V3<Widget>Preview` must exist in the file) — no manual registration step. Run the generator after adding or renaming a preview file, and never hand-edit `preview_registry.g.dart`.
- Before adding, renaming, publishing, or troubleshooting a Widget V3 preview, read `docs/v3/V3_WIDGET_PREVIEW_PUBLISHING_GUIDE.md`. A widget is not available to the published preview skill until its source/preview/generated registry are merged to `main`, bundle CI publishes successfully, and the existing Render service reports freshness for the same full commit SHA.

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
5. Validate in both light and dark themes through the widget's standalone preview.

#### Theme V3 Change Playbook

1. Read `docs/V3_THEME_MCP_SKILLS_PLAN.md`.
2. Read `task/V3_THEME_MCP_SKILLS_TASKS.md` and select the smallest unchecked task whose dependencies are complete.
3. Preserve the legacy theme system; V3 source files belong under `lib/config/themes/v3/` and V3 widgets under `lib/widgets/v3/`.
4. Treat V3 token JSON as source input and V3 generated Dart files as derived output.
5. Use V3-prefixed paths/classes/tools/skills and do not silently fall back to legacy theme tokens.
6. Validate Light/Dark parity, alias resolution, generated output, preview/tests, and legacy regression gates appropriate to the task.
7. Update the V3 task timestamp and evidence only after verification succeeds.

#### Widget V3 Local Web Preview Change Playbook

1. Read `docs/v3/V3_WIDGET_PREVIEW_PUBLISHING_GUIDE.md` for new-widget onboarding, publishing, or preview troubleshooting.
2. Read `docs/V3_WEB_PREVIEW_PLAN.md` and `task/V3_WEB_PREVIEW_TASKS.md` when changing preview-host architecture or historical migration scope.
3. Preview routing/testable classes live in `lib/preview_v3/preview_app.dart`; `lib/preview_v3/main.dart` stays a thin entrypoint (only `setUrlStrategy(null)` + `runApp`) because it imports `flutter_web_plugins`, which is incompatible with VM-based `flutter test`.
4. New Widget V3 previews are picked up automatically by naming convention (`preview_v3_<widget>.dart` with `class V3<Widget>Preview`); after adding or renaming one, run `dart run tool/generate_v3_preview_registry.dart` to regenerate `lib/preview_v3/preview_registry.g.dart`. Never hand-edit that file or `lib/preview_v3/preview_registry.dart`'s consumption of it.
5. Validate with `flutter analyze`, `dart run tool/generate_v3_preview_registry.dart --check`, targeted `flutter test test/preview_v3/ test/tool/`, `flutter build web --release -t lib/preview_v3/main.dart`, and a real run via `scripts/serve-v3-preview.sh` plus `curl -I` against the served bundle.
6. For published consumer availability, merge to `main`, confirm bundle CI/release success, deploy the same commit on the existing Render service, keep `MCP_REMOTE_COMMIT_SHA` equal to that commit, and require `/info.previewBundle` plus `verify:mcp:remote:v3` to pass before claiming the Skill can show the new widget.
7. Update the V3 web preview task timestamp and evidence only when the task actually changes that completed backlog; ordinary new-widget onboarding should not rewrite historical VP-01–VP-10 evidence.

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
8. For Widget V3 local HTML/browser preview or Widgetbook removal, use `task/V3_WEB_PREVIEW_TASKS.md`; do not append that work to the completed Theme V3 backlog.
9. For Lucide package integration, Figma icon mapping, SVG overrides, or the shared V3 icon adapter, use `task/V3_LUCIDE_ICON_TASKS.md` and preserve Widget-typed icon slots in reusable Widget V3 APIs.

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
