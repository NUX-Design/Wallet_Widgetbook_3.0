import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {
  buildConfig,
  buildExampleFileName,
  defaultRepoRoot,
  getSelectedClients,
  mergeServerConfig,
  normalizeClientName,
  readJsonConfig,
  writeExampleConfigs,
  writeSettingsConfig,
} from "../installer.js";

test("installer normalizes supported client aliases", () => {
  assert.equal(normalizeClientName("claude"), "claude-code");
  assert.equal(normalizeClientName("codex"), "codex-chatgpt-agent");
  assert.equal(normalizeClientName("chatgpt-agent"), "codex-chatgpt-agent");
  assert.equal(normalizeClientName("cursor"), "cursor");
  assert.throws(() => normalizeClientName("unknown"), /Unsupported client/);
});

test("installer generates per-client example files", () => {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "flutter-widget-wallet-mcp-examples-"));
  const exampleDir = path.join(workspace, "examples");
  const written = writeExampleConfigs({
    client: "all",
    exampleDir,
    repoRoot: defaultRepoRoot,
    serverName: "flutter-widget-wallet-mcp",
  });

  assert.equal(getSelectedClients("all").length, 3);
  assert.ok(
    written.some((file) => file.path.endsWith(buildExampleFileName("claude-code"))),
  );
  assert.ok(
    fs.existsSync(path.join(exampleDir, buildExampleFileName("codex-chatgpt-agent"))),
  );
  assert.ok(fs.existsSync(path.join(exampleDir, buildExampleFileName("cursor"))));
});

test("installer writes settings into empty config files", () => {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "flutter-widget-wallet-mcp-config-"));
  const configPath = path.join(workspace, "mcp.json");
  fs.writeFileSync(configPath, "", "utf8");

  writeSettingsConfig(configPath, {
    repoRoot: defaultRepoRoot,
    serverName: "flutter-widget-wallet-mcp",
  });

  const config = readJsonConfig(configPath);
  assert.deepEqual(config, buildConfig({ repoRoot: defaultRepoRoot, serverName: "flutter-widget-wallet-mcp" }));
});

test("installer rejects malformed JSON configs with a clear error", () => {
  const workspace = fs.mkdtempSync(path.join(os.tmpdir(), "flutter-widget-wallet-mcp-bad-config-"));
  const configPath = path.join(workspace, "mcp.json");
  fs.writeFileSync(configPath, "{oops", "utf8");

  assert.throws(() => readJsonConfig(configPath), /malformed JSON/);
});

test("installer merges server config without dropping existing servers", () => {
  const merged = mergeServerConfig(
    {
      mcpServers: {
        existing: {
          command: "node",
          args: ["/tmp/existing.js"],
        },
      },
    },
    {
      repoRoot: defaultRepoRoot,
      serverName: "flutter-widget-wallet-mcp",
    },
  );

  assert.ok(merged.mcpServers.existing);
  assert.ok(merged.mcpServers["flutter-widget-wallet-mcp"]);
});
