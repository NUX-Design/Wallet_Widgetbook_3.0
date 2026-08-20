---
name: flutter-widget-beginner
description: Scan the current workspace and bootstrap a Flutter app or publishable Flutter UI package with consumer-owned theme and widget names, ready to consume widgets from `flutter-widget-wallet-mcp`. Use when a repo may or may not already contain a Flutter project and the user wants guided setup with explicit scope questions before any edits.
---

# Flutter Widget Beginner

Invoke with `/flutter-widget-beginner` in Claude Code, or ask Claude to scan and bootstrap the workspace naturally.

Use this skill when the user wants to start using `flutter-widget-wallet-mcp` in a workspace that may be empty, may already contain a Flutter app, or may need missing foundation such as theme, localization, tests, previews, or Widgetbook.

## Mandatory Flow

Always run in this order:

1. Ask discovery questions.
2. Scan the workspace.
3. Summarize what exists and what is missing.
4. Ask for confirmation on the execution plan.
5. Execute only the confirmed scope.

Never edit the repo before the question flow completes.

## Discovery Questions

Ask these questions first. Include the meaning of each answer so the user knows the scope impact.

### 1. Goal

Question:
- `รอบนี้ต้องการให้ flutter-widget-beginner ทำอะไร`

Options:

- `scan-only`
  Meaning: analyze the repo only, create nothing, edit nothing, and return a gap report plus suggested next steps.

- `bootstrap-existing`
  Meaning: assume the workspace already has a Flutter project or should be treated like one; add only the missing foundation and integrate with the existing structure.

- `bootstrap-new`
  Meaning: create a new Flutter widget foundation when the workspace does not already contain one; if a Flutter project is found, stop and confirm before proceeding.

### 2. Workspace State Preference

Question:
- `สภาพ workspace ตอนนี้เป็นแบบไหน หรืออยากให้ skill ตีความแบบไหน`

Options:

- `existing-flutter`
  Meaning: the user believes a Flutter project already exists. Prioritize integration over scaffolding. If the scan does not find Flutter, report the mismatch.

- `no-flutter-yet`
  Meaning: the user expects no Flutter project yet. Prepare a bootstrap-new plan. If Flutter is found, stop and ask whether to switch to integration mode.

- `auto-detect`
  Meaning: let the scan decide. This is the safest default.

When `bootstrap-new` and `package-ui-library` are selected, also collect the package name, destination directory, public library barrel name, and the platforms required by the separate `example/` app.

### 3. Output Shape

Question:
- `ต้องการให้ผลลัพธ์เป็น Flutter app หรือ Flutter Package UI library`

Options:

- `app`
  Meaning: create a normal Flutter application with `lib/main.dart` for building and running a product app.

- `package-ui-library`
  Meaning: create a reusable Flutter package with public exports under `lib/`, package tests, basic package documentation, and a separate `example/` Flutter app for preview and manual testing. The package root is not treated as an application and does not depend on a root `main.dart`.

For an existing project, scan `pubspec.yaml` to identify app versus package shape. Never convert an existing app into a package implicitly; summarize the migration and ask for confirmation.

### 4. Foundation Level

Question:
- `ต้องการ foundation ระดับไหน`

Options:

- `minimal`
  Meaning: create only what is required to run one starter widget preview.
  Includes: basic Flutter entrypoint, widget folder, one starter widget, one preview entrypoint.
  Excludes by default: full localization, full test harness, Widgetbook.

- `standard`
  Meaning: recommended default for real use.
  Includes: theme foundation, preview system, localization base, test harness base, starter widget integration from MCP.

- `full`
  Meaning: strongest setup in one pass.
  Includes everything in `standard`, plus Widgetbook when appropriate, stricter folder conventions, and starter docs or setup guidance.

### 5. Consumer Naming

Question:
- `ต้องการให้ Theme และ Widget ใช้ชื่อแบบไหนใน project`

Options:

- `generic`
  Meaning: recommended. Use normal names such as `AppTheme`, `PrimaryButton`, `lib/theme/`, and `lib/widgets/`.

- `brand`
  Meaning: use the user's brand namespace and public class prefix, such as `AcmeTheme`, `AcmeButton`, and `lib/acme_ui/`.

- `preserve-source-names`
  Meaning: retain names returned by the MCP source. Use only when source-system naming is intentionally part of the consumer API.

Collect the theme namespace, widget namespace, public class prefix, and public library/barrel name for `generic` or `brand`. These values control file paths, class names, imports, and exports.

### 6. Starter Widget

Question:
- `ต้องการให้เริ่มต้นด้วย widget อะไร`

Options:

- `Buttons`
  Meaning: good for proving theme usage, visual states, and preview wiring.

- `SearchInput`
  Meaning: good for proving input patterns, state handling, and form-like integration.

- `Avatar`
  Meaning: good for proving layout, assets, and display-only widget integration.

- `auto`
  Meaning: choose the starter widget after scanning the repo and consulting MCP metadata; prefer a low-dependency widget with a ready preview.

### 7. Change Policy

Question:
- `ให้ skill แตะ repo ได้ระดับไหน`

Options:

- `additive-only`
  Meaning: add new files and small glue changes only. Avoid editing existing files unless the user explicitly confirms later.

- `allow-structure-setup`
  Meaning: allow the skill to add or modify the structure required to make the workspace usable, while still avoiding silent overwrites.

- `ask-before-overwrite`
  Meaning: the skill may plan edits to existing files, but must ask again before changing high-risk files or replacing existing patterns.

## Workspace Scan

After the discovery questions, inspect at least:

- `pubspec.yaml`
- `lib/main.dart`
- `lib/widgets/` or an equivalent component folder
- `lib/config/themes/` or the current theme layer
- `lib/l10n/` and `l10n.yaml`
- `test/` and any shared test harness
- preview entrypoints or Widgetbook files
- asset structure

## Summary After Scan

Before editing, summarize:

- whether this is a Flutter repo
- whether a Flutter app already exists
- what foundation already exists
- what is missing
- which files are likely to be created
- which existing files may need edits
- any risks, such as theme or localization overlap

## Confirmation Question

Ask this after the scan summary.

Question:
- `จากสิ่งที่สแกนพบ จะให้ดำเนินการตามแผนนี้หรือไม่`

Options:

- `proceed`
  Meaning: execute the summarized plan.

- `revise-scope`
  Meaning: revisit one or more earlier answers and reduce or redirect the plan.

- `stop-after-scan`
  Meaning: finish with analysis only and make no changes.

## What To Build

### If `goal = scan-only`

- do not edit files
- provide gap analysis
- recommend the next skill or next command

### If `goal = bootstrap-existing`

- integrate with the current Flutter structure
- add only the missing foundation required by the chosen `foundation_level`
- use MCP to select and install a starter widget
- add preview, tests, localization, or Widgetbook only when they are in scope

### If `goal = bootstrap-new`

- scaffold a new Flutter widget foundation only after confirming no existing Flutter project should be reused
- for `output_shape = app`, create a normal Flutter application
- for `output_shape = package-ui-library`, create a package root, its public library barrel, reusable widget source, tests, basic package docs, and a separate `example/` Flutter app for previews
- wire `example/` to the package with a local path dependency
- adapt source widget/theme names to the confirmed consumer naming before exposing them; do not leave V3 or source-system prefixes in the public API unless explicitly selected
- create the minimal directories and files for the chosen `foundation_level`
- install one starter widget from MCP as proof the flow works

### Package UI Library Requirements

When `output_shape = package-ui-library`:

- use `flutter create --template=package` for the package root; do not use the app template
- keep reusable widgets and theme code under `lib/`
- create `lib/<package_name>.dart` as the public export barrel
- use the confirmed generic or brand namespaces for folders, classes, imports, and exports
- keep `main.dart`, preview screens, and manual demo wiring under `example/`
- add package-oriented tests and run `dart pub publish --dry-run`
- verify public exports and generated source do not contain source-system `V3`/`v3` names unless explicitly selected
- do not silently convert an existing Flutter app into a package

## MCP Usage

Use these MCP tools when available:

- `get_design_system_info`
- `get_codebase_patterns`
- `list_categories`
- `search_widgets`
- `get_widget_metadata`
- `get_widget_code`
- `get_widget_preview`
- `get_flutter_widget_template`
- `generate_widgetbook_use_case`

## Guardrails

- Never assume a repo is Flutter without scanning.
- Never overwrite a major entrypoint, theme system, or localization system silently.
- Never replace an existing structure wholesale just because a cleaner structure is possible.
- Prefer additive integration over structural replacement.
- If the repo is not Flutter, stop after the scan and ask whether the user wants a Flutter project added at all.
