import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import { DEFAULT_SERVER_NAME } from "./server_metadata.js";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const DEFAULT_CLIENT = "all";
export const CLIENT_ORDER = ["claude-code", "codex-chatgpt-agent", "cursor"];

const CLIENT_ALIASES = {
  all: "all",
  claude: "claude-code",
  "claude-code": "claude-code",
  codex: "codex-chatgpt-agent",
  chatgpt: "codex-chatgpt-agent",
  "chatgpt-agent": "codex-chatgpt-agent",
  "codex-chatgpt-agent": "codex-chatgpt-agent",
  cursor: "cursor",
  generic: "generic",
};

const CLIENT_LABELS = {
  "claude-code": "Claude Code",
  "codex-chatgpt-agent": "Codex",
  cursor: "Cursor",
  generic: "Generic MCP config",
};

export { CLIENT_LABELS };

export const defaultRepoRoot = path.resolve(__dirname, "..");
export const defaultExampleConfigPath = path.resolve(__dirname, "mcp.json.example");
export const defaultExamplesDir = path.resolve(__dirname, "examples");

function hasValue(candidate) {
  return typeof candidate === "string" && candidate.trim().length > 0;
}

export function normalizeClientName(clientName = DEFAULT_CLIENT) {
  const normalized = CLIENT_ALIASES[String(clientName).trim().toLowerCase()];
  if (!normalized) {
    throw new Error(
      `Unsupported client "${clientName}". Valid values: ${[
        "all",
        "claude-code",
        "codex-chatgpt-agent",
        "cursor",
        "generic",
      ].join(", ")}`,
    );
  }
  return normalized;
}

export function parseArgs(argv) {
  const parsed = {};

  for (let index = 0; index < argv.length; index += 1) {
    const arg = argv[index];
    const next = argv[index + 1];

    if (arg === "--settings") parsed.settingsPath = next;
    if (arg === "--server-name") parsed.serverName = next;
    if (arg === "--client") parsed.client = next;
    if (arg === "--repo-root") parsed.repoRoot = next;
    if (arg === "--example-dir") parsed.exampleDir = next;
  }

  return parsed;
}

export function resolveInstallOptions(cli = {}, env = process.env) {
  const repoRoot = path.resolve(cli.repoRoot || env.MCP_REPO_ROOT || defaultRepoRoot);
  const serverName = cli.serverName || env.MCP_SERVER_NAME || DEFAULT_SERVER_NAME;
  const client = normalizeClientName(cli.client || env.MCP_CLIENT || DEFAULT_CLIENT);
  const settingsPath = cli.settingsPath || env.MCP_SETTINGS_PATH || null;
  const exampleDir = path.resolve(cli.exampleDir || env.MCP_EXAMPLE_DIR || defaultExamplesDir);

  return {
    client,
    repoRoot,
    serverName,
    settingsPath,
    exampleDir,
  };
}

export function resolveServerIndexPath(repoRoot) {
  return path.resolve(repoRoot, "mcp-server", "index.js");
}

export function buildServerEntry(repoRoot) {
  return {
    command: "node",
    args: [resolveServerIndexPath(repoRoot)],
  };
}

export function buildConfig({ repoRoot, serverName }) {
  return {
    mcpServers: {
      [serverName]: buildServerEntry(repoRoot),
    },
  };
}

export function buildExampleFileName(client) {
  return client === "generic" ? "generic.mcp.json" : `${client}.mcp.json`;
}

export function getSelectedClients(client) {
  if (client === "all") {
    return CLIENT_ORDER;
  }
  if (client === "generic") {
    return ["generic"];
  }
  return [client];
}

export function readJsonConfig(filePath) {
  if (!fs.existsSync(filePath)) {
    return {};
  }

  const raw = fs.readFileSync(filePath, "utf8").trim();
  if (!raw) {
    return {};
  }

  let parsed;
  try {
    parsed = JSON.parse(raw);
  } catch (error) {
    throw new Error(`Config file "${filePath}" is malformed JSON: ${error.message}`);
  }

  if (parsed === null || Array.isArray(parsed) || typeof parsed !== "object") {
    throw new Error(`Config file "${filePath}" must contain a JSON object at the root.`);
  }

  return parsed;
}

export function mergeServerConfig(existingConfig, { repoRoot, serverName }) {
  const merged = { ...existingConfig };
  const currentServers =
    merged.mcpServers && typeof merged.mcpServers === "object" && !Array.isArray(merged.mcpServers)
      ? { ...merged.mcpServers }
      : {};

  currentServers[serverName] = buildServerEntry(repoRoot);
  merged.mcpServers = currentServers;
  return merged;
}

export function ensureServerExists(repoRoot) {
  const serverIndex = resolveServerIndexPath(repoRoot);
  if (!fs.existsSync(serverIndex)) {
    throw new Error(`Could not find MCP server entrypoint at ${serverIndex}`);
  }
  return serverIndex;
}

export function writeExampleConfigs({ client, exampleDir, repoRoot, serverName }) {
  const selectedClients = getSelectedClients(client);
  const genericConfig = buildConfig({ repoRoot, serverName });

  fs.mkdirSync(exampleDir, { recursive: true });
  fs.writeFileSync(defaultExampleConfigPath, `${JSON.stringify(genericConfig, null, 2)}\n`, "utf8");

  const writtenFiles = [
    {
      client: "generic",
      label: CLIENT_LABELS.generic,
      path: defaultExampleConfigPath,
    },
  ];

  for (const selectedClient of selectedClients) {
    const outputPath = path.join(exampleDir, buildExampleFileName(selectedClient));
    fs.writeFileSync(outputPath, `${JSON.stringify(genericConfig, null, 2)}\n`, "utf8");
    writtenFiles.push({
      client: selectedClient,
      label: CLIENT_LABELS[selectedClient],
      path: outputPath,
    });
  }

  return writtenFiles;
}

export function writeSettingsConfig(settingsPath, { repoRoot, serverName }) {
  const directory = path.dirname(settingsPath);
  fs.mkdirSync(directory, { recursive: true });
  const existing = readJsonConfig(settingsPath);
  const merged = mergeServerConfig(existing, { repoRoot, serverName });
  fs.writeFileSync(settingsPath, `${JSON.stringify(merged, null, 2)}\n`, "utf8");
  return settingsPath;
}
