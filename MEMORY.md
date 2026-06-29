# MEMORY.md

## Project Snapshot

- Repository type: Flutter widget/design-system repository with a runnable demo app and Widgetbook catalog.
- Primary domain: reusable UI components for a financial app.
- Main package name: `mcp_test_app`
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
- Standalone widget preview: `flutter run -t lib/widgets/<folder>/preview_<name>.dart -d <device>`

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
- Parallel test execution backlog is now tracked in `TASKS.md`, while `WIDGET_TEST_PLAN.md` keeps the higher-level analysis and prioritization.

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
- `mcp-server/` is a separate Node-based MCP helper server.
- `tools/flutter_mcp_2/` is an additional standalone tooling area with its own package manifest.
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

## When To Update This File

Update this file when discovering stable information about:

- architecture
- source-of-truth ownership
- generation workflows
- verification commands
- directory responsibilities
- recurring environment caveats

Do not store temporary debugging notes or task-specific minutiae here.
