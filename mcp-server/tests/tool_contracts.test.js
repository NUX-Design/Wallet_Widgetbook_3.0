import assert from "node:assert/strict";
import test from "node:test";
import { toolDefinitions } from "../tool_contracts.js";
import { assertMatchesSnapshot } from "./helpers/snapshot.js";

const requiredWidgetTools = [
  "list_categories",
  "list_widgets",
  "search_widgets",
  "get_widget_metadata",
  "get_widget_code",
  "get_widget_preview",
];

const requiredV3Tools = [
  "get_v3_design_system_info", "list_v3_categories",
  "list_v3_color_tokens", "search_v3_color_tokens", "get_v3_color_token",
  "list_v3_widgets", "search_v3_widgets", "get_v3_widget_details", "get_v3_widget_metadata",
  "get_v3_widget_code", "get_v3_widget_preview", "audit_v3_widget",
  "get_v3_flutter_widget_template", "get_v3_codebase_patterns",
  "get_v3_figma_to_flutter_mapping", "generate_v3_widget_code",
  "generate_v3_widgetbook_use_case",
];

test("tool contracts expose the required MCP widget tools", () => {
  const names = toolDefinitions.map((tool) => tool.name);

  for (const toolName of requiredWidgetTools) {
    assert.ok(names.includes(toolName), `Required tool "${toolName}" is missing.`);
  }
});

test("V3 tool contracts are additive and all read-only", () => {
  const byName = new Map(toolDefinitions.map((tool) => [tool.name, tool]));
  for (const name of requiredV3Tools) {
    assert.equal(byName.get(name)?.annotations?.readOnlyHint, true, `V3 tool "${name}" must be read-only.`);
  }
});

test("tool contract snapshot stays stable until explicitly updated", () => {
  assertMatchesSnapshot("tool_definitions.contracts", toolDefinitions);
});
