import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const fixtureProjectRoot = path.resolve(__dirname, "..", "fixtures", "widget_repo");
