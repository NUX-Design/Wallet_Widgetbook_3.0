// ZP-06 — Bundle delivery catalog/provider.
//
// Wraps a bundle store and turns it into the additive `previewDelivery` metadata
// the MCP preview/metadata tools surface. Responsibilities kept isolated from
// the widget source catalog:
//   - validate the manifest against the frozen contract
//   - enforce source-SHA parity against MCP freshness (STALE_BUNDLE)
//   - confirm the requested widget slug is actually in the published bundle
//   - build a secret-free bundleUrl pointing at the hosted delivery route
//   - report availability/freshness health
//
// Never throws on the "no bundle yet" path in a way that breaks a preview tool;
// callers get a structured status instead.

import {
  V3_PREVIEW_ERROR_CODES,
  buildSignedBundleUrl,
  buildPreviewDelivery,
  urlContainsSecret,
  validateBundleManifest,
} from "./bundle_contract.js";

const DEFAULT_BUNDLE_BASE_URL =
  process.env.V3_PREVIEW_BUNDLE_BASE_URL || "https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle";

export class V3BundleCatalog {
  #store;
  #baseUrl;
  #resolveFreshnessCommit;
  #signingSecret;
  #signedUrlTtlSeconds;

  /**
   * @param {object} opts
   * @param {object} opts.store  bundle store (LocalDir / GitHubRelease)
   * @param {string} [opts.bundleBaseUrl]  public, secret-free base URL for the delivery route
   * @param {() => string} [opts.resolveFreshnessCommit]  MCP catalog freshness commit ("" to skip parity)
   */
  constructor({ store, bundleBaseUrl = DEFAULT_BUNDLE_BASE_URL, resolveFreshnessCommit = () => "", signingSecret = "", signedUrlTtlSeconds = 300 }) {
    this.#store = store;
    this.#baseUrl = bundleBaseUrl.replace(/\/+$/, "");
    this.#resolveFreshnessCommit = resolveFreshnessCommit;
    this.#signingSecret = signingSecret;
    this.#signedUrlTtlSeconds = signedUrlTtlSeconds;
  }

  #bundleUrl(commit) {
    const url = buildSignedBundleUrl({
      baseUrl: this.#baseUrl,
      commit,
      signingSecret: this.#signingSecret,
      ttlSeconds: this.#signedUrlTtlSeconds,
    });
    if (urlContainsSecret(url)) {
      throw new Error("computed bundleUrl unexpectedly contains a secret; refusing to expose it");
    }
    return url;
  }

  /**
   * Resolve delivery metadata for a widget slug.
   * @returns {{ available: true, previewDelivery: object }
   *          | { available: false, code: string, message: string }}
   */
  async describeDelivery({ slug }) {
    let manifest;
    const freshnessCommit = (this.#resolveFreshnessCommit() || "").trim();
    try {
      // Production selection is immutable: resolve the release matching the
      // deployed MCP commit, never the mutable convenience pointer "latest".
      manifest = await this.#store.readManifest({ commit: freshnessCommit || "latest" });
    } catch (error) {
      return { available: false, code: error.code || V3_PREVIEW_ERROR_CODES.NOT_BUILT, message: error.message };
    }

    const validation = validateBundleManifest(manifest);
    if (!validation.valid) {
      return { available: false, code: validation.code, message: `Published manifest is invalid: ${validation.errors.join("; ")}` };
    }

    if (freshnessCommit && freshnessCommit !== manifest.sourceCommit) {
      return {
        available: false,
        code: V3_PREVIEW_ERROR_CODES.STALE_BUNDLE,
        message: `Published bundle commit ${manifest.sourceCommit} does not match MCP freshness commit ${freshnessCommit}.`,
      };
    }

    if (slug && !manifest.slugs.includes(slug)) {
      return {
        available: false,
        code: V3_PREVIEW_ERROR_CODES.NOT_BUILT,
        message: `No published preview for slug "${slug}" in bundle ${manifest.sourceCommit}. Available: ${manifest.slugs.join(", ")}.`,
      };
    }

    return {
      available: true,
      previewDelivery: buildPreviewDelivery({ manifest, bundleUrl: this.#bundleUrl(manifest.sourceCommit) }),
    };
  }

  /** Availability/freshness health for /info and diagnostics. */
  async health() {
    try {
      const freshnessCommit = (this.#resolveFreshnessCommit() || "").trim();
      const manifest = await this.#store.readManifest({ commit: freshnessCommit || "latest" });
      const validation = validateBundleManifest(manifest);
      if (!validation.valid) {
        return { available: false, code: validation.code, message: validation.errors.join("; ") };
      }
      const fresh = !freshnessCommit || freshnessCommit === manifest.sourceCommit;
      return {
        available: true,
        fresh,
        sourceCommit: manifest.sourceCommit,
        freshnessCommit: freshnessCommit || null,
        slugs: manifest.slugs,
        createdAt: manifest.createdAt,
      };
    } catch (error) {
      return { available: false, code: error.code || V3_PREVIEW_ERROR_CODES.NOT_BUILT, message: error.message };
    }
  }

  /** Direct archive access for the HTTP delivery route (streaming). */
  async openArchive({ commit }) {
    return this.#store.openArchive({ commit });
  }

  /** Validated manifest for the HTTP delivery route (manifest.json). */
  async manifest({ commit = "latest" } = {}) {
    const manifest = await this.#store.readManifest({ commit });
    const validation = validateBundleManifest(manifest);
    if (!validation.valid) {
      const err = new Error(`Published manifest is invalid: ${validation.errors.join("; ")}`);
      err.code = validation.code;
      throw err;
    }
    return manifest;
  }
}
