import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { createToolHarness } from "../helpers/tool_harness.js";
import { V3BundleCatalog } from "../../v3/bundle_catalog.js";
import { LocalDirBundleStore } from "../../v3/bundle_store.js";

const fixtureRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../fixtures/v3_repo");
const COMMIT = "e".repeat(40);
const SHA256 = "f".repeat(64);

function distWith(slugs) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "v3deliv-"));
  fs.writeFileSync(path.join(dir, "manifest.json"), JSON.stringify({
    schemaVersion: 1, sourceCommit: COMMIT, createdAt: "2026-07-14T00:00:00.000Z",
    entryPath: "index.html", archiveName: "v3-preview-bundle.tar.gz", bytes: 6, sha256: SHA256, slugs,
  }));
  fs.writeFileSync(path.join(dir, "v3-preview-bundle.tar.gz"), Buffer.from("ABCDEF"));
  return dir;
}

function harnessWithBundle(slugs) {
  const catalog = new V3BundleCatalog({ store: new LocalDirBundleStore(distWith(slugs)), resolveFreshnessCommit: () => COMMIT });
  return createToolHarness(fixtureRoot, { v3BundleCatalog: catalog });
}

test("previewDelivery is added additively when a matching bundle is published", async () => {
  const harness = harnessWithBundle(["button/V3TestButton"]);
  for (const tool of ["get_v3_widget_metadata", "get_v3_widget_details", "get_v3_widget_preview"]) {
    const res = await harness.callSuccess(tool, { widgetName: "V3TestButton" });
    assert.equal(res.data.previewDelivery.mode, "bundle", `${tool} previewDelivery.mode`);
    assert.equal(res.data.previewDelivery.sourceCommit, COMMIT);
    assert.equal(res.data.previewDelivery.sha256, SHA256);
    assert.equal(res.data.previewDelivery.entryPath, "index.html");
    // Additive: legacy fields still present and unchanged.
    assert.equal(res.data.previewSlug, "button/V3TestButton");
    assert.equal(res.data.localPreviewUrl, "http://127.0.0.1:8090/#/button/V3TestButton");
    assert.equal(res.data.previewDeliveryStatus, undefined);
  }
});

test("previewDeliveryStatus reports NOT_BUILT without breaking the tool", async () => {
  const harness = harnessWithBundle(["badge/V3Badge"]); // requested widget slug is absent
  const res = await harness.callSuccess("get_v3_widget_preview", { widgetName: "V3TestButton" });
  assert.equal(res.data.previewDelivery, undefined);
  assert.equal(res.data.previewDeliveryStatus.available, false);
  assert.equal(res.data.previewDeliveryStatus.code, "NOT_BUILT");
  // Legacy fields still present.
  assert.equal(res.data.previewSlug, "button/V3TestButton");
  assert.match(res.data.previews[0].file, /preview_v3_test_button/);
});

test("without a bundle catalog wired, the pre-existing contract is unchanged", async () => {
  const harness = createToolHarness(fixtureRoot); // no v3BundleCatalog
  const res = await harness.callSuccess("get_v3_widget_metadata", { widgetName: "V3TestButton" });
  assert.equal(res.data.previewDelivery, undefined);
  assert.equal(res.data.previewDeliveryStatus, undefined);
  assert.equal(res.data.previewSlug, "button/V3TestButton");
});
