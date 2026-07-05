#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");

const ignoredDirs = new Set(["node_modules", ".git"]);

function collectJavaScriptFiles(directory) {
  const entries = fs.readdirSync(directory, { withFileTypes: true });
  const files = [];

  for (const entry of entries) {
    if (entry.isDirectory()) {
      if (ignoredDirs.has(entry.name)) continue;
      files.push(...collectJavaScriptFiles(path.join(directory, entry.name)));
      continue;
    }

    if (entry.isFile() && entry.name.endsWith(".js")) {
      files.push(path.join(directory, entry.name));
    }
  }

  return files.sort();
}

function main() {
  const files = collectJavaScriptFiles(serverRoot);

  for (const file of files) {
    const result = spawnSync("node", ["--check", file], {
      cwd: serverRoot,
      encoding: "utf8",
    });

    if (result.status !== 0) {
      throw new Error(
        [
          `Syntax check failed for ${path.relative(serverRoot, file)}.`,
          result.stderr?.trim(),
          result.stdout?.trim(),
        ]
          .filter(Boolean)
          .join("\n"),
      );
    }

    console.log(`PASS syntax ${path.relative(serverRoot, file)}`);
  }

  console.log(`Syntax check passed for ${files.length} file(s).`);
}

try {
  main();
} catch (error) {
  console.error("MCP syntax check failed.");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
