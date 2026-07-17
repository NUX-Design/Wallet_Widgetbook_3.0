# Widget V3 Knowledge Map

Read this reference for a full system explanation or Wiki routing.

```text
Figma/DTCG → primitive tokens → semantic tokens → generated Theme V3
→ V3ThemeScope → Widget V3 → Lucide adapter → preview/tests
→ Remote MCP V3 → Skills V3
```

- Raw values belong in token sources; do not hardcode them in Widget V3.
- Primitive tokens name stable values; semantic tokens name UI purpose and support Light/Dark aliases.
- Widget V3 uses `V3ThemeScope` and stays isolated from legacy theme APIs.
- `V3LucideIcon` uses the Lucide package by default and checked-in SVG only for verified exceptions; color comes from `IconTheme`.
- Reusable component icon slots remain `Widget`/`Widget?`.

Wiki: https://github.com/NUX-Design/Wallet_Widgetbook_3.0/wiki

- `/Theme-V3-and-Design-Tokens`
- `/Widget-V3`
- `/V3-Lucide-Icon`
- `/Skills-V3`
- `/Remote-MCP-V3`
- `/Preview-and-Testing`

Trust order: `AGENTS.md` → `MEMORY.md` → live source → local guide → broad README/Wiki.
