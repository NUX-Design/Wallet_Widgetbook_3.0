import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

const v3WorkPrefixes = [
  "lib/config/themes/v3/",
  "lib/widgets/v3/",
  "test/config/themes/v3/",
  "test/widgets/v3/",
  "mcp-server/v3/",
  "mcp-server/tests/v3/",
  "skills-v3/",
  "docs/v3/",
];

const v3ControlFiles = new Set([
  "docs/V3_THEME_MCP_SKILLS_PLAN.md",
  "task/V3_THEME_MCP_SKILLS_TASKS.md",
  "scripts/check-v3-boundaries.js",
  "scripts/check-v3-boundaries.test.js",
]);

function toPosix(filePath) {
  return filePath.split(path.sep).join("/").replace(/^\.\//, "");
}

function walkFiles(directory) {
  if (!fs.existsSync(directory)) return [];

  return fs.readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const entryPath = path.join(directory, entry.name);
    return entry.isDirectory() ? walkFiles(entryPath) : [entryPath];
  });
}

function extractImportUris(source) {
  const imports = [];
  const importPattern = /^\s*import\s+['"]([^'"]+)['"]/gm;
  for (const match of source.matchAll(importPattern)) imports.push(match[1]);
  return imports;
}

function resolveRepoImport(filePath, uri) {
  if (uri.startsWith("package:mcp_test_app/")) {
    return `lib/${uri.slice("package:mcp_test_app/".length)}`;
  }
  if (uri.startsWith("dart:") || uri.startsWith("package:")) return null;
  return path.posix.normalize(path.posix.join(path.posix.dirname(filePath), uri));
}

export function inspectDartBoundary(filePath, source) {
  const normalizedPath = toPosix(filePath);
  const violations = [];
  const isV3Theme = normalizedPath.startsWith("lib/config/themes/v3/");
  const isLegacyWidget =
    normalizedPath.startsWith("lib/widgets/") &&
    !normalizedPath.startsWith("lib/widgets/v3/");

  for (const uri of extractImportUris(source)) {
    const resolvedImport = resolveRepoImport(normalizedPath, uri);
    if (!resolvedImport) continue;

    if (isV3Theme && resolvedImport === "lib/config/themes/theme_color.dart") {
      violations.push(
        `${normalizedPath}: V3 theme code must not import legacy theme_color.dart (${uri})`,
      );
    }

    if (
      isLegacyWidget &&
      (resolvedImport.startsWith("lib/config/themes/v3/") ||
        resolvedImport.startsWith("lib/widgets/v3/"))
    ) {
      violations.push(
        `${normalizedPath}: legacy widgets must not import V3 code (${uri})`,
      );
    }
  }

  if (isV3Theme && /\bThemeColors\s*\.\s*get\s*\(/.test(source)) {
    violations.push(
      `${normalizedPath}: V3 theme code must use V3 semantic APIs, not ThemeColors.get()`,
    );
  }

  return violations;
}

export function inspectChangedPaths(changedPaths) {
  const normalizedPaths = [...new Set(changedPaths.map(toPosix))];
  const isV3Work = normalizedPaths.some(
    (filePath) =>
      v3WorkPrefixes.some((prefix) => filePath.startsWith(prefix)) ||
      v3ControlFiles.has(filePath),
  );
  if (!isV3Work) return [];

  return normalizedPaths
    .filter(
      (filePath) =>
        filePath === "skills" ||
        (filePath.startsWith("skills/") && !filePath.startsWith("skills-v3/")),
    )
    .map(
      (filePath) =>
        `${filePath}: legacy skills must remain unchanged in V3 work; use skills-v3/**`,
    );
}

function runGit(args) {
  try {
    return execFileSync("git", args, {
      cwd: repoRoot,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    })
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);
  } catch {
    return [];
  }
}

function isGitRef(value) {
  if (!value || /^0+$/.test(value)) return false;
  try {
    execFileSync("git", ["rev-parse", "--verify", `${value}^{commit}`], {
      cwd: repoRoot,
      stdio: "ignore",
    });
    return true;
  } catch {
    return false;
  }
}

function readBaseRef(argv) {
  const argumentIndex = argv.indexOf("--base-ref");
  return argumentIndex >= 0 ? argv[argumentIndex + 1] : process.env.V3_BOUNDARY_BASE_REF;
}

export function collectChangedPaths(baseRef) {
  const changedPaths = [];
  if (isGitRef(baseRef)) {
    changedPaths.push(...runGit(["diff", "--name-only", `${baseRef}...HEAD`]));
  }
  changedPaths.push(...runGit(["diff", "--name-only"]));
  changedPaths.push(...runGit(["diff", "--cached", "--name-only"]));
  changedPaths.push(...runGit(["ls-files", "--others", "--exclude-standard"]));
  return [...new Set(changedPaths)];
}

export function runBoundaryCheck({ baseRef } = {}) {
  const dartFiles = [
    ...walkFiles(path.join(repoRoot, "lib/config/themes/v3")),
    ...walkFiles(path.join(repoRoot, "lib/widgets")),
  ].filter((filePath) => filePath.endsWith(".dart"));

  const importViolations = dartFiles.flatMap((absolutePath) => {
    const relativePath = toPosix(path.relative(repoRoot, absolutePath));
    return inspectDartBoundary(relativePath, fs.readFileSync(absolutePath, "utf8"));
  });
  const changedPaths = collectChangedPaths(baseRef);
  const changedPathViolations = inspectChangedPaths(changedPaths);
  return {
    checkedDartFiles: dartFiles.length,
    checkedChangedPaths: changedPaths.length,
    violations: [...importViolations, ...changedPathViolations],
  };
}

function main() {
  const result = runBoundaryCheck({ baseRef: readBaseRef(process.argv.slice(2)) });
  if (result.violations.length > 0) {
    console.error("V3 boundary check failed:");
    for (const violation of result.violations) console.error(`- ${violation}`);
    process.exitCode = 1;
    return;
  }

  console.log(
    `V3 boundary check passed (${result.checkedDartFiles} Dart files, ` +
      `${result.checkedChangedPaths} changed paths).`,
  );
}

if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main();
}
