import fs from "fs";
import path from "path";
import { hasMainEntrypoint, normalize, safeRead, toRelative } from "./shared.js";

const WIDGETS_ROOT = ["lib", "widgets"];
const PREVIEWS_ROOT = ["lib", "previews"];

export function discoverCatalogFiles(repoRoot) {
  const widgetsDir = path.join(repoRoot, ...WIDGETS_ROOT);
  const previewDir = path.join(repoRoot, ...PREVIEWS_ROOT);
  const widgetDirectoryFiles = walkFiles(widgetsDir).filter((file) => file.endsWith(".dart"));

  const classifiedWidgetFiles = widgetDirectoryFiles.map((absoluteFile) => {
    const content = safeRead(absoluteFile) ?? "";
    return {
      absoluteFile,
      content,
      kind: classifyWidgetDirectoryFile(absoluteFile, content),
    };
  });

  const previewFiles = [
    ...classifiedWidgetFiles
      .filter((entry) => entry.kind === "preview")
      .map((entry) => entry.absoluteFile),
    ...walkFiles(previewDir).filter(isPreviewFile),
  ];

  return {
    widgetFiles: classifiedWidgetFiles
      .filter((entry) => entry.kind === "widget")
      .map((entry) => entry.absoluteFile),
    previewFiles: [...new Set(previewFiles)].sort(),
  };
}

export function buildPreviewIndex(repoRoot, previewFiles, extractImportedRelativePaths) {
  return previewFiles.map((absoluteFile) => {
    const content = safeRead(absoluteFile) ?? "";
    const relativeFile = toRelative(repoRoot, absoluteFile);
    const directory = path.posix.dirname(relativeFile);

    return {
      file: relativeFile,
      directory,
      baseName: path.posix.basename(relativeFile, ".dart").toLowerCase(),
      normalizedContent: normalize(content),
      imports: extractImportedRelativePaths(content),
    };
  });
}

export function collectAdjacentDocFiles(repoRoot, absoluteFile) {
  return walkFiles(path.dirname(absoluteFile))
    .filter((file) => file.endsWith(".md"))
    .map((file) => toRelative(repoRoot, file))
    .sort();
}

function classifyWidgetDirectoryFile(absoluteFile, content) {
  const base = path.basename(absoluteFile).toLowerCase();

  if (!containsWidgetClass(content)) {
    return "support";
  }

  if (isPreviewFileName(base) || isExampleFileName(base)) {
    return "preview";
  }

  if (hasMainEntrypoint(content) && looksLikePreviewEntrypoint(content)) {
    return "preview";
  }

  return "widget";
}

function containsWidgetClass(content) {
  return /class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+(?:StatefulWidget|StatelessWidget)\b/g.test(
    content,
  );
}

function looksLikePreviewEntrypoint(content) {
  return (
    /runApp\s*\(/.test(content) ||
    /MaterialApp\s*\(/.test(content) ||
    /Widgetbook/.test(content)
  );
}

function isExampleFileName(base) {
  return base.startsWith("example_") || base.includes("example");
}

function isPreviewFileName(base) {
  return (
    base.startsWith("preview_") ||
    base.endsWith("_preview.dart") ||
    base.includes("preview")
  );
}

function isPreviewFile(file) {
  return isPreviewFileName(path.basename(file).toLowerCase());
}

function walkFiles(root) {
  if (!fs.existsSync(root)) return [];

  const results = [];
  const entries = fs.readdirSync(root, { withFileTypes: true });

  for (const entry of entries) {
    const fullPath = path.join(root, entry.name);
    if (entry.isDirectory()) {
      results.push(...walkFiles(fullPath));
      continue;
    }
    results.push(fullPath);
  }

  return results;
}
