import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { V3WidgetCatalog } from "../../v3/widget_catalog.js";

const fixtureRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../fixtures/v3_repo");

test("V3 widget catalog indexes only V3 source, previews, docs, and token metadata", () => {
  const catalog = new V3WidgetCatalog(fixtureRoot);
  assert.deepEqual(catalog.list().map((widget) => widget.name), ["V3Broken", "V3TestButton"]);
  const widget = catalog.get("V3TestButton");
  assert.equal(widget.themeVersion, "v3");
  assert.deepEqual(widget.semanticTokens, ["content/primary"]);
  assert.deepEqual(widget.previewFiles, ["lib/widgets/v3/button/preview_v3_test_button.dart"]);
  assert.ok(!catalog.list().some((entry) => entry.widgetFile.includes("legacy")));
});

test("V3 audit passes compliant widgets and finds legacy imports/raw colors", () => {
  const catalog = new V3WidgetCatalog(fixtureRoot);
  assert.equal(catalog.audit(catalog.get("V3TestButton")).passed, true);
  const audit = catalog.audit(catalog.get("V3Broken"));
  assert.equal(audit.passed, false);
  assert.deepEqual(audit.findings.filter((item) => item.severity === "error").map((item) => item.code), ["MISSING_THEME_VERSION", "LEGACY_THEME_IMPORT", "RAW_COLOR", "MISSING_V3_THEME_SCOPE"]);
});
