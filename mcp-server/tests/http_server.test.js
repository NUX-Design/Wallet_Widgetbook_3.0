import assert from "node:assert/strict";
import test from "node:test";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { createStructuredLogger } from "../observability.js";
import { startRemoteHttpServer } from "../http-server.js";
import { REMOTE_READ_ONLY_TOOL_DEFINITIONS } from "../remote_support.js";
import { createToolHarness } from "./helpers/tool_harness.js";
import { fixtureProjectRoot } from "./helpers/fixture_repo.js";

const authHeaders = {
  "x-mcp-authenticated-user": "remote-test-user",
  "x-mcp-proxy-secret": "proxy-secret",
};

async function createRemoteClient(serverUrl, headers = authHeaders) {
  const client = new Client({
    name: "remote-http-test-client",
    version: "1.0.0",
  });
  const transport = new StreamableHTTPClientTransport(new URL(serverUrl), {
    requestInit: {
      headers,
    },
  });
  await client.connect(transport);
  return { client, transport };
}

test("remote HTTP exposes the read-only registry and matches stdio tool output", async (t) => {
  const remote = await startRemoteHttpServer({
    projectRoot: fixtureProjectRoot,
    host: "127.0.0.1",
    port: 0,
    repoIdentity: "fixture/widget-repo",
    commitSha: "commit-a",
    resolveCommitSha: () => "commit-a",
    deployedAt: "2026-07-05T00:00:00.000Z",
    proxySharedSecret: "proxy-secret",
    logger: createStructuredLogger({ level: "silent" }),
  });
  t.after(async () => {
    await remote.close();
  });

  const { client, transport } = await createRemoteClient(remote.url);
  t.after(async () => {
    await transport.close().catch(() => {});
  });

  const tools = await client.listTools();
  assert.deepEqual(tools.tools, REMOTE_READ_ONLY_TOOL_DEFINITIONS);
  assert.ok(!tools.tools.some((tool) => tool.name === "generate_widget_code"));
  assert.ok(!tools.tools.some((tool) => tool.name === "generate_widgetbook_use_case"));
  assert.ok(!tools.tools.some((tool) => tool.name === "generate_v3_widget_code"));
  assert.ok(!tools.tools.some((tool) => tool.name === "generate_v3_widgetbook_use_case"));
  assert.ok(tools.tools.some((tool) => tool.name === "get_v3_design_system_info"));
  assert.ok(tools.tools.some((tool) => tool.name === "get_v3_figma_to_flutter_mapping"));

  const remoteResult = await client.callTool({
    name: "list_widgets",
    arguments: {
      category: "button",
      limit: 5,
      offset: 0,
    },
  });
  const localHarness = createToolHarness();
  const localResult = await localHarness.callSuccess("list_widgets", {
    category: "button",
    limit: 5,
    offset: 0,
  });

  assert.deepEqual(remoteResult.structuredContent, localResult.data);
});

test("remote HTTP rejects unauthenticated requests and caller-controlled repo selectors", async (t) => {
  const remote = await startRemoteHttpServer({
    projectRoot: fixtureProjectRoot,
    host: "127.0.0.1",
    port: 0,
    repoIdentity: "fixture/widget-repo",
    commitSha: "commit-a",
    resolveCommitSha: () => "commit-a",
    deployedAt: "2026-07-05T00:00:00.000Z",
    proxySharedSecret: "proxy-secret",
    logger: createStructuredLogger({ level: "silent" }),
  });
  t.after(async () => {
    await remote.close();
  });

  const unauthenticated = await fetch(remote.url, {
    method: "POST",
    headers: {
      "content-type": "application/json",
    },
    body: JSON.stringify({}),
  });
  assert.equal(unauthenticated.status, 401);

  const repoOverride = await fetch(`${remote.url}?repoRoot=/tmp/other`, {
    method: "POST",
    headers: {
      ...authHeaders,
      "content-type": "application/json",
    },
    body: JSON.stringify({}),
  });
  assert.equal(repoOverride.status, 400);
  const repoOverridePayload = await repoOverride.json();
  assert.match(repoOverridePayload.error, /Caller-controlled repo/);
});

test("remote HTTP info and refresh endpoints expose commit-pinned freshness metadata", async (t) => {
  let currentCommit = "commit-a";
  const remote = await startRemoteHttpServer({
    projectRoot: fixtureProjectRoot,
    host: "127.0.0.1",
    port: 0,
    repoIdentity: "fixture/widget-repo",
    commitSha: currentCommit,
    resolveCommitSha: () => currentCommit,
    deployedAt: "2026-07-05T00:00:00.000Z",
    proxySharedSecret: "proxy-secret",
    refreshToken: "refresh-secret",
    logger: createStructuredLogger({ level: "silent" }),
  });
  t.after(async () => {
    await remote.close();
  });

  const infoBefore = await fetch(remote.url.replace("/mcp", "/info"));
  assert.equal(infoBefore.status, 200);
  const infoBeforePayload = await infoBefore.json();
  assert.equal(infoBeforePayload.freshness.commitSha, "commit-a");
  assert.equal(infoBeforePayload.freshness.deployedAt, "2026-07-05T00:00:00.000Z");
  assert.equal(infoBeforePayload.targeting.namespace, "fixture/widget-repo::production::commit-a");

  currentCommit = "commit-b";
  const refresh = await fetch(remote.url.replace("/mcp", "/admin/refresh"), {
    method: "POST",
    headers: {
      "x-mcp-refresh-token": "refresh-secret",
    },
  });
  assert.equal(refresh.status, 200);
  const refreshPayload = await refresh.json();
  assert.equal(refreshPayload.commitSha, "commit-b");

  const healthAfter = await fetch(remote.url.replace("/mcp", "/health"));
  assert.equal(healthAfter.status, 200);
  const healthPayload = await healthAfter.json();
  assert.equal(healthPayload.commitSha, "commit-b");
  assert.equal(healthPayload.namespace, "fixture/widget-repo::production::commit-b");
});

test("remote HTTP rate limits repeated authenticated MCP requests", async (t) => {
  const remote = await startRemoteHttpServer({
    projectRoot: fixtureProjectRoot,
    host: "127.0.0.1",
    port: 0,
    repoIdentity: "fixture/widget-repo",
    commitSha: "commit-a",
    resolveCommitSha: () => "commit-a",
    deployedAt: "2026-07-05T00:00:00.000Z",
    proxySharedSecret: "proxy-secret",
    rateLimitMaxRequests: 2,
    rateLimitWindowMs: 60_000,
    logger: createStructuredLogger({ level: "silent" }),
  });
  t.after(async () => {
    await remote.close();
  });

  const { transport } = await createRemoteClient(remote.url);
  t.after(async () => {
    await transport.close().catch(() => {});
  });

  const limited = await fetch(remote.url, {
    method: "POST",
    headers: {
      ...authHeaders,
      "content-type": "application/json",
    },
    body: JSON.stringify({}),
  });
  assert.equal(limited.status, 429);
});
