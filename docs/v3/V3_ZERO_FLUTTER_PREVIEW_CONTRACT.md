# Widget V3 Zero-Flutter Consumer Preview — Frozen Contract (ZP-01)

สร้างเมื่อ: `2026-07-14`

Frozen delivery contract for the zero-Flutter consumer preview. Machine source
of truth is [`mcp-server/v3/bundle_contract.js`](../../mcp-server/v3/bundle_contract.js);
this document is the human-facing spec. Do not change either without bumping
`schemaVersion` and updating both. Plan: [`docs/V3_ZERO_FLUTTER_PREVIEW_PLAN.md`](../V3_ZERO_FLUTTER_PREVIEW_PLAN.md).

## Scope

- **Consumer/target repo**: any repo (React, Node, empty, plain directory). No
  Flutter SDK, no Dart SDK, no `pubspec.yaml`, no `lib/`, no Flutter files.
- **Source repo**: this repo. Sole source of truth for Widget V3, previews,
  Theme V3, and the compiled preview bundle (built only in source CI).

## Bundle Manifest

Deterministic JSON emitted next to the archive by the source packer (ZP-03).

| Field | Type | Rule |
|---|---|---|
| `schemaVersion` | integer | Currently `2`. Consumer rejects `> supported`. |
| `sourceCommit` | string | Full 40-char lowercase hex git SHA. Commit-addressed. |
| `createdAt` | string | ISO-8601 build timestamp. |
| `entryPath` | string | Relative in-bundle HTML entry, `index.html`. No `..`/absolute. |
| `archiveName` | string | `v3-preview-bundle.tar.gz`. |
| `bytes` | integer | Archive size in bytes (> 0). |
| `sha256` | string | 64-char lowercase hex SHA-256 of the archive bytes. |
| `slugs` | string[] | Non-empty `<category>/V3<Widget>` routes the bundle serves. |

One bundle covers **all** registered slugs so widgets never trigger a per-widget
rebuild. `validateBundleManifest()` is the shared validator (never throws).

## `previewDelivery` (additive MCP field, ZP-07)

Returned additively by `get_v3_widget_preview` / `get_v3_widget_metadata`
/ `get_v3_widget_details`. Legacy fields are preserved.

```json
{
  "previewDelivery": {
    "mode": "bundle",
    "schemaVersion": 2,
    "sourceCommit": "<full-sha>",
    "bundleUrl": "<secret-free download URL>",
    "sha256": "<hex>",
    "entryPath": "index.html"
  }
}
```

- `sourceCommit` MUST equal the MCP catalog freshness commit; otherwise the
  provider reports `STALE_BUNDLE` rather than serving a mismatched bundle.
- `bundleUrl` is a commit-bound signed URL with short-lived `expires`/`sig`
  parameters. It never contains the MCP bearer token and needs no second
  consumer credential.
- `mode` unknown to a consumer is fatal.

## Cache Path Policy

- Root: `<userCache>/flutter-widget-wallet/v3-preview/<sourceCommit>/`
  - `<userCache>` = `$XDG_CACHE_HOME` if set, else `~/.cache` (Linux),
    `~/Library/Caches` (macOS), `%LOCALAPPDATA%` (Windows).
- Immutable, commit-addressed: a warm cache is reused only when both the commit
  **and** the manifest `sha256` match. Cache is never written inside the
  consumer workspace.
- Download goes to a temp file in the cache dir, is checksum-verified, then
  atomically renamed into place. Concurrent launches lock per commit.

## Port Policy

- Bind **loopback only** (`127.0.0.1`). Never `0.0.0.0`.
- Select a free ephemeral port unless the caller pins one; a warm server whose
  `/__preview_health__` reports the matching commit+checksum is reused.
- The local URL (`http://127.0.0.1:<port>/#/<slug>`) is handed back **only**
  after an HTTP readiness probe passes.

## Auth Boundary

- Bearer token is used only by the MCP client to resolve delivery metadata.
- The authenticated MCP response returns a short-lived signed archive URL;
  the launcher downloads through it without reading or receiving the MCP token.
- Token MUST NOT appear in: the bundle URL, the manifest, any log line, the
  cache directory/manifest, or browser history.
- Uses the existing hosted Render service and its existing bearer mechanism. No
  second Render service.

## Error Codes

Stable strings (`V3_PREVIEW_ERROR_CODES`) so skills/launchers branch and fail
closed with actionable messages.

Delivery / MCP side: `NOT_BUILT`, `STALE_BUNDLE`, `UNAUTHORIZED`,
`MALFORMED_MANIFEST`.
Launcher / consumer side: `CHECKSUM_MISMATCH`, `DOWNLOAD_FAILED`,
`UNSAFE_ARCHIVE`, `SCHEMA_UNSUPPORTED`, `PORT_UNAVAILABLE`, `RUNTIME_MISSING`.

## Published vs Source-Development Semantics

| | Published consumer mode (default) | Source-development mode |
|---|---|---|
| Called from | any repo (no Flutter) | this source repo |
| Flutter runs | source CI only | local developer machine |
| Freshness | the immutable commit the MCP/manifest reports | latest working tree |
| Entrypoint | launcher + hosted bundle | `scripts/serve-v3-preview.sh` |
| Hot reload of uncommitted Dart | **not supported** | supported via Flutter tooling |

"Published preview" means an interactive local preview of a verified source
commit — **not** hot reload of uncommitted Dart source on a machine without
Flutter. If a caller needs uncommitted-source hot reload, they must use
source-development mode on a machine with Flutter (see the plan's Hard
Constraint), or commit/push so source CI publishes a new bundle.
