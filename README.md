<img width="1920" height="1080" alt="Cover" src="https://github.com/user-attachments/assets/4e0d1102-da06-4f92-bbfc-20123db01353" />

# Flutter Widgetbook Library

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-02569B?logo=flutter)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A Flutter UI library for Dart/Flutter focused on Finance, Wallet, and Banking use cases. This repo is a collection of reusable widgets, Design System, Design Tokens, i18n, Themes, Foundation layers, and preview workflows converted from Figma design components, so teams can reuse them at production quality.

Beyond the UI side, this repo also ships an `mcp-server/` for connecting AI agents via the Model Context Protocol (MCP), along with agent context docs such as `AGENTS.md` and `MEMORY.md`, so agents understand the repo's rules, read the right source-of-truth, and pull widget/code metadata in a structured way.

## Table of Contents

- [What is this repo](#what-is-this-repo)
- [What's in this repo](#whats-in-this-repo)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Design System Foundation](#design-system-foundation)
- [MCP Server and Agent Skills](#mcp-server-and-agent-skills)
- [Setup MCP for Codex, Claude Code, Kiro](#setup-mcp-for-codex-claude-code-kiro)
- [Install Skills V3 (Recommended)](#install-skills-v3-recommended)
- [Why using MCP + Skills from this repo is useful](#why-using-mcp--skills-from-this-repo-is-useful)
- [Useful Commands](#useful-commands)

## What is this repo

This repo serves as the source-of-truth for a Flutter widget library targeted at financial products, focused on three things at once:

1. Ready-to-reuse UI components
2. A consistent Design System and theme/token foundation
3. Agent tooling that lets AI agents read, search, and reuse components more accurately

Overview of what this repo covers:

- Reusable Flutter widgets for Finance / Wallet / Banking flows
- A Widgetbook catalog and standalone previews for inspecting UI in isolation
- A theme system supporting light/dark modes
- Design tokens that can be consistently reused
- Localization source + generator pipeline
- Widget docs / metadata / previews wired to the real source code
- An MCP server for AI agents that need to search widgets, read metadata, and pull code examples

## What's in this repo

- `lib/widgets/` — core reusable widgets such as button, card, drawer, receipt, input, avatar, tab, navigator bar, snack bar, loading, shortcut menu, and more
- `lib/config/themes/` — the central home for theme primitives and color tokens
- `lib/l10n/localization.json` — the editable source of truth for multi-language text
- `lib/widgetbook.dart` and `lib/widgetbook_use_cases.dart` — support component previews via Widgetbook
- `mcp-server/` — an MCP server letting external agents/tools query widget and design-system data
- `AGENTS.md` and `MEMORY.md` — repo-specific agent context that helps agents work with this repo following the actual rules and structure

## Project Structure

```text
lib/
├── config/themes/            # Theme system, tokens, base theme
├── generated/intl/           # Generated localization output
├── l10n/                     # Localization source + ARB files
├── providers/                # ThemeProvider / LocaleProvider
├── widgets/                  # Reusable UI components
├── main.dart                 # Demo app entry
├── widgetbook.dart           # Widgetbook entry
└── widgetbook_use_cases.dart # Manual Widgetbook use cases

mcp-server/                   # MCP server for AI agents
scripts/                      # Schema / docs tooling
test/                         # Flutter tests
task/                         # Backlog / execution tracking
```

## Quick Start

### Prerequisites

- Flutter SDK `^3.7.2`
- Dart SDK
- Node.js `18+` for MCP tooling and docs/schema scripts

### Run the Flutter project

```bash
flutter pub get
dart run tool/generate_arb.dart
flutter gen-l10n
flutter run
```

### Run Widgetbook

```bash
flutter run -t lib/widgetbook.dart -d chrome
```

### Run MCP server locally

```bash
cd mcp-server
npm install
npm start
```

## Design System Foundation

This repo doesn't just store finished widgets — it holds a foundation that's ready to be reused across the whole system:

- `Design Tokens`
  Uses token-based color access through the theme layer instead of hardcoding colors in shared widgets
- `Themes`
  Supports light/dark mode using shared theme primitives across the whole library
- `i18n`
  Has an editable source (`lib/l10n/localization.json`) and a generation pipeline into ARB/intl outputs
- `Widgetbook + Standalone Preview`
  Supports both catalog-style previews and standalone runnable files for debugging components
- `Foundation for Financial UI`
  Many widgets and naming conventions are designed for wallet, payment, account summary, receipt, transaction, drawer action, and navigation use cases

Currently supported languages:

- English (`en`)
- Thai (`th`)
- Chinese (`zh`)
- Russian (`ru`)
- Myanmar (`my`)

## MCP Server and Agent Skills

### What is the MCP Server

MCP (Model Context Protocol) is a standard that lets AI agents call external tools through a consistent structure — for example, searching widgets, reading metadata, pulling source code, or reading design-system rules directly from this repo.

In this repo, the MCP server lives at `mcp-server/` and supports both:

- `local stdio`
  Best for people who clone the repo locally and want the agent to read the latest source directly from the working tree
- `hosted streamable-http`
  Best for zero-clone / remote access, letting clients connect via a URL instead of a local path

### What are Agent Skills in the context of this repo

In practice, this repo has two layers that help agents work better:

1. `AGENTS.md` and `MEMORY.md`
   Repo-specific operating rules / memory that describe file-reading order, source-of-truth, real commands to run, and project caveats
2. `MCP tools`
   Machine-callable tools agents use to query repo data without guessing the structure

This approach makes it easier for agents such as Codex, Claude Code, Cursor, Antigravity, or Kiro to work from the same shared understanding, even though actual support levels vary by client.

### What the MCP server can help with

Key tools this repo exposes to agents include:

- `list_categories`
- `list_widgets`
- `search_widgets`
- `get_widget_details`
- `get_widget_metadata`
- `get_widget_code`
- `get_widget_preview`
- `get_design_system_info`
- `get_color_token`
- `get_codebase_patterns`
- `generate_widget_code`

As a result, agents can:

- Search for existing widgets before creating duplicates
- Read preview/doc/widget metadata straight from the repo
- Pull component code to reuse or reference
- Understand design-system rules and codebase patterns before generating code
- Use this design system's data to build new components more accurately in a target project

When used through the `hosted streamable-http` endpoint, agents don't even need to clone this repo locally — they can still:

- Search for the widget closest to what they need
- Read metadata, props, previews, and implementation guidance
- Pull the source code of existing widgets
- Apply the same patterns/tokens/theme rules to generate components for their own project

In short, this repo can act as a `remote source of truth` for a UI library, where external projects or AI agents connect via MCP and pull widget components directly into a target project — even without cloning this repo locally.

## Setup MCP for Codex, Claude Code, Kiro

This section only covers `remote` configuration, assuming you already have a hosted MCP endpoint, such as:

- `https://flutter-widget-wallet-mcp.onrender.com/mcp`
- and an access token for that endpoint's reverse proxy / gateway

The repo's main reference config lives at `mcp-server/examples/remote.generic.mcp.json`

### 1. Codex

Use the remote MCP URL with an `Authorization` header:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

### 2. Claude Code

**Option A — CLI (recommended)**

```bash
claude mcp add --transport http flutter-widget-wallet-mcp \
  https://flutter-widget-wallet-mcp.onrender.com/mcp \
  --header "Authorization: Bearer <EDGE_ACCESS_TOKEN>"
```

**Option B — JSON config**

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

### 3. Kiro

If the version of Kiro you're using supports remote MCP with a `url` + `headers` shape, you can use the same generic shape:

```json
{
  "mcpServers": {
    "flutter-widget-wallet-mcp": {
      "url": "https://flutter-widget-wallet-mcp.onrender.com/mcp",
      "headers": {
        "Authorization": "Bearer <EDGE_ACCESS_TOKEN>"
      }
    }
  }
}
```

Notes:

- The repo's remote example is `mcp-server/examples/remote.generic.mcp.json`
- The `streamable-http` remote protocol is fully supported in this repo
- Direct host-app remote integration for `Claude Code` and `Codex` is still `best-effort / unverified` per `mcp-server/COMPATIBILITY_POLICY.md`
- `Kiro` has no template generated directly by the repo, so treat it as a generic remote example as well
- To verify the actually deployed endpoint, use `cd mcp-server && npm run verify:mcp:remote`

## Install Skills V3 (Recommended)

After connecting to the MCP endpoint, install the **Skills V3** pack into your target project. Skills act as workflow guides that tell the agent _how_ to use the MCP tools correctly — searching before creating, using V3 theme tokens, respecting Light/Dark parity, running previews, and never overwriting existing widgets.

Without skills, the agent has raw MCP tools but no guardrails. With skills, the agent follows a structured workflow every time.

### What the 8 skills do

| Skill | Purpose |
|---|---|
| `flutter-widget-v3-beginner` | Bootstrap a Flutter project to consume widgets from this library (ask → scan → confirm → execute) |
| `flutter-widget-v3-search` | Search the widget catalog before building anything new |
| `flutter-widget-v3-install` | Pull a widget's source + preview into your project |
| `flutter-widget-v3-adapt` | Adapt an installed widget to match your project's theme tokens |
| `flutter-widget-v3-preview` | Run a standalone Light/Dark preview of any widget in a browser |
| `flutter-widget-v3-figma-to-code` | Convert a Figma component into a V3 widget using token mappings |
| `flutter-widget-v3-audit` | Check an existing widget for legacy imports, raw colors, missing tokens |
| `flutter-widget-v3-upgrade` | Compare a local widget against the latest source-of-truth and upgrade |

### Installation per agent

Skills V3 packs live in `skills-v3/` in this repo. Copy the appropriate folder into **your target project root**:

**Codex**

```bash
cp -r skills-v3/codex/.codex <YOUR_PROJECT_ROOT>/
```

This places `.codex/skills/flutter-widget-v3-*` in your project so Codex auto-discovers them.

**Claude Code**

```bash
cp -r skills-v3/claude-code/.claude <YOUR_PROJECT_ROOT>/
```

This places `.claude/skills/flutter-widget-v3-*` in your project. Invoke with `/flutter-widget-v3-beginner` or let Claude match from natural language.

**Kiro**

```bash
cp -r skills-v3/kiro/.kiro <YOUR_PROJECT_ROOT>/
```

This places `.kiro/skills/flutter-widget-v3-*` in your project for Kiro to discover.

### Notes

- Skills V3 work with the **same MCP endpoint and Bearer token** you already configured above
- Skills only operate on `lib/widgets/v3/**` — they never touch legacy widgets
- `flutter-widget-v3-beginner` will not create Theme V3 foundation; it expects `lib/config/themes/v3/generated/` to already exist (use `flutter-widget-v3-install` to pull it)
- Remote MCP exposes only read-only tools; skills that generate code do so locally in your project
- For the full canonical spec, see `docs/v3/V3_SKILLS_SPEC.md`

## Why using MCP + Skills from this repo is useful

### 1. Less guessing about repo structure

Agents don't need to guess where widgets live, how themes are used, or which file holds the localization source, because both repo rules and machine-callable tools already describe it.

### 2. Fewer duplicate components

Instead of generating a new widget every time, agents can `search_widgets` and `get_widget_metadata` first to check whether something reusable already exists.

### 3. Pull real code straight from the source-of-truth

Agents can pull code examples, previews, metadata, and design-system patterns directly from the real repo, instead of relying only on broad descriptions.

### 4. Build widgets into a target project without cloning the repo

If the MCP endpoint is already hosted, agents can connect via a remote URL, read the widget catalog, pull code/metadata, and create or adapt components directly in a target project — without cloning this design-system repo first.

### 5. More consistent work across multiple agents

When the same repo has both MCP tools and agent context docs, moving work between Codex, Claude Code, Cursor, or other clients has less chance of drifting.

### 6. Fits a Figma-to-Flutter workflow

Because this repo positions itself as a collection of design components converted into Flutter widgets with proper foundations, agents can use it as a base for generating/comparing/refactoring work from design specs.

## Useful Commands

### Flutter

```bash
flutter pub get
flutter analyze
flutter test
flutter run
flutter run -t lib/widgetbook.dart -d chrome
```

### Localization

```bash
dart run tool/generate_arb.dart
flutter gen-l10n
```

### Widgetbook / Generated files

```bash
dart run build_runner build --delete-conflicting-outputs
```

### MCP Server

```bash
cd mcp-server
npm install
npm start
npm run start:http
npm run verify:mcp
npm run verify:mcp:http
npm run verify:mcp:remote
npm run validate:onboarding
```

## Notes

- If overview docs disagree with the source code, trust `AGENTS.md`, `MEMORY.md`, and the live source files first
- Generated files such as localization outputs, Widgetbook generated directories, and `docs/schema.json` should not be edited by hand
- If you plan to use an AI agent with this repo seriously, read `AGENTS.md` and `MEMORY.md` first every time
