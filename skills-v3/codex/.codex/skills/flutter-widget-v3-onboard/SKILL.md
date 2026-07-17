---
name: flutter-widget-v3-onboard
description: Explain and navigate the Flutter Widget Library V3 system before implementation. Use when a user asks what Widget V3 is, how Theme V3/design tokens/Lucide icons/previews/Remote MCP/Skills V3 work together, where to start, which V3 skill to use next, or wants a read-only onboarding tour of a new or existing Flutter workspace.
---

# Flutter Widget V3 Onboard

Orient the user before implementation. Explain the system in the user's language, connect concepts to concrete repo paths or MCP results, and recommend the smallest next workflow. Remain read-only unless the user explicitly asks to continue with another implementation skill.

## Workflow

1. Identify the user's goal:
   - learn the whole V3 system
   - understand one concept such as tokens, Lucide icons, previews, or MCP
   - assess how V3 fits an existing Flutter project
   - choose the next Skill V3 workflow
2. Detect the available context:
   - In the source repo, read the nearest `AGENTS.md`, `MEMORY.md`, `README.md`, `DESIGN.md`, and relevant V3 guide.
   - Outside the source repo, use Remote MCP V3 tools and the public Wiki links in `references/v3-knowledge-map.md`.
3. Explain from concept to usage:
   - what the layer is
   - why it exists
   - how data or code flows through it
   - one concrete example
   - the guardrail that prevents misuse
4. If the user wants workspace-specific guidance, scan without writing and summarize:
   - whether Flutter and Theme V3 are present
   - which Widget V3 components already exist
   - preview/test coverage
   - the safest next skill
5. End with a recommended handoff. Do not invoke or simulate implementation without confirmation.

## Explanation Order

Use this order for a full onboarding tour:

```text
Figma / DTCG
→ raw values
→ primitive tokens
→ semantic tokens
→ generated Theme V3 runtime
→ V3ThemeScope
→ Widget V3
→ V3LucideIcon and Widget-typed icon slots
→ previews and tests
→ Remote MCP V3
→ Skills V3 workflows
```

Read `references/v3-knowledge-map.md` when explaining this flow, answering architecture questions, or choosing a Wiki page.

## Next-Skill Router

| User goal | Recommend |
|---|---|
| Create a new Flutter app or install Theme V3 foundation | `flutter-widget-v3-beginner` |
| Find the best existing component | `flutter-widget-v3-search` |
| Bring a selected component into the project | `flutter-widget-v3-install` |
| Align an imported component with the host Theme V3 | `flutter-widget-v3-adapt` |
| See a component running in Light/Dark | `flutter-widget-v3-preview` |
| Convert Figma intent into Widget V3 | `flutter-widget-v3-figma-to-code` |
| Review token usage, previews, metadata, or legacy leakage | `flutter-widget-v3-audit` |
| Sync a local V3 component with upstream | `flutter-widget-v3-upgrade` |

## MCP Tools

- `get_v3_design_system_info`
- `get_v3_theme_foundation`
- `get_v3_codebase_patterns`
- `list_v3_categories`
- `list_v3_widgets`
- `search_v3_widgets`
- `get_v3_widget_metadata`
- `get_v3_widget_preview`

Use only the minimum tools needed for the question. Prefer `get_v3_design_system_info` for system orientation, `get_v3_theme_foundation` for installable runtime boundaries, and catalog tools only when the user asks about available components.

## Guardrails

- Stay read-only during onboarding; do not create, install, migrate, or overwrite files.
- Never fall back to legacy widgets, legacy MCP tools, `theme_color.dart`, or `ThemeColors.get()` when explaining V3.
- Distinguish verified implementation from plans or historical documentation.
- Explain raw → primitive → semantic accurately: raw values are valid in token sources but become harmful hardcoding when embedded directly in Widget V3 code.
- Explain Lucide accurately: package rendering is the default; checked-in SVG is an exception used only for a verified mismatch. `V3LucideIcon` receives color from `IconTheme` and reusable components keep icon slots typed as `Widget`.
- Do not claim Flutter Inspector is controlled by Skills V3. Inspector supplies widget/source context; a follow-on skill uses that context only after the user confirms scope.
- Ask before handing off to any skill that writes files.
