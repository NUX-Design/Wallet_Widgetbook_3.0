const DEFAULT_UPSTREAM = "https://flutter-widget-wallet-mcp.onrender.com/mcp";

function required(env, name) {
  const value = String(env[name] ?? "").trim();
  if (!value) throw new Error(`${name} is required.`);
  return value;
}

function positiveInteger(env, name, fallback) {
  const value = Number.parseInt(String(env[name] ?? fallback), 10);
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new Error(`${name} must be a positive integer.`);
  }
  return value;
}

function csv(value) {
  return new Set(
    String(value ?? "")
      .split(",")
      .map((item) => item.trim())
      .filter(Boolean),
  );
}

function httpsUrl(value, name) {
  const url = new URL(value);
  if (url.protocol !== "https:") throw new Error(`${name} must use HTTPS.`);
  return url;
}

export function resolveGatewayConfig(env = process.env) {
  const publicOrigin = httpsUrl(required(env, "GATEWAY_PUBLIC_ORIGIN"), "GATEWAY_PUBLIC_ORIGIN");
  if (publicOrigin.pathname !== "/" || publicOrigin.search || publicOrigin.hash) {
    throw new Error("GATEWAY_PUBLIC_ORIGIN must be an origin without a path, query, or fragment.");
  }

  const issuer = httpsUrl(required(env, "AUTH0_ISSUER"), "AUTH0_ISSUER");
  if (!issuer.pathname.endsWith("/")) issuer.pathname += "/";

  const upstream = httpsUrl(env.GATEWAY_UPSTREAM_URL || DEFAULT_UPSTREAM, "GATEWAY_UPSTREAM_URL");
  if (upstream.pathname !== "/mcp" || upstream.search || upstream.hash) {
    throw new Error("GATEWAY_UPSTREAM_URL must point to the fixed /mcp path.");
  }

  const allowedSubjects = csv(required(env, "GATEWAY_ALLOWED_SUBJECTS"));
  const allowedClients = csv(required(env, "GATEWAY_ALLOWED_CLIENT_IDS"));
  if (allowedSubjects.size === 0 || allowedClients.size === 0) {
    throw new Error("Single-owner mode requires non-empty subject and client allowlists.");
  }

  return Object.freeze({
    host: env.HOST || "0.0.0.0",
    port: positiveInteger(env, "PORT", 10000),
    publicOrigin: publicOrigin.origin,
    resource: `${publicOrigin.origin}/mcp`,
    metadataUrl: `${publicOrigin.origin}/.well-known/oauth-protected-resource`,
    issuer: issuer.href,
    jwksUrl: new URL(".well-known/jwks.json", issuer).href,
    audience: required(env, "AUTH0_AUDIENCE"),
    requiredScope: env.GATEWAY_REQUIRED_SCOPE || "mcp:read",
    allowedSubjects,
    allowedClients,
    revokedJtis: csv(env.GATEWAY_REVOKED_JTIS),
    upstreamUrl: upstream.href,
    upstreamBearer: required(env, "GATEWAY_UPSTREAM_BEARER"),
    bodyLimitBytes: positiveInteger(env, "GATEWAY_BODY_LIMIT_BYTES", 1_048_576),
    upstreamHeaderTimeoutMs: positiveInteger(env, "GATEWAY_UPSTREAM_HEADER_TIMEOUT_MS", 15_000),
    upstreamIdleTimeoutMs: positiveInteger(env, "GATEWAY_UPSTREAM_IDLE_TIMEOUT_MS", 120_000),
    maxTokenAgeSeconds: positiveInteger(env, "GATEWAY_MAX_TOKEN_AGE_SECONDS", 86_400),
    rateWindowMs: positiveInteger(env, "GATEWAY_RATE_WINDOW_MS", 60_000),
    ratePerIdentity: positiveInteger(env, "GATEWAY_RATE_PER_IDENTITY", 120),
    rateGlobal: positiveInteger(env, "GATEWAY_RATE_GLOBAL", 600),
    rateMaxKeys: positiveInteger(env, "GATEWAY_RATE_MAX_KEYS", 10_000),
    sessionTtlMs: positiveInteger(env, "GATEWAY_SESSION_TTL_MS", 3_600_000),
    sessionMaxEntries: positiveInteger(env, "GATEWAY_SESSION_MAX_ENTRIES", 1_000),
    sessionMaxPerIdentity: positiveInteger(env, "GATEWAY_SESSION_MAX_PER_IDENTITY", 20),
    allowedOrigins: csv(env.GATEWAY_ALLOWED_ORIGINS),
    trustProxy: String(env.GATEWAY_TRUST_PROXY ?? "true").toLowerCase() === "true",
    allowInsecureLocal: String(env.GATEWAY_ALLOW_INSECURE_LOCAL ?? "false").toLowerCase() === "true",
  });
}
