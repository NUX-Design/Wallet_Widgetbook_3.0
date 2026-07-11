import fs from "node:fs";
import { ToolError } from "../tool_runtime.js";

function normalizeSegment(value) {
  return value
    .trim()
    .replace(/([a-z0-9])([A-Z])/g, "$1-$2")
    .replace(/[\s_]+/g, "-")
    .toLowerCase();
}

export function normalizeTokenPath(parts) {
  const normalized = parts.map(normalizeSegment).filter(Boolean);
  if (["semantic", "core"].includes(normalized[0])) normalized.shift();
  return normalized.join("/");
}

export function toDartProperty(tokenPath) {
  const parts = tokenPath.split(/[\/-]/).filter(Boolean);
  return parts.map((part, index) =>
    index === 0 ? part : `${part[0].toUpperCase()}${part.slice(1)}`,
  ).join("");
}

function readColorValue(value, sourcePath) {
  if (typeof value === "string") {
    const alias = value.match(/^\{(.+)\}$/)?.[1];
    return alias ? { alias: normalizeTokenPath(alias.split(".")) } : { value };
  }
  if (value && typeof value === "object" && typeof value.hex === "string") {
    return { value: value.hex.toUpperCase(), alpha: value.alpha ?? 1 };
  }
  throw new ToolError("INVALID_RESOURCE", `Unsupported V3 color value at "${sourcePath}".`, {
    hint: "Use a Figma/DTCG color object or an alias such as {Core.Slate.900}.",
  });
}

export function parseTokenDocument(document, { source = "token document" } = {}) {
  const tokens = [];
  function walk(node, parts = [], inheritedType = null) {
    if (!node || typeof node !== "object" || Array.isArray(node)) return;
    const type = node.$type ?? inheritedType;
    if (Object.hasOwn(node, "$value")) {
      if (type && type !== "color") return;
      const sourcePath = parts.join("/");
      const path = normalizeTokenPath(parts);
      const parsedValue = readColorValue(node.$value, sourcePath);
      const figmaAlias = node.$extensions?.["com.figma.aliasData"]?.targetVariableName;
      const normalizedFigmaAlias = figmaAlias ? normalizeTokenPath(figmaAlias.split("/")) : null;
      tokens.push({
        sourcePath,
        path,
        dartProperty: toDartProperty(path),
        ...parsedValue,
        ...(normalizedFigmaAlias && normalizedFigmaAlias !== path
          ? { alias: normalizedFigmaAlias, aliasPrimitive: true }
          : {}),
      });
      return;
    }
    for (const [key, value] of Object.entries(node)) {
      if (!key.startsWith("$")) walk(value, [...parts, key], type);
    }
  }
  walk(document);
  const seen = new Set();
  for (const token of tokens) {
    if (seen.has(token.path)) {
      throw new ToolError("INVALID_RESOURCE", `Duplicate normalized V3 token path "${token.path}" in ${source}.`);
    }
    seen.add(token.path);
  }
  return tokens;
}

export function parseTokenFile(filePath) {
  try {
    return parseTokenDocument(JSON.parse(fs.readFileSync(filePath, "utf8")), { source: filePath });
  } catch (error) {
    if (error instanceof ToolError) throw error;
    throw new ToolError("INVALID_RESOURCE", `Failed to parse V3 token file "${filePath}".`, {
      hint: "Verify that the file contains valid Figma/DTCG JSON.",
      details: { cause: error.message },
    });
  }
}
