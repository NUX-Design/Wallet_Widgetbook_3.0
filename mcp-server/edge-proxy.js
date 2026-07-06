#!/usr/bin/env node

import { createServer } from "node:http";
import { Readable } from "node:stream";

function getEnv(name, fallback = "") {
  return process.env[name]?.trim() || fallback;
}

function parseInteger(value, fallback) {
  const parsed = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function firstHeader(value) {
  if (Array.isArray(value)) return value[0] ?? "";
  return typeof value === "string" ? value : "";
}

function json(res, statusCode, payload) {
  res.writeHead(statusCode, { "content-type": "application/json; charset=utf-8" });
  res.end(`${JSON.stringify(payload, null, 2)}\n`);
}

function stripHopByHopHeaders(headers) {
  const blocked = new Set([
    "host",
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "content-length",
  ]);

  const cleaned = new Headers();
  for (const [key, value] of Object.entries(headers)) {
    if (!value || blocked.has(key.toLowerCase())) continue;
    if (Array.isArray(value)) {
      for (const item of value) cleaned.append(key, item);
      continue;
    }
    cleaned.set(key, value);
  }
  return cleaned;
}

function parseBearerTokens() {
  const single = getEnv("MCP_EDGE_BEARER_TOKEN");
  const csv = getEnv("MCP_EDGE_BEARER_TOKENS");
  const tokens = [single, ...csv.split(",")]
    .map((value) => value.trim())
    .filter(Boolean);
  return new Set(tokens);
}

const listenHost = getEnv("MCP_EDGE_HOST", "127.0.0.1");
const listenPort = parseInteger(getEnv("MCP_EDGE_PORT", "8788"), 8788);
const upstreamBaseUrl = getEnv("MCP_EDGE_UPSTREAM_BASE_URL");
const authenticatedUser = getEnv("MCP_EDGE_AUTHENTICATED_USER", "external-client");
const authHeaderName = getEnv("MCP_EDGE_AUTH_USER_HEADER", "x-mcp-authenticated-user");
const proxySecretHeaderName = getEnv("MCP_EDGE_PROXY_SECRET_HEADER", "x-mcp-proxy-secret");
const upstreamProxySecret = getEnv("MCP_EDGE_UPSTREAM_PROXY_SHARED_SECRET");
const healthPath = getEnv("MCP_EDGE_HEALTH_PATH", "/health");
const infoPath = getEnv("MCP_EDGE_INFO_PATH", "/info");
const acceptedTokens = parseBearerTokens();

if (!upstreamBaseUrl) {
  console.error("Missing MCP_EDGE_UPSTREAM_BASE_URL.");
  process.exit(1);
}

if (!upstreamProxySecret) {
  console.error("Missing MCP_EDGE_UPSTREAM_PROXY_SHARED_SECRET.");
  process.exit(1);
}

if (acceptedTokens.size === 0) {
  console.error("Missing MCP_EDGE_BEARER_TOKEN or MCP_EDGE_BEARER_TOKENS.");
  process.exit(1);
}

function isAuthorized(req) {
  const authHeader = firstHeader(req.headers.authorization).trim();
  if (!authHeader.startsWith("Bearer ")) return false;
  const token = authHeader.slice("Bearer ".length).trim();
  return acceptedTokens.has(token);
}

async function proxyRequest(req, res, { allowAnonymous = false } = {}) {
  if (!allowAnonymous && !isAuthorized(req)) {
    json(res, 401, {
      ok: false,
      error: "Missing or invalid bearer token.",
    });
    return;
  }

  const upstreamUrl = new URL(req.url ?? "/", upstreamBaseUrl);
  const upstreamHeaders = stripHopByHopHeaders(req.headers);
  upstreamHeaders.set(authHeaderName, authenticatedUser);
  upstreamHeaders.set(proxySecretHeaderName, upstreamProxySecret);
  upstreamHeaders.delete("authorization");

  const upstreamResponse = await fetch(upstreamUrl, {
    method: req.method,
    headers: upstreamHeaders,
    body: ["GET", "HEAD"].includes(req.method ?? "GET") ? undefined : Readable.toWeb(req),
    duplex: "half",
  });

  const responseHeaders = {};
  upstreamResponse.headers.forEach((value, key) => {
    if (key.toLowerCase() === "transfer-encoding") return;
    responseHeaders[key] = value;
  });

  res.writeHead(upstreamResponse.status, responseHeaders);

  if (!upstreamResponse.body) {
    res.end();
    return;
  }

  Readable.fromWeb(upstreamResponse.body).pipe(res);
}

const server = createServer(async (req, res) => {
  try {
    const pathname = new URL(req.url ?? "/", `http://${req.headers.host ?? "127.0.0.1"}`).pathname;

    if (pathname === healthPath) {
      if ((req.method ?? "GET") !== "GET") {
        json(res, 405, { ok: false, error: "Method not allowed." });
        return;
      }

      const upstreamUrl = new URL(healthPath, upstreamBaseUrl);
      const upstreamHeaders = new Headers({
        [authHeaderName]: authenticatedUser,
        [proxySecretHeaderName]: upstreamProxySecret,
      });
      const upstreamResponse = await fetch(upstreamUrl, {
        method: "GET",
        headers: upstreamHeaders,
      });
      const payload = await upstreamResponse.json();
      json(res, upstreamResponse.status, {
        ok: upstreamResponse.ok,
        service: "mcp-edge-proxy",
        publicAuth: "bearer-token",
        upstreamBaseUrl,
        upstreamStatus: payload,
      });
      return;
    }

    if (pathname === infoPath) {
      if ((req.method ?? "GET") !== "GET") {
        json(res, 405, { ok: false, error: "Method not allowed." });
        return;
      }

      json(res, 200, {
        ok: true,
        service: "mcp-edge-proxy",
        authMode: "Authorization: Bearer <token>",
        upstreamBaseUrl,
        protectedPaths: ["/mcp", infoPath],
        anonymousHealthPath: healthPath,
      });
      return;
    }

    await proxyRequest(req, res);
  } catch (error) {
    json(res, 502, {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(listenPort, listenHost, () => {
  console.log(`MCP edge proxy listening on http://${listenHost}:${listenPort}`);
  console.log(`Upstream base URL: ${upstreamBaseUrl}`);
});
