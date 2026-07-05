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

## Verified Repo Facts

- `flutter analyze` passed on 2026-06-25.
- `flutter test` passed on 2026-06-25.
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
- When updating `task/TASKS.md`, always refresh the `อัปเดตล่าสุดเมื่อ` timestamp whenever any checklist item, note, or progress detail changes.
- When asked for the latest work, latest completed item, or current execution progress, inspect `task/TASKS.md` first and answer from its checklist state plus the `อัปเดตล่าสุดเมื่อ` timestamp.

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
- `mcp-server/app.js` is the reusable source-of-truth factory for tool dispatching and MCP server setup; `mcp-server/index.js` is now the thin stdio entrypoint wrapper.
- `mcp-server/http-server.js` is the hosted Streamable HTTP entrypoint and reuses the same dispatcher/tool contracts from `app.js`.
- `mcp-server/remote_support.js` owns the remote read-only registry filter, commit-scoped snapshot namespace, and refresh/freshness helpers for hosted mode.
- `mcp-server/widget_catalog.js` is the filesystem-driven widget indexer used by the MCP server.
- `mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml` is the current MCP evaluation file.
- `mcp-server/examples/` now holds client-facing MCP config templates for Claude Code, Codex, and Cursor.
- `mcp-server/scripts/verify-mcp.js` is the repeatable Inspector workflow wrapper for local stdio verification.
- `mcp-server/scripts/run-evaluations.js` executes the structured XML evaluation suite directly against the tool dispatcher.
- `mcp-server/scripts/check-syntax.js` runs repo-local JavaScript syntax validation across the MCP server tree.
- `mcp-server/scripts/validate-onboarding.js` smoke-tests the documented install flow against temp config files for supported local clients.
- `mcp-server/installer.js` is the source-of-truth module for MCP client config generation/merging, while `mcp-server/install.js` is now the thin CLI wrapper.
- `.github/workflows/mcp-ci.yml` is the dedicated GitHub Actions gate for MCP changes and uses `npm run ci:mcp` as its source-of-truth command.
- `mcp-server/PRODUCTION_READY_PLAN.md` tracks the roadmap from internal-ready to production-ready MCP quality.
- `mcp-server/PRODUCTION_READY_PLAN.md` now explicitly defines the primary production-ready use case as: this repo is a GitHub-hosted widget-library source of truth that receives ongoing Flutter widget updates from Figma/design-spec implementation work, and external users/agents should be able to connect to that hosted source directly through MCP without cloning the full repo locally.
- `mcp-server/KOYEB_HOSTING_PLAN.md` is a separate, not-yet-executed pilot plan (status: Proposed / Pilot pending) for hosting the existing `streamable-http` transport (`http-server.js`) on Koyeb, chosen over Render/Northflank/Hostinger VPS/Cloudflare Workers because it needs no code changes, has no credit-card requirement, faster cold start than Render, and official monorepo subdirectory support (`mcp-server` as Work directory). Its known unresolved risk is that Koyeb's free tier blocks held connections (websocket/HTTP2 streams) from the internet, which may or may not affect `StreamableHTTPServerTransport`; this must be validated with `npm run verify:mcp:http` against the live Koyeb URL before treating the pilot as viable. Execution checklist lives in `task/TASKS.md` under "Phase 8: Koyeb Hosting Pilot" (P8-01 through P8-04), which is intentionally separate from the already-closed production-ready Phase 1-7/6B checklist. The recommended multi-client (Claude Code, Codex, Cursor, Antigravity, Kiro) access pattern in that plan is an `npx mcp-remote <hosted-url>` stdio bridge rather than relying on each client's native remote-URL support, since only local stdio is officially verified compatible across all of them per `COMPATIBILITY_POLICY.md`.
- `mcp-server/package.json` is now the source-of-truth for MCP server versioning, and `mcp-server/server_metadata.js` fans that name/version into runtime code to avoid drift.
- Local MCP/tooling configs must reference secrets through environment variables, not committed literal tokens.

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

## Known Constraints And Gotchas

- The repo may contain unrelated local changes; avoid overwriting them.
- Generated files exist alongside hand-written sources, so confirm whether a target file is authoritative before editing.
- Some docs still describe the project as a broader app foundation, but the current repo also serves as a design-system/widget catalog with Widgetbook and MCP-related tooling.
- Root overview docs can drift from the live Flutter tree; verify paths against the filesystem before acting on them.
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
- Phase 4 automation now uses two repo-local commands: `npm run verify:mcp` for Inspector transport checks and `npm run evaluate:mcp` for structured evaluation assertions sourced from `mcp-server/evaluations/flutter-widget-wallet-mcp-evaluation.xml`.
- Phase 5 local/CI parity now uses `npm run ci:mcp`, which runs syntax checks, Node tests, Inspector verification, and evaluation smoke checks in the same order as GitHub Actions.
- MCP contract regression coverage now includes `mcp-server/tests/tool_contracts.test.js` plus the snapshot `mcp-server/tests/snapshots/tool_definitions.contracts.json`, so tool registry/schema changes require an intentional snapshot update.
- Phase 6A onboarding validation is now repeatable through `npm run validate:onboarding`, which checks per-client config generation and malformed-config failure behavior against the documented install flow.
- Phase 6B remote-mode decision is documented in `mcp-server/REMOTE_MODE_DECISION.md`: local `stdio` remains the only supported transport for now, while future remote HTTP work must define auth boundary, cache invalidation keyed by commit, freshness as deployed-snapshot semantics, and explicit branch/commit pinning.
- Phase 6B is now implemented: hosted `streamable-http` is supported alongside local `stdio`, with `/health`, `/info`, and `/admin/refresh` surfaces plus read-only-only exposure on the remote endpoint.
- Hosted remote snapshots are pinned by `repoIdentity + channel + commitSha`; callers cannot override repo/branch/commit via request query or headers.
- Hosted auth boundary assumes a trusted reverse proxy injects `x-mcp-authenticated-user` plus a shared secret header (`x-mcp-proxy-secret` by default); public clients should authenticate at the proxy, not send those internal headers directly.
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

## When To Update This File

Update this file when discovering stable information about:

- architecture
- source-of-truth ownership
- generation workflows
- verification commands
- directory responsibilities
- recurring environment caveats

Do not store temporary debugging notes or task-specific minutiae here.
