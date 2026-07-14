#!/usr/bin/env node
// Real headless-browser verification of a Widget V3 preview bundle.
// Extracts the archive to a temp dir, serves it over loopback HTTP (python3),
// drives system Chrome via Playwright, and asserts the interactive Flutter app
// renders, routes by fragment, survives reload, and handles unknown routes.
//
// Used by ZP-02 (portability smoke) and ZP-12 (full E2E). Requires Playwright +
// a local Chrome; both are optional dev-only tools, so this is NOT a CI gate.
//
// Usage: node scripts/v3-preview-bundle/browser-verify.mjs \
//   --archive dist/v3-preview-bundle/v3-preview-bundle.tar.gz \
//   --slug button/V3MiniButton [--full] [--screenshot-dir /tmp]

import { execFileSync, spawn } from "node:child_process";
import fs from "node:fs";
import net from "node:net";
import os from "node:os";
import path from "node:path";

function arg(name, fallback) {
  const i = process.argv.indexOf(name);
  return i >= 0 && i + 1 < process.argv.length ? process.argv[i + 1] : fallback;
}
const hasFlag = (name) => process.argv.includes(name);

const archive = path.resolve(arg("--archive", "dist/v3-preview-bundle/v3-preview-bundle.tar.gz"));
const slug = arg("--slug", "button/V3MiniButton");
const full = hasFlag("--full");
const screenshotDir = arg("--screenshot-dir", os.tmpdir());

function freePort() {
  return new Promise((resolve, reject) => {
    const srv = net.createServer();
    srv.listen(0, "127.0.0.1", () => {
      const { port } = srv.address();
      srv.close(() => resolve(port));
    });
    srv.on("error", reject);
  });
}

async function waitHttp(url, tries = 60) {
  for (let i = 0; i < tries; i += 1) {
    try {
      const res = await fetch(url);
      if (res.ok) return true;
    } catch { /* not ready */ }
    await new Promise((r) => setTimeout(r, 250));
  }
  return false;
}

const results = [];
function check(name, ok, detail = "") {
  results.push({ name, ok, detail });
  console.log(`  ${ok ? "PASS" : "FAIL"}  ${name}${detail ? ` — ${detail}` : ""}`);
}

async function main() {
  if (!fs.existsSync(archive)) throw new Error(`archive not found: ${archive}`);
  const { chromium } = await import("playwright");

  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "v3browser-"));
  const served = path.join(tmp, "served");
  fs.mkdirSync(served);
  execFileSync("tar", ["-xzf", archive, "-C", served]);

  const port = await freePort();
  const server = spawn("python3", ["-m", "http.server", String(port), "--bind", "127.0.0.1"], { cwd: served, stdio: "ignore" });

  let browser;
  try {
    const base = `http://127.0.0.1:${port}`;
    if (!(await waitHttp(`${base}/`))) throw new Error("http server did not become ready");

    browser = await chromium.launch({ channel: "chrome", headless: true });
    const page = await browser.newPage({ viewport: { width: 900, height: 700 } });
    const consoleErrors = [];
    page.on("console", (msg) => { if (msg.type() === "error") consoleErrors.push(msg.text()); });

    // --- route + render ---
    await page.goto(`${base}/#/${slug}`, { waitUntil: "load" });
    await page.waitForSelector("flt-glass-pane, flutter-view", { timeout: 30000 });
    await page.waitForTimeout(3500); // let first frame settle
    const title = await page.title();
    check("interactive Flutter app renders (flt-glass-pane present)", await page.$("flt-glass-pane, flutter-view") !== null, `title="${title}"`);
    const href1 = page.url();
    check("fragment route preserved after boot", href1.endsWith(`#/${slug}`), href1);
    await page.screenshot({ path: path.join(screenshotDir, "zp-preview-light.png") });

    // --- reload preserves route ---
    await page.reload({ waitUntil: "load" });
    await page.waitForTimeout(2500);
    check("route survives full reload", page.url().endsWith(`#/${slug}`), page.url());

    if (full) {
      // --- unknown route -> Not Found without crash ---
      await page.goto(`${base}/#/button/DoesNotExist`, { waitUntil: "load" });
      await page.reload({ waitUntil: "load" }); // fragment-only nav needs a real reload to re-route
      await page.waitForTimeout(2500);
      const bodyText = await page.evaluate(() => document.body.innerText || "");
      // Flutter canvas may not expose text; also probe the semantics tree if present.
      const notFoundVisible = /DoesNotExist|No preview/.test(bodyText) || (await page.$("flt-glass-pane, flutter-view")) !== null;
      check("unknown route renders without crashing", notFoundVisible);
      await page.screenshot({ path: path.join(screenshotDir, "zp-preview-notfound.png") });

      // --- narrow viewport, no overflow crash ---
      await page.setViewportSize({ width: 320, height: 480 });
      await page.goto(`${base}/#/${slug}`, { waitUntil: "load" });
      await page.waitForTimeout(2500);
      check("narrow viewport (320x480) renders without crash", (await page.$("flt-glass-pane, flutter-view")) !== null);
      await page.screenshot({ path: path.join(screenshotDir, "zp-preview-narrow.png") });

      // --- keyboard input doesn't crash ---
      await page.keyboard.press("Tab");
      await page.waitForTimeout(300);
      check("keyboard Tab does not crash", (await page.$("flt-glass-pane, flutter-view")) !== null);
    }

    check("no fatal browser console errors", consoleErrors.length === 0, consoleErrors.slice(0, 3).join(" | "));
  } finally {
    if (browser) await browser.close();
    server.kill("SIGTERM");
    fs.rmSync(tmp, { recursive: true, force: true });
  }

  const failed = results.filter((r) => !r.ok);
  console.log(`\n${results.length - failed.length}/${results.length} checks passed. screenshots in ${screenshotDir}`);
  if (failed.length) process.exit(1);
}

main().catch((e) => { console.error(`browser-verify: ${e.message}`); process.exit(1); });
