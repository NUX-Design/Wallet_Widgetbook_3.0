import fs from "fs";
import { ToolError } from "./tool_runtime.js";
import path from "path";
import {
  buildPreviewIndex,
  collectAdjacentDocFiles,
  discoverCatalogFiles,
} from "./catalog/discovery.js";
import {
  extractAssets,
  extractDependencies,
  extractImportedRelativePaths,
  extractInternalImports,
  extractWidgetClassNames,
  parsePropsFromCode,
  readLastUpdatedAt,
} from "./catalog/dart_parser.js";
import { buildMetadataSignals, buildTags, mergeProps, resolvePreviewFiles } from "./catalog/metadata.js";
import { parseDocs, resolveDocFiles } from "./catalog/doc_parser.js";
import { createStructuredLogger, measureDurationMs } from "./observability.js";
import { buildSearchIndex, scoreWidget } from "./catalog/search.js";
import { normalize, safeRead, toRelative } from "./catalog/shared.js";
const CACHE_TTL_MS = Number(process.env.WIDGET_LIBRARY_CACHE_TTL_MS ?? "2000");

export class WidgetCatalog {
  #repoRoot;
  #cache;
  #logger;

  constructor(repoRoot, options = {}) {
    this.#repoRoot = repoRoot;
    this.#cache = null;
    this.#logger = options.logger ?? createStructuredLogger();
  }

  async listCategories() {
    const startTime = performance.now();
    const data = await this.#load();
    const categories = [...new Set(data.widgets.map((widget) => widget.category))].sort();
    this.#logger.debug("widget_catalog.list_categories", {
      durationMs: measureDurationMs(startTime),
      count: categories.length,
    });
    return categories;
  }

  async listWidgets(category) {
    const startTime = performance.now();
    const data = await this.#load();
    const normalizedCategory = category?.trim().toLowerCase();
    const widgets = data.widgets.filter((widget) => {
      if (!normalizedCategory) return true;
      return widget.category.toLowerCase() === normalizedCategory;
    });
    this.#logger.debug("widget_catalog.list_widgets", {
      durationMs: measureDurationMs(startTime),
      category: category ?? null,
      resultCount: widgets.length,
    });
    return widgets;
  }

  async searchWidgets(query) {
    const startTime = performance.now();
    const data = await this.#load();
    const needle = normalize(query);
    const tokens = needle.split(/\s+/).filter(Boolean);

    const widgets = data.widgets
      .map((widget) => ({
        widget,
        score: scoreWidget(widget, needle, tokens),
      }))
      .filter((entry) => entry.score > 0)
      .sort((a, b) => b.score - a.score || a.widget.name.localeCompare(b.widget.name))
      .map((entry) => entry.widget);
    this.#logger.info("widget_catalog.search", {
      durationMs: measureDurationMs(startTime),
      query,
      resultCount: widgets.length,
    });
    return widgets;
  }

  async getWidget(name) {
    const startTime = performance.now();
    const data = await this.#load();
    const normalized = normalize(name);
    const widget =
      data.widgets.find((entry) => entry.normalizedName === normalized) ??
      data.widgets.find((entry) => normalize(entry.name) === normalized);

    if (!widget) {
      this.#logger.debug("widget_catalog.get_widget", {
        durationMs: measureDurationMs(startTime),
        widgetName: name,
        found: false,
      });
      throw new ToolError("NOT_FOUND", `Widget "${name}" was not found.`, {
        hint: 'Use "list_widgets" to browse categories or "search_widgets" to find similar widget names first.',
        details: { widgetName: name },
      });
    }

    this.#logger.debug("widget_catalog.get_widget", {
      durationMs: measureDurationMs(startTime),
      widgetName: name,
      found: true,
      category: widget.category,
    });
    return widget;
  }

  readRelativeFile(relativePath) {
    const absolutePath = path.join(this.#repoRoot, relativePath);
    if (!fs.existsSync(absolutePath)) {
      throw new ToolError("MISSING_RESOURCE", `File "${relativePath}" was not found in the repository.`, {
        hint: "Refresh the widget catalog or verify that the file still exists on disk.",
        details: { path: relativePath },
      });
    }

    try {
      return fs.readFileSync(absolutePath, "utf8");
    } catch (error) {
      throw new ToolError(
        "INTERNAL_ERROR",
        `Failed to read "${relativePath}".`,
        {
          hint: "Retry the call after checking filesystem permissions for the repository.",
          details: { path: relativePath, cause: error.message },
        },
      );
    }
  }

  async getCatalogState() {
    const data = await this.#load();
    return {
      repoRoot: this.#repoRoot,
      generatedAt: data.generatedAt,
      widgetCount: data.widgets.length,
      categoryCount: [...new Set(data.widgets.map((widget) => widget.category))].length,
    };
  }

  async #load() {
    const startTime = performance.now();
    const now = Date.now();
    if (this.#cache && now < this.#cache.expiresAt) {
      this.#logger.debug("widget_catalog.load", {
        durationMs: measureDurationMs(startTime),
        cache: "hit",
        ttlMsRemaining: this.#cache.expiresAt - now,
        widgetCount: this.#cache.data.widgets.length,
      });
      return this.#cache.data;
    }

    const data = buildCatalog(this.#repoRoot);
    this.#cache = {
      data,
      expiresAt: now + CACHE_TTL_MS,
    };
    this.#logger.info("widget_catalog.load", {
      durationMs: measureDurationMs(startTime),
      cache: "miss",
      widgetCount: data.widgets.length,
      categoryCount: [...new Set(data.widgets.map((widget) => widget.category))].length,
      generatedAt: data.generatedAt,
      cacheTtlMs: CACHE_TTL_MS,
    });
    return data;
  }
}

function buildCatalog(repoRoot) {
  const { widgetFiles, previewFiles } = discoverCatalogFiles(repoRoot);
  const previewIndex = buildPreviewIndex(repoRoot, previewFiles, extractImportedRelativePaths);
  const widgets = [];

  for (const absoluteFile of widgetFiles) {
    const content = safeRead(absoluteFile);
    if (!content) continue;

    const widgetNames = extractWidgetClassNames(content);
    if (widgetNames.length === 0) continue;

    const relativeFile = toRelative(repoRoot, absoluteFile);
    const category = path.basename(path.dirname(absoluteFile));
    const allDocFiles = collectAdjacentDocFiles(repoRoot, absoluteFile);

    const internalImports = extractInternalImports(content);
    const updatedAtMetadata = readLastUpdatedAt(repoRoot, relativeFile, absoluteFile);

    for (const widgetName of widgetNames) {
      const parsedProps = parsePropsFromCode(content, widgetName);
      const docFiles = resolveDocFiles(repoRoot, allDocFiles, widgetName, relativeFile);
      const docMetadata = parseDocs(repoRoot, docFiles);
      const mergedProps = mergeProps(parsedProps, docMetadata.props);
      const dependencies = extractDependencies(content, docMetadata.dependencies);
      const assets = extractAssets(content, docMetadata.assets);
      const tags = buildTags(widgetName, category, docMetadata.tags);
      const relatedPreviews = resolvePreviewFiles(previewIndex, widgetName, relativeFile);
      const metadataSignals = buildMetadataSignals({
        widgetName,
        widgetFile: relativeFile,
        codeProps: parsedProps,
        docProps: docMetadata.props,
        docFiles,
        previewFiles: relatedPreviews,
        dependencies,
        figmaLinks: docMetadata.figmaLinks,
        updatedAtSource: updatedAtMetadata.source,
      });

      const widget = {
        name: widgetName,
        normalizedName: normalize(widgetName),
        category,
        widgetFile: relativeFile,
        previewFiles: relatedPreviews,
        docFiles,
        props: mergedProps,
        dependencies,
        internalImports,
        assets,
        tags,
        figmaLinks: docMetadata.figmaLinks,
        updatedAt: updatedAtMetadata.value,
        metadataSources: metadataSignals.metadataSources,
        metadataConfidence: metadataSignals.metadataConfidence,
        warnings: metadataSignals.warnings,
        sourceText: content,
      };

      widget.searchIndex = {
        ...buildSearchIndex(widget, docMetadata),
      };

      widgets.push(widget);
    }
  }

  widgets.sort((a, b) => {
    const categoryCompare = a.category.localeCompare(b.category);
    return categoryCompare !== 0 ? categoryCompare : a.name.localeCompare(b.name);
  });

  return {
    repoRoot,
    generatedAt: new Date().toISOString(),
    widgets,
  };
}
