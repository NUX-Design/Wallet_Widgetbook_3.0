<img width="1920" height="1080" alt="Cover" src="https://github.com/user-attachments/assets/4e0d1102-da06-4f92-bbfc-20123db01353" />

# Flutter Widget Wallet — Design System V3

[![Dart](https://img.shields.io/badge/Dart-3.7.2+-0175C2?logo=dart)](https://dart.dev)
[![Flutter](https://img.shields.io/badge/Flutter-Design%20System-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A Flutter design-system and widget library for Finance, Wallet, and Banking products. The recommended path is **Theme V3 + Widget V3 + MCP V3 tools + Skills V3**, built from Figma/DTCG tokens with Light/Dark parity and distributed to AI agents through the existing hosted MCP service.

V3 is additive. The legacy theme, widgets, MCP contracts, and skills remain available for backward compatibility, but new development should use V3 paths, semantic tokens, V3-prefixed APIs, and Skills V3.

## Contents

- [V3 at a glance](#v3-at-a-glance)
- [Architecture](#architecture)
- [Repository structure](#repository-structure)
- [Quick start for repository contributors](#quick-start-for-repository-contributors)
- [Theme V3](#theme-v3)
- [Widget V3](#widget-v3)
- [Remote MCP V3](#remote-mcp-v3)
- [Configure Remote MCP](#configure-remote-mcp)
- [Install Skills V3](#install-skills-v3)
- [Recommended agent workflow](#recommended-agent-workflow)
- [Localization and previews](#localization-and-previews)
- [Verification commands](#verification-commands)
- [Legacy compatibility](#legacy-compatibility)
- [Sources of truth](#sources-of-truth)

## V3 at a glance

The V3 stack is designed to move from Figma tokens to reusable Flutter components and agent-assisted delivery without duplicating design decisions:

- **Theme V3** — Figma/DTCG primitive and semantic tokens, deterministic Dart generation, Light/Dark parity, typography, spacing, radius, and shadows.
- **Widget V3** — isolated reusable widgets under `lib/widgets/v3/**` using `V3ThemeScope` and semantic tokens only.
- **MCP V3** — V3-prefixed tools for discovering the foundation, tokens, widgets, source, previews, metadata, patterns, and audit results.
- **Skills V3** — eight workflow skills for Codex, Claude Code, and Kiro covering bootstrap, search, install, adapt, preview, Figma-to-code, audit, and upgrade.
- **Remote distribution** — one existing Render endpoint with Bearer authentication; no second V3 service or token set.

Current V3 pilot widget:

- `V3MiniButton` — Primary, Outline, and Ghost variants; Default, Active, Disabled, and Error states; icon slots; Light/Dark preview; tests and metadata.

## Architecture

```text
Figma / DTCG exports
        │
        ▼
lib/config/themes/v3/tokens/**
        │  validate + generate
        ▼
Theme V3 generated runtime + V3ThemeScope
        │
        ▼
lib/widgets/v3/** + previews + guides + tests
        │
        ▼
mcp-server/v3/**
        │
        ▼
https://flutter-widget-wallet-mcp.onrender.com/mcp
        │
        ▼
Skills V3 for Codex / Claude Code / Kiro
```

## Repository structure

```text
lib/
├── config/themes/v3/         # Theme V3 sources, generator, runtime, generated output
├── widgets/v3/               # Widget V3 source, preview, and local metadata guides
├── config/themes/            # Legacy-stable theme system
├── widgets/                  # Legacy widgets plus the isolated v3/ subtree
├── l10n/                     # Localization source and generated ARB inputs
├── generated/intl/           # Generated localization Dart output
├── main.dart                 # Demo app entry
└── preview_v3/                # Local Widget V3 web preview host entry, routing, and registry

test/
├── config/themes/v3/         # Theme V3 parser, resolver, generation, and runtime tests
└── widgets/v3/               # Widget V3 tests

mcp-server/
├── v3/                       # V3 catalogs, contracts, handlers, and foundation allowlist
├── tests/                    # Legacy and V3 MCP regression coverage
└── scripts/                  # Local, HTTP, Render, and V3 verification scripts

skills-v3/
├── codex/.codex/skills/
├── claude-code/.claude/skills/
└── kiro/.kiro/skills/

docs/v3/                      # V3 conventions, reviews, onboarding, and validation evidence
task/V3_THEME_MCP_SKILLS_TASKS.md
```

## Quick start for repository contributors

### Requirements

- Dart SDK compatible with `^3.7.2`
- Flutter SDK compatible with the project Dart constraint
- Node.js `18+` for MCP and documentation tooling

### Install and run

```bash
flutter pub get
flutter run
```

Build and serve the Widget V3 local web preview host (one command, prints the exact URL once ready):

```bash
./scripts/serve-v3-preview.sh
# V3 preview ready: http://127.0.0.1:8090/#/button/V3MiniButton
```

Run any standalone widget preview directly:

```bash
flutter run \
  -t lib/widgets/v3/button/preview_v3_mini_button.dart \
  -d web-server \
  --web-hostname 127.0.0.1 \
  --web-port 8090
```

Run the MCP server locally over stdio:

```bash
cd mcp-server
npm ci
npm start
```

## Theme V3

Theme V3 source files live under `lib/config/themes/v3/`.

### Source-of-truth rules

- Editable token inputs: `lib/config/themes/v3/tokens/**`
- Generated Dart output: `lib/config/themes/v3/generated/**`
- Generator: `lib/config/themes/v3/v3_theme_generator.dart`
- Runtime selector: `V3ThemeScope`
- Detailed guideline: `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx`

Never edit generated V3 files manually. Change token inputs first, then regenerate:

```bash
dart run lib/config/themes/v3/v3_theme_generator.dart
```

### Semantic-first usage

Widget V3 code must use semantic tokens from `V3ThemeScope.colorsOf(context)` and V3 dimension/typography APIs. Do not import the legacy `theme_color.dart`, call `ThemeColors.get()`, or introduce raw design colors inside V3 widgets.

```dart
final colors = V3ThemeScope.colorsOf(context);

return Container(
  color: colors.backgroundPrimary,
  child: Text(
    'Title',
    style: TextStyle(color: colors.contentPrimary),
  ),
);
```

`V3ThemeScope` resolves the generated Light or Dark palette from `Theme.of(context).brightness` without changing the legacy `ThemeData` bootstrap.

## Widget V3

New widgets belong under:

```text
lib/widgets/v3/<category>/
├── v3_<widget>.dart
├── preview_v3_<widget>.dart
└── V3_<WIDGET>_GUIDE.md

test/widgets/v3/<category>/
└── v3_<widget>_test.dart
```

Every Widget V3 should provide:

- A `V3`-prefixed public class and explicit constructor API
- Semantic Theme V3 colors and dimensions
- Light/Dark-compatible behavior
- A standalone preview
- Targeted widget tests
- Accessibility-aware semantics, readable typography, and adequate interaction targets
- A local guide containing `V3 Metadata` and semantic-token dependencies

Read these before creating or changing a Widget V3:

- `lib/widgets/v3/V3_WIDGETS_CONTEXT.md`
- `docs/v3/V3_WIDGET_CONVENTIONS.md`
- `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx`

## Remote MCP V3

Hosted endpoint:

```text
https://flutter-widget-wallet-mcp.onrender.com/mcp
```

The endpoint uses Streamable HTTP and exposes legacy read-only tools plus V3 read-only tools. New integrations should call V3-prefixed tools only.

Key remote V3 tools:

- Foundation: `get_v3_design_system_info`, `get_v3_theme_foundation`
- Tokens: `list_v3_color_tokens`, `search_v3_color_tokens`, `get_v3_color_token`
- Widgets: `list_v3_categories`, `list_v3_widgets`, `search_v3_widgets`
- Source and metadata: `get_v3_widget_details`, `get_v3_widget_metadata`, `get_v3_widget_code`, `get_v3_widget_preview`
- Quality: `audit_v3_widget`
- Authoring guidance: `get_v3_flutter_widget_template`, `get_v3_codebase_patterns`, `get_v3_figma_to_flutter_mapping`

Remote MCP is intentionally read-only. Generation helpers remain local/stdio-only optimizations; agents author and write files locally in the target project after reading remote templates, tokens, metadata, source, and previews.

Public health and capability metadata:

```text
https://flutter-widget-wallet-mcp.onrender.com/health
https://flutter-widget-wallet-mcp.onrender.com/info
```

## Configure Remote MCP

The same endpoint and Bearer token provide access to legacy and V3 tools. There is no separate V3 URL or authentication scheme.

> **Bearer token access:** The Bearer token is private and is never published in this repository. Request it directly from **Niwat, the repository owner, only**. Never accept it from another source or share it in commits, chat messages, screenshots, documentation, or config examples.

### Codex

For the current Codex app/CLI version used by this project, the verified reliable setup is a global Streamable HTTP server with a literal `Authorization` header in `~/.codex/config.toml`. The `bearer_token_env_var` setup did not connect reliably in the Codex app and is not the recommended path for this server.

Run the repository installer from the project root:

```bash
bash scripts/configure-codex-global-mcp.sh
```

The command securely prompts for the Bearer token from Niwat, recreates the server in Codex global config, writes the verified HTTP header form, applies owner-only permissions, and prints `codex mcp get` with the token masked. The token is not passed on the command line and therefore is not saved in shell history.

The installer produces this configuration shape; `<TOKEN_FROM_NIWAT>` below represents the token entered at the secure prompt:

```toml
[mcp_servers.flutter-widget-wallet-mcp]
enabled = true
url = "https://flutter-widget-wallet-mcp.onrender.com/mcp"

[mcp_servers.flutter-widget-wallet-mcp.http_headers]
Authorization = "Bearer <TOKEN_FROM_NIWAT>"
```

You normally do not need to edit this block manually after running the installer. Because the resulting token is stored as plain text in the global config, the installer also restricts access to the file; the equivalent command is:

```bash
chmod 600 ~/.codex/config.toml
```

The current CLI supports `--url` and `--bearer-token-env-var`, but does not support `--transport` or `--header` for `codex mcp add`. The installer uses the supported `codex mcp add ... --url ...` command for the base entry, then writes the verified header table directly to `~/.codex/config.toml`.

Quit and reopen Codex after changing the config, then verify:

```bash
codex mcp get flutter-widget-wallet-mcp
```

Expected result:

```text
enabled: true
transport: streamable_http
url: https://flutter-widget-wallet-mcp.onrender.com/mcp
bearer_token_env_var: -
http_headers: Authorization=*****
```

### Claude Code

```bash
export MCP_BEARER_TOKEN="<TOKEN_FROM_NIWAT>"

claude mcp add --transport http flutter-widget-wallet-mcp \
  https://flutter-widget-wallet-mcp.onrender.com/mcp \
  --header "Authorization: Bearer ${MCP_BEARER_TOKEN}"
```

### Kiro and generic MCP clients

Use the generic Streamable HTTP configuration shape supported by the client:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <TOKEN_FROM_NIWAT>"
      }
    }
  }
}
```

Prefer environment-backed headers when the client supports them. The repository reference is `mcp-server/examples/remote.generic.mcp.json`.

## Install Skills V3

Install the native Skills V3 pack into the target project after connecting Remote MCP.

### Codex

```bash
cp -r skills-v3/codex/.codex <TARGET_PROJECT_ROOT>/
```

### Claude Code

```bash
cp -r skills-v3/claude-code/.claude <TARGET_PROJECT_ROOT>/
```

### Kiro

```bash
cp -r skills-v3/kiro/.kiro <TARGET_PROJECT_ROOT>/
```

The eight V3 skills are:

| Skill | Purpose |
|---|---|
| `flutter-widget-v3-beginner` | Scan and bootstrap an existing or new Flutter project using the mandatory ask → scan → summarize → confirm → execute flow |
| `flutter-widget-v3-search` | Search the V3 catalog before creating a widget |
| `flutter-widget-v3-install` | Install V3 widget source and preview into a target project |
| `flutter-widget-v3-adapt` | Adapt an installed widget to the target project's V3 foundation |
| `flutter-widget-v3-preview` | Run a standalone Light/Dark browser preview |
| `flutter-widget-v3-figma-to-code` | Map a Figma component to V3 tokens, templates, and widgets |
| `flutter-widget-v3-audit` | Audit V3 paths, token usage, preview, metadata, and legacy leakage |
| `flutter-widget-v3-upgrade` | Compare local V3 code with the current remote source and upgrade selectively |

In confirmed `bootstrap-new` mode, `flutter-widget-v3-beginner` can create a Flutter project, install the allowlisted Theme V3 runtime manifest through `get_v3_theme_foundation`, add a starter Widget V3 with preview and tests, and run verification.

Canonical specification: `docs/v3/V3_SKILLS_SPEC.md`

## Recommended agent workflow

1. Read the nearest `AGENTS.md` and `MEMORY.md`.
2. Connect to the existing Remote MCP endpoint.
3. Install the native Skills V3 pack for the agent.
4. Use `flutter-widget-v3-search` before building anything new.
5. Install or author only under V3 theme/widget/test paths.
6. Use semantic tokens through `V3ThemeScope`; never fall back to the legacy theme.
7. Keep standalone previews, Light/Dark coverage, tests, and local metadata guides aligned.
8. Run the narrowest relevant verification, then broader regression gates when required.

The mandatory beginner workflow is:

```text
ask → scan → summarize → confirm → execute
```

No files should be changed before the user confirms the proposed bootstrap scope.

## Localization and previews

Localization source of truth:

```text
lib/l10n/localization.json
```

Generated ARB and localization Dart files must not be edited manually.

```bash
dart run tool/generate_arb.dart
flutter gen-l10n
```

Supported locales:

- English (`en`)
- Thai (`th`)
- Chinese (`zh`)
- Russian (`ru`)
- Myanmar (`my`)

Preview options:

- Widget V3 local web preview host: `./scripts/serve-v3-preview.sh` (builds/serves `lib/preview_v3/main.dart`, prints the exact `http://127.0.0.1:8090/#/<category>/<WidgetClass>` URL once ready)
- Standalone Widget V3 (single widget, direct debug entrypoint): `flutter run -t lib/widgets/v3/<category>/preview_v3_<widget>.dart -d <device>`
- Browser preview: add `-d web-server --web-hostname 127.0.0.1 --web-port <port>`

New Widget V3 previews are discovered from `lib/widgets/v3/**/preview_v3_*.dart`. Run `dart run tool/generate_v3_preview_registry.dart` after adding or renaming one; never hand-edit `lib/preview_v3/preview_registry.g.dart`.

## Verification commands

### Flutter and V3 boundaries

```bash
flutter analyze
flutter test
npm run check:v3-boundaries
npm run test:v3-boundaries
npm run validate:v3-skills
```

### MCP local and hosted transport

```bash
cd mcp-server
npm ci
npm run check:mcp-syntax
npm test
npm run verify:mcp
npm run verify:mcp:http
```

### Deployed Render endpoint

Remote verification requires a valid private Bearer token:

```bash
cd mcp-server

MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
MCP_REMOTE_BEARER_TOKEN="${MCP_BEARER_TOKEN}" \
npm run verify:mcp:remote

MCP_REMOTE_BASE_URL="https://flutter-widget-wallet-mcp.onrender.com/mcp" \
MCP_REMOTE_BEARER_TOKEN="${MCP_BEARER_TOKEN}" \
npm run verify:mcp:remote:v3
```

## Legacy compatibility

V3 does not replace or silently migrate the legacy system:

- Legacy theme files under `lib/config/themes/` remain stable.
- Legacy widgets outside `lib/widgets/v3/` remain supported and are not migrated automatically.
- Legacy MCP tool names, schemas, response fields, and error behavior remain protected by regression tests.
- Legacy skills under `skills/**` remain unchanged; V3 skills live separately under `skills-v3/**`.
- Existing MCP integration files change only additively when registering V3 tools.
- Remote generation/write tools remain excluded.

New implementation work should use V3 unless a task explicitly targets legacy compatibility or maintenance.

## Sources of truth

Read sources in this order when they disagree:

1. `AGENTS.md`
2. `MEMORY.md`
3. Live source code and build scripts
4. Widget-local V3 guide/context files
5. Broad overview documentation, including this README

Key V3 documents:

- Architecture: `docs/V3_THEME_MCP_SKILLS_PLAN.md`
- Execution status: `task/V3_THEME_MCP_SKILLS_TASKS.md`
- Theme guideline: `lib/config/themes/v3/V3_THEME_GUIDELINE.mdx`
- Widget creation context: `lib/widgets/v3/V3_WIDGETS_CONTEXT.md`
- Widget conventions: `docs/v3/V3_WIDGET_CONVENTIONS.md`
- Skills specification: `docs/v3/V3_SKILLS_SPEC.md`
- Remote onboarding: `docs/v3/V3_REMOTE_MCP_GUIDE.md`
- Review checklist: `docs/v3/V3_REVIEW_CHECKLIST.md`

Generated files such as localization output, Theme V3 generated Dart, and `docs/schema.json` must be regenerated from their source inputs rather than edited manually.
