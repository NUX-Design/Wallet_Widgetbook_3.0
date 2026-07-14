// ZP-05 — Bundle delivery source abstraction.
//
// A bundle store knows how to read the manifest and stream the archive bytes for
// a published Widget V3 preview bundle. Two backends:
//   - LocalDirBundleStore: reads dist/v3-preview-bundle (source-dev / self-host).
//   - GitHubReleaseBundleStore: reads commit-addressed GitHub Release assets
//     published by the CI pipeline (ZP-04); server-side token stays here so the
//     consumer only ever talks to the hosted MCP endpoint with its bearer token.
//
// Stores never load the whole archive into memory as base64 in an MCP JSON
// response — archive bytes are always streamed by the HTTP delivery route.

import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { Readable } from "node:stream";
import {
  V3_PREVIEW_ARCHIVE_NAME,
  V3_PREVIEW_MANIFEST_NAME,
} from "./bundle_contract.js";

export class BundleStoreError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "BundleStoreError";
    this.code = code;
  }
}

export class LocalDirBundleStore {
  #dir;
  constructor(dir) {
    this.#dir = dir;
  }

  available() {
    return fs.existsSync(path.join(this.#dir, V3_PREVIEW_MANIFEST_NAME));
  }

  // Returns the parsed manifest JSON. `commit`/"latest" are accepted for API
  // symmetry with the release store; a local dir only ever holds one bundle so
  // a specific-commit request that doesn't match reports NOT_BUILT.
  async readManifest({ commit = "latest" } = {}) {
    const manifestPath = path.join(this.#dir, V3_PREVIEW_MANIFEST_NAME);
    if (!fs.existsSync(manifestPath)) {
      throw new BundleStoreError("NOT_BUILT", `No local preview bundle at ${this.#dir}. Run scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs.`);
    }
    const manifest = JSON.parse(fs.readFileSync(manifestPath, "utf8"));
    if (commit !== "latest" && manifest.sourceCommit !== commit) {
      throw new BundleStoreError("NOT_BUILT", `Local bundle is commit ${manifest.sourceCommit}, not requested ${commit}.`);
    }
    return manifest;
  }

  async openArchive({ commit = "latest" } = {}) {
    const manifest = await this.readManifest({ commit });
    const archivePath = path.join(this.#dir, manifest.archiveName || V3_PREVIEW_ARCHIVE_NAME);
    if (!fs.existsSync(archivePath)) {
      throw new BundleStoreError("NOT_BUILT", `Bundle archive missing at ${archivePath}.`);
    }
    const bytes = fs.statSync(archivePath).size;
    return {
      bytes,
      sha256: manifest.sha256,
      sourceCommit: manifest.sourceCommit,
      stream: () => fs.createReadStream(archivePath),
    };
  }
}

export class GitHubReleaseBundleStore {
  #repo;
  #token;
  #fetch;
  #apiBase;
  constructor({ repo, token = "", fetchImpl = globalThis.fetch, apiBase = "https://api.github.com" }) {
    if (!repo) throw new Error("GitHubReleaseBundleStore requires a repo (owner/name).");
    this.#repo = repo;
    this.#token = token;
    this.#fetch = fetchImpl;
    this.#apiBase = apiBase;
  }

  #headers(accept) {
    const headers = { accept, "user-agent": "flutter-widget-wallet-mcp" };
    if (this.#token) headers.authorization = `Bearer ${this.#token}`;
    return headers;
  }

  #tagFor(commit) {
    return commit === "latest" ? "v3-preview-latest" : `v3-preview-${commit}`;
  }

  async #release(commit) {
    const tag = this.#tagFor(commit);
    const res = await this.#fetch(`${this.#apiBase}/repos/${this.#repo}/releases/tags/${tag}`, {
      headers: this.#headers("application/vnd.github+json"),
    });
    if (res.status === 404) throw new BundleStoreError("NOT_BUILT", `No published bundle release "${tag}".`);
    if (res.status === 401 || res.status === 403) throw new BundleStoreError("UNAUTHORIZED", `GitHub rejected bundle release access for "${tag}".`);
    if (!res.ok) throw new BundleStoreError("DOWNLOAD_FAILED", `GitHub release lookup failed (${res.status}).`);
    return res.json();
  }

  #asset(release, name) {
    const asset = (release.assets || []).find((a) => a.name === name);
    if (!asset) throw new BundleStoreError("NOT_BUILT", `Release "${release.tag_name}" has no asset "${name}".`);
    return asset;
  }

  async readManifest({ commit = "latest" } = {}) {
    const release = await this.#release(commit);
    const asset = this.#asset(release, V3_PREVIEW_MANIFEST_NAME);
    const res = await this.#fetch(asset.url, { headers: this.#headers("application/octet-stream") });
    if (!res.ok) throw new BundleStoreError("DOWNLOAD_FAILED", `Failed to fetch manifest asset (${res.status}).`);
    return res.json();
  }

  async openArchive({ commit = "latest" } = {}) {
    const release = await this.#release(commit);
    const manifest = await (async () => {
      const asset = this.#asset(release, V3_PREVIEW_MANIFEST_NAME);
      const res = await this.#fetch(asset.url, { headers: this.#headers("application/octet-stream") });
      if (!res.ok) throw new BundleStoreError("DOWNLOAD_FAILED", `Failed to fetch manifest asset (${res.status}).`);
      return res.json();
    })();
    const archiveAsset = this.#asset(release, manifest.archiveName || V3_PREVIEW_ARCHIVE_NAME);
    return {
      bytes: archiveAsset.size ?? manifest.bytes,
      sha256: manifest.sha256,
      sourceCommit: manifest.sourceCommit,
      stream: async () => {
        const res = await this.#fetch(archiveAsset.url, { headers: this.#headers("application/octet-stream") });
        if (res.status === 401 || res.status === 403) throw new BundleStoreError("UNAUTHORIZED", "GitHub rejected archive download.");
        if (!res.ok || !res.body) throw new BundleStoreError("DOWNLOAD_FAILED", `Failed to stream archive (${res.status}).`);
        return Readable.fromWeb(res.body);
      },
    };
  }
}

// Small helper for tests / self-host verification.
export function sha256Hex(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}
