import assert from "node:assert/strict";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { createToolHarness } from "../helpers/tool_harness.js";

const fixtureRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../fixtures/v3_repo");

test("all V3 token and widget tools are routed through the existing dispatcher", async () => {
  const harness = createToolHarness(fixtureRoot);
  const tokens = await harness.callSuccess("list_v3_color_tokens");
  assert.equal(tokens.data.total, 1);
  const searchTokens = await harness.callSuccess("search_v3_color_tokens", { query: "slate" });
  assert.equal(searchTokens.data.tokens[0].tokenName, "content/primary");
  const token = await harness.callSuccess("get_v3_color_token", { tokenName: "content/primary" });
  assert.equal(token.data.darkValue, "#FFFFFF");

  const widgets = await harness.callSuccess("list_v3_widgets", { category: "button" });
  assert.equal(widgets.data.widgets[0].name, "V3TestButton");
  const search = await harness.callSuccess("search_v3_widgets", { query: "content primary" });
  assert.equal(search.data.widgets[0].name, "V3TestButton");
  const metadata = await harness.callSuccess("get_v3_widget_metadata", { widgetName: "V3TestButton" });
  assert.equal(metadata.data.themeVersion, "v3");
  const code = await harness.callSuccess("get_v3_widget_code", { widgetName: "V3TestButton" });
  assert.match(code.data.code, /class V3TestButton/);
  const preview = await harness.callSuccess("get_v3_widget_preview", { widgetName: "V3TestButton" });
  assert.match(preview.data.previews[0].file, /preview_v3_test_button/);
  const audit = await harness.callSuccess("audit_v3_widget", { widgetName: "V3Broken" });
  assert.equal(audit.data.passed, false);
});

test("V3 parity tools enforce V3 paths, names, and theme APIs", async () => {
  const harness = createToolHarness(fixtureRoot);
  const info = await harness.callSuccess("get_v3_design_system_info", { section: "designTokens" });
  assert.equal(info.data.data.runtimeAccessor, "V3ThemeScope.colorsOf(context)");
  const categories = await harness.callSuccess("list_v3_categories");
  assert.deepEqual(categories.data.categories, ["broken", "button"]);
  const details = await harness.callSuccess("get_v3_widget_details", { widgetName: "V3TestButton" });
  assert.equal(details.data.widgetFile, "lib/widgets/v3/button/v3_test_button.dart");
  const template = await harness.callSuccess("get_v3_flutter_widget_template", { widgetType: "stateless", widgetName: "V3Banner", category: "banner" });
  assert.equal(template.data.filePath, "lib/widgets/v3/banner/v3_banner.dart");
  assert.match(template.data.code, /V3ThemeScope\.colorsOf\(context\)/);
  assert.doesNotMatch(template.data.code, /ThemeColors/);
  const badName = await harness.callError("get_v3_flutter_widget_template", { widgetType: "stateless", widgetName: "Banner", category: "banner" });
  assert.equal(badName.error.error.code, "INVALID_ARGUMENT");
  const patterns = await harness.callSuccess("get_v3_codebase_patterns", { pattern: "all" });
  assert.match(patterns.data.data.theme.join(" "), /never silently fall back/);
  const mapping = await harness.callSuccess("get_v3_figma_to_flutter_mapping", { figmaComponentName: "Test Button" });
  assert.equal(mapping.data.flutterClass, "V3TestButton");
  const generated = await harness.callSuccess("generate_v3_widget_code", { componentName: "V3Banner", category: "banner", figmaDescription: "Banner", widgetType: "stateless", semanticTokens: ["content/primary"] });
  assert.equal(generated.data.semanticTokens[0], "content/primary");
  assert.match(generated.data.note, /does not write files/);
  const useCase = await harness.callSuccess("generate_v3_widgetbook_use_case", { widgetName: "V3TestButton", importPath: "package:mcp_test_app/widgets/v3/button/v3_test_button.dart", category: "button" });
  assert.equal(useCase.data.fileToCreate, "lib/widgets/v3/button/preview_v3_test_button.dart");
  const legacyImport = await harness.callError("generate_v3_widgetbook_use_case", { widgetName: "V3TestButton", importPath: "package:mcp_test_app/widgets/button/buttons.dart", category: "button" });
  assert.equal(legacyImport.error.error.code, "INVALID_ARGUMENT");
});
