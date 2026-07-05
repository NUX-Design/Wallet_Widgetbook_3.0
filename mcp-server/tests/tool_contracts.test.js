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

test("tool contracts expose the required MCP widget tools", () => {
  const names = toolDefinitions.map((tool) => tool.name);

  for (const toolName of requiredWidgetTools) {
    assert.ok(names.includes(toolName), `Required tool "${toolName}" is missing.`);
  }
});

test("tool contract snapshot stays stable until explicitly updated", () => {
  assertMatchesSnapshot("tool_definitions.contracts", toolDefinitions);
});
