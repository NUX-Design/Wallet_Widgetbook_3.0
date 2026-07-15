# MEMORY.md

## Project Snapshot

- Repository type: Flutter widget/design-system repository with a runnable demo app and a local Flutter Web preview host (`lib/preview_v3/`) for Widget V3 (Widgetbook was fully removed in VP-07).
- Primary domain: reusable UI components for a financial app.
- Main package name: `mcp_test_app`
- MCP package/server name for cross-repo widget access: `flutter-widget-wallet-mcp`
- Verified on review date: 2026-06-25

## Core Entry Points

- App entry: `lib/main.dart`
- Widget V3 local web preview host entry: `lib/preview_v3/main.dart` (routing in `lib/preview_v3/preview_app.dart`, registry in `lib/preview_v3/preview_registry.dart`)

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

### Widget V3 Local Web Preview

- `docs/v3/V3_WIDGET_PREVIEW_PUBLISHING_GUIDE.md` is the canonical operational guide for scaling beyond the pilot widget. For every new Widget V3: add `v3_<widget>.dart`, `preview_v3_<widget>.dart` with constructible `class V3<Widget>Preview`, local `V3_<WIDGET>_GUIDE.md`, and targeted tests; run and commit the generated `lib/preview_v3/preview_registry.g.dart`; verify locally; then merge to `main` so bundle CI publishes. Published Skill availability requires the existing Render service, `MCP_REMOTE_COMMIT_SHA`, MCP freshness, bundle manifest, and `previewDelivery.sourceCommit` to share the same full SHA. No per-widget Skill, launcher, router, or MCP-handler edit is required.
- Zero-Flutter consumer preview is a separate successor initiative, specified by `docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md` and tracked in `task/V3_ZERO_FLUTTER_PREVIEW_TASKS.md`. Its required boundary is: consumer repos receive no Flutter/Dart/project files and are never asked to install Flutter; source CI compiles an immutable commit-addressed Flutter Web bundle, the existing hosted MCP exposes delivery metadata, and a repo-independent launcher downloads/verifies/caches it outside the workspace before serving it on loopback. The existing `scripts/serve-v3-preview.sh` remains the source-development mode. Published preview means an interactive local preview of a verified source commit, not hot reload of uncommitted Dart source.
  - IMPLEMENTATION HISTORY (`2026-07-14`, before live rollout): ZP-01–ZP-12 were done and ZP-13/ZP-14 were code-complete. Frozen contract: `mcp-server/v3/bundle_contract.js` (schemaVersion 1, `validateBundleManifest`/`buildPreviewDelivery`/`urlContainsSecret`/`V3_PREVIEW_ERROR_CODES`) + human doc `docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md`. Packer `scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs` (`packBundle()`, deterministic pure-Node ustar+gzip, reads slugs from generated registry, rejects dirty/non-40hex/empty). CI `.github/workflows/v3-preview-bundle.yml` publishes `v3-preview-<sha>` (immutable) + `v3-preview-latest` GitHub Releases. Delivery: `mcp-server/v3/bundle_store.js` (LocalDir + GitHubRelease stores) served by an additive bearer-authenticated streaming route in `http-server.js` `GET /v3/preview-bundle/manifest.json|/<commit|latest>.tar.gz` (content-length + etag=sha256 + cache-control; env `MCP_PREVIEW_BUNDLE_REPO`/`MCP_PREVIEW_BUNDLE_GH_TOKEN`/`V3_PREVIEW_BUNDLE_BASE_URL`, defaults in `render.yaml`). Provider `mcp-server/v3/bundle_catalog.js` `V3BundleCatalog` (describeDelivery available/STALE_BUNDLE/NOT_BUILT/MALFORMED, health, manifest, openArchive, freshness parity). Handlers add `previewDelivery` (or `previewDeliveryStatus`) additively to `get_v3_widget_metadata`/`get_v3_widget_details`/`get_v3_widget_preview` when an optional `v3BundleCatalog` is wired via `createToolDispatcher` (default null = unchanged legacy/local behavior); `localPreviewUrl` retained but source-dev-only/deprecated for remote. Launcher `scripts/v3-preview-bundle/launch-v3-preview.mjs` (zero-dep Node + system tar) is repo-independent: caches at `<userCache>/flutter-widget-wallet/v3-preview/<commit>/`, per-commit lock, download→verify sha256→safe-extract (rejects symlink/absolute/`..`)→atomic install, python3-baseline/node-fallback loopback server, `__preview_health__.json{commit,sha256}`, warm reuse via `servers.json`, foreground-blocking default (skill backgrounds it) with `--detach`; token only as Authorization header, never persisted. The launcher is shipped into each `skills-v3/*/flutter-widget-v3-preview/assets/` (kept byte-identical by `scripts/v3-preview-bundle/launcher-sync.test.js`). `flutter-widget-v3-preview` SKILL.md (all 3 packs) defaults to **published consumer mode** (any repo, no Flutter) and keeps source-development mode for the source repo only. Tests: `mcp-server/tests/v3/{bundle_contract,bundle_catalog,preview_delivery,preview_bundle_http}.test.js`, `scripts/v3-preview-bundle/pack-v3-preview-bundle.test.js` + `launcher-sync.test.js`, acceptance `scripts/v3-preview-bundle/zero-flutter-acceptance.mjs`, and real headless-Chrome `scripts/v3-preview-bundle/browser-verify.mjs --full`. Rollout/rollback: `docs/v3/V3_ZERO_FLUTTER_PREVIEW_ROLLOUT.md`; live remote check is `cd mcp-server && npm run verify:mcp:remote:v3`. `dist/` is gitignored generated output. Current live completion evidence is recorded in the next bullet. `browser-verify.mjs` needs `NODE_PATH` pointing at the hoisted Playwright parent (dev-only; not used by the launcher/CI). Gotcha: a shell `FORCE_COLOR` can make `node -e "console.log(<number>)"` inject ANSI into captured vars — parse the launcher's JSON string output or set `FORCE_COLOR=0`.

- LIVE COMPLETE (`2026-07-15`) supersedes the earlier `LIVE-PENDING` marker in the implementation history above: ZP-01 through ZP-14 are closed. GitHub Actions run `29352517196` published immutable + latest bundle assets for `8a44373e6be8535d49b44f8b14bae6f63865f877`; Render deploy `dep-d9b6s8pkh4rs73cjljag` is live at the same commit; `/info.previewBundle` reports `available:true`, `fresh:true`; corrected `verify:mcp:remote:v3` passes 19/19; authenticated archive streaming matched SHA-256 `54a2b15c9da97c4137343273e07a3bd8507134cafb2adbd79300707071867e1f`; rollback drill returned `NOT_BUILT` while MCP stayed operational (18/18 with delivery SKIPs), then restored to 19/19. Public release repos use `MCP_PREVIEW_BUNDLE_PUBLIC_REPO=true` and deterministic `github.com/<repo>/releases/download/<tag>/<asset>` URLs so shared-host GitHub API rate limits or stale private tokens cannot block delivery; private repos retain authenticated GitHub API lookup.

- Production bundle selection is immutable and commit-pinned: `V3BundleCatalog` asks the store for `v3-preview-<MCP freshness SHA>`, never the mutable `v3-preview-latest` pointer; a missing exact release fails closed as `NOT_BUILT`. In addition, `v3-preview-latest` cannot be moved by a stale rerun, a tag/non-main workflow dispatch, or a commit removed from rewritten `main` history: `.github/workflows/v3-preview-bundle.yml` queries the live remote `main` ref immediately before updating the pointer, then `scripts/v3-preview-bundle/assert-latest-publishable.mjs` requires both `GITHUB_REF == refs/heads/main` and `GITHUB_SHA == MAIN_HEAD_SHA`. Regression coverage is included in `npm run test:v3-preview-bundle` and the MCP V3 catalog tests.

- The local Flutter Web preview host that replaced Widgetbook is documented in `docs/V3_WEB_PREVIEW_PLAN.md`; execution and verified progress belong in `task/V3_WEB_PREVIEW_TASKS.md` (`VP-01` through `VP-10`, all verified complete as of `2026-07-14`).
- The MVP route `http://127.0.0.1:8090/#/button/V3MiniButton` is live and verified in a real browser, served from the single Flutter Web host under `lib/preview_v3/` via `scripts/serve-v3-preview.sh`; `build/web/**` remains generated and untracked.
- MCP preview route metadata (VP-08), all three Skills V3 preview flows (VP-09), and generated registry scaling (VP-10) are implemented with evidence in the checklist.
- Widgetbook packages (`widgetbook`, `widgetbook_annotation`, `widgetbook_generator`), `build_runner` (no other builder depended on it), the three Widgetbook source files (`lib/widgetbook.dart`, `lib/widgetbook_use_cases.dart`, `lib/widgetbook.directories.g.dart`), and the deprecated Cloud workflow are fully removed (VP-07, `2026-07-14`). No `lib/**` file imports `package:widgetbook*` anymore.
- VP-02 is verified complete (`2026-07-14`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c`): `lib/widgets/v3/button/preview_v3_mini_button.dart` no longer imports `widgetbook_annotation` or declares `@UseCase`/`buildV3MiniButtonUseCase`, while keeping standalone `main()` and the Light/Dark `_FigmaMiniButtonMatrix` (3 variants × 4 states). Removing the annotation and rerunning `dart run build_runner build --delete-conflicting-outputs` automatically drops just the `V3MiniButton` folder/use-case entry from `lib/widgetbook.directories.g.dart` (23-line diff, generated file only) while leaving every other Widgetbook use case registered and working — this is the expected way to decouple one pilot preview from Widgetbook without touching the rest of the catalog ahead of full removal in VP-07.
- VP-03 is verified complete (`2026-07-14`): `lib/preview_v3/preview_definition.dart` defines `V3PreviewDefinition` (category/widgetName/lazy `WidgetBuilder`, computed `slug`) plus standalone `normalizeV3PreviewSlug` and `ensureUniqueV3PreviewSlugs` helpers so slug normalization/duplicate detection are unit-testable outside the singleton registry. `lib/preview_v3/preview_registry.dart` holds the MVP explicit `V3PreviewRegistry` with one entry (`button/V3MiniButton` → builds `V3MiniButtonPreview` lazily); `resolve(slug)` normalizes and returns `null` for unknown/empty slugs, `all()` returns an unmodifiable list. Tests live under `test/preview_v3/`. Phase 7 (VP-10) is expected to replace this hand-maintained list with a generator scanning `lib/widgets/v3/**/preview_v3_*.dart`; do not treat the explicit registry as final.
- VP-04 is verified complete (`2026-07-14`, revised by the VP-06 fix below): the preview host routing — `V3PreviewApp` (wraps `MaterialApp`) and `V3PreviewRoute` (normalizes the fragment; empty → first `V3PreviewRegistry.all()` entry as root "redirect to pilot widget", resolvable slug → that definition's lazy `builder` via `Builder`, unresolvable slug → `lib/preview_v3/preview_not_found.dart`'s `V3PreviewNotFound` which lists every registered slug and never throws) — now live in `lib/preview_v3/preview_app.dart`. `lib/preview_v3/main.dart` is a thin entrypoint that only calls `setUrlStrategy(null)` then `runApp(V3PreviewApp(rawSlug: Uri.base.fragment))`.
- **Critical Flutter-web gotcha found during VP-06 browser verification**: a plain `MaterialApp(home: ...)` with no explicit `Router`/`Navigator 2.0` config still syncs the browser address bar to its own internal route ("/") on first frame, which silently overwrites/strips any URL fragment set manually before `runApp` (confirmed live: `http://host:port/#/button/V3MiniButton` collapsed to `http://host:port/` within ~1s of boot). Any Flutter Web app that wants to own the URL fragment itself (like this preview host) MUST add `flutter_web_plugins: sdk: flutter` to `pubspec.yaml` and call `setUrlStrategy(null)` from `package:flutter_web_plugins/flutter_web_plugins.dart` before `runApp`, disabling Flutter's own history sync entirely. Because `flutter_web_plugins` transitively imports `dart:ui_web`, which does not resolve under the VM platform `flutter test` uses, that import must live only in a thin `main()`-only entrypoint file (`lib/preview_v3/main.dart`) — never in a file that widget tests also import — or `flutter test` fails to compile with "Dart library 'dart:ui_web' is not available on this platform." This is why the testable `V3PreviewApp`/`V3PreviewRoute` classes were moved out of `main.dart` into `lib/preview_v3/preview_app.dart` (no `flutter_web_plugins` import), tested by `test/preview_v3/preview_app_test.dart`.
- VP-05 is verified complete (`2026-07-14`): `scripts/serve-v3-preview.sh` regenerates the V3 preview registry, rebuilds when any `lib/**`, `web/**`, `pubspec.yaml`, or `pubspec.lock` input is newer than `build/web/main.dart.js`, serves `build/web` via `python3 -m http.server`, rejects port collisions, polls HTTP readiness before printing the exact URL, and cleans up its subprocess via traps. Defaults remain `127.0.0.1:8090` with slug `button/V3MiniButton`, overridable through flags or `V3_PREVIEW_*` env vars.
- VP-06 is verified complete (`2026-07-14`): after the `setUrlStrategy(null)` fix above, `http://127.0.0.1:8090/#/button/V3MiniButton` genuinely works end-to-end in a real browser (verified headlessly via the Puppeteer MCP tools, since `mcp__claude-in-chrome__*` was unavailable in this environment — extension not connected). Confirmed: correct 3×4 variant/state matrix, working Light/Dark toggle, route survives a full page reload (fragment-only same-document navigation does NOT re-trigger routing — there is no `hashchange` listener in MVP scope, so switching preview routes in-browser requires a real navigation/reload, matching the plan's refresh-based fragment contract), unknown routes render the Not Found screen without crashing, no overflow at a 320×480 viewport, and Tab keyboard input doesn't crash (Flutter web's default non-semantics renderer keeps focus on the single `flutter-view` canvas host rather than exposing per-widget DOM focus targets).
- VP-07 is verified complete (`2026-07-14`): deleted `lib/widgetbook.dart`, `lib/widgetbook_use_cases.dart`, `lib/widgetbook.directories.g.dart`; removed `widgetbook`, `widgetbook_annotation`, `widgetbook_generator`, and `build_runner` from `pubspec.yaml` (no other builder used `build_runner`; there is no `build.yaml` and no other `dart run build_runner` usage in the repo); ran `flutter pub get` (35 transitive packages dropped). `.github/workflows/widgetbook.yml` was already removed in an earlier session and stays gitignored per the `.gitignore` comment explaining why. Confirmed `grep -rln "widgetbook" lib/ --include="*.dart"` returns nothing and no file imports `package:widgetbook*`. Updated the actively-instructive docs that told users/agents to run Widgetbook (`README.md`, `AGENTS.md`, `MEMORY.md`, `CODEBASE_CONTEXT.md`, `CONTRIBUTING.md`, `SETUP_GUIDE.md`) to point at `scripts/serve-v3-preview.sh` / standalone previews instead; left `RELEASE_NOTES.md` (historical changelog) and V3 planning/evidence docs (`docs/V3_WEB_PREVIEW_PLAN.md`, `docs/V3_THEME_MCP_SKILLS_PLAN.md`, `task/**`, `docs/v3/**`) untouched as intentional migration history, per the plan's own acceptance bar ("no runtime/dependency/workflow references remain, except historical migration references"). Full regression after removal: `flutter analyze` clean, `flutter test` full suite passed, `flutter build web --release -t lib/preview_v3/main.dart` succeeded, `npm run check:v3-boundaries` passed, `cd mcp-server && npm run check:mcp-syntax && npm test` passed (29/29), `npm run validate:v3-skills` passed.
- Gotcha caught during VP-07: `.github/workflows/widget-sync-ci.yml` (a separate CI workflow from the removed `widgetbook.yml`) had a `flutter pub run build_runner build` step and a `flutter build web -t lib/widgetbook.dart` step that would have started failing on the next push once Widgetbook/`build_runner` were removed from `pubspec.yaml`. Fixed by dropping the code-gen step and replacing the Widgetbook build step with `flutter build web --release -t lib/preview_v3/main.dart`, plus adding `lib/preview_v3/**` to its path triggers. When removing a Flutter package/tool, always check `.github/workflows/**` for CI steps that reference it, not just app source and docs — CI-only references are easy to miss with a repo-wide doc sweep. Also fixed `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` (the mandatory Widget V3 creation guide) which still instructed adding `@widgetbook.UseCase` and running `build_runner`; it now points at registering new previews in `lib/preview_v3/preview_registry.dart`.
- VP-08 is verified complete (`2026-07-14`): `mcp-server/v3/handlers.js` adds `v3PreviewRouteMetadata(widget)` — a single helper computing `previewSlug` (`${category}/${name}`) and `localPreviewUrl` (`http://${V3_LOCAL_PREVIEW_HOST}:${V3_LOCAL_PREVIEW_PORT}/#/${previewSlug}`, defaults `127.0.0.1:8090` matching `scripts/serve-v3-preview.sh`, overridable via the same `V3_PREVIEW_HOST`/`V3_PREVIEW_PORT` env vars) — spread additively into `get_v3_widget_metadata`, `get_v3_widget_details` (via the shared `widgetMetadata()` builder), and `get_v3_widget_preview`. Verified live against the real repo: `V3MiniButton` → `previewSlug: "button/V3MiniButton"`, `localPreviewUrl: "http://127.0.0.1:8090/#/button/V3MiniButton"`. `outputSchema` for these tools is `{ type: "object", additionalProperties: true }`, so no schema changes were needed. `mcp-server/scripts/verify-remote-v3.js` gained two new checks (`get_v3_widget_metadata.previewRoute`, `get_v3_widget_preview.previewRoute`) but has not been run against the live Render endpoint yet.
- Gotcha: `mcp-server/node_modules` does not exist in this sandbox and the hoisted `~/node_modules` cache lacks `@modelcontextprotocol/inspector-cli`, so `npm run verify:mcp` (Inspector-based) always fails here regardless of code changes. `npm test` and `npm run verify:mcp:http` don't need that package and already provide equivalent/stronger local regression coverage — use those instead of treating an Inspector failure as a real regression in this environment.
- VP-09 is verified complete (`2026-07-14`): `flutter-widget-v3-preview` (all 3 native packs — `skills-v3/codex/`, `skills-v3/claude-code/`, `skills-v3/kiro/`) no longer has any Widgetbook use-case flow; `## MCP Tools` is now just `get_v3_widget_preview`/`get_v3_widget_metadata`. Its "Live Browser Preview" flow now resolves `previewSlug`/`localPreviewUrl` via those two tools (the VP-08 additive fields) instead of hand-building a `flutter run -d web-server --web-port <port>` invocation, checks HTTP readiness before ever handing back a URL, starts `./scripts/serve-v3-preview.sh` when the server isn't up, and has an explicit fallback for missing Flutter SDK / failed build / script errors instead of claiming success. `npm run validate:v3-skills` passes (3 packs × 8 skills, 18 known V3 tools). `flutter-widget-v3-beginner` and the pack `README.md` files still mention Widgetbook intentionally — that's portable guidance for other host repos that may still use it, and was out of VP-09's explicit scope (which names only the preview skill), same scoping call as VP-07.
- Skills V3 preview mode selection was hardened after a real Claude Code misroute: all three `flutter-widget-v3-preview` packs must choose source-development mode automatically when both `lib/preview_v3/` and `scripts/serve-v3-preview.sh` exist, then use the generated registry + `scripts/serve-v3-preview.sh` flow without MCP bundle delivery or bearer tokens. Published consumer mode is only for workspaces lacking either source marker. A missing consumer token must be resolved by privately setting `MCP_REMOTE_BEARER_TOKEN` in the launching shell; skills must never ask users to paste, type, or reveal secrets in chat. `scripts/validate-v3-skills.js` enforces these invariants across all packs.
- VP-10 is verified complete (`2026-07-14`) — **`task/V3_WEB_PREVIEW_TASKS.md` VP-01 through VP-10 are all done; the Widgetbook-to-local-web-preview migration is closed.** `tool/v3_preview_registry_generator.dart` is the pure discovery/render library (`discoverV3PreviewEntries`, `generateV3PreviewRegistrySource`, `v3ClassNameFromSnakeCase`); `tool/generate_v3_preview_registry.dart` is the CLI (`dart run tool/generate_v3_preview_registry.dart` writes, `--check` verifies without writing, both auto-run `dart format` on the output so CI's format check never breaks). It scans `lib/widgets/v3/**/preview_v3_*.dart`, derives `category` from the immediate parent directory name and the widget/preview class names from the filename (`preview_v3_<widget>.dart` -> `class V3<Widget>Preview` must exist in that file), throws an actionable `V3PreviewGeneratorException` on a missing preview class or a duplicate `category/widgetName` slug, and sorts entries by slug for deterministic output. `lib/preview_v3/preview_registry.g.dart` is the generated output (never hand-edit); `lib/preview_v3/preview_registry.dart` is now just the hand-maintained validation/lookup wrapper (`ensureUniqueV3PreviewSlugs(generatedV3PreviewEntries)`, `resolve`/`all`) — its public API and `preview_app.dart`/`main.dart` are unchanged. CI gate: `.github/workflows/widget-sync-ci.yml` has a "Check Widget V3 preview registry is up to date" step running `dart run tool/generate_v3_preview_registry.dart --check`; local equivalent is `npm run check:v3-preview-registry`. `test/tool/v3_preview_registry_generator_test.dart` (8 tests) proves the scale flow with a real multi-entry fixture (2 categories) plus duplicate-slug and missing-builder error paths — **the "second widget" scale proof was done via generator unit tests with synthetic fixtures, not a second production `lib/widgets/v3/` widget**, because every real Widget V3 component requires a genuine Figma source-of-truth per `V3_WIDGETS_CONTEXT.md` and no second widget spec was available in-session (explicit user decision, asked via AskUserQuestion). Full regression after wiring in: `flutter analyze` clean, `dart format --set-exit-if-changed .` clean, `flutter test` full suite 182/182 (174 prior + 8 new), `flutter build web --release -t lib/preview_v3/main.dart` succeeded, `npm run check:v3-boundaries`/`validate:v3-skills` passed, MCP `check:mcp-syntax`+`npm test` 30/30 passed, and a real `scripts/serve-v3-preview.sh` run served `http://127.0.0.1:8090/#/button/V3MiniButton` correctly off the generated registry. Docs updated to describe the generator instead of manual registry edits: `docs/V3_WEB_PREVIEW_PLAN.md` (Phase 7 marked implemented, target-architecture diagram updated), `AGENTS.md` (Widget V3 Local Web Preview Change Playbook + Repo Shape + Widget Documentation sections), `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` (workflow step 5 and verification commands).

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

- Root `DESIGN.md` is the mandatory V3 design-system reference for design language, visual rules, token intent, typography, spacing, radius, effects, and component variants. Theme V3 token JSON remains the editable implementation source consumed by the generator, and generated Dart remains derived output. Theme V3/Widget V3 work must read both; if `DESIGN.md`, Figma/local specs, and token/runtime sources disagree, stop and reconcile the sources rather than guessing, hardcoding, or falling back to legacy theme.
- `DESIGN.md` represents **Wi Design System — DesignBridge** (generated from Wi Design System on `2026-07-14`). Its normative agent rules require exact defined colors/tokens, typography metrics, spacing, radii, shadows, themes, and component variant names; undefined visual decisions must not be invented. The document includes Light/Dark definitions, 18 typography styles, effect styles, and component variant sets in addition to primitive/semantic catalogs.
- For Flutter V3 implementation, `DESIGN.md` describes what the UI must mean and look like, while `lib/config/themes/v3/tokens/**`, the generator, and public V3 Dart APIs define how that intent enters runtime. Agents must map the reference to semantic APIs such as `V3ThemeScope`, `V3Typography`, `V3Spacing`, and `V3Radii`; CSS variables and raw hex values shown in `DESIGN.md` are reference representations, not permission to hardcode them into Widget V3.
- Mandatory V3 read sequence is: `AGENTS.md` → `MEMORY.md` → `DESIGN.md` → `V3_THEME_GUIDELINE.mdx` / `V3_WIDGETS_CONTEXT.md` → nearest widget Figma/local guide/source/preview/tests. Any drift between these layers must be surfaced and resolved at the editable source before implementation continues.
- Central token accessor: `ThemeColors.get(theme, token)`
- Token definitions live in `lib/config/themes/theme_color.dart`
- Base color schemes live in `lib/config/themes/base_theme.dart`
- Shared UI should use theme tokens instead of hardcoded colors where possible.
- A separate additive Theme V3 initiative is in progress. Its architecture source of truth is `docs/V3_THEME_MCP_SKILLS_PLAN.md`, and its execution/progress source of truth is `task/V3_THEME_MCP_SKILLS_TASKS.md`; V3-01 through V3-25 are verified complete, including the Render rollout.
- Root `README.md` is now V3-first onboarding: Theme V3, Widget V3, Remote MCP V3, and Skills V3 are the recommended path, while legacy theme/widgets/tools/skills are documented only as backward-compatible additive boundaries.
- Theme V3 Render rollout (Phase 7, `V3-22` to `V3-25`) verified complete on `2026-07-12`: currently deployed commit `82ca59401fe21d684b24a3d91e2a5a6cfa4a084e` (post-V3 merge, built `2026-07-11T18:22Z`) on the existing service `flutter-widget-wallet-mcp` at `https://flutter-widget-wallet-mcp.onrender.com/mcp`, matching `origin/main`. `/info` exposes 27 remote read-only tools (12 legacy + 15 V3); the 4 generation tools stay excluded from remote. `npm run verify:mcp:remote` PASS 8/8 and the new `npm run verify:mcp:remote:v3` PASS 13/13 against the real endpoint; unauthenticated `POST /mcp` returns HTTP 401; `get_v3_color_token(content/primary)` returns Light `#0F172A` / Dark `#FFFFFF` / aliases `slate/900`,`white`. `mcp-server/scripts/verify-remote-v3.js` (npm `verify:mcp:remote:v3`) is the source-of-truth V3 remote verifier — additive and NOT a CI gate (needs live endpoint + bearer secret like `verify:mcp:remote`). `render.yaml` now declares `buildFilter.paths` = `mcp-server/**` + `lib/config/themes/v3/**` + `lib/widgets/v3/**` (excludes `skills-v3/**`); the Render Dashboard build filter must be synced to match for V3-only commits to auto-deploy. Onboarding guide `docs/v3/V3_REMOTE_MCP_GUIDE.md` documents that the URL and Bearer token mechanism are unchanged for both legacy and V3.
- The planned V3 boundary keeps legacy theme files and widgets unchanged, places V3 theme code under `lib/config/themes/v3/`, and places V3 widgets under `lib/widgets/v3/`.
- Planned V3 inputs are Figma/DTCG primitive plus semantic Light/Dark JSON tokens; V3 widgets should consume semantic colors through a V3-prefixed API rather than `ThemeColors.get()`.
- V3 change boundaries are enforced by `npm run check:v3-boundaries` with unit coverage from `npm run test:v3-boundaries`. The checker blocks legacy `theme_color.dart` imports and `ThemeColors.get()` calls inside both V3 theme code and Widget V3, blocks V3 imports from legacy widgets, and blocks legacy `skills/**` changes when a diff contains V3 work. Flutter CI supplies the PR/push base SHA so changed-path checks cover committed diffs; `docs/v3/V3_REVIEW_CHECKLIST.md` is the reviewer source for frozen files and additive-only MCP integration boundaries.
- Theme V3 editable token inputs use direct Figma exports under `lib/config/themes/v3/tokens/`: the 145 top-level primitive colors live at `tokens/primitive/primitive.tokens.json`, while matching Light/Dark semantic catalogs of 55 paths each live under `tokens/semantic/`. The semantic exports include alias chains such as `Button → Core → primitive`; `V3TokenResolver` resolves these chains with cycle detection. `background/primary` resolves to Light `Blue/50` (`#FBFCFF`) and Dark `Slate/950` (`#020617`). Generated Dart outputs live under `lib/config/themes/v3/generated/` and must be refreshed with `dart run lib/config/themes/v3/v3_theme_generator.dart` rather than edited manually.
- Theme V3 primitive inputs also include `tokens/primitive/color.alpha.json` (52 alpha colors), `tokens/primitive/radius.json` (9 radii) and `tokens/primitive/space.json` (18 spacing values). Semantic dimension inputs live at `tokens/semantic/radius.json` (9 aliases) and `tokens/semantic/space.json` (18 aliases). Alpha colors generate into `V3PrimitiveColors`; numeric tokens are parsed by `V3NumberTokenParser`, semantic aliases resolve through `V3NumberTokenResolver`, and outputs are `V3PrimitiveRadii`/`V3PrimitiveSpacing` plus semantic `V3Radii`/`V3Spacing`. Widgets should import `v3_dimensions.dart` and prefer semantic dimensions; `v3_primitives.dart` is the explicit primitive boundary.
- Theme V3 typography source is `tokens/semantic/typography.json`: 18 semantic Display/Heading/Label/Paragraph styles generate as `V3Typography` through `v3_typography.dart`. The parser resolves the embedded font definition, maps Regular/Medium/Bold/ExtraBold to Flutter weights 400/500/700/800, normalizes `Noto sans` to `Noto Sans`, converts absolute line-height to a Flutter height ratio, and rejects unsupported non-zero paragraph spacing. Locale-aware widgets may need to override the generated font family for Thai/Myanmar while retaining the generated metrics.
- Theme V3 `Noto Sans` is bundled for deterministic/offline runtime rendering under `lib/assets/fonts/v3/` with OFL license and registered in `pubspec.yaml` as family `Noto Sans` for weights 300/400/500/600/700/800. This exact family name must remain aligned with generated `V3Typography`; `google_fonts` is not required for V3 English/Latin typography or Zero-Flutter preview delivery. Real Headless Chrome verification against the built `button/V3MiniButton` web preview loaded `FontManifest.json` and fetched all six bundled files with HTTP 200, including `NotoSans-Medium.ttf` used by `V3Typography.labelTiny` (`FontWeight.w500`). Thai/Myanmar still require an explicit locale-family strategy if exact script-specific Noto families are required.
- Theme V3 shadow source is `tokens/primitive/shadow.effect.json`: 10 Figma layers compose into 6 `V3PrimitiveShadows` scales (`sm`, `base`, `md`, `lg`, `xl`, `xl2`) exported by `v3_primitives.dart`. Shadow colors must resolve to `color.alpha.json`; base/md/lg/xl are two-layer `List<BoxShadow>` values. Shadows remain primitive until Design supplies semantic elevation-role mappings.
- Theme V3 parsing/validation is implemented in `v3_token_parser.dart` and `v3_token_resolver.dart`; it supports DTCG/Figma color values and aliases, deterministic path/property normalization, alias resolution/cycle detection, missing targets, duplicate paths, Light/Dark parity, and Dart property collision checks. `V3ThemeScope.colorsOf(context)` selects generated semantic palettes from Flutter brightness without changing legacy `ThemeData`.
- `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx` is the detailed architecture and maintenance guide for Theme V3; `lib/config/themes/v3/README.md` remains the short quick-start entrypoint.
- Widget V3 conventions live in `docs/v3/V3_WIDGET_CONVENTIONS.md`: V3 widgets use `lib/widgets/v3/<category>/v3_<widget>.dart`, standalone `preview_v3_<widget>.dart`, a `V3_<WIDGET>_GUIDE.md` metadata guide, and targeted tests under `test/widgets/v3/<category>/`; colors must come from `V3ThemeScope.colorsOf(context)` and user-facing copy remains caller-owned.
- `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` is the mandatory creation context for all Widget V3 work. It links bidirectionally with `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx` and defines the Figma-to-token-to-widget workflow, file/API/accessibility conventions, preview/test/metadata requirements, verification commands, and Definition of Done.
- The verified Widget V3 pilot is `V3MiniButton` under `lib/widgets/v3/button/`, scoped only to Figma Size=Mini with Primary/Outline/Ghost variants, Default/Active/Disabled/Error states, left/right icon slots, Light/Dark standalone preview, generated Widgetbook registration, local token metadata, and accessibility/state coverage. Pilot QA evidence is in `docs/v3/V3_WIDGET_PILOT_AUDIT.md`.
- `V3MiniButton` design source of truth is the 12 `Wi Design System` Mini Button nodes in file key `mhUvPg9tOjlvQvEW6glQhJ` recorded in `V3_MINI_BUTTON_GUIDE.md`; those nodes replace aggregate node `18:1764` as the pilot's visual/state SOT.
- `V3MiniButton` was revalidated against all 12 Figma Mini nodes after the expanded V3 token imports: its geometry/effects now consume `V3Spacing` (`0/2/6/8/12/16/24`), `V3Radii.roundedFull`, `V3Typography.labelTiny`, `V3PrimitiveColors.blackAlpha0/5`, and `V3PrimitiveShadows.sm`; Outline shadow applies only to Default/Active because Disabled/Error Figma nodes have no shadow.
- Skills V3 (Phase 6, `V3-19` to `V3-21`) is implemented: `docs/v3/V3_SKILLS_SPEC.md` is the canonical spec for 8 V3 skills (`flutter-widget-v3-beginner/-search/-install/-adapt/-preview/-figma-to-code/-audit/-upgrade`), routed exclusively to the 18 V3-prefixed MCP tools in `mcp-server/v3/tool_contracts.js`. Native packs live under `skills-v3/codex/.codex/skills/`, `skills-v3/claude-code/.claude/skills/`, and `skills-v3/kiro/.kiro/skills/`. `flutter-widget-v3-beginner` keeps the mandatory `ask → scan → summarize → confirm → execute` flow and now supports a confirmed `bootstrap-new`: run `flutter create`, install the 11-file Theme V3 runtime manifest through remote-safe `get_v3_theme_foundation`, add a starter Widget V3/preview/test, and verify Light/Dark/analyze/test. Existing-project mode remains isolated to V3 theme/widget/test paths and never modifies legacy theme/widgets.
- `get_v3_theme_foundation` is the read-only distribution surface for new-project bootstrap: without `file` it returns the allowlisted runtime manifest; with an exact manifest path it returns one source file. The allowlist is owned by `mcp-server/v3/foundation_catalog.js` and contains generated colors/dimensions/shadows/typography plus public barrels, palette and `V3ThemeScope`; arbitrary or legacy paths are rejected. It is locally verified but requires the next Render deployment before hosted clients can call it.
- `docs/v3/V3_SKILLS_VALIDATION.md` records real tool-call evidence for all 8 Skills V3 workflows. Repeatable validation lives at `scripts/validate-v3-skills.js`, runs via `npm run validate:v3-skills`, and is a Flutter CI gate covering 3 packs × 8 skills, metadata, V3-only tool routing, beginner markers, remote-safe fallbacks, and remote generation-tool exclusions. `generate_v3_widget_code`/`generate_v3_widgetbook_use_case` remain optional local/stdio optimizations; Remote MCP workflows author source locally from read-only V3 template/metadata/token/code/preview results without legacy fallback.
- `flutter-widget-v3-preview` in all three native packs defaults to published consumer mode: resolve `previewDelivery`/`previewSlug` through hosted MCP, then use the bundled repo-independent launcher to download, checksum, cache outside the workspace, bind loopback, and return a URL only after readiness. Source-development mode remains available only inside this source repo for uncommitted changes and uses `scripts/serve-v3-preview.sh`; consumer mode must never install Flutter, call `flutter-widget-v3-install`, or write Flutter files into the target repo.
- `flutter-widget-v3-beginner` in all three native packs uses explanation-first discovery: before asking, explain every Goal, Workspace State, Target Widget, and Change Policy label in the user's language; show the V3-only existing-project paths and legacy exclusion; explain all `bootstrap-new` fields; recommend `scan-only, auto-detect, auto, additive-only` when the user wants the safest assessment. `scripts/validate-v3-skills.js` enforces these markers.
- `scripts/check-v3-boundaries.js` flags any diff touching legacy `skills/**` whenever a diff also contains V3 work; Skills V3 additions must stay entirely under `skills-v3/**` to pass `npm run check:v3-boundaries` (run from repo root, not `mcp-server/`).

### Widget Previews (Widgetbook Removed)

- Widgetbook was fully removed in VP-07 (`2026-07-14`); see the Widget V3 Local Web Preview notes above for the removal evidence.
- Additions or changes to shared widgets should consider preview coverage: standalone `preview_*.dart` entrypoints for all widgets. For Widget V3, following the naming convention (`preview_v3_<widget>.dart` with `class V3<Widget>Preview`) and running `dart run tool/generate_v3_preview_registry.dart` is enough to make it reachable through `scripts/serve-v3-preview.sh` — no manual registry edit (see VP-10 below).

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
- Analyze: `flutter analyze`
- Test: `flutter test`
- Build/serve the Widget V3 local preview host: `./scripts/serve-v3-preview.sh` (builds `lib/preview_v3/main.dart` for web and serves it at `http://127.0.0.1:8090`)

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

- Latest deployed Render commit (as of `2026-07-12`): `82ca59401fe21d684b24a3d91e2a5a6cfa4a084e` on `main`, built with Node 24.14.1 and `npm ci`, started `node http-server.js` at `2026-07-11T18:22:52Z`, live at `https://flutter-widget-wallet-mcp.onrender.com`.
- `flutter analyze` passed on 2026-06-25.
- `flutter test` passed on 2026-06-25.
- Theme V3 baseline `V3-01`/`V3-02` was captured on 2026-07-10 at commit `18ed97af7e62579cceea7bc8dd4100d716a159d9`; evidence is stored inline in `task/V3_THEME_MCP_SKILLS_TASKS.md`. `flutter analyze` and all 114 Flutter tests pass after the test-only `PlaceholderAssetBundle` was updated to serve Flutter's binary `AssetManifest.bin`; targeted tests explicitly preserve SVG markup and Lottie JSON behavior. All four MCP baseline gates passed after `npm ci`; the legacy registry contained 14 local tools and 12 remotely exposed read-only tools, and the existing contract snapshot passed unchanged.
- Flutter commands may require permissions to write to the external Flutter SDK cache, depending on sandbox/runtime.
- Golden baselines for ImageCarousel, VisaCard, and receipt widgets are macOS-rendered and their pixel assertions run only on macOS; Linux CI still runs the functional tests. Receipt test font mocks use `/System/Library/Fonts/SFNS.ttf` on macOS and fall back to Flutter's bundled `Roboto-Regular.ttf` on other platforms so the test files remain loadable in Ubuntu CI.

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

- Widgetbook is fully removed from this repository (VP-07, `2026-07-14`): no packages, source files, generated registry, or Cloud workflow remain. `.github/workflows/widgetbook.yml` stays gitignored; do not restore or recommit it. Widget previews now use standalone `preview_*.dart` entrypoints plus the Widget V3 local web preview host under `lib/preview_v3/`.

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
- MCP V3 is implemented under `mcp-server/v3/` with isolated token/widget/foundation catalogs, handlers, and contracts. The local dispatcher now exposes 18 additive V3 tools (32 total); local HTTP exposes 28 read-only tools after adding remote-safe `get_v3_theme_foundation`. All 14 legacy definitions remain unchanged and in their original order. Both legacy generation tools and `generate_v3_widget_code` / `generate_v3_widgetbook_use_case` stay excluded from remote exposure; the currently deployed Render build still exposes the previous 27-tool registry until the new commit is deployed.
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
- Gotcha: `cd mcp-server && npm test` regenerates `mcp-server/mcp.json.example` as a side effect (the "installer generates per-client example files" test writes it with the current absolute repo path baked in). This is expected test behavior, not a real change — `git checkout -- mcp-server/mcp.json.example` after running mcp-server tests if it shows as modified and you didn't intend to touch it.
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
- Local MCP/tooling configs should reference secrets through environment variables where the client supports them reliably and must never be committed. Verified Codex exception: this project's remote MCP currently connects reliably only through the global `~/.codex/config.toml` `http_headers.Authorization = "Bearer ..."` form; protect that untracked file with owner-only permissions.
- Hosted MCP Bearer tokens are distributed privately by Niwat, the repository owner, and must be requested directly from Niwat only; they must not be published in the repo or accepted from another source.
- Verified Codex global setup (`2026-07-13`): configure `[mcp_servers.flutter-widget-wallet-mcp]` with `enabled = true` and the Render `/mcp` URL, then set `[mcp_servers.flutter-widget-wallet-mcp.http_headers] Authorization = "Bearer <TOKEN>"`. Do not set `bearer_token_env_var` for this server. The current Codex CLI has no `--transport` or `--header` options, so this header form must be edited directly in `~/.codex/config.toml`; `codex mcp get` masks the value as `Authorization=*****`.
- `scripts/configure-codex-global-mcp.sh` is the distributable one-command Codex global installer for this verified setup. It securely prompts for the private token, recreates the base server through `codex mcp add --url`, appends the `http_headers.Authorization` table, applies mode `600`, and prints the masked `codex mcp get` result; regression coverage lives in `scripts/configure-codex-global-mcp.test.js`.
- `MCP_REMOTE_BEARER_TOKEN` / `MCP_REMOTE_BEARER_TOKENS` are secrets for the hosted Render MCP endpoint and must be stored only in the Render Dashboard (or other secret manager), never written as literal values in `MEMORY.md`, repo docs, tracked config files, commits, or PR text.
- `render.yaml` at the repo root is the Render Blueprint for the Phase 8 hosting pilot (`rootDir: mcp-server`); its plain env vars (`MCP_REMOTE_HOST`, `MCP_REMOTE_PORT`, `MCP_REMOTE_CHANNEL`) are committed, but secret env vars are declared with `sync: false` and must be set only in the Render Dashboard.
- Verified rollback gotcha (`2026-07-12`): rolling back the Render service `flutter-widget-wallet-mcp` to a previous deploy build does NOT require changing the hosted URL or Bearer secrets — those keep working unchanged. However, `mcp-server/remote_support.js`'s `resolveRemoteCommitSha()` reads `env.MCP_REMOTE_COMMIT_SHA` first if set, and only falls back to `git rev-parse HEAD` when that env var is empty; because this env var is a manually pinned Render Dashboard secret (`sync: false`), rolling back the running build without also updating `MCP_REMOTE_COMMIT_SHA` to the old commit's SHA leaves `/health`/`/info` and the `namespace = repoIdentity::channel::commitSha` cache key reporting a stale commit that no longer matches the code actually running. Any manual rollback must update this one env var; URL/secret rotation is not needed.

### Generated Or Derived Areas

- `lib/generated/intl/`
- `lib/l10n/app_*.arb`
- `lib/config/themes/v3/generated/`
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
5. for Widget V3, `lib/preview_v3/preview_registry.dart` if preview registration is involved

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
- Some docs still describe the project as a broader app foundation, but the current repo also serves as a design-system/widget catalog with standalone/Widget V3 previews and MCP-related tooling.
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
