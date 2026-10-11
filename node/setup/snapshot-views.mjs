#!/usr/bin/env node
/*
 * snapshot-views - the view of every screen, as the browser gets it.
 *
 * Every app hands its view to ZCL_SAPGUI_FRAME, which opens the
 * mvc:View and the window bands in another class - so the abap2UI5 linter,
 * reading one class at a time, rebuilds no control of any screen. This
 * script runs the transpiled apps instead (npm run transpile first): it
 * installs the doubles of the system API and the authorization checks,
 * starts every app the command field knows plus SAP Easy Access against
 * ZCL_SAPGUI_CLIENT_DBL (SE80 with ZCL_SAPGUI_SE80_API_DBL), and writes the view each one displays to
 * node/views/<class>.view.xml. The linter then checks those files - every
 * control, property, aggregation and binding, against UI5 1.71.
 *
 *   node node/setup/snapshot-views.mjs
 */
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
const OUT = path.join(ROOT, "node", "output");
const VIEWS = path.join(ROOT, "node", "views");

if (!fs.existsSync(path.join(OUT, "init.mjs"))) {
  console.error("node/output is missing - run `npm run transpile` first.");
  process.exit(2);
}

// The transpiler (2.14 on) writes the classes of src/ to node/output/project/,
// next to one folder per dependency; init.mjs stays at the top.
const load = async (name) =>
  (await import(pathToFileURL(path.join(OUT, "project", `${name}.clas.mjs`)).href))[name];
await import(pathToFileURL(path.join(OUT, "init.mjs")).href);

const sysDbl = await load("zcl_sapgui_sys_api_dbl");
const authDbl = await load("zcl_sapgui_auth_sys_dbl");
const clientDbl = await load("zcl_sapgui_client_dbl");
const router = await load("zcl_sapgui_router");
const se80Dbl = await load("zcl_sapgui_se80_api_dbl");

// the router reads the transaction texts through the system API too
await sysDbl.install();
const classes = new Set(["ZCL_SAPGUI_START"]);
for (const row of (await router.get_apps()).array()) {
  const cls = row.get().class.get().trim();
  if (cls) classes.add(cls);
}

fs.rmSync(VIEWS, { recursive: true, force: true });
fs.mkdirSync(VIEWS, { recursive: true });

let failed = 0;
for (const cls of [...classes].sort()) {
  const name = cls.toLowerCase();
  try {
    await sysDbl.install();
    await authDbl.install();
    const AppClass = await load(name);
    const app = await new AppClass().constructor_();
    if (name === "zcl_sapgui_se80") {
      // the Object Navigator takes its repository API as an instance
      const api = new abap.types.ABAPObject();
      api.set(await new se80Dbl().constructor_());
      app.mo_api.set(api);
    }
    const client = await new clientDbl().constructor_();
    client.mv_on_init.set(abap.builtin.abap_true);
    const ref = new abap.types.ABAPObject();
    ref.set(client);
    await app.z2ui5_if_app$main({ client: ref });
    const view = client.mv_view.get();
    if (!view) throw new Error("rendered no view");
    fs.writeFileSync(path.join(VIEWS, `${name}.view.xml`), view);
    console.log(`${cls}: ${view.length} characters`);
  } catch (err) {
    failed++;
    console.log(`${cls}: FAILED - ${err?.message || err}`);
  } finally {
    await sysDbl.uninstall();
    await authDbl.uninstall();
  }
}
process.exit(failed ? 1 : 0);
