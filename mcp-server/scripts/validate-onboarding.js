#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawnSync } from "node:child_process";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");
const repoRoot = path.resolve(serverRoot, "..");
const clients = ["claude-code", "codex-chatgpt-agent", "cursor"];

function runInstall(args) {
  const result = spawnSync("npm", ["run", "install-mcp", "--", ...args], {
    cwd: serverRoot,
    encoding: "utf8",
    shell: process.platform === "win32",
  });

  return result;
}

function main() {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "flutter-widget-wallet-mcp-onboarding-"));
  const exampleDir = path.join(workspace, "examples");

  console.log("Validating onboarding flow with generated examples...");
  const examplesRun = runInstall(["--client", "all", "--repo-root", repoRoot, "--example-dir", exampleDir]);
  assert.equal(examplesRun.status, 0, examplesRun.stderr || examplesRun.stdout);

  for (const client of clients) {
    const configPath = path.join(workspace, `${client}.json`);
    fs.writeFileSync(configPath, "", "utf8");
    const result = runInstall([
      "--client",
      client,
      "--repo-root",
      repoRoot,
      "--settings",
      configPath,
    ]);
    assert.equal(result.status, 0, result.stderr || result.stdout);

    const config = JSON.parse(fs.readFileSync(configPath, "utf8"));
    assert.equal(
      config.mcpServers["flutter-widget-wallet-mcp"].args[0],
      path.join(repoRoot, "mcp-server", "index.js"),
    );
    console.log(`PASS onboarding ${client}`);
  }

  const malformedPath = path.join(workspace, "malformed.json");
  fs.writeFileSync(malformedPath, "{not json", "utf8");
  const malformedResult = runInstall([
    "--client",
    "cursor",
    "--repo-root",
    repoRoot,
    "--settings",
    malformedPath,
  ]);
  assert.notEqual(malformedResult.status, 0, "Malformed config should fail.");
  assert.match(malformedResult.stderr, /malformed JSON/);
  console.log("PASS onboarding malformed-config guard");

  console.log("Onboarding validation passed.");
}

try {
  main();
} catch (error) {
  console.error("Onboarding validation failed.");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
