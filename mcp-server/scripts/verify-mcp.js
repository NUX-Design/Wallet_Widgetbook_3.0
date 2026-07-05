#!/usr/bin/env node

import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");
const inspectorCliPath = path.join(
  serverRoot,
  "node_modules",
  "@modelcontextprotocol",
  "inspector-cli",
  "build",
  "index.js",
);

function formatArgs(toolArgs) {
  return Object.entries(toolArgs).flatMap(([key, value]) => ["--tool-arg", `${key}=${value}`]);
}

function runInspector({ method, toolName, toolArgs = {} }) {
  const args = [inspectorCliPath, "node", "index.js", "--method", method];
  if (toolName) {
    args.push("--tool-name", toolName);
  }
  args.push(...formatArgs(toolArgs));

  const result = spawnSync("node", args, {
    cwd: serverRoot,
    encoding: "utf8",
  });

  if (result.status !== 0) {
    throw new Error(
      [
        `Inspector command failed for ${method}${toolName ? `:${toolName}` : ""}.`,
        result.stderr?.trim(),
        result.stdout?.trim(),
      ]
        .filter(Boolean)
        .join("\n"),
    );
  }

  try {
    return JSON.parse(result.stdout);
  } catch (error) {
    throw new Error(
      `Inspector output was not valid JSON for ${method}${toolName ? `:${toolName}` : ""}: ${error.message}`,
    );
  }
}

function readToolData(response) {
  if (response.structuredContent) {
    return response.structuredContent;
  }

  const text = response.content?.[0]?.text;
  if (!text) {
    throw new Error("Tool response did not include structuredContent or text content.");
  }

  return JSON.parse(text);
}

function reportPass(label, details) {
  console.log(`PASS ${label}${details ? ` - ${details}` : ""}`);
}

function verifyToolsList() {
  const payload = runInspector({ method: "tools/list" });
  const toolNames = payload.tools.map((tool) => tool.name);
  const requiredTools = [
    "list_widgets",
    "search_widgets",
    "get_widget_metadata",
    "get_widget_code",
    "get_widget_preview",
  ];

  for (const toolName of requiredTools) {
    assert.ok(toolNames.includes(toolName), `Required tool "${toolName}" is missing from tools/list.`);
  }

  reportPass("tools/list", `${requiredTools.length} required tools exposed`);
}

function verifyListWidgets() {
  const payload = readToolData(
    runInspector({
      method: "tools/call",
      toolName: "list_widgets",
      toolArgs: { category: "input", limit: 2, offset: 0 },
    }),
  );

  assert.equal(payload.category, "input");
  assert.equal(payload.limit, 2);
  assert.ok(payload.count > 0, "list_widgets returned no widgets.");
  assert.ok(Array.isArray(payload.widgets), "list_widgets.widgets must be an array.");
  assert.ok(
    payload.widgets.some((widget) => widget.name === "FullAmountInput"),
    'Expected "FullAmountInput" in list_widgets(category=input).',
  );

  reportPass("list_widgets", `returned ${payload.count}/${payload.total} widgets for category=input`);
}

function verifySearchWidgets() {
  const payload = readToolData(
    runInspector({
      method: "tools/call",
      toolName: "search_widgets",
      toolArgs: { query: "cancel-circle", limit: 5, offset: 0 },
    }),
  );

  assert.equal(payload.query, "cancel-circle");
  assert.ok(payload.count > 0, "search_widgets returned no matches.");
  assert.ok(
    payload.widgets.some((widget) => widget.name === "FullAmountInput"),
    'Expected "FullAmountInput" in search_widgets(query=cancel-circle).',
  );

  reportPass("search_widgets", `returned ${payload.count}/${payload.total} matches for cancel-circle`);
}

function verifyWidgetMetadata() {
  const payload = readToolData(
    runInspector({
      method: "tools/call",
      toolName: "get_widget_metadata",
      toolArgs: { widgetName: "FullAmountInput" },
    }),
  );

  assert.equal(payload.name, "FullAmountInput");
  assert.equal(payload.category, "input");
  assert.ok(
    payload.assets.includes("lib/assets/images/cancel-circle.svg"),
    'Expected cancel-circle asset in "FullAmountInput" metadata.',
  );
  assert.ok(payload.metadataSources.updatedAt, "metadataSources.updatedAt should be present.");

  reportPass("get_widget_metadata", `category=${payload.category}, assets=${payload.assets.length}`);
}

function verifyWidgetCode() {
  const payload = readToolData(
    runInspector({
      method: "tools/call",
      toolName: "get_widget_code",
      toolArgs: { widgetName: "SearchInput" },
    }),
  );

  assert.equal(payload.widgetName, "SearchInput");
  assert.equal(payload.widgetFile, "lib/widgets/input/search_input.dart");
  assert.match(payload.code, /class SearchInput extends StatefulWidget/);

  reportPass("get_widget_code", payload.widgetFile);
}

function verifyWidgetPreview() {
  const payload = readToolData(
    runInspector({
      method: "tools/call",
      toolName: "get_widget_preview",
      toolArgs: { widgetName: "Avatar" },
    }),
  );

  assert.equal(payload.widgetName, "Avatar");
  assert.ok(Array.isArray(payload.previews) && payload.previews.length > 0);
  assert.ok(
    payload.previews.some((preview) => preview.file === "lib/widgets/avatar/preview_avatar.dart"),
    'Expected "lib/widgets/avatar/preview_avatar.dart" in Avatar previews.',
  );

  reportPass("get_widget_preview", `${payload.previews.length} preview file(s) returned`);
}

function main() {
  console.log("Running MCP Inspector verification against local stdio server...");
  verifyToolsList();
  verifyListWidgets();
  verifySearchWidgets();
  verifyWidgetMetadata();
  verifyWidgetCode();
  verifyWidgetPreview();
  console.log("MCP Inspector verification passed.");
}

try {
  main();
} catch (error) {
  console.error("MCP Inspector verification failed.");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
