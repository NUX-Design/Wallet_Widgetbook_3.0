import assert from "node:assert/strict";
import { createToolDispatcher } from "../../app.js";
import { fixtureProjectRoot } from "./fixture_repo.js";

export function createToolHarness(projectRoot = fixtureProjectRoot, options = {}) {
  const dispatchToolCall = createToolDispatcher({ projectRoot, ...options });

  return {
    async callTool(name, args = {}) {
      return dispatchToolCall(name, args);
    },
    async callSuccess(name, args = {}) {
      const response = await dispatchToolCall(name, args);
      assert.equal(response.isError, undefined, `Expected "${name}" to succeed.`);
      return {
        response,
        data: response.structuredContent,
      };
    },
    async callError(name, args = {}) {
      const response = await dispatchToolCall(name, args);
      assert.equal(response.isError, true, `Expected "${name}" to fail.`);
      return {
        response,
        error: JSON.parse(response.content[0].text),
      };
    },
  };
}
