---
name: flutter-widget-v3-preview
description: Create or refresh standalone previews and Widgetbook use cases for a Widget V3 component integrated from `flutter-widget-wallet-mcp`. Use when a V3 widget exists but is not yet easy to run or inspect in isolation.
---

# Flutter Widget V3 Preview

Invoke with `/flutter-widget-v3-preview` in Claude Code, or ask Claude to create or refresh a Widget V3 preview naturally.

Use this skill to make Widget V3 components easy to inspect and validate visually in Light and Dark.

## Workflow

1. Inspect how the current repo handles Widget V3 previews: standalone `preview_v3_*.dart` or Widgetbook.
2. Pull preview examples from MCP with `get_v3_widget_preview` when available.
3. If the repo uses Widgetbook and local/stdio MCP is available, optionally generate use cases with `generate_v3_widgetbook_use_case`.
4. If the repo uses standalone previews, create or refresh the local `preview_v3_<widget>.dart` entrypoint with a Light/Dark toggle, mirroring the `V3MiniButton` pilot pattern.
5. Keep preview sample data aligned with the widget's public API and semantic token metadata.
6. Confirm both Light and Dark render correctly before finishing.

## Remote-Safe Fallback

When connected through Remote MCP, use `get_v3_widget_preview` and `get_v3_widget_metadata`, then author the local standalone preview or Widgetbook use case directly from those read-only results and the host repo conventions. Do not call `generate_v3_widgetbook_use_case` or fall back to a legacy generation tool.

## Live Browser Preview (On Request)

Use this when the requester names a specific Widget V3 component and wants to see it rendered live, not just read the preview source.

1. Resolve the component:
   - If it is already installed locally, use its existing `lib/widgets/v3/<category>/preview_v3_<widget>.dart`.
   - If it is not installed yet, first run the `flutter-widget-v3-install` workflow (`get_v3_widget_metadata` + `get_v3_widget_code` + `get_v3_widget_preview`) so a real preview file exists before launching anything.
   - Never invent a preview path; if no widget or preview matches the request, say so and suggest `flutter-widget-v3-search`.
2. Pick a free local port (`8090` is a reasonable default; increment if that port is already bound to another running preview).
3. Launch it as a background process, completely independent of Widgetbook:
   ```bash
   flutter run -t lib/widgets/v3/<category>/preview_v3_<widget>.dart -d web-server --web-hostname 127.0.0.1 --web-port <port>
   ```
4. Read the process output until it reports the serving URL (for example `http://127.0.0.1:<port>`), then share that exact URL with the requester so they can open it in their own browser.
5. Keep the dev server running for the rest of the session. Stop it explicitly when the requester is done, or before starting a different component's live preview on the same port.

Guardrails for this flow:

- Never touch `lib/widgetbook.dart`, `lib/widgetbook_use_cases.dart`, or `lib/widgetbook.directories.g.dart` — this path only runs the widget's own standalone `preview_v3_*.dart` entrypoint.
- Never reuse a port already bound to another running dev server; check first or pick a different one.
- Only launch a preview file that already exists or was just created via `flutter-widget-v3-install`.

## MCP Tools

- `get_v3_widget_preview`
- `generate_v3_widgetbook_use_case`
- `get_v3_widget_metadata`

## Guardrails

- Do not hand-edit `lib/widgetbook.directories.g.dart`; regenerate it with the project's build_runner command instead.
- Preserve the host repo's preview style rather than copying the source repo verbatim.
- Keep preview data realistic enough to exercise the widget's main states (default, interactive, disabled/error where applicable).
