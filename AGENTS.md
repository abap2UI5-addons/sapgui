# AGENTS.md — AI Assistant Guide for sapgui

> This file follows the cross-tool AGENTS.md convention and is the single
> agent instruction file of this repository. `CLAUDE.md` next to it is a
> pointer at this file, nothing more.

## What this repository is

Classic SAP GUI transactions - SE80, SE16N, SM37, ST22, SU01 and about
thirty more - rebuilt as [abap2UI5](https://github.com/abap2UI5/abap2UI5)
apps, installed with abapGit into a standard ABAP system (SAP_BASIS 7.50 and
up). Every screen looks like a SAP GUI window: menu bar, system bar with the
command field, title bar, application toolbar, work area, status bar.

What users see is in [README.md](README.md); what is planned and why, in
[CONCEPT.md](CONCEPT.md). This file is the rules for changing it.

**Language:** English for all code, comments, docs, commit messages, PRs.

## Layout

| Path | |
|---|---|
| `src/zcl_sapgui_start.*` | SAP Easy Access, the entry screen (`app_start=ZCL_SAPGUI_START`) |
| `src/zcl_sapgui_<tcode>.*` | One class per transaction, inheriting from `ZCL_SAPGUI_SCREEN` |
| `src/zcl_sapgui_screen.*` | The abstract base of every screen: `main( )`, the frame events |
| `src/zcl_sapgui_frame.*` | The window bands, the System and Help menus, popups |
| `src/zcl_sapgui_router.*` | The command field: which class a transaction code starts |
| `src/zcl_sapgui_sys_api.*`, `zif_sapgui_sys_api.*` | Everything the screens read from the system - the facade and its interface |
| `src/zcl_sapgui_sys_api_db.*`, `zcl_sapgui_api_*.*` | ... the implementation on a system, one class per area |
| `src/zif_sapgui_se80_api.*`, `zcl_sapgui_se80_api.*` | The SE80 repository API - the only class that writes |
| `src/zcl_sapgui_auth.*`, `zif_sapgui_auth_sys.*`, `zcl_sapgui_auth_sys.*` | The authorization checks and their AUTHORITY-CHECK statements |
| `src/*_dbl.*` | Test doubles: client, system API, SE80 API, authorizations |
| `src/zsapgui.msag.xml` | Message class of the status bar messages |
| `src/zse16n_a2u5_var.tabl.xml` | SE16N display variants - the one object with the old name, it holds data |
| `node/setup/` | Transpile config, pinned dependencies, the unit runner, the view snapshots |
| `scripts/core-pin.mjs` | Reads and moves the abap2UI5 release the checks run against |

## Rules for `src/`

**Names.** Every object is `ZCL_SAPGUI_*`, `ZIF_SAPGUI_*` or message class
`ZSAPGUI`; a screen is `ZCL_SAPGUI_<TCODE>`. Keep object names at 30
characters. abapGit turns a rename into delete plus create on every
installation - do not rename lightly, and never rename
`ZSE16N_A2U5_VAR`.

**The screens never touch the system.** No `SELECT`, `CALL FUNCTION`,
`AUTHORITY-CHECK`, Workbench class or BAdI in a screen class, the frame, the
router or `ZCL_SAPGUI_AUTH`. They go through:

- `ZCL_SAPGUI_SYS_API` for every read - add the method to
  `ZIF_SAPGUI_SYS_API`, implement it in `ZCL_SAPGUI_SYS_API_DB` (delegating to
  the `ZCL_SAPGUI_API_*` class of its area), add the static facade method,
  and add it to `ZCL_SAPGUI_SYS_API_DBL` (every interface method implemented,
  following the existing `reply( )` pattern - the transpiler gives no stubs).
  Helpers that only compute stay static in `ZCL_SAPGUI_SYS_API`.
- `ZIF_SAPGUI_SE80_API` for the repository (SE80).
- `ZIF_SAPGUI_AUTH_SYS` for an AUTHORITY-CHECK - the logic and the message
  stay in `ZCL_SAPGUI_AUTH`, only the statement goes into
  `ZCL_SAPGUI_AUTH_SYS`, and the double gets the method.

This is what lets the unit tests run in Node without a system. Half of it is
checked: `npm run transpile` leaves the database layer out, so a screen that
calls one of its classes no longer transpiles. A `SELECT` written straight
into a screen is not caught - it fails only when a test runs it.

One known exception: SE16N still reads the displayed table and its own
variants table itself (dynamic `SELECT * FROM (name)`); moving that behind
the interface is open in CONCEPT.md.

**Authorizations.** Ask what the original transaction asks. The app level -
S_TCODE plus the basic object check - runs in `ZCL_SAPGUI_AUTH=>guard_app( )`
on every roundtrip (the base class does it); a new transaction needs its
basic check in `check_tcode_base( )` and its code in the router. Object level
checks (the table, the object, the user group, the log, ...) go into the API
method before it reads. A refusal ends in a status bar message from
`ZSAPGUI`, never in a silently empty list.

**Nothing writes**, except `ZCL_SAPGUI_SE80_API` (behind its
`c_write_enabled` switch, off by default, and S_DEVELOP) and SE16N's own
variants table. Functions of the original that would change the system are
shown but disabled - the honest SAP GUI look.

**A new screen** is a subclass of `ZCL_SAPGUI_SCREEN` implementing
`on_init( )`, `render( )` and `on_event( )`; redefine `on_frame_event( )` only
to take an event over before the frame (see SLG1). Build the window with
`ZCL_SAPGUI_FRAME` like the existing screens, register the code in
`ZCL_SAPGUI_ROUTER=>get_apps( )`, add its basic authorization, a test class
and a row in the README tables. Titles, menu and function texts are the
original ones (say where they come from in the class header).

**Views** are built with `z2ui5_cl_ui5_view_builder` (abap2UI5's released
builder - never the frozen `z2ui5_cl_xml_view`): `ele( )` opens, `tag( )` is a
leaf, `a( )` an attribute, `end( )` closes. Data goes through `a( t = ... )`,
which escapes it - a brace in `v = ...` is read as a binding. Flags through
`a( b = ... )`. Every control, property, aggregation and icon must exist in
UI5 1.71. The chains follow the abap2UI5 house layout - one call per line,
four spaces per level - which `npx abap2ui5lint --fix` applies.

**Events.** `client->get_event( )` and `client->get_event_arg( n )`.

**abapGit files.** `.xml` sidecars start with the UTF-8 BOM, files end with
one newline, no trailing blanks, lines under 255 characters. Never "tidy" a
`.clas.xml` by hand - it is a serialization. A new object needs its sidecar
(copy one of the same kind and change name and description; an abstract
class carries `<CLSABSTRCT>`, a FOR TESTING class `<CATEGORY>05</CATEGORY>`).

**Release floor 7.50.** `npm run lint_standard` checks it. No `FIND PCRE`
(7.55), no `INTO CORRESPONDING FIELDS OF TABLE @DATA( )`, no APIs newer than
7.50 (CL_BALI_* was replaced in SLG1 for that reason). A regex is POSIX with
`##REGEX_POSIX`, or better plain string logic.

## Tests

Every test class installs the doubles in `setup( )` and removes them in
`teardown( )`:

```abap
mo_api = zcl_sapgui_sys_api_dbl=>install( ).   " what the system answers
zcl_sapgui_auth_sys_dbl=>install( ).           " every check passes until deny( )
```

A test states what the system answers (`mo_api->answer( iv_method = ...
iv_param = ... iv_key = ... iv_value = ... )`) instead of relying on what a
development system happens to contain. Tests that must read the real
database belong to `ZCL_SAPGUI_SYS_API_DB` or `ZCL_SAPGUI_SE80_API`, which
run on a system only.

Things that behave differently in the Node runtime, each worked around with
a comment where it happens: iXML `get_item( )` counts from 1 and `get_type( )`
is not implemented (`ZCL_SAPGUI_CLIENT_DBL` iterates and reads the name);
`DELETE TABLE ... WITH TABLE KEY` compares only the first key component
(use `DELETE ... WHERE`); a DDIC type open-abap-core does not know fails when
the code using it runs - prefer `string` and local types in transpiled code,
and skip a test in `node/setup/abap_transpile.json` with a note only when
the type is the point of the test.

## Validation

```bash
npm ci
npm test      # all of the below
```

| Command | What it does |
|---|---|
| `npm run lint` | abaplint, style and correctness profile |
| `npm run lint_standard` | abaplint, syntax against SAP_BASIS 7.50 |
| `npm run lint_abap2ui5` | the abap2UI5 linter over `src/` |
| `npm run transpile` | ABAP to JavaScript into `node/output` |
| `npm run unit` | the unit tests in Node, every failure listed |
| `npm run views` | the view of every screen into `node/views`, linted; CI adds `-- --render` |

All of it has to be green before a push. abaplint and the transpiler clone
their dependencies on the first run (network needed).

The abap2UI5 release the checks run against is pinned (`"branch"` in the
three abaplint configs); read and move it only with `scripts/core-pin.mjs`.
`bump-core` and `bump-linter` move the pin and the linter weekly through a
pull request, after the gates passed.

## Workflow

- Changes reach `main` only through a pull request with green CI.
- The development system and this repository drifted once: a push from the
  system undid two fixes made here. Pull into the system before editing
  there, never edit in both places at the same time, and treat a push from
  the system like any other change - it goes through the same checks.
- A push from the system that breaks the checks is repaired here, in a
  commit of its own, before anything else is built on it.
