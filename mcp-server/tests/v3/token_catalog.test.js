import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { V3TokenCatalog } from "../../v3/token_catalog.js";

const fixtureRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../fixtures/v3_repo");

test("V3 token catalog resolves Light/Dark aliases and Dart usage", () => {
  const catalog = new V3TokenCatalog(fixtureRoot);
  assert.deepEqual(catalog.get("content/primary"), {
    themeVersion: "v3", tokenName: "content/primary", dartProperty: "contentPrimary",
    lightValue: "#0F172A", darkValue: "#FFFFFF", lightPrimitiveAlias: "slate/900",
    darkPrimitiveAlias: "white", lightAlpha: 1, darkAlpha: 1,
    dartUsage: "V3ThemeScope.colorsOf(context).contentPrimary",
  });
  assert.equal(catalog.search("slate")[0].tokenName, "content/primary");
});

test("missing V3 token returns actionable suggestions", () => {
  const catalog = new V3TokenCatalog(fixtureRoot);
  assert.throws(() => catalog.get("content/missing"), (error) => {
    assert.equal(error.code, "NOT_FOUND");
    assert.match(error.hint, /list_v3_color_tokens|Try one/);
    return true;
  });
});
