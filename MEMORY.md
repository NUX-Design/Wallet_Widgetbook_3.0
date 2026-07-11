# MEMORY.md

## Project Snapshot

- Repository type: Flutter widget/design-system repository with a runnable demo app and Widgetbook catalog.
- Primary domain: reusable UI components for a financial app.
- Main package name: `mcp_test_app`
- MCP package/server name for cross-repo widget access: `flutter-widget-wallet-mcp`
- Verified on review date: 2026-06-25

## Core Entry Points

- App entry: `lib/main.dart`
- Widgetbook entry: `lib/widgetbook.dart`
- Widgetbook directories registry: `lib/widgetbook.directories.g.dart`
- Widgetbook use cases file: `lib/widgetbook_use_cases.dart`

## Architecture Summary

- `lib/widgets/` contains reusable UI components, grouped by feature/widget family.
- Most widget folders include:
  - implementation `.dart`
  - preview `.dart`
  - local guide/spec markdown
- `lib/config/themes/` contains the design token system and theme setup.
- `lib/providers/` currently contains app-level `ThemeProvider` and `LocaleProvider`.
- `lib/l10n/` contains editable localization source plus generated ARB inputs.
- `lib/generated/intl/` contains generated localization Dart output.

## Source Of Truth Rules

### Localization

- Editable source of truth: `lib/l10n/localization.json`
- Generator: `tool/generate_arb.dart`
- Generated outputs:
  - `lib/l10n/app_*.arb`
  - `lib/generated/intl/app_localizations*.dart`
- Language mapping in generator:
  - `EN -> en`
  - `TH -> th`
  - `RU -> ru`
  - `ZH -> zh`
  - `MM -> my`

### Theme And Design Tokens

- Central token accessor: `ThemeColors.get(theme, token)`
- Token definitions live in `lib/config/themes/theme_color.dart`
- Base color schemes live in `lib/config/themes/base_theme.dart`
- Shared UI should use theme tokens instead of hardcoded colors where possible.
- A separate additive Theme V3 initiative is in progress. Its architecture source of truth is `docs/V3_THEME_MCP_SKILLS_PLAN.md`, and its execution/progress source of truth is `task/V3_THEME_MCP_SKILLS_TASKS.md`; V3-01 through V3-21 are verified complete while Render rollout remains unimplemented.
- The planned V3 boundary keeps legacy theme files and widgets unchanged, places V3 theme code under `lib/config/themes/v3/`, and places V3 widgets under `lib/widgets/v3/`.
- Planned V3 inputs are Figma/DTCG primitive plus semantic Light/Dark JSON tokens; V3 widgets should consume semantic colors through a V3-prefixed API rather than `ThemeColors.get()`.
- V3 change boundaries are enforced by `npm run check:v3-boundaries` with unit coverage from `npm run test:v3-boundaries`. The checker blocks legacy theme use inside V3 theme code, V3 imports from legacy widgets, and legacy `skills/**` changes when a diff contains V3 work. Flutter CI supplies the PR/push base SHA so changed-path checks cover committed diffs; `docs/v3/V3_REVIEW_CHECKLIST.md` is the reviewer source for frozen files and additive-only MCP integration boundaries.
- Theme V3 editable token inputs now use the direct Figma exports under `lib/config/themes/v3/tokens/`: 145 top-level primitive colors and matching Light/Dark semantic catalogs of 55 paths each. The semantic exports include alias chains such as `Button → Core → primitive`; `V3TokenResolver` resolves these chains with cycle detection. `background/primary` resolves to Light `Blue/50` (`#FBFCFF`) and Dark `Slate/950` (`#020617`). Generated Dart outputs live under `lib/config/themes/v3/generated/` and must be refreshed with `dart run lib/config/themes/v3/v3_theme_generator.dart` rather than edited manually.
- Theme V3 parsing/validation is implemented in `v3_token_parser.dart` and `v3_token_resolver.dart`; it supports DTCG/Figma color values and aliases, deterministic path/property normalization, alias resolution/cycle detection, missing targets, duplicate paths, Light/Dark parity, and Dart property collision checks. `V3ThemeScope.colorsOf(context)` selects generated semantic palettes from Flutter brightness without changing legacy `ThemeData`.
- `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx` is the detailed architecture and maintenance guide for Theme V3; `lib/config/themes/v3/README.md` remains the short quick-start entrypoint.
- Widget V3 conventions live in `docs/v3/V3_WIDGET_CONVENTIONS.md`: V3 widgets use `lib/widgets/v3/<category>/v3_<widget>.dart`, standalone `preview_v3_<widget>.dart`, a `V3_<WIDGET>_GUIDE.md` metadata guide, and targeted tests under `test/widgets/v3/<category>/`; colors must come from `V3ThemeScope.colorsOf(context)` and user-facing copy remains caller-owned.
- `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` is the mandatory creation context for all Widget V3 work. It links bidirectionally with `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx` and defines the Figma-to-token-to-widget workflow, file/API/accessibility conventions, preview/test/metadata requirements, verification commands, and Definition of Done.
- The verified Widget V3 pilot is `V3MiniButton` under `lib/widgets/v3/button/`, scoped only to Figma Size=Mini with Primary/Outline/Ghost variants, Default/Active/Disabled/Error states, left/right icon slots, Light/Dark standalone preview, generated Widgetbook registration, local token metadata, and accessibility/state coverage. Pilot QA evidence is in `docs/v3/V3_WIDGET_PILOT_AUDIT.md`.
- `V3MiniButton` design source of truth is the 12 `Wi Design System` Mini Button nodes in file key `mhUvPg9tOjlvQvEW6glQhJ` recorded in `V3_MINI_BUTTON_GUIDE.md`; those nodes replace aggregate node `18:1764` as the pilot's visual/state SOT.
- Skills V3 (Phase 6, `V3-19` to `V3-21`) is implemented: `docs/v3/V3_SKILLS_SPEC.md` is the canonical spec for 8 V3 skills (`flutter-widget-v3-beginner/-search/-install/-adapt/-preview/-figma-to-code/-audit/-upgrade`), each mapped 1:1 to a legacy skill but routed exclusively to the 17 V3-prefixed MCP tools in `mcp-server/v3/tool_contracts.js` and scoped only to `lib/widgets/v3/**`/`test/widgets/v3/**`. Native packs live under `skills-v3/codex/.codex/skills/` (SKILL.md + `agents/openai.yaml` per skill, matching legacy Codex layout), `skills-v3/claude-code/.claude/skills/` (SKILL.md only + pack README, no `agents/openai.yaml`), and `skills-v3/kiro/.kiro/skills/` (same native shape as Claude Code). `flutter-widget-v3-beginner` keeps the legacy `ask → scan → summarize → confirm → execute` mandatory flow but never creates Theme V3 foundation itself; it only adds/extends widgets once `lib/config/themes/v3/generated/` already exists.
- `docs/v3/V3_SKILLS_VALIDATION.md` records real tool-call evidence for all 8 Skills V3 workflows. Repeatable validation lives at `scripts/validate-v3-skills.js`, runs via `npm run validate:v3-skills`, and is a Flutter CI gate covering 3 packs × 8 skills, metadata, V3-only tool routing, beginner markers, remote-safe fallbacks, and remote generation-tool exclusions. `generate_v3_widget_code`/`generate_v3_widgetbook_use_case` remain optional local/stdio optimizations; Remote MCP workflows author source locally from read-only V3 template/metadata/token/code/preview results without legacy fallback.
- `scripts/check-v3-boundaries.js` flags any diff touching legacy `skills/**` whenever a diff also contains V3 work; Skills V3 additions must stay entirely under `skills-v3/**` to pass `npm run check:v3-boundaries` (run from repo root, not `mcp-server/`).

### Widgetbook

- Widgetbook is a first-class workflow for previewing reusable widgets.
- Additions or changes to shared widgets should consider preview coverage.
- The catalog depends on generated directories and registered use cases.
- `lib/widgetbook_use_cases.dart` is the manual annotation/use-case file.
- `lib/widgetbook.directories.g.dart` is generated output from Widgetbook/build_runner and should not be edited manually.

### Widget Documentation And Schema

- Widget folders commonly use the pattern: implementation widget + standalone preview + local markdown guide/spec/context.
- Standalone previews under `lib/widgets/**/preview_*.dart` are valid Flutter entrypoints for manual debug runs.
- `docs/schema.json` is generated from root docs plus widget-local markdown files.
- The schema generator reads `CODEBASE_CONTEXT.md`, `WIDGETS_GUIDE.md`, and markdown files under `lib/widgets/`.
- `docs/schema.json` should be regenerated with `npm run generate-schema` when schema-facing docs change and the task depends on updated schema output.

### Documentation Trust Order

- Task startup order begins with `AGENTS.md`, then `MEMORY.md`, before any scope-specific source files.
- `CODEBASE_CONTEXT.md` is a lower-trust root overview doc; read it only after `MEMORY.md` when a task needs repo-level context, docs, or schema orientation.
- Highest trust: `AGENTS.md`, then `MEMORY.md`, then live source/build scripts.
- Lower trust: broad overview docs such as `README.md`, `CODEBASE_CONTEXT.md`, and `WIDGETS_GUIDE.md`, which may lag behind the current code layout.

## Key Commands

### Flutter

- Install deps: `flutter pub get`
- Run app: `flutter run`
- Run Widgetbook: `flutter run -t lib/widgetbook.dart -d chrome`
- Analyze: `flutter analyze`
- Test: `flutter test`
- Generate Widgetbook/build output: `dart run build_runner build --delete-conflicting-outputs`

### Localization

- Generate ARB from JSON: `dart run tool/generate_arb.dart`
- Generate localizations: `flutter gen-l10n`

### Node Tooling

- Root schema generation: `npm run generate-schema`
- Watch schema generation: `npm run generate-schema:watch`
- MCP server: `cd mcp-server && npm start`
- MCP hosted HTTP server: `cd mcp-server && npm run start:http`
- MCP server tests: `cd mcp-server && npm test`
- MCP syntax check: `cd mcp-server && npm run check:mcp-syntax`
- MCP inspector verification: `cd mcp-server && npm run verify:mcp`
- MCP hosted HTTP verification: `cd mcp-server && npm run verify:mcp:http`
- MCP real hosted endpoint verification (Phase 8 / Render pilot): `cd mcp-server && MCP_REMOTE_BASE_URL="https://<host>/mcp" MCP_REMOTE_PROXY_SHARED_SECRET="<secret>" npm run verify:mcp:remote`
- MCP evaluation suite: `cd mcp-server && npm run evaluate:mcp`
- MCP onboarding validation: `cd mcp-server && npm run validate:onboarding`
- MCP CI parity workflow: `cd mcp-server && npm run ci:mcp`
- MCP snapshot refresh: `cd mcp-server && npm run test:update-snapshots`
- MCP inspector CLI verification: `cd mcp-server && node node_modules/@modelcontextprotocol/inspector-cli/build/index.js node index.js --method tools/list`
- MCP installer example output: `cd mcp-server && node install.js`
- MCP installer write-to-config: `cd mcp-server && node install.js --settings /absolute/path/to/mcp.json`
- Standalone widget preview: `flutter run -t lib/widgets/<folder>/preview_<name>.dart -d <device>`
- Browser-friendly preview inspection: `flutter run -t lib/widgets/<folder>/preview_<name>.dart -d web-server --web-hostname 127.0.0.1 --web-port <port>`

### Claude Code Reference

- Local knowledge base for Claude Code slash commands: `/Users/Niwat.yah/Documents/Obsidian Vault/Claude-Slash/claude-code-slash-commands-cheatsheet.md`
- Use that file as the reference source when the user asks about Claude Code slash commands; keep `AGENTS.md` limited to the pointer and repo-specific rules.
- Local knowledge base folder for the completed Render hosting pilot setup (`P8-01`): `/Users/Niwat.yah/Documents/Obsidian Vault/MCP Knowledge/`
- Use that folder as the reusable reference location when repeating the Render deploy flow, checking required env vars/secrets, or revalidating `/health` and `/info` for `flutter-widget-wallet-mcp`.

## Verified Repo Facts

- `flutter analyze` passed on 2026-06-25.
- `flutter test` passed on 2026-06-25.
- Theme V3 baseline `V3-01`/`V3-02` was captured on 2026-07-10 at commit `18ed97af7e62579cceea7bc8dd4100d716a159d9`; evidence is stored inline in `task/V3_THEME_MCP_SKILLS_TASKS.md`. `flutter analyze` and all 114 Flutter tests pass after the test-only `PlaceholderAssetBundle` was updated to serve Flutter's binary `AssetManifest.bin`; targeted tests explicitly preserve SVG markup and Lottie JSON behavior. All four MCP baseline gates passed after `npm ci`; the legacy registry contained 14 local tools and 12 remotely exposed read-only tools, and the existing contract snapshot passed unchanged.
- Flutter commands may require permissions to write to the external Flutter SDK cache, depending on sandbox/runtime.

## Testing Layout

- Widget and integration-style tests live under `test/`
- Current test coverage includes:
  - app/theme bootstrapping
  - localization font selection
  - drawer widgets
  - buttons
  - item list
  - image carousel
  - snack bar
- Many reusable widgets still have no direct tests yet, especially inputs, announcement variants, receipt widgets, NavigatorBar, Avatar, HorizontalTabs, ShortcutMenuItem, PreLoading, and LottieSkeleton.
- Shared test setup now lives in `test/support/widget_test_harness.dart` and covers `MaterialApp` + `Scaffold` pumping, localized light/dark themes, modal bottom sheet and snackbar hosts, settle helpers, and a placeholder asset bundle for `SvgPicture.asset`/`Image.asset`/`Lottie.asset` smoke tests.
- Active task backlogs live under `task/`.
- `task/TASKS.md` currently tracks the MCP production-ready execution checklist and keeps a short historical reference to the completed widget-test backlog; `WIDGET_TEST_PLAN.md` still holds the higher-level widget testing analysis and prioritization.
- `task/V3_THEME_MCP_SKILLS_TASKS.md` is a separate backlog for Theme V3, Widget V3, additive MCP V3 tools, Skills V3, and rollout through the existing hosted Render MCP service. Do not merge its progress into `task/TASKS.md`.
- When updating `task/TASKS.md`, always refresh the `อัปเดตล่าสุดเมื่อ` timestamp whenever any checklist item, note, or progress detail changes.
- When asked for the latest work, latest completed item, or current execution progress, inspect `task/TASKS.md` first and answer from its checklist state plus the `อัปเดตล่าสุดเมื่อ` timestamp.
- Batch 1 widget coverage now exists under `test/widgets/input/input_widgets_test.dart`, `test/widgets/tab/horizontal_tabs_test.dart`, `test/widgets/navigator_bar/navigator_bar_test.dart`, `test/widgets/avatar/avatar_test.dart`, and `test/widgets/snack_bar/snack_bar_test.dart`.

## Repo Boundaries

### Primary Product Code

- `lib/`
- `test/`
- `tool/`
- `pubspec.yaml`
- `analysis_options.yaml`
- `l10n.yaml`

### Supporting Tooling

- Root `package.json` and `scripts/` support schema/doc generation.
- `task/` stores task-tracking markdown for active execution backlogs.
- `mcp-server/` is the single Node-based MCP server for both design-system guidance and cross-repo widget discovery/source extraction.
- The approved V3 hosting direction is to extend this same MCP server additively and continue using the existing Remote Streamable HTTP endpoint `https://flutter-widget-wallet-mcp.onrender.com/mcp`, service name `flutter-widget-wallet-mcp`, and existing bearer-auth mechanism. A second Render service is not planned.
- Planned MCP V3 code should be isolated under `mcp-server/v3/`; existing MCP registry/entry files may change only for additive V3 registration/integration, and published legacy tool contracts/behavior must remain protected by regression tests.
- MCP V3 Phase 5 is implemented under `mcp-server/v3/` with isolated token and widget parsers/catalogs, handlers, and contracts. The existing dispatcher exposes 17 additive V3 tools: capability parity with all 14 legacy tool groups plus token list/search and widget audit. The verified registry baseline is 31 total tools / 27 remote read-only tools, with all 14 legacy definitions unchanged and in their original order. Both legacy generation tools and `generate_v3_widget_code` / `generate_v3_widgetbook_use_case` are explicitly excluded from remote exposure; V3 generation handlers return source/instructions only and never write files.
- V3 token MCP reads only `lib/config/themes/v3/tokens/**`, resolves Figma/DTCG aliases and Light/Dark parity, and exposes 55 semantic tokens with primitive aliases and `V3ThemeScope` Dart usage. V3 widget MCP reads only `lib/widgets/v3/**`, enriches source/preview/local-guide metadata, and audits legacy theme imports, raw `Color` literals, missing `V3ThemeScope`, preview, and semantic-token metadata.
- Planned V3 MCP tools must use V3-specific names, remain read-only for hosted exposure, read only V3 theme/widget paths, and never silently fall back to the legacy theme.
- Existing skills remain unchanged; the V3 skill distributions are implemented separately under `skills-v3/` for Codex, Claude Code, and Kiro (8 skills each, 24 native skill folders total) while using the same hosted MCP endpoint. See the Theme And Design Tokens section above for the canonical spec (`docs/v3/V3_SKILLS_SPEC.md`) and validation evidence (`docs/v3/V3_SKILLS_VALIDATION.md`) locations. Render rollout (Phase 7, `V3-22` to `V3-25`) is still not done. Skills V3 must preserve capability parity with the eight legacy workflows by providing `flutter-widget-v3-beginner`, search, install, adapt, preview, figma-to-code, audit, and upgrade variants; every variant is restricted to V3 paths/tools, and the beginner variant preserves the mandatory ask → scan → summarize → confirm → execute flow.
- `mcp-server/app.js` is the reusable source-of-truth factory for tool dispatching and MCP server setup; `mcp-server/index.js` is now the thin stdio entrypoint wrapper.
- `mcp-server/http-server.js` is the hosted Streamable HTTP entrypoint and reuses the same dispatcher/tool contracts from `app.js`.
- `mcp-server/remote_support.js` owns the remote read-only registry filter, commit-scoped snapshot namespace, and refresh/freshness helpers for hosted mode.
- `mcp-server/widget_catalog.js` is the filesystem-driven widget indexer used by the MCP server.
- `mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml` is the current MCP evaluation file.
- `mcp-server/examples/` now holds client-facing MCP config templates for Claude Code, Codex, and Cursor.
- `mcp-server/examples/` now includes hosted remote onboarding examples for both direct remote URL (`remote.generic.mcp.json`) and `mcp-remote` bridge (`mcp-remote.generic.mcp.json`, `codex-chatgpt-agent.remote-bridge.mcp.json`); current Phase 8 direction is to use the existing hosted Render service with direct `Authorization: Bearer ...` auth as the primary external path, and keep the bridge examples as a fallback for host apps that struggle with native remote URL flows.
- `mcp-server/FLUTTER_WIDGET_BEGINNER_SKILL_SPEC.md` is the repo-local spec for the proposed `flutter-widget-beginner` skill. It defines the required ask -> scan -> summarize -> confirm -> execute flow, the interactive questions and per-option meanings, and the guardrails for bootstrapping a Flutter workspace with widgets sourced from `flutter-widget-wallet-mcp`.
- `skills/` at repo root now holds the local skill pack for using `flutter-widget-wallet-mcp`: `flutter-widget-beginner`, `flutter-widget-search`, `flutter-widget-install`, `flutter-widget-adapt`, `flutter-widget-preview`, `flutter-widget-figma-to-code`, `flutter-widget-audit`, and `flutter-widget-upgrade`. Each skill has a `SKILL.md` plus `agents/openai.yaml`; `flutter-widget-beginner` is the only one that mandates an ask -> scan -> summarize -> confirm -> execute flow before edits.
- The canonical step-by-step guide for using the `flutter-widget-*` skill pack together with `flutter-widget-wallet-mcp` now lives in the Obsidian knowledge base at `/Users/Niwat.yah/Documents/Obsidian Vault/MCP Knowledge/Flutter Widget MCP Skills Guide.md`. It covers local/remote MCP setup, per-agent skill-pack placement, recommended skill flows, and ready-to-use prompts.
- `skills/codex/.codex/skills/` now contains the Codex-native distribution of the same skill pack, using the standard Codex layout `.codex/skills/<skill-name>/SKILL.md` inside the distribution folder so the whole pack can be copied into a Codex workspace or user config as-is.
- `skills/claude-code/.claude/skills/` and `skills/kiro/.kiro/skills/` hold the per-agent native skill-pack layouts for Claude Code and Kiro. The Claude Code pack is intentionally pure native format: each skill is `.claude/skills/<skill>/SKILL.md` with no `agents/openai.yaml`, plus a pack-level `README.md` for `/skill-name` usage and MCP setup expectations. The Kiro pack follows the same native principle based on the local Kiro install at `~/.kiro/skills/`: each skill is `.kiro/skills/<skill>/SKILL.md` with no `agents/openai.yaml`, plus a pack-level `README.md` for Kiro setup expectations. The former `agent-packs/` Cursor and Antigravity fallback distributions were removed because they were unverified, duplicated MCP examples maintained elsewhere, and were not used by runtime/build/test workflows.
- `mcp-server/scripts/verify-mcp.js` is the repeatable Inspector workflow wrapper for local stdio verification.
- `mcp-server/scripts/run-evaluations.js` executes the structured XML evaluation suite directly against the tool dispatcher.
- `mcp-server/scripts/check-syntax.js` runs repo-local JavaScript syntax validation across the MCP server tree.
- `mcp-server/scripts/validate-onboarding.js` smoke-tests the documented install flow against temp config files for supported local clients.
- `mcp-server/installer.js` is the source-of-truth module for MCP client config generation/merging, while `mcp-server/install.js` is now the thin CLI wrapper.
- `.github/workflows/mcp-ci.yml` is the dedicated GitHub Actions gate for MCP changes and uses `npm run ci:mcp` as its source-of-truth command.
- `mcp-server/PRODUCTION_READY_PLAN.md` tracks the roadmap from internal-ready to production-ready MCP quality.
- `mcp-server/PRODUCTION_READY_PLAN.md` now explicitly defines the primary production-ready use case as: this repo is a GitHub-hosted widget-library source of truth that receives ongoing Flutter widget updates from Figma/design-spec implementation work, and external users/agents should be able to connect to that hosted source directly through MCP without cloning the full repo locally.
- `mcp-server/RENDER_HOSTING_PLAN.md` is the current Phase 8 pilot plan for hosting the existing `streamable-http` transport (`http-server.js`) on Render, chosen after Koyeb closed its free tier to new users in early 2026 following a Mistral AI acquisition. Render's free web service tier gives 750 free instance-hours/workspace/month, official monorepo `rootDir` support (Blueprint field, mirrored by a Dashboard "Root Directory" setting), and free custom domains + managed TLS even on the free instance type. Known tradeoff vs the old Koyeb plan: free-tier cold start is ~1 minute after 15 min idle (per `render.com/docs/free`) instead of Koyeb's 1-5s, which is accepted as fine for agent-tooling use rather than production traffic. The repo has a checked-in `render.yaml` Blueprint at repo root (`rootDir: mcp-server`, `buildCommand: npm ci`, `startCommand: node http-server.js`, `healthCheckPath: /health`) with secret env vars (`MCP_REMOTE_PROXY_SHARED_SECRET`, `MCP_REMOTE_REFRESH_TOKEN`, `MCP_REMOTE_COMMIT_SHA`) marked `sync: false` so they must be set in the Render Dashboard, never committed. Because `http-server.js` reads `MCP_REMOTE_HOST`/`MCP_REMOTE_PORT` from its own env vars (not Render's injected `PORT`), the Blueprint pins `MCP_REMOTE_HOST=0.0.0.0` and `MCP_REMOTE_PORT=10000` (Render's default expected port) so no server code change is needed. Execution checklist lives in `task/TASKS.md` under "Phase 8: Render Hosting Pilot" (P8-01 through P8-04), which is intentionally separate from the already-closed production-ready Phase 1-7/6B checklist. The team has Codex CLI with the official Render plugin already installed (`render.com/agents/codex`), which lets Codex propose/validate/apply the `render.yaml` Blueprint, tail deploy logs, and monitor the service directly from the terminal via Render's hosted MCP server (`mcp.render.com`, `RENDER_API_KEY` bearer auth) — this is the recommended deploy path over manual Dashboard clicking. `mcp-server/KOYEB_HOSTING_PLAN.md` is kept only as a superseded historical reference (status: Superseded), not an active plan. Phase 8 P8-01 is now verified deployed on Render: workspace `My Workspace`, service `flutter-widget-wallet-mcp` (`srv-d95m7oa8qa3s73e6ahg0`), URL `https://flutter-widget-wallet-mcp.onrender.com`, branch `main`, rootDir `mcp-server`, build `npm ci`, start `node http-server.js`, health path `/health`, build filter `mcp-server/**`, and deploy commit `88bffadb3bd535b6fc4ae7bdfefd63eb8b69949d`. When checking freshness later, trust `/health` and `/info` metadata plus Render deploy metadata to confirm the exact deployed commit.
- The canonical generalized framework-agnostic playbook for turning a UI library repo into a hosted MCP service on Render now lives only in the Obsidian knowledge base at `/Users/Niwat.yah/Documents/Obsidian Vault/MCP Knowledge/UI Library Remote MCP Playbook.md`. It distills the repo's Phase 6B/8 implementation and Obsidian Render guides into reusable steps that apply to Flutter widget libraries and React/Next component libraries alike: define source-of-truth paths, freeze tool contracts first, keep `stdio` and `streamable-http` on shared core logic, expose only read-only tools remotely, use bearer-token onboarding as the primary external auth path, publish both direct remote URL and `mcp-remote` bridge config examples, and document freshness/auth/support-matrix expectations explicitly.
- Phase 8 P8-02 is now verified against the real hosted Render endpoint `https://flutter-widget-wallet-mcp.onrender.com/mcp`: `npm run verify:mcp:remote` passes end-to-end for `/health`, `/info`, `tools/list`, `list_widgets`, `search_widgets`, `get_widget_metadata`, and `/admin/refresh`, with the endpoint exposing 12 read-only tools and matching freshness metadata for commit `88bffadb3bd535b6fc4ae7bdfefd63eb8b69949d`. After leaving the service idle for 15+ minutes to force a free-tier wake-up, `time npm run verify:mcp:remote` still passed 8/8 checks with a measured wall time of `26.493s total`, which is acceptable for this agent-tooling use case and is evidence against a held-connection restriction or transport-level incompatibility on Render free tier for the current `streamable-http` implementation.
- Phase 8 P8-03 is now closed for the current pilot without adding a custom domain: the team explicitly decided to keep using `https://flutter-widget-wallet-mcp.onrender.com` because Render-managed TLS is already verified by the successful `/health` and `/info` checks in P8-02. Custom domain work and Cloudflare Access/Zero Trust are both intentionally deferred. The current P8-04 direction is single-service external onboarding on this existing Render URL through `Authorization: Bearer ...` plus client-facing config examples, while retaining legacy trusted-proxy headers only for backward compatibility.
- Current deployed Render MCP endpoint used in README examples: `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- `mcp-server/package.json` is now the source-of-truth for MCP server versioning, and `mcp-server/server_metadata.js` fans that name/version into runtime code to avoid drift.
- Local MCP/tooling configs must reference secrets through environment variables, not committed literal tokens.
- `MCP_REMOTE_BEARER_TOKEN` / `MCP_REMOTE_BEARER_TOKENS` are secrets for the hosted Render MCP endpoint and must be stored only in the Render Dashboard (or other secret manager), never written as literal values in `MEMORY.md`, repo docs, tracked config files, commits, or PR text.
- `render.yaml` at the repo root is the Render Blueprint for the Phase 8 hosting pilot (`rootDir: mcp-server`); its plain env vars (`MCP_REMOTE_HOST`, `MCP_REMOTE_PORT`, `MCP_REMOTE_CHANNEL`) are committed, but secret env vars are declared with `sync: false` and must be set only in the Render Dashboard.

### Generated Or Derived Areas

- `lib/generated/intl/`
- `lib/l10n/app_*.arb`
- `lib/widgetbook.directories.g.dart`
- platform build outputs and dependency folders such as `build/`, `.dart_tool/`, `macos/Pods/`, and nested `node_modules/`

## Coding Patterns Observed

- Provider is used for app-level theme and locale state.
- Light/dark theming is handled through `ThemeMode` and token-backed color schemes.
- Thai locale uses `GoogleFonts.notoSansThaiTextTheme()`.
- Myanmar locale uses `GoogleFonts.notoSansMyanmarTextTheme()`.
- Other non-Thai/non-Myanmar locales use `GoogleFonts.notoSansTextTheme()`.
- Reusable widgets often ship with adjacent preview/demo files and markdown usage docs.

## Practical Read Paths

### For Widget Changes

Read in this order:
1. target widget source
2. target preview file
3. target local guide/spec markdown
4. relevant tests
5. `lib/widgetbook.dart` or `lib/widgetbook_use_cases.dart` if preview registration is involved

### For Localization Changes

Read in this order:
1. `lib/l10n/localization.json`
2. `tool/generate_arb.dart`
3. `l10n.yaml`
4. generated ARB/intl outputs only if needed for validation

### For Theme Changes

Read in this order:
1. `lib/config/themes/theme_color.dart`
2. `lib/config/themes/base_theme.dart`
3. consuming widget files

### For Planned Theme V3 Work

Read in this order:
1. `docs/V3_THEME_MCP_SKILLS_PLAN.md`
2. `task/V3_THEME_MCP_SKILLS_TASKS.md`
3. the specific V3 token/theme/widget/MCP/skill files required by the selected task
4. legacy files only as read-only compatibility references unless the task explicitly calls for additive MCP registration

## Known Constraints And Gotchas

- The repo may contain unrelated local changes; avoid overwriting them.
- Generated files exist alongside hand-written sources, so confirm whether a target file is authoritative before editing.
- Some docs still describe the project as a broader app foundation, but the current repo also serves as a design-system/widget catalog with Widgetbook and MCP-related tooling.
- Root overview docs can drift from the live Flutter tree; verify paths against the filesystem before acting on them.
- V3 plan/task documents describe approved future architecture and execution, not completed implementation. Check the V3 task checkboxes and evidence before reporting availability.
- Widget-local markdown is not just human documentation; it can also feed the schema generation pipeline.
- Secret scanning risk exists for local MCP setup docs/configs; never commit PATs or API keys into tracked files.
- Flutter verification may fail in restricted environments unless the runtime can write to the Flutter SDK cache.
- The merged `mcp-server/` widget-library index assumes widget source files live under `lib/widgets/<category>/`, preview files live either beside widgets (`preview_*.dart` / `*_preview.dart`) or under `lib/previews/`, and docs live beside widgets as `*.md`.
- `mcp-server/index.js` now exposes structured MCP outputs with `outputSchema`, `structuredContent`, and read-only tool annotations for the main widget-library and design-system tools.
- MCP Phase 3 test coverage now lives under `mcp-server/tests/` using Node's built-in `node:test` runner, with fixture repo content in `mcp-server/tests/fixtures/widget_repo/`, dispatcher-based integration helper in `mcp-server/tests/helpers/tool_harness.js`, and contract snapshots in `mcp-server/tests/snapshots/`.
- MCP tool success payloads can use `structuredContent`, but in the current SDK flow error payloads should stay in `content[0].text` as JSON with `isError: true`; trying to put custom error `structuredContent` behind non-object or union `outputSchema` breaks `tools/list` or tool-call schema validation.
- `search_widgets` now uses the same pagination contract shape as `list_widgets`: `total`, `count`, `limit`, `offset`, `hasMore`, and `widgets`.
- Widget indexing internals are now split under `mcp-server/catalog/` into filesystem discovery, Dart parsing, markdown/doc enrichment, and search scoring modules instead of keeping all logic inside `widget_catalog.js`.
- Preview matching is no longer filename-only; it combines preview naming patterns, imported widget paths, same-folder proximity, and widget-name mentions inside preview content.
- `get_widget_metadata` now returns `metadataSources`, `metadataConfidence`, and `warnings` so clients can see fallback behavior, stale doc signals, and whether `updatedAt` came from git history or filesystem mtime.
- Current parser-depth decision for the MCP indexer is to stay regex/filesystem-driven until Phase 3 tests exist; revisit when prop extraction or preview/doc matching misses recurring real widgets.
- `@modelcontextprotocol/inspector` v0.22.0 can fail when invoked through its packaged CLI entrypoint; the working local verification path in this repo is `node node_modules/@modelcontextprotocol/inspector-cli/build/index.js ...`.
- `mcp-server/install.js` supports both generating `mcp.json.example` and writing directly into an existing MCP config file via `--settings`; empty target config files should be treated as `{}`.
- `mcp-server/install.js` now supports `--client`, `--repo-root`, `--settings`, `--server-name`, and `--example-dir`, with supported client targets `claude-code`, `codex-chatgpt-agent`, and `cursor`.
- Official generated MCP client templates currently exist only for `claude-code`, `codex-chatgpt-agent`, and `cursor`; `Kiro` may use the same generic command-based shape, but this repo does not ship or validate a dedicated Kiro template today.
- Phase 4 automation now uses two repo-local commands: `npm run verify:mcp` for Inspector transport checks and `npm run evaluate:mcp` for structured evaluation assertions sourced from `mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml`.
- Phase 5 local/CI parity now uses `npm run ci:mcp`, which runs syntax checks, Node tests, Inspector verification, and evaluation smoke checks in the same order as GitHub Actions.
- MCP contract regression coverage now includes `mcp-server/tests/tool_contracts.test.js` plus the snapshot `mcp-server/tests/snapshots/tool_definitions.contracts.json`, so tool registry/schema changes require an intentional snapshot update.
- Phase 6A onboarding validation is now repeatable through `npm run validate:onboarding`, which checks per-client config generation and malformed-config failure behavior against the documented install flow.
- Phase 6B remote-mode decision is documented in `mcp-server/REMOTE_MODE_DECISION.md`: local `stdio` remains the only supported transport for now, while future remote HTTP work must define auth boundary, cache invalidation keyed by commit, freshness as deployed-snapshot semantics, and explicit branch/commit pinning.
- Phase 6B is now implemented: hosted `streamable-http` is supported alongside local `stdio`, with `/health`, `/info`, and `/admin/refresh` surfaces plus read-only-only exposure on the remote endpoint.
- Hosted remote snapshots are pinned by `repoIdentity + channel + commitSha`; callers cannot override repo/branch/commit via request query or headers.
- Hosted auth boundary assumes a trusted reverse proxy injects `x-mcp-authenticated-user` plus a shared secret header (`x-mcp-proxy-secret` by default); public clients should authenticate at the proxy, not send those internal headers directly.
- `mcp-server/scripts/verify-http.js` is the local self-host transport verifier, while `mcp-server/scripts/verify-remote.js` is the source-of-truth verifier for a real hosted endpoint such as the Render Phase 8 pilot.
- The hosted `http-server.js` endpoint now supports direct bearer-token auth through `MCP_REMOTE_BEARER_TOKEN` / `MCP_REMOTE_BEARER_TOKENS` while still retaining legacy trusted-proxy headers for backward compatibility; this is the preferred single-service external onboarding path for Phase 8 instead of deploying a second public edge service.
- Phase 8 P8-04 is now verified complete on the existing Render service `https://flutter-widget-wallet-mcp.onrender.com/mcp`: `/health` and `/info` show commit `9652855e8536d5bbf3b3db4a7b498c683b522130`, `authBoundary.supportsBearerToken` is `true`, and `npm run verify:mcp:remote` passed 8/8 against the real hosted endpoint using direct bearer-token auth. Keep direct remote URL + `Authorization: Bearer <TOKEN>` as the primary production config, with `mcp-remote` bridge examples retained only as fallbacks for host apps that struggle with native remote URL flows.
- `mcp-server/http-server.js` reads `MCP_REMOTE_PORT` (default `3310`) rather than a generic platform `PORT`, so Render deploys must explicitly set `MCP_REMOTE_HOST=0.0.0.0` and `MCP_REMOTE_PORT=10000` (Render's default expected port for web services) via env vars/Blueprint rather than relying on Render's own injected `PORT`.
- Current MCP distribution requirement is broader than internal-team use only: official production-ready docs/config now include hosted-access onboarding without requiring a full local clone, while still separating officially supported remote clients (SDK/generic Streamable HTTP) from best-effort host-app remote integrations.
- Phase 7 ops docs now live in `mcp-server/RELEASE_POLICY.md`, `mcp-server/CHANGELOG.md`, `mcp-server/COMPATIBILITY_POLICY.md`, and `mcp-server/TROUBLESHOOTING.md`; `MAINTENANCE_TH.md` remains the Thai maintenance runbook.
- Runtime observability is opt-in via `MCP_LOG_LEVEL` with supported levels `silent`, `error`, `warn`, `info`, and `debug`; logs are JSON lines on stderr and cover `server.started`, `mcp.tools.list`, `tool.call.*`, `widget_catalog.load`, `widget_catalog.list_*`, `widget_catalog.get_widget`, and `widget_catalog.search`.
- `PlaceholderAssetBundle` is useful for svg/lottie-heavy tests, but raster-heavy widgets that call `Image.asset` may still require real assets because Flutter resolves `AssetManifest.bin` during image loading.
- Some drawer headers intentionally keep a hidden `Icons.close` placeholder for layout symmetry, so tests should prefer a more specific finder when tapping the visible close control.
- `NetworkImage` in widget tests can emit a framework-managed 400 unless the test suppresses the error or provides a mock HTTP client, so avatar precedence tests need explicit error handling.
- Small icon-only `GestureDetector` actions inside dense input rows can be awkward to hit-test in widget tests; calling the resolved `onTap` callback directly is sometimes more reliable than `tester.tap()` for clear actions.
- Test harness disables `google_fonts` runtime fetching so widget and golden tests stay offline-friendly and deterministic.
- Infinite or repeating Lottie animations should not use `pumpAndSettle()` in tests; use a bounded `pump()` instead.
- Widgets that call `GoogleFonts` directly inside `build()` may require dedicated local font assets or custom test overrides; otherwise offline golden tests can fail on font resolution.
- `ImageCarousel` autoplay should stay safe when `pages` is empty; tests now cover empty-page and dispose paths, and timer state is reset when autoplay settings or page count changes.
- Receipt widgets can exercise fallback rendering by passing null asset paths for icons/backgrounds, which avoids asset-heavy setup when testing long-text truncation and detail-row layout.
- In widget tests, safe-area padding is easiest to control via `tester.view.viewPadding` plus `tester.view.resetViewPadding`; `viewPaddingTestValue` is not available on `TestFlutterView` in this Flutter version.
- `NetworkImage` widget tests need a fake `HttpClient` via `HttpOverrides`; the default test binding returns HTTP 400 for real network requests.

## When To Update This File

Update this file when discovering stable information about:

- architecture
- source-of-truth ownership
- generation workflows
- verification commands
- directory responsibilities
- recurring environment caveats

Do not store temporary debugging notes or task-specific minutiae here.
