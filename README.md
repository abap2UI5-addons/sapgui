# sapgui

**The SAP GUI in your browser.** Twenty classic transactions - SE80, SE16N,
SM37, ST22, SU01 and more - rebuilt as [abap2UI5](https://github.com/abap2UI5/abap2UI5)
apps. Pure ABAP, installed with abapGit. No SAP GUI installation, no Fiori
launchpad, no OData service.

## What is this?

You open one URL in the browser and land on **SAP Easy Access**, the same
start screen the SAP GUI shows. Type `/nSM37` into the command field, or click
through the SAP menu, and the job overview opens - in a window that looks like
the SAP GUI: menu bar, command field, title bar, toolbar, work area, status
bar.

Behind every screen is one ABAP class. abap2UI5 turns it into a UI5 page in the
browser, so nothing has to be installed on the client and nothing has to be
set up in the frontend server.

Good for:

- **Looking into a system without the SAP GUI** - from a Mac, a tablet, a
  locked-down laptop or any machine with a browser: read tables, check jobs,
  dumps, locks, work processes, transports, users.
- **Browser-based development** - SE80 is a real Workbench: edit, save, check
  and activate source code.
- **Learning abap2UI5** - twenty full apps with selection screens, lists,
  trees, detail screens and a shared window frame, plus 431 unit tests.

## What it is not

- **Not the SAP GUI for HTML (WebGUI).** The WebGUI runs the original screens.
  This project rebuilds a selection of them from scratch, so only the
  transactions listed below exist, and not every function of the original is
  there. Buttons that are not implemented yet are shown, but disabled.
- **Not for ABAP Cloud.** It reads system tables and uses classic Workbench
  APIs, so it needs a standard ABAP system (see [Requirements](#requirements)).
- **Not [abap-cloud-gui](https://github.com/abap2UI5-addons/abap-cloud-gui).**
  That one is a framework for writing *your own* apps like classic reports
  (selection screen, `WRITE`, ALV). This one is a finished set of *SAP's*
  transactions.

## Before you install: read this

> [!WARNING]
> **There are no authorization checks yet.** Every user who can reach the
> abap2UI5 HTTP service can read any table (`USR02` included) and change
> source code through SE80 - regardless of their SAP authorizations.
> Install it only on systems where every user of that service may use the
> Workbench and read every table anyway, for example a private sandbox or a
> developer trial.

Details: the SAP GUI transactions check S_TCODE, S_TABU_DIS, S_DEVELOP and
friends; these apps do not. Function modules that check on their own still
do. Adding the checks is the first item of [CONCEPT.md](CONCEPT.md).

## Quick start

1. Install [abap2UI5](https://github.com/abap2UI5/abap2UI5) with
   [abapGit](https://abapgit.org) and set up its HTTP handler as described in
   the [abap2UI5 quickstart](https://abap2ui5.github.io/docs/get_started/quickstart.html).
2. Install this repository with abapGit:

   ```
   https://github.com/abap2UI5-addons/sapgui
   ```

3. Open the entry screen in the browser, with the ICF path you gave the
   handler, for example:

   ```
   /sap/bc/http/sap/z2ui5?app_start=ZCL_SAPGUI_A2UI5
   ```

From there, the command field and the menu tree reach every transaction below.
The command field understands the usual syntax: `SE80`, `/nSE80` (same
window), `/oSE80` (new window).

## Transactions

| Transaction | Screen | What you can do |
| --- | --- | --- |
| SAP Easy Access | Start screen | Browse the SAP menu (the real area menu `S000`) and the Favorites folder, start transactions from the command field |
| SE80 | Object Navigator | Browse packages and objects; display, **edit, save, check and activate** source; create and delete programs, classes and interfaces; where-used list, version compare, pretty printer, search and replace |
| SE38 | ABAP Editor | Find a program and display its source |
| SE11 | ABAP Dictionary | Find database tables, views and data elements and display their fields or definition |
| SE24 | Class Builder | Find a class or interface and display its components |
| SE37 | Function Builder | Find a function module and display its parameters |
| SE93 | Maintain Transaction | Find a transaction code and display what it starts |
| SE09, SE10 | Transport Organizer | Select transport requests by user, type and status; display their objects |
| SE16N, SE16 | General Table Display | Display the content of any table with selection criteria, count entries, save and load display variants |
| SM12 | Display and Delete Locks | List lock entries (display only - nothing is deleted) |
| SM21 | System Log | Read the system log by time range, user, transaction and problem class |
| SM37 | Job Overview | Select background jobs by name, user and status; display their steps |
| SM50, SM66 | Work Process Overview | List the work processes and what they are doing |
| ST02 | Tune Buffers | Display the buffer statistics |
| ST05 | Performance Trace | Display the trace state and the trace filters (starting a trace is not implemented) |
| ST22 | ABAP Dump Analysis | List runtime errors and display a dump in detail |
| SU01 | User Maintenance | Find users and display their details and roles |
| SCC4 | Client Administration | List the clients of the system |
| RZ10, RZ11 | Profile Parameters | Find a profile parameter and display its value, attributes and documentation |
| STMS | Transport Management System | Display the transport domain, its systems and their import queues |

The SAP menu tree shows the whole area menu, so it also lists transactions
that are not rebuilt here. Starting one of those shows a message instead of a
screen, and a transaction that does not exist at all is reported as such.

### What changes the system

Almost nothing. `ZCL_ZLK05_SYS_API`, which every screen uses to read the
system, has no method that changes anything. Two exceptions:

- **SE80** (`ZCL_SE80_API`) saves source with `INSERT REPORT`, activates
  objects, creates and deletes classes, interfaces and programs, and records
  objects in transport requests.
- **SE16N** stores its display variants in its own table `ZSE16N_A2U5_VAR`. It
  never changes the data of the table it displays.

## Requirements

- SAP_BASIS 7.50 or higher, standard ABAP (on-premise, private cloud or a
  developer trial). Not ABAP Cloud - the screens read system tables (`TADIR`,
  `TRDIR`, `SNAP`, `DD03L`, ...) and use classic Workbench APIs that are not
  released for the ABAP Cloud language version.
- [abap2UI5](https://github.com/abap2UI5/abap2UI5) - the only dependency.

## For contributors

Which class implements which transaction:

| Transaction | Class | Transaction | Class |
| --- | --- | --- | --- |
| SAP Easy Access | `ZCL_SAPGUI_A2UI5` | SM12 | `ZCL_SM12_A2U5` |
| SE80 | `ZCL_SE80_UI` | SM21 | `ZCL_SM21_A2U5` |
| SE38 | `ZCL_SE38_A2U5` | SM37 | `ZCL_SM37_A2U5` |
| SE11 | `ZCL_SE11_A2U5` | SM50, SM66 | `ZCL_SM50_A2U5` |
| SE24 | `ZCL_SE24_A2U5` | ST02 | `ZCL_ST02_A2U5` |
| SE37 | `ZCL_SE37_A2U5` | ST05 | `ZCL_ST05_A2U5` |
| SE93 | `ZCL_SE93_A2U5` | ST22 | `ZCL_ST22_A2U5` |
| SE09, SE10 | `ZCL_SE09_A2U5` | SU01 | `ZCL_SU01_A2U5` |
| SE16N, SE16 | `ZCL_SE16N_A2U5` | SCC4 | `ZCL_SCC4_A2U5` |
| RZ10, RZ11 | `ZCL_RZ11_A2U5` | STMS | `ZCL_STMS_A2U5` |

What is planned next, and what is still missing, is in [CONCEPT.md](CONCEPT.md).

### Repository layout

```
src/
  zcl_sapgui_a2ui5.clas.abap     SAP Easy Access, the entry screen
  zcl_se*.clas.abap              one class per transaction
  zcl_sm*.clas.abap
  zcl_st*.clas.abap
  zcl_su01_a2u5.clas.abap
  zcl_scc4_a2u5.clas.abap
  zcl_rz11_a2u5.clas.abap
  zcl_stms_a2u5.clas.abap
  zcl_se80_api.clas.abap         SE80 repository API, the only writing class
  zcl_zlk05_sys_api.clas.abap    shared read only system API
  zcl_zlk05_gui_frame.clas.abap  the six bands of a SAP GUI window
  zcl_zlk05_tcode_router.clas.abap  the command field: which class a code starts
  zcl_zlk05_client_dbl.clas.abap test double for z2ui5_if_client
  zse16n_a2u5_var.tabl.xml       SE16N display variants
```

The apps build views and dispatch events, they never read the system directly -
that is what `ZCL_ZLK05_SYS_API` and `ZCL_SE80_API` are for. The window frame
lives in `ZCL_ZLK05_GUI_FRAME`, so all screens look the same.

There are 431 ABAP Unit tests. They run against `ZCL_ZLK05_CLIENT_DBL` instead
of a live client, so the view and the event wiring can be asserted without a
browser.

### Development

The checks run on Node, no ABAP system needed:

```bash
npm ci
npm test        # abaplint.jsonc, abap_standard.jsonc, abap2ui5lint.jsonc
```

| Command                 | What it does                                        |
| ----------------------- | --------------------------------------------------- |
| `npm run lint`          | style and correctness profile (`abaplint.jsonc`)     |
| `npm run lint_standard` | syntax check against SAP_BASIS 7.50                  |
| `npm run lint_702`      | syntax check against SAP_BASIS 7.02                  |
| `npm run lint_abap2ui5` | the abap2UI5 linter (`abap2ui5lint.jsonc`)           |
| `npm run auto_fix`      | apply the quick fixes abaplint can apply on its own  |
| `npm run auto_downport` | rewrite `src/` to 7.02 syntax                        |

abaplint resolves the dependencies by cloning abap2UI5 and the Steampunk API
intersect, so the first run needs network access. abap2UI5 is **pinned to a
release tag** (the `"branch"` key of the dependency, abap2UI5 CONVENTIONS §9):
users install a release next to this addon, so the checks run against that
release and not against the framework's `main`. Four configs carry the pin
(`abaplint.jsonc`, `.github/abaplint/abap_standard.jsonc`,
`.github/abaplint/auto_fix.jsonc`, and the downported `<tag>-702` form in
`.github/abaplint/abap_702.jsonc`); read and move them only with
`scripts/core-pin.mjs` (`get` fails when they disagree). The `bump-core`
workflow moves the pin weekly to the newest release after `npm run lint` and
`npm run lint_standard` passed on it. Do not drop the key: abaplint then
clones `main` silently.

CI, in `.github/workflows`:

| Workflow        | Trigger                       |
| --------------- | ----------------------------- |
| `abaplint`      | push to main, pull request    |
| `abap2ui5lint`  | push to main, pull request    |
| `ABAP_STANDARD` | push to main, pull request    |
| `auto_fix`      | weekly, opens a pull request  |
| `bump-core`     | weekly, opens a pull request  |
| `auto_downport` | manual                        |
| `ABAP_702`      | push to 702, after a downport |

The [abap2UI5 linter](https://github.com/abap2UI5/linter) checks what abaplint
cannot know about abap2UI5: bindings, events, frontend actions, icons against
the UI5 1.71 floor, the lifecycle of `main( )`, obsolete framework calls. One
limit to know about: it rebuilds a view from the builder chain in the class it
reads, and every screen here hands its view to `ZCL_ZLK05_GUI_FRAME`, which
opens the `mvc:View` and the window bands in another class. So the run summary
says `judged 0 controls` - the ABAP side of every app is checked, the controls
and properties of the views are not yet. The render gate is off for the same
reason.

The one finding silenced in the source is `non-released-api` on
`z2ui5_cl_util=>json_*` in SE16N: the stored display variants in
`ZSE16N_A2U5_VAR` are in that JSON format, and a different serializer would
make the existing ones unreadable.

A few rules are switched off on purpose, with the reason written next to them
in `abaplint.jsonc`. This repository is a rebuild of the ABAP Workbench, so
`INSERT REPORT` and dynamic SQL are the feature rather than an accident, and a
table browser that selects from a table name known only at runtime cannot have
a static column list or `ORDER BY`.

### Downport

`npm run auto_downport` rewrites the sources to 7.02 syntax with abaplint, and
the `auto_downport` workflow pushes the result to a `702` branch that
`ABAP_702` then checks.

**The downport is not green yet**, which is why the workflow is manual and does
not run on every push - it must not force push a broken branch. What abaplint
cannot rewrite today:

- `SELECT` with a `LEFT OUTER JOIN`: the statement keeps its strict SQL form,
  the comma separated column list and the `@` escaped host variables, none of
  which parse on 7.02. Selects without a join are rewritten correctly. Nine
  selects in `ZCL_ZLK05_SYS_API` are affected.
- `COND` nested inside a `VALUE` constructor: the outer constructor is expanded
  but the inner `COND` is left as it is, mostly in `ZCL_SE16N_A2U5`.
- `DATA(x) = <call on a class abaplint cannot resolve>`: without the type the
  inline declaration cannot be split, so it stays. All 55 findings in
  `ZCL_SE80_API` come from the `CL_OO_CLIF_SOURCE` calls.

Making the sources downportable means hoisting those expressions and writing
the joins as separate selects. Until then `npm run lint_702` reports what is
left, and the sources stay on the 7.50 syntax the main branch is checked
against.

## License

[MIT](LICENSE)
