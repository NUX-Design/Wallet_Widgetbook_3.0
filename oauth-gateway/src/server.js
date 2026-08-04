import { createServer } from "node:http";
import { Readable, Transform } from "node:stream";
import { pipeline } from "node:stream/promises";
import { clientResponseHeaders, upstreamHeaders } from "./headers.js";
import { createAuditLogger, FixedWindowLimiter, identityHash, SessionBindings } from "./security.js";

const MCP_METHODS = new Set(["GET", "POST", "DELETE"]);
const ROUTING_QUERY_KEYS = new Set(["upstream", "upstreamUrl", "url", "endpoint", "destination", "proxy"]);
const ROUTING_HEADERS = ["x-gateway-upstream", "x-mcp-upstream-url", "x-proxy-destination"];

function sendJson(res, status, payload, headers = {}) {
  res.writeHead(status, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store", ...headers });
  res.end(`${JSON.stringify(payload)}\n`);
}

async function readBody(req, limit) {
  const chunks = [];
  let size = 0;
  for await (const chunk of req) {
    size += chunk.length;
    if (size > limit) {
      const error = new Error("request_too_large");
      error.statusCode = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks);
}

function validateJsonRpc(body) {
  if (body.length === 0) return;
  let parsed;
  try {
    parsed = JSON.parse(body.toString("utf8"));
  } catch {
    const error = new Error("invalid_json");
    error.statusCode = 400;
    throw error;
  }
  const messages = Array.isArray(parsed) ? parsed : [parsed];
  if (messages.length === 0 || messages.some((message) => !message || message.jsonrpc !== "2.0" || typeof message.method !== "string")) {
    const error = new Error("invalid_jsonrpc_shape");
    error.statusCode = 400;
    throw error;
  }
  return messages.map((message) => message.method);
}

function requestIsSecure(req, config) {
  if (config.allowInsecureLocal && ["127.0.0.1", "localhost"].includes(req.socket.localAddress)) return true;
  if (req.socket.encrypted) return true;
  if (!config.trustProxy) return false;
  return String(req.headers["x-forwarded-proto"] ?? "").split(",")[0].trim().toLowerCase() === "https";
}

function clientIp(req, config) {
  if (config.trustProxy) {
    const forwarded = String(req.headers["x-forwarded-for"] ?? "").split(",")[0].trim();
    if (forwarded) return forwarded;
  }
  return req.socket.remoteAddress ?? "unknown";
}

function hasRoutingOverride(req, url) {
  return [...url.searchParams.keys()].some((key) => ROUTING_QUERY_KEYS.has(key)) ||
    ROUTING_HEADERS.some((name) => req.headers[name] !== undefined);
}

function originAllowed(req, config) {
  const raw = req.headers.origin;
  if (raw === undefined) return true;
  if (Array.isArray(raw) || raw === "null" || raw.includes(",")) return false;
  try {
    const parsed = new URL(raw);
    return parsed.origin === raw && config.allowedOrigins.has(parsed.origin);
  } catch {
    return false;
  }
}

function idleWatchdog(timeoutMs, onTimeout) {
  let timer;
  const reset = () => {
    clearTimeout(timer);
    timer = setTimeout(onTimeout, timeoutMs);
    timer.unref();
  };
  const transform = new Transform({
    transform(chunk, encoding, callback) {
      reset();
      callback(null, chunk);
    },
    final(callback) {
      clearTimeout(timer);
      callback();
    },
    destroy(error, callback) {
      clearTimeout(timer);
      callback(error);
    },
  });
  reset();
  return transform;
}

async function readUpstreamBody(stream, limit, idleTimeoutMs) {
  if (!stream) return Buffer.alloc(0);
  const reader = stream.getReader();
  const chunks = [];
  let size = 0;
  try {
    while (true) {
      let timer;
      const timeout = new Promise((_, reject) => {
        timer = setTimeout(() => reject(new Error("upstream_idle_timeout")), idleTimeoutMs);
        timer.unref();
      });
      const { done, value } = await Promise.race([reader.read(), timeout]);
      clearTimeout(timer);
      if (done) break;
      size += value.byteLength;
      if (size > limit) throw new Error("upstream_response_too_large");
      chunks.push(Buffer.from(value));
    }
    return Buffer.concat(chunks);
  } finally {
    reader.releaseLock();
  }
}

function successfulInitializeBody(body) {
  const isInitializeResult = (payload) =>
    payload?.jsonrpc === "2.0" && !payload.error && typeof payload.result?.protocolVersion === "string";
  const text = body.toString("utf8").trim();

  try {
    return isInitializeResult(JSON.parse(text));
  } catch {
    // Streamable HTTP may encode a JSON-RPC response as an SSE `data` event.
    // Inspect complete events only; never infer success from arbitrary text.
    for (const event of text.split(/\r?\n\r?\n/)) {
      const data = event
        .split(/\r?\n/)
        .filter((line) => line.startsWith("data:"))
        .map((line) => line.slice(5).trimStart())
        .join("\n")
        .trim();
      if (!data || data === "[DONE]") continue;
      try {
        if (isInitializeResult(JSON.parse(data))) return true;
      } catch {
        // Ignore malformed/non-JSON SSE events and fail closed below.
      }
    }
    return false;
  }
}

export function createGatewayServer({ config, verifyToken, fetchImpl = fetch, audit = createAuditLogger(), sessions }) {
  const globalLimiter = new FixedWindowLimiter(config.rateWindowMs, config.rateGlobal, config.rateMaxKeys);
  const identityLimiter = new FixedWindowLimiter(config.rateWindowMs, config.ratePerIdentity, config.rateMaxKeys);
  const sessionBindings = sessions ?? new SessionBindings({
    ttlMs: config.sessionTtlMs,
    maxEntries: config.sessionMaxEntries,
    maxPerIdentity: config.sessionMaxPerIdentity,
  });

  return createServer(async (req, res) => {
    const url = new URL(req.url ?? "/", config.publicOrigin);

    if (req.method === "GET" && url.pathname === "/health") {
      return sendJson(res, 200, { ok: true, service: "flutter-widget-wallet-oauth-gateway", scaling: "single-instance" });
    }

    if (req.method === "GET" && ["/.well-known/oauth-protected-resource", "/.well-known/oauth-protected-resource/mcp"].includes(url.pathname)) {
      return sendJson(res, 200, {
        resource: config.resource,
        authorization_servers: [config.issuer],
        scopes_supported: [config.requiredScope],
        bearer_methods_supported: ["header"],
      });
    }

    if (url.pathname !== "/mcp") return sendJson(res, 404, { error: "not_found" });
    if (!MCP_METHODS.has(req.method)) return sendJson(res, 405, { error: "method_not_allowed" }, { allow: "GET, POST, DELETE" });
    if (!requestIsSecure(req, config)) return sendJson(res, 400, { error: "https_required" });
    if (!originAllowed(req, config)) return sendJson(res, 403, { error: "origin_forbidden" });
    if (hasRoutingOverride(req, url)) return sendJson(res, 400, { error: "routing_override_forbidden" });

    const ip = clientIp(req, config);
    if (!globalLimiter.take("global") || !identityLimiter.take(`ip:${ip}`)) {
      audit("gateway.rate_limited", { ip });
      return sendJson(res, 429, { error: "rate_limited" }, { "retry-after": "60" });
    }

    let identity;
    try {
      identity = await verifyToken(req.headers.authorization);
    } catch (error) {
      audit("gateway.auth_rejected", { reason: error.message, ip });
      const missing = error.message === "missing_token";
      const insufficientScope = error.message === "insufficient_scope";
      const forbiddenIdentity = ["invalid_subject", "invalid_client"].includes(error.message);
      const status = insufficientScope || forbiddenIdentity ? 403 : 401;
      const responseError = insufficientScope ? "insufficient_scope" : forbiddenIdentity ? "forbidden" : "invalid_token";
      const challengeError = missing || forbiddenIdentity ? "" : `, error="${responseError}"`;
      return sendJson(res, status, { error: responseError }, {
        "www-authenticate": `Bearer resource_metadata="${config.metadataUrl}"${challengeError}, scope="${config.requiredScope}"`,
      });
    }

    const identityId = identityHash(identity);
    if (!identityLimiter.take(`identity:${identityId}`)) {
      audit("gateway.rate_limited", { identity: identityId, ip });
      return sendJson(res, 429, { error: "rate_limited" }, { "retry-after": "60" });
    }

    const incomingSessionId = String(req.headers["mcp-session-id"] ?? "").trim();
    try {
      sessionBindings.assert(incomingSessionId, identity);
    } catch (error) {
      audit("gateway.session_rejected", { identity: identityId, ip, reason: error.code });
      return sendJson(res, error.statusCode, { error: error.code });
    }

    let body;
    let rpcMethods = [];
    try {
      body = req.method === "POST" ? await readBody(req, config.bodyLimitBytes) : undefined;
      if (req.method === "POST") rpcMethods = validateJsonRpc(body) ?? [];
    } catch (error) {
      return sendJson(res, error.statusCode ?? 400, { error: error.message });
    }

    const upstreamAbort = new AbortController();
    const abortOnDisconnect = () => {
      if (!res.writableEnded) upstreamAbort.abort(new Error("client_disconnected"));
    };
    req.once("aborted", abortOnDisconnect);
    res.once("close", abortOnDisconnect);
    const headerTimer = setTimeout(
      () => upstreamAbort.abort(new Error("upstream_header_timeout")),
      config.upstreamHeaderTimeoutMs,
    );
    headerTimer.unref();

    try {
      const upstream = await fetchImpl(config.upstreamUrl, {
        method: req.method,
        headers: upstreamHeaders(req.headers, config.upstreamBearer),
        body,
        redirect: "error",
        signal: upstreamAbort.signal,
      });
      clearTimeout(headerTimer);
      const responseSessionId = String(upstream.headers.get("mcp-session-id") ?? "").trim();
      const isInitialize = rpcMethods.includes("initialize");
      if (responseSessionId && !incomingSessionId) {
        if (!isInitialize || !upstream.ok) {
          upstreamAbort.abort(new Error("unexpected_session_id"));
          return sendJson(res, 502, { error: "upstream_protocol_error" });
        }
      } else if (responseSessionId && responseSessionId !== incomingSessionId) {
        upstreamAbort.abort(new Error("session_id_changed"));
        return sendJson(res, 502, { error: "upstream_protocol_error" });
      }
      if (req.method === "DELETE" && upstream.ok) sessionBindings.delete(incomingSessionId, identity);

      const responseHeaders = clientResponseHeaders(upstream.headers);
      if (isInitialize && !incomingSessionId) {
        const initializeBody = await readUpstreamBody(upstream.body, config.bodyLimitBytes, config.upstreamIdleTimeoutMs);
        if (!successfulInitializeBody(initializeBody)) {
          delete responseHeaders["mcp-session-id"];
          res.writeHead(upstream.status, responseHeaders);
          audit("gateway.initialize_rejected", { identity: identityId, status: upstream.status });
          return res.end(initializeBody);
        }
        try {
          sessionBindings.bind(responseSessionId, identity);
        } catch (error) {
          upstreamAbort.abort(error);
          return sendJson(res, error.statusCode ?? 502, { error: error.code ?? "upstream_protocol_error" });
        }
        res.writeHead(upstream.status, responseHeaders);
        audit("gateway.request_completed", { identity: identityId, method: req.method, status: upstream.status });
        return res.end(initializeBody);
      }

      res.writeHead(upstream.status, responseHeaders);
      audit("gateway.request_completed", { identity: identityId, method: req.method, status: upstream.status });
      if (!upstream.body) return res.end();
      const source = Readable.fromWeb(upstream.body);
      const watchdog = idleWatchdog(config.upstreamIdleTimeoutMs, () => {
        upstreamAbort.abort(new Error("upstream_idle_timeout"));
        source.destroy(new Error("upstream_idle_timeout"));
      });
      await pipeline(source, watchdog, res);
    } catch (error) {
      clearTimeout(headerTimer);
      audit("gateway.upstream_failed", { identity: identityId, reason: error.name });
      if (!res.headersSent) return sendJson(res, 502, { error: "upstream_unavailable" });
      res.destroy();
    }
  });
}
