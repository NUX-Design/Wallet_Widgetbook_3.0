import assert from "node:assert/strict";
import test from "node:test";

import { assertLatestPublishable } from "./assert-latest-publishable.mjs";

const oldSha = "1".repeat(40);
const headSha = "2".repeat(40);

test("allows main HEAD to update the latest pointer", () => {
  assert.deepEqual(
    assertLatestPublishable({ ref: "refs/heads/main", runSha: headSha, mainSha: headSha }),
    { publishable: true, sourceCommit: headSha },
  );
});

test("blocks workflow dispatches and reruns from a tag or non-main branch", () => {
  assert.throws(
    () => assertLatestPublishable({ ref: "refs/tags/v3-preview-old", runSha: oldSha, mainSha: oldSha }),
    /only be updated from refs\/heads\/main/,
  );
});

test("blocks an obsolete run after main moves or is rewritten", () => {
  assert.throws(
    () => assertLatestPublishable({ ref: "refs/heads/main", runSha: oldSha, mainSha: headSha }),
    /is no longer main HEAD/,
  );
});

test("rejects abbreviated or malformed SHAs", () => {
  assert.throws(
    () => assertLatestPublishable({ ref: "refs/heads/main", runSha: "abc123", mainSha: headSha }),
    /GITHUB_SHA must be a full 40-character commit SHA/,
  );
});
