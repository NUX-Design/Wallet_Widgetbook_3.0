#!/usr/bin/env node
// ZP-03 — Deterministic Widget V3 preview bundle packer.
//
// Packs a built Flutter Web preview host (default `build/web`) into an
// immutable, commit-addressed archive plus a manifest that satisfies the frozen
// contract (mcp-server/v3/bundle_contract.js). The archive is byte-for-byte
// reproducible across machines: entries are sorted, header mtime/uid/gid/mode
// are normalized, and gzip is written without an embedded filename/timestamp.
//
// Usage:
//   node scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs \
//     [--source-dir build/web] [--out-dir dist/v3-preview-bundle] \
//     [--commit <sha>] [--created-at <iso>] [--registry <file>] [--allow-dirty]
//
// In publish mode (default) a dirty git worktree or a non-40-hex commit is
// rejected so a published bundle always traces back to a clean source commit.
//
// The core is exported as packBundle() so tests and the CI pipeline can drive
// it with injected git values instead of shelling out.

import { execFileSync } from "node:child_process";
import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import zlib from "node:zlib";
import {
  V3_PREVIEW_ARCHIVE_NAME,
  V3_PREVIEW_BUNDLE_SCHEMA_VERSION,
  V3_PREVIEW_COMMIT_SHA_PATTERN,
  V3_PREVIEW_ENTRY_PATH,
  V3_PREVIEW_MANIFEST_NAME,
  validateBundleManifest,
} from "../../mcp-server/v3/bundle_contract.js";

const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "../..");

// Recursively collect files under `dir`, returning paths relative to `dir`
// using forward slashes, sorted for deterministic ordering. Rejects symlinks.
export function collectFiles(dir) {
  const out = [];
  const walk = (current, prefix) => {
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      const rel = prefix ? `${prefix}/${entry.name}` : entry.name;
      const abs = path.join(current, entry.name);
      if (entry.isSymbolicLink()) throw new Error(`refusing to pack symlink: ${rel}`);
      if (entry.isDirectory()) walk(abs, rel);
      else if (entry.isFile()) out.push(rel);
      else throw new Error(`refusing to pack non-regular file: ${rel}`);
    }
  };
  walk(dir, "");
  out.sort();
  return out;
}

// --- Minimal deterministic POSIX ustar writer (no dependencies) ------------
function octal(value, length) {
  return value.toString(8).padStart(length - 1, "0");
}

function tarHeader(name, size) {
  if (Buffer.byteLength(name) > 255) throw new Error(`path too long for ustar: ${name}`);
  let prefix = "";
  let filename = name;
  if (Buffer.byteLength(filename) > 100) {
    const idx = name.lastIndexOf("/", 154);
    if (idx <= 0 || Buffer.byteLength(name.slice(idx + 1)) > 100) {
      throw new Error(`path cannot be split into ustar prefix/name: ${name}`);
    }
    prefix = name.slice(0, idx);
    filename = name.slice(idx + 1);
  }

  const header = Buffer.alloc(512, 0);
  header.write(filename, 0, 100, "utf8");
  header.write(`${octal(0o644, 8)}\0`, 100, 8, "ascii"); // mode
  header.write(`${octal(0, 8)}\0`, 108, 8, "ascii"); // uid
  header.write(`${octal(0, 8)}\0`, 116, 8, "ascii"); // gid
  header.write(`${octal(size, 12)}\0`, 124, 12, "ascii"); // size
  header.write(`${octal(0, 12)}\0`, 136, 12, "ascii"); // mtime = 0 (deterministic)
  header.write("        ", 148, 8, "ascii"); // checksum placeholder
  header.write("0", 156, 1, "ascii"); // typeflag: regular file
  header.write("ustar\0", 257, 6, "ascii"); // magic
  header.write("00", 263, 2, "ascii"); // version
  if (prefix) header.write(prefix, 345, 155, "utf8");

  let checksum = 0;
  for (let i = 0; i < 512; i += 1) checksum += header[i];
  header.write(`${octal(checksum, 7)}\0 `, 148, 8, "ascii");
  return header;
}

export function buildTar(sourceDir, files) {
  const chunks = [];
  for (const rel of files) {
    const data = fs.readFileSync(path.join(sourceDir, rel));
    chunks.push(tarHeader(rel, data.length));
    chunks.push(data);
    const pad = (512 - (data.length % 512)) % 512;
    if (pad) chunks.push(Buffer.alloc(pad, 0));
  }
  chunks.push(Buffer.alloc(1024, 0)); // two zero blocks = end of archive
  return Buffer.concat(chunks);
}

// Slugs come from the generated registry (already the preview source of truth).
export function slugsFromRegistry(registryPath) {
  const src = fs.readFileSync(registryPath, "utf8");
  const slugs = [];
  const re = /category:\s*'([^']+)'\s*,\s*widgetName:\s*'([^']+)'/g;
  let m;
  while ((m = re.exec(src)) !== null) slugs.push(`${m[1]}/${m[2]}`);
  slugs.sort();
  return slugs;
}

/**
 * Pure core: build the archive + validated manifest and (optionally) write them.
 * Throws Error on any contract or safety violation so callers fail closed.
 *
 * @param {object} opts
 * @param {string} opts.sourceDir      absolute path to the built web bundle
 * @param {string} opts.registryPath   absolute path to the generated registry
 * @param {string} opts.commit         full 40-hex source commit SHA
 * @param {string} [opts.createdAt]    ISO timestamp (defaults to now)
 * @param {boolean} [opts.allowDirty]  allow a dirty worktree (local test bundle)
 * @param {string} [opts.dirtyStatus]  `git status --porcelain` output ("" = clean)
 * @param {string} [opts.outDir]       if set, archive + manifest are written here
 * @returns {{ archive: Buffer, manifest: object, files: string[] }}
 */
export function packBundle({ sourceDir, registryPath, commit, createdAt, allowDirty = false, dirtyStatus = "", outDir = null }) {
  if (!fs.existsSync(path.join(sourceDir, V3_PREVIEW_ENTRY_PATH))) {
    throw new Error(`source dir has no ${V3_PREVIEW_ENTRY_PATH}; run "flutter build web --release -t lib/preview_v3/main.dart" first.`);
  }
  if (!fs.existsSync(registryPath)) throw new Error(`registry file not found: ${registryPath}`);
  if (!V3_PREVIEW_COMMIT_SHA_PATTERN.test(commit ?? "")) {
    throw new Error(`commit "${commit}" is not a full 40-char hex SHA.`);
  }
  if (!allowDirty && dirtyStatus.trim()) {
    throw new Error(`refusing to publish from a dirty worktree; commit changes or pass allowDirty.\n${dirtyStatus}`);
  }

  const slugs = slugsFromRegistry(registryPath);
  if (slugs.length === 0) throw new Error("no preview slugs found in the registry; run tool/generate_v3_preview_registry.dart first.");

  const files = collectFiles(sourceDir);
  const tar = buildTar(sourceDir, files);
  const archive = zlib.gzipSync(tar, { level: 9 }); // Node gzip header carries no filename/mtime -> deterministic
  const sha256 = crypto.createHash("sha256").update(archive).digest("hex");

  const manifest = {
    schemaVersion: V3_PREVIEW_BUNDLE_SCHEMA_VERSION,
    sourceCommit: commit,
    createdAt: createdAt ?? new Date().toISOString(),
    entryPath: V3_PREVIEW_ENTRY_PATH,
    archiveName: V3_PREVIEW_ARCHIVE_NAME,
    bytes: archive.length,
    sha256,
    slugs,
  };
  const validation = validateBundleManifest(manifest);
  if (!validation.valid) throw new Error(`generated manifest failed contract validation (${validation.code}): ${validation.errors.join("; ")}`);

  if (outDir) {
    fs.rmSync(outDir, { recursive: true, force: true });
    fs.mkdirSync(outDir, { recursive: true });
    fs.writeFileSync(path.join(outDir, V3_PREVIEW_ARCHIVE_NAME), archive);
    fs.writeFileSync(path.join(outDir, V3_PREVIEW_MANIFEST_NAME), `${JSON.stringify(manifest, null, 2)}\n`);
  }

  return { archive, manifest, files };
}

// --- CLI -------------------------------------------------------------------
function parseArgs(argv) {
  const args = { sourceDir: "build/web", outDir: "dist/v3-preview-bundle", registry: "lib/preview_v3/preview_registry.g.dart", commit: null, createdAt: null, allowDirty: false };
  for (let i = 0; i < argv.length; i += 1) {
    const flag = argv[i];
    switch (flag) {
      case "--source-dir": args.sourceDir = argv[++i]; break;
      case "--out-dir": args.outDir = argv[++i]; break;
      case "--registry": args.registry = argv[++i]; break;
      case "--commit": args.commit = argv[++i]; break;
      case "--created-at": args.createdAt = argv[++i]; break;
      case "--allow-dirty": args.allowDirty = true; break;
      case "-h": case "--help": args.help = true; break;
      default: throw new Error(`unknown argument: ${flag}`);
    }
  }
  return args;
}

function gitValue(gitArgs) {
  try {
    return execFileSync("git", gitArgs, { cwd: projectRoot, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"] }).trim();
  } catch {
    return "";
  }
}

function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help) {
    console.log("Usage: node scripts/v3-preview-bundle/pack-v3-preview-bundle.mjs [--source-dir build/web] [--out-dir dist/v3-preview-bundle] [--commit <sha>] [--created-at <iso>] [--registry <file>] [--allow-dirty]");
    return;
  }
  try {
    const { archive, manifest, files } = packBundle({
      sourceDir: path.resolve(projectRoot, args.sourceDir),
      registryPath: path.resolve(projectRoot, args.registry),
      commit: args.commit ?? gitValue(["rev-parse", "HEAD"]),
      createdAt: args.createdAt,
      allowDirty: args.allowDirty,
      dirtyStatus: gitValue(["status", "--porcelain"]),
      outDir: path.resolve(projectRoot, args.outDir),
    });
    const rel = path.relative(projectRoot, path.resolve(projectRoot, args.outDir, V3_PREVIEW_ARCHIVE_NAME));
    console.log(`Packed ${files.length} files -> ${rel}`);
    console.log(`  commit:  ${manifest.sourceCommit}`);
    console.log(`  bytes:   ${archive.length}`);
    console.log(`  sha256:  ${manifest.sha256}`);
    console.log(`  slugs:   ${manifest.slugs.join(", ")}`);
  } catch (error) {
    console.error(`pack-v3-preview-bundle: ${error.message}`);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) main();
