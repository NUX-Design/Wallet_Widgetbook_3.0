import { createHash } from "node:crypto";

const SECRET_KEYS = /authorization|cookie|token|secret|code|body/i;

export function redact(value, key = "") {
  if (SECRET_KEYS.test(key)) return "[REDACTED]";
  if (Array.isArray(value)) return value.map((item) => redact(item));
  if (value && typeof value === "object") {
    return Object.fromEntries(Object.entries(value).map(([entryKey, entryValue]) => [entryKey, redact(entryValue, entryKey)]));
  }
  return value;
}

export function createAuditLogger(output = process.stderr) {
  return (event, fields = {}) => {
    output.write(`${JSON.stringify(redact({ timestamp: new Date().toISOString(), event, ...fields }))}\n`);
  };
}

export function identityKey(identity) {
  return `${identity.issuer}\u0000${identity.subject}\u0000${identity.clientId}`;
}

export function identityHash(identity) {
  return createHash("sha256").update(identityKey(identity)).digest("hex").slice(0, 16);
}

export class FixedWindowLimiter {
  #entries = new Map();

  constructor(windowMs, limit, maxEntries = 10_000) {
    this.windowMs = windowMs;
    this.limit = limit;
    this.maxEntries = maxEntries;
  }

  #sweep(now) {
    for (const [key, value] of this.#entries) {
      if (now >= value.resetAt) this.#entries.delete(key);
    }
    while (this.#entries.size >= this.maxEntries) {
      this.#entries.delete(this.#entries.keys().next().value);
    }
  }

  take(key, now = Date.now()) {
    const current = this.#entries.get(key);
    if (!current || now >= current.resetAt) {
      if (this.#entries.size >= this.maxEntries) this.#sweep(now);
      this.#entries.set(key, { count: 1, resetAt: now + this.windowMs });
      return true;
    }
    if (current.count >= this.limit) return false;
    current.count += 1;
    return true;
  }
}

export class SessionBindings {
  #bindings = new Map();

  constructor({ ttlMs = 3_600_000, maxEntries = 1_000, maxPerIdentity = 20 } = {}) {
    this.ttlMs = ttlMs;
    this.maxEntries = maxEntries;
    this.maxPerIdentity = maxPerIdentity;
  }

  #sweep(now = Date.now()) {
    for (const [sessionId, binding] of this.#bindings) {
      if (now >= binding.expiresAt) this.#bindings.delete(sessionId);
    }
  }

  assert(sessionId, identity, now = Date.now()) {
    if (!sessionId) return;
    const binding = this.#bindings.get(sessionId);
    if (!binding || now >= binding.expiresAt) {
      this.#bindings.delete(sessionId);
      const error = new Error("Unknown or expired MCP session.");
      error.code = "unknown_session";
      error.statusCode = 404;
      throw error;
    }
    if (binding.owner !== identityKey(identity)) {
      const error = new Error("MCP session belongs to another OAuth identity.");
      error.code = "session_identity_mismatch";
      error.statusCode = 403;
      throw error;
    }
    binding.expiresAt = now + this.ttlMs;
  }

  bind(sessionId, identity, now = Date.now()) {
    if (!sessionId) return;
    this.#sweep(now);
    const owner = identityKey(identity);
    const existing = this.#bindings.get(sessionId);
    if (existing && existing.owner !== owner) {
      const error = new Error("MCP session belongs to another OAuth identity.");
      error.code = "session_identity_mismatch";
      error.statusCode = 403;
      throw error;
    }
    const identityCount = [...this.#bindings.values()].filter((binding) => binding.owner === owner).length;
    if (!existing && (this.#bindings.size >= this.maxEntries || identityCount >= this.maxPerIdentity)) {
      const error = new Error("MCP session capacity exceeded.");
      error.code = "session_capacity_exceeded";
      error.statusCode = 429;
      throw error;
    }
    this.#bindings.set(sessionId, { owner, expiresAt: now + this.ttlMs });
  }

  delete(sessionId, identity) {
    if (!sessionId) return;
    this.assert(sessionId, identity);
    this.#bindings.delete(sessionId);
  }
}
