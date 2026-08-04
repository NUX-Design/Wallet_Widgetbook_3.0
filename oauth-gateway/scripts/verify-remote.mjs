#!/usr/bin/env node

import { pathToFileURL } from "node:url";

const DEFAULT_ENDPOINT = "https://flutter-widget-wallet-oauth-gateway.onrender.com/mcp";

export function decodeJsonRpcBody(text) {
  const trimmed = text.trim();
  if (!trimmed) return undefined;
  try {
    return JSON.parse(trimmed);
  } catch {
    for (const event of trimmed.split(/\r?\n\r?\n/)) {
      const data = event
        .split(/\r?\n/)
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).trimStart())
        .join("\n")
        .trim();
      if (!data || data === "[DONE]") continue;
      try {
        return JSON.parse(data);
      } catch {
        // Continue until a complete JSON-RPC SSE event is found.
      }
    }
  }
  throw new Error("Response did not contain a JSON-RPC JSON or SSE data event.");
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

async function requestWithTimeout(url, init, timeoutMs) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal, redirect: "error" });
  } finally {
    clearTimeout(timer);
  }
}

export async function runSmoke(env = process.env) {
  const endpoint = new URL(env.OAUTH_GATEWAY_URL || DEFAULT_ENDPOINT);
  const accessToken = String(env.OAUTH_GATEWAY_ACCESS_TOKEN ?? "").trim();
  const timeoutMs = Number.parseInt(env.OAUTH_GATEWAY_TIMEOUT_MS || "60000", 10);
  const toolName = env.OAUTH_GATEWAY_SMOKE_TOOL || "list_v3_categories";
  const toolArguments = JSON.parse(env.OAUTH_GATEWAY_SMOKE_ARGUMENTS || "{}");
  assert(endpoint.protocol === "https:" && endpoint.pathname === "/mcp", "OAUTH_GATEWAY_URL must be an HTTPS /mcp URL.");
  assert(accessToken, "OAUTH_GATEWAY_ACCESS_TOKEN is required and is never printed by this verifier.");
  assert(Number.isSafeInteger(timeoutMs) && timeoutMs > 0, "OAUTH_GATEWAY_TIMEOUT_MS must be a positive integer.");

  const origin = endpoint.origin;
  const metadataUrl = new URL("/.well-known/oauth-protected-resource", origin);
  const metadataResponse = await requestWithTimeout(metadataUrl, {}, timeoutMs);
  assert(metadataResponse.ok, `Protected Resource Metadata returned HTTP ${metadataResponse.status}.`);
  const metadata = await metadataResponse.json();
  assert(metadata.resource === endpoint.href, "Protected Resource Metadata resource does not match the Gateway endpoint.");
  assert(Array.isArray(metadata.authorization_servers) && metadata.authorization_servers.length === 1, "Expected one Authorization Server.");
  console.log("PASS discovery: RFC 9728 metadata is valid.");

  const challengeResponse = await requestWithTimeout(endpoint, { method: "POST" }, timeoutMs);
  const challenge = challengeResponse.headers.get("www-authenticate") || "";
  assert(challengeResponse.status === 401 && challenge.includes("resource_metadata="), "Unauthenticated /mcp did not return the expected Bearer challenge.");
  console.log("PASS challenge: unauthenticated /mcp returned 401 with resource metadata.");

  let nextId = 1;
  let sessionId = "";
  const rpc = async (method, params, notification = false) => {
    const payload = { jsonrpc: "2.0", method, ...(params === undefined ? {} : { params }), ...(notification ? {} : { id: nextId++ }) };
    const response = await requestWithTimeout(endpoint, {
      method: "POST",
      headers: {
        authorization: `Bearer ${accessToken}`,
        accept: "application/json, text/event-stream",
        "content-type": "application/json",
        "mcp-protocol-version": "2025-06-18",
        ...(sessionId ? { "mcp-session-id": sessionId } : {}),
      },
      body: JSON.stringify(payload),
    }, timeoutMs);
    assert(response.ok, `${method} returned HTTP ${response.status}.`);
    sessionId = response.headers.get("mcp-session-id") || sessionId;
    const text = await response.text();
    if (notification || response.status === 202) return undefined;
    const message = decodeJsonRpcBody(text);
    assert(!message?.error, `${method} returned JSON-RPC error ${message?.error?.code ?? "unknown"}.`);
    return message;
  };

  const initialized = await rpc("initialize", {
    protocolVersion: "2025-06-18",
    capabilities: {},
    clientInfo: { name: "oauth-gateway-generic-smoke", version: "1.0.0" },
  });
  assert(typeof initialized?.result?.protocolVersion === "string", "initialize did not return a protocolVersion.");
  await rpc("notifications/initialized", undefined, true);
  console.log(`PASS initialize: protocol ${initialized.result.protocolVersion}.`);

  const listed = await rpc("tools/list", {});
  assert(Array.isArray(listed?.result?.tools) && listed.result.tools.length > 0, "tools/list returned no tools.");
  assert(listed.result.tools.some((tool) => tool.name === toolName), `Smoke tool ${toolName} is not exposed.`);
  console.log(`PASS tools/list: ${listed.result.tools.length} tool(s) exposed.`);

  const called = await rpc("tools/call", { name: toolName, arguments: toolArguments });
  assert(called?.result && called.result.isError !== true, `${toolName} returned an MCP tool error.`);
  console.log(`PASS tools/call: ${toolName}.`);
  console.log("PASS generic OAuth MCP smoke verification.");
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  runSmoke().catch((error) => {
    console.error(`FAIL ${error instanceof Error ? error.message : String(error)}`);
    process.exitCode = 1;
  });
}
