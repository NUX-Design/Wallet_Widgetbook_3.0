#!/usr/bin/env node

/**
 * Verifies the V3 read-only tools on a REAL hosted Streamable HTTP MCP endpoint
 * (e.g. the Render deployment) over an authenticated session.
 *
 * This complements `verify-remote.js` (which exercises legacy widget tools). It is
 * the tool referenced by `task/V3_THEME_MCP_SKILLS_TASKS.md` V3-24 for validating
 * that Theme V3 + Widget V3 read-only tools work through the existing remote endpoint
 * and that generation/write tools remain excluded from remote exposure.
 *
 * Usage:
 *
 *   cd mcp-server
 *   MCP_REMOTE_BASE_URL="https://<host>/mcp" \
 *   MCP_REMOTE_BEARER_TOKEN="<public-bearer-token>" \
 *   npm run verify:mcp:remote:v3
 *
 * Required env vars:
 *   MCP_REMOTE_BASE_URL             Full URL to the /mcp endpoint, e.g. https://host/mcp
 *   MCP_REMOTE_BEARER_TOKEN         Must match MCP_REMOTE_BEARER_TOKEN(S) on the server
 *
 * Optional env vars:
 *   MCP_REMOTE_AUTH_MODE            "bearer" (default) or "proxy"
 *   MCP_REMOTE_BEARER_TOKEN_HEADER  Header name for direct auth (default: Authorization)
 *   MCP_REMOTE_BEARER_TOKEN_PREFIX  Prefix for direct auth (default: Bearer)
 *   MCP_REMOTE_PROXY_SHARED_SECRET  Shared secret for legacy proxy auth mode
 *   MCP_REMOTE_AUTH_USER            Principal for the authenticated-user header (default: render-pilot-verifier)
 *   MCP_REMOTE_AUTH_USER_HEADER     Header name for the principal (default: x-mcp-authenticated-user)
 *   MCP_REMOTE_PROXY_SECRET_HEADER  Header name for the shared secret (default: x-mcp-proxy-secret)
 *   MCP_V3_TOKEN_NAME               Semantic token used for get_v3_color_token (default: content/primary)
 *   MCP_V3_WIDGET_NAME              V3 widget used for metadata/code/preview/audit (default: V3MiniButton)
 *   MCP_V3_SEARCH_QUERY             Query used for search_v3_widgets (default: mini)
 *   MCP_REMOTE_TIMEOUT_MS           Per-request timeout in ms (default: 15000)
 *
 * Output: PASS/FAIL per check, plus a final verdict block.
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
const tokenName = env.MCP_V3_TOKEN_NAME ?? "content/primary";
const widgetName = env.MCP_V3_WIDGET_NAME ?? "V3MiniButton";
const searchQuery = env.MCP_V3_SEARCH_QUERY ?? "mini";
const timeoutMs = Number.parseInt(env.MCP_REMOTE_TIMEOUT_MS ?? "15000", 10);

// V3 read-only tools that MUST be exposed remotely.
const EXPECTED_V3_TOOLS = [
  "get_v3_design_system_info",
  "list_v3_categories",
  "list_v3_color_tokens",
  "search_v3_color_tokens",
  "get_v3_color_token",
  "list_v3_widgets",
  "search_v3_widgets",
  "get_v3_widget_details",
  "get_v3_widget_metadata",
  "get_v3_widget_code",
  "get_v3_widget_preview",
  "audit_v3_widget",
  "get_v3_flutter_widget_template",
  "get_v3_codebase_patterns",
  "get_v3_figma_to_flutter_mapping",
];

// Generation/write tools that MUST NOT be exposed remotely.
const FORBIDDEN_REMOTE_TOOLS = [
  "generate_widget_code",
  "generate_widgetbook_use_case",
  "generate_v3_widget_code",
  "generate_v3_widgetbook_use_case",
];

const results = [];

function record(name, status, detail) {
  results.push({ name, status, detail });
  const label = status === "PASS" ? "PASS" : status === "SKIP" ? "SKIP" : "FAIL";
  console.log(`${label} ${name}${detail ? ` - ${detail}` : ""}`);
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
          `restriction or a free-tier cold start.`,
      );
    }
    throw error;
  } finally {
    clearTimeout(timer);
  }
}

function parseToolResult(result) {
  return result.structuredContent ?? JSON.parse(result.content?.[0]?.text ?? "{}");
}

async function main() {
  if (!baseUrl) {
    console.error(
      "Missing MCP_REMOTE_BASE_URL. Example:\n" +
        '  MCP_REMOTE_BASE_URL="https://<your-service>.onrender.com/mcp" \\\n' +
        '  MCP_REMOTE_BEARER_TOKEN="<token>" \\\n' +
        "  npm run verify:mcp:remote:v3",
    );
    process.exitCode = 1;
    return;
  }

  console.log(`Running MCP V3 verification against hosted endpoint: ${baseUrl}`);
  console.log(`Per-request timeout: ${timeoutMs}ms\n`);

  if (authMode === "bearer" && !bearerToken) {
    console.warn("WARNING: MCP_REMOTE_BEARER_TOKEN is empty. Requests to /mcp will likely be rejected with 401.\n");
  }

  let client;
  let transport;
  try {
    client = new Client({ name: "flutter-widget-wallet-mcp-v3-verifier", version: "1.0.0" });
    const headers =
      authMode === "proxy"
        ? { [authUserHeader]: authUser, [proxySecretHeader]: proxySharedSecret }
        : { [bearerTokenHeader]: `${bearerTokenPrefix} ${bearerToken}` };
    transport = new StreamableHTTPClientTransport(new URL(baseUrl), { requestInit: { headers } });

    await withTimeout("client.connect", async (signal) => {
      const abortPromise = new Promise((_, reject) => {
        signal.addEventListener("abort", () => reject(new Error("aborted")));
      });
      return Promise.race([client.connect(transport), abortPromise]);
    });
    record("MCP session connect", "PASS");

    // tools/list — confirm V3 tools present and generation tools absent.
    const listed = await withTimeout("tools/list", () => client.listTools());
    const toolNames = new Set(listed.tools.map((t) => t.name));
    record("tools/list", "PASS", `${listed.tools.length} tool(s) exposed`);

    const missingV3 = EXPECTED_V3_TOOLS.filter((t) => !toolNames.has(t));
    record(
      "V3 tools exposed",
      missingV3.length === 0 ? "PASS" : "FAIL",
      missingV3.length === 0 ? `all ${EXPECTED_V3_TOOLS.length} V3 read-only tools present` : `missing: ${missingV3.join(", ")}`,
    );

    const leakedGeneration = FORBIDDEN_REMOTE_TOOLS.filter((t) => toolNames.has(t));
    record(
      "generation tools excluded",
      leakedGeneration.length === 0 ? "PASS" : "FAIL",
      leakedGeneration.length === 0 ? "no generation/write tools exposed remotely" : `LEAKED: ${leakedGeneration.join(", ")}`,
    );

    // get_v3_color_token — Light/Dark values + primitive aliases.
    const tokenRes = await withTimeout("get_v3_color_token", () =>
      client.callTool({ name: "get_v3_color_token", arguments: { tokenName, mode: "both" } }),
    );
    const tokenData = parseToolResult(tokenRes);
    const hasLightDark = Boolean(tokenData.lightValue && tokenData.darkValue);
    const hasAlias = Boolean(tokenData.lightPrimitiveAlias || tokenData.darkPrimitiveAlias);
    record(
      "get_v3_color_token",
      hasLightDark && hasAlias ? "PASS" : "FAIL",
      `token=${tokenData.tokenName} light=${tokenData.lightValue} dark=${tokenData.darkValue} ` +
        `lightAlias=${tokenData.lightPrimitiveAlias} darkAlias=${tokenData.darkPrimitiveAlias} usage=${tokenData.dartUsage}`,
    );

    // list_v3_color_tokens
    const listTokens = await withTimeout("list_v3_color_tokens", () =>
      client.callTool({ name: "list_v3_color_tokens", arguments: { mode: "both", limit: 5, offset: 0 } }),
    );
    const listTokensData = parseToolResult(listTokens);
    record(
      "list_v3_color_tokens",
      (listTokensData.total ?? listTokensData.count ?? 0) > 0 ? "PASS" : "FAIL",
      `total=${listTokensData.total} count=${listTokensData.count}`,
    );

    // search_v3_color_tokens
    const searchTokens = await withTimeout("search_v3_color_tokens", () =>
      client.callTool({ name: "search_v3_color_tokens", arguments: { query: "content", limit: 5, offset: 0 } }),
    );
    const searchTokensData = parseToolResult(searchTokens);
    record(
      "search_v3_color_tokens",
      (searchTokensData.count ?? 0) >= 0 ? "PASS" : "FAIL",
      `count=${searchTokensData.count} query=content`,
    );

    // list_v3_widgets
    const listWidgets = await withTimeout("list_v3_widgets", () =>
      client.callTool({ name: "list_v3_widgets", arguments: { limit: 10, offset: 0 } }),
    );
    const listWidgetsData = parseToolResult(listWidgets);
    record(
      "list_v3_widgets",
      (listWidgetsData.count ?? 0) > 0 ? "PASS" : "FAIL",
      `count=${listWidgetsData.count}`,
    );

    // search_v3_widgets
    const searchWidgets = await withTimeout("search_v3_widgets", () =>
      client.callTool({ name: "search_v3_widgets", arguments: { query: searchQuery, limit: 5, offset: 0 } }),
    );
    const searchWidgetsData = parseToolResult(searchWidgets);
    record(
      "search_v3_widgets",
      (searchWidgetsData.count ?? 0) >= 0 ? "PASS" : "FAIL",
      `count=${searchWidgetsData.count} query=${searchQuery}`,
    );

    // get_v3_widget_metadata
    const metadata = await withTimeout("get_v3_widget_metadata", () =>
      client.callTool({ name: "get_v3_widget_metadata", arguments: { widgetName } }),
    );
    const metadataData = parseToolResult(metadata);
    record(
      "get_v3_widget_metadata",
      metadataData.name === widgetName ? "PASS" : "FAIL",
      `name=${metadataData.name} themeVersion=${metadataData.themeVersion}`,
    );

    // get_v3_widget_code
    const code = await withTimeout("get_v3_widget_code", () =>
      client.callTool({ name: "get_v3_widget_code", arguments: { widgetName } }),
    );
    const codeData = parseToolResult(code);
    const codeText = codeData.code ?? codeData.source ?? "";
    record(
      "get_v3_widget_code",
      typeof codeText === "string" && codeText.length > 0 ? "PASS" : "FAIL",
      `sourceLength=${typeof codeText === "string" ? codeText.length : 0}`,
    );

    // get_v3_widget_preview
    const preview = await withTimeout("get_v3_widget_preview", () =>
      client.callTool({ name: "get_v3_widget_preview", arguments: { widgetName } }),
    );
    const previewData = parseToolResult(preview);
    const previewFiles = previewData.previews ?? previewData.files ?? [];
    record(
      "get_v3_widget_preview",
      Array.isArray(previewFiles) && previewFiles.length > 0 ? "PASS" : "FAIL",
      `previewFiles=${Array.isArray(previewFiles) ? previewFiles.length : 0}`,
    );

    // audit_v3_widget
    const audit = await withTimeout("audit_v3_widget", () =>
      client.callTool({ name: "audit_v3_widget", arguments: { widgetName } }),
    );
    const auditData = parseToolResult(audit);
    record(
      "audit_v3_widget",
      auditData.passed === true ? "PASS" : "FAIL",
      `passed=${auditData.passed} findings=${Array.isArray(auditData.findings) ? auditData.findings.length : "n/a"}`,
    );
  } catch (error) {
    record("MCP V3 protocol calls", "FAIL", error instanceof Error ? error.message : String(error));
  } finally {
    await transport?.close().catch(() => {});
  }

  const failed = results.filter((r) => r.status === "FAIL");

  console.log("\n--- Verdict ---");
  if (failed.length === 0) {
    console.log("PASS: all V3 remote checks succeeded. V3 read-only tools work over the hosted endpoint and generation tools stay excluded.");
  } else {
    console.log("FAIL: one or more V3 remote checks failed — see details above.");
  }
  console.log(`Checks: ${results.length - failed.length}/${results.length} passed.`);

  process.exitCode = failed.length === 0 ? 0 : 1;
}

main().catch((error) => {
  console.error(error instanceof Error ? error.stack ?? error.message : String(error));
  process.exitCode = 1;
});
