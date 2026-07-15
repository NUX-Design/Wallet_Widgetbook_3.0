#!/usr/bin/env node

export function assertLatestPublishable({ ref, runSha, mainSha }) {
  if (ref !== "refs/heads/main") {
    throw new Error(`latest pointer may only be updated from refs/heads/main (received ${ref || "<empty>"})`);
  }

  if (!/^[0-9a-f]{40}$/i.test(runSha || "")) {
    throw new Error("GITHUB_SHA must be a full 40-character commit SHA");
  }

  if (!/^[0-9a-f]{40}$/i.test(mainSha || "")) {
    throw new Error("MAIN_HEAD_SHA must be a full 40-character commit SHA");
  }

  if (runSha !== mainSha) {
    throw new Error(`workflow commit ${runSha} is no longer main HEAD ${mainSha}; refusing to move v3-preview-latest`);
  }

  return { publishable: true, sourceCommit: runSha };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    const result = assertLatestPublishable({
      ref: process.env.GITHUB_REF,
      runSha: process.env.GITHUB_SHA,
      mainSha: process.env.MAIN_HEAD_SHA,
    });
    console.log(`v3-preview-latest publish guard passed for ${result.sourceCommit}`);
  } catch (error) {
    console.error(`v3-preview-latest publish guard blocked update: ${error.message}`);
    process.exitCode = 1;
  }
}
