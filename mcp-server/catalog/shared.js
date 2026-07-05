import fs from "fs";
import path from "path";

export function safeRead(file) {
  try {
    return fs.readFileSync(file, "utf8");
  } catch {
    return null;
  }
}

export function toRelative(repoRoot, absoluteFile) {
  return path.relative(repoRoot, absoluteFile).split(path.sep).join(path.posix.sep);
}

export function stripCode(value) {
  return String(value ?? "").replace(/`/g, "").trim();
}

export function splitCamelCase(value) {
  return String(value ?? "")
    .replace(/([a-z0-9])([A-Z])/g, "$1 $2")
    .split(/[\s_-]+/)
    .filter(Boolean);
}

export function normalize(value) {
  return String(value ?? "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, " ")
    .trim();
}

export function hasMainEntrypoint(content) {
  return /\bvoid\s+main\s*\(/.test(content);
}

export function uniqueSorted(values) {
  return [...new Set(values)].sort();
}
