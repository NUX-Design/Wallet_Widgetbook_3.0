---
name: flutter-widget-v3-preview
description: Create or refresh a standalone preview for a Widget V3 component from `flutter-widget-wallet-mcp`, and open it live through the local Widget V3 web preview host. Use when a V3 widget exists but is not yet easy to run or inspect in isolation.
---

# Flutter Widget V3 Preview

Use this skill to make Widget V3 components easy to inspect and validate visually in Light and Dark through the local Widget V3 web preview host (`lib/preview_v3/`, served by `scripts/serve-v3-preview.sh`). This repo isolates Widget V3 from legacy widgets/theme (never import legacy `theme_color.dart` or call `ThemeColors.get()`) and has no Widgetbook; never generate or reference Widgetbook use cases.

## Workflow

1. Pull preview examples from MCP with `get_v3_widget_preview` (or `get_v3_widget_metadata`) when available — the response includes `previewSlug` and `localPreviewUrl` so you never have to hand-construct the route.
2. If the repo does not yet have a standalone `preview_v3_<widget>.dart` entrypoint, create or refresh it with a Light/Dark toggle, mirroring the `V3MiniButton` pilot pattern.
3. Run `dart run tool/generate_v3_preview_registry.dart` after adding or renaming a preview. The generator discovers `preview_v3_*.dart` by convention and updates `lib/preview_v3/preview_registry.g.dart`; never hand-edit either registry file.
4. Keep preview sample data aligned with the widget's public API and semantic token metadata.
5. Confirm both Light and Dark render correctly before finishing.

## Remote-Safe Fallback

When connected through Remote MCP, use `get_v3_widget_preview` and `get_v3_widget_metadata` (both include `previewSlug`/`localPreviewUrl`), then author the local standalone preview and registry entry directly from those read-only results and the host repo conventions. Do not call a Widgetbook generation tool or fall back to any legacy generation tool.

## Live Browser Preview (On Request)

Use this when the requester names a specific Widget V3 component and wants to see it rendered live, not just read the preview source.

1. Resolve the component and its route:
   - Call `get_v3_widget_metadata` (or `get_v3_widget_preview`) to get `previewSlug` and `localPreviewUrl`.
   - If the widget is not installed locally yet, first run the `flutter-widget-v3-install` workflow (`get_v3_widget_metadata` + `get_v3_widget_code` + `get_v3_widget_preview`) so a real preview file exists, then run `dart run tool/generate_v3_preview_registry.dart`.
   - Never invent a preview path or slug; if no widget or preview matches the request, say so and suggest `flutter-widget-v3-search`.
2. Check server readiness before sending any URL: request the base of `localPreviewUrl` (for example `curl -I http://127.0.0.1:8090/`) and only treat it as ready on a 200 response.
3. If the server is not ready, start it as a background process:
   ```bash
   ./scripts/serve-v3-preview.sh
   ```
   Poll the same readiness check (a few retries with short waits) until it responds, then read the exact URL the script prints (`V3 preview ready: http://<host>:<port>/#/<slug>`) to confirm it matches the resolved `localPreviewUrl`.
4. Only once the server has actually responded, share the exact `localPreviewUrl` with the requester so they can open it in their own browser. Never hand back a localhost URL that has not been confirmed reachable.
5. Keep the server running for the rest of the session. Stop it explicitly (the script exits cleanly on Ctrl-C / SIGTERM, leaving no stale process) when the requester is done.

If the Flutter SDK is missing, `flutter build web` fails, or the script errors (port collision, missing entrypoint, etc.), do not claim the preview is live — report the exact command and error, and suggest the actionable fix from the script's own error message (for example pick another port, install/activate Flutter) rather than retrying silently.

Guardrails for this flow:

- Never generate or reference Widgetbook use cases, `@UseCase` annotations, or `lib/widgetbook*` files — none exist in this repo.
- Never reuse a port already bound to another running dev server; the script detects this and reports an actionable error.
- Only launch a preview file that already exists or was just created via `flutter-widget-v3-install`; regenerate the preview registry before serving it.
- Never send a URL before confirming the HTTP server actually responds.

## MCP Tools

- `get_v3_widget_preview`
- `get_v3_widget_metadata`

## Guardrails

- Preserve the host repo's preview style rather than copying the source repo verbatim.
- Keep preview data realistic enough to exercise the widget's main states (default, interactive, disabled/error where applicable).
- This repo has no Widgetbook; do not add it back or generate Widgetbook boilerplate.
