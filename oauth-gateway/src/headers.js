const REQUEST_HEADERS = new Set([
  "accept",
  "content-type",
  "mcp-protocol-version",
  "mcp-session-id",
  "last-event-id",
  "user-agent",
]);

const RESPONSE_BLOCKED = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
  "set-cookie",
  "www-authenticate",
  "server",
  "via",
  "content-length",
  "content-encoding",
]);

export function upstreamHeaders(incoming, upstreamBearer) {
  const headers = new Headers();
  for (const [name, value] of Object.entries(incoming)) {
    const normalized = name.toLowerCase();
    if (!REQUEST_HEADERS.has(normalized) || value === undefined) continue;
    headers.set(normalized, Array.isArray(value) ? value.join(", ") : String(value));
  }
  headers.set("authorization", `Bearer ${upstreamBearer}`);
  return headers;
}

export function clientResponseHeaders(upstream) {
  const headers = {};
  for (const [name, value] of upstream.entries()) {
    const normalized = name.toLowerCase();
    if (RESPONSE_BLOCKED.has(normalized) || normalized.startsWith("x-mcp-proxy-") || normalized === "authorization") continue;
    headers[normalized] = value;
  }
  headers["cache-control"] = "no-store";
  return headers;
}
