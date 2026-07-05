import fs from "fs";

const packageJson = JSON.parse(
  fs.readFileSync(new URL("./package.json", import.meta.url), "utf8"),
);

export const DEFAULT_SERVER_NAME = packageJson.name;
export const DEFAULT_SERVER_VERSION = packageJson.version;
