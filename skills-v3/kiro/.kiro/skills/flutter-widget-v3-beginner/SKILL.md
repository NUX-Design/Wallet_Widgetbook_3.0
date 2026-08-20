---
name: flutter-widget-v3-beginner
description: Create a new Flutter app or publishable Flutter UI package with an installable Theme V3 runtime and starter widget using consumer-owned names, or scan and extend the V3 foundation in an existing Flutter workspace using `flutter-widget-wallet-mcp`. Use for guided new-project setup or existing-project adoption with explicit confirmation before edits.
---

# Flutter Widget V3 Beginner

Use this skill from Kiro by selecting the skill directly or by asking Kiro to scan and bootstrap Theme V3 / Widget V3 usage naturally.

Use this skill when the user wants a brand-new Flutter app ready for Theme V3, or wants to add Widget V3 to an existing Flutter workspace.

The MCP source is V3, but V3 is implementation provenance, not a required consumer-facing name. For a new project or confirmed package mode, expose normal or brand-owned names such as `AppTheme`, `BrandButton`, and `lib/theme/**`; do not expose `V3Theme`, `V3Button`, or `themes/v3` unless the user explicitly chooses `preserve-v3` naming.

## Mandatory Flow

Always run in this order:

1. Ask discovery questions.
2. Scan the workspace.
3. Summarize what exists and what is missing.
4. Ask for confirmation on the execution plan.
5. Execute only the confirmed scope.

Never edit the repo before the question flow completes.

## Discovery Questions

Before asking the user to choose, explain every option in the user's language. Never present bare labels such as `auto-detect` or `additive-only` without saying what they mean, when to use them, and what the skill may change. Recommend the safest choice when the user is unsure.

### 1. Goal

Question: `รอบนี้ต้องการให้ flutter-widget-v3-beginner ทำอะไร`

Options:

- `scan-only` — analyze existing Theme V3 / Widget V3 state only, create nothing, edit nothing, return a gap report.
- `bootstrap-existing` — the workspace already has Theme V3 foundation (`lib/config/themes/v3/generated/`); add a new Widget V3 or fill in missing preview/test/guide for an existing one.
- `bootstrap-new` — create a new Flutter app, install the MCP-provided Theme V3 runtime foundation, add one starter Widget V3 with a standalone preview and tests, then verify Light/Dark behavior.

### 2. Workspace State Preference

Question: `สภาพ workspace ตอนนี้เป็นแบบไหน หรืออยากให้ skill ตีความแบบไหน`

Explain these options before asking:

- `auto-detect` — recommended and safest when the user is unsure. Inspect the workspace and classify it automatically before proposing changes.
- `existing-v3-foundation` — an existing Flutter project that already contains Theme V3, normally including `lib/config/themes/v3/generated/`.
- `existing-flutter-no-v3` — an existing Flutter project with `pubspec.yaml` and `lib/main.dart`, but without the Theme V3 runtime foundation.
- `no-flutter-yet` — the destination is not a Flutter project. Creating it requires the explicit `bootstrap-new` goal.

### 3. Output Shape

Question: `ต้องการให้ผลลัพธ์เป็น Flutter app หรือ Flutter Package UI library`

Explain these options before asking:

- `app` — create a normal Flutter application with `lib/main.dart` for building and running a product app.
- `package-ui-library` — create a reusable package with public exports under `lib/`, package tests, basic package documentation, and a separate `example/` Flutter app for preview and manual testing. The package root does not use `main.dart` as its runtime entrypoint.

For an existing project, detect the current shape from `pubspec.yaml`. Do not convert an existing app to a package implicitly; report the migration and ask for confirmation.

### 4. Target Widget Scope

Question: `ต้องการเพิ่ม/แก้ widget V3 ตัวไหน`

Options: an explicit widget name, or `auto` to let the skill pick from `search_v3_widgets` / `list_v3_widgets`, preferring a widget not yet present in the target repo's `lib/widgets/v3/**`.

### 5. Consumer Naming

Question: `ต้องการให้ชื่อ Theme และ Widget ที่สร้างใน project เป็นแบบไหน`

Explain these options before asking:

- `generic` — recommended. Use normal names such as `AppTheme`, `PrimaryButton`, `UiTheme`, and generic folders such as `lib/theme/` and `lib/widgets/`.
- `brand` — use names supplied by the user, such as `AcmeTheme`, `AcmeButton`, and `lib/acme_ui/`.
- `preserve-v3` — advanced compatibility mode. Keep V3-prefixed paths/classes from the source system. Do not choose this when the library is intended to be consumer-branded.

Collect the theme namespace, widget namespace, public class prefix, and public library/barrel name when `generic` or `brand` is selected. These names control the generated consumer API; they are not just display labels.

### 6. Change Policy

Question: `ให้ skill แตะ repo ได้ระดับไหน`

Explain these options before asking:

- `additive-only` — recommended. Create only missing files. Stop and report before any path collision; never overwrite an existing file.
- `allow-structure-setup` — allow creation of folders and structural files required by V3, but never overwrite existing files implicitly.
- `ask-before-overwrite` — if changing or replacing an existing file becomes necessary, request explicit permission for that file first.

For an existing project, state this allowed scope visibly before confirmation. With `generic` or `brand` naming, use the confirmed consumer namespaces instead of the source-system `v3` paths:

```text
lib/config/themes/<consumer-theme-namespace>/**
lib/widgets/<consumer-widget-namespace>/**
test/widgets/<consumer-widget-namespace>/**
```

State that unrelated legacy theme files and legacy widgets will not be changed.

### Additional Information For `bootstrap-new`

When the user selects `bootstrap-new`, explain and collect:

- `project name` — lowercase Dart package name using `_` instead of spaces, for example `wi_wallet_demo`.
- `destination directory` — a new or empty directory, for example `/Users/<user>/Documents/wi_wallet_demo`.
- `organization identifier` — reverse-domain namespace used by Android/iOS, for example `com.wi.wallet`.
- `target platforms` — only the required values from `android`, `ios`, `web`, `macos`, `windows`, or `linux` to avoid unnecessary platform files.

When `output_shape = package-ui-library`, also collect:

- `package name` — lowercase Dart package name using `_` instead of spaces.
- `public library name` — root barrel filename and import name, normally derived from the package name.
- `example platforms` — platforms needed only by the separate `example/` app.

Show this answer template when useful:

```text
goal: bootstrap-new
workspace: no-flutter-yet
output shape: package-ui-library
widget: auto
policy: additive-only
package name: wi_wallet_ui
destination: /Users/<user>/Documents/wi_wallet_demo
public library: wi_wallet_ui.dart
example platforms: android, ios, web
consumer naming: generic
theme namespace: theme
widget namespace: widgets
public prefix: App
```

If the user wants only the safest assessment of the current workspace, recommend:

```text
scan-only, auto-detect, auto, additive-only
```

## Workspace Scan

Inspect at least:

- whether `flutter` is available and `flutter doctor` reports a usable SDK
- `pubspec.yaml` and `lib/main.dart` (Flutter project detection)
- `lib/config/themes/v3/generated/` or the confirmed consumer theme namespace (Theme V3 foundation readiness)
- `lib/widgets/v3/**` or the confirmed consumer widget namespace and its category/pattern
- `test/widgets/v3/**` or the confirmed consumer test namespace and preview coverage
- whether the target widget already exists (if so, prefer `flutter-widget-v3-upgrade` or `flutter-widget-v3-adapt` instead)

## Summary And Confirmation

Summarize before editing: whether the source Theme V3 foundation exists, how it will be adapted to the confirmed consumer names, what widgets already exist, what will be created/edited, and any risk (most commonly: source identifiers that cannot be safely adapted). Then ask:

Question: `จากสิ่งที่สแกนพบ จะให้ดำเนินการตามแผนนี้หรือไม่`

Options: `proceed`, `revise-scope`, `stop-after-scan`.

## Execute

- For confirmed `bootstrap-new`:
  1. Re-check that the destination does not contain files that would be overwritten. Stop on a non-empty conflicting directory.
  2. For `output_shape = app`, run `flutter create --project-name <name> --org <org> --platforms <platforms> <destination>`. For `output_shape = package-ui-library`, run `flutter create --template=package --project-name <package-name> <destination>` and create a separate `example/` app using only the confirmed example platforms; wire the example app to the package through its path dependency.
  3. Call `get_v3_theme_foundation` without `file`, fetch every manifest entry by exact path, then adapt the source paths, filenames, class names, imports, and public exports to the confirmed consumer naming. Do not copy `v3` into the consumer path when `generic` or `brand` is selected. Preserve behavior and token values; never expose a V3-prefixed symbol in the public API.
  4. Install the confirmed starter widget using `get_v3_widget_metadata` + `get_v3_widget_code`, or scaffold one with `get_v3_flutter_widget_template`. Adapt V3-prefixed widget files/classes/imports to the confirmed consumer names, including preview and tests. Do not perform blind text replacement; inspect references and stop with a gap report if an identifier cannot be safely adapted.
  5. For `app`, create `lib/main.dart` with Material 3 Light/Dark themes using the consumer theme API. For `package-ui-library`, create `lib/<public-library>.dart` as the public export barrel, keep preview/demo wiring in `example/`, wire the example app to the package, and add targeted package tests. User-facing strings remain caller-owned and localization-ready.
  6. Run `dart format .`, `flutter analyze`, and `flutter test`. For packages, also run `dart pub publish --dry-run`. Verify that public exports and generated source contain no `V3`/`v3` names unless `preserve-v3` was selected. When a runnable device is available, smoke-test the example app or standalone preview in Light and Dark themes.
- If the target widget already exists in the MCP V3 catalog: use `get_v3_widget_metadata`, `get_v3_widget_code`, and `get_v3_widget_preview`.
- If it does not exist yet: use `get_v3_flutter_widget_template` to scaffold. When local/stdio MCP is available, `generate_v3_widgetbook_use_case` may optionally produce preview wiring.
- Follow `docs/v3/V3_WIDGET_CONVENTIONS.md` for file layout, naming, and the required `V3 Metadata` guide section.

## Remote-Safe Fallback

When connected through Remote MCP, keep using the remotely exposed `get_v3_flutter_widget_template`, metadata, token, code, and preview tools. Author the Widgetbook use case or standalone preview locally from those read-only results and the target repo conventions; do not call `generate_v3_widgetbook_use_case`, silently switch to a legacy tool, or stop an otherwise valid workflow.

## MCP Tools

- `get_v3_design_system_info`
- `get_v3_theme_foundation`
- `get_v3_codebase_patterns`
- `list_v3_categories`
- `search_v3_widgets`
- `get_v3_widget_metadata`
- `get_v3_widget_code`
- `get_v3_widget_preview`
- `get_v3_flutter_widget_template`
- `generate_v3_widgetbook_use_case`

## Guardrails

- Never assume Theme V3 foundation exists without scanning for `lib/config/themes/v3/generated/` or the confirmed consumer namespace.
- Never create or replace a Flutter project unless the user selected `bootstrap-new` and confirmed the exact destination.
- In existing projects, touch only the confirmed consumer theme/widget/test namespaces and their required public barrels; never modify unrelated legacy theme or widget paths.
- Never fall back to legacy MCP tools or `ThemeColors.get()` when V3 data is missing; report the gap instead.
- If no Flutter project exists and the user did not select `bootstrap-new`, report the gap and offer that mode; do not create a project implicitly.
