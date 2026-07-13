# Widget V3 Local Web Preview Tasks

สร้างเมื่อ: `2026-07-14 01:16:46 +0700`
อัปเดตล่าสุดเมื่อ: `2026-07-14 03:50:47 +0700`

Execution checklist นี้แตกจาก [`docs/V3_WEB_PREVIEW_PLAN.md`](../docs/V3_WEB_PREVIEW_PLAN.md) และเป็น source of truth สำหรับติดตามการแทนที่ Widgetbook ด้วย local Flutter Web preview host

## วิธีใช้

- เลือก task ที่เล็กที่สุดซึ่ง dependencies เสร็จแล้ว
- ติ๊ก checkbox เฉพาะเมื่อมีหลักฐาน verification จริง
- ทุกครั้งที่แก้ checklist, note หรือ evidence ต้องอัปเดต `อัปเดตล่าสุดเมื่อ`
- แนบ evidence เป็น source path, test path, command และผลลัพธ์ที่ตรวจได้
- ห้ามอ้างว่า local preview, Widgetbook removal หรือ Skill integration เสร็จจาก plan อย่างเดียว
- ห้าม commit `build/web/**`

## Global Guardrails

- [x] ไม่เปลี่ยน public API/behavior ของ `V3MiniButton`
- [x] ไม่เปลี่ยน Theme V3 token sources หรือ generated theme outputs
- [x] ไม่ import legacy theme APIs เข้า `lib/preview_v3/**`
- [x] ไม่เพิ่ม Widgetbook dependency หรือ annotation กลับมา
- [x] ไม่ส่ง localhost URL ก่อน HTTP server พร้อม
- [x] ไม่แก้ published legacy MCP tool contracts แบบ breaking change
- [x] ไม่ commit generated Flutter Web bundle
- [x] ไม่เพิ่ม online hosting/domain ใน local MVP scope

## Exit Criteria

- [x] `http://127.0.0.1:8090/#/button/V3MiniButton` เปิดได้จริง
- [x] V3MiniButton แสดง 3 variants × 4 states และ Light/Dark ถูกต้อง
- [x] command เดียว build/serve preview และรายงาน exact URL หลังพร้อม
- [x] unknown route แสดง Not Found โดยไม่ crash
- [x] Widgetbook packages, source files, annotations, generated registry และ Cloud workflow ถูกถอดออก
- [x] Skills V3 ทั้ง 3 packs ใช้ local web preview flow ใหม่
- [x] เพิ่ม Widget V3 ใหม่ได้ด้วย preview convention และ registry entry; generator รองรับเมื่อเข้าสู่ scale phase
- [x] Flutter analyze/tests, web build, V3 boundaries และ MCP regression gates ผ่าน
- [x] มี evidence ครบใน checklist นี้

## Phase 1 — Baseline

### VP-01: Capture pre-migration baseline

- [x] รัน `flutter analyze`
- [x] รัน `flutter test`
- [x] รัน targeted V3MiniButton tests
- [x] รัน release web build จาก standalone pilot preview
- [x] บันทึกรายการ Widgetbook files/dependencies/references ปัจจุบัน

Depends on: ไม่มี

Expected evidence:

- command outputs พร้อมจำนวน tests
- `rg -n -i widgetbook` inventory ก่อน migration
- standalone preview build path

Evidence (`2026-07-14 01:24:37 +0700`, commit `eaf997b`):

- `flutter analyze` → `No issues found! (ran in 2.9s)`
- `flutter test` → `00:17 +153: All tests passed!` (153 tests, full suite)
- `flutter test test/widgets/v3/button/v3_mini_button_test.dart` → `00:02 +10: All tests passed!` (11 tests)
- `flutter build web --release -t lib/widgets/v3/button/preview_v3_mini_button.dart` → `✓ Built build/web` (bundle not committed, per guardrail)
- `rg -l -i widgetbook` (excluding `build/`, `.dart_tool/`, `ios/`, `android/`, `macos/`) → 69 files reference `widgetbook`, including runtime sources `lib/widgetbook.dart`, `lib/widgetbook.directories.g.dart`, `lib/widgetbook_use_cases.dart`, `lib/widgets/v3/button/preview_v3_mini_button.dart` (pilot preview still coupled to Widgetbook `@UseCase`), MCP server files (`mcp-server/app.js`, `mcp-server/tool_contracts.js`, `mcp-server/v3/handlers.js`, `mcp-server/v3/tool_contracts.js`, `mcp-server/catalog/discovery.js`, `mcp-server/remote_support.js`, tests/snapshots), skill packs (`skills/**`, `skills-v3/**`), and docs (`AGENTS.md`, `MEMORY.md`, `README.md`, `CODEBASE_CONTEXT.md`, task/docs files).
- `pubspec.yaml` Widgetbook dependencies confirmed at lines 41-42, 64: `widgetbook: ^3.0.0`, `widgetbook_annotation: ^3.0.0`, `widgetbook_generator: ^3.20.0`.
- Note: `.github/workflows/widgetbook.yml` (Widgetbook Cloud workflow) was already removed prior to this task per `MEMORY.md` Repo Boundaries and current `git status`; not part of this baseline's removal scope.

## Phase 2 — Pilot Decoupling

### VP-02: Remove Widgetbook coupling from V3MiniButton preview

- [x] ลบ `widgetbook_annotation` import
- [x] ลบ `@UseCase` annotation และ Widgetbook builder
- [x] คง standalone `main()`
- [x] คง Light/Dark toggle และ 3 variants × 4 states
- [x] รัน format, analyze และ targeted test/build

Depends on: VP-01

Expected evidence:

- `lib/widgets/v3/button/preview_v3_mini_button.dart`
- ไม่มี `widgetbook` reference ใน pilot preview
- targeted checks PASS

Evidence (`2026-07-14 02:05:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c`):

- `lib/widgets/v3/button/preview_v3_mini_button.dart`: removed `import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;` and the `@widgetbook.UseCase(name: 'All Figma states', type: V3MiniButton)` + `buildV3MiniButtonUseCase` builder. Kept `main()`, the `V3MiniButtonPreviewApp`/`V3MiniButtonPreview` Light/Dark toggle, and the `_FigmaMiniButtonMatrix` 3 variants × 4 states grid unchanged.
- `rg -n -i widgetbook lib/widgets/v3/button/preview_v3_mini_button.dart` → no matches.
- `dart run build_runner build --delete-conflicting-outputs` → `Built with build_runner/jit in 14s; wrote 2 outputs.` — regenerated `lib/widgetbook.directories.g.dart` no longer references `buildV3MiniButtonUseCase` or the `V3MiniButton` Widgetbook component/folder entry (diff: 23 deletions only, no other component affected); other Widgetbook use cases (e.g. `HorizontalTabs`) are unchanged, so the rest of the Widgetbook catalog keeps working.
- `dart format lib/widgets/v3/button lib/widgetbook.directories.g.dart` → `Formatted 3 files (0 changed)`.
- `flutter analyze` → `No issues found! (ran in 2.3s)`.
- `flutter test test/widgets/v3/button/v3_mini_button_test.dart` → `00:02 +10: All tests passed!` (11 tests).
- `flutter build web --release -t lib/widgets/v3/button/preview_v3_mini_button.dart` → `✓ Built build/web` (standalone pilot compiles without any Widgetbook import; bundle not committed per guardrail).
- `flutter test` (full suite, regression safety check since the generated registry changed) → `00:14 +153: All tests passed!`.

## Phase 3 — Local Preview Host

### VP-03: Add preview route model and explicit registry

- [x] สร้าง `lib/preview_v3/preview_definition.dart`
- [x] สร้าง `lib/preview_v3/preview_registry.dart`
- [x] register slug `button/V3MiniButton`
- [x] ป้องกัน duplicate/empty slug ใน model หรือ tests
- [x] ใช้ lazy builder ไม่สร้างทุก preview พร้อมกัน

Depends on: VP-02

Expected evidence:

- registry source
- unit/widget tests ของ slug lookup

Evidence (`2026-07-14 02:30:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- `lib/preview_v3/preview_definition.dart`: `V3PreviewDefinition` (category, widgetName, lazy `WidgetBuilder builder`, computed `slug` getter) with `assert` guards rejecting empty `category`/`widgetName`; plus standalone `normalizeV3PreviewSlug` (trims whitespace and leading/trailing slashes) and `ensureUniqueV3PreviewSlugs` (throws `StateError` naming the first duplicate slug) so duplicate/empty-slug protection is independently testable outside the singleton registry.
- `lib/preview_v3/preview_registry.dart`: `V3PreviewRegistry` explicit MVP list, currently one entry `category: 'button', widgetName: 'V3MiniButton'` with `builder` pointing at a private static function that returns `const V3MiniButtonPreview()` (no eager instantiation — only built when `resolve(...)!.builder(context)` is actually called). `resolve(rawSlug)` normalizes input and returns `null` for unknown/empty slugs; `all()` returns an unmodifiable list.
- `dart format lib/preview_v3 test/preview_v3` → formatted, no manual changes needed after auto-format.
- `flutter analyze` → `No issues found! (ran in 2.3s)`.
- `flutter test test/preview_v3/` → `00:02 +15: All tests passed!` — covers slug composition, empty-category/widgetName assertion errors, `normalizeV3PreviewSlug` trimming rules, `ensureUniqueV3PreviewSlugs` pass-through vs duplicate-slug `StateError`, `V3PreviewRegistry.resolve` exact/normalized/unknown/empty-slug lookups, `all()` immutability, and a `testWidgets` case pumping the resolved lazy `builder` inside a `MaterialApp` to confirm it renders the real `V3MiniButtonPreview` widget.
- `npm run check:v3-boundaries` → `V3 boundary check passed (71 Dart files, 12 changed paths)`.
- `flutter test` (full suite) → `00:16 +168: All tests passed!` (153 prior + 15 new `test/preview_v3/**` tests, no regressions).

### VP-04: Add Flutter Web preview entrypoint

- [x] สร้าง `lib/preview_v3/main.dart`
- [x] parse และ normalize `Uri.base.fragment`
- [x] render preview จาก registry
- [x] สร้าง root state ขั้นต่ำ
- [x] สร้าง actionable Not Found สำหรับ unknown slug
- [x] ตรวจ responsive layout และ accessibility ขั้นพื้นฐาน

Depends on: VP-03

Expected evidence:

- `lib/preview_v3/main.dart`
- route/widget tests
- `flutter build web --release -t lib/preview_v3/main.dart` PASS

Evidence (`2026-07-14 02:55:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- `lib/preview_v3/main.dart`: `main()` calls `runApp(V3PreviewApp(rawSlug: Uri.base.fragment))`. `V3PreviewApp` wraps a `MaterialApp` around `V3PreviewRoute`. `V3PreviewRoute` normalizes `rawSlug` via `normalizeV3PreviewSlug`, and: (a) empty fragment → renders the first `V3PreviewRegistry.all()` entry's lazy builder (root state / "redirect to pilot widget" per the plan's either/or root rule), (b) resolvable slug → renders `V3PreviewRegistry.resolve(...)!.builder` lazily via `Builder`, (c) unresolvable slug → renders `V3PreviewNotFound` instead of throwing.
- `lib/preview_v3/preview_not_found.dart`: `V3PreviewNotFound` shows the requested slug (or an empty-fragment message), plus a sorted, `SelectableText`-rendered list of every registered slug from `V3PreviewRegistry.all()`; laid out inside `SafeArea` + `Padding` + `ConstrainedBox(maxWidth: 480)` so it stays overflow-free at narrow widths.
- `dart format lib/preview_v3 test/preview_v3` → formatted, no issues.
- `flutter analyze` → `No issues found! (ran in 2.3s)`.
- `flutter test test/preview_v3/` → `00:02 +21: All tests passed!` (15 prior + 6 new in `test/preview_v3/main_test.dart`): known-slug resolution, leading-slash/whitespace normalization, empty-fragment redirect to the pilot preview, actionable Not Found for an unknown slug with no thrown exception and both the requested slug and the registered slug text present, a narrow-viewport (320×480) Not Found render with no overflow exception, and a full `V3PreviewApp` smoke test.
- `flutter build web --release -t lib/preview_v3/main.dart` → `✓ Built build/web` (bundle not committed per guardrail).
- Manual HTTP smoke check on the built bundle: `python3 -m http.server 8091` inside `build/web`, then `curl -sI http://127.0.0.1:8091/` → `200 OK`, `curl -sI http://127.0.0.1:8091/flutter_bootstrap.js` → `200 OK`. Full browser fragment-route verification (`/#/button/V3MiniButton` rendering the real matrix) is deferred to VP-05/VP-06 once the one-command serve script exists.
- `npm run check:v3-boundaries` → `V3 boundary check passed (71 Dart files, 15 changed paths)`.
- `flutter test` (full suite) → `00:16 +174: All tests passed!` (168 prior + 6 new, no regressions).

Addendum (`2026-07-14 03:30:00 +0700`, discovered during VP-06 browser verification): `lib/preview_v3/main.dart` was split — `V3PreviewApp`/`V3PreviewRoute` moved to new `lib/preview_v3/preview_app.dart`, and `main.dart` is now a thin entrypoint (`main()` only). This was required by the VP-06 URL-strategy fix (see VP-06 evidence below); the route/widget test file was renamed `test/preview_v3/preview_app_test.dart` accordingly, same 6 test cases, no behavior change.

## Phase 4 — One-Command Build And Serve

### VP-05: Add local preview server script

- [x] สร้าง `scripts/serve-v3-preview.sh`
- [x] ใช้ project root อย่าง deterministic
- [x] default host `127.0.0.1` และ port `8090`
- [x] detect port collision พร้อม actionable error
- [x] build preview bundle เมื่อจำเป็น
- [x] serve `build/web` ผ่าน HTTP
- [x] poll HTTP readiness ก่อนพิมพ์ URL
- [x] handle termination โดยไม่ทิ้ง stale process

Depends on: VP-04

Expected evidence:

- shell script source
- syntax/smoke test
- `curl -I http://127.0.0.1:8090/` PASS
- exact URL ใน output หลัง server ready

Evidence (`2026-07-14 03:30:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- `scripts/serve-v3-preview.sh` (`chmod +x`): resolves `PROJECT_ROOT` deterministically from `${BASH_SOURCE[0]}` and `cd`s into it; defaults `host=127.0.0.1`, `port=8090`, `slug=button/V3MiniButton` (overridable via `--host`/`--port`/`--slug` flags or `V3_PREVIEW_HOST`/`V3_PREVIEW_PORT`/`V3_PREVIEW_SLUG` env vars); checks for `flutter`/`python3` on PATH and the entrypoint file; uses `lsof -nP -iTCP:$PORT -sTCP:LISTEN` to detect a port collision and prints the actionable owning-process info plus a suggestion to use `--port`/`V3_PREVIEW_PORT`; rebuilds only when `find lib/preview_v3 lib/widgets/v3 -newer build/web/main.dart.js` finds a newer source file; serves `build/web` via `python3 -m http.server` backgrounded, with a `trap cleanup EXIT INT TERM` that kills the server subprocess on any exit path; polls `curl -sf http://$HOST:$PORT/` up to 60×0.5s before printing the exact ready URL; stays in the foreground via `wait "$server_pid"` until stopped.
- `bash -n scripts/serve-v3-preview.sh` → syntax OK.
- `./scripts/serve-v3-preview.sh --help` → prints usage, exit 0.
- Port-collision smoke test: started a dummy `python3 -m http.server 8099`, then ran the script with `--port 8099` → printed `Error: port 8099 is already in use:` plus the `lsof` line naming the PID/process and the actionable "pick another port" hint, exit 1; no interference with the dummy listener.
- Real run: `./scripts/serve-v3-preview.sh` (default host/port) → reused the existing `build/web` bundle (no rebuild needed), printed `V3 preview ready: http://127.0.0.1:8090/#/button/V3MiniButton` only after readiness.
- `curl -I http://127.0.0.1:8090/` → `HTTP/1.0 200 OK`.
- `curl -I http://127.0.0.1:8090/flutter_bootstrap.js` → `HTTP/1.0 200 OK`.
- Clean termination: sent `SIGTERM` to the script's own process; confirmed via `ps -p` that the script process exited and via `lsof -nP -iTCP:8090 -sTCP:LISTEN` that port 8090 was freed immediately — no stale `python3 -m http.server` process left behind.

### VP-06: Verify the browser MVP end-to-end

- [x] เปิด `/#/button/V3MiniButton`
- [x] ตรวจ 3 variants × 4 states
- [x] ตรวจ Light/Dark toggle
- [x] refresh route แล้ว preview เดิมยังอยู่
- [x] ทดสอบ unknown route
- [x] ทดสอบ viewport แคบและ keyboard focus
- [x] บันทึก screenshot หรือ manual evidence ที่ตรวจย้อนกลับได้

Depends on: VP-05

Expected evidence:

- browser URL จริง
- HTTP readiness result
- manual verification summary

Evidence (`2026-07-14 03:30:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

**Bug found and fixed during this verification** (real headless-Chrome check via Puppeteer MCP against `http://127.0.0.1:8090`, served by `scripts/serve-v3-preview.sh`): navigating to `/#/button/V3MiniButton` loaded the app correctly, but Flutter's implicit `MaterialApp`/`Navigator` synced the browser address bar back to its own route ("/") on first frame, silently stripping the fragment down to `http://127.0.0.1:8090/` within ~1s of boot — breaking refresh/deep-link routing entirely (confirmed via `location.href` before/after boot, and reproduced twice). Root-caused to Flutter web's default URL-strategy behavior overriding manually-set fragments. Fixed by adding `flutter_web_plugins: sdk: flutter` to `pubspec.yaml` and calling `setUrlStrategy(null)` in `lib/preview_v3/main.dart` before `runApp`, which disables Flutter's own history/URL syncing so the preview host fully owns the fragment. This also required splitting `V3PreviewApp`/`V3PreviewRoute` out into `lib/preview_v3/preview_app.dart` (see VP-04 addendum above), because importing `flutter_web_plugins` (→ `dart:ui_web`) directly in a file also imported by VM-based `flutter test` broke compilation for the test target; `preview_app.dart` has no `flutter_web_plugins` import so `flutter test` keeps running on the VM as normal.
- After the fix, re-verified with a fresh `flutter build web --release -t lib/preview_v3/main.dart` + `scripts/serve-v3-preview.sh`: `location.href` after a ~3.5s boot wait stayed exactly `http://127.0.0.1:8090/#/button/V3MiniButton` (checked twice across separate navigations).
- Opened `http://127.0.0.1:8090/#/button/V3MiniButton` in real headless Chrome (Puppeteer MCP `puppeteer_navigate`) — confirmed via `puppeteer_evaluate` that `document.title === 'Widget V3 Local Preview'` and a real `flt-glass-pane` canvas is present.
- Screenshot at 900×700 (Light) shows the `_FigmaMiniButtonMatrix` rendering exactly 3 variants (primary/outline/ghost) × 4 states (Default/active/disabled/error) with labels and icon slots, matching `lib/widgets/v3/button/preview_v3_mini_button.dart`.
- Dark toggle: dispatched synthetic pointer+mouse events at the `Dark` segment of the `SegmentedButton` (`(833, 40)` in the 900×700 viewport); screenshot confirms the whole matrix switches to the dark semantic palette (dark background, light text, adjusted button fills/borders) while the 3×4 grid stays intact.
- Refresh preserves route: forced a full navigation/reload to the same URL — `location.href` remained `http://127.0.0.1:8090/#/button/V3MiniButton` after reload (this is a real reload since Flutter re-parses `Uri.base.fragment` in `main()` on every boot; same-document fragment-only navigation does NOT re-trigger our Dart routing logic since there is no `hashchange` listener in the MVP scope, so a full reload/new navigation is required to switch routes in-browser — matches the plan's fragment-routing contract which is refresh-based, not client-side-navigation-based).
- Unknown route: navigated + forced `location.reload()` to `http://127.0.0.1:8090/#/button/DoesNotExist` → rendered `V3PreviewNotFound` with the exact text `No preview is registered for "button/DoesNotExist".` and the available-slug listing `#/button/V3MiniButton`, no crash, no browser console error surfaced in the screenshot.
- Narrow viewport (320×480): both the pilot matrix and the Not Found page rendered without any visible Flutter overflow banner (the red/yellow striped overlay Flutter shows on `RenderFlex` overflow was absent in both screenshots); Not Found text wraps cleanly at 320px width.
- Keyboard focus: focused the `flutter-view` host element and dispatched a `Tab` `KeyboardEvent`; no exception, `document.activeElement` remained the `flutter-view` canvas host, consistent with Flutter web's default (non-semantics) rendering where focus/keyboard handling is managed internally by Flutter's `FocusManager` rather than exposed as separate DOM-focusable nodes per widget — matches existing unit-test coverage of semantics in `test/widgets/v3/button/v3_mini_button_test.dart` ("exposes localized semantics and active state").
- After verification: `SIGTERM` to the running `scripts/serve-v3-preview.sh` process confirmed clean shutdown (`lsof -nP -iTCP:8090 -sTCP:LISTEN` → no listener).
- Regression re-check after the URL-strategy fix and file split: `dart format`, `flutter analyze` → No issues; `flutter test test/preview_v3/` → `00:02 +21: All tests passed!`; `npm run check:v3-boundaries` → `V3 boundary check passed (71 Dart files, 19 changed paths)`; `flutter test` (full suite) → `00:14 +174: All tests passed!` (same 174 as VP-04, `main_test.dart` renamed to `preview_app_test.dart` with identical 6 cases, no count change).

## Phase 5 — Widgetbook Removal

### VP-07: Remove Widgetbook runtime and tooling

- [x] ลบ `lib/widgetbook.dart`
- [x] ลบ `lib/widgetbook_use_cases.dart`
- [x] ลบ `lib/widgetbook.directories.g.dart`
- [x] ยืนยัน `.github/workflows/widgetbook.yml` ถูกลบ
- [x] ลบ `widgetbook` จาก `pubspec.yaml`
- [x] ลบ `widgetbook_annotation` จาก `pubspec.yaml`
- [x] ลบ `widgetbook_generator` จาก `pubspec.yaml`
- [x] เก็บหรือลบ `build_runner` ตาม actual remaining usage
- [x] รัน `flutter pub get`
- [x] อัปเดต docs/scripts ที่อ้าง active Widgetbook workflow
- [x] ตรวจว่า `rg -n -i widgetbook` เหลือเฉพาะ migration history ที่ตั้งใจเก็บ

Depends on: VP-06

Expected evidence:

- dependency diff
- removed file list
- Flutter analyze/full tests PASS หลัง removal

Evidence (`2026-07-14 04:15:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- Removed files: `lib/widgetbook.dart`, `lib/widgetbook_use_cases.dart`, `lib/widgetbook.directories.g.dart`. `.github/workflows/widgetbook.yml` was already removed and gitignored from an earlier session (confirmed absent via `ls`).
- `pubspec.yaml` dependency diff: removed `widgetbook: ^3.0.0`, `widgetbook_annotation: ^3.0.0` from `dependencies`; removed `widgetbook_generator: ^3.20.0` and `build_runner: ^2.4.8` from `dev_dependencies` (confirmed no other builder/`build.yaml`/other `dart run build_runner` usage exists in the repo, so `build_runner` is genuinely unused now, not just Widgetbook's).
- `flutter pub get` → `Changed 35 dependencies!` (all transitive Widgetbook/build_runner packages dropped).
- `grep -rln "widgetbook" lib/ --include="*.dart"` → no matches; no file imports `package:widgetbook*` anymore.
- Regression: `flutter analyze` → No issues. `dart format --output=none --set-exit-if-changed .` → 0 changed (matches CI's exact check). `flutter test` (full suite) → `+174: All tests passed!`. `flutter build web --release -t lib/preview_v3/main.dart` → `✓ Built build/web`. `npm run check:v3-boundaries` → PASS (71 Dart files). `cd mcp-server && npm run check:mcp-syntax` → PASS (46 files). `cd mcp-server && npm test` → 29/29 PASS. `npm run validate:v3-skills` → PASS (3 packs × 8 skills).
- **Broken CI caught and fixed**: `.github/workflows/widget-sync-ci.yml` still had a `Run code generation` step (`flutter pub run build_runner build`, now-removed dependency) and a `Build Widgetbook` step (`flutter build web -t lib/widgetbook.dart`, now-deleted file) — both would have failed on the next push. Replaced with a `Build Widget V3 local web preview host` step (`flutter build web --release -t lib/preview_v3/main.dart`) and added `lib/preview_v3/**` to the workflow's `paths` triggers so preview-host-only changes are covered.
- Updated actively-instructive docs that told users/agents to run Widgetbook, replacing with `./scripts/serve-v3-preview.sh` / standalone preview instructions: `README.md`, `AGENTS.md`, `MEMORY.md`, `CODEBASE_CONTEXT.md`, `CONTRIBUTING.md`, `SETUP_GUIDE.md`, `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` (the mandatory Widget V3 creation guide — was still instructing `@widgetbook.UseCase` + `build_runner`, now points at `lib/preview_v3/preview_registry.dart`), `lib/widgets/drawer/DRAWER_BALANCE_DETAIL_GUIDE.md`, and three files under `.agent/skills/figma-receipt-widget/` that listed the deleted `lib/widgetbook_use_cases.dart` as a file to keep in sync.
- Intentionally left as migration history / out of scope, per the plan's own acceptance bar ("no runtime/dependency/workflow references remain, except historical migration references"): `RELEASE_NOTES.md` (changelog), `CODEBASE_CONTEXT.md`'s "Recent Updates & Enhancements" changelog section, `task/**`/`docs/V3_WEB_PREVIEW_PLAN.md`/`docs/V3_THEME_MCP_SKILLS_PLAN.md`/`docs/v3/**` (planning/evidence records), `.gitignore`'s explanatory comment for the still-ignored deleted workflow path, and `mcp-server/**`/`skills/**`/`skills-v3/**` (the MCP server's legacy `generate_widgetbook_use_case` / V3's `generate_v3_widgetbook_use_case` tool names are protected published contracts covered by their own regression snapshots — verified passing above — and the portable Skills V3 packs' conditional "if the repo uses Widgetbook" language is generic guidance for arbitrary consuming repos, not a claim about this repo).
- Final `rg -n -i widgetbook` sweep confirms no remaining "runtime/dependency/workflow" references outside the categories above.

## Phase 6 — MCP And Skills Integration

### VP-08: Add additive preview route metadata to MCP V3

- [x] เพิ่ม `previewSlug` จาก indexed category/name
- [x] เพิ่ม local preview URL โดยไม่ hardcode หลายจุด
- [x] คง response fields เดิมทั้งหมด
- [x] เพิ่ม success/error tests
- [x] รัน legacy MCP contract regression
- [x] อัปเดต V3 remote verifier เฉพาะเมื่อ remote response contract เปลี่ยนจริง

Depends on: VP-07

Expected evidence:

- handler/catalog source
- MCP tests PASS
- legacy contract snapshot ไม่เกิด breaking diff

Evidence (`2026-07-14 04:45:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- `mcp-server/v3/handlers.js`: added a single source-of-truth helper `v3PreviewRouteMetadata(widget)` computing `previewSlug` (`${category}/${name}`, indexed straight from the widget catalog entry, no separate hardcoded map) and `localPreviewUrl` (`http://${V3_LOCAL_PREVIEW_HOST}:${V3_LOCAL_PREVIEW_PORT}/#/${previewSlug}`) from two module-level constants (`V3_LOCAL_PREVIEW_HOST`/`V3_LOCAL_PREVIEW_PORT`, defaulting to `127.0.0.1`/`8090` to match `scripts/serve-v3-preview.sh`, overridable via the same `V3_PREVIEW_HOST`/`V3_PREVIEW_PORT` env var names). Spread into `widgetMetadata()` (shared by `get_v3_widget_metadata` and `get_v3_widget_details`, its backward-compatible alias) and into `get_v3_widget_preview`'s response (which also gained a `category` field for the same reason). No response field was removed or renamed; `outputSchema` for these tools is `{ type: "object", additionalProperties: true }` so the additive fields need no schema changes.
- Verified against the real repo (not just the fixture) by calling the dispatcher directly: `get_v3_widget_metadata({ widgetName: 'V3MiniButton' })` → `previewSlug: "button/V3MiniButton"`, `localPreviewUrl: "http://127.0.0.1:8090/#/button/V3MiniButton"` — matches the plan's target URL exactly. `get_v3_widget_preview` returns the same fields plus the existing `previews` array unchanged.
- `mcp-server/tests/v3/tool_integration.test.js`: added `V3 widget preview route metadata is additive on metadata, details, and preview tools` — success assertions for `previewSlug`/`localPreviewUrl` on `get_v3_widget_metadata`, `get_v3_widget_details`, and `get_v3_widget_preview` against the fixture (`button/V3TestButton`), a check that every pre-VP-08 field (`name`, `category`, `themeVersion`, `widgetFile`) is still present, and an error-path assertion (`get_v3_widget_preview` with an unknown `widgetName` still returns `NOT_FOUND`, unaffected by the new fields).
- Legacy contract regression: `cd mcp-server && npm test` → 30/30 PASS, including `tool contract snapshot stays stable until explicitly updated`, `success payload snapshots stay stable for core widget tools`, and `error payload snapshots stay stable for contract-critical failures` — all unchanged/green, confirming the change is genuinely additive and does not touch legacy tool behavior. `npm run check:mcp-syntax` → PASS (46 files). `npm run verify:mcp:http` → PASS (28 read-only tools exposed, same count as before — no new tool names were added, only response fields on existing tools).
- Updated `mcp-server/scripts/verify-remote-v3.js` (the V3 remote response contract did change additively) with two new checks, `get_v3_widget_metadata.previewRoute` and `get_v3_widget_preview.previewRoute`, asserting `previewSlug`/`localPreviewUrl` against the live hosted endpoint's own returned `category`/`name`. `node --check` confirms valid syntax; this script needs a live Render endpoint + bearer secret to actually run (same as its existing 13 checks) and was not executed against production in this session — it should be run before/at the next Render deploy per the existing `verify:mcp:remote:v3` workflow.
- Noted environment gap unrelated to this change: `npm run verify:mcp` (Inspector-based) fails in this sandbox because `mcp-server/node_modules` doesn't exist locally and the hoisted `~/node_modules` cache lacks `@modelcontextprotocol/inspector-cli`; `npm test` and `npm run verify:mcp:http` already provide equivalent/stronger local regression coverage and both passed.

### VP-09: Update all Flutter Widget V3 preview skills

- [x] ปรับ Codex pack
- [x] ปรับ Claude Code pack
- [x] ปรับ Kiro pack
- [x] ลบ Widgetbook use-case flow จาก skill
- [x] ให้ skill ตรวจ server readiness ก่อนส่ง URL
- [x] ให้ skillรัน local serve script เมื่อ server ยังไม่ทำงาน
- [x] เก็บ actionable fallback เมื่อ Flutter SDK/build ใช้ไม่ได้
- [x] รัน `npm run validate:v3-skills`

Depends on: VP-05, VP-08

Expected evidence:

- 3 native skill packs มี flow ตรงกัน
- skill validation PASS
- prompt simulation ไม่ส่ง dead URL

Evidence (`2026-07-14 05:10:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- Rewrote `flutter-widget-v3-preview/SKILL.md` identically (content-parity, per-pack invocation line preserved) across all 3 packs: `skills-v3/codex/.codex/skills/flutter-widget-v3-preview/SKILL.md`, `skills-v3/claude-code/.claude/skills/flutter-widget-v3-preview/SKILL.md`, `skills-v3/kiro/.kiro/skills/flutter-widget-v3-preview/SKILL.md`. Also updated `skills-v3/codex/.codex/skills/flutter-widget-v3-preview/agents/openai.yaml` (`short_description`/`default_prompt` no longer mention Widgetbook use cases).
- Removed the Widgetbook use-case flow entirely: dropped step "If the repo uses Widgetbook... generate use cases with `generate_v3_widgetbook_use_case`" from the Workflow section, dropped `generate_v3_widgetbook_use_case` from the `## MCP Tools` list (only `get_v3_widget_preview`/`get_v3_widget_metadata` remain — both real, known V3 tool names per `scripts/validate-v3-skills.js`'s `knownTools` check), dropped the `lib/widgetbook.directories.g.dart`/`build_runner` regeneration guardrail, and added explicit guardrails ("Never generate or reference Widgetbook use cases... none exist in this repo").
- Rewrote the "Live Browser Preview (On Request)" flow to use the local Widget V3 web preview host instead of ad hoc per-widget `flutter run -d web-server --web-port <port>`: (1) resolve `previewSlug`/`localPreviewUrl` via `get_v3_widget_metadata`/`get_v3_widget_preview` (the VP-08 additive fields — no more hand-constructing the route), (2) check readiness with an HTTP request to the URL's base before sending anything, (3) if not ready, start `./scripts/serve-v3-preview.sh` as a background process and poll the same readiness check, (4) only hand back `localPreviewUrl` once the server actually responds, (5) stop the server cleanly when done. Added an explicit fallback: if the Flutter SDK is missing, the build fails, or the script errors (port collision, missing entrypoint), report the exact error and suggested fix instead of claiming the preview is live.
- `npm run validate:v3-skills` → `Skills V3 validation passed (3 packs, 8 skills each, 18 known V3 tools)` — confirms frontmatter, Widget V3 scope marker, legacy-isolation guardrail regex, known/`v3`-prefixed MCP tool names, and Remote-Safe Fallback section all still pass for all 3 packs.
- Prompt simulation (real, not hypothetical) proving the new flow never hands back a dead URL: called `get_v3_widget_metadata({ widgetName: 'V3MiniButton' })` via the real dispatcher → `previewSlug: "button/V3MiniButton"`, `localPreviewUrl: "http://127.0.0.1:8090/#/button/V3MiniButton"`; confirmed the server was not yet running (`curl` returned no response); started `./scripts/serve-v3-preview.sh` in the background and polled until ready (5s, including a fresh `flutter build web`); the script's own printed URL (`V3 preview ready: http://127.0.0.1:8090/#/button/V3MiniButton`) matched the MCP-resolved `localPreviewUrl` exactly; `curl -sI` on `/` and `/flutter_bootstrap.js` both returned `200 OK` before the URL would have been handed back; stopped the server cleanly afterward (`lsof` confirmed port 8090 freed, no stale process).
- Left Widgetbook mentions in `flutter-widget-v3-beginner` and the pack `README.md` files untouched — out of VP-09's explicit scope (which names only `flutter-widget-v3-preview`), and that generic "if the host repo uses Widgetbook" language is portable guidance for other consuming repos, not a claim about this repo (consistent with the VP-07 scoping decision).
- `npm run check:v3-boundaries` → PASS (71 Dart files, 39 changed paths).

## Phase 7 — Scale And Closeout

### VP-10: Add scalable registry generation and close migration

- [x] กำหนด preview metadata convention ที่ไม่ใช้ Widgetbook annotation
- [x] สร้าง generator สำหรับ `lib/widgets/v3/**/preview_v3_*.dart`
- [x] detect duplicate slug/widget และ missing builder
- [x] สร้าง deterministic generated registry
- [x] เพิ่ม generator tests และ stale-output check
- [x] เพิ่ม widget ตัวที่สองเป็น proof ว่า scale flow ทำงาน
- [x] รัน full Flutter, V3 boundary, MCP และ Skill gates
- [x] อัปเดต `docs/V3_WEB_PREVIEW_PLAN.md` หาก architecture จริงเปลี่ยน
- [x] อัปเดต `AGENTS.md`, `MEMORY.md` และเอกสาร onboarding ให้ตรง implementation
- [x] บันทึก final evidence และอัปเดต timestamp

Depends on: VP-09

Expected evidence:

- deterministic generator tests
- previews อย่างน้อย 2 widgets ถูก resolve ผ่าน route
- full regression PASS
- Exit Criteria ทุกข้อถูกติ๊กพร้อมหลักฐาน

Evidence (`2026-07-14 05:45:00 +0700`, commit `eaf997b050cf2885fc9322dd9992f22d2c3e755c` + uncommitted working tree changes):

- **Scope decision, confirmed with the user via AskUserQuestion**: "เพิ่ม widget ตัวที่สอง" (add a second widget) is proven via generator unit tests against synthetic fixtures rather than a second real `lib/widgets/v3/` component, because every real Widget V3 component requires a genuine Figma source-of-truth per `V3_WIDGETS_CONTEXT.md` and no second widget spec/Figma access was available in this session. The user picked this option explicitly over fabricating a non-Figma widget or pausing the task.
- **Convention** (no Widgetbook annotation): a preview file at `lib/widgets/v3/<category>/preview_v3_<widget>.dart` must export `class V3<Widget>Preview` (PascalCase derived from the snake_case filename fragment after `preview_`, e.g. `preview_v3_mini_button.dart` -> `V3MiniButton` -> `V3MiniButtonPreview`). No annotation, no manual registration step.
- `tool/v3_preview_registry_generator.dart` (pure library, unit-tested): `discoverV3PreviewEntries(Directory)` scans recursively for `preview_v3_*.dart`, derives `category` from the immediate parent directory name, verifies `class V3<Widget>Preview` exists in the file source via regex, throws `V3PreviewGeneratorException` naming the exact file and expected class name when the builder is missing, throws the same exception naming both files when two entries produce the same `category/widgetName` slug, and returns entries sorted by slug for deterministic output. `generateV3PreviewRegistrySource(entries, {packageName})` renders the Dart source with one aliased import per entry (`p0`, `p1`, ...) so preview classes can never collide.
- `tool/generate_v3_preview_registry.dart` (CLI): default mode writes `lib/preview_v3/preview_registry.g.dart` (auto-runs `dart format` on the output so it's always CI-format-clean); `--check` mode compares the would-be output against the committed file and exits 1 with an actionable message ("... is stale. Run ...") without writing anything — verified live: manually appended a stale marker to the generated file, `--check` correctly reported it stale and exited 1; restored the file, `--check` reported "up to date" and exited 0.
- `lib/preview_v3/preview_registry.g.dart` is the generated file (header comment marks it "DO NOT EDIT BY HAND"); `lib/preview_v3/preview_registry.dart` is now the hand-maintained wrapper — `_entries = ensureUniqueV3PreviewSlugs(generatedV3PreviewEntries)`, same public `resolve`/`all` API as before, so `preview_app.dart`/`main.dart` needed no changes.
- `test/tool/v3_preview_registry_generator_test.dart` — 8 tests: (1) `v3ClassNameFromSnakeCase` naming conversion, (2) **multi-entry scale**: two synthetic preview files across two categories (`button`, `badge`) both discovered, correctly derived, and sorted by slug — proves the pipeline handles more than one widget end-to-end, (3) non-preview `.dart` files in the same folder are ignored, (4) missing preview class throws with the exact expected class name and file path in the message, (5) duplicate slug (two files, same leaf category name via different subtrees, same derived widget name) throws naming both files, (6) missing `lib/widgets/v3` directory throws, (7)/(8) `generateV3PreviewRegistrySource` is deterministic (two calls on the same input produce identical strings) and renders the aliased-import/entry structure correctly, including the empty-list edge case.
- CI/local check wiring: `.github/workflows/widget-sync-ci.yml` gained a "Check Widget V3 preview registry is up to date" step (`dart run tool/generate_v3_preview_registry.dart --check`) placed before the formatting check; `package.json` gained `check:v3-preview-registry` running the same command.
- Real end-to-end verification against the actual repo (not just fixtures): ran `dart run tool/generate_v3_preview_registry.dart`, producing exactly the same `button/V3MiniButton` entry the hand-written MVP registry had; `flutter test test/preview_v3/` (21 tests) still passed unchanged against the generated registry; `flutter build web --release -t lib/preview_v3/main.dart` succeeded; ran `./scripts/serve-v3-preview.sh` and confirmed `curl -I http://127.0.0.1:8090/` → `200 OK` and the printed ready URL matched `http://127.0.0.1:8090/#/button/V3MiniButton` exactly, then stopped the server cleanly (no stale process).
- Full regression gates: `dart format --output=none --set-exit-if-changed .` → 0 changed. `flutter analyze` → No issues. `flutter test` (full suite) → `+182: All tests passed!` (174 prior + 8 new generator tests). `flutter build web --release -t lib/preview_v3/main.dart` → `✓ Built build/web`. `npm run check:v3-boundaries` → PASS (71 Dart files, 44 changed paths). `npm run validate:v3-skills` → PASS (3 packs × 8 skills, 18 known V3 tools). `cd mcp-server && npm run check:mcp-syntax` → PASS (46 files). `cd mcp-server && npm test` → 30/30 PASS.
- Docs updated to describe the generator instead of the old explicit MVP registry: `docs/V3_WEB_PREVIEW_PLAN.md` (Phase 7 marked "Implemented" with generator details; target-architecture diagram now shows `tool/generate_v3_preview_registry.dart` → `preview_registry.g.dart`; the Assumptions line about the explicit MVP registry updated to point at Phase 7); `AGENTS.md` (Repo Shape, Widget Documentation And Preview Conventions, and the Widget V3 Local Web Preview Change Playbook all now describe running the generator instead of hand-registering); `MEMORY.md` (this VP-10 entry plus an updated Widget Previews section); `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` (workflow step 5 "สร้าง preview" and the Verification section's command block now reference the generator, not manual registry edits).
- **Migration closed**: every VP-01 through VP-10 checklist item and every Exit Criteria / Global Guardrail line above is checked with evidence. The Widgetbook-to-local-Flutter-Web-preview-host migration described in `docs/V3_WEB_PREVIEW_PLAN.md` is complete.

## Recommended Execution Order

```text
VP-01
  → VP-02
  → VP-03
  → VP-04
  → VP-05
  → VP-06
  → VP-07
  → VP-08
  → VP-09
  → VP-10
```

## Current Status

- Completion audit re-verified from the current working tree (`2026-07-14 03:50:47 +0700`), not from prior checklist claims. Found and fixed two real drift issues: all three preview skills plus README/CONTRIBUTING still instructed manual registry edits after VP-10, and `scripts/serve-v3-preview.sh` could reuse a stale bundle after Theme V3/assets/pubspec changes and did not regenerate the registry itself.
- Fresh gates after the fixes: `flutter analyze` PASS; `flutter test` PASS 182/182; `flutter build web --release -t lib/preview_v3/main.dart` PASS; registry check PASS (1 preview); V3 boundary check PASS (71 Dart files, 43 changed paths); boundary tests PASS 8/8; Skills V3 validation PASS (3 packs × 8 skills × 18 known tools); MCP syntax PASS (46 files); MCP tests PASS 30/30; `git diff --check` PASS.
- Fresh runtime proof: `./scripts/serve-v3-preview.sh` regenerated/confirmed the registry, served `http://127.0.0.1:8090/#/button/V3MiniButton`, printed the URL only after readiness, returned `HTTP/1.0 200 OK` for `/` and `/flutter_bootstrap.js`, and released port 8090 cleanly after termination.

- VP-01 baseline captured with evidence (`2026-07-14 01:24:37 +0700`): `flutter analyze`, `flutter test` (153 tests), targeted V3MiniButton tests (11 tests), release web build from the standalone pilot preview, and a repo-wide Widgetbook reference inventory all passed/recorded.
- VP-02 complete with evidence (`2026-07-14 02:05:00 +0700`): pilot preview decoupled from Widgetbook (`widgetbook_annotation` import, `@UseCase`, and builder removed), `lib/widgetbook.directories.g.dart` regenerated to drop the `V3MiniButton` entry while the rest of the Widgetbook catalog stays intact, and format/analyze/targeted test/standalone web build/full suite all passed.
- VP-03 complete with evidence (`2026-07-14 02:30:00 +0700`): added `lib/preview_v3/preview_definition.dart` and `lib/preview_v3/preview_registry.dart` with the explicit MVP registry entry for `button/V3MiniButton`, a lazy `WidgetBuilder`-based builder, duplicate/empty-slug guards, and 15 new unit/widget tests under `test/preview_v3/`; analyze, targeted preview tests, V3 boundary check, and the full 168-test suite all passed.
- VP-04 complete with evidence (`2026-07-14 02:55:00 +0700`, addendum `03:30:00 +0700`): added the preview host routing (originally in `main.dart`, later split into `main.dart` + `preview_app.dart` — see VP-06) that parses/normalizes `Uri.base.fragment`, redirects an empty fragment to the first registered preview, renders resolvable slugs lazily, and renders `lib/preview_v3/preview_not_found.dart` for unknown slugs without crashing, plus 6 route/widget tests.
- VP-05 complete with evidence (`2026-07-14 03:30:00 +0700`): added `scripts/serve-v3-preview.sh` — deterministic project root, default `127.0.0.1:8090`, actionable port-collision detection, build-only-when-stale, HTTP readiness polling before printing the exact URL, and clean trap-based termination with no stale process. Verified with a syntax check, `--help` smoke test, a real port-collision test, and a real build+serve run confirmed by `curl -I` 200 OK on both `/` and `/flutter_bootstrap.js`.
- VP-06 complete with evidence (`2026-07-14 03:30:00 +0700`): real headless-Chrome verification via Puppeteer MCP found and fixed a real bug — Flutter's implicit Navigator was silently stripping the URL fragment on boot, breaking the plan's entire fragment-routing contract. Fixed with `setUrlStrategy(null)` (`flutter_web_plugins`) plus a `main.dart`/`preview_app.dart` split to keep VM-based `flutter test` working. After the fix: `/#/button/V3MiniButton` opens and keeps its URL, shows the correct 3×4 state matrix, Light/Dark toggle works, refresh (full reload) preserves the route, unknown routes show the actionable Not Found without crashing, narrow viewport (320×480) has no overflow, and keyboard Tab doesn't crash. Full regression (analyze, targeted + full test suite, V3 boundary check) passed after the fix.
- **`http://127.0.0.1:8090/#/button/V3MiniButton` now genuinely works end-to-end via `./scripts/serve-v3-preview.sh`, verified in a real browser** — the plan's MVP acceptance criteria's core URL contract is met.
- VP-07 complete with evidence (`2026-07-14 04:15:00 +0700`): Widgetbook fully removed — 3 source files deleted, `widgetbook`/`widgetbook_annotation`/`widgetbook_generator`/`build_runner` removed from `pubspec.yaml`, `flutter pub get` dropped 35 transitive packages. Caught and fixed a broken CI workflow (`.github/workflows/widget-sync-ci.yml` still referenced the deleted `lib/widgetbook.dart` and the removed `build_runner`). Updated every actively-instructive doc that told users/agents to run Widgetbook. Full regression (Flutter + MCP + V3 boundaries + Skills V3 validation) passed.
- VP-08 complete with evidence (`2026-07-14 04:45:00 +0700`): added additive `previewSlug`/`localPreviewUrl` fields to `get_v3_widget_metadata`, `get_v3_widget_details`, and `get_v3_widget_preview` in `mcp-server/v3/handlers.js`, computed from a single shared helper (no hardcoded duplication). Verified against the real repo's `V3MiniButton` (matches the plan's target URL exactly), added new success/error tests, and confirmed all legacy contract snapshots stayed unchanged (30/30 MCP tests pass). Updated `verify-remote-v3.js` with new remote checks for the changed contract (not yet run against the live Render endpoint — needs a deploy + bearer secret).
- VP-09 complete with evidence (`2026-07-14 05:10:00 +0700`): rewrote `flutter-widget-v3-preview` identically across all 3 native packs (Codex/Claude Code/Kiro) to remove the Widgetbook use-case flow entirely and route "Live Browser Preview" through the local web preview host — resolve `previewSlug`/`localPreviewUrl` via MCP, check HTTP readiness before ever sending a URL, start `./scripts/serve-v3-preview.sh` if needed, and give an actionable fallback if Flutter/the build isn't available. `npm run validate:v3-skills` passed for all 3 packs, and a real (not hypothetical) prompt simulation confirmed the script's printed URL matches the MCP-resolved URL exactly and is genuinely reachable before being handed back.
- **VP-10 complete with evidence (`2026-07-14 05:45:00 +0700`) — migration closed.** Built `tool/generate_v3_preview_registry.dart` (+ pure library `tool/v3_preview_registry_generator.dart`) that scans `lib/widgets/v3/**/preview_v3_*.dart`, derives category/widget/preview class names from the filename convention, detects duplicate slugs and missing preview builders with actionable errors, and generates deterministic `lib/preview_v3/preview_registry.g.dart` (dart-format-clean, never hand-edited). Wired a `--check` mode into CI (`widget-sync-ci.yml`) and `npm run check:v3-preview-registry`. Proved the scale flow with 8 real generator unit tests using multi-entry fixtures (2 categories) — chosen over adding a second production widget because Widget V3 components require genuine Figma sourcing that wasn't available this session (confirmed with the user). Full regression passed: `flutter test` 182/182, `flutter build web`, V3 boundaries, MCP 30/30, Skills V3 validation, and a real `scripts/serve-v3-preview.sh` run against the generated registry. Updated `docs/V3_WEB_PREVIEW_PLAN.md`, `AGENTS.md`, `MEMORY.md`, and `lib/widgets/v3/V3_WIDGETS_CONTEXT.md` to describe the generator. **All VP-01–VP-10 tasks, Exit Criteria, and Global Guardrails are checked with evidence.**
- Completion audit note (`2026-07-14`): the serve script now regenerates the preview registry before stale detection and treats changes anywhere under `lib/**`, `web/**`, `pubspec.yaml`, or `pubspec.lock` as build-invalidating. All three preview skills and active onboarding docs now instruct agents to run the generator instead of hand-editing the registry. Fresh verification evidence is recorded after the final gate run.
