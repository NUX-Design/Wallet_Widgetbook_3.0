import assert from "node:assert/strict";
import test from "node:test";
import { decodeJsonRpcBody } from "../scripts/verify-remote.mjs";

test("generic smoke client decodes JSON and SSE JSON-RPC responses", () => {
  const json = decodeJsonRpcBody('{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2025-06-18"}}');
  assert.equal(json.result.protocolVersion, "2025-06-18");

  const sse = decodeJsonRpcBody(
    'event: message\ndata: {"jsonrpc":"2.0","id":2,"result":{"tools":[]}}\n\n',
  );
  assert.deepEqual(sse.result.tools, []);
});

test("generic smoke client rejects bodies without a complete JSON-RPC event", () => {
  assert.throws(() => decodeJsonRpcBody("event: ping\ndata: not-json\n\n"), /did not contain/);
});
