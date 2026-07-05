import path from "path";
import { normalize, splitCamelCase } from "./shared.js";

export function mergeProps(codeProps, docProps) {
  const merged = new Map();

  for (const prop of codeProps) {
    merged.set(prop.name, { ...prop });
  }

  for (const prop of docProps) {
    const existing = merged.get(prop.name);
    if (!existing) {
      merged.set(prop.name, prop);
      continue;
    }

    merged.set(prop.name, {
      ...existing,
      required: prop.required || existing.required,
      defaultValue: existing.defaultValue ?? prop.defaultValue,
      description: prop.description ?? existing.description,
    });
  }

  return [...merged.values()].sort((a, b) => a.name.localeCompare(b.name));
}

export function buildTags(widgetName, category, docTags) {
  const tags = new Set(docTags);
  tags.add(category.toLowerCase());

  for (const token of splitCamelCase(widgetName)) {
    tags.add(token.toLowerCase());
  }

  return [...tags].sort();
}

export function resolvePreviewFiles(previewIndex, widgetName, widgetFile) {
  const widgetBase = path.posix.basename(widgetFile, ".dart");
  const widgetDir = path.posix.dirname(widgetFile);
  const widgetNeedle = normalize(widgetName);

  return previewIndex
    .map((preview) => ({
      file: preview.file,
      score: scorePreviewMatch(preview, widgetName, widgetNeedle, widgetFile, widgetBase, widgetDir),
    }))
    .filter((entry) => entry.score > 0)
    .sort((a, b) => b.score - a.score || a.file.localeCompare(b.file))
    .map((entry) => entry.file)
    .filter((file, index, files) => files.indexOf(file) === index);
}

export function buildMetadataSignals({
  widgetName,
  widgetFile,
  codeProps,
  docProps,
  docFiles,
  previewFiles,
  dependencies,
  figmaLinks,
  updatedAtSource,
}) {
  const warnings = [];
  const codePropNames = new Set(codeProps.map((prop) => prop.name));
  const docPropNames = new Set(docProps.map((prop) => prop.name));
  const undocumentedProps = [...codePropNames].filter((name) => !docPropNames.has(name));
  const staleDocProps = [...docPropNames].filter((name) => !codePropNames.has(name));

  if (previewFiles.length === 0) {
    warnings.push(`No preview file matched for ${widgetName}.`);
  }

  if (docFiles.length === 0) {
    warnings.push(`No widget-local markdown docs were matched for ${widgetName}.`);
  }

  if (undocumentedProps.length > 0) {
    warnings.push(
      `Docs are missing ${undocumentedProps.length} code prop(s): ${undocumentedProps.join(", ")}.`,
    );
  }

  if (staleDocProps.length > 0) {
    warnings.push(
      `Docs mention ${staleDocProps.length} prop(s) not found in code: ${staleDocProps.join(", ")}.`,
    );
  }

  if (updatedAtSource === "mtime") {
    warnings.push(
      `updatedAt for ${widgetFile} fell back to filesystem mtime because git history was unavailable.`,
    );
  }

  return {
    metadataSources: {
      props: docProps.length > 0 ? "code+docs" : "code",
      dependencies: dependencies.length > 0 ? "code+docs" : "code",
      previews: previewFiles.length > 0 ? "adjacent-preview-index" : "unmatched",
      docs: docFiles.length > 0 ? "widget-local-markdown" : "none",
      figmaLinks: figmaLinks.length > 0 ? "docs" : "none",
      updatedAt: updatedAtSource,
    },
    metadataConfidence: {
      props: confidenceFromCounts(codeProps.length, docProps.length),
      previews: previewFiles.length > 0 ? "high" : "low",
      docs: docFiles.length > 0 ? "high" : "low",
      figmaLinks: figmaLinks.length > 0 ? "high" : "low",
      overall: overallConfidence({ docFiles, previewFiles, undocumentedProps, staleDocProps }),
    },
    warnings,
  };
}

function scorePreviewMatch(preview, widgetName, widgetNeedle, widgetFile, widgetBase, widgetDir) {
  let score = 0;

  if (preview.imports.includes(widgetFile)) {
    score += 220;
  }

  if (
    preview.baseName === `preview_${widgetBase}` ||
    preview.baseName === `${widgetBase}_preview`
  ) {
    score += 180;
  }

  if (preview.baseName.includes(widgetBase)) {
    score += 60;
  }

  if (preview.directory === widgetDir && preview.normalizedContent.includes(widgetNeedle)) {
    score += 100;
  }

  return score;
}

function confidenceFromCounts(codeCount, docCount) {
  if (codeCount > 0 && docCount > 0) return "high";
  if (codeCount > 0 || docCount > 0) return "medium";
  return "low";
}

function overallConfidence({ docFiles, previewFiles, undocumentedProps, staleDocProps }) {
  if (previewFiles.length > 0 && docFiles.length > 0 && undocumentedProps.length === 0 && staleDocProps.length === 0) {
    return "high";
  }
  if (previewFiles.length > 0 || docFiles.length > 0) {
    return "medium";
  }
  return "low";
}
