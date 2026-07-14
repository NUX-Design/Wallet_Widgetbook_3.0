import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { createStructuredLogger } from "../../observability.js";
import { startRemoteHttpServer } from "../../http-server.js";

const COMMIT = "a".repeat(40);

function makeDist() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "v3httpdist-"));
  const archive = Buffer.from("hello-bundle-bytes");
  fs.writeFileSync(path.join(dir, "v3-preview-bundle.tar.gz"), archive);
  const manifest = {
    schemaVersion: 1, sourceCommit: COMMIT, createdAt: "2026-07-14T00:00:00.000Z",
    entryPath: "index.html", archiveName: "v3-preview-bundle.tar.gz",
    bytes: archive.length, sha256: crypto.createHash("sha256").update(archive).digest("hex"),
    slugs: ["button/V3MiniButton"],
  };
  fs.writeFileSync(path.join(dir, "manifest.json"), JSON.stringify(manifest));
  return { dir, manifest, archive };
}

async function startServer(t, previewBundleDir) {
  const remote = await startRemoteHttpServer({
    projectRoot: path.resolve(path.dirname(new URL(import.meta.url).pathname), "../.."),
    host: "127.0.0.1", port: 0,
    repoIdentity: "fixture/widget-repo", commitSha: COMMIT, resolveCommitSha: () => COMMIT,
    deployedAt: "2026-07-14T00:00:00.000Z",
    bearerTokens: new Set(["test-token"]),
    previewBundleDir,
    logger: createStructuredLogger({ level: "silent" }),
  });
  t.after(async () => { await remote.close(); });
  return remote.url.replace("/mcp", "");
}

test("preview bundle route requires auth and serves the manifest", async (t) => {
  const { dir, manifest } = makeDist();
  const base = await startServer(t, dir);

  const noAuth = await fetch(`${base}/v3/preview-bundle/manifest.json`);
  assert.equal(noAuth.status, 401);

  const withAuth = await fetch(`${base}/v3/preview-bundle/manifest.json`, { headers: { authorization: "Bearer test-token" } });
  assert.equal(withAuth.status, 200);
  const body = await withAuth.json();
  assert.equal(body.sourceCommit, manifest.sourceCommit);
  assert.deepEqual(body.slugs, ["button/V3MiniButton"]);
});

test("preview bundle route streams the archive with checksum + length headers", async (t) => {
  const { dir, manifest, archive } = makeDist();
  const base = await startServer(t, dir);

  const res = await fetch(`${base}/v3/preview-bundle/${COMMIT}.tar.gz`, { headers: { authorization: "Bearer test-token" } });
  assert.equal(res.status, 200);
  assert.equal(res.headers.get("content-type"), "application/gzip");
  assert.equal(res.headers.get("content-length"), String(manifest.bytes));
  assert.equal(res.headers.get("etag"), `"${manifest.sha256}"`);
  assert.match(res.headers.get("cache-control"), /immutable/);
  const bytes = Buffer.from(await res.arrayBuffer());
  assert.ok(bytes.equals(archive));
  assert.equal(crypto.createHash("sha256").update(bytes).digest("hex"), manifest.sha256);
});

test("preview bundle route rejects bad commit shapes and unknown commits", async (t) => {
  const { dir } = makeDist();
  const base = await startServer(t, dir);

  const badShape = await fetch(`${base}/v3/preview-bundle/deadbeef.tar.gz`, { headers: { authorization: "Bearer test-token" } });
  assert.equal(badShape.status, 404); // not a 40-hex/latest slug -> unknown path

  const unknown = await fetch(`${base}/v3/preview-bundle/${"9".repeat(40)}.tar.gz`, { headers: { authorization: "Bearer test-token" } });
  assert.equal(unknown.status, 404);
  const payload = await unknown.json();
  assert.equal(payload.code, "NOT_BUILT");
});
