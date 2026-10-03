# Concept: where sapgui goes next

Written 2026-09-30, after moving the views to `z2ui5_cl_ui5_view_builder` and
adopting the abap2UI5 linter; brought up to date 2026-10-03, after the
authorization checks, nine more transactions and the split of the system API
arrived from the development system. Ordered by what has to happen first, not
by what is most fun.

## Where it stands

- 29 apps for 35 transaction codes plus SAP Easy Access, 48 classes and 4 interfaces, about
  37,000 lines, 629 ABAP Unit tests against `ZCL_SAPGUI_CLIENT_DBL`.
- Green: abaplint (style profile and SAP_BASIS 7.50), the abap2UI5 linter and
  the unit tests, transpiled to JavaScript (section 2).
  The update from the system arrived red on all three (PCRE, which needs
  7.55, 20 TEST-SEAMs, `v =` for data in the views) and was brought back to
  green in the commit after it.
- Not verified by anything that runs without a system:
  - the tests of the database layer - they read the real system,
  - the contents of the views - the linter checks the ABAP side of every app
    but rebuilds no control, because the view is opened in
    `ZCL_SAPGUI_FRAME` and not in the app class - now covered by
    `npm run views` (section 2), but only for the first screen of each app,
- About 300 buttons and fields are shown but disabled ("not available in this
  environment"). That is the honest SAP GUI look, and also the size of the
  functional backlog.

## 1. Authorization checks - done

**Status 2026-10-03:** implemented as proposed below. `ZCL_SAPGUI_AUTH` holds
every check, `guard_app( )` runs S_TCODE plus the basic object check at the
start of every roundtrip of every app, the API classes check the concrete
object, a missing authorization ends in the "No Authorization" screen with the
message from message class `ZSAPGUI`, and SE80 is read-only unless
`ZCL_SAPGUI_SE80_API=>c_write_enabled` is switched on. The AUTHORITY-CHECK
statements sit behind `ZIF_SAPGUI_AUTH_SYS`, so the unit tests decide each
check with a double instead of TEST-SEAMs (section 2). What is left: compare
each screen with a restricted user against the original.

The table and the proposal, as written before:

| Where | What happens today | Standard check to add |
| --- | --- | --- |
| router, command field | any implemented transaction starts | `AUTHORITY_CHECK_TCODE` (S_TCODE) for the typed code, like the SAP GUI |
| SE16N, SE80 table preview | `SELECT * FROM (name)` on any table, `USR02` included | `VIEW_AUTHORITY_CHECK` (S_TABU_DIS / S_TABU_NAM) |
| SE80, SE38 | `INSERT REPORT`, create, delete, activate | S_DEVELOP with ACTVT 01/02/06/07, OBJTYPE, OBJNAME, DEVCLASS - and 03 for display |
| SU01 | user details | S_USER_GRP ACTVT 03 |
| SM12, SM50, SM21, ST05, ST22, ST02 | admin data | S_ENQUE, S_ADMI_FCD (the codes the originals check) |
| STMS, SCC4, RZ11 | transport and system settings | S_CTS_ADMI, S_TABU_DIS for T000, S_RZL_ADM |

Proposal:

- One class `ZCL_SAPGUI_AUTH` (behind an interface, so the double can say "no")
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

**Status 2026-10-03: done.** The apps reach the system only through three
interfaces - `ZIF_SAPGUI_SYS_API` (behind the static facade
`ZCL_SAPGUI_SYS_API`, so the call sites stayed), `ZIF_SAPGUI_SE80_API` and
`ZIF_SAPGUI_AUTH_SYS` (the AUTHORITY-CHECK statements, which replaced the
friend-only fake table of `ZCL_SAPGUI_AUTH`). Each has a `FOR TESTING` double;
every test class installs them in `setup( )`. The real implementations are
created by name, so the transpile leaves the database layer out, and the
`unit` workflow runs 568 tests in Node on every pull request (2 skipped with a
reason; the integration tests of the database layer run on a system only).
Then `npm run views` starts every app in that build, writes the 29 views to
`node/views/` and lints them with the property and the render gate - 4,363
controls instead of 1. Two real defects surfaced on the way: two SE93 tests
had been red on every system since the frame changed its menu tooltip, and
the SE16N table suggestion used `core:Item`, which has no `additionalText`,
so the descriptions never showed. Left as hints: every view declares the
`table` and `editor` namespaces whether it uses them or not
(`ZCL_SAPGUI_FRAME=>open_window`).

The plan, as written before:

**Make the apps independent of the system.** The apps call
`ZCL_SAPGUI_SYS_API` statically, 37 different methods; SE80 already goes through
an instance of `ZCL_SAPGUI_SE80_API`. Proposal: interfaces `ZIF_SAPGUI_SYS_API` and
`ZIF_SAPGUI_SE80_API`, one injection point per app (a factory with a test seam that is
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
- each test that renders a screen writes its view to `test/views/*.view.xml`
  (done as `node/views/`, by a script over the transpiled build rather than
  by the tests),
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
  CI (branch protection). The rule is in AGENTS.md; the branch protection
  itself is a repository setting an owner has to switch on.
- **The scratch class** `ZCL_ZLK05_TMP_PROBE` - done: it is gone from the
  package, and its excludes are gone from the configs.
- **AGENTS.md** - done, with `CLAUDE.md` pointing at it, like the other
  abap2UI5 repositories: the builder
  (`ele`/`tag`/`a`/`end`, `a( b = )` for flags, `a( t = )` for data), no system
  access outside the API classes, the authorization rule, how to run the checks.
  The builder rename broke this repository because nothing here said which
  builder to use and where it comes from.
- **A weekly linter bump** - done, `bump-linter.yaml` (from abap2UI5/samples,
  gated by the linter over `src/` and over the rendered views), so the
  next framework change arrives as a failing pull request instead of as a red
  main branch weeks later - the `ai-demokit` rename sat unnoticed that way.

## 4. Architecture clean-up

- **Names** - done: one prefix for everything, `ZCL_SAPGUI_<TCODE>`,
  `ZCL_SAPGUI_FRAME`, `ZIF_SAPGUI_SYS_API`, message class `ZSAPGUI`; the entry
  screen is `ZCL_SAPGUI_START`. Only the SE16N variants table kept its name,
  because it holds the users' data. (Before: `ZCL_*_A2U5`, `ZCL_SAPGUI_A2UI5`,
  `ZCL_SE80_UI`/`ZCL_SE80_API` and the `ZLK05` of the original package.)
- **Split the system API** - done: the logic sits in one class per area
  (`ZCL_SAPGUI_API_DEV`, `_ADM`, `_MON`, `_OPS`, `_REPO`, `_TRN`) behind
  `ZIF_SAPGUI_SYS_API` and `ZCL_SAPGUI_SYS_API_DB`, and `ZCL_SAPGUI_SYS_API`
  stays the single entry point (section 2).
- **A screen base class** - done: `ZCL_SAPGUI_SCREEN` owns `main( )` - the
  authorization guard, `on_init( )`, `render( )` when navigated back, the
  frame event, `on_event( )` - and the command field and status bar
  attributes. About 840 lines less; three screens redefine `on_frame_event( )`.
- **The rest of the event API** - done: `client->get_event_arg( n )`
  everywhere, and the builder chains in the house layout, which
  `chain-house-layout` now enforces in `abap2ui5lint.jsonc`.
- **Texts.** Every text is hard-coded English. If other logon languages
  matter: text symbols or a message class, read the way the originals read
  theirs.
- **SE16N variants** - done: stored as the XML of `CALL TRANSFORMATION id`
  (kernel, no dependency). A variant still in the JSON of `z2ui5_cl_util`
  is read once more with it and stored as XML right away, so the table
  converts itself as its variants are used; no conversion run needed.

## 5. Downport to 7.02

**Decided 2026-10-03: not a goal.** SAP_BASIS 7.50 is the floor, said so in
the README; the 702 configuration, `auto_downport`, `ABAP_702` and the
`-702` handling of `core-pin.mjs` are gone. SLG1 reads its messages with the
classic BAL function modules instead of `CL_BALI_LOG_DB`, which is not there
on every 7.50 system. What the analysis said before:

Decide first whether 7.02 is a goal at all. If it is:

- the first blocker aborts the whole downport: a table expression in an ELSEIF
  (`ZCL_SAPGUI_SE80`, `lt_arg[ 2 ] = 'METH'`),
- then the list in the README: joins with the strict SQL column list, COND
  inside VALUE, inline declarations from `CL_OO_CLIF_SOURCE`,
- then let `auto_downport` run on every push to main, as abap2UI5 does.

If it is not, say "7.50 and up" in the README and delete the 702 configuration
and both workflows, so nobody maintains a pipeline nobody uses.

## 6. Functionality

The disabled functions of the existing screens first - they are visible to
every user today.

Done since the first version of this list: SLG1, SM59, SP01, SE91, SM04 and
SM30 (display only - it hands the table to SE16N), and beyond the list SU53,
PFCG and WE02/WE05; on 2026-10-03 SE03 (Search for Objects in
Requests/Tasks, opening the request in SE09) and SE01 (the Transport
Organizer of SE09). Still open: SICF, SM13, SE84 and SM30 maintenance.
SICF and SM13 read tables (ICFSERVICE, VBHDR) that nothing here reads yet,
so they want to be written on a system, where the field names are checked
on activation - abaplint does not know SAP's tables and a wrong field only
shows when the class is activated. The original list:

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

1. Section 1, authorization - done.
2. Section 3, AGENTS.md and linter bump - done; branch protection is a
   setting an owner of the repository has to switch on.
3. Section 2, interfaces, transpiled tests, view snapshots - done.
4. Section 4 names and base class, event API, SE16N variants - done.
5. Section 5 - decided: 7.50 is the floor, no 7.02.
6. Section 6 - SE03 and SE01 done.

What is left, in this order:

- **Check on a system.** Everything since 2026-10-03 was built without one:
  the global friends with FOR TESTING classes, the abstract base class with
  the LOCAL FRIENDS tests of its subclasses, the classes created by name,
  the BAL function modules of SLG1 and the conversion of old SE16N variants
  want one activation and one run of the unit tests on a real system.
- **SE16N reads the displayed table and its variants itself** - the one
  screen that still touches the database directly. Behind
  `ZIF_SAPGUI_SYS_API` it would be a dynamic read returning a data
  reference, and the variants a small store interface of their own.
- **Section 6**: SICF and SM13 (written on a system), SE84, SM30
  maintenance, and the functions shown disabled in the existing screens.
- **Texts** (section 4): only if other logon languages matter.
