# Concept: where sapgui-in-abap2UI5 goes next

Written 2026-09-30, after moving the views to `z2ui5_cl_ui5_view_builder` and
adopting the abap2UI5 linter. Ordered by what has to happen first, not by
what is most fun.

## Where it stands

- 20 apps for 23 transaction codes plus SAP Easy Access, 25 classes, about 24,000 lines, 431
  ABAP Unit tests against `ZCL_ZLK05_CLIENT_DBL`.
- Green: abaplint (style profile and SAP_BASIS 7.50) and the abap2UI5 linter.
- Not verified by anything that runs without a system:
  - the unit tests - they only run on an ABAP system,
  - the contents of the views - the linter checks the ABAP side of every app
    but rebuilds no control, because the view is opened in
    `ZCL_ZLK05_GUI_FRAME` and not in the app class (`judged 0 controls`),
  - the 7.02 downport - it aborts on its first blocker.
- 245 buttons and fields are shown but disabled ("not available in this
  environment"). That is the honest SAP GUI look, and also the size of the
  functional backlog.

## 1. Authorization checks (first, before anything else)

There is not a single `AUTHORITY-CHECK` in `src/`. The previous README said
users can do exactly what their own authorizations allow - that only holds for
the few function modules that check on their own. It does not hold for:

| Where | What happens today | Standard check to add |
| --- | --- | --- |
| router, command field | any implemented transaction starts | `AUTHORITY_CHECK_TCODE` (S_TCODE) for the typed code, like the SAP GUI |
| SE16N, SE80 table preview | `SELECT * FROM (name)` on any table, `USR02` included | `VIEW_AUTHORITY_CHECK` (S_TABU_DIS / S_TABU_NAM) |
| SE80, SE38 | `INSERT REPORT`, create, delete, activate | S_DEVELOP with ACTVT 01/02/06/07, OBJTYPE, OBJNAME, DEVCLASS - and 03 for display |
| SU01 | user details | S_USER_GRP ACTVT 03 |
| SM12, SM50, SM21, ST05, ST22, ST02 | admin data | S_ENQUE, S_ADMI_FCD (the codes the originals check) |
| STMS, SCC4, RZ11 | transport and system settings | S_CTS_ADMI, S_TABU_DIS for T000, S_RZL_ADM |

Proposal:

- One class `ZCL_ZLK05_AUTH` (behind an interface, so the double can say "no")
  with one method per check above, called by the apps and the two API classes
  before they read or write.
- A missing authorization ends in the status bar message the original shows
  ("You are not authorized to use transaction &"), never in an empty list.
- A system-wide read-only switch that turns every writing function of SE80 off,
  for installations that want the browser but not the Workbench.
- Unit tests per screen: without authorization, no data and the message.

Until this is done the README says plainly that the ICF service must only be
reachable for users who may use the Workbench anyway.

## 2. Tests and views without a system

Two gaps, one fix.

**Make the apps independent of the system.** The apps call
`ZCL_ZLK05_SYS_API` statically, 37 different methods; SE80 already goes through
an instance of `ZCL_SE80_API`. Proposal: interfaces `ZIF_ZLK05_SYS_API` and
`ZIF_SE80_API`, one injection point per app (a factory with a test seam that is
not a `TEST-SEAM`), and a double per interface. The unit tests then need no
database at all - today many of them silently run against whatever the
development system happens to contain.

**Run the tests in CI.** abap2UI5 runs its own unit tests transpiled to
JavaScript on open-abap (`@abaplint/transpiler`); the mcp-server
(`build_backend`, `run_unit_tests`, `run_app`, `interact_app`) does the same for
single apps. With the system API behind an interface the apps no longer touch
system tables or Workbench function modules, which is what makes them
transpilable. Then:

- the 431 tests run on every pull request,
- each test that renders a screen writes its view to `test/views/*.view.xml`,
- the abap2UI5 linter checks those files with the property AND the render gate -
  every control, property, aggregation and binding of every screen, against
  UI5 1.71, in a real browser.

That closes the "judged 0 controls" gap without giving up the shared frame.
Two alternatives were considered and rejected: writing every view as one chain
in its app (throws the frame away, 20 copies of the window bands), and waiting
for the linter to follow views across classes (worth an issue in
abap2UI5/linter, not worth waiting for).

## 3. Development workflow

- **The system and the repository drifted once already.** The commit `fix`
  (2026-08-10) was pushed from the system and silently undid two fixes made
  here before (INTO last in the TSTC selects, the removed scratch class). Rule:
  pull into the system before editing there, never edit in both places at the
  same time, and changes reach `main` only through a pull request with green
  CI (branch protection).
- **The scratch class** `ZCL_ZLK05_TMP_PROBE` lives in the development package,
  so abapGit brings it back on every push. Move it into `$TMP` or a local
  package outside the repository; then drop its excludes from the configs.
- **AGENTS.md**, like the other abap2UI5 repositories: the builder
  (`ele`/`tag`/`a`/`end`, `a( b = )` for flags, `a( t = )` for data), no system
  access outside the API classes, the authorization rule, how to run the checks.
  The builder rename broke this repository because nothing here said which
  builder to use and where it comes from.
- **A weekly linter bump** (abap2UI5/samples has `bump-linter.yaml`), so the
  next framework change arrives as a failing pull request instead of as a red
  main branch weeks later - the `ai-demokit` rename sat unnoticed that way.

## 4. Architecture clean-up

- **Names.** Four schemes side by side: `ZCL_*_A2U5`, `ZCL_SAPGUI_A2UI5`,
  `ZCL_SE80_UI`/`ZCL_SE80_API`, and the `ZLK05` of the original package. One
  prefix for everything (for example `ZCL_CSG_<TCODE>`, `ZCL_CSG_FRAME`,
  `ZIF_CSG_SYS_API`). abapGit turns a rename into delete plus create, so do it
  once, together with the interfaces of section 2, before more screens exist.
- **Split the system API.** `ZCL_ZLK05_SYS_API` has 2,600 lines for every
  transaction. One class per area (transports, jobs, dumps, users, profile
  parameters, ...) behind the interfaces of section 2.
- **A screen base class.** Every app repeats the same main( ) - init,
  navigated, event, frame event, render - and the same five frame calls
  (menu, system bar, title, application bar, status bar). An abstract
  `ZCL_CSG_SCREEN` owning that flow, with the app implementing only its menu,
  its buttons, its work area and its events, removes a few hundred duplicated
  lines and makes the next screen a day's work.
- **The rest of the event API.** `client->get( )-t_event_arg` into
  `client->get_event_arg( n )`, and the builder chains into the house layout
  (the linter's opt-in `chain-house-layout`, which `--fix` applies).
- **Texts.** Every text is hard-coded English. If other logon languages
  matter: text symbols or a message class, read the way the originals read
  theirs.
- **SE16N variants.** The stored variants are JSON written by
  `z2ui5_cl_util`, which abap2UI5 froze. Moving to `CALL TRANSFORMATION id`
  (kernel, no dependency) needs a one-time conversion of `ZSE16N_A2U5_VAR`.

## 5. Downport to 7.02

Decide first whether 7.02 is a goal at all. If it is:

- the first blocker aborts the whole downport: a table expression in an ELSEIF
  (`ZCL_SE80_UI`, `lt_arg[ 2 ] = 'METH'`),
- then the list in the README: joins with the strict SQL column list, COND
  inside VALUE, inline declarations from `CL_OO_CLIF_SOURCE`,
- then let `auto_downport` run on every push to main, as abap2UI5 does.

If it is not, say "7.50 and up" in the README and delete the 702 configuration
and both workflows, so nobody maintains a pipeline nobody uses.

## 6. Functionality

The disabled functions of the existing screens first - they are visible to
every user today. The next transactions, read-only first, by value:

| Transaction | What | Read from |
| --- | --- | --- |
| SLG1 | Application log | BALHDR, `BAL_DB_SEARCH`/`BAL_DB_LOAD` |
| SM59 | RFC destinations (display) | RFCDES |
| SICF | ICF services - where abap2UI5 itself lives | ICFSERVICE, ICFDOCU |
| SP01 | Spool requests | TSP01 |
| SE91 | Message classes | T100A, T100 |
| SM04 / AL08 | User sessions | `TH_USER_LIST` |
| SM13 | Update requests | VBHDR |
| SE84 / SE03 | Repository information system, transport tools | TADIR, E071 |
| SM30 | Table maintenance - writes, so only after section 1 | S_TABU_DIS, locks, transport |

SE01, SE03 and SM30 are in the router's list already, without a screen.

## Order

1. Section 1, authorization - before this is installed anywhere with more than
   one user.
2. Section 3, AGENTS.md, branch protection, linter bump.
3. Section 2, interfaces, transpiled tests, view snapshots - the linter then
   sees every screen.
4. Section 4 names and base class, together, in one migration.
5. Sections 5 and 6 as time allows.
