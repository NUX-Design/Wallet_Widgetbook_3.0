#!/usr/bin/env node

import { createServer } from "node:http";
import { Readable } from "node:stream";

function getEnv(name, fallback = "") {
  return process.env[name]?.trim() || fallback;
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

const listenHost = getEnv("DEV_EDGE_PROXY_HOST", "127.0.0.1");
const listenPort = Number.parseInt(getEnv("DEV_EDGE_PROXY_PORT", "8787"), 10);
const targetBaseUrl = getEnv("DEV_EDGE_PROXY_TARGET", "https://flutter-widget-wallet-mcp.onrender.com");
const bearerToken = getEnv("DEV_EDGE_PROXY_BEARER_TOKEN", "dev-token-change-me");
const authenticatedUser = getEnv("DEV_EDGE_PROXY_USER", "codex-dev");
const proxySecret = getEnv("DEV_EDGE_PROXY_SHARED_SECRET");
const authHeaderName = getEnv("DEV_EDGE_PROXY_AUTH_HEADER", "x-mcp-authenticated-user");
const proxySecretHeaderName = getEnv("DEV_EDGE_PROXY_SECRET_HEADER", "x-mcp-proxy-secret");

if (!proxySecret) {
  console.error("Missing DEV_EDGE_PROXY_SHARED_SECRET.");
  process.exit(1);
}

const server = createServer(async (req, res) => {
  try {
    const authHeader = firstHeader(req.headers.authorization);
    const expected = `Bearer ${bearerToken}`;

    if (authHeader !== expected) {
      json(res, 401, {
        ok: false,
        error: "Invalid bearer token for dev edge proxy.",
      });
      return;
    }

    const upstreamUrl = new URL(req.url ?? "/", targetBaseUrl);
    const upstreamHeaders = stripHopByHopHeaders(req.headers);
    upstreamHeaders.set(authHeaderName, authenticatedUser);
    upstreamHeaders.set(proxySecretHeaderName, proxySecret);
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
  } catch (error) {
    json(res, 502, {
      ok: false,
      error: error instanceof Error ? error.message : String(error),
    });
  }
});

server.listen(listenPort, listenHost, () => {
  console.log(
    `Dev edge proxy listening on http://${listenHost}:${listenPort} -> ${targetBaseUrl}`,
  );
  console.log(`Expecting Authorization: Bearer ${bearerToken}`);
});
