#!/usr/bin/env node

import { spawnSync } from "node:child_process";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");

const commands = [
  { label: "syntax", args: ["run", "check:mcp-syntax"] },
  { label: "tests", args: ["test"] },
  { label: "verify", args: ["run", "verify:mcp"] },
  { label: "verify-http", args: ["run", "verify:mcp:http"] },
  { label: "evaluate", args: ["run", "evaluate:mcp"] },
];

function main() {
  console.log("Running MCP CI parity workflow...");

  for (const command of commands) {
    console.log(`\n==> npm ${command.args.join(" ")}`);
    const result = spawnSync("npm", command.args, {
      cwd: serverRoot,
      stdio: "inherit",
      shell: process.platform === "win32",
    });

    if (result.status !== 0) {
      throw new Error(`Step "${command.label}" failed with exit code ${result.status}.`);
    }
  }

  console.log("\nMCP CI parity workflow passed.");
}

try {
  main();
} catch (error) {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
