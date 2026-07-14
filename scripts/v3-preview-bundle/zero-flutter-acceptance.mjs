#!/usr/bin/env node
// ZP-10 — Zero-Flutter consumer acceptance harness.
//
// Proves the launcher opens an interactive Widget V3 preview from a consumer
// repo that has NO Flutter/Dart, without mutating the workspace. Runs the launcher
// with Flutter/Dart stripped from PATH across: empty git repo, React-ish repo, and
// a plain directory; and exercises cold / warm / concurrent / port-collision /
// corrupt-download / unauthorized paths, asserting no worktree mutation and no
// token leakage into the cache.
//
// Not a CI gate (needs a built bundle + python3/curl); run locally:
//   node scripts/v3-preview-bundle/zero-flutter-acceptance.mjs

import { execFileSync, spawn } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import net from "node:net";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";

const here = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(here, "../..");
const LAUNCHER = path.join(here, "launch-v3-preview.mjs");
const DIST = path.join(projectRoot, "dist", "v3-preview-bundle");
const TOKEN = "super-secret-bearer-token-should-never-leak";
const SLUG = "button/V3MiniButton";

const results = [];
function check(name, ok, detail = "") {
  results.push({ name, ok });
  console.log(`  ${ok ? "PASS" : "FAIL"}  ${name}${detail ? ` — ${detail}` : ""}`);
}

// Ensure a built dist bundle exists (build the bundle from build/web if needed).
function ensureDist() {
  if (fs.existsSync(path.join(DIST, "manifest.json"))) return;
  console.log("No dist bundle found; packing from build/web (allow-dirty)...");
  execFileSync("node", [path.join(here, "pack-v3-preview-bundle.mjs"), "--allow-dirty"], { cwd: projectRoot, stdio: "inherit" });
}

function strippedPath() {
  const flutterBin = path.dirname(execFileSync("bash", ["-lc", "command -v flutter || true"], { encoding: "utf8" }).trim() || "/nonexistent/flutter");
  return process.env.PATH.split(":").filter((p) => p !== flutterBin && !p.includes("/flutter/bin")).join(":");
}

function freePort() {
  return new Promise((resolve, reject) => {
    const s = net.createServer();
    s.on("error", reject);
    s.listen(0, "127.0.0.1", () => { const { port } = s.address(); s.close(() => resolve(port)); });
  });
}

// Mock delivery endpoint: serves the dist archive + manifest over loopback.
async function startMockRelease() {
  const port = await freePort();
  const server = http.createServer((req, res) => {
    const name = req.url.split("?")[0].replace(/^\/+/, "");
    const file = path.join(DIST, name);
    if (!file.startsWith(DIST) || !fs.existsSync(file)) { res.writeHead(404); return res.end("nope"); }
    res.writeHead(200); fs.createReadStream(file).pipe(res);
  });
  await new Promise((r) => server.listen(port, "127.0.0.1", r));
  return { server, base: `http://127.0.0.1:${port}` };
}

function launcherEnv(cacheDir) {
  return { ...process.env, PATH: strippedPath(), XDG_CACHE_HOME: cacheDir, FORCE_COLOR: "0" };
}

// Run the (foreground/blocking) launcher, resolve with its first JSON line + proc handle.
function runLauncher(args, env, cwd = projectRoot) {
  return new Promise((resolve, reject) => {
    const proc = spawn("node", [LAUNCHER, ...args], { env, cwd, stdio: ["ignore", "pipe", "pipe"] });
    let out = "", err = "";
    const timer = setTimeout(() => { proc.kill("SIGTERM"); reject(new Error(`launcher timed out; stderr=${err}`)); }, 60000);
    proc.stdout.on("data", (d) => {
      out += d.toString();
      const line = out.split("\n").find((l) => l.trim().startsWith("{"));
      if (line) { clearTimeout(timer); resolve({ proc, json: JSON.parse(line) }); }
    });
    proc.stderr.on("data", (d) => { err += d.toString(); });
    proc.on("exit", (code) => { clearTimeout(timer); if (out.trim()) return; resolve({ proc, json: JSON.parse((err.split("\n").find((l) => l.trim().startsWith("{")) || "{}")), exitCode: code }); });
  });
}

function deliveryArgs(base, sha, commit) {
  return ["--bundle-url", `${base}/v3-preview-bundle.tar.gz`, "--sha256", sha, "--source-commit", commit, "--slug", SLUG, "--token", TOKEN, "--host", "127.0.0.1", "--port", "0"];
}

async function httpCode(url) {
  try { const r = await fetch(url); return r.status; } catch { return 0; }
}

async function main() {
  ensureDist();
  const manifest = JSON.parse(fs.readFileSync(path.join(DIST, "manifest.json"), "utf8"));
  const { sha256, sourceCommit } = manifest;
  const { server: mock, base } = await startMockRelease();
  const cleanupProcs = [];
  const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), "zpaccept-"));

  try {
    // --- flutter/dart really gone from the launcher's PATH ---
    const sp = strippedPath();
    const flutterVisible = sp.split(":").some((p) => fs.existsSync(path.join(p, "flutter")));
    const dartVisible = sp.split(":").some((p) => fs.existsSync(path.join(p, "dart")));
    check("Flutter and Dart are absent from the consumer PATH", !flutterVisible && !dartVisible);

    // --- three consumer repo shapes ---
    const scenarios = [];
    // empty git repo
    const gitRepo = path.join(tmpRoot, "empty-git"); fs.mkdirSync(gitRepo);
    execFileSync("git", ["init", "-q"], { cwd: gitRepo }); execFileSync("git", ["config", "user.email", "t@t"], { cwd: gitRepo }); execFileSync("git", ["config", "user.name", "t"], { cwd: gitRepo });
    fs.writeFileSync(path.join(gitRepo, ".gitkeep"), ""); execFileSync("git", ["add", "-A"], { cwd: gitRepo }); execFileSync("git", ["commit", "-qm", "base"], { cwd: gitRepo });
    scenarios.push({ name: "empty-git", dir: gitRepo, git: true });
    // react-ish repo
    const reactRepo = path.join(tmpRoot, "react"); fs.mkdirSync(reactRepo);
    execFileSync("git", ["init", "-q"], { cwd: reactRepo }); execFileSync("git", ["config", "user.email", "t@t"], { cwd: reactRepo }); execFileSync("git", ["config", "user.name", "t"], { cwd: reactRepo });
    fs.writeFileSync(path.join(reactRepo, "package.json"), '{"name":"react-app"}\n'); fs.mkdirSync(path.join(reactRepo, "src")); fs.writeFileSync(path.join(reactRepo, "src/App.jsx"), "export default 1;\n");
    execFileSync("git", ["add", "-A"], { cwd: reactRepo }); execFileSync("git", ["commit", "-qm", "base"], { cwd: reactRepo });
    scenarios.push({ name: "react", dir: reactRepo, git: true });
    // plain dir (no git)
    const plain = path.join(tmpRoot, "plain"); fs.mkdirSync(plain); fs.writeFileSync(path.join(plain, "notes.txt"), "hi");
    scenarios.push({ name: "plain", dir: plain, git: false });

    for (const sc of scenarios) {
      const cache = path.join(tmpRoot, `cache-${sc.name}`);
      const env = launcherEnv(cache);
      const before = sc.git ? execFileSync("git", ["status", "--porcelain"], { cwd: sc.dir, encoding: "utf8" }) : fs.readdirSync(sc.dir).sort().join(",");

      // cold
      const cold = await runLauncher(deliveryArgs(base, sha256, sourceCommit), { ...env, PWD: sc.dir }, sc.dir);
      cleanupProcs.push(cold.proc);
      const port = cold.json.port;
      const rootCode = await httpCode(`http://127.0.0.1:${port}/`);
      const health = await (await fetch(`http://127.0.0.1:${port}/__preview_health__.json`)).json().catch(() => ({}));
      check(`[${sc.name}] cold launch serves interactive bundle (GET / 200)`, cold.json.ok === true && rootCode === 200 && health.commit === sourceCommit && health.sha256 === sha256, `port=${port}`);

      // warm (reuse)
      const warm = await runLauncher(deliveryArgs(base, sha256, sourceCommit), env, sc.dir);
      if (warm.proc) cleanupProcs.push(warm.proc);
      check(`[${sc.name}] warm launch reuses the running server`, warm.json.reused === true && warm.json.port === port);

      // worktree unchanged
      const after = sc.git ? execFileSync("git", ["status", "--porcelain"], { cwd: sc.dir, encoding: "utf8" }) : fs.readdirSync(sc.dir).sort().join(",");
      check(`[${sc.name}] consumer worktree unchanged`, before === after);

      // token never leaked into cache
      const cacheDump = execFileSync("bash", ["-lc", `grep -rl "${TOKEN}" "${cache}" 2>/dev/null || true`], { encoding: "utf8" }).trim();
      check(`[${sc.name}] bearer token not persisted in cache`, cacheDump === "");
    }

    // --- concurrent cold launches (fresh cache) share one download safely ---
    const ccache = path.join(tmpRoot, "cache-concurrent");
    const cenv = launcherEnv(ccache);
    const [c1, c2] = await Promise.all([
      runLauncher(deliveryArgs(base, sha256, sourceCommit), cenv),
      runLauncher(deliveryArgs(base, sha256, sourceCommit), cenv),
    ]);
    cleanupProcs.push(c1.proc, c2.proc);
    const commitDirs = fs.readdirSync(path.join(ccache, "flutter-widget-wallet", "v3-preview")).filter((n) => /^[0-9a-f]{40}$/.test(n));
    check("concurrent launches produce exactly one cached commit dir", c1.json.ok && c2.json.ok && commitDirs.length === 1, `dirs=${commitDirs.length}`);

    // --- port collision -> PORT_UNAVAILABLE ---
    const busyPort = await freePort();
    const blocker = http.createServer((_, res) => res.end("busy")); await new Promise((r) => blocker.listen(busyPort, "127.0.0.1", r));
    const collide = await runLauncher([...deliveryArgs(base, sha256, sourceCommit).slice(0, -1), String(busyPort)], launcherEnv(path.join(tmpRoot, "cache-collide")));
    if (collide.proc) cleanupProcs.push(collide.proc);
    check("pinned busy port fails closed (PORT_UNAVAILABLE)", collide.json.ok === false && collide.json.code === "PORT_UNAVAILABLE");
    blocker.close();

    // --- corrupt download (bad sha) -> CHECKSUM_MISMATCH ---
    const badSha = "0".repeat(64);
    const corrupt = await runLauncher(["--bundle-url", `${base}/v3-preview-bundle.tar.gz`, "--sha256", badSha, "--source-commit", sourceCommit, "--slug", SLUG, "--token", TOKEN], launcherEnv(path.join(tmpRoot, "cache-corrupt")));
    if (corrupt.proc) cleanupProcs.push(corrupt.proc);
    check("corrupt download fails closed (CHECKSUM_MISMATCH)", corrupt.json.ok === false && corrupt.json.code === "CHECKSUM_MISMATCH");

    // --- unauthorized (mock returns 404 for a missing asset) -> NOT_BUILT ---
    const unauth = await runLauncher(["--bundle-url", `${base}/missing.tar.gz`, "--sha256", sha256, "--source-commit", sourceCommit, "--slug", SLUG], launcherEnv(path.join(tmpRoot, "cache-unauth")));
    if (unauth.proc) cleanupProcs.push(unauth.proc);
    check("missing bundle fails closed (NOT_BUILT)", unauth.json.ok === false && unauth.json.code === "NOT_BUILT");
  } finally {
    for (const p of cleanupProcs) { try { p.kill("SIGTERM"); } catch { /* noop */ } }
    mock.close();
    // stop any servers the launcher recorded, per scenario cache
    for (const entry of fs.existsSync(tmpRoot) ? fs.readdirSync(tmpRoot) : []) {
      if (entry.startsWith("cache-") || entry.startsWith("cache")) {
        try { execFileSync("node", [LAUNCHER, "--stop-all"], { env: launcherEnv(path.join(tmpRoot, entry)), stdio: "ignore" }); } catch { /* noop */ }
      }
    }
    fs.rmSync(tmpRoot, { recursive: true, force: true });
  }

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} acceptance checks passed.`);
  if (failed.length) process.exit(1);
}

main().catch((e) => { console.error(`zero-flutter-acceptance: ${e.stack || e.message}`); process.exit(1); });
