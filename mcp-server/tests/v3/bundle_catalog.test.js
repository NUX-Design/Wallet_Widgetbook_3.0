import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { Readable } from "node:stream";
import test from "node:test";
import { V3BundleCatalog } from "../../v3/bundle_catalog.js";
import { GitHubReleaseBundleStore, LocalDirBundleStore } from "../../v3/bundle_store.js";
import { V3_PREVIEW_ERROR_CODES } from "../../v3/bundle_contract.js";

const COMMIT = "b".repeat(40);
const SHA256 = "c".repeat(64);

function makeDist({ commit = COMMIT, slugs = ["button/V3MiniButton"], corrupt = false } = {}) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "v3dist-"));
  const manifest = corrupt
    ? { schemaVersion: 1, sourceCommit: "bad", sha256: SHA256, slugs }
    : {
        schemaVersion: 1,
        sourceCommit: commit,
        createdAt: "2026-07-14T00:00:00.000Z",
        entryPath: "index.html",
        archiveName: "v3-preview-bundle.tar.gz",
        bytes: 6,
        sha256: SHA256,
        slugs,
      };
  fs.writeFileSync(path.join(dir, "manifest.json"), JSON.stringify(manifest));
  fs.writeFileSync(path.join(dir, "v3-preview-bundle.tar.gz"), Buffer.from("ABCDEF"));
  return dir;
}

test("catalog resolves an available, fresh, secret-free delivery", async () => {
  const catalog = new V3BundleCatalog({
    store: new LocalDirBundleStore(makeDist()),
    bundleBaseUrl: "https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle",
    resolveFreshnessCommit: () => COMMIT,
  });
  const result = await catalog.describeDelivery({ slug: "button/V3MiniButton" });
  assert.equal(result.available, true);
  assert.equal(result.previewDelivery.mode, "bundle");
  assert.equal(result.previewDelivery.sourceCommit, COMMIT);
  assert.equal(result.previewDelivery.sha256, SHA256);
  assert.equal(result.previewDelivery.bundleUrl, `https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle/${COMMIT}.tar.gz`);
});

test("catalog reports STALE_BUNDLE when freshness commit differs", async () => {
  const catalog = new V3BundleCatalog({ store: new LocalDirBundleStore(makeDist()), resolveFreshnessCommit: () => "d".repeat(40) });
  const result = await catalog.describeDelivery({ slug: "button/V3MiniButton" });
  assert.equal(result.available, false);
  assert.equal(result.code, V3_PREVIEW_ERROR_CODES.STALE_BUNDLE);
});

test("catalog reports NOT_BUILT for a slug missing from the bundle and for no bundle", async () => {
  const withBundle = new V3BundleCatalog({ store: new LocalDirBundleStore(makeDist()), resolveFreshnessCommit: () => COMMIT });
  const missingSlug = await withBundle.describeDelivery({ slug: "badge/V3Badge" });
  assert.equal(missingSlug.available, false);
  assert.equal(missingSlug.code, V3_PREVIEW_ERROR_CODES.NOT_BUILT);

  const noBundle = new V3BundleCatalog({ store: new LocalDirBundleStore(path.join(os.tmpdir(), "does-not-exist-xyz")) });
  const none = await noBundle.describeDelivery({ slug: "button/V3MiniButton" });
  assert.equal(none.available, false);
  assert.equal(none.code, V3_PREVIEW_ERROR_CODES.NOT_BUILT);
});

test("catalog reports MALFORMED_MANIFEST for an invalid published manifest", async () => {
  const catalog = new V3BundleCatalog({ store: new LocalDirBundleStore(makeDist({ corrupt: true })) });
  const result = await catalog.describeDelivery({ slug: "button/V3MiniButton" });
  assert.equal(result.available, false);
  assert.equal(result.code, V3_PREVIEW_ERROR_CODES.MALFORMED_MANIFEST);
});

test("catalog health reports availability and freshness", async () => {
  const catalog = new V3BundleCatalog({ store: new LocalDirBundleStore(makeDist()), resolveFreshnessCommit: () => COMMIT });
  const health = await catalog.health();
  assert.equal(health.available, true);
  assert.equal(health.fresh, true);
  assert.equal(health.sourceCommit, COMMIT);
  assert.deepEqual(health.slugs, ["button/V3MiniButton"]);
});

test("LocalDirBundleStore streams archive bytes with size + checksum", async () => {
  const store = new LocalDirBundleStore(makeDist());
  const archive = await store.openArchive({ commit: "latest" });
  assert.equal(archive.sha256, SHA256);
  assert.equal(archive.sourceCommit, COMMIT);
  const chunks = [];
  for await (const c of archive.stream()) chunks.push(c);
  assert.equal(Buffer.concat(chunks).toString(), "ABCDEF");
});

test("GitHubReleaseBundleStore maps status codes and streams via injected fetch", async () => {
  const release = {
    tag_name: `v3-preview-${COMMIT}`,
    assets: [
      { name: "manifest.json", url: "https://api.example/assets/1" },
      { name: "v3-preview-bundle.tar.gz", url: "https://api.example/assets/2", size: 6 },
    ],
  };
  const manifest = { schemaVersion: 1, sourceCommit: COMMIT, createdAt: "2026-07-14T00:00:00.000Z", entryPath: "index.html", archiveName: "v3-preview-bundle.tar.gz", bytes: 6, sha256: SHA256, slugs: ["button/V3MiniButton"] };
  const fetchImpl = async (url) => {
    if (url.endsWith("/releases/tags/v3-preview-" + COMMIT)) return new Response(JSON.stringify(release), { status: 200 });
    if (url === "https://api.example/assets/1") return new Response(JSON.stringify(manifest), { status: 200 });
    if (url === "https://api.example/assets/2") return new Response(Readable.toWeb(Readable.from([Buffer.from("ABCDEF")])), { status: 200 });
    return new Response("nope", { status: 404 });
  };
  const store = new GitHubReleaseBundleStore({ repo: "owner/repo", token: "t", fetchImpl });
  const got = await store.readManifest({ commit: COMMIT });
  assert.equal(got.sourceCommit, COMMIT);
  const archive = await store.openArchive({ commit: COMMIT });
  assert.equal(archive.bytes, 6);
  const stream = await archive.stream();
  const chunks = [];
  for await (const c of stream) chunks.push(c);
  assert.equal(Buffer.concat(chunks).toString(), "ABCDEF");

  // 404 -> NOT_BUILT
  const missingStore = new GitHubReleaseBundleStore({ repo: "owner/repo", fetchImpl: async () => new Response("", { status: 404 }) });
  await assert.rejects(() => missingStore.readManifest({ commit: COMMIT }), /NOT_BUILT|no published/i);
});
