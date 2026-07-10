import { execFileSync } from "node:child_process";
import path from "node:path";
import { createStructuredLogger } from "./observability.js";
import { toolDefinitions } from "./tool_contracts.js";
import { fail, ToolError } from "./tool_runtime.js";
import { WidgetCatalog } from "./widget_catalog.js";

const REMOTE_EXCLUDED_TOOL_NAMES = new Set([
  "generate_widget_code",
  "generate_widgetbook_use_case",
  "generate_v3_widget_code",
  "generate_v3_widgetbook_use_case",
]);

export const REMOTE_READ_ONLY_TOOL_DEFINITIONS = toolDefinitions.filter(
  (tool) => tool.annotations?.readOnlyHint === true && !REMOTE_EXCLUDED_TOOL_NAMES.has(tool.name),
);
export const REMOTE_READ_ONLY_TOOL_NAMES = new Set(
  REMOTE_READ_ONLY_TOOL_DEFINITIONS.map((tool) => tool.name),
);

function readGitValue(repoRoot, args) {
  try {
    return execFileSync("git", args, {
      cwd: repoRoot,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"],
    }).trim();
  } catch {
    return "";
  }
}

export function resolveRemoteRepoIdentity(repoRoot, env = process.env) {
  const configured = env.MCP_REMOTE_REPO_ID?.trim();
  if (configured) return configured;

  const remoteUrl = readGitValue(repoRoot, ["config", "--get", "remote.origin.url"]);
  if (remoteUrl) return remoteUrl;

  return path.basename(repoRoot);
}

export function resolveRemoteCommitSha(repoRoot, env = process.env) {
  const configured = env.MCP_REMOTE_COMMIT_SHA?.trim();
  if (configured) return configured;

  const headCommit = readGitValue(repoRoot, ["rev-parse", "HEAD"]);
  return headCommit || "unknown";
}

export function buildRemoteNamespace({ repoIdentity, channel, commitSha }) {
  return `${repoIdentity}::${channel}::${commitSha}`;
}

export function createRestrictedDispatchToolCall(dispatchToolCall, allowedToolNames = REMOTE_READ_ONLY_TOOL_NAMES) {
  return async (name, args = {}) => {
    if (!allowedToolNames.has(name)) {
      return fail(
        new ToolError(
          "UNKNOWN_TOOL",
          `Tool "${name}" is not exposed on the remote HTTP transport.`,
          {
            hint: "Use tools/list on the remote endpoint to inspect the read-only tool registry.",
          },
        ),
      );
    }

    return dispatchToolCall(name, args);
  };
}

export class RemoteCatalogRegistry {
  #repoRoot;
  #repoIdentity;
  #channel;
  #logger;
  #resolveCommitSha;
  #widgetCatalogFactory;
  #snapshots;
  #activeNamespace;

  constructor({
    repoRoot,
    repoIdentity = resolveRemoteRepoIdentity(repoRoot),
    channel = "production",
    logger = createStructuredLogger(),
    resolveCommitSha = () => resolveRemoteCommitSha(repoRoot),
    widgetCatalogFactory = () => new WidgetCatalog(repoRoot, { logger }),
  }) {
    this.#repoRoot = repoRoot;
    this.#repoIdentity = repoIdentity;
    this.#channel = channel;
    this.#logger = logger;
    this.#resolveCommitSha = resolveCommitSha;
    this.#widgetCatalogFactory = widgetCatalogFactory;
    this.#snapshots = new Map();
    this.#activeNamespace = null;
  }

  async getActiveSnapshot() {
    if (this.#activeNamespace && this.#snapshots.has(this.#activeNamespace)) {
      return this.#snapshots.get(this.#activeNamespace);
    }

    return this.refresh({ reason: "startup" });
  }

  async refresh({ reason = "manual", commitSha, deployedAt = new Date().toISOString() } = {}) {
    const resolvedCommitSha = commitSha ?? this.#resolveCommitSha();
    const namespace = buildRemoteNamespace({
      repoIdentity: this.#repoIdentity,
      channel: this.#channel,
      commitSha: resolvedCommitSha,
    });
    const widgetCatalog = this.#widgetCatalogFactory({
      namespace,
      commitSha: resolvedCommitSha,
      deployedAt,
    });
    const catalogState = await widgetCatalog.getCatalogState();
    const snapshot = {
      repoRoot: this.#repoRoot,
      repoIdentity: this.#repoIdentity,
      channel: this.#channel,
      commitSha: resolvedCommitSha,
      deployedAt,
      namespace,
      widgetCatalog,
      catalogGeneratedAt: catalogState.generatedAt,
      widgetCount: catalogState.widgetCount,
      categoryCount: catalogState.categoryCount,
    };

    this.#snapshots.set(namespace, snapshot);
    this.#activeNamespace = namespace;
    this.#logger.info("remote.snapshot.refresh", {
      reason,
      namespace,
      repoIdentity: this.#repoIdentity,
      channel: this.#channel,
      commitSha: resolvedCommitSha,
      deployedAt,
      widgetCount: catalogState.widgetCount,
      categoryCount: catalogState.categoryCount,
      catalogGeneratedAt: catalogState.generatedAt,
    });

    return snapshot;
  }

  async describeActiveSnapshot() {
    const snapshot = await this.getActiveSnapshot();
    const catalogState = await snapshot.widgetCatalog.getCatalogState();

    return {
      repoIdentity: snapshot.repoIdentity,
      repoRoot: snapshot.repoRoot,
      channel: snapshot.channel,
      commitSha: snapshot.commitSha,
      deployedAt: snapshot.deployedAt,
      namespace: snapshot.namespace,
      catalogGeneratedAt: catalogState.generatedAt,
      widgetCount: catalogState.widgetCount,
      categoryCount: catalogState.categoryCount,
    };
  }
}
