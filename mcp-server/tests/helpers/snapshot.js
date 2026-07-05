import assert from "node:assert/strict";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const snapshotsDir = path.resolve(__dirname, "..", "snapshots");
const shouldUpdate = process.env.UPDATE_SNAPSHOTS === "1";

export function assertMatchesSnapshot(snapshotName, value) {
  const filePath = path.join(snapshotsDir, `${snapshotName}.json`);
  const serialized = `${JSON.stringify(value, null, 2)}\n`;

  if (shouldUpdate) {
    fs.mkdirSync(path.dirname(filePath), { recursive: true });
    fs.writeFileSync(filePath, serialized, "utf8");
    return;
  }

  const expected = fs.readFileSync(filePath, "utf8");
  assert.equal(serialized, expected, `Snapshot mismatch: ${snapshotName}`);
}
