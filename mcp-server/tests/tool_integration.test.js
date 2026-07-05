import assert from "node:assert/strict";
import test from "node:test";
import { createToolHarness } from "./helpers/tool_harness.js";

test("required widget tools return the expected integration payloads", async () => {
  const harness = createToolHarness();

  const categories = await harness.callSuccess("list_categories");
  assert.deepEqual(categories.data.categories, ["badge", "banner", "button", "card", "chip"]);

  const widgetPage = await harness.callSuccess("list_widgets", {
    category: "button",
    limit: 1,
    offset: 0,
  });
  assert.deepEqual(widgetPage.data, {
    category: "button",
    total: 1,
    count: 1,
    limit: 1,
    offset: 0,
    hasMore: false,
    widgets: [
      {
        name: "PrimaryButton",
        category: "button",
        widgetFile: "lib/widgets/button/primary_button.dart",
        previewFiles: ["lib/widgets/button/preview_primary_button.dart"],
        tags: ["button", "dependencies", "primary", "usage"],
        updatedAt: widgetPage.data.widgets[0].updatedAt,
      },
    ],
  });

  const searchResult = await harness.callSuccess("search_widgets", {
    query: "gift chip",
    limit: 5,
  });
  assert.equal(searchResult.data.widgets[0].name, "IconChip");

  const metadata = await harness.callSuccess("get_widget_metadata", {
    widgetName: "PrimaryButton",
  });
  assert.equal(metadata.data.widgetFile, "lib/widgets/button/primary_button.dart");
  assert.equal(metadata.data.metadataConfidence.overall, "high");

  const code = await harness.callSuccess("get_widget_code", {
    widgetName: "PrimaryButton",
  });
  assert.equal(code.data.widgetName, "PrimaryButton");
  assert.match(code.data.code, /class PrimaryButton extends StatelessWidget/);

  const preview = await harness.callSuccess("get_widget_preview", {
    widgetName: "PrimaryButton",
  });
  assert.equal(preview.data.previews[0].file, "lib/widgets/button/preview_primary_button.dart");
});

test("critical error and edge-case paths stay predictable", async () => {
  const harness = createToolHarness();

  const missingWidget = await harness.callError("get_widget_metadata", {
    widgetName: "MissingWidget",
  });
  assert.deepEqual(missingWidget.error.error, {
    code: "NOT_FOUND",
    message: 'Widget "MissingWidget" was not found.',
    hint: 'Use "list_widgets" to browse categories or "search_widgets" to find similar widget names first.',
    details: { widgetName: "MissingWidget" },
  });

  const emptyPreview = await harness.callError("get_widget_preview", {
    widgetName: "GhostBanner",
  });
  assert.equal(emptyPreview.error.error.code, "EMPTY_RESULT");

  const invalidArgument = await harness.callError("list_widgets", {
    limit: 0,
  });
  assert.equal(invalidArgument.error.error.code, "INVALID_ARGUMENT");
  assert.match(invalidArgument.error.error.message, /Field "limit" must be in range 1 to 200/);

  const malformedDocs = await harness.callSuccess("get_widget_metadata", {
    widgetName: "BrokenBadge",
  });
  assert.equal(malformedDocs.data.metadataSources.props, "code");
  assert.ok(
    malformedDocs.data.warnings.some((warning) =>
      warning.includes("Docs are missing 2 code prop(s): color, text."),
    ),
  );

  const emptyCategory = await harness.callSuccess("list_widgets", {
    category: "missing-category",
    limit: 10,
    offset: 0,
  });
  assert.deepEqual(emptyCategory.data, {
    category: "missing-category",
    total: 0,
    count: 0,
    limit: 10,
    offset: 0,
    hasMore: false,
    widgets: [],
  });
});
