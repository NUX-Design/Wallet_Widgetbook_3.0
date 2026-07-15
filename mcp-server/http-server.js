#!/usr/bin/env node

import { createServer } from "node:http";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import { createMcpServer, createToolDispatcher, DEFAULT_SERVER_NAME, DEFAULT_SERVER_VERSION } from "./app.js";
import { createStructuredLogger } from "./observability.js";
import { V3BundleCatalog } from "./v3/bundle_catalog.js";
import { GitHubReleaseBundleStore, LocalDirBundleStore, BundleStoreError } from "./v3/bundle_store.js";
import {
  V3_PREVIEW_COMMIT_SHA_PATTERN,
  verifySignedBundleUrl,
} from "./v3/bundle_contract.js";
import {
  createRestrictedDispatchToolCall,
  REMOTE_READ_ONLY_TOOL_DEFINITIONS,
  RemoteCatalogRegistry,
  resolveRemoteCommitSha,
  resolveRemoteRepoIdentity,
} from "./remote_support.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const defaultProjectRoot = path.resolve(__dirname, "..");

function parseBoolean(value, defaultValue) {
  if (value === undefined || value === null || value === "") return defaultValue;
  const normalized = String(value).trim().toLowerCase();
  return ["1", "true", "yes", "on"].includes(normalized);
}

function parseInteger(value, defaultValue) {
  const parsed = Number.parseInt(String(value ?? ""), 10);
  return Number.isFinite(parsed) ? parsed : defaultValue;
}

function parseCsvSet(...values) {
  return new Set(
    values
      .flatMap((value) => String(value ?? "").split(","))
      .map((value) => value.trim())
      .filter(Boolean),
  );
}

function firstHeaderValue(value) {
  if (Array.isArray(value)) return value[0] ?? "";
  return typeof value === "string" ? value : "";
}

function json(res, statusCode, payload) {
  res.writeHead(statusCode, { "content-type": "application/json; charset=utf-8" });
  res.end(`${JSON.stringify(payload, null, 2)}\n`);
}

async function readJsonBody(req, maxBytes = 1024 * 1024) {
  const chunks = [];
  let totalBytes = 0;

  for await (const chunk of req) {
    totalBytes += chunk.length;
    if (totalBytes > maxBytes) {
      throw new Error(`Request body exceeds ${maxBytes} bytes.`);
    }
    chunks.push(chunk);
  }

  if (chunks.length === 0) return undefined;

  const text = Buffer.concat(chunks).toString("utf8").trim();
  if (!text) return undefined;
  return JSON.parse(text);
}

function buildBaseUrl(req) {
  return new URL(req.url ?? "/", `http://${req.headers.host ?? "127.0.0.1"}`);
}

function findCallerControlledRepoSelectors(requestUrl, req) {
  const matches = [];
  for (const queryKey of ["repo", "repoRoot", "branch", "commit"]) {
    if (requestUrl.searchParams.has(queryKey)) {
      matches.push(`query:${queryKey}`);
    }
  }

  for (const headerName of ["x-mcp-repo-root", "x-mcp-branch", "x-mcp-commit-sha"]) {
    if (req.headers[headerName]) {
      matches.push(`header:${headerName}`);
    }
  }

  return matches;
}

class FixedWindowRateLimiter {
  #windowMs;
  #maxRequests;
  #entries;

  constructor({ windowMs, maxRequests }) {
    this.#windowMs = windowMs;
    this.#maxRequests = maxRequests;
    this.#entries = new Map();
  }

  take(key) {
    if (this.#maxRequests <= 0) {
      return {
        allowed: true,
        remaining: Number.POSITIVE_INFINITY,
        resetAt: Date.now() + this.#windowMs,
      };
    }

    const now = Date.now();
    const current = this.#entries.get(key);
    if (!current || now >= current.resetAt) {
      const resetAt = now + this.#windowMs;
      this.#entries.set(key, { count: 1, resetAt });
      return {
        allowed: true,
        remaining: Math.max(this.#maxRequests - 1, 0),
        resetAt,
      };
    }

    if (current.count >= this.#maxRequests) {
      return {
        allowed: false,
        remaining: 0,
        resetAt: current.resetAt,
      };
    }

    current.count += 1;
    return {
      allowed: true,
      remaining: Math.max(this.#maxRequests - current.count, 0),
      resetAt: current.resetAt,
    };
  }
}

export function resolveRemoteHttpOptions(rawOptions = {}, env = process.env) {
  const projectRoot = path.resolve(rawOptions.projectRoot ?? env.MCP_REMOTE_REPO_ROOT ?? defaultProjectRoot);
  const channel = rawOptions.channel ?? env.MCP_REMOTE_CHANNEL ?? "production";
  const host = rawOptions.host ?? env.MCP_REMOTE_HOST ?? "127.0.0.1";
  const port = rawOptions.port ?? parseInteger(env.MCP_REMOTE_PORT, 3310);
  const endpointPath = rawOptions.endpointPath ?? env.MCP_REMOTE_ENDPOINT_PATH ?? "/mcp";
  const healthPath = rawOptions.healthPath ?? env.MCP_REMOTE_HEALTH_PATH ?? "/health";
  const infoPath = rawOptions.infoPath ?? env.MCP_REMOTE_INFO_PATH ?? "/info";
  const refreshPath = rawOptions.refreshPath ?? env.MCP_REMOTE_REFRESH_PATH ?? "/admin/refresh";
  const repoIdentity =
    rawOptions.repoIdentity ?? resolveRemoteRepoIdentity(projectRoot, env);
  const deployedAt = rawOptions.deployedAt ?? env.MCP_REMOTE_DEPLOYED_AT ?? new Date().toISOString();
  const commitSha = rawOptions.commitSha ?? resolveRemoteCommitSha(projectRoot, env);
  const requireProxyAuth = rawOptions.requireProxyAuth ?? parseBoolean(env.MCP_REMOTE_REQUIRE_PROXY_AUTH, true);
  const authenticatedUserHeader =
    rawOptions.authenticatedUserHeader ?? env.MCP_REMOTE_AUTH_USER_HEADER ?? "x-mcp-authenticated-user";
  const proxySecretHeader =
    rawOptions.proxySecretHeader ?? env.MCP_REMOTE_PROXY_SECRET_HEADER ?? "x-mcp-proxy-secret";
  const proxySharedSecret = rawOptions.proxySharedSecret ?? env.MCP_REMOTE_PROXY_SHARED_SECRET ?? "";
  const bearerTokenHeader =
    rawOptions.bearerTokenHeader ?? env.MCP_REMOTE_BEARER_TOKEN_HEADER ?? "authorization";
  const bearerTokenPrefix =
    rawOptions.bearerTokenPrefix ?? env.MCP_REMOTE_BEARER_TOKEN_PREFIX ?? "Bearer";
  const bearerTokens =
    rawOptions.bearerTokens ??
    parseCsvSet(env.MCP_REMOTE_BEARER_TOKEN, env.MCP_REMOTE_BEARER_TOKENS);
  const bearerPrincipal =
    rawOptions.bearerPrincipal ?? env.MCP_REMOTE_BEARER_PRINCIPAL ?? "external-client";
  const refreshTokenHeader =
    rawOptions.refreshTokenHeader ?? env.MCP_REMOTE_REFRESH_TOKEN_HEADER ?? "x-mcp-refresh-token";
  const refreshToken = rawOptions.refreshToken ?? env.MCP_REMOTE_REFRESH_TOKEN ?? "";
  // ZP-05 — zero-Flutter preview bundle delivery.
  const previewBundlePath = rawOptions.previewBundlePath ?? env.V3_PREVIEW_BUNDLE_PATH ?? "/v3/preview-bundle";
  const previewBundleBaseUrl =
    rawOptions.previewBundleBaseUrl ?? env.V3_PREVIEW_BUNDLE_BASE_URL ?? "https://flutter-widget-wallet-mcp.onrender.com/v3/preview-bundle";
  const previewBundleRepo = rawOptions.previewBundleRepo ?? env.MCP_PREVIEW_BUNDLE_REPO ?? "";
  const previewBundleToken = rawOptions.previewBundleToken ?? env.MCP_PREVIEW_BUNDLE_GH_TOKEN ?? "";
  const previewBundlePublicRepo =
    rawOptions.previewBundlePublicRepo ?? parseBoolean(env.MCP_PREVIEW_BUNDLE_PUBLIC_REPO, false);
  const previewBundleDir = rawOptions.previewBundleDir ?? env.V3_PREVIEW_BUNDLE_DIR ?? path.join(projectRoot, "dist", "v3-preview-bundle");
  const previewBundleSigningSecret =
    rawOptions.previewBundleSigningSecret ??
    env.V3_PREVIEW_BUNDLE_SIGNING_SECRET ??
    [...bearerTokens][0] ??
    proxySharedSecret;
  const previewBundleSignedUrlTtlSeconds =
    rawOptions.previewBundleSignedUrlTtlSeconds ?? parseInteger(env.V3_PREVIEW_BUNDLE_SIGNED_URL_TTL_SECONDS, 300);
  const allowAnonymousHealth =
    rawOptions.allowAnonymousHealth ?? parseBoolean(env.MCP_REMOTE_ALLOW_ANON_HEALTH, true);
  const rateLimitWindowMs =
    rawOptions.rateLimitWindowMs ?? parseInteger(env.MCP_REMOTE_RATE_LIMIT_WINDOW_MS, 60_000);
  const rateLimitMaxRequests =
    rawOptions.rateLimitMaxRequests ?? parseInteger(env.MCP_REMOTE_RATE_LIMIT_MAX_REQUESTS, 120);
  const serverName =
    rawOptions.serverName ?? `${DEFAULT_SERVER_NAME}-${channel}-remote`;
  const serverVersion = rawOptions.serverVersion ?? DEFAULT_SERVER_VERSION;
  const resolveCommitSha = rawOptions.resolveCommitSha ?? (() => resolveRemoteCommitSha(projectRoot, env));
  const logger =
    rawOptions.logger ??
    createStructuredLogger({
      level: env.MCP_LOG_LEVEL ?? "silent",
      baseContext: {
        serverName,
        serverVersion,
        transport: "streamable-http",
        channel,
      },
    });

  return {
    projectRoot,
    channel,
    host,
    port,
    endpointPath,
    healthPath,
    infoPath,
    refreshPath,
    repoIdentity,
    deployedAt,
    commitSha,
    requireProxyAuth,
    authenticatedUserHeader,
    proxySecretHeader,
    proxySharedSecret,
    bearerTokenHeader,
    bearerTokenPrefix,
    bearerTokens,
    bearerPrincipal,
    refreshTokenHeader,
    refreshToken,
    previewBundlePath,
    previewBundleBaseUrl,
    previewBundleRepo,
    previewBundleToken,
    previewBundlePublicRepo,
    previewBundleDir,
    previewBundleSigningSecret,
    previewBundleSignedUrlTtlSeconds,
    allowAnonymousHealth,
    rateLimitWindowMs,
    rateLimitMaxRequests,
    serverName,
    serverVersion,
    resolveCommitSha,
    logger,
  };
}

function authenticateRequest(req, options) {
  const bearerHeader = firstHeaderValue(req.headers[options.bearerTokenHeader.toLowerCase()]).trim();
  const principal = firstHeaderValue(req.headers[options.authenticatedUserHeader.toLowerCase()]).trim();
  const proxySecret = firstHeaderValue(req.headers[options.proxySecretHeader.toLowerCase()]).trim();
  const bearerPrefix = `${options.bearerTokenPrefix} `;

  if (options.bearerTokens.size > 0 && bearerHeader.startsWith(bearerPrefix)) {
    const bearerToken = bearerHeader.slice(bearerPrefix.length).trim();
    if (options.bearerTokens.has(bearerToken)) {
      return {
        ok: true,
        principal: options.bearerPrincipal,
        authMode: "bearer-token",
      };
    }

    return {
      ok: false,
      statusCode: 401,
      message: `Missing or invalid bearer token header "${options.bearerTokenHeader}".`,
    };
  }

  if (!options.requireProxyAuth) {
    return {
      ok: true,
      principal: principal || "anonymous",
      authMode: "anonymous",
    };
  }

  if (!options.proxySharedSecret || proxySecret !== options.proxySharedSecret) {
    return {
      ok: false,
      statusCode: 401,
      message: `Missing or invalid proxy secret header "${options.proxySecretHeader}".`,
    };
  }

  if (!principal) {
    return {
      ok: false,
      statusCode: 401,
      message: `Missing authenticated user header "${options.authenticatedUserHeader}" from the trusted proxy.`,
    };
  }

  return {
    ok: true,
    principal,
    authMode: "trusted-proxy",
  };
}

export function resolvePreviewBundleAccessToken(options) {
  return options.previewBundlePublicRepo ? "" : options.previewBundleToken;
}

async function handleMcpRequest(req, res, requestUrl, remoteState) {
  const { options, registry } = remoteState;
  const auth = authenticateRequest(req, options);
  if (!auth.ok) {
    remoteState.logger.warn("remote.http.auth_rejected", {
      method: req.method,
      path: requestUrl.pathname,
      statusCode: auth.statusCode,
      reason: auth.message,
    });
    json(res, auth.statusCode, { ok: false, error: auth.message });
    return;
  }

  const rateLimitResult = remoteState.rateLimiter.take(
    `${auth.principal}:${req.socket.remoteAddress ?? "unknown"}`,
  );
  if (!rateLimitResult.allowed) {
    const retryAfterSeconds = Math.max(
      Math.ceil((rateLimitResult.resetAt - Date.now()) / 1000),
      1,
    );
    res.setHeader("retry-after", String(retryAfterSeconds));
    remoteState.logger.warn("remote.http.rate_limited", {
      method: req.method,
      path: requestUrl.pathname,
      principal: auth.principal,
      authMode: auth.authMode,
      retryAfterSeconds,
    });
    json(res, 429, {
      ok: false,
      error: "Rate limit exceeded for the remote MCP endpoint.",
      retryAfterSeconds,
    });
    return;
  }

  const snapshot = await registry.getActiveSnapshot();
  const baseDispatchToolCall = createToolDispatcher({
    projectRoot: snapshot.repoRoot,
    logger: remoteState.logger,
    widgetCatalog: snapshot.widgetCatalog,
    v3BundleCatalog: remoteState.bundleCatalog,
  });
  const dispatchToolCall = createRestrictedDispatchToolCall(baseDispatchToolCall);
  const { server } = createMcpServer({
    projectRoot: snapshot.repoRoot,
    serverName: options.serverName,
    serverVersion: options.serverVersion,
    toolRegistry: REMOTE_READ_ONLY_TOOL_DEFINITIONS,
    dispatchToolCall,
    logger: remoteState.logger,
  });
  const transport = new StreamableHTTPServerTransport({
    sessionIdGenerator: undefined,
  });

  res.on("close", () => {
    transport.close().catch(() => {});
    server.close().catch?.(() => {});
  });

  await server.connect(transport);
  const parsedBody =
    req.method === "POST" || req.method === "DELETE" ? await readJsonBody(req) : undefined;

  remoteState.logger.info("remote.http.request", {
    method: req.method,
    path: requestUrl.pathname,
    principal: auth.principal,
    authMode: auth.authMode,
    namespace: snapshot.namespace,
    commitSha: snapshot.commitSha,
    repoIdentity: snapshot.repoIdentity,
  });

  await transport.handleRequest(req, res, parsedBody);
}

const BUNDLE_STORE_ERROR_STATUS = { NOT_BUILT: 404, STALE_BUNDLE: 409, UNAUTHORIZED: 401, MALFORMED_MANIFEST: 502, DOWNLOAD_FAILED: 502 };

// ZP-05 — Authenticated, streaming preview-bundle delivery. Serves the manifest
// and the commit-addressed archive over the same bearer boundary as the MCP
// endpoint. Archive bytes are streamed, never buffered as base64.
async function handlePreviewBundleRequest(req, res, requestUrl, remoteState) {
  const { options } = remoteState;
  if (req.method !== "GET") {
    json(res, 405, { ok: false, error: "Preview bundle delivery only accepts GET." });
    return;
  }

  const remainder = requestUrl.pathname.slice(options.previewBundlePath.length).replace(/^\/+/, "");
  const archiveMatch = /^([0-9a-f]{40}|latest)\.tar\.gz$/.exec(remainder);
  const signedArchiveAccess = Boolean(
    archiveMatch &&
    archiveMatch[1] !== "latest" &&
    verifySignedBundleUrl({
      commit: archiveMatch[1],
      expires: requestUrl.searchParams.get("expires"),
      sig: requestUrl.searchParams.get("sig"),
      signingSecret: options.previewBundleSigningSecret,
    }),
  );
  const auth = signedArchiveAccess ? { ok: true, principal: "signed-preview-url", authMode: "signed-url" } : authenticateRequest(req, options);
  if (!auth.ok) {
    remoteState.logger.warn("remote.bundle.auth_rejected", { path: requestUrl.pathname, statusCode: auth.statusCode });
    json(res, auth.statusCode, { ok: false, error: auth.message });
    return;
  }

  try {
    if (remainder === "manifest.json") {
      const manifest = await remoteState.bundleCatalog.manifest({ commit: "latest" });
      res.writeHead(200, { "content-type": "application/json; charset=utf-8", "cache-control": "no-store" });
      res.end(`${JSON.stringify(manifest, null, 2)}\n`);
      return;
    }

    if (!archiveMatch) {
      json(res, 404, { ok: false, error: "Unknown preview bundle path.", expected: `${options.previewBundlePath}/manifest.json or ${options.previewBundlePath}/<commit>.tar.gz` });
      return;
    }
    const commit = archiveMatch[1];
    if (commit !== "latest" && !V3_PREVIEW_COMMIT_SHA_PATTERN.test(commit)) {
      json(res, 400, { ok: false, error: "commit must be a full 40-char hex SHA or 'latest'." });
      return;
    }

    const archive = await remoteState.bundleCatalog.openArchive({ commit });
    res.writeHead(200, {
      "content-type": "application/gzip",
      "content-length": String(archive.bytes),
      "etag": `"${archive.sha256}"`,
      "x-bundle-source-commit": archive.sourceCommit,
      "cache-control": commit === "latest" || signedArchiveAccess ? "no-store" : "public, max-age=31536000, immutable",
    });
    const stream = await archive.stream();
    stream.on("error", (error) => {
      remoteState.logger.error("remote.bundle.stream_error", { path: requestUrl.pathname, errorMessage: error.message });
      res.destroy(error);
    });
    stream.pipe(res);
    remoteState.logger.info("remote.bundle.download", { path: requestUrl.pathname, principal: auth.principal, commit, bytes: archive.bytes });
  } catch (error) {
    const code = error instanceof BundleStoreError ? error.code : error.code;
    const status = BUNDLE_STORE_ERROR_STATUS[code] ?? 500;
    remoteState.logger.warn("remote.bundle.error", { path: requestUrl.pathname, code: code ?? "INTERNAL_ERROR", statusCode: status });
    json(res, status, { ok: false, error: error.message, code: code ?? "INTERNAL_ERROR" });
  }
}

export async function startRemoteHttpServer(rawOptions = {}) {
  const options = resolveRemoteHttpOptions(rawOptions);
  const registry = new RemoteCatalogRegistry({
    repoRoot: options.projectRoot,
    repoIdentity: options.repoIdentity,
    channel: options.channel,
    logger: options.logger,
    resolveCommitSha: options.resolveCommitSha,
  });
  await registry.refresh({
    reason: "startup",
    commitSha: options.commitSha,
    deployedAt: options.deployedAt,
  });
  const rateLimiter = new FixedWindowRateLimiter({
    windowMs: options.rateLimitWindowMs,
    maxRequests: options.rateLimitMaxRequests,
  });
  const previewBundleStore = options.previewBundleRepo
    ? new GitHubReleaseBundleStore({
        repo: options.previewBundleRepo,
        token: resolvePreviewBundleAccessToken(options),
        publicRepo: options.previewBundlePublicRepo,
      })
    : new LocalDirBundleStore(options.previewBundleDir);
  const bundleCatalog = new V3BundleCatalog({
    store: previewBundleStore,
    bundleBaseUrl: options.previewBundleBaseUrl,
    resolveFreshnessCommit: () => options.commitSha,
    signingSecret: options.previewBundleSigningSecret,
    signedUrlTtlSeconds: options.previewBundleSignedUrlTtlSeconds,
  });
  const remoteState = {
    options,
    registry,
    rateLimiter,
    bundleCatalog,
    logger: options.logger,
  };
  const sockets = new Set();

  const nodeServer = createServer(async (req, res) => {
    const requestUrl = buildBaseUrl(req);
    const selectors = findCallerControlledRepoSelectors(requestUrl, req);

    try {
      if (selectors.length > 0) {
        json(res, 400, {
          ok: false,
          error: "Caller-controlled repo, branch, or commit selection is not supported on the hosted endpoint.",
          selectors,
        });
        return;
      }

      if (req.method === "GET" && requestUrl.pathname === options.healthPath) {
        const snapshot = await registry.describeActiveSnapshot();
        json(res, 200, {
          ok: true,
          status: "healthy",
          transport: "streamable-http",
          mode: "snapshot-of-deployed-clone",
          ...snapshot,
        });
        return;
      }

      if (req.method === "GET" && requestUrl.pathname === options.infoPath) {
        const snapshot = await registry.describeActiveSnapshot();
        const bundleHealth = await remoteState.bundleCatalog.health();
        json(res, 200, {
          ok: true,
          transport: "streamable-http",
          toolCount: REMOTE_READ_ONLY_TOOL_DEFINITIONS.length,
          toolNames: REMOTE_READ_ONLY_TOOL_DEFINITIONS.map((tool) => tool.name),
          previewBundle: {
            deliveryPath: options.previewBundlePath,
            baseUrl: options.previewBundleBaseUrl,
            source: options.previewBundleRepo ? `github-release:${options.previewBundleRepo}` : "local-dir",
            ...bundleHealth,
          },
          authBoundary: {
            supportsBearerToken: options.bearerTokens.size > 0,
            bearerTokenHeader: options.bearerTokenHeader,
            bearerTokenPrefix: options.bearerTokenPrefix,
            bearerPrincipal: options.bearerPrincipal,
            requiresTrustedProxy: options.requireProxyAuth,
            authenticatedUserHeader: options.authenticatedUserHeader,
            proxySecretHeader: options.proxySecretHeader,
          },
          freshness: {
            model: "snapshot-of-deployed-clone",
            commitSha: snapshot.commitSha,
            deployedAt: snapshot.deployedAt,
            catalogGeneratedAt: snapshot.catalogGeneratedAt,
          },
          targeting: {
            repoIdentity: snapshot.repoIdentity,
            channel: snapshot.channel,
            namespace: snapshot.namespace,
          },
        });
        return;
      }

      if (requestUrl.pathname === options.refreshPath) {
        if (!options.refreshToken) {
          json(res, 404, {
            ok: false,
            error: "Refresh endpoint is disabled until MCP_REMOTE_REFRESH_TOKEN is configured.",
          });
          return;
        }

        if (req.method !== "POST") {
          json(res, 405, {
            ok: false,
            error: "Refresh endpoint only accepts POST requests.",
          });
          return;
        }

        const refreshToken = firstHeaderValue(req.headers[options.refreshTokenHeader.toLowerCase()]).trim();
        if (refreshToken !== options.refreshToken) {
          json(res, 401, {
            ok: false,
            error: `Missing or invalid refresh token header "${options.refreshTokenHeader}".`,
          });
          return;
        }

        const previousSnapshot = await registry.describeActiveSnapshot();
        const refreshed = await registry.refresh({
          reason: "manual-refresh",
          deployedAt: new Date().toISOString(),
        });
        json(res, 200, {
          ok: true,
          previousNamespace: previousSnapshot.namespace,
          namespace: refreshed.namespace,
          commitSha: refreshed.commitSha,
          deployedAt: refreshed.deployedAt,
          repoIdentity: refreshed.repoIdentity,
          channel: refreshed.channel,
        });
        return;
      }

      if (requestUrl.pathname === options.endpointPath) {
        await handleMcpRequest(req, res, requestUrl, remoteState);
        return;
      }

      if (
        requestUrl.pathname === options.previewBundlePath ||
        requestUrl.pathname.startsWith(`${options.previewBundlePath}/`)
      ) {
        await handlePreviewBundleRequest(req, res, requestUrl, remoteState);
        return;
      }

      if (
        options.allowAnonymousHealth &&
        req.method === "GET" &&
        (requestUrl.pathname === "/" || requestUrl.pathname === "")
      ) {
        json(res, 200, {
          ok: true,
          message: "Remote MCP server is running.",
          healthUrl: options.healthPath,
          infoUrl: options.infoPath,
          endpointPath: options.endpointPath,
        });
        return;
      }

      json(res, 404, {
        ok: false,
        error: "Route not found.",
      });
    } catch (error) {
      options.logger.error("remote.http.error", {
        method: req.method,
        path: requestUrl.pathname,
        errorMessage: error instanceof Error ? error.message : String(error),
      });
      json(res, 500, {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  });
  nodeServer.on("connection", (socket) => {
    sockets.add(socket);
    socket.on("close", () => {
      sockets.delete(socket);
    });
  });

  await new Promise((resolve, reject) => {
    nodeServer.once("error", reject);
    nodeServer.listen(options.port, options.host, resolve);
  });

  const address = nodeServer.address();
  const url =
    typeof address === "object" && address
      ? `http://${options.host}:${address.port}${options.endpointPath}`
      : `http://${options.host}:${options.port}${options.endpointPath}`;
  const snapshot = await registry.describeActiveSnapshot();
  options.logger.info("server.started", {
    transport: "streamable-http",
    projectRoot: options.projectRoot,
    repoIdentity: snapshot.repoIdentity,
    channel: snapshot.channel,
    commitSha: snapshot.commitSha,
    deployedAt: snapshot.deployedAt,
    endpointPath: options.endpointPath,
    url,
  });

  return {
    url,
    options,
    registry,
    nodeServer,
    async close() {
      for (const socket of sockets) {
        socket.destroy();
      }
      await new Promise((resolve, reject) => {
        nodeServer.close((error) => {
          if (error) reject(error);
          else resolve();
        });
      });
    },
  };
}

const isEntrypoint = process.argv[1] && fileURLToPath(import.meta.url) === path.resolve(process.argv[1]);

if (isEntrypoint) {
  try {
    const remoteServer = await startRemoteHttpServer();
    console.log(`Remote MCP endpoint: ${remoteServer.url}`);
  } catch (error) {
    console.error(error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}
