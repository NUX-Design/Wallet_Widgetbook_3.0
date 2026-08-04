import assert from "node:assert/strict";
import { once } from "node:events";
import test from "node:test";
import { createGatewayServer } from "../src/server.js";

function config(overrides = {}) {
  return {
    publicOrigin: "https://gateway.example.com",
    resource: "https://gateway.example.com/mcp",
    metadataUrl: "https://gateway.example.com/.well-known/oauth-protected-resource",
    issuer: "https://tenant.example.com/",
    requiredScope: "mcp:read",
    upstreamUrl: "https://upstream.example.com/mcp",
    upstreamBearer: "gateway-only-secret",
    bodyLimitBytes: 1024,
    upstreamHeaderTimeoutMs: 5_000,
    upstreamIdleTimeoutMs: 5_000,
    rateWindowMs: 60_000,
    ratePerIdentity: 100,
    rateGlobal: 100,
    rateMaxKeys: 1_000,
    sessionTtlMs: 60_000,
    sessionMaxEntries: 100,
    sessionMaxPerIdentity: 10,
    allowedOrigins: new Set(),
    trustProxy: true,
    allowInsecureLocal: false,
    ...overrides,
  };
}

const owner = { issuer: "https://tenant.example.com/", subject: "owner", clientId: "gemini" };

async function start(options = {}) {
  const server = createGatewayServer({
    config: config(options.config),
    verifyToken: options.verifyToken ?? (async () => owner),
    fetchImpl: options.fetchImpl ?? (async () => new Response("ok", { status: 200 })),
    audit: options.audit ?? (() => {}),
  });
  server.listen(0, "127.0.0.1");
  await once(server, "listening");
  const { port } = server.address();
  return {
    server,
    request(path, init = {}) {
      return fetch(`http://127.0.0.1:${port}${path}`, {
        ...init,
        headers: { "x-forwarded-proto": "https", ...(init.headers ?? {}) },
      });
    },
  };
}

test("publishes RFC 9728 protected resource metadata", async (t) => {
  const app = await start();
  t.after(() => app.server.close());
  const response = await app.request("/.well-known/oauth-protected-resource");
  assert.equal(response.status, 200);
  assert.deepEqual(await response.json(), {
    resource: "https://gateway.example.com/mcp",
    authorization_servers: ["https://tenant.example.com/"],
    scopes_supported: ["mcp:read"],
    bearer_methods_supported: ["header"],
  });
  const pathAware = await app.request("/.well-known/oauth-protected-resource/mcp");
  assert.equal(pathAware.status, 200);
  assert.deepEqual(await pathAware.json(), await (await app.request("/.well-known/oauth-protected-resource")).json());
});

test("challenges unauthenticated MCP requests with resource metadata", async (t) => {
  const app = await start({ verifyToken: async () => { throw new Error("missing_token"); } });
  t.after(() => app.server.close());
  const response = await app.request("/mcp", { method: "POST" });
  assert.equal(response.status, 401);
  assert.match(response.headers.get("www-authenticate"), /resource_metadata="https:\/\/gateway\.example\.com\/\.well-known\/oauth-protected-resource"/);
  assert.doesNotMatch(response.headers.get("www-authenticate"), /error=/);
  assert.equal(response.headers.get("access-control-allow-origin"), null);
});

test("returns 403 for authenticated identities without scope or allowlist access", async (t) => {
  for (const reason of ["insufficient_scope", "invalid_subject", "invalid_client"]) {
    const app = await start({ verifyToken: async () => { throw new Error(reason); } });
    t.after(() => app.server.close());
    const response = await app.request("/mcp", { method: "GET", headers: { authorization: "Bearer valid-but-forbidden" } });
    assert.equal(response.status, 403);
    assert.match(response.headers.get("www-authenticate"), reason === "insufficient_scope" ? /error="insufficient_scope"/ : /^Bearer resource_metadata=/);
    if (reason !== "insufficient_scope") assert.doesNotMatch(response.headers.get("www-authenticate"), /error=/);
  }
});

test("forwards original JSON-RPC bytes and only approved headers", async (t) => {
  const original = Buffer.from('{ "jsonrpc": "2.0", "method": "tools/call", "params": { "repo": "safe", "target": "x" }, "id": 1 }');
  let captured;
  const app = await start({
    fetchImpl: async (url, init) => {
      captured = { url, init, body: Buffer.from(init.body) };
      return new Response("event: message\ndata: {}\n\n", {
        status: 200,
        headers: {
          "content-type": "text/event-stream",
          "set-cookie": "leak=true",
          "x-mcp-proxy-secret": "leak",
        },
      });
    },
  });
  t.after(() => app.server.close());
  const response = await app.request("/mcp?target=ignored", {
    method: "POST",
    headers: {
      authorization: "Bearer client-token",
      cookie: "client-cookie=true",
      "content-type": "application/json",
      accept: "application/json, text/event-stream",
      "mcp-protocol-version": "2025-06-18",
      "last-event-id": "event-7",
      "x-mcp-proxy-secret": "client-secret",
    },
    body: original,
  });

  assert.equal(response.status, 200);
  assert.equal(captured.url, "https://upstream.example.com/mcp");
  assert.deepEqual(captured.body, original);
  assert.equal(captured.init.headers.get("authorization"), "Bearer gateway-only-secret");
  assert.equal(captured.init.headers.get("cookie"), null);
  assert.equal(captured.init.headers.get("x-mcp-proxy-secret"), null);
  assert.equal(captured.init.headers.get("mcp-protocol-version"), "2025-06-18");
  assert.equal(captured.init.headers.get("last-event-id"), "event-7");
  assert.equal(response.headers.get("set-cookie"), null);
  assert.equal(response.headers.get("x-mcp-proxy-secret"), null);
  assert.equal(response.headers.get("cache-control"), "no-store");
});

test("rejects cross-identity MCP session reuse", async (t) => {
  const identities = {
    "Bearer owner": owner,
    "Bearer other": { ...owner, subject: "other" },
  };
  const app = await start({
    verifyToken: async (header) => identities[header],
    fetchImpl: async () => new Response('{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18"}}', { headers: { "mcp-session-id": "bound-session" } }),
  });
  t.after(() => app.server.close());

  const first = await app.request("/mcp", { method: "POST", headers: { authorization: "Bearer owner", "content-type": "application/json" }, body: '{"jsonrpc":"2.0","method":"initialize","id":1}' });
  assert.equal(first.status, 200);

  const second = await app.request("/mcp", { method: "GET", headers: { authorization: "Bearer other", "mcp-session-id": "bound-session" } });
  assert.equal(second.status, 403);
  assert.deepEqual(await second.json(), { error: "session_identity_mismatch" });
});

test("does not bind or expose a session from a failed initialize result", async (t) => {
  const app = await start({
    fetchImpl: async () => new Response('{"jsonrpc":"2.0","id":1,"error":{"code":-32603,"message":"failed"}}', {
      headers: { "content-type": "application/json", "mcp-session-id": "failed-session" },
    }),
  });
  t.after(() => app.server.close());
  const initialize = await app.request("/mcp", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: '{"jsonrpc":"2.0","method":"initialize","id":1}',
  });
  assert.equal(initialize.status, 200);
  assert.equal(initialize.headers.get("mcp-session-id"), null);

  const reuse = await app.request("/mcp", { method: "GET", headers: { "mcp-session-id": "failed-session" } });
  assert.equal(reuse.status, 404);
});

test("rejects unknown session IDs and only binds sessions issued by initialize", async (t) => {
  const app = await start({
    fetchImpl: async () => new Response("{}", { headers: { "mcp-session-id": "new-session" } }),
  });
  t.after(() => app.server.close());

  const unknown = await app.request("/mcp", { method: "GET", headers: { "mcp-session-id": "unknown" } });
  assert.equal(unknown.status, 404);
  assert.deepEqual(await unknown.json(), { error: "unknown_session" });

  const nonInitialize = await app.request("/mcp", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: '{"jsonrpc":"2.0","method":"tools/list","id":1}',
  });
  assert.equal(nonInitialize.status, 502);
  assert.deepEqual(await nonInitialize.json(), { error: "upstream_protocol_error" });
});

test("rejects invalid JSON-RPC and oversized requests", async (t) => {
  const app = await start({ config: { bodyLimitBytes: 32 } });
  t.after(() => app.server.close());

  const invalid = await app.request("/mcp", { method: "POST", body: "{}" });
  assert.equal(invalid.status, 400);
  assert.deepEqual(await invalid.json(), { error: "invalid_jsonrpc_shape" });

  const oversized = await app.request("/mcp", { method: "POST", body: "x".repeat(33) });
  assert.equal(oversized.status, 413);
});

test("rejects gateway routing overrides without inspecting tool arguments", async (t) => {
  const app = await start();
  t.after(() => app.server.close());
  const query = await app.request("/mcp?upstream=https://attacker.example.com/mcp", { method: "GET" });
  assert.equal(query.status, 400);
  assert.deepEqual(await query.json(), { error: "routing_override_forbidden" });

  const header = await app.request("/mcp", { method: "GET", headers: { "x-gateway-upstream": "https://attacker.example.com/mcp" } });
  assert.equal(header.status, 400);

  const validToolArgument = await app.request("/mcp", {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: '{"jsonrpc":"2.0","method":"tools/call","params":{"arguments":{"upstream":"a valid tool argument"}},"id":1}',
  });
  assert.equal(validToolArgument.status, 200);
});

test("does not expose authorization server endpoints and requires TLS", async (t) => {
  const app = await start();
  t.after(() => app.server.close());
  assert.equal((await app.request("/authorize")).status, 404);
  assert.equal((await app.request("/token", { method: "POST" })).status, 404);

  const { port } = app.server.address();
  const insecure = await fetch(`http://127.0.0.1:${port}/mcp`);
  assert.equal(insecure.status, 400);
  assert.deepEqual(await insecure.json(), { error: "https_required" });
});

test("rejects browser origins unless they are exact allowlist matches", async (t) => {
  const app = await start({ config: { allowedOrigins: new Set(["https://allowed.example.com"]) } });
  t.after(() => app.server.close());
  assert.equal((await app.request("/mcp", { method: "GET", headers: { origin: "https://evil.example.com" } })).status, 403);
  assert.equal((await app.request("/mcp", { method: "GET", headers: { origin: "null" } })).status, 403);
  assert.equal((await app.request("/mcp", { method: "GET", headers: { origin: "not a url" } })).status, 403);
  assert.equal((await app.request("/mcp", { method: "GET", headers: { origin: "https://allowed.example.com" } })).status, 200);
});

test("keeps active SSE alive beyond header timeout and cancels on client disconnect", async (t) => {
  let cancelled = false;
  let timer;
  const stream = new ReadableStream({
    start(controller) {
      let count = 0;
      timer = setInterval(() => {
        controller.enqueue(new TextEncoder().encode(`event: message\ndata: ${count}\n\n`));
        count += 1;
        if (count === 20) {
          clearInterval(timer);
          controller.close();
        }
      }, 10);
    },
    cancel() {
      cancelled = true;
      clearInterval(timer);
    },
  });
  const app = await start({
    config: { upstreamHeaderTimeoutMs: 20, upstreamIdleTimeoutMs: 100 },
    fetchImpl: async () => new Response(stream, { headers: { "content-type": "text/event-stream" } }),
  });
  t.after(() => app.server.close());

  const controller = new AbortController();
  const response = await app.request("/mcp", { method: "GET", signal: controller.signal });
  const reader = response.body.getReader();
  assert.equal((await reader.read()).done, false);
  await new Promise((resolve) => setTimeout(resolve, 50));
  assert.equal((await reader.read()).done, false);
  controller.abort();
  await new Promise((resolve) => setTimeout(resolve, 20));
  assert.equal(cancelled, true);
});

test("aborts an upstream that does not return headers in time", async (t) => {
  const app = await start({
    config: { upstreamHeaderTimeoutMs: 20 },
    fetchImpl: async (_url, init) => new Promise((_resolve, reject) => {
      init.signal.addEventListener("abort", () => reject(init.signal.reason), { once: true });
    }),
  });
  t.after(() => app.server.close());
  const response = await app.request("/mcp", { method: "GET" });
  assert.equal(response.status, 502);
  assert.deepEqual(await response.json(), { error: "upstream_unavailable" });
});

test("aborts a stalled SSE stream after the configured idle timeout", async (t) => {
  let cancelled = false;
  const stream = new ReadableStream({
    start(controller) {
      controller.enqueue(new TextEncoder().encode("event: message\ndata: first\n\n"));
    },
    cancel() {
      cancelled = true;
    },
  });
  const app = await start({
    config: { upstreamIdleTimeoutMs: 20 },
    fetchImpl: async () => new Response(stream, { headers: { "content-type": "text/event-stream" } }),
  });
  t.after(() => app.server.close());
  const response = await app.request("/mcp", { method: "GET" });
  const reader = response.body.getReader();
  assert.equal((await reader.read()).done, false);
  await assert.rejects(reader.read());
  assert.equal(cancelled, true);
});

test("redacts audit fields marked as secrets", async (t) => {
  const events = [];
  const app = await start({ audit: (event, fields) => events.push({ event, fields }) });
  t.after(() => app.server.close());
  await app.request("/mcp", { method: "GET", headers: { authorization: "Bearer client" } });
  assert.ok(events.some(({ event }) => event === "gateway.request_completed"));
  assert.equal(JSON.stringify(events).includes("gateway-only-secret"), false);
  assert.equal(JSON.stringify(events).includes("Bearer client"), false);
});
