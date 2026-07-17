# Widget V3 Knowledge Map

## System map

| Layer | Purpose | Source or API |
|---|---|---|
| Design intent | Normative visual language and component rules | `DESIGN.md` |
| Primitive tokens | Stable named scales around raw values | `lib/config/themes/v3/tokens/primitive/**` |
| Semantic tokens | UI-purpose aliases with Light/Dark parity | `lib/config/themes/v3/tokens/semantic/**` |
| Generated runtime | Typed Dart primitives and palettes | `lib/config/themes/v3/generated/**` |
| Runtime access | Resolves semantic palette from brightness | `V3ThemeScope` |
| Widget V3 | Reusable, previewed, tested components | `lib/widgets/v3/**` |
| Icon adapter | Lucide package renderer plus selective SVG overrides | `V3LucideIcon` |
| Preview host | Local or published browser preview | `flutter-widget-v3-preview` |
| Remote discovery | Read-only tokens, widgets, source, metadata, preview | Remote MCP V3 |
| Agent workflows | Onboard, bootstrap, search, install, adapt, preview, Figma, audit, upgrade | Skills V3 |

## Essential concepts

```text
raw value → primitive token → semantic token → Widget V3
```

- Raw value: literal source data such as `#0F172A` or `24`.
- Primitive token: stable scale name such as `Core/Slate/900` or `Space/24`.
- Semantic token: purpose such as `Content/Primary`; it can resolve to different primitives in Light and Dark.
- Widget usage: semantic API such as `colors.contentPrimary` through `V3ThemeScope`.

```text
LucideIcons.house → V3LucideIcon → IconTheme → Widget-typed slot
                         └─ svgAsset present → checked-in SVG override
```

- Use the Lucide package renderer by default.
- Use `svgAsset` only for a verified Figma/package mismatch.
- Keep color in `IconTheme`; do not add a raw color parameter.
- Keep reusable component icon APIs as `Widget`/`Widget?`.

## Public Wiki

- Home: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki
- Getting Started: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Getting-Started
- Theme V3 and Design Tokens: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Theme-V3-and-Design-Tokens
- Widget V3: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Widget-V3
- V3 Lucide Icon: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/V3-Lucide-Icon
- Skills V3: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Skills-V3
- Remote MCP V3: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Remote-MCP-V3
- Preview and Testing: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Preview-and-Testing
- Contributing: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki/Contributing

## Local source priority

When documentation conflicts, use:

```text
AGENTS.md
→ MEMORY.md
→ live source/build scripts
→ widget-local guide
→ broad README/Wiki overview
```
