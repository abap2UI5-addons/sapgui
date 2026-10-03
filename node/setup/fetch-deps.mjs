#!/usr/bin/env node
/*
 * fetch-deps - the two git dependencies of the transpiled unit tests,
 * at fixed versions, under node/deps/ (not in the repository).
 *
 *   abap2UI5        the release the abaplint configs are pinned to
 *                   (scripts/core-pin.mjs), in its downported form
 *                   <tag>-702 - the form abap2UI5 transpiles itself
 *   open-abap-core  the ABAP kernel classes for Node, at OPEN_ABAP_CORE -
 *                   the commit abap2UI5 pins in its own fetch-deps.mjs
 *
 * The transpiler reads node/deps/ before it falls back to cloning the URL
 * in node/setup/abap_transpile.json, so a run without this script would
 * transpile against whatever upstream HEAD is today. A no-op when both are
 * already at the right version.
 *
 *   node node/setup/fetch-deps.mjs
 *
 * To move open-abap-core: take the sha from abap2UI5's
 * node/setup/fetch-deps.mjs at the pinned release, then `npm run transpile`
 * and `npm run unit`.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const DEPS = path.join(ROOT, "node", "deps");
const OPEN_ABAP_CORE = "b2d219df61f8c077df7a038bc43d168f9f280fbf";

// an argument array, never a shell string
const git = (args, cwd) =>
  execFileSync("git", args, { cwd, stdio: ["ignore", "pipe", "pipe"] }).toString().trim();

const pin = execFileSync(process.execPath, [path.join(ROOT, "scripts", "core-pin.mjs"), "get"])
  .toString().trim();
// the downported tag: abap2UI5 transpiles its own downport, the plain
// release tag does not go through the transpiler (tried with 1.146.0).
// This is the framework's build, not a 7.02 target of this repository.
const coreRef = pin === "main" ? "702" : `${pin}-702`;

function ensure(name, url, ref, isSha) {
  const dir = path.join(DEPS, name);
  const marker = path.join(dir, ".fetched-ref");
  if (fs.existsSync(marker) && fs.readFileSync(marker, "utf8").trim() === ref) {
    console.log(`${name}: ${ref} (already there)`);
    return;
  }
  fs.rmSync(dir, { recursive: true, force: true });
  fs.mkdirSync(DEPS, { recursive: true });
  if (isSha) {
    git(["init", "-q", dir], ROOT);
    git(["fetch", "-q", "--depth", "1", url, ref], dir);
    git(["checkout", "-q", "FETCH_HEAD"], dir);
  } else {
    git(["clone", "-q", "--depth", "1", "--branch", ref, url, dir], ROOT);
  }
  fs.writeFileSync(marker, ref + "\n");
  console.log(`${name}: ${ref}`);
}

ensure("abap2ui5", "https://github.com/abap2UI5/abap2UI5", coreRef, false);
ensure("open-abap-core", "https://github.com/open-abap/open-abap-core", OPEN_ABAP_CORE, true);
