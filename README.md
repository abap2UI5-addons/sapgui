# sapgui

[![abap2UI5-addons](https://img.shields.io/badge/abap2UI5--addons-app-1873b4)](https://github.com/abap2UI5-addons)
[![ABAP](https://img.shields.io/badge/ABAP-Standard%20%E2%89%A5%207.50-blue)](#installation)
[![abap2UI5](https://img.shields.io/badge/requires-abap2UI5-blue)](https://github.com/abap2UI5/abap2UI5)
[![License](https://img.shields.io/github/license/abap2UI5-addons/sapgui)](LICENSE)
<br>
[![ABAP Standard](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sapgui/ABAP_STANDARD.yaml?branch=main&label=ABAP%20Standard)](https://github.com/abap2UI5-addons/sapgui/actions/workflows/ABAP_STANDARD.yaml)
[![abaplint](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sapgui/abaplint.yaml?branch=main&label=abaplint)](https://github.com/abap2UI5-addons/sapgui/actions/workflows/abaplint.yaml)
[![ABAP Unit](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sapgui/unit.yaml?branch=main&label=ABAP%20Unit)](https://github.com/abap2UI5-addons/sapgui/actions/workflows/unit.yaml)
[![check-abap2UI5](https://img.shields.io/github/actions/workflow/status/abap2UI5-addons/sapgui/abap2ui5lint.yaml?branch=main&label=check-abap2UI5)](https://github.com/abap2UI5-addons/sapgui/actions/workflows/abap2ui5lint.yaml)

**The SAP GUI in your browser.** Thirty classic transactions - SE80, SE16N,
SM37, ST22, SU01, SLG1, WE02 and more - rebuilt as [abap2UI5](https://github.com/abap2UI5/abap2UI5)
apps. Pure ABAP, installed with abapGit into a standard ABAP system. No SAP
GUI installation, no Fiori launchpad, no OData service.

> Part of [abap2UI5-addons](https://github.com/abap2UI5-addons) - addons and apps for [abap2UI5](https://github.com/abap2UI5/abap2UI5), installed with [abapGit](https://abapgit.org).

<img width="600" height="300" alt="image" src="https://github.com/user-attachments/assets/4617ae21-079f-4a1f-acb4-6e51a563b118" />

## Why

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
- **Browser-based development** - SE80 browses packages, displays and checks
  source. Editing, saving and activating are built in and switched off by
  default (see [What changes the system](#what-changes-the-system)).
- **Learning abap2UI5** - 29 full apps with selection screens, lists,
  trees, detail screens and a shared window frame, plus 629 unit tests.

What it is not:

- **Not the SAP GUI for HTML (WebGUI).** The WebGUI runs the original screens.
  This project rebuilds a selection of them from scratch, so only the
  transactions listed below exist, and not every function of the original is
  there. Buttons that are not implemented yet are shown, but disabled.
- **Not for ABAP Cloud.** It reads system tables and uses classic Workbench
  APIs, so it needs a standard ABAP system (see [Installation](#installation)).
- **Not [abap-cloud-gui](https://github.com/abap2UI5-addons/abap-cloud-gui).**
  That one is a framework for writing *your own* apps like classic reports
  (selection screen, `WRITE`, ALV). This one is a finished set of *SAP's*
  transactions.

## Installation

**Requirements**

- SAP_BASIS 7.50 or higher, standard ABAP (on-premise, private cloud or a
  developer trial). Not ABAP Cloud - the screens read system tables (`TADIR`,
  `TRDIR`, `SNAP`, `DD03L`, ...) and use classic Workbench APIs that are not
  released for the ABAP Cloud language version. There is no 7.02 version
  ([Release floor](#release-floor)).
- [abap2UI5](https://github.com/abap2UI5/abap2UI5) - the only dependency.

**Steps** - with [abapGit](https://abapgit.org), in this order:

1. [abap2UI5](https://github.com/abap2UI5/abap2UI5), with its HTTP handler set
   up as described in the [abap2UI5 quickstart](https://abap2ui5.github.io/docs/get_started/quickstart.html)
2. this repository (branch `main`):

   ```
   https://github.com/abap2UI5-addons/sapgui
   ```

**Start** - open the entry screen, SAP Easy Access, in the browser with the
ICF path you gave the handler, for example:

```
/sap/bc/http/sap/z2ui5?app_start=ZCL_SAPGUI_START
```

> [!NOTE]
> **Upgrading from a version before October 2026:** every object was renamed
> to one prefix (`ZCL_SAPGUI_*`, `ZIF_SAPGUI_*`, message class `ZSAPGUI`);
> the entry screen is now `ZCL_SAPGUI_START`. abapGit shows the old objects as
> deleted and the new ones as new - pull, and let it delete the old ones. The
> SE16N variants table `ZSE16N_A2U5_VAR` kept its name, so the saved variants
> stay.

## Usage

From the entry screen, the command field and the menu tree reach every
transaction below. The command field understands the usual syntax: `SE80`,
`/nSE80` (same window), `/oSE80` (new window).

Before you open the service to more people, read
[Authorizations](#authorizations) and [What changes the system](#what-changes-the-system).

## Transactions

| Transaction | Screen | What you can do |
| --- | --- | --- |
| SAP Easy Access | Start screen | Browse the SAP menu (the real area menu `S000`) and the Favorites folder, start transactions from the command field |
| SE80 | Object Navigator | Browse packages and objects; display and check source; where-used list, version compare, pretty printer, search. Edit, save, activate, create and delete are built in and switched off (see below) |
| SE38 | ABAP Editor | Find a program and display its source |
| SE11 | ABAP Dictionary | Find database tables, views and data elements and display their fields or definition |
| SE24 | Class Builder | Find a class or interface and display its components |
| SE37 | Function Builder | Find a function module and display its parameters |
| SE91 | Message Maintenance | Find a message class and display its messages and their long texts |
| SE93 | Maintain Transaction | Find a transaction code and display what it starts |
| SE09, SE10, SE01 | Transport Organizer | Select transport requests by user, type and status; display their objects |
| SE03 | Transport Organizer Tools | Search for objects in requests and tasks; open a request in SE09 |
| SE16N, SE16 | General Table Display | Display the content of any table with selection criteria, count entries, save and load display variants |
| SM30 | Call View Maintenance | Enter a table or view and display it in SE16N (no maintenance) |
| SM04 | User List | List the sessions of the own application server |
| SM12 | Display and Delete Locks | List lock entries (display only - nothing is deleted) |
| SM21 | System Log | Read the system log by time range, user, transaction and problem class |
| SM37 | Job Overview | Select background jobs by name, user and status; display their steps |
| SM50, SM66 | Work Process Overview | List the work processes and what they are doing |
| SM59 | RFC Connections | List the RFC destinations and display their technical settings (no logon data) |
| SLG1 | Application Log | Select logs by object, subobject, user and date; display their messages |
| SP01 | Output Controller | Select spool requests and display their content |
| WE02, WE05 | IDoc List | Select IDocs; display control, status and data records |
| ST02 | Tune Buffers | Display the buffer statistics |
| ST05 | Performance Trace | Display the trace state and the trace filters (starting a trace is not implemented) |
| ST22 | ABAP Dump Analysis | List runtime errors and display a dump in detail |
| SU01 | User Maintenance | Find users and display their details and roles |
| SU53 | Authorization Check | Display the failed authorization checks of the last hours |
| PFCG | Role Maintenance | Find a role and display its description, menu, authorizations and users |
| SCC4 | Client Administration | List the clients of the system |
| RZ10, RZ11 | Profile Parameters | Find a profile parameter and display its value, attributes and documentation |
| STMS | Transport Management System | Display the transport domain, its systems and their import queues |

The SAP menu tree shows the whole area menu, so it also lists transactions
that are not rebuilt here. Starting one of those shows a message instead of a
screen, and a transaction that does not exist at all is reported as such.

### What changes the system

Almost nothing. `ZCL_SAPGUI_SYS_API`, which every screen uses to read the
system, has no method that changes anything. Two exceptions:

- **SE80** (`ZCL_SAPGUI_SE80_API`) can save source with `INSERT REPORT`, activate
  objects, create and delete classes, interfaces and programs, and record
  objects in transport requests - but only when the constant
  `c_write_enabled` in that class is switched to `abap_true`, which is a
  deliberate code change in the system. As delivered it refuses every
  write, and even when switched on every write still needs S_DEVELOP for
  the package and the object.
- **SE16N** stores its display variants in its own table `ZSE16N_A2U5_VAR`. It
  never changes the data of the table it displays.

## Authorizations

The apps ask for the authorizations the original transactions ask for, in
`ZCL_SAPGUI_AUTH`:

- **Every roundtrip of every app** starts with S_TCODE for the transaction
  behind the app and the basic object check the original makes right after
  it (S_DEVELOP display for the Workbench tools, S_ADMI_FCD for SM21,
  S_RZL_ADM for RZ10/RZ11/SM04, S_USER_GRP for SU01, S_TRANSPRT for
  SE09/SE10/STMS, S_APPL_LOG for SLG1, S_RFC_ADM for SM59, S_USER_AGR for
  PFCG, S_IDOCMONI for WE02/WE05). That also covers an app started directly
  by URL. Without it the screen shows "No Authorization" and the message,
  like the status bar of the SAP GUI.
- **Per object**, where the original checks the concrete object: the table
  in SE16N and SM30 (S_TABU_DIS for its authorization group, then
  S_TABU_NAM), the object and package in SE80 and the Workbench tools
  (S_DEVELOP), the user group in SU01 (S_USER_GRP), the log in SLG1, the
  destination in SM59, the role in PFCG, the IDoc in WE02 (S_IDOCMONI plus
  the BAdI `IDOC_AUTHORITY_RESTRICTION`), the spool request in SP01
  (`RSPO_CHECK_JOB_PERMISSION`) and another user's job log in SM37
  (S_BTCH_JOB / S_BTCH_ADM).

> [!NOTE]
> These are rebuilt checks, not the originals. Try the screens with a
> restricted user on a sandbox before you open the service to more people,
> and report what an original checks and this one does not.

## For contributors

Which class implements which transaction:

| Transaction | Class | Transaction | Class |
| --- | --- | --- | --- |
| SAP Easy Access | `ZCL_SAPGUI_START` | SM04 | `ZCL_SAPGUI_SM04` |
| SE80 | `ZCL_SAPGUI_SE80` | SM12 | `ZCL_SAPGUI_SM12` |
| SE38 | `ZCL_SAPGUI_SE38` | SM21 | `ZCL_SAPGUI_SM21` |
| SE11 | `ZCL_SAPGUI_SE11` | SM30 | `ZCL_SAPGUI_SM30` |
| SE24 | `ZCL_SAPGUI_SE24` | SM37 | `ZCL_SAPGUI_SM37` |
| SE37 | `ZCL_SAPGUI_SE37` | SM50, SM66 | `ZCL_SAPGUI_SM50` |
| SE91 | `ZCL_SAPGUI_SE91` | SM59 | `ZCL_SAPGUI_SM59` |
| SE93 | `ZCL_SAPGUI_SE93` | SLG1 | `ZCL_SAPGUI_SLG1` |
| SE09, SE10, SE01 | `ZCL_SAPGUI_SE09` | SP01 | `ZCL_SAPGUI_SP01` |
| SE16N, SE16 | `ZCL_SAPGUI_SE16N` | ST02 | `ZCL_SAPGUI_ST02` |
| RZ10, RZ11 | `ZCL_SAPGUI_RZ11` | ST05 | `ZCL_SAPGUI_ST05` |
| SU01 | `ZCL_SAPGUI_SU01` | ST22 | `ZCL_SAPGUI_ST22` |
| SU53 | `ZCL_SAPGUI_SU53` | STMS | `ZCL_SAPGUI_STMS` |
| PFCG | `ZCL_SAPGUI_PFCG` | WE02, WE05 | `ZCL_SAPGUI_WE02` |
| SCC4 | `ZCL_SAPGUI_SCC4` | SE03 | `ZCL_SAPGUI_SE03` |

What is planned next, and what is still missing, is in [CONCEPT.md](CONCEPT.md).

### Repository layout

```
src/
  zcl_sapgui_start.clas.abap         SAP Easy Access, the entry screen
  zcl_sapgui_<tcode>.clas.abap       one class per transaction (SE80, SM37, ...)
  zcl_sapgui_screen.clas.abap        their abstract base: main( ), the frame events
  zcl_sapgui_frame.clas.abap         the six bands of a SAP GUI window
  zcl_sapgui_router.clas.abap        the command field: which class a code starts
  zif_sapgui_start_params.intf.abap  start values for an app (like SPA/GPA)

  zcl_sapgui_sys_api.clas.abap       read only system API, the single entry point
  zif_sapgui_sys_api.intf.abap       what it reads from the system, as an interface
  zcl_sapgui_sys_api_db.clas.abap      ... on a system, through ZCL_SAPGUI_API_*
  zcl_sapgui_api_*.clas.abap         one class per area (dev, adm, mon, ops, repo, trn)
  zcl_sapgui_sys_api_dbl.clas.abap     ... in the unit tests (FOR TESTING)

  zif_sapgui_se80_api.intf.abap      the SE80 repository API, as an interface
  zcl_sapgui_se80_api.clas.abap        ... on a system, the only writing class
  zcl_sapgui_se80_api_dbl.clas.abap    ... in the unit tests (FOR TESTING)

  zcl_sapgui_auth.clas.abap          every authorization check
  zif_sapgui_auth_sys.intf.abap      its AUTHORITY-CHECK statements, as an interface
  zcl_sapgui_auth_sys.clas.abap        ... on a system
  zcl_sapgui_auth_sys_dbl.clas.abap    ... in the unit tests (FOR TESTING)

  zcl_sapgui_client_dbl.clas.abap    test double for z2ui5_if_client
  zsapgui.msag.xml                   the messages of the status bar
  zse16n_a2u5_var.tabl.xml           SE16N display variants (its name kept, it holds data)
```

The apps build views and dispatch events, they never read the system directly -
that is what `ZCL_SAPGUI_SYS_API` and `ZCL_SAPGUI_SE80_API` are for. The window frame
lives in `ZCL_SAPGUI_FRAME`, so all screens look the same. Every app inherits
from `ZCL_SAPGUI_SCREEN`, whose `main( )` calls `ZCL_SAPGUI_AUTH=>guard_app( )`
first and then the app's `on_init( )`, `render( )` or `on_event( )`; the API
classes check the concrete object before they read or write it. A new screen
is a subclass with those three methods and its views.

There are 629 ABAP Unit tests. They run against `ZCL_SAPGUI_CLIENT_DBL` instead
of a live client, so the view and the event wiring can be asserted without a
browser - and against two more doubles instead of the system:

- `ZCL_SAPGUI_SYS_API_DBL` stands in for everything the apps read
  (`ZIF_SAPGUI_SYS_API`). A test says what the system answers with
  `answer( )` - a result, an EXPORTING parameter, for one key or for every
  call.
- `ZCL_SAPGUI_AUTH_SYS_DBL` stands in for the AUTHORITY-CHECK statements
  (`ZIF_SAPGUI_AUTH_SYS`): every check passes until a test calls `deny( )`
  for it, so no test depends on the roles of the user who runs it.

Every test class installs both in `setup( )` and removes them in
`teardown( )`. They are global friends of `ZCL_SAPGUI_SYS_API` and
`ZCL_SAPGUI_AUTH` and `FOR TESTING`, so productive code cannot use them.
`ZCL_SAPGUI_SYS_API`, `ZCL_SAPGUI_AUTH` and `ZCL_SAPGUI_SE80` create their real
implementation by name, which keeps the apps free of any static dependency
on the classes that touch the database. The tests of those classes
(`ZCL_SAPGUI_SYS_API_DB`, `ZCL_SAPGUI_SE80_API`) read the real system and run on a
system only.

## Development

The checks run on Node, no ABAP system needed:

```bash
npm ci
npm test        # the three lint profiles, the transpiled unit tests, the views
```

| Command                 | What it does                                        |
| ----------------------- | --------------------------------------------------- |
| `npm run lint`          | style and correctness profile (`abaplint.jsonc`)     |
| `npm run lint_standard` | syntax check against SAP_BASIS 7.50                  |
| `npm run lint_abap2ui5` | the abap2UI5 linter (`abap2ui5lint.jsonc`)           |
| `npm run transpile`     | ABAP to JavaScript into `node/output`                |
| `npm run unit`          | run the transpiled unit tests, report every failure  |
| `npm run views`         | write the view of every screen, lint those files     |
| `npm run deps`          | abap2UI5 and open-abap-core at their pins (`node/deps`) |
| `npm run auto_fix`      | apply the quick fixes abaplint can apply on its own  |

abaplint resolves the dependencies by cloning abap2UI5 and the Steampunk API
intersect, so the first run needs network access. abap2UI5 is **pinned to a
release tag** (the `"branch"` key of the dependency, abap2UI5 CONVENTIONS §9):
users install a release next to this addon, so the checks run against that
release and not against the framework's `main`. Three configs carry the pin
(`abaplint.jsonc`, `.github/abaplint/abap_standard.jsonc` and
`.github/abaplint/auto_fix.jsonc`, and `node/setup/fetch-deps.mjs` follows
it); read and move them only with
`scripts/core-pin.mjs` (`get` fails when they disagree). The `bump-core`
workflow moves the pin weekly to the newest release after `npm run lint`,
`npm run lint_standard` and the transpiled unit tests passed on it. Do not drop the key: abaplint then
clones `main` silently.

CI, in `.github/workflows`:

| Workflow        | Trigger                       |
| --------------- | ----------------------------- |
| `abaplint`      | push to main, pull request    |
| `abap2ui5lint`  | push to main, pull request    |
| `unit`          | push to main, pull request    |
| `ABAP_STANDARD` | push to main, pull request    |
| `auto_fix`      | weekly, opens a pull request  |
| `bump-core`     | weekly, opens a pull request  |
| `bump-linter`   | weekly, opens a pull request  |

The [abap2UI5 linter](https://github.com/abap2UI5/linter) checks what abaplint
cannot know about abap2UI5: bindings, events, frontend actions, icons against
the UI5 1.71 floor, the lifecycle of `main( )`, obsolete framework calls. One
limit to know about: it rebuilds a view from the builder chain in the class it
reads, and every screen here hands its view to `ZCL_SAPGUI_FRAME`, which
opens the `mvc:View` and the window bands in another class. So on `src/` the
run summary says `judged 1 controls` - the ABAP side of every app is checked
there, the views are not. `npm run views` closes that gap: it starts every app
in the transpiled build (with the doubles), writes the view each one displays
to `node/views/<class>.view.xml`, and runs the linter on those files - 29
screens, about 4,400 controls, 290 bindings and 1,100 icons, against the UI5
1.71 floor. CI adds the render gate (`npm run views -- --render`): each view
is loaded with `XMLView.create` in headless Chromium.

The findings silenced in the source, each with its reason next to it:

- `non-released-api` on `z2ui5_cl_util=>json_parse( )` in SE16N: display
  variants are stored with `CALL TRANSFORMATION id` since 2026-10, and the
  JSON reader of abap2UI5 is only used to read - and convert, on first
  load - a variant saved by an older version.
- `unescaped-text-in-attribute` on the `value` and `submit` of the command
  field in `ZCL_SAPGUI_FRAME`: the app hands in a `_bind( )` and an
  `_event( )`, which the linter cannot see from inside the frame.
- `popup-without-close-wire` on the dialog of `popup_open( )`: its Close
  button is added by `popup_show( )`.

**The transpiled unit tests.** `npm run transpile` turns `src/` into
JavaScript with [@abaplint/transpiler](https://github.com/abaplint/transpiler),
against the downported abap2UI5 release of the pin and
[open-abap-core](https://github.com/open-abap/open-abap-core) for the kernel
classes (`node/setup/fetch-deps.mjs` pins both). The classes that read the
database - `ZCL_SAPGUI_SYS_API_DB`, `ZCL_SAPGUI_API_*`, `ZCL_SAPGUI_SE80_API`,
`ZCL_SAPGUI_AUTH_SYS` - are left out (`exclude_filter` in
`node/setup/abap_transpile.json`): their tables, function modules and BAdIs
do not exist in Node, and nothing depends on them statically. Two tests are
skipped there, each with its reason (DDIC structures open-abap-core does not
have). Three things behave differently in Node and are worked around in the
source, with a comment where it happens: iXML's `get_item( )` counts from 1
and `get_type( )` is not implemented in open-abap, and the transpiler
compares only the first component of a multi-component key in
`DELETE TABLE ... WITH TABLE KEY`.

A few rules are switched off on purpose, with the reason written next to them
in `abaplint.jsonc`. This repository is a rebuild of the ABAP Workbench, so
`INSERT REPORT` and dynamic SQL are the feature rather than an accident, and a
table browser that selects from a table name known only at runtime cannot have
a static column list or `ORDER BY`.

### Release floor

SAP_BASIS 7.50 is the floor, and the only one: `npm run lint_standard` checks
the sources against it on every pull request. There is no 7.02 version and
no downport pipeline - the screens use strict Open SQL with joins, ABAP 7.40
expressions throughout and Workbench APIs that 7.02 does not have, and a
downport would cost more than the systems it would reach are worth.

(The transpiled unit tests read abap2UI5 in its downported `<tag>-702` form
- that is the framework's own build for the transpiler, not a target of this
repository.)

## Contributing

Issues and pull requests are welcome. The rules for changing the code are in
[AGENTS.md](AGENTS.md), what is planned next in [CONCEPT.md](CONCEPT.md).

## License

MIT - see [LICENSE](LICENSE).
