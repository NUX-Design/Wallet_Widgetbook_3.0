import assert from "node:assert/strict";
import { PassThrough } from "node:stream";
import test from "node:test";
import { createAuditLogger, FixedWindowLimiter, redact, SessionBindings } from "../src/security.js";

test("redacts nested credential-shaped fields", () => {
  assert.deepEqual(redact({ authorization: "Bearer x", nested: { clientSecret: "x", safe: "ok" } }), {
    authorization: "[REDACTED]",
    nested: { clientSecret: "[REDACTED]", safe: "ok" },
  });
});

test("structured logger never emits secret fields", async () => {
  const output = new PassThrough();
  let text = "";
  output.on("data", (chunk) => { text += chunk; });
  createAuditLogger(output)("test", { token: "sensitive", status: 200 });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(text.includes("sensitive"), false);
  assert.match(text, /\[REDACTED\]/);
});

test("session bindings isolate issuer-subject-client tuples", () => {
  const sessions = new SessionBindings();
  const first = { issuer: "issuer", subject: "one", clientId: "client" };
  const second = { issuer: "issuer", subject: "two", clientId: "client" };
  sessions.bind("session", first);
  sessions.assert("session", first);
  assert.throws(() => sessions.assert("session", second), /another OAuth identity/);
});

test("session bindings expire and enforce global/per-identity capacity", () => {
  const identity = { issuer: "issuer", subject: "one", clientId: "client" };
  const sessions = new SessionBindings({ ttlMs: 10, maxEntries: 2, maxPerIdentity: 1 });
  sessions.bind("first", identity, 0);
  assert.throws(() => sessions.bind("second", identity, 1), /capacity exceeded/);
  assert.throws(() => sessions.assert("first", identity, 11), /Unknown or expired/);
  sessions.bind("second", identity, 11);
});

test("rate limiter bounds high-cardinality keys", () => {
  const limiter = new FixedWindowLimiter(1_000, 1, 2);
  assert.equal(limiter.take("one", 0), true);
  assert.equal(limiter.take("two", 0), true);
  assert.equal(limiter.take("three", 0), true);
  assert.equal(limiter.take("three", 1), false);
});
