import fs from "fs";
import { execFileSync } from "child_process";

export function extractWidgetClassNames(content) {
  const names = new Set();
  const pattern = /class\s+([A-Z][A-Za-z0-9_]*)\s+extends\s+(?:StatefulWidget|StatelessWidget)\b/g;
  for (const match of content.matchAll(pattern)) {
    names.add(match[1]);
  }
  return [...names];
}

export function parsePropsFromCode(content, widgetName) {
  const widgetClassBody = extractClassBody(content, widgetName);
  if (!widgetClassBody) {
    return [];
  }

  const fields = new Map();
  const fieldPattern =
    /^\s*(?:final\s+)?([A-Za-z_][A-Za-z0-9_<>,?.\s]*)\s+([A-Za-z][A-Za-z0-9_]*)\s*;/gm;

  for (const match of widgetClassBody.matchAll(fieldPattern)) {
    const [, type, name] = match;
    fields.set(name, {
      name,
      type: type.trim(),
      required: false,
      source: "code",
    });
  }

  const constructorPattern = new RegExp(
    `(?:const\\s+)?${widgetName}\\s*\\(\\s*\\{([\\s\\S]*?)\\}\\s*\\);`,
    "m",
  );
  const constructorBody = widgetClassBody.match(constructorPattern)?.[1] ?? "";
  const namedParameterPattern =
    /(?:required\s+)?this\.([A-Za-z_]\w*)(?:\s*=\s*([^,\n]+))?/g;

  for (const match of constructorBody.matchAll(namedParameterPattern)) {
    const [, name, defaultValue] = match;
    const prop = fields.get(name) ?? {
      name,
      type: "dynamic",
      required: false,
      source: "code",
    };

    prop.required = prop.required || match[0].includes("required");
    if (defaultValue) {
      prop.defaultValue = defaultValue.trim();
    }

    fields.set(name, prop);
  }

  return [...fields.values()].sort((a, b) => a.name.localeCompare(b.name));
}

function extractClassBody(content, widgetName) {
  const classStart = content.search(
    new RegExp(`class\\s+${widgetName}\\s+extends\\s+(?:StatefulWidget|StatelessWidget)\\b`),
  );
  if (classStart === -1) return null;

  const openingBrace = content.indexOf("{", classStart);
  if (openingBrace === -1) return null;

  let depth = 0;
  for (let index = openingBrace; index < content.length; index += 1) {
    const character = content[index];
    if (character === "{") depth += 1;
    if (character === "}") {
      depth -= 1;
      if (depth === 0) {
        return content.slice(openingBrace + 1, index);
      }
    }
  }

  return null;
}

export function extractDependencies(content, docDependencies) {
  const dependencies = new Set(docDependencies);
  const pattern = /import\s+['"]package:([^/'"]+)\//g;

  for (const match of content.matchAll(pattern)) {
    const dependency = match[1];
    if (!dependency || dependency === "flutter" || dependency === "mcp_test_app") continue;
    dependencies.add(dependency);
  }

  return [...dependencies].sort();
}

export function extractInternalImports(content) {
  const imports = new Set();
  const packagePattern = /import\s+['"]package:mcp_test_app\/([^'"]+)['"]/g;
  const relativePattern = /import\s+['"](\.[^'"]+)['"]/g;

  for (const match of content.matchAll(packagePattern)) {
    imports.add(`lib/${match[1]}`);
  }

  for (const match of content.matchAll(relativePattern)) {
    imports.add(match[1]);
  }

  return [...imports].sort();
}

export function extractImportedRelativePaths(content) {
  const imports = new Set();
  const packagePattern = /import\s+['"]package:mcp_test_app\/([^'"]+)['"]/g;

  for (const match of content.matchAll(packagePattern)) {
    imports.add(`lib/${match[1]}`);
  }

  return [...imports].sort();
}

export function extractAssets(content, docAssets) {
  const assets = new Set(docAssets);
  for (const match of content.matchAll(/(?:lib\/)?assets\/[^'"`)\s]+/g)) {
    const asset = match[0].startsWith("lib/") ? match[0] : `lib/${match[0]}`;
    assets.add(asset);
  }
  return [...assets].sort();
}

export function readLastUpdatedAt(repoRoot, relativeFile, absoluteFile) {
  try {
    const output = execFileSync(
      "git",
      ["log", "-1", "--format=%cI", "--", relativeFile],
      {
        cwd: repoRoot,
        encoding: "utf8",
        stdio: ["ignore", "pipe", "ignore"],
      },
    ).trim();

    if (output) {
      return { value: output, source: "git" };
    }
  } catch {
    // Fallback to mtime when git history is unavailable.
  }

  return {
    value: fs.statSync(absoluteFile).mtime.toISOString(),
    source: "mtime",
  };
}
