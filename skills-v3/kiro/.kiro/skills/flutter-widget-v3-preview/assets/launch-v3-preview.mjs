#!/usr/bin/env node
// ZP-08 + ZP-09 — Repo-independent Widget V3 preview launcher.
//
// Runs from ANY repo (React/Node/empty/plain dir) with only Node.js — no Flutter,
// no Dart, no writes into the caller's workspace. Given a resolved previewDelivery
// (bundleUrl + sha256 + sourceCommit + slug), it:
//   1. resolves an OS user-cache dir OUTSIDE the workspace
//   2. locks per-commit, downloads to a temp file, verifies SHA-256,
//      safe-extracts (no path traversal / absolute / symlink escape), atomic-installs
//   3. serves the immutable cache over loopback (python3 baseline, node fallback)
//   4. reuses a matching warm server, else starts one, waits for HTTP + health
//      readiness, then prints the exact deep-link URL
//
// Signed delivery URLs need no separate consumer token. Legacy bearer-protected
// delivery remains supported through --token/env during rollout.
//
// Zero third-party dependencies (Node builtins + system `tar` only).

import { execFileSync, spawn } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";

const VENDOR_DIR = "flutter-widget-wallet";
const CACHE_SUBDIR = "v3-preview";
const HEALTH_FILE = "__preview_health__.json";
const SUPPORTED_SCHEMA_VERSION = 2;

// ---------------------------------------------------------------- args ----
function parseArgs(argv) {
  const a = { host: "127.0.0.1", port: 0, detach: false };
  for (let i = 0; i < argv.length; i += 1) {
    const f = argv[i];
    const next = () => argv[++i];
    switch (f) {
      case "--delivery-json": a.deliveryJson = next(); break;
      case "--bundle-url": a.bundleUrl = next(); break;
      case "--sha256": a.sha256 = next(); break;
      case "--source-commit": a.sourceCommit = next(); break;
      case "--schema-version": a.schemaVersion = Number(next()); break;
      case "--slug": a.slug = next(); break;
      case "--token": a.token = next(); break;
      case "--host": a.host = next(); break;
      case "--port": a.port = Number(next()); break;
      case "--detach": a.detach = true; break;
      case "--foreground": a.detach = false; break;
      case "--stop": a.stop = true; break;
      case "--stop-all": a.stopAll = true; break;
      case "--print-cache": a.printCache = true; break;
      case "-h": case "--help": a.help = true; break;
      default: throw new Error(`unknown argument: ${f}`);
    }
  }
  return a;
}

function fail(code, message) {
  console.error(JSON.stringify({ ok: false, code, error: message }));
  process.exit(1);
}

// -------------------------------------------------------------- cache ----
function userCacheRoot() {
  if (process.env.XDG_CACHE_HOME) return process.env.XDG_CACHE_HOME;
  if (process.platform === "darwin") return path.join(os.homedir(), "Library", "Caches");
  if (process.platform === "win32") return process.env.LOCALAPPDATA || path.join(os.homedir(), "AppData", "Local");
  return path.join(os.homedir(), ".cache");
}
function cacheBase() {
  return path.join(userCacheRoot(), VENDOR_DIR, CACHE_SUBDIR);
}
function commitDir(commit) {
  return path.join(cacheBase(), commit);
}
function serversFile() {
  return path.join(cacheBase(), "servers.json");
}

// ------------------------------------------------------------ locking ----
async function withCommitLock(commit, fn, { timeoutMs = 120000 } = {}) {
  fs.mkdirSync(cacheBase(), { recursive: true });
  const lockDir = `${commitDir(commit)}.lock`;
  const start = Date.now();
  for (;;) {
    try {
      fs.mkdirSync(lockDir, { recursive: false });
      break; // acquired
    } catch (e) {
      if (e.code !== "EEXIST") throw e;
      // Stale lock older than timeout -> reclaim.
      try {
        const age = Date.now() - fs.statSync(lockDir).mtimeMs;
        if (age > timeoutMs) { fs.rmSync(lockDir, { recursive: true, force: true }); continue; }
      } catch { /* race: lock vanished */ }
      if (Date.now() - start > timeoutMs) throw new Error(`timed out acquiring download lock for ${commit}`);
      await new Promise((r) => setTimeout(r, 200));
    }
  }
  try {
    return await fn();
  } finally {
    fs.rmSync(lockDir, { recursive: true, force: true });
  }
}

// ----------------------------------------------------------- download ----
async function downloadTo(tmpFile, bundleUrl, token) {
  const headers = { "user-agent": "v3-preview-launcher" };
  if (token) headers.authorization = `Bearer ${token}`;
  let res;
  try {
    res = await fetch(bundleUrl, { headers, redirect: "follow" });
  } catch (e) {
    throw Object.assign(new Error(`download failed: ${e.message}`), { code: "DOWNLOAD_FAILED" });
  }
  if (res.status === 401 || res.status === 403) throw Object.assign(new Error("bundle download unauthorized"), { code: "UNAUTHORIZED" });
  if (res.status === 404) throw Object.assign(new Error("bundle not built / not found"), { code: "NOT_BUILT" });
  if (!res.ok || !res.body) throw Object.assign(new Error(`download failed (HTTP ${res.status})`), { code: "DOWNLOAD_FAILED" });

  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(tmpFile, buf);
  return crypto.createHash("sha256").update(buf).digest("hex");
}

// ------------------------------------------------------ safe extraction ----
function assertSafeArchive(archivePath) {
  // tar -tvzf shows a mode string whose first char flags the entry type.
  const out = execFileSync("tar", ["-tvzf", archivePath], { encoding: "utf8" });
  for (const line of out.split("\n")) {
    if (!line.trim()) continue;
    const typeChar = line[0];
    if (typeChar === "l" || typeChar === "h") {
      throw Object.assign(new Error(`archive contains a link entry (type '${typeChar}'): ${line}`), { code: "UNSAFE_ARCHIVE" });
    }
    // Path is the last whitespace-delimited field (Flutter web asset paths encode spaces as %20).
    const name = line.trim().split(/\s+/).pop();
    if (path.isAbsolute(name) || name.split("/").includes("..")) {
      throw Object.assign(new Error(`archive contains an unsafe path: ${name}`), { code: "UNSAFE_ARCHIVE" });
    }
  }
}

function safeExtract(archivePath, destDir) {
  assertSafeArchive(archivePath);
  fs.mkdirSync(destDir, { recursive: true });
  execFileSync("tar", ["-xzf", archivePath, "-C", destDir, "--no-same-owner"], { stdio: "ignore" });
}

// ensure the immutable cache/<commit>/ dir exists and matches sha256.
async function ensureCached({ commit, sha256, bundleUrl, token }) {
  const dir = commitDir(commit);
  const readyMarker = path.join(dir, ".ready.json");
  if (fs.existsSync(readyMarker)) {
    const ready = JSON.parse(fs.readFileSync(readyMarker, "utf8"));
    if (ready.sha256 === sha256) return dir; // warm cache hit
    // Checksum drift for the same commit is suspicious. Do NOT delete the
    // existing cache on an unverified claim; only a freshly downloaded and
    // verified copy may atomically replace it (below, under the lock).
  }

  return withCommitLock(commit, async () => {
    if (fs.existsSync(readyMarker)) {
      const ready = JSON.parse(fs.readFileSync(readyMarker, "utf8"));
      if (ready.sha256 === sha256) return dir; // another process finished while we waited
    }
    fs.mkdirSync(cacheBase(), { recursive: true });
    const tmpArchive = path.join(cacheBase(), `.dl-${commit}-${process.pid}.tar.gz`);
    const tmpExtract = `${dir}.tmp-${process.pid}`;
    try {
      const gotSha = await downloadTo(tmpArchive, bundleUrl, token);
      if (gotSha !== sha256) {
        throw Object.assign(new Error(`checksum mismatch: expected ${sha256}, got ${gotSha}`), { code: "CHECKSUM_MISMATCH" });
      }
      fs.rmSync(tmpExtract, { recursive: true, force: true });
      safeExtract(tmpArchive, tmpExtract);
      // health file lives alongside served content (not part of archive integrity)
      fs.writeFileSync(path.join(tmpExtract, HEALTH_FILE), JSON.stringify({ commit, sha256 }));
      fs.rmSync(dir, { recursive: true, force: true });
      fs.renameSync(tmpExtract, dir); // atomic install
      fs.writeFileSync(readyMarker, JSON.stringify({ commit, sha256, installedAt: new Date().toISOString() }));
      return dir;
    } finally {
      fs.rmSync(tmpArchive, { force: true });
      fs.rmSync(tmpExtract, { recursive: true, force: true });
    }
  });
}

// -------------------------------------------------------------- server ----
function freePort(host) {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.on("error", reject);
    srv.listen(0, host, () => { const { port } = srv.address(); srv.close(() => resolve(port)); });
  });
}

async function probeHealth(host, port) {
  try {
    const res = await fetch(`http://${host}:${port}/${HEALTH_FILE}`);
    if (!res.ok) return null;
    return await res.json();
  } catch { return null; }
}

function readServers() {
  try { return JSON.parse(fs.readFileSync(serversFile(), "utf8")); } catch { return []; }
}
function writeServers(list) {
  fs.mkdirSync(cacheBase(), { recursive: true });
  fs.writeFileSync(serversFile(), JSON.stringify(list, null, 2));
}
function pidAlive(pid) {
  try { process.kill(pid, 0); return true; } catch { return false; }
}

async function findWarmServer({ host, commit, sha256 }) {
  for (const entry of readServers()) {
    if (entry.host !== host || entry.commit !== commit || entry.sha256 !== sha256) continue;
    if (!pidAlive(entry.pid)) continue;
    const health = await probeHealth(host, entry.port);
    if (health && health.commit === commit && health.sha256 === sha256) return entry;
  }
  return null;
}

function recordServer(entry) {
  const list = readServers().filter((e) => pidAlive(e.pid) && e.port !== entry.port);
  list.push(entry);
  writeServers(list);
}

function pickRuntime() {
  const has = (bin) => { try { execFileSync(bin, ["--version"], { stdio: "ignore" }); return true; } catch { return false; } };
  if (has("python3")) return "python3";
  if (has("node")) return "node";
  return null;
}

function spawnStaticServer(runtime, servedDir, host, port, foreground) {
  if (runtime === "python3") {
    return spawn("python3", ["-m", "http.server", String(port), "--bind", host], {
      cwd: servedDir, detached: !foreground, stdio: "ignore",
    });
  }
  // Node fallback: a tiny inline static file server bound to loopback.
  const script = `
    const http=require('http'),fs=require('fs'),path=require('path');
    const root=${JSON.stringify(servedDir)};
    const types={'.html':'text/html','.js':'text/javascript','.json':'application/json','.wasm':'application/wasm','.css':'text/css','.svg':'image/svg+xml','.png':'image/png','.otf':'font/otf','.ttf':'font/ttf','.bin':'application/octet-stream','.gz':'application/gzip'};
    http.createServer((req,res)=>{
      let p=decodeURIComponent((req.url||'/').split('?')[0]); if(p==='/')p='/index.html';
      const fp=path.join(root,path.normalize(p).replace(/^\\/+/,''));
      if(!fp.startsWith(root)){res.writeHead(403);return res.end();}
      fs.readFile(fp,(e,b)=>{ if(e){res.writeHead(404);return res.end('not found');}
        res.writeHead(200,{'content-type':types[path.extname(fp)]||'application/octet-stream'}); res.end(b);});
    }).listen(${port},${JSON.stringify(host)});
  `;
  return spawn("node", ["-e", script], { detached: !foreground, stdio: "ignore" });
}

async function waitReady(host, port, commit, sha256, tries = 80) {
  for (let i = 0; i < tries; i += 1) {
    const health = await probeHealth(host, port);
    if (health && health.commit === commit && health.sha256 === sha256) return true;
    await new Promise((r) => setTimeout(r, 250));
  }
  return false;
}

// -------------------------------------------------------------- main ----
function resolveDelivery(a) {
  if (a.deliveryJson) {
    const d = JSON.parse(a.deliveryJson);
    return { bundleUrl: d.bundleUrl, sha256: d.sha256, sourceCommit: d.sourceCommit, schemaVersion: d.schemaVersion, slug: a.slug };
  }
  return { bundleUrl: a.bundleUrl, sha256: a.sha256, sourceCommit: a.sourceCommit, schemaVersion: a.schemaVersion, slug: a.slug };
}

async function stopServers({ all, commit }) {
  const list = readServers();
  const remaining = [];
  for (const e of list) {
    if (all || (commit && e.commit === commit)) {
      if (pidAlive(e.pid)) { try { process.kill(e.pid, "SIGTERM"); } catch { /* already gone */ } }
    } else if (pidAlive(e.pid)) {
      remaining.push(e);
    }
  }
  writeServers(remaining);
  console.log(JSON.stringify({ ok: true, stopped: list.length - remaining.length }));
}

async function main() {
  const a = parseArgs(process.argv.slice(2));
  if (a.help) {
    console.log("Usage: node launch-v3-preview.mjs --delivery-json '<previewDelivery>' --slug <category/Widget> [--token <t>] [--host 127.0.0.1] [--port 0] [--foreground]\n       node launch-v3-preview.mjs --bundle-url <url> --sha256 <hex> --source-commit <sha> --slug <slug> [...]\n       node launch-v3-preview.mjs --print-cache | --stop-all | --stop --source-commit <sha>");
    return;
  }
  if (a.printCache) { console.log(cacheBase()); return; }
  if (a.stopAll) return stopServers({ all: true });
  if (a.stop) return stopServers({ all: false, commit: a.sourceCommit });

  const token = a.token || process.env.MCP_REMOTE_BEARER_TOKEN || process.env.V3_PREVIEW_BEARER_TOKEN || "";
  const d = resolveDelivery(a);
  if (!d.bundleUrl || !d.sha256 || !d.sourceCommit || !d.slug) {
    fail("INVALID_ARGUMENT", "require bundleUrl, sha256, sourceCommit (via --delivery-json or flags) and --slug");
  }
  if (d.schemaVersion && d.schemaVersion > SUPPORTED_SCHEMA_VERSION) {
    fail("SCHEMA_UNSUPPORTED", `manifest schemaVersion ${d.schemaVersion} newer than supported ${SUPPORTED_SCHEMA_VERSION}`);
  }
  if (!/^[0-9a-f]{40}$/.test(d.sourceCommit) || !/^[0-9a-f]{64}$/.test(d.sha256)) {
    fail("INVALID_ARGUMENT", "sourceCommit must be 40-hex and sha256 64-hex");
  }

  const runtime = pickRuntime();
  if (!runtime) fail("RUNTIME_MISSING", "neither python3 nor node is available to serve the bundle");

  let servedDir;
  try {
    servedDir = await ensureCached({ commit: d.sourceCommit, sha256: d.sha256, bundleUrl: d.bundleUrl, token });
  } catch (e) {
    fail(e.code || "DOWNLOAD_FAILED", e.message);
  }

  // Warm-server reuse.
  const warm = await findWarmServer({ host: a.host, commit: d.sourceCommit, sha256: d.sha256 });
  if (warm) {
    console.log(JSON.stringify({ ok: true, reused: true, url: `http://${a.host}:${warm.port}/#/${d.slug}`, port: warm.port, sourceCommit: d.sourceCommit, runtime: warm.runtime }));
    return;
  }

  const port = a.port && a.port > 0 ? a.port : await freePort(a.host);
  const child = spawnStaticServer(runtime, servedDir, a.host, port, !a.detach);

  const ready = await waitReady(a.host, port, d.sourceCommit, d.sha256);
  if (!ready) {
    try { process.kill(child.pid, "SIGTERM"); } catch { /* noop */ }
    fail("PORT_UNAVAILABLE", `server did not become ready on http://${a.host}:${port}`);
  }
  recordServer({ host: a.host, port, pid: child.pid, commit: d.sourceCommit, sha256: d.sha256, runtime, startedAt: new Date().toISOString() });

  const url = `http://${a.host}:${port}/#/${d.slug}`;
  console.log(JSON.stringify({ ok: true, reused: false, url, port, sourceCommit: d.sourceCommit, runtime, cacheDir: servedDir }));

  if (a.detach) {
    child.unref(); // best-effort daemon; server keeps running, launcher exits
    return;
  }
  // Default: stay in the foreground serving (like serve-v3-preview.sh). The
  // skill/harness runs this as a background process and reads the URL line.
  const cleanup = () => {
    try { child.kill("SIGTERM"); } catch { /* noop */ }
    writeServers(readServers().filter((e) => e.port !== port));
    process.exit(0);
  };
  process.on("SIGINT", cleanup);
  process.on("SIGTERM", cleanup);
  await new Promise(() => {}); // stay alive until signalled
}

main().catch((e) => fail(e.code || "INTERNAL_ERROR", e.message));
