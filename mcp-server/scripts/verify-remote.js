#!/usr/bin/env node

/**
 * Verifies a REAL hosted Streamable HTTP MCP endpoint (e.g. a Render pilot deployment).
 *
 * Unlike `verify-http.js` (which spins up its own local server and tests against
 * itself), this script only makes outbound requests to a URL you provide. It is the
 * tool referenced by `task/TASKS.md` P8-02 for validating the Render hosting pilot,
 * including whether cold-start/free-tier behavior breaks `StreamableHTTPServerTransport`.
 *
 * Usage:
 *
 *   cd mcp-server
 *   MCP_REMOTE_BASE_URL="https://<host>/mcp" \
 *   MCP_REMOTE_BEARER_TOKEN="<public-bearer-token>" \
 *   MCP_REMOTE_REFRESH_TOKEN="<same-refresh-token>" \
 *   npm run verify:mcp:remote
 *
 * Required env vars:
 *   MCP_REMOTE_BASE_URL             Full URL to the /mcp endpoint, e.g. https://host/mcp
 *   MCP_REMOTE_BEARER_TOKEN         Must match MCP_REMOTE_BEARER_TOKEN(S) on the server
 *
 * Optional env vars:
 *   MCP_REMOTE_AUTH_MODE            "bearer" (default) or "proxy"
 *   MCP_REMOTE_BEARER_TOKEN_HEADER  Header name for direct auth (default: Authorization)
 *   MCP_REMOTE_BEARER_TOKEN_PREFIX  Prefix for direct auth (default: Bearer)
 *   MCP_REMOTE_AUTH_USER            Principal to send as the authenticated-user header (default: render-pilot-verifier)
 *   MCP_REMOTE_AUTH_USER_HEADER     Header name for the principal (default: x-mcp-authenticated-user)
 *   MCP_REMOTE_PROXY_SECRET_HEADER  Header name for the shared secret (default: x-mcp-proxy-secret)
 *   MCP_REMOTE_REFRESH_TOKEN        If set, also exercises POST /admin/refresh
 *   MCP_REMOTE_REFRESH_TOKEN_HEADER Header name for the refresh token (default: x-mcp-refresh-token)
 *   MCP_REMOTE_CATEGORY             Category used for list_widgets smoke check (default: button)
 *   MCP_REMOTE_WIDGET_NAME          Widget name used for get_widget_metadata smoke check (default: Buttons)
 *   MCP_REMOTE_SEARCH_QUERY         Query used for search_widgets smoke check (default: button)
 *   MCP_REMOTE_TIMEOUT_MS           Per-request timeout in ms before treating a call as a held-connection hang (default: 15000)
 *
 * Output: PASS/FAIL per check, plus a final verdict block summarizing whether the
 * endpoint is viable for production per the Phase 8 validation checklist.
 */

import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";

const env = process.env;

const baseUrl = env.MCP_REMOTE_BASE_URL;
const authMode = env.MCP_REMOTE_AUTH_MODE ?? "bearer";
const bearerToken = env.MCP_REMOTE_BEARER_TOKEN ?? "";
const bearerTokenHeader = env.MCP_REMOTE_BEARER_TOKEN_HEADER ?? "Authorization";
const bearerTokenPrefix = env.MCP_REMOTE_BEARER_TOKEN_PREFIX ?? "Bearer";
const proxySharedSecret = env.MCP_REMOTE_PROXY_SHARED_SECRET ?? "";
const authUser = env.MCP_REMOTE_AUTH_USER ?? "render-pilot-verifier";
const authUserHeader = env.MCP_REMOTE_AUTH_USER_HEADER ?? "x-mcp-authenticated-user";
const proxySecretHeader = env.MCP_REMOTE_PROXY_SECRET_HEADER ?? "x-mcp-proxy-secret";
const refreshToken = env.MCP_REMOTE_REFRESH_TOKEN ?? "";
const refreshTokenHeader = env.MCP_REMOTE_REFRESH_TOKEN_HEADER ?? "x-mcp-refresh-token";
const category = env.MCP_REMOTE_CATEGORY ?? "button";
const widgetName = env.MCP_REMOTE_WIDGET_NAME ?? "Buttons";
const searchQuery = env.MCP_REMOTE_SEARCH_QUERY ?? "button";
const timeoutMs = Number.parseInt(env.MCP_REMOTE_TIMEOUT_MS ?? "15000", 10);

const results = [];

function record(name, status, detail) {
  results.push({ name, status, detail });
  const label = status === "PASS" ? "PASS" : status === "SKIP" ? "SKIP" : "FAIL";
  console.log(`${label} ${name}${detail ? ` - ${detail}` : ""}`);
}

function deriveHttpUrl(pathname) {
  const url = new URL(baseUrl);
  url.pathname = pathname;
  url.search = "";
  return url.toString();
}

async function withTimeout(label, promiseFactory) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await promiseFactory(controller.signal);
  } catch (error) {
    if (controller.signal.aborted) {
      throw new Error(
        `${label} did not respond within ${timeoutMs}ms. This is the signature of a held-connection ` +
          `restriction (free-tier platforms sometimes drop long-lived/streaming HTTP connections).`,
      );
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

async function checkHttpJson(name, pathname, init = {}) {
  const url = deriveHttpUrl(pathname);
  try {
    const response = await withTimeout(name, (signal) => fetch(url, { ...init, signal }));
    const payload = await response.json().catch(() => undefined);
    if (!response.ok) {
      record(name, "FAIL", `HTTP ${response.status} at ${url}: ${JSON.stringify(payload)}`);
      return { ok: false, payload, status: response.status };
    }
    record(name, "PASS", `HTTP ${response.status} at ${url}`);
    return { ok: true, payload, status: response.status };
  } catch (error) {
    record(name, "FAIL", error instanceof Error ? error.message : String(error));
    return { ok: false, error };
  }
}

async function main() {
  if (!baseUrl) {
    console.error(
      "Missing MCP_REMOTE_BASE_URL. Example:\n" +
        '  MCP_REMOTE_BASE_URL="https://<your-service>.onrender.com/mcp" \\\n' +
        '  MCP_REMOTE_BEARER_TOKEN="<token>" \\\n' +
        "  npm run verify:mcp:remote",
    );
    process.exitCode = 1;
    return;
  }

  console.log(`Running MCP Streamable HTTP verification against hosted endpoint: ${baseUrl}`);
  console.log(`Per-request timeout: ${timeoutMs}ms (used to detect held-connection issues)\n`);

  if (authMode === "bearer" && !bearerToken) {
    console.warn(
      "WARNING: MCP_REMOTE_BEARER_TOKEN is empty. Requests to /mcp will likely be rejected with 401 " +
        "unless the server has MCP_REMOTE_BEARER_TOKEN(S) configured differently.\n",
    );
  }

  if (authMode === "proxy" && !proxySharedSecret) {
    console.warn(
      "WARNING: MCP_REMOTE_PROXY_SHARED_SECRET is empty. Legacy trusted-proxy requests to /mcp will likely be rejected with 401.\n",
    );
  }

  // 1. /health — should be reachable anonymously by default.
  const health = await checkHttpJson("GET /health", "/health");

  // 2. /info — should be reachable anonymously by default and expose freshness metadata.
  const info = await checkHttpJson("GET /info", "/info");
  if (info.ok && info.payload) {
    console.log(
      `       commitSha=${info.payload.freshness?.commitSha} channel=${info.payload.targeting?.channel} ` +
        `namespace=${info.payload.targeting?.namespace}`,
    );
  }

  // 3. MCP protocol calls over the streamable-http transport (this is the part most
  //    likely to fail under a held-connection restriction, since the SDK transport
  //    relies on a persistent HTTP request/response cycle per call).
  let client;
  let transport;
  try {
    client = new Client({ name: "flutter-widget-wallet-mcp-remote-verifier", version: "1.0.0" });
    const headers =
      authMode === "proxy"
        ? {
            [authUserHeader]: authUser,
            [proxySecretHeader]: proxySharedSecret,
          }
        : {
            [bearerTokenHeader]: `${bearerTokenPrefix} ${bearerToken}`,
          };
    transport = new StreamableHTTPClientTransport(new URL(baseUrl), {
      requestInit: {
        headers,
      },
    });

    await withTimeout("client.connect", async (signal) => {
      const controllerPromise = client.connect(transport);
      const abortPromise = new Promise((_, reject) => {
        signal.addEventListener("abort", () => reject(new Error("aborted")));
      });
      return Promise.race([controllerPromise, abortPromise]);
    });
    record("MCP session connect", "PASS");

    const listedTools = await withTimeout("tools/list", () => client.listTools());
    record("tools/list", "PASS", `${listedTools.tools.length} tool(s) exposed`);

    const widgets = await withTimeout("list_widgets", () =>
      client.callTool({ name: "list_widgets", arguments: { category, limit: 5, offset: 0 } }),
    );
    const widgetsData = widgets.structuredContent ?? JSON.parse(widgets.content?.[0]?.text ?? "{}");
    record("list_widgets", widgetsData.count > 0 ? "PASS" : "FAIL", `count=${widgetsData.count} category=${category}`);

    const search = await withTimeout("search_widgets", () =>
      client.callTool({ name: "search_widgets", arguments: { query: searchQuery, limit: 5, offset: 0 } }),
    );
    const searchData = search.structuredContent ?? JSON.parse(search.content?.[0]?.text ?? "{}");
    record("search_widgets", searchData.count >= 0 ? "PASS" : "FAIL", `count=${searchData.count} query=${searchQuery}`);

    const metadata = await withTimeout("get_widget_metadata", () =>
      client.callTool({ name: "get_widget_metadata", arguments: { widgetName } }),
    );
    const metadataData = metadata.structuredContent ?? JSON.parse(metadata.content?.[0]?.text ?? "{}");
    record(
      "get_widget_metadata",
      metadataData.name === widgetName ? "PASS" : "FAIL",
      `name=${metadataData.name}`,
    );
  } catch (error) {
    record("MCP protocol calls", "FAIL", error instanceof Error ? error.message : String(error));
  } finally {
    await transport?.close().catch(() => {});
  }

  // 4. /admin/refresh — only if a refresh token was provided, since it mutates state.
  if (refreshToken) {
    await checkHttpJson("POST /admin/refresh", "/admin/refresh", {
      method: "POST",
      headers: { [refreshTokenHeader]: refreshToken },
    });
  } else {
    record("POST /admin/refresh", "SKIP", "MCP_REMOTE_REFRESH_TOKEN not provided");
  }

  const failed = results.filter((r) => r.status === "FAIL");
  const heldConnectionSuspect = failed.some((r) => /held-connection|did not respond within/i.test(r.detail ?? ""));

  console.log("\n--- Verdict ---");
  if (failed.length === 0) {
    console.log("PASS: all checks succeeded. No evidence of a held-connection restriction on this endpoint.");
  } else if (heldConnectionSuspect) {
    console.log(
      "FAIL: one or more checks timed out. This could be Render free-tier cold-start (spin-up takes up to " +
        "~1 minute after 15 min idle per render.com/docs/free) rather than a held-connection restriction — " +
        "retry once after warming the instance, then see RENDER_HOSTING_PLAN.md section 7 if it persists.",
    );
  } else {
    console.log("FAIL: one or more checks failed for reasons other than a timeout — see details above.");
  }
  console.log(`Checks: ${results.length - failed.length}/${results.length} passed.`);

  process.exitCode = failed.length === 0 ? 0 : 1;
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack ?? error.message : String(error));
  process.exitCode = 1;
});
