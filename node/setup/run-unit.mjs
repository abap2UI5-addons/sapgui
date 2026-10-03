#!/usr/bin/env node
/*
 * run-unit - runs the transpiled ABAP Unit tests of src/ in Node.
 *
 * The transpiler writes node/output/index.mjs, whose runner stops at the
 * first failing test. This one runs every test, prints one line per
 * failure with the assertion text, a summary at the end, and exits 1
 * when anything failed - so one run shows the whole state.
 *
 *   node node/setup/run-unit.mjs              every test
 *   node node/setup/run-unit.mjs ZCL_SM37     only objects whose name starts so
 *   UNIT_STACK=1 node node/setup/run-unit.mjs ...   with the stack of each failure
 *
 * Needs `npm run transpile` first (node/output is not in the repository).
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const OUT = path.join(ROOT, "node", "output");
const INDEX = path.join(OUT, "index.mjs");

if (!fs.existsSync(INDEX)) {
  console.error("node/output/index.mjs is missing - run `npm run transpile` first.");
  process.exit(2);
}

// the test list is the getData( ) function of the generated runner
const src = fs.readFileSync(INDEX, "utf8");
const start = src.indexOf("function getData()");
const end = src.indexOf("  return ret;\n}", start);
if (start < 0 || end < 0) {
  console.error("node/output/index.mjs has no getData( ) - transpiler changed its runner?");
  process.exit(2);
}
const getData = new Function(src.slice(start, end + "  return ret;\n}".length) + "\nreturn getData;")();

await import(pathToFileURL(path.join(OUT, "init.mjs")).href);

const filter = (process.argv[2] || "").toUpperCase();
const failures = [];
let passed = 0;
let skipped = 0;

const text = (err) => {
  // an ABAP exception: the assertion message lives in its attributes
  for (const key of ["msg", "message", "mv_message"]) {
    const v = err?.[key]?.get?.();
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  return String(err?.message || err?.constructor?.name || err).split("\n")[0];
};

for (const st of getData()) {
  if (filter && !st.objectName.startsWith(filter)) continue;
  const imported = await import(pathToFileURL(path.join(OUT, st.filename)).href);
  const localClass = imported[st.localClass];
  try {
    if (localClass.class_setup) await localClass.class_setup();
  } catch (err) {
    failures.push(`${st.objectName} ${st.localClass} class_setup: ${text(err)}`);
    continue;
  }
  for (const m of st.methods) {
    const name = `${st.objectName} ${st.localClass}->${m.name}`;
    if (m.skip) { skipped++; continue; }
    const test = await (new localClass()).constructor_();
    const fa = test.FRIENDS_ACCESS_INSTANCE;
    try {
      if (fa.setup) await fa.setup();
      await fa[m.name]();
      passed++;
    } catch (err) {
      failures.push(`${name}: ${text(err)}`);
      if (process.env.UNIT_STACK) console.log(name, err?.stack || err);
    } finally {
      try { if (fa.teardown) await fa.teardown(); } catch { /* reported by the test itself */ }
    }
  }
  if (localClass.class_teardown) await localClass.class_teardown();
}

for (const f of failures) console.log("FAIL " + f);
console.log(`\n${passed} passed, ${failures.length} failed, ${skipped} skipped`);
process.exit(failures.length ? 1 : 0);
