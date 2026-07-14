import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import {
  V3_PREVIEW_BUNDLE_SCHEMA_VERSION,
  V3_PREVIEW_ERROR_CODES,
  buildPreviewDelivery,
  urlContainsSecret,
  validateBundleManifest,
} from "../../v3/bundle_contract.js";

const fixtureManifestPath = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "../fixtures/v3_preview_bundle/manifest.json",
);

function validFixture() {
  return JSON.parse(fs.readFileSync(fixtureManifestPath, "utf8"));
}

test("fixture manifest satisfies the frozen contract", () => {
  const result = validateBundleManifest(validFixture());
  assert.equal(result.valid, true);
  assert.equal(result.manifest.schemaVersion, V3_PREVIEW_BUNDLE_SCHEMA_VERSION);
});

test("validateBundleManifest rejects non-object input without throwing", () => {
  for (const bad of [null, undefined, "x", 5, []]) {
    const result = validateBundleManifest(bad);
    assert.equal(result.valid, false);
    assert.equal(result.code, V3_PREVIEW_ERROR_CODES.MALFORMED_MANIFEST);
  }
});

test("validateBundleManifest flags each malformed field", () => {
  const cases = [
    ["sourceCommit", "not-a-sha"],
    ["sha256", "deadbeef"],
    ["createdAt", "yesterday"],
    ["entryPath", "../escape.html"],
    ["bytes", 0],
    ["slugs", []],
    ["slugs", ["button/NotV3"]],
  ];
  for (const [field, value] of cases) {
    const manifest = validFixture();
    manifest[field] = value;
    const result = validateBundleManifest(manifest);
    assert.equal(result.valid, false, `expected ${field}=${JSON.stringify(value)} to be invalid`);
  }
});

test("validateBundleManifest fails closed on a newer schema version", () => {
  const manifest = validFixture();
  manifest.schemaVersion = V3_PREVIEW_BUNDLE_SCHEMA_VERSION + 1;
  const result = validateBundleManifest(manifest);
  assert.equal(result.valid, false);
  assert.equal(result.code, V3_PREVIEW_ERROR_CODES.SCHEMA_UNSUPPORTED);
});

test("buildPreviewDelivery mirrors the manifest additively and stays secret-free", () => {
  const manifest = validFixture();
  const bundleUrl = "https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle/" + manifest.sourceCommit + ".tar.gz";
  const delivery = buildPreviewDelivery({ manifest, bundleUrl });
  assert.equal(delivery.mode, "bundle");
  assert.equal(delivery.schemaVersion, manifest.schemaVersion);
  assert.equal(delivery.sourceCommit, manifest.sourceCommit);
  assert.equal(delivery.sha256, manifest.sha256);
  assert.equal(delivery.entryPath, manifest.entryPath);
  assert.equal(delivery.bundleUrl, bundleUrl);
  assert.equal(urlContainsSecret(delivery.bundleUrl), false);
});

test("urlContainsSecret catches token leaks in query and userinfo", () => {
  assert.equal(urlContainsSecret("https://host/bundle.tar.gz?token=abc123"), true);
  assert.equal(urlContainsSecret("https://host/bundle.tar.gz?access_token=abc"), true);
  assert.equal(urlContainsSecret("https://user:secretpat@host/bundle.tar.gz"), true);
  assert.equal(urlContainsSecret("https://host/v3/preview-bundle/deadbeef.tar.gz"), false);
});
