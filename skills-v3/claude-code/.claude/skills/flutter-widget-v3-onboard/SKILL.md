---
name: flutter-widget-v3-onboard
description: Explain and navigate the Flutter Widget Library V3 system before implementation. Use when a user asks what Widget V3 is, how Theme V3/design tokens/Lucide icons/previews/Remote MCP/Skills V3 work together, where to start, which V3 skill to use next, or wants a read-only onboarding tour of a new or existing Flutter workspace.
---

# Flutter Widget V3 Onboard

Orient the user before implementation. Explain the system in the user's language, connect concepts to concrete repo paths or MCP results, and recommend the smallest next workflow. Remain read-only unless the user explicitly asks to continue with another implementation skill.

## Workflow

1. Identify whether the user wants a full tour, one concept, workspace assessment, or next-skill recommendation.
2. In the source repo, read the nearest agent rules and V3 guides. Outside it, use Remote MCP V3 and `references/v3-knowledge-map.md`.
3. Explain what the layer is, why it exists, its flow, one example, and its main guardrail.
4. For workspace-specific guidance, scan without writing and summarize Theme V3, Widget V3, preview, and test readiness.
5. Recommend the smallest next Skill V3 and ask before any write workflow.

## Explanation Order

```text
Figma/DTCG → raw → primitive → semantic → generated Theme V3
→ V3ThemeScope → Widget V3 → V3LucideIcon → previews/tests
→ Remote MCP V3 → Skills V3
```

## Next-Skill Router

- New app/foundation: `flutter-widget-v3-beginner`
- Find component: `flutter-widget-v3-search`
- Install component: `flutter-widget-v3-install`
- Adapt component: `flutter-widget-v3-adapt`
- Live preview: `flutter-widget-v3-preview`
- Figma implementation: `flutter-widget-v3-figma-to-code`
- Quality review: `flutter-widget-v3-audit`
- Upstream sync: `flutter-widget-v3-upgrade`

## MCP Tools

- `get_v3_design_system_info`
- `get_v3_theme_foundation`
- `get_v3_codebase_patterns`
- `list_v3_categories`
- `list_v3_widgets`
- `search_v3_widgets`
- `get_v3_widget_metadata`
- `get_v3_widget_preview`

## Guardrails

- Stay read-only during onboarding and ask before handing off to a writing skill.
- Never fall back to legacy widgets, tools, `theme_color.dart`, or `ThemeColors.get()`.
- Treat raw values as valid token source data but harmful hardcoding inside Widget V3.
- Explain Lucide package rendering as the default and checked-in SVG as a verified exception; color comes from `IconTheme` and component slots remain `Widget`-typed.
- Do not claim Skills V3 control Flutter Inspector; it only supplies target context.
