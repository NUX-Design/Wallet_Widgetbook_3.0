import assert from "node:assert/strict";
import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { packBundle } from "./pack-v3-preview-bundle.mjs";
import { validateBundleManifest } from "../../mcp-server/v3/bundle_contract.js";

const FAKE_COMMIT = "a".repeat(40);

function makeFixture() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "v3pack-"));
  const sourceDir = path.join(dir, "web");
  // A deep path (>100 bytes) forces ustar prefix/name splitting.
  const deep = "assets/packages/some_really_long_package_name_here/assets/images/deeply/nested/icon.svg";
  fs.mkdirSync(path.join(sourceDir, path.dirname(deep)), { recursive: true });
  fs.writeFileSync(path.join(sourceDir, "index.html"), "<html>preview</html>");
  fs.writeFileSync(path.join(sourceDir, "main.dart.js"), "console.log('flutter');");
  fs.writeFileSync(path.join(sourceDir, deep), "<svg></svg>");

  const registryPath = path.join(dir, "preview_registry.g.dart");
  fs.writeFileSync(
    registryPath,
    "const entries = [V3PreviewDefinition(category: 'button', widgetName: 'V3MiniButton'), V3PreviewDefinition(category: 'badge', widgetName: 'V3Badge')];",
  );
  return { dir, sourceDir, registryPath, deep };
}

test("packBundle produces a valid, contract-conformant manifest", () => {
  const { sourceDir, registryPath } = makeFixture();
  const { manifest } = packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, createdAt: "2026-07-14T00:00:00.000Z", allowDirty: true });
  assert.equal(validateBundleManifest(manifest).valid, true);
  assert.equal(manifest.sourceCommit, FAKE_COMMIT);
  assert.equal(manifest.entryPath, "index.html");
  assert.deepEqual(manifest.slugs, ["badge/V3Badge", "button/V3MiniButton"]); // sorted
});

test("packBundle is byte-for-byte deterministic", () => {
  const { sourceDir, registryPath } = makeFixture();
  const a = packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, createdAt: "2026-07-14T00:00:00.000Z", allowDirty: true });
  const b = packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, createdAt: "2026-07-14T00:00:00.000Z", allowDirty: true });
  assert.ok(a.archive.equals(b.archive), "archives must be identical bytes");
  assert.equal(a.manifest.sha256, b.manifest.sha256);
  assert.equal(a.manifest.sha256, crypto.createHash("sha256").update(a.archive).digest("hex"));
});

test("packBundle output is a standard tar.gz readable by system tar with correct paths", () => {
  const { dir, sourceDir, registryPath, deep } = makeFixture();
  const outDir = path.join(dir, "out");
  packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, allowDirty: true, outDir });
  const archivePath = path.join(outDir, "v3-preview-bundle.tar.gz");
  const listing = execFileSync("tar", ["-tzf", archivePath], { encoding: "utf8" }).trim().split("\n");
  assert.ok(listing.includes("index.html"));
  assert.ok(listing.includes(deep), "deep (prefix-split) path must round-trip");

  const extractDir = path.join(dir, "extract");
  fs.mkdirSync(extractDir);
  execFileSync("tar", ["-xzf", archivePath, "-C", extractDir]);
  assert.equal(fs.readFileSync(path.join(extractDir, "index.html"), "utf8"), "<html>preview</html>");
  assert.equal(fs.readFileSync(path.join(extractDir, deep), "utf8"), "<svg></svg>");
});

test("packBundle rejects a dirty worktree in publish mode", () => {
  const { sourceDir, registryPath } = makeFixture();
  assert.throws(
    () => packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, allowDirty: false, dirtyStatus: " M lib/foo.dart" }),
    /dirty worktree/,
  );
  // allowDirty bypasses for local test bundles
  assert.doesNotThrow(() => packBundle({ sourceDir, registryPath, commit: FAKE_COMMIT, allowDirty: true, dirtyStatus: " M lib/foo.dart" }));
});

test("packBundle rejects an unknown/short commit and an empty registry", () => {
  const { dir, sourceDir, registryPath } = makeFixture();
  assert.throws(() => packBundle({ sourceDir, registryPath, commit: "deadbeef", allowDirty: true }), /40-char hex/);

  const emptyRegistry = path.join(dir, "empty.g.dart");
  fs.writeFileSync(emptyRegistry, "const entries = [];");
  assert.throws(() => packBundle({ sourceDir, registryPath: emptyRegistry, commit: FAKE_COMMIT, allowDirty: true }), /no preview slugs/);
});
