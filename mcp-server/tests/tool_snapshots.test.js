import test from "node:test";
import { createToolHarness } from "./helpers/tool_harness.js";
import { assertMatchesSnapshot } from "./helpers/snapshot.js";

test("success payload snapshots stay stable for core widget tools", async () => {
  const harness = createToolHarness();

  const categories = await harness.callSuccess("list_categories");
  assertMatchesSnapshot("list_categories.success", categories.data);

  const widgets = await harness.callSuccess("list_widgets", {
    category: "button",
    limit: 5,
    offset: 0,
  });
  assertMatchesSnapshot("list_widgets.success", widgets.data);

  const search = await harness.callSuccess("search_widgets", {
    query: "primary button",
    limit: 5,
    offset: 0,
  });
  assertMatchesSnapshot("search_widgets.success", search.data);

  const metadata = await harness.callSuccess("get_widget_metadata", {
    widgetName: "PrimaryButton",
  });
  assertMatchesSnapshot("get_widget_metadata.success", metadata.data);

  const code = await harness.callSuccess("get_widget_code", {
    widgetName: "PrimaryButton",
  });
  assertMatchesSnapshot("get_widget_code.success", code.data);

  const preview = await harness.callSuccess("get_widget_preview", {
    widgetName: "PrimaryButton",
  });
  assertMatchesSnapshot("get_widget_preview.success", preview.data);
});

test("error payload snapshots stay stable for contract-critical failures", async () => {
  const harness = createToolHarness();

  const missingWidget = await harness.callError("get_widget_metadata", {
    widgetName: "MissingWidget",
  });
  assertMatchesSnapshot("get_widget_metadata.not_found", {
    isError: missingWidget.response.isError,
    payload: missingWidget.error,
  });

  const emptyPreview = await harness.callError("get_widget_preview", {
    widgetName: "GhostBanner",
  });
  assertMatchesSnapshot("get_widget_preview.empty_result", {
    isError: emptyPreview.response.isError,
    payload: emptyPreview.error,
  });

  const invalidArgument = await harness.callError("list_widgets", {
    limit: 0,
  });
  assertMatchesSnapshot("list_widgets.invalid_argument", {
    isError: invalidArgument.response.isError,
    payload: invalidArgument.error,
  });
});
