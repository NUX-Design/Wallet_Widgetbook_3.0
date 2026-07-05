import assert from "node:assert/strict";
import test from "node:test";
import { createInMemoryLogger } from "../observability.js";
import { createToolHarness } from "./helpers/tool_harness.js";

test("structured logs include timing for tool calls and widget catalog searches", async () => {
  const { logger, entries } = createInMemoryLogger();
  const harness = createToolHarness(undefined, { logger });

  await harness.callSuccess("search_widgets", {
    query: "gift chip",
    limit: 5,
  });

  assert.ok(
    entries.some((entry) =>
      entry.event === "widget_catalog.search"
      && entry.level === "info"
      && entry.query === "gift chip"
      && typeof entry.durationMs === "number"
      && entry.resultCount >= 1),
  );
  assert.ok(
    entries.some((entry) =>
      entry.event === "tool.call.finish"
      && entry.tool === "search_widgets"
      && entry.ok === true
      && typeof entry.durationMs === "number"),
  );
});

test("structured logs record cache hits and predictable tool errors", async () => {
  const { logger, entries } = createInMemoryLogger();
  const harness = createToolHarness(undefined, { logger });

  await harness.callSuccess("list_widgets", { category: "button" });
  await harness.callSuccess("list_widgets", { category: "button" });
  await harness.callError("get_widget_metadata", { widgetName: "MissingWidget" });

  assert.ok(entries.some((entry) => entry.event === "widget_catalog.load" && entry.cache === "miss"));
  assert.ok(entries.some((entry) => entry.event === "widget_catalog.load" && entry.cache === "hit"));
  assert.ok(
    entries.some((entry) =>
      entry.event === "tool.call.error"
      && entry.tool === "get_widget_metadata"
      && entry.errorCode === "NOT_FOUND"
      && entry.level === "warn"),
  );
});
