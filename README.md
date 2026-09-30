# sapgui-in-abap2UI5

Classic SAP GUI transactions rebuilt as [abap2UI5](https://github.com/abap2UI5/abap2UI5) apps.

Every screen keeps the layout of the SAP GUI window it replaces - menu bar,
system function bar with the command field, title bar, application function
bar, work area, status bar - but it is rendered as UI5 in the browser. No SAP
GUI installation, no Fiori launchpad, no OData service: the whole thing is
ABAP classes installed with abapGit.

The entry screen is `ZCL_SAPGUI_A2UI5`, a SAP Easy Access clone. It reads the
real area menu (structure `S000`, the same hierarchy the SAP GUI reads), shows
a Favorites folder, and accepts the usual command field syntax (`/nSE80`,
`/oSE80`, `SE80`).

## Transactions

| Transaction     | Screen                        | Class              |
| --------------- | ----------------------------- | ------------------ |
| SAP Easy Access | Entry screen and area menu    | `ZCL_SAPGUI_A2UI5` |
| SE80            | Object Navigator              | `ZCL_SE80_UI`      |
| SE38            | ABAP Editor                   | `ZCL_SE38_A2U5`    |
| SE11            | ABAP Dictionary               | `ZCL_SE11_A2U5`    |
| SE24            | Class Builder                 | `ZCL_SE24_A2U5`    |
| SE37            | Function Builder              | `ZCL_SE37_A2U5`    |
| SE93            | Maintain Transaction          | `ZCL_SE93_A2U5`    |
| SE09, SE10      | Transport Organizer           | `ZCL_SE09_A2U5`    |
| SE16N, SE16     | General Table Display         | `ZCL_SE16N_A2U5`   |
| SM12            | Display and Delete Locks      | `ZCL_SM12_A2U5`    |
| SM21            | Online System Log Analysis    | `ZCL_SM21_A2U5`    |
| SM37            | Overview of Job Selection     | `ZCL_SM37_A2U5`    |
| SM50, SM66      | Work Process Overview         | `ZCL_SM50_A2U5`    |
| ST02            | Setups/Tune Buffers           | `ZCL_ST02_A2U5`    |
| ST05            | Performance Trace             | `ZCL_ST05_A2U5`    |
| ST22            | ABAP Dump Analysis            | `ZCL_ST22_A2U5`    |
| SU01            | User Maintenance              | `ZCL_SU01_A2U5`    |
| SCC4            | Client Administration         | `ZCL_SCC4_A2U5`    |
| RZ10, RZ11      | Profile Parameter Maintenance | `ZCL_RZ11_A2U5`    |
| STMS            | Transport Management System   | `ZCL_STMS_A2U5`    |

The SAP menu tree lists the whole area menu, so it also shows transactions that
are not implemented here. Starting one of those gives a message instead of a
screen, and a transaction that does not exist at all is reported as such.

### What writes and what does not

Almost everything is display only. `ZCL_ZLK05_SYS_API`, which every screen uses
to read the system, has no method that changes system state.

Two exceptions:

- **SE80** (`ZCL_SE80_API`) is a real Workbench. It saves source with `INSERT
  REPORT`, activates objects, creates and deletes classes, interfaces and
  programs, and registers objects in transports.
- **SE16N** stores its display variants in `ZSE16N_A2U5_VAR`. It never changes
  the data of the table being displayed - the browser itself is read only.

**There are no authorization checks yet.** The SAP GUI transactions check
S_TCODE, S_TABU_DIS, S_DEVELOP and friends; these apps do not. Function modules
that check on their own still do, but the table browsers select from any table
and SE80 writes source with `INSERT REPORT` for every user who reaches the
abap2UI5 HTTP service. Until the checks are in (the first item of
[CONCEPT.md](CONCEPT.md)), install it only where every user of that service may
use the Workbench and read every table anyway.

## Requirements

- SAP_BASIS 7.50 or higher, standard ABAP. Not ABAP Cloud - the screens read
  system tables (`TADIR`, `TRDIR`, `SNAP`, `DD03L`, ...) and use classic
  Workbench APIs that are not released for the ABAP Cloud language version.
- [abap2UI5](https://github.com/abap2UI5/abap2UI5), the UI5 runtime. The views
  are built with its view builder `Z2UI5_CL_UI5_VIEW_BUILDER`, so there is no
  second dependency.

## Installation

Install abap2UI5 first, then this repository, both with
[abapGit](https://abapgit.org):

```
https://github.com/abap2UI5/abap2UI5
https://github.com/oblomov-dev/sapgui-in-abap2UI5
```

Follow the [abap2UI5 quickstart](https://abap2ui5.github.io/docs/get_started/quickstart.html)
to set up the HTTP handler, then open it with the entry screen as the start
app - with the ICF path you gave the handler, for example:

```
/sap/bc/http/sap/z2ui5?app_start=ZCL_SAPGUI_A2UI5
```

From there the command field and the menu tree reach every screen listed above.

## Repository layout

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

## Development

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
intersect, so the first run needs network access.

CI, in `.github/workflows`:

| Workflow        | Trigger                       |
| --------------- | ----------------------------- |
| `abaplint`      | push to main, pull request    |
| `abap2ui5lint`  | push to main, pull request    |
| `ABAP_STANDARD` | push to main, pull request    |
| `auto_fix`      | weekly, opens a pull request  |
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

## Downport

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
