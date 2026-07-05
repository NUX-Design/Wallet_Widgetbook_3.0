import path from "path";
import { normalize, safeRead, stripCode } from "./shared.js";

export function resolveDocFiles(repoRoot, allDocFiles, widgetName, widgetFile) {
  if (allDocFiles.length <= 1) return allDocFiles;

  const widgetFileBase = path.basename(widgetFile, ".dart").toLowerCase();
  const widgetBase = normalize(widgetFileBase);
  const widgetNeedle = normalize(widgetName);

  const fileNameMatches = allDocFiles.filter((relativeFile) => {
    const rawBase = path.basename(relativeFile, path.extname(relativeFile)).toLowerCase();
    if (
      rawBase === widgetFileBase ||
      rawBase.startsWith(`${widgetFileBase}_`) ||
      rawBase.endsWith(`_${widgetFileBase}`)
    ) {
      return true;
    }
    return normalize(stripDocSuffixes(rawBase)) === widgetBase;
  });

  if (fileNameMatches.length > 0) {
    return fileNameMatches.sort();
  }

  return allDocFiles
    .filter((relativeFile) => {
      const raw = safeRead(path.join(repoRoot, relativeFile)) ?? "";
      const firstHeading = raw.match(/^#\s+(.+)$/m)?.[1] ?? "";
      if (normalize(firstHeading).includes(widgetNeedle)) {
        return true;
      }

      const normalizedContent = normalize(raw);
      if (!normalizedContent.includes(widgetNeedle)) {
        return false;
      }

      const occurrences = normalizedContent.split(widgetNeedle).length - 1;
      return occurrences >= 2 || normalizedContent.includes(`${widgetNeedle} widget`);
    })
    .sort();
}

export function parseDocs(repoRoot, docFiles) {
  const props = new Map();
  const dependencies = new Set();
  const assets = new Set();
  const figmaLinks = new Set();
  const tags = new Set();
  const headings = new Set();
  const textChunks = [];

  for (const relativeFile of docFiles) {
    const content = safeRead(path.join(repoRoot, relativeFile)) ?? "";
    textChunks.push(content);

    for (const link of content.match(/https:\/\/www\.figma\.com\/[^\s)]+/g) ?? []) {
      figmaLinks.add(link);
    }

    for (const asset of content.match(/(?:lib\/)?assets\/[^\s`'")]+/g) ?? []) {
      assets.add(asset.startsWith("lib/") ? asset : `lib/${asset}`);
    }

    for (const dep of content.match(/([a-z0-9_]+):\s*\^[0-9][^\s]*/gi) ?? []) {
      const name = dep.split(":")[0]?.trim();
      if (name && name !== "flutter") {
        dependencies.add(name);
      }
    }

    const headingPattern = /^##+\s+(.+)$/gm;
    for (const heading of content.matchAll(headingPattern)) {
      const title = heading[1].trim();
      headings.add(title);
      tags.add(title.toLowerCase());
    }

    for (const prop of extractPropTable(content)) {
      props.set(prop.name, prop);
    }
  }

  return {
    props: [...props.values()].sort((a, b) => a.name.localeCompare(b.name)),
    dependencies: [...dependencies].sort(),
    assets: [...assets].sort(),
    figmaLinks: [...figmaLinks].sort(),
    tags: [...tags].sort(),
    headings: [...headings].sort(),
    searchText: textChunks.join(" "),
  };
}

function stripDocSuffixes(value) {
  return value.replace(/_(guide|spec|context|review|usage)$/i, "");
}

function extractPropTable(content) {
  const lines = content.split(/\r?\n/);
  const props = [];
  let dataStart = -1;

  for (let i = 0; i < lines.length; i += 1) {
    const line = lines[i];
    if (!line.trim().startsWith("|")) continue;
    if (line.includes("---")) continue;

    const cells = line
      .split("|")
      .map((cell) => cell.trim())
      .filter(Boolean);

    if (cells.length < 5) continue;
    if (
      !/property|parameter/i.test(cells[0]) ||
      !/type/i.test(cells[1]) ||
      !/required/i.test(cells[2])
    ) {
      continue;
    }

    dataStart = i + 2;
    break;
  }

  if (dataStart === -1) return props;

  for (let index = dataStart; index < lines.length; index += 1) {
    const row = lines[index];
    if (!row.trim().startsWith("|")) break;
    if (row.includes("---")) continue;

    const rowCells = row
      .split("|")
      .map((cell) => cell.trim())
      .filter(Boolean);

    if (rowCells.length < 5) continue;

    props.push({
      name: stripCode(rowCells[0]),
      type: stripCode(rowCells[1]),
      required: /^yes|required$/i.test(stripCode(rowCells[2])),
      defaultValue: stripCode(rowCells[3]),
      description: stripCode(rowCells[4]),
      source: "docs",
    });
  }

  return props;
}
