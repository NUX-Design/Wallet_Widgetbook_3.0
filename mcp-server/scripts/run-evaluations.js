#!/usr/bin/env node

import assert from "node:assert/strict";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { createToolDispatcher } from "../app.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const serverRoot = path.resolve(__dirname, "..");
const projectRoot = path.resolve(serverRoot, "..");
const evaluationFile = path.join(
  serverRoot,
  "evaluations",
  "flutter-widget-wallet-mcp-evaluation.xml",
);

function parseAttributes(raw) {
  return Object.fromEntries(
    [...raw.matchAll(/([a-zA-Z0-9_-]+)="([^"]*)"/g)].map((match) => [match[1], match[2]]),
  );
}

function readFirstTag(body, tagName) {
  const match = body.match(new RegExp(`<${tagName}>([\\s\\S]*?)</${tagName}>`));
  if (!match) {
    throw new Error(`Missing <${tagName}> tag in evaluation case.`);
  }
  return match[1].trim();
}

function parseCases(xml) {
  return [...xml.matchAll(/<case\b([^>]*)>([\s\S]*?)<\/case>/g)].map((match) => {
    const attrs = parseAttributes(match[1]);
    const body = match[2];
    const asserts = [...body.matchAll(/<assert\b([^>]*)>([\s\S]*?)<\/assert>/g)].map(
      (assertMatch) => ({
        ...parseAttributes(assertMatch[1]),
        expected: assertMatch[2].trim(),
      }),
    );

    return {
      id: attrs.id,
      description: readFirstTag(body, "description"),
      tool: readFirstTag(body, "tool"),
      args: JSON.parse(readFirstTag(body, "args")),
      assertions: asserts,
    };
  });
}

function parseExpectedValue(raw) {
  const trimmed = raw.trim();
  if (!trimmed) return "";

  if (
    trimmed.startsWith("{") ||
    trimmed.startsWith("[") ||
    trimmed.startsWith('"') ||
    trimmed === "true" ||
    trimmed === "false" ||
    trimmed === "null" ||
    /^-?\d+(\.\d+)?$/.test(trimmed)
  ) {
    return JSON.parse(trimmed);
  }

  return trimmed;
}

function resolvePath(data, pathExpression) {
  if (!pathExpression || pathExpression === ".") {
    return data;
  }

  return pathExpression.split(".").reduce((current, segment) => {
    if (current == null) return undefined;

    const match = segment.match(/^([^\[\]]+)(?:\[(\d+)\])?$/);
    if (!match) {
      throw new Error(`Unsupported path segment "${segment}".`);
    }

    const [, key, index] = match;
    const next = current[key];
    if (index == null) {
      return next;
    }

    return next?.[Number(index)];
  }, data);
}

function assertIncludesObject(actual, expected, message) {
  assert.ok(Array.isArray(actual), `${message} (actual value is not an array)`);
  const found = actual.some((item) =>
    Object.entries(expected).every(([key, value]) => {
      try {
        assert.deepEqual(item?.[key], value);
        return true;
      } catch {
        return false;
      }
    }),
  );
  assert.ok(found, message);
}

function runAssertion(assertion, data) {
  const actual = resolvePath(data, assertion.path);
  const expected = parseExpectedValue(assertion.expected);
  const label = `${assertion.op} ${assertion.path}`;

  switch (assertion.op) {
    case "equals":
      assert.deepEqual(actual, expected, `${label} mismatch`);
      return;
    case "includes":
      if (typeof actual === "string") {
        assert.ok(actual.includes(String(expected)), `${label} mismatch`);
        return;
      }
      assert.ok(Array.isArray(actual), `${label} requires a string or array`);
      assert.ok(actual.includes(expected), `${label} mismatch`);
      return;
    case "includesObject":
      assertIncludesObject(actual, expected, `${label} mismatch`);
      return;
    case "notEmpty":
      if (typeof actual === "string" || Array.isArray(actual)) {
        assert.ok(actual.length > 0, `${label} expected non-empty value`);
        return;
      }
      assert.ok(actual && Object.keys(actual).length > 0, `${label} expected non-empty object`);
      return;
    default:
      throw new Error(`Unsupported assert op "${assertion.op}".`);
  }
}

async function main() {
  const xml = fs.readFileSync(evaluationFile, "utf8");
  const cases = parseCases(xml);
  const dispatchToolCall = createToolDispatcher({ projectRoot });

  console.log(`Running ${cases.length} MCP evaluation case(s)...`);

  for (const evaluationCase of cases) {
    const response = await dispatchToolCall(evaluationCase.tool, evaluationCase.args);
    assert.equal(
      response.isError,
      undefined,
      `Case "${evaluationCase.id}" failed because tool "${evaluationCase.tool}" returned an error.`,
    );

    const data = response.structuredContent;
    assert.ok(data, `Case "${evaluationCase.id}" returned no structuredContent.`);

    for (const assertion of evaluationCase.assertions) {
      runAssertion(assertion, data);
    }

    console.log(`PASS ${evaluationCase.id} - ${evaluationCase.description}`);
  }

  console.log("MCP evaluation suite passed.");
}

try {
  await main();
} catch (error) {
  console.error("MCP evaluation suite failed.");
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
}
