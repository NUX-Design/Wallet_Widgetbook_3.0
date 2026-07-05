import assert from "node:assert/strict";
import test from "node:test";
import { WidgetCatalog } from "../widget_catalog.js";
import {
  buildPreviewIndex,
  collectAdjacentDocFiles,
  discoverCatalogFiles,
} from "../catalog/discovery.js";
import { resolveDocFiles } from "../catalog/doc_parser.js";
import { extractImportedRelativePaths } from "../catalog/dart_parser.js";
import { resolvePreviewFiles } from "../catalog/metadata.js";
import { fixtureProjectRoot } from "./helpers/fixture_repo.js";

test("discoverCatalogFiles separates widgets from previews and includes lib/previews", () => {
  const { widgetFiles, previewFiles } = discoverCatalogFiles(fixtureProjectRoot);

  assert.deepEqual(
    widgetFiles.map((file) => file.replace(`${fixtureProjectRoot}/`, "")).sort(),
    [
      "lib/widgets/badge/broken_badge.dart",
      "lib/widgets/banner/ghost_banner.dart",
      "lib/widgets/button/primary_button.dart",
      "lib/widgets/card/multi_doc_card.dart",
      "lib/widgets/chip/icon_chip.dart",
    ],
  );

  assert.deepEqual(
    previewFiles.map((file) => file.replace(`${fixtureProjectRoot}/`, "")).sort(),
    [
      "lib/previews/card_gallery_preview.dart",
      "lib/widgets/badge/preview_broken_badge.dart",
      "lib/widgets/button/preview_primary_button.dart",
      "lib/widgets/chip/icon_chip_preview.dart",
    ],
  );
});

test("resolveDocFiles chooses the widget-specific markdown when multiple docs exist", () => {
  const widgetFile = "lib/widgets/card/multi_doc_card.dart";
  const allDocFiles = collectAdjacentDocFiles(
    fixtureProjectRoot,
    `${fixtureProjectRoot}/lib/widgets/card/multi_doc_card.dart`,
  );

  const docFiles = resolveDocFiles(fixtureProjectRoot, allDocFiles, "MultiDocCard", widgetFile);

  assert.deepEqual(docFiles, ["lib/widgets/card/multi_doc_card_GUIDE.md"]);
});

test("resolvePreviewFiles matches both adjacent previews and shared previews by import path", () => {
  const { previewFiles } = discoverCatalogFiles(fixtureProjectRoot);
  const previewIndex = buildPreviewIndex(
    fixtureProjectRoot,
    previewFiles,
    extractImportedRelativePaths,
  );

  assert.deepEqual(
    resolvePreviewFiles(
      previewIndex,
      "PrimaryButton",
      "lib/widgets/button/primary_button.dart",
    ),
    ["lib/widgets/button/preview_primary_button.dart"],
  );

  assert.deepEqual(
    resolvePreviewFiles(
      previewIndex,
      "MultiDocCard",
      "lib/widgets/card/multi_doc_card.dart",
    ),
    ["lib/previews/card_gallery_preview.dart"],
  );

  assert.deepEqual(
    resolvePreviewFiles(previewIndex, "IconChip", "lib/widgets/chip/icon_chip.dart"),
    ["lib/widgets/chip/icon_chip_preview.dart"],
  );
});

test("WidgetCatalog extracts metadata and preserves fallback warnings", async () => {
  const catalog = new WidgetCatalog(fixtureProjectRoot);
  const widgets = await catalog.listWidgets();
  const primaryButton = widgets.find((widget) => widget.name === "PrimaryButton");
  const ghostBanner = widgets.find((widget) => widget.name === "GhostBanner");
  const brokenBadge = widgets.find((widget) => widget.name === "BrokenBadge");

  assert.ok(primaryButton);
  assert.deepEqual(primaryButton.previewFiles, ["lib/widgets/button/preview_primary_button.dart"]);
  assert.deepEqual(primaryButton.docFiles, ["lib/widgets/button/primary_button_GUIDE.md"]);
  assert.equal(primaryButton.metadataSources.props, "code+docs");
  assert.equal(primaryButton.metadataSources.updatedAt, "mtime");
  assert.deepEqual(primaryButton.dependencies, ["flutter_svg"]);
  assert.deepEqual(primaryButton.internalImports, ["lib/widgets/shared/badge.dart"]);
  assert.deepEqual(primaryButton.assets, ["lib/assets/icons/send.svg"]);
  assert.deepEqual(
    primaryButton.props.map((prop) => ({
      name: prop.name,
      required: prop.required,
      defaultValue: prop.defaultValue ?? null,
      source: prop.source,
    })),
    [
      { name: "isLoading", required: false, defaultValue: "false", source: "code" },
      { name: "label", required: true, defaultValue: "-", source: "code" },
      { name: "onPressed", required: false, defaultValue: "-", source: "code" },
    ],
  );
  assert.equal(primaryButton.metadataConfidence.overall, "high");
  assert.ok(
    primaryButton.warnings.some((warning) => warning.includes("fell back to filesystem mtime")),
  );

  assert.ok(ghostBanner);
  assert.equal(ghostBanner.metadataConfidence.overall, "low");
  assert.ok(ghostBanner.warnings.some((warning) => warning.includes("No preview file matched")));
  assert.ok(
    ghostBanner.warnings.some((warning) => warning.includes("No widget-local markdown docs")),
  );

  assert.ok(brokenBadge);
  assert.equal(brokenBadge.metadataSources.docs, "widget-local-markdown");
  assert.ok(
    brokenBadge.warnings.some((warning) => warning.includes("Docs are missing 2 code prop(s)")),
  );
});
