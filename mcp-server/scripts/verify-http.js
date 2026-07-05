#!/usr/bin/env node

import assert from "node:assert/strict";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { startRemoteHttpServer } from "../http-server.js";
import { REMOTE_READ_ONLY_TOOL_DEFINITIONS } from "../remote_support.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(__dirname, "..", "..");

async function main() {
  console.log("Running MCP Streamable HTTP verification against local hosted endpoint...");

  let currentCommit = "verify-commit-a";
  const remoteServer = await startRemoteHttpServer({
    projectRoot,
    host: "127.0.0.1",
    port: 0,
    repoIdentity: "local/flutter_widgetbook_3.0",
    commitSha: currentCommit,
    resolveCommitSha: () => currentCommit,
    deployedAt: "2026-07-05T00:00:00.000Z",
    proxySharedSecret: "verify-secret",
    refreshToken: "verify-refresh-secret",
  });

  const client = new Client({
    name: "flutter-widget-wallet-mcp-http-verifier",
    version: "1.0.0",
  });
  const transport = new StreamableHTTPClientTransport(new URL(remoteServer.url), {
    requestInit: {
      headers: {
        "x-mcp-authenticated-user": "verify-user",
        "x-mcp-proxy-secret": "verify-secret",
      },
    },
  });

  try {
    await client.connect(transport);

    const listedTools = await client.listTools();
    assert.deepEqual(
      listedTools.tools.map((tool) => tool.name),
      REMOTE_READ_ONLY_TOOL_DEFINITIONS.map((tool) => tool.name),
    );
    console.log(`PASS tools/list (${listedTools.tools.length} read-only tools)`);

    const widgets = await client.callTool({
      name: "list_widgets",
      arguments: { category: "button", limit: 5, offset: 0 },
    });
    assert.equal(widgets.structuredContent.category, "button");
    console.log(`PASS list_widgets (${widgets.structuredContent.count} item(s))`);

    const search = await client.callTool({
      name: "search_widgets",
      arguments: { query: "button", limit: 5, offset: 0 },
    });
    assert.ok(search.structuredContent.count >= 1);
    console.log(`PASS search_widgets (${search.structuredContent.count} item(s))`);

    const metadata = await client.callTool({
      name: "get_widget_metadata",
      arguments: { widgetName: "Buttons" },
    });
    assert.equal(metadata.structuredContent.name, "Buttons");
    console.log("PASS get_widget_metadata");

    const infoBefore = await fetch(remoteServer.url.replace("/mcp", "/info"));
    assert.equal(infoBefore.status, 200);
    const infoBeforePayload = await infoBefore.json();
    assert.equal(infoBeforePayload.freshness.commitSha, "verify-commit-a");
    console.log("PASS info endpoint");

    currentCommit = "verify-commit-b";
    const refresh = await fetch(remoteServer.url.replace("/mcp", "/admin/refresh"), {
      method: "POST",
      headers: {
        "x-mcp-refresh-token": "verify-refresh-secret",
      },
    });
    assert.equal(refresh.status, 200);

    const healthAfter = await fetch(remoteServer.url.replace("/mcp", "/health"));
    assert.equal(healthAfter.status, 200);
    const healthPayload = await healthAfter.json();
    assert.equal(healthPayload.commitSha, "verify-commit-b");
    console.log("PASS refresh + health endpoints");

    console.log("MCP Streamable HTTP verification passed.");
  } finally {
    await transport.close().catch(() => {});
    await remoteServer.close().catch(() => {});
  }
}

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
