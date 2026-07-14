// Widget V3 Zero-Flutter Consumer Preview — frozen delivery contract.
//
// Single source of truth for the immutable, commit-addressed Flutter Web
// preview bundle contract shared by:
//   - the source packer (scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs)
//   - the MCP bundle provider (mcp-server/v3/bundle_catalog.js)
//   - the repo-independent launcher (scripts/v3-preview-bundle/launch-v3-preview.mjs
//     keeps an inlined copy of the small constants it needs so it stays a
//     dependency-free standalone file)
//
// See docs/v3/V3_ZERO_FLUTTER_PREVIEW_CONTRACT.md for the human-facing spec.

// Bump only on an incompatible manifest/previewDelivery shape change. Consumers
// must reject a manifest whose schemaVersion is greater than they understand.
export const V3_PREVIEW_BUNDLE_SCHEMA_VERSION = 1;

// The delivery mode advertised in previewDelivery.mode. Reserved for future
// alternatives (e.g. "stream"); consumers must treat unknown modes as fatal.
export const V3_PREVIEW_DELIVERY_MODE = "bundle";

// Full 40-char lowercase hex git SHA. Bundles are addressed by full commit so a
// consumer cache key can never collide across branches or rebases.
export const V3_PREVIEW_COMMIT_SHA_PATTERN = /^[0-9a-f]{40}$/;

// Lowercase hex SHA-256 of the archive bytes.
export const V3_PREVIEW_SHA256_PATTERN = /^[0-9a-f]{64}$/;

// Route slug shape: "<category>/<WidgetClass>" e.g. "button/V3MiniButton".
export const V3_PREVIEW_SLUG_PATTERN = /^[a-z0-9_]+\/V3[A-Za-z0-9]+$/;

// Canonical archive + manifest file names produced by the packer.
export const V3_PREVIEW_ARCHIVE_NAME = "v3-preview-bundle.tar.gz";
export const V3_PREVIEW_MANIFEST_NAME = "manifest.json";

// The HTML entry the launcher must serve as "/" inside the extracted bundle.
export const V3_PREVIEW_ENTRY_PATH = "index.html";

// Error codes are stable, matchable strings so skills/launchers can branch and
// fail closed with actionable messages. MCP-side codes reuse the existing
// ToolError vocabulary (NOT_FOUND/INTERNAL_ERROR); these are the delivery- and
// launcher-specific codes layered on top.
export const V3_PREVIEW_ERROR_CODES = Object.freeze({
  // Delivery/MCP side
  NOT_BUILT: "NOT_BUILT", // no published bundle exists for the requested commit/widget
  STALE_BUNDLE: "STALE_BUNDLE", // bundle sourceCommit does not match MCP freshness commit
  UNAUTHORIZED: "UNAUTHORIZED", // bearer token missing/invalid for resolve or download
  MALFORMED_MANIFEST: "MALFORMED_MANIFEST", // manifest failed schema validation
  // Launcher / consumer side
  CHECKSUM_MISMATCH: "CHECKSUM_MISMATCH", // downloaded archive sha256 != manifest sha256
  DOWNLOAD_FAILED: "DOWNLOAD_FAILED", // network/transport failure fetching the bundle
  UNSAFE_ARCHIVE: "UNSAFE_ARCHIVE", // archive contained a path-traversal / absolute / symlink entry
  SCHEMA_UNSUPPORTED: "SCHEMA_UNSUPPORTED", // manifest schemaVersion newer than launcher understands
  PORT_UNAVAILABLE: "PORT_UNAVAILABLE", // could not bind a loopback port
  RUNTIME_MISSING: "RUNTIME_MISSING", // neither python3 nor node available to serve
});

// Platform-neutral consumer cache root, relative to the OS user cache dir.
// Full path resolves to: <userCache>/flutter-widget-wallet/v3-preview/<commit>/
export const V3_PREVIEW_CACHE_VENDOR_DIR = "flutter-widget-wallet";
export const V3_PREVIEW_CACHE_SUBDIR = "v3-preview";

function isNonEmptyString(value) {
  return typeof value === "string" && value.length > 0;
}

/**
 * Validate a bundle manifest object against the frozen contract.
 * Returns { valid: true, manifest } or { valid: false, code, errors: [...] }.
 * Pure and dependency-free so the packer, MCP provider, and launcher can all
 * reuse it. Never throws on bad input.
 */
export function validateBundleManifest(manifest) {
  const errors = [];
  if (manifest === null || typeof manifest !== "object" || Array.isArray(manifest)) {
    return { valid: false, code: V3_PREVIEW_ERROR_CODES.MALFORMED_MANIFEST, errors: ["manifest must be a JSON object"] };
  }

  if (!Number.isInteger(manifest.schemaVersion) || manifest.schemaVersion < 1) {
    errors.push("schemaVersion must be a positive integer");
  } else if (manifest.schemaVersion > V3_PREVIEW_BUNDLE_SCHEMA_VERSION) {
    return {
      valid: false,
      code: V3_PREVIEW_ERROR_CODES.SCHEMA_UNSUPPORTED,
      errors: [`schemaVersion ${manifest.schemaVersion} is newer than supported ${V3_PREVIEW_BUNDLE_SCHEMA_VERSION}`],
    };
  }

  if (!isNonEmptyString(manifest.sourceCommit) || !V3_PREVIEW_COMMIT_SHA_PATTERN.test(manifest.sourceCommit)) {
    errors.push("sourceCommit must be a full 40-char lowercase hex git SHA");
  }
  if (!isNonEmptyString(manifest.sha256) || !V3_PREVIEW_SHA256_PATTERN.test(manifest.sha256)) {
    errors.push("sha256 must be a 64-char lowercase hex SHA-256");
  }
  if (!isNonEmptyString(manifest.createdAt) || Number.isNaN(Date.parse(manifest.createdAt))) {
    errors.push("createdAt must be an ISO-8601 timestamp");
  }
  if (!isNonEmptyString(manifest.entryPath)) {
    errors.push("entryPath must be a non-empty relative path");
  } else if (manifest.entryPath.startsWith("/") || manifest.entryPath.includes("..")) {
    errors.push("entryPath must be a relative in-bundle path with no traversal");
  }
  if (!isNonEmptyString(manifest.archiveName)) {
    errors.push("archiveName must be a non-empty string");
  }
  if (!Number.isInteger(manifest.bytes) || manifest.bytes <= 0) {
    errors.push("bytes must be a positive integer");
  }
  if (!Array.isArray(manifest.slugs) || manifest.slugs.length === 0) {
    errors.push("slugs must be a non-empty array");
  } else {
    for (const slug of manifest.slugs) {
      if (!isNonEmptyString(slug) || !V3_PREVIEW_SLUG_PATTERN.test(slug)) {
        errors.push(`slug "${slug}" must match <category>/V3<Widget>`);
        break;
      }
    }
  }

  if (errors.length > 0) {
    return { valid: false, code: V3_PREVIEW_ERROR_CODES.MALFORMED_MANIFEST, errors };
  }
  return { valid: true, manifest };
}

/**
 * Build the additive `previewDelivery` object exposed on MCP preview/metadata
 * responses from a validated manifest plus a resolved (secret-free) bundle URL.
 * The bundleUrl MUST NOT embed a bearer token — auth is sent as a request
 * header by the consumer at download time.
 */
export function buildPreviewDelivery({ manifest, bundleUrl }) {
  return {
    mode: V3_PREVIEW_DELIVERY_MODE,
    schemaVersion: manifest.schemaVersion,
    sourceCommit: manifest.sourceCommit,
    bundleUrl,
    sha256: manifest.sha256,
    entryPath: manifest.entryPath,
  };
}

/**
 * Detect a bearer token accidentally embedded in a URL (query or userinfo) so
 * the provider/launcher can fail closed instead of leaking it into logs/cache.
 */
export function urlContainsSecret(rawUrl) {
  if (!isNonEmptyString(rawUrl)) return false;
  const lowered = rawUrl.toLowerCase();
  if (/[?&](token|access_token|bearer|authorization|secret|api[_-]?key)=/.test(lowered)) return true;
  // userinfo component like https://user:token@host/...
  const match = /^[a-z][a-z0-9+.-]*:\/\/([^/@]+)@/.exec(lowered);
  return Boolean(match && match[1].includes(":"));
}
