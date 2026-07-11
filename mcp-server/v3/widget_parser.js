import fs from "node:fs";
import path from "node:path";
import { extractDependencies, extractInternalImports, extractWidgetClassNames, parsePropsFromCode } from "../catalog/dart_parser.js";

const TOKEN_PATTERN = /colors\.([A-Za-z][A-Za-z0-9]*)/g;

export function parseV3Metadata(docText) {
  const metadata = docText.match(/## V3 Metadata[\s\S]*?```yaml\s*([\s\S]*?)```/i)?.[1] ?? "";
  const scalar = (key) => metadata.match(new RegExp(`^${key}:\\s*(.+)$`, "mi"))?.[1]?.trim() ?? null;
  const list = (key) => {
    const block = metadata.match(new RegExp(`^${key}:\\s*\\n((?:\\s+- .+\\n?)+)`, "mi"))?.[1] ?? "";
    return [...block.matchAll(/^\s+-\s+["']?(.+?)["']?\s*$/gm)].map((match) => match[1]);
  };
  return { themeVersion: scalar("Theme system")?.toLowerCase() ?? null, semanticTokens: list("Semantic tokens"), figmaNodes: list("Figma nodes") };
}

export function parseV3Widget({ repoRoot, filePath, docFiles, previewFiles }) {
  const code = fs.readFileSync(path.join(repoRoot, filePath), "utf8");
  const names = extractWidgetClassNames(code).filter((name) => name.startsWith("V3"));
  const docs = docFiles.map((file) => fs.readFileSync(path.join(repoRoot, file), "utf8")).join("\n");
  const metadata = parseV3Metadata(docs);
  const tokenProperties = [...new Set([...code.matchAll(TOKEN_PATTERN)].map((match) => match[1]))].sort();
  return names.map((name) => ({
    name,
    normalizedName: name.toLowerCase(),
    themeVersion: metadata.themeVersion,
    category: filePath.split("/").at(-2),
    widgetFile: filePath,
    previewFiles,
    docFiles,
    props: parsePropsFromCode(code, name),
    dependencies: extractDependencies(code, []),
    internalImports: extractInternalImports(code),
    semanticTokens: metadata.semanticTokens,
    tokenProperties,
    figmaNodes: metadata.figmaNodes,
    sourceText: code,
    docsText: docs,
  }));
}
