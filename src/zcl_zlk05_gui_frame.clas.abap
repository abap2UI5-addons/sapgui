CLASS zcl_zlk05_gui_frame DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  The window frame of the classic SAP GUI, shared by all apps of
*  package $ZLK_05.
*
*  A SAP GUI window is built from six horizontal bands:
*
*    1  menu bar                 Table Display  Edit  Goto  System  Help
*    2  system function bar      command field + the standard icons
*    3  title bar                SAP logo + screen title
*    4  application function bar screen specific buttons
*    5  work area                the screen itself
*    6  status bar               message + system / server / INS
*
*  Bands 1, 2, 3 and 6 look the same on every screen and are built here.
*  Band 4 is filled by the app, band 5 is the app's own content.
*
*  The functions of the SAP GUI itself live here as well, so that every
*  transaction has them without a line of its own - all of them reach
*  this class through handle_frame_event( ):
*
*    command field   SE80  /nSE80  /n  /oSE80  /o  /nend  /nex  /*SE80
*    function keys   F3 Back, Shift+F3 Exit, F12 Cancel, F1 Help,
*                    Ctrl+F / Ctrl+G Find, F8 Execute, Ctrl+S Save
*    System menu     Create Session, User Profile, Own Spool Requests,
*                    Own Jobs, Services, Display Authorization Check,
*                    List > Find / Save to Local File, Status, Log Off
*    Help menu       Application Help, Keyboard Shortcuts
*
*  Find and Save to Local File work on the lists of the running app: its
*  public internal tables, read with RTTI - exactly the data its screen
*  shows. The frame never reads or changes system data itself; the
*  status data come from ZCL_ZLK05_SYS_API.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    " Colours of the classic SAP GUI toolbar icons
    CONSTANTS c_green  TYPE string VALUE `#107e3e`.
    CONSTANTS c_yellow TYPE string VALUE `#e9730c`.
    CONSTANTS c_red    TYPE string VALUE `#bb0000`.
    CONSTANTS c_blue   TYPE string VALUE `#0a6ed1`.
    CONSTANTS c_grey   TYPE string VALUE `#6a6d70`.
    CONSTANTS c_gold   TYPE string VALUE `#e9a800`.

    "! Height of the work area - the six bands add up to roughly 12rem
    CONSTANTS c_work_height TYPE string VALUE `calc(100vh - 13rem)`.

    "! Event names the frame reserves for itself. Every screen routes them
    "! through handle_frame_event( ), so the command field, Back, the menus
    "! and the function keys work the same way on every screen.
    CONSTANTS c_ev_command     TYPE string VALUE `GUI_COMMAND`.
    CONSTANTS c_ev_back        TYPE string VALUE `GUI_BACK`.
    "! Exit (Shift+F3) - leaves the transaction from any of its screens
    CONSTANTS c_ev_exit        TYPE string VALUE `GUI_EXIT`.
    "! An entry of the System or Help menu - the argument names it
    CONSTANTS c_ev_menu        TYPE string VALUE `GUI_MENU`.
    CONSTANTS c_ev_help        TYPE string VALUE `GUI_HELP`.
    CONSTANTS c_ev_find        TYPE string VALUE `GUI_FIND`.
    CONSTANTS c_ev_find_exec   TYPE string VALUE `GUI_FIND_EXEC`.
    CONSTANTS c_ev_list_save   TYPE string VALUE `GUI_LIST_SAVE`.
    CONSTANTS c_ev_logoff      TYPE string VALUE `GUI_LOGOFF`.
    CONSTANTS c_ev_popup_close TYPE string VALUE `GUI_POPUP_CLOSE`.

    "! Entries of the System and Help menu (argument of c_ev_menu)
    CONSTANTS:
      BEGIN OF c_menu,
        own_data   TYPE string VALUE `OWN_DATA`,
        own_spool  TYPE string VALUE `OWN_SPOOL`,
        own_jobs   TYPE string VALUE `OWN_JOBS`,
        auth_check TYPE string VALUE `SU53`,
        status     TYPE string VALUE `STATUS`,
        find       TYPE string VALUE `FIND`,
        list_save  TYPE string VALUE `LIST_SAVE`,
        logoff     TYPE string VALUE `LOGOFF`,
        session    TYPE string VALUE `SESSION`,
        help       TYPE string VALUE `HELP`,
        keys       TYPE string VALUE `KEYS`,
        "! prefix of System > Services entries: TX:SM37 starts SM37
        service    TYPE string VALUE `TX:`,
      END OF c_menu.

    "! URL parameter that makes a new session start with a transaction
    CONSTANTS c_url_tcode TYPE string VALUE `zlk05_tcode`.
    "! The entry screen of a session (SAP Easy Access)
    CONSTANTS c_entry_class TYPE string VALUE `ZCL_SAPGUI_A2UI5`.

    "! Return values of handle_frame_event( )
    CONSTANTS c_not_handled TYPE string VALUE ``.
    "! The frame has done everything for this roundtrip - another app was
    "! started, a popup opened, a file sent. The caller must return at once.
    CONSTANTS c_navigated   TYPE string VALUE `NAV`.
    CONSTANTS c_message     TYPE string VALUE `MSG`.

    TYPES:
      "! Result of handle_frame_event( ): the outcome and the status bar text
      BEGIN OF ty_s_frame_result,
        outcome  TYPE string,
        message  TYPE string,
        msg_type TYPE string,
      END OF ty_s_frame_result.

    " One entry of a toolbar. Entries with TEXT are rendered as a button,
    " entries with SEP as a separator, everything else as a coloured icon.
    " DISABLED greys an entry out that HAS a handler - the SAP GUI greys a
    " function out while it does not apply (no object loaded, display mode)
    " instead of hiding it. An entry without a handler is greyed out anyway,
    " so DISABLED only matters together with PRESS.
    TYPES:
      BEGIN OF ty_s_button,
        icon     TYPE string,
        text     TYPE string,
        color    TYPE string,
        tooltip  TYPE string,
        press    TYPE string,
        sep      TYPE abap_bool,
        disabled TYPE abap_bool,
      END OF ty_s_button.
    TYPES ty_t_button TYPE STANDARD TABLE OF ty_s_button WITH EMPTY KEY.

    "! A list of the running app: one of its public internal tables
    TYPES:
      BEGIN OF ty_s_list,
        name  TYPE string,
        lines TYPE i,
        data  TYPE REF TO data,
      END OF ty_s_list.
    TYPES ty_t_list TYPE STANDARD TABLE OF ty_s_list WITH EMPTY KEY.

    "! One hit of System > List > Find
    TYPES:
      BEGIN OF ty_s_hit,
        list   TYPE string,
        row    TYPE i,
        column TYPE string,
        value  TYPE string,
      END OF ty_s_hit.
    TYPES ty_t_hit TYPE STANDARD TABLE OF ty_s_hit WITH EMPTY KEY.

    "! Opens View / Shell / Page and returns the page, ready for the bands.
    CLASS-METHODS open_window
      IMPORTING io_view       TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Band 1 - menu bar. With io_client the entries System and Help are
    "! the real menus of the SAP GUI; the menus of the application are
    "! shown for orientation.
    CLASS-METHODS build_menu_bar
      IMPORTING io_parent  TYPE REF TO z2ui5_cl_ui5_view_builder
                it_entries TYPE string_table
                io_client  TYPE REF TO z2ui5_if_client OPTIONAL.

    "! Band 2 - system function bar with the command field.
    "! iv_cmd_value / iv_cmd_event wire up the command field,
    "! iv_back_event makes the yellow Back arrow (F3) active. With
    "! io_client Exit, Find, Create Session and Help are active as well.
    CLASS-METHODS build_system_bar
      IMPORTING io_parent     TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_cmd_value  TYPE string OPTIONAL
                iv_cmd_event  TYPE string OPTIONAL
                iv_back_event TYPE string OPTIONAL
                io_client     TYPE REF TO z2ui5_if_client OPTIONAL.

    "! Band 3 - title bar with the SAP logo and the screen title. With
    "! io_client the browser tab carries the title as well.
    CLASS-METHODS build_title_bar
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_title  TYPE string
                iv_hint   TYPE string OPTIONAL
                io_client TYPE REF TO z2ui5_if_client OPTIONAL.

    "! Band 4 - application function bar.
    CLASS-METHODS build_app_bar
      IMPORTING io_parent  TYPE REF TO z2ui5_cl_ui5_view_builder
                it_buttons TYPE ty_t_button.

    "! Band 6 - status bar. Message on the left, system data on the right.
    "! The system data are passed in by the app so that this class stays free
    "! of system access. When they are omitted the SY fields are used.
    CLASS-METHODS build_status_bar
      IMPORTING io_parent   TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_message  TYPE string OPTIONAL
                iv_msg_type TYPE string OPTIONAL
                iv_sysid    TYPE string OPTIONAL
                iv_client   TYPE string OPTIONAL
                iv_user     TYPE string OPTIONAL
                iv_host     TYPE string OPTIONAL.

    "! Registers the function keys of the SAP GUI on the running app.
    "! F3 and F12 fire iv_back_name, Shift+F3 leaves the transaction
    "! (c_ev_exit), F8 the execute event of the screen and Ctrl+S its save
    "! event, F1 opens the help, Ctrl+F / Ctrl+G the find dialog.
    "! Call it from every view method - the registrations belong to the
    "! running app and are dropped as soon as another app takes over.
    "! iv_back_name is the event the screen wants for Back: the default
    "! c_ev_back leaves the transaction, a screen inside a transaction
    "! passes its own event so that F3 goes back one screen. An empty name
    "! registers no Back / Exit key at all (entry screen of the session).
    CLASS-METHODS register_keys
      IMPORTING io_client    TYPE REF TO z2ui5_if_client
                iv_back_name TYPE string DEFAULT c_ev_back
                iv_exec_name TYPE string OPTIONAL
                iv_save_name TYPE string OPTIONAL.

    "! Handles the events of the frame: command field, Back / Exit, the
    "! System and Help menu, Find, Save to Local File and Log Off. The
    "! outcome is c_navigated (the caller must return at once), c_message
    "! (the message fields carry the text for the status bar) or
    "! c_not_handled (an event of the screen itself).
    "! iv_root: the screen is the root of the session (SAP Easy Access) -
    "! transactions are started on top of it instead of replacing it.
    CLASS-METHODS handle_frame_event
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_event      TYPE string
                iv_command    TYPE string OPTIONAL
                iv_root       TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    "! A single coloured icon or button inside a toolbar.
    CLASS-METHODS add_button
      IMPORTING io_bar    TYPE REF TO z2ui5_cl_ui5_view_builder
                is_button TYPE ty_s_button.

    "! Label / field row of a classic dynpro selection screen
    CLASS-METHODS add_label
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_text   TYPE string
                iv_width  TYPE string DEFAULT `11rem`.

    "! The lists of an app: its public, non-empty internal tables with a
    "! flat line type (or elementary lines)
    CLASS-METHODS get_lists
      IMPORTING io_app        TYPE REF TO object
      RETURNING VALUE(result) TYPE ty_t_list.

    "! System > List > Find over the lists of an app - case-insensitive,
    "! at most iv_max hits
    CLASS-METHODS find_in_lists
      IMPORTING io_app        TYPE REF TO object
                iv_term       TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_hit.

    "! A list as CSV text for a spreadsheet: header line with the column
    "! names, ; as separator, values quoted where needed. A value that a
    "! spreadsheet would run as a formula (= + - @) is prefixed with '.
    CLASS-METHODS list_to_csv
      IMPORTING ir_table      TYPE REF TO data
      RETURNING VALUE(result) TYPE string.

    "! Address of a new session: the entry screen of this ICF node, and
    "! with iv_tcode the transaction it starts with (c_url_tcode)
    CLASS-METHODS session_url
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_tcode      TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    "! The transaction code given to a new session in its URL, or empty
    CLASS-METHODS start_tcode_of_url
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.

    CLASS-METHODS build_system_menu
      IMPORTING io_bar    TYPE REF TO z2ui5_cl_ui5_view_builder
                io_client TYPE REF TO z2ui5_if_client.

    CLASS-METHODS build_help_menu
      IMPORTING io_bar    TYPE REF TO z2ui5_cl_ui5_view_builder
                io_client TYPE REF TO z2ui5_if_client.

    CLASS-METHODS menu_item
      IMPORTING io_menu   TYPE REF TO z2ui5_cl_ui5_view_builder
                io_client TYPE REF TO z2ui5_if_client
                iv_text   TYPE string
                iv_code   TYPE string
                iv_icon   TYPE string OPTIONAL.

    CLASS-METHODS handle_command
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_command    TYPE string
                iv_root       TYPE abap_bool
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    CLASS-METHODS handle_menu
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_code       TYPE string
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    "! Starts a transaction from a menu - called on top of the running
    "! one, so Back returns there
    CLASS-METHODS start_tcode
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_tcode      TYPE string
                it_params     TYPE zif_zlk05_start_params=>ty_t_param OPTIONAL
                iv_replace    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    CLASS-METHODS open_session
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    CLASS-METHODS confirm_logoff
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    "! Transaction code and class of the running app
    CLASS-METHODS running_app
      IMPORTING io_client TYPE REF TO z2ui5_if_client
      EXPORTING eo_app    TYPE REF TO object
                ev_class  TYPE string
                ev_tcode  TYPE string.

    CLASS-METHODS popup_open
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_title      TYPE string
                iv_width      TYPE string DEFAULT `40rem`
      EXPORTING eo_popup      TYPE REF TO z2ui5_cl_ui5_view_builder
      RETURNING VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS popup_show
      IMPORTING io_client TYPE REF TO z2ui5_if_client
                io_popup  TYPE REF TO z2ui5_cl_ui5_view_builder
                io_dialog TYPE REF TO z2ui5_cl_ui5_view_builder.

    CLASS-METHODS show_status
      IMPORTING io_client TYPE REF TO z2ui5_if_client.

    CLASS-METHODS show_help
      IMPORTING io_client TYPE REF TO z2ui5_if_client
                iv_keys   TYPE abap_bool DEFAULT abap_false.

    CLASS-METHODS show_find
      IMPORTING io_client TYPE REF TO z2ui5_if_client
                iv_term   TYPE string OPTIONAL
                iv_search TYPE abap_bool DEFAULT abap_false.

    CLASS-METHODS save_list
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_list       TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ty_s_frame_result.

    CLASS-METHODS csv_value
      IMPORTING iv_value      TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS row_values
      IMPORTING is_row        TYPE any
      EXPORTING et_names      TYPE string_table
                et_values     TYPE string_table.

ENDCLASS.


CLASS zcl_zlk05_gui_frame IMPLEMENTATION.

  METHOD open_window.

    result = io_view->ele( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:table`  v = `sap.ui.table`
        )->a( n = `xmlns:editor` v = `sap.ui.codeeditor`
        )->a( n = `height`     v = `100%`
        )->ele( `Shell`
        )->a( n = `appWidthLimited` v = `false`
        )->ele( `Page`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false` ).

  ENDMETHOD.


  METHOD build_menu_bar.

    DATA(bar) = io_parent->ele( `Toolbar`
        )->a( n = `design` v = `Solid`
        )->a( n = `height` v = `1.85rem` ).

    LOOP AT it_entries INTO DATA(lv_entry).
      IF io_client IS BOUND AND lv_entry = `System`.
        build_system_menu( io_bar = bar io_client = io_client ).
      ELSEIF io_client IS BOUND AND lv_entry = `Help`.
        build_help_menu( io_bar = bar io_client = io_client ).
      ELSE.
        bar->tag( `Text`
            )->a( n = `text`    v = lv_entry
            )->a( n = `class`   v = `sapUiSmallMarginEnd`
            )->a( n = `tooltip` v = |{ lv_entry } - the menu of the application is shown for orientation| ).
      ENDIF.
    ENDLOOP.

    " System and Help belong to every SAP GUI window, whatever the app lists
    IF io_client IS BOUND AND NOT line_exists( it_entries[ table_line = `System` ] ).
      build_system_menu( io_bar = bar io_client = io_client ).
    ENDIF.
    IF io_client IS BOUND AND NOT line_exists( it_entries[ table_line = `Help` ] ).
      build_help_menu( io_bar = bar io_client = io_client ).
    ENDIF.

  ENDMETHOD.


  METHOD menu_item.

    io_menu->tag( `MenuItem`
        )->a( n = `text`  v = iv_text
        )->a( n = `icon`  v = iv_icon
        )->a( n = `press` v = io_client->_event( val = c_ev_menu arg = iv_code ) ).

  ENDMETHOD.


  METHOD build_system_menu.

    " the System menu of the SAP GUI - the entries that make sense in a
    " browser, with the transactions behind them
    DATA(menu) = io_bar->ele( `MenuButton`
        )->a( n = `text` v = `System`
        )->a( n = `type` v = `Transparent`
        )->ele( `menu`
        )->ele( `Menu` ).

    " Create Session opens a new browser tab - a pure frontend action, so
    " the browser accepts it as a reaction to the click
    menu->tag( `MenuItem`
        )->a( n = `text`  v = `Create Session`
        )->a( n = `icon`  v = `sap-icon://sys-monitor`
        )->a( n = `press` v = io_client->follow_up_action(
                                  val   = io_client->cs_event-open_new_tab
                                  t_arg = VALUE #( ( session_url( io_client ) ) ) ) ).
    menu->tag( `MenuItem`
        )->a( n = `text`    v = `End Session`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Close the browser tab to end the session` ).

    DATA(profile) = menu->ele( `MenuItem` )->a( n = `text` v = `User Profile` )->ele( `items` ).
    menu_item( io_menu = profile io_client = io_client iv_text = `Own Data`
               iv_code = c_menu-own_data iv_icon = `sap-icon://person-placeholder` ).

    DATA(services) = menu->ele( `MenuItem` )->a( n = `text` v = `Services` )->ele( `items` ).
    menu_item( io_menu = services io_client = io_client iv_text = `Reporting (SE38)`
               iv_code = |{ c_menu-service }SE38| ).
    menu_item( io_menu = services io_client = io_client iv_text = `Table Maintenance (SM30)`
               iv_code = |{ c_menu-service }SM30| ).
    menu_item( io_menu = services io_client = io_client iv_text = `Data Browser (SE16)`
               iv_code = |{ c_menu-service }SE16| ).
    menu_item( io_menu = services io_client = io_client iv_text = `Output Control (SP01)`
               iv_code = |{ c_menu-service }SP01| ).
    menu_item( io_menu = services io_client = io_client iv_text = `Jobs (SM37)`
               iv_code = |{ c_menu-service }SM37| ).
    menu_item( io_menu = services io_client = io_client iv_text = `Application Log (SLG1)`
               iv_code = |{ c_menu-service }SLG1| ).

    DATA(utilities) = menu->ele( `MenuItem` )->a( n = `text` v = `Utilities` )->ele( `items` ).
    menu_item( io_menu = utilities io_client = io_client iv_text = `Display Authorization Check`
               iv_code = c_menu-auth_check ).

    DATA(list) = menu->ele( `MenuItem` )->a( n = `text` v = `List` )->ele( `items` ).
    menu_item( io_menu = list io_client = io_client iv_text = `Find...`
               iv_code = c_menu-find iv_icon = `sap-icon://sys-find` ).
    menu_item( io_menu = list io_client = io_client iv_text = `Save to Local File...`
               iv_code = c_menu-list_save iv_icon = `sap-icon://download` ).

    menu_item( io_menu = menu io_client = io_client iv_text = `Own Spool Requests`
               iv_code = c_menu-own_spool iv_icon = `sap-icon://print` ).
    menu_item( io_menu = menu io_client = io_client iv_text = `Own Jobs`
               iv_code = c_menu-own_jobs iv_icon = `sap-icon://history` ).
    menu_item( io_menu = menu io_client = io_client iv_text = `Status...`
               iv_code = c_menu-status iv_icon = `sap-icon://hint` ).
    menu_item( io_menu = menu io_client = io_client iv_text = `Log Off`
               iv_code = c_menu-logoff iv_icon = `sap-icon://log` ).

  ENDMETHOD.


  METHOD build_help_menu.

    DATA(menu) = io_bar->ele( `MenuButton`
        )->a( n = `text` v = `Help`
        )->a( n = `type` v = `Transparent`
        )->ele( `menu`
        )->ele( `Menu` ).

    menu_item( io_menu = menu io_client = io_client iv_text = `Application Help`
               iv_code = c_menu-help iv_icon = `sap-icon://sys-help` ).
    menu_item( io_menu = menu io_client = io_client iv_text = `Keyboard Shortcuts`
               iv_code = c_menu-keys iv_icon = `sap-icon://keyboard-and-mouse` ).

  ENDMETHOD.


  METHOD build_system_bar.

    DATA(bar) = io_parent->ele( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.35rem` ).

    " green tick - Enter
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-enter-2`
                                     color   = c_green
                                     tooltip = `Continue (Enter)`
                                     press   = iv_cmd_event ) ).

    " command field - active on every screen, exactly like in the SAP GUI.
    " Its drop-down proposes the transactions of this environment, the way
    " the SAP GUI proposes the history of the command field.
    IF iv_cmd_event IS NOT INITIAL.
      DATA(cmd) = bar->ele( `Input`
          )->a( n = `id`             v = `idCommandField`
          )->a( n = `value`          v = iv_cmd_value
          )->a( n = `width`          v = `13rem`
          )->a( n = `showSuggestion` v = `true`
          )->a( n = `tooltip`        v = `Command field - SE80, /nSE80 ends the transaction, /oSE80 opens a new session, /nend logs off`
          )->a( n = `submit`         v = iv_cmd_event ).
      DATA(sugg) = cmd->ele( `suggestionItems` ).
      LOOP AT zcl_zlk05_tcode_router=>get_apps( ) INTO DATA(ls_app) WHERE class IS NOT INITIAL.
        sugg->tag( n = `ListItem` ns = `core`
            )->a( n = `text`           v = ls_app-tcode
            )->a( n = `additionalText` t = ls_app-text ).
      ENDLOOP.
    ELSE.
      bar->tag( `Input`
          )->a( n = `width`   v = `13rem`
          )->a( n = `enabled` v = `false`
          )->a( n = `tooltip` v = `Command field` ).
    ENDIF.

    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://open-command-field`
                                     color   = c_grey
                                     tooltip = `Command field` ) ).

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://save`
                                     color   = c_grey
                                     tooltip = `Save (Ctrl+S) - not available in this environment` ) ).

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    " Back / Exit / Cancel - active when the app passes a back event.
    " Exit leaves the transaction from every one of its screens.
    IF iv_back_event IS NOT INITIAL.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-back`
                                       color   = c_yellow
                                       tooltip = `Back (F3)`
                                       press   = iv_back_event ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://arrow-top`
                                       color   = c_yellow
                                       tooltip = `Exit (Shift+F3)`
                                       press   = COND #( WHEN io_client IS BOUND
                                                         THEN io_client->_event( c_ev_exit )
                                                         ELSE iv_back_event ) ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://decline`
                                       color   = c_red
                                       tooltip = `Cancel (F12)`
                                       press   = iv_back_event ) ).
    ELSE.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-back`
                                       color   = c_yellow
                                       tooltip = `Back (F3) - not available on the initial screen` ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://arrow-top`
                                       color   = c_yellow
                                       tooltip = `Exit (Shift+F3) - not available on the initial screen` ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://decline`
                                       color   = c_red
                                       tooltip = `Cancel (F12) - not available on the initial screen` ) ).
    ENDIF.

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://print`
                                     color   = c_grey
                                     tooltip = `Print - use the print function of the browser (Ctrl+P), or System > List > Save to Local File` ) ).

    IF io_client IS BOUND.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-find`
                                       color   = c_blue
                                       tooltip = `Find (Ctrl+F)`
                                       press   = io_client->_event( c_ev_find ) ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-find-next`
                                       color   = c_blue
                                       tooltip = `Find next (Ctrl+G)`
                                       press   = io_client->_event( c_ev_find ) ) ).
    ELSE.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-find`
                                       color   = c_grey
                                       tooltip = `Find (Ctrl+F) - not available on this screen` ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-find-next`
                                       color   = c_grey
                                       tooltip = `Find next (Ctrl+G) - not available on this screen` ) ).
    ENDIF.

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    " paging: the lists scroll, the column menus sort and filter them
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-first-page`
                                     color   = c_grey
                                     tooltip = `First page - scroll the list, its column menu sorts and filters` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-prev-page`
                                     color   = c_grey
                                     tooltip = `Previous page - scroll the list` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-next-page`
                                     color   = c_grey
                                     tooltip = `Next page - scroll the list` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-last-page`
                                     color   = c_grey
                                     tooltip = `Last page - scroll the list` ) ).

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    IF io_client IS BOUND.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-monitor`
                                       color   = c_gold
                                       tooltip = `Create new session (opens a new browser tab)`
                                       press   = io_client->follow_up_action(
                                                     val   = io_client->cs_event-open_new_tab
                                                     t_arg = VALUE #( ( session_url( io_client ) ) ) ) ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-help`
                                       color   = c_blue
                                       tooltip = `Help (F1)`
                                       press   = io_client->_event( c_ev_help ) ) ).
    ELSE.
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-monitor`
                                       color   = c_gold
                                       tooltip = `Create new session - not available on this screen` ) ).
      add_button( io_bar    = bar
                  is_button = VALUE #( icon    = `sap-icon://sys-help`
                                       color   = c_blue
                                       tooltip = `Help (F1) - not available on this screen` ) ).
    ENDIF.

  ENDMETHOD.


  METHOD build_title_bar.

    DATA(bar) = io_parent->ele( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.5rem` ).

    bar->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://SAP-logo-shape`
        )->a( n = `size`    v = `1.35rem`
        )->a( n = `color`   v = c_blue
        )->a( n = `tooltip` v = `SAP` ).

    bar->tag( `Title`
        )->a( n = `text`  v = iv_title
        )->a( n = `level` v = `H2`
        )->a( n = `class` v = `sapUiSmallMarginBegin` ).

    IF iv_hint IS NOT INITIAL.
      bar->tag( `ToolbarSpacer` ).
      bar->tag( `Text` )->a( n = `text` v = iv_hint ).
    ENDIF.

    " the browser tab carries the screen title, like the SAP GUI window
    IF io_client IS BOUND.
      io_client->follow_up_action( val   = io_client->cs_event-set_title
                                   t_arg = VALUE #( ( iv_title ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD build_app_bar.

    DATA(bar) = io_parent->ele( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.1rem` ).

    LOOP AT it_buttons INTO DATA(ls_button).
      add_button( io_bar = bar is_button = ls_button ).
    ENDLOOP.

  ENDMETHOD.


  METHOD build_status_bar.

    DATA(bar) = io_parent->ele( `footer`
        )->ele( `OverflowToolbar`
        )->a( n = `height` v = `1.95rem` ).

    IF iv_message IS NOT INITIAL.
      bar->tag( n = `Icon` ns = `core`
          )->a( n = `src`   v = COND string(
                  WHEN iv_msg_type = `Error`   THEN `sap-icon://error`
                  WHEN iv_msg_type = `Warning` THEN `sap-icon://alert`
                  ELSE                              `sap-icon://message-information` )
          )->a( n = `size`  v = `0.875rem`
          )->a( n = `color` v = COND string(
                  WHEN iv_msg_type = `Error`   THEN c_red
                  WHEN iv_msg_type = `Warning` THEN c_yellow
                  ELSE                              c_blue ) ).

      bar->tag( `Text`
          )->a( n = `text`  v = iv_message
          )->a( n = `class` v = `sapUiTinyMarginBegin` ).
    ENDIF.

    bar->tag( `ToolbarSpacer` ).

    DATA(lv_sysid)  = COND string( WHEN iv_sysid  IS NOT INITIAL THEN iv_sysid
                                   ELSE CONV string( sy-sysid ) ).
    DATA(lv_client) = COND string( WHEN iv_client IS NOT INITIAL THEN iv_client
                                   ELSE CONV string( sy-mandt ) ).
    DATA(lv_user)   = COND string( WHEN iv_user   IS NOT INITIAL THEN iv_user
                                   ELSE CONV string( sy-uname ) ).
    DATA(lv_host)   = COND string( WHEN iv_host   IS NOT INITIAL THEN iv_host
                                   ELSE CONV string( sy-host ) ).

    bar->tag( n = `Icon` ns = `core`
        )->a( n = `src`   v = `sap-icon://open-command-field`
        )->a( n = `size`  v = `0.75rem`
        )->a( n = `color` v = c_grey ).

    bar->tag( `ToolbarSeparator` ).

    " the tooltip carries system, client and user, like the expanded
    " status field of the SAP GUI
    bar->tag( `Text`
        )->a( n = `text`    v = lv_sysid
        )->a( n = `tooltip` v = |System { lv_sysid } - Client { lv_client } - User { lv_user }| ).

    bar->tag( `ToolbarSeparator` ).

    bar->tag( `Text`
        )->a( n = `text`    v = lv_host
        )->a( n = `tooltip` v = |Application server { lv_host }| ).

    bar->tag( `ToolbarSeparator` ).

    bar->tag( `Text`
        )->a( n = `text`    v = `INS`
        )->a( n = `tooltip` v = `Insert mode` ).

  ENDMETHOD.


  METHOD register_keys.

    " ===== Function keys =====
    " The framework binds a key combination to a backend event, so the
    " keys reach the app the same way a button press does.
    IF io_client IS INITIAL.
      RETURN.
    ENDIF.

    " The registry lives in the frontend and survives a transaction switch,
    " so every screen has to state its own binding for EVERY key it knows -
    " an empty event name unregisters the combination. Skipping the call
    " instead would leave the key of the screen before armed: F3 on the
    " entry screen would still fire the Back event of the transaction that
    " was left last.
    " Exit (Shift+F3) leaves the transaction from every screen of it; on
    " the first screen that is the same as Back.
    DATA(lv_exit) = COND string( WHEN iv_back_name IS INITIAL     THEN ``
                                 WHEN iv_back_name = c_ev_back    THEN c_ev_back
                                 ELSE c_ev_exit ).

    LOOP AT VALUE string_table(
        ( |F3;{ iv_back_name }| )
        ( |Shift+F3;{ lv_exit }| )
        ( |F12;{ iv_back_name }| )
        ( |F8;{ iv_exec_name }| )
        ( |Ctrl+S;{ iv_save_name }| )
        ( |F1;{ c_ev_help }| )
        ( |Ctrl+F;{ c_ev_find }| )
        ( |Ctrl+G;{ c_ev_find }| ) ) INTO DATA(lv_key).
      SPLIT lv_key AT `;` INTO DATA(lv_combo) DATA(lv_event).
      io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                   t_arg = VALUE #( ( lv_combo ) ( lv_event ) ) ).
    ENDLOOP.

  ENDMETHOD.


  METHOD handle_frame_event.

    " ===== Frame events =====
    result-outcome = c_not_handled.
    IF io_client IS INITIAL.
      RETURN.
    ENDIF.

    CASE iv_event.

      WHEN c_ev_back OR c_ev_exit.
        " F3 / Shift+F3 / F12 and the arrows of the system function bar.
        " The root of the session has nowhere to go back to.
        IF iv_root = abap_true.
          RETURN.
        ENDIF.
        io_client->nav_app_leave( ).
        result-outcome = c_navigated.

      WHEN c_ev_command.
        result = handle_command( io_client  = io_client
                                 iv_command = iv_command
                                 iv_root    = iv_root ).

      WHEN c_ev_menu.
        result = handle_menu( io_client = io_client
                              iv_code   = io_client->get_event_arg( ) ).

      WHEN c_ev_help.
        show_help( io_client ).
        result-outcome = c_navigated.

      WHEN c_ev_find.
        show_find( io_client ).
        result-outcome = c_navigated.

      WHEN c_ev_find_exec.
        show_find( io_client = io_client
                   iv_term   = io_client->get_event_arg( )
                   iv_search = abap_true ).
        result-outcome = c_navigated.

      WHEN c_ev_list_save.
        result = save_list( io_client = io_client
                            iv_list   = io_client->get_event_arg( ) ).

      WHEN c_ev_logoff.
        " the answer of the Log Off box arrives as the event argument
        IF to_upper( io_client->get_event_arg( ) ) = `YES`.
          io_client->follow_up_action( val = io_client->cs_event-system_logout ).
        ENDIF.
        result-outcome = c_navigated.

      WHEN c_ev_popup_close.
        io_client->popup_destroy( ).
        result-outcome = c_navigated.

      WHEN OTHERS.
        result-outcome = c_not_handled.

    ENDCASE.

  ENDMETHOD.


  METHOD handle_command.

    DATA(ls_cmd) = zcl_zlk05_tcode_router=>parse_command( iv_command ).

    CASE ls_cmd-kind.

      WHEN zcl_zlk05_tcode_router=>c_cmd_none.
        MESSAGE w022(zlk05) INTO result-message.
        result-msg_type = `Warning`.
        result-outcome  = c_message.

      WHEN zcl_zlk05_tcode_router=>c_cmd_tcode OR zcl_zlk05_tcode_router=>c_cmd_new.
        " inside a transaction the new one REPLACES it, like /n in the SAP
        " GUI - Back from it does not return to the transaction left. From
        " the root of the session it is started on top of the root.
        result = start_tcode( io_client  = io_client
                              iv_tcode   = ls_cmd-tcode
                              iv_replace = xsdbool( iv_root = abap_false ) ).

      WHEN zcl_zlk05_tcode_router=>c_cmd_end.
        IF iv_root = abap_true.
          result-message  = `You are already on the initial screen of the session.`.
          result-msg_type = `Information`.
          result-outcome  = c_message.
        ELSE.
          io_client->nav_app_leave( ).
          result-outcome = c_navigated.
        ENDIF.

      WHEN zcl_zlk05_tcode_router=>c_cmd_session.
        result = open_session( io_client = io_client
                               iv_tcode  = ls_cmd-tcode ).

      WHEN zcl_zlk05_tcode_router=>c_cmd_logoff.
        confirm_logoff( io_client ).
        result-outcome = c_navigated.

      WHEN zcl_zlk05_tcode_router=>c_cmd_logoff_now.
        io_client->follow_up_action( val = io_client->cs_event-system_logout ).
        result-outcome = c_navigated.

      WHEN OTHERS.
        " /i, /h, /$tab ... - the router has the answer
        DATA(ls_run) = zcl_zlk05_tcode_router=>run( iv_command = iv_command
                                                    io_client  = io_client ).
        result-message  = ls_run-message.
        result-msg_type = ls_run-msg_type.
        result-outcome  = c_message.

    ENDCASE.

  ENDMETHOD.


  METHOD start_tcode.

    DATA(ls_run) = zcl_zlk05_tcode_router=>run( iv_command  = iv_tcode
                                                io_client   = io_client
                                                it_params   = it_params
                                                iv_replace  = iv_replace ).
    result-message  = ls_run-message.
    result-msg_type = ls_run-msg_type.
    result-outcome  = SWITCH #( ls_run-outcome
                                WHEN zcl_zlk05_tcode_router=>c_nav THEN c_navigated
                                WHEN zcl_zlk05_tcode_router=>c_msg THEN c_message
                                ELSE c_not_handled ).

  ENDMETHOD.


  METHOD open_session.

    " /oSE80: the transaction is checked here already, so the user gets
    " the message in this window instead of an empty new one
    DATA(lv_tcode) = to_upper( condense( iv_tcode ) ).
    IF lv_tcode IS NOT INITIAL.
      DATA(ls_check) = zcl_zlk05_tcode_router=>check_start( lv_tcode ).
      IF ls_check-outcome = zcl_zlk05_tcode_router=>c_msg.
        result-message  = ls_check-message.
        result-msg_type = ls_check-msg_type.
        result-outcome  = c_message.
        RETURN.
      ENDIF.
    ENDIF.

    io_client->follow_up_action( val   = io_client->cs_event-open_new_tab
                                 t_arg = VALUE #( ( session_url( io_client = io_client
                                                                 iv_tcode  = lv_tcode ) ) ) ).
    result-message  = COND #( WHEN lv_tcode IS INITIAL THEN `New session opened in a new browser tab.`
                              ELSE |New session with { lv_tcode } opened in a new browser tab.| ).
    result-msg_type = `Success`.
    result-outcome  = c_message.

  ENDMETHOD.


  METHOD session_url.

    " same ICF node and the same URL parameters as this session (client,
    " language ...), only the app to start is exchanged - a relative URL,
    " the only kind the frontend opens in a new tab
    DATA(ls_config) = io_client->get( )-s_config.
    DATA(lv_search) = ls_config-search.
    IF lv_search CP `?*`.
      lv_search = substring( val = lv_search off = 1 ).
    ENDIF.

    SPLIT lv_search AT `&` INTO TABLE DATA(lt_param).
    DELETE lt_param WHERE table_line IS INITIAL
                       OR table_line CP `app_start=*`
                       OR table_line CP |{ c_url_tcode }=*|.
    APPEND |app_start={ to_lower( c_entry_class ) }| TO lt_param.

    " only a valid transaction code goes into the address
    DATA(lv_tcode) = to_upper( condense( iv_tcode ) ).
    IF lv_tcode IS NOT INITIAL AND lv_tcode CO `ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_/`
       AND strlen( lv_tcode ) <= 20.
      APPEND |{ c_url_tcode }={ lv_tcode }| TO lt_param.
    ENDIF.

    result = |{ ls_config-pathname }?{ concat_lines_of( table = lt_param sep = `&` ) }|.

  ENDMETHOD.


  METHOD start_tcode_of_url.

    DATA(lv_search) = io_client->get( )-s_config-search.
    FIND FIRST OCCURRENCE OF PCRE |[?&]{ c_url_tcode }=([A-Za-z0-9_/]\{1,20\})(&\|$)|
      IN lv_search SUBMATCHES DATA(lv_tcode).
    IF sy-subrc = 0.
      result = to_upper( lv_tcode ).
    ENDIF.

  ENDMETHOD.


  METHOD confirm_logoff.

    " /nend and System > Log Off ask first, like the SAP GUI
    io_client->message_box_display(
        text             = `Unsaved data will be lost. Do you want to log off?`
        type             = `confirm`
        title            = `Log Off`
        onclose          = c_ev_logoff
        actions          = VALUE #( ( `YES` ) ( `NO` ) )
        emphasizedaction = `YES` ).

  ENDMETHOD.


  METHOD handle_menu.

    CASE iv_code.
      WHEN c_menu-own_data.
        " System > User Profile > Own Data - the own user in SU01
        result = start_tcode( io_client = io_client
                              iv_tcode  = `SU01`
                              it_params = VALUE #( ( name  = zif_zlk05_start_params=>c_user
                                                     value = sy-uname ) ) ).
      WHEN c_menu-own_spool.
        result = start_tcode( io_client = io_client
                              iv_tcode  = `SP01`
                              it_params = VALUE #( ( name  = zif_zlk05_start_params=>c_user
                                                     value = sy-uname ) ) ).
      WHEN c_menu-own_jobs.
        result = start_tcode( io_client = io_client iv_tcode = `SM37` ).
      WHEN c_menu-auth_check.
        result = start_tcode( io_client = io_client iv_tcode = `SU53` ).
      WHEN c_menu-status.
        show_status( io_client ).
        result-outcome = c_navigated.
      WHEN c_menu-find.
        show_find( io_client ).
        result-outcome = c_navigated.
      WHEN c_menu-list_save.
        result = save_list( io_client ).
      WHEN c_menu-logoff.
        confirm_logoff( io_client ).
        result-outcome = c_navigated.
      WHEN c_menu-session.
        result = open_session( io_client = io_client iv_tcode = `` ).
      WHEN c_menu-help.
        show_help( io_client ).
        result-outcome = c_navigated.
      WHEN c_menu-keys.
        show_help( io_client = io_client iv_keys = abap_true ).
        result-outcome = c_navigated.
      WHEN OTHERS.
        IF iv_code CP |{ c_menu-service }*|.
          result = start_tcode( io_client = io_client
                                iv_tcode  = substring( val = iv_code off = strlen( c_menu-service ) ) ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.


  METHOD running_app.

    CLEAR: eo_app, ev_class, ev_tcode.
    TRY.
        eo_app = io_client->get_app( ).
      CATCH cx_root.
        CLEAR eo_app.
    ENDTRY.
    IF eo_app IS NOT BOUND.
      RETURN.
    ENDIF.
    ev_class = zcl_zlk05_auth=>class_name_of( eo_app ).
    IF ev_class = c_entry_class.
      ev_tcode = `SMEN`.
    ELSE.
      DATA(lt_tcodes) = zcl_zlk05_auth=>get_tcodes_of_class( ev_class ).
      ev_tcode = VALUE #( lt_tcodes[ 1 ] OPTIONAL ).
    ENDIF.

  ENDMETHOD.


  METHOD add_button.

    IF is_button-sep = abap_true.
      io_bar->tag( `ToolbarSeparator` ).
      RETURN.
    ENDIF.

    " entries with a text are buttons, like Background or All Entries
    IF is_button-text IS NOT INITIAL.
      IF is_button-press IS INITIAL OR is_button-disabled = abap_true.
        io_bar->tag( `Button`
            )->a( n = `text`    v = is_button-text
            )->a( n = `icon`    v = is_button-icon
            )->a( n = `type`    v = `Transparent`
            )->a( n = `enabled` v = `false`
            )->a( n = `tooltip` v = is_button-tooltip ).
      ELSE.
        io_bar->tag( `Button`
            )->a( n = `text`    v = is_button-text
            )->a( n = `icon`    v = is_button-icon
            )->a( n = `type`    v = `Transparent`
            )->a( n = `tooltip` v = is_button-tooltip
            )->a( n = `press`   v = is_button-press ).
      ENDIF.
      RETURN.
    ENDIF.

    " Icons instead of buttons - sap.ui.core.Icon can be coloured and that
    " is what gives the toolbars their SAP GUI look. sap.ui.core.Icon has no
    " ENABLED, so a disabled icon is rendered grey and without its handler.
    IF is_button-press IS INITIAL OR is_button-disabled = abap_true.
      io_bar->tag( n = `Icon` ns = `core`
          )->a( n = `src`     v = is_button-icon
          )->a( n = `size`    v = `1.05rem`
          )->a( n = `color`   v = COND string( WHEN is_button-disabled = abap_true
                                               THEN c_grey ELSE is_button-color )
          )->a( n = `tooltip` v = is_button-tooltip
          )->a( n = `class`   v = `sapUiTinyMarginEnd` ).
    ELSE.
      io_bar->tag( n = `Icon` ns = `core`
          )->a( n = `src`     v = is_button-icon
          )->a( n = `size`    v = `1.05rem`
          )->a( n = `color`   v = is_button-color
          )->a( n = `tooltip` v = is_button-tooltip
          )->a( n = `class`   v = `sapUiTinyMarginEnd`
          )->a( n = `press`   v = is_button-press ).
    ENDIF.

  ENDMETHOD.


  METHOD add_label.

    io_parent->tag( `Label`
        )->a( n = `text`  v = iv_text
        )->a( n = `width` v = iv_width ).

  ENDMETHOD.


  METHOD popup_open.

    eo_popup = z2ui5_cl_ui5_view_builder=>factory( ).
    result = eo_popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
            )->a( n = `title`         t = iv_title
            )->a( n = `contentWidth`  v = iv_width
            )->a( n = `draggable`     v = `true`
            )->a( n = `resizable`     v = `true` ).

  ENDMETHOD.


  METHOD popup_show.

    io_dialog->ele( `buttons`
        )->tag( `Button`
            )->a( n = `text`  v = `Close`
            )->a( n = `icon`  v = `sap-icon://decline`
            )->a( n = `press` v = io_client->_event( c_ev_popup_close ) ).
    io_client->popup_display( io_popup->stringify( ) ).

  ENDMETHOD.


  METHOD show_status.

    " System > Status: the data of the session, the running transaction
    " and the system, grouped like the dialog of the SAP GUI
    running_app( EXPORTING io_client = io_client
                 IMPORTING ev_class  = DATA(lv_class)
                           ev_tcode  = DATA(lv_tcode) ).

    DATA(lt_status) = zcl_zlk05_sys_api=>get_system_status( iv_tcode   = lv_tcode
                                                            iv_program = lv_class ).

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA(dialog) = popup_open( EXPORTING io_client = io_client
                                         iv_title  = `System: Status`
                               IMPORTING eo_popup  = popup ).
    DATA(box) = dialog->ele( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(lv_group) = ``.
    LOOP AT lt_status INTO DATA(ls_status).
      IF ls_status-group <> lv_group.
        lv_group = ls_status-group.
        box->tag( `Title`
            )->a( n = `text`  t = lv_group
            )->a( n = `level` v = `H4`
            )->a( n = `class` v = `sapUiSmallMarginTop` ).
      ENDIF.
      DATA(row) = box->ele( `HBox` ).
      row->tag( `Label` )->a( n = `text` t = ls_status-label )->a( n = `width` v = `14rem` ).
      row->tag( `Text`  )->a( n = `text` t = ls_status-value ).
    ENDLOOP.

    popup_show( io_client = io_client io_popup = popup io_dialog = dialog ).

  ENDMETHOD.


  METHOD show_help.

    running_app( EXPORTING io_client = io_client
                 IMPORTING ev_tcode  = DATA(lv_tcode) ).

    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA(dialog) = popup_open( EXPORTING io_client = io_client
                                         iv_title  = COND #( WHEN iv_keys = abap_true THEN `Keyboard Shortcuts`
                                                             ELSE `Application Help` )
                                         iv_width  = `44rem`
                               IMPORTING eo_popup  = popup ).
    DATA(box) = dialog->ele( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).

    IF iv_keys = abap_false.
      IF lv_tcode IS NOT INITIAL.
        box->tag( `Title` )->a( n = `text` t = |Transaction { lv_tcode }| )->a( n = `level` v = `H4` ).
        DATA(lt_apps) = zcl_zlk05_tcode_router=>get_apps( ).
        box->tag( `Text` )->a( n = `text` t = VALUE string( lt_apps[ tcode = lv_tcode ]-text OPTIONAL ) ).
      ENDIF.
      " the documentation is on SAP Help Portal - plain links, opened by the
      " browser in a new tab
      box->tag( `Link`
          )->a( n = `text`   t = |SAP Help Portal: search for { lv_tcode }|
          )->a( n = `href`   t = |https://help.sap.com/docs/search?q={ escape( val = lv_tcode format = cl_abap_format=>e_url_full ) }|
          )->a( n = `target` v = `_blank`
          )->a( n = `class`  v = `sapUiSmallMarginTop` ).
      box->tag( `Link`
          )->a( n = `text`   v = `SAP Help Portal`
          )->a( n = `href`   v = `https://help.sap.com`
          )->a( n = `target` v = `_blank` ).
      box->tag( `Link`
          )->a( n = `text`   v = `SAP for Me - SAP Notes and Knowledge Base`
          )->a( n = `href`   v = `https://me.sap.com/notes`
          )->a( n = `target` v = `_blank` ).
    ENDIF.

    " the keys and commands this environment understands
    box->tag( `Title`
        )->a( n = `text`  v = `Function keys and commands`
        )->a( n = `level` v = `H4`
        )->a( n = `class` v = `sapUiSmallMarginTop` ).
    LOOP AT VALUE string_table(
        ( `Enter|Continue / execute the command field` )
        ( `F1|Help` )
        ( `F3|Back - one screen back` )
        ( `Shift+F3|Exit - leave the transaction` )
        ( `F12|Cancel` )
        ( `F8|Execute` )
        ( `Ctrl+F / Ctrl+G|Find / find next in the lists of the screen` )
        ( `Ctrl+P|Print (browser)` )
        ( `SE80|Start a transaction` )
        ( `/nSE80|End the transaction and start SE80` )
        ( `/n|End the transaction` )
        ( `/oSE80|New session (browser tab) with SE80` )
        ( `/o|New session` )
        ( `/nend|Log off (with confirmation)` )
        ( `/nex|Log off at once` ) ) INTO DATA(lv_line).
      SPLIT lv_line AT `|` INTO DATA(lv_key) DATA(lv_text).
      DATA(row) = box->ele( `HBox` ).
      row->tag( `Label` )->a( n = `text` t = lv_key )->a( n = `width` v = `10rem` ).
      row->tag( `Text`  )->a( n = `text` t = lv_text ).
    ENDLOOP.

    popup_show( io_client = io_client io_popup = popup io_dialog = dialog ).

  ENDMETHOD.


  METHOD show_find.

    " System > List > Find: the term is read from the dialog when Find is
    " pressed - the frame keeps no state between two roundtrips
    DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
    DATA(dialog) = popup_open( EXPORTING io_client = io_client
                                         iv_title  = `Find`
                                         iv_width  = `48rem`
                               IMPORTING eo_popup  = popup ).
    DATA(box) = dialog->ele( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(lv_find) = io_client->_event(
        val   = c_ev_find_exec
        t_arg = VALUE #( ( |$controller.slotValue('{ io_client->cs_view-popup }', 'idGuiFindTerm', 'getValue')| ) ) ).

    DATA(row) = box->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    row->tag( `Label` )->a( n = `text` v = `Find` )->a( n = `width` v = `5rem` ).
    row->tag( `Input`
        )->a( n = `id`     v = `idGuiFindTerm`
        )->a( n = `value`  t = iv_term
        )->a( n = `width`  v = `24rem`
        )->a( n = `submit` v = lv_find ).
    row->tag( `Button`
        )->a( n = `text`  v = `Find`
        )->a( n = `icon`  v = `sap-icon://sys-find`
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = lv_find
        )->a( n = `class` v = `sapUiTinyMarginBegin` ).

    IF iv_search = abap_true.
      running_app( EXPORTING io_client = io_client
                   IMPORTING eo_app    = DATA(lo_app) ).
      IF condense( iv_term ) = ``.
        box->tag( `Text` )->a( n = `text` v = `Enter a search term.` )->a( n = `class` v = `sapUiSmallMarginTop` ).
      ELSE.
        DATA(lt_hits) = find_in_lists( io_app = lo_app iv_term = condense( iv_term ) ).
        box->tag( `Text`
            )->a( n = `text`  t = COND #( WHEN lt_hits IS INITIAL
                                          THEN |"{ condense( iv_term ) }" was not found in the lists of this screen.|
                                          ELSE |{ lines( lt_hits ) } hit(s) for "{ condense( iv_term ) }".| )
            )->a( n = `class` v = `sapUiSmallMarginTop sapUiSmallMarginBottom` ).
        IF lt_hits IS NOT INITIAL.
          DATA(tab) = box->ele( `Table` )->a( n = `class` v = `sapUiSizeCompact` ).
          DATA(cols) = tab->ele( `columns` ).
          LOOP AT VALUE string_table( ( `List` ) ( `Row` ) ( `Column` ) ( `Value` ) ) INTO DATA(lv_head).
            cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = lv_head ).
          ENDLOOP.
          DATA(items) = tab->ele( `items` ).
          LOOP AT lt_hits INTO DATA(ls_hit).
            DATA(cells) = items->ele( `ColumnListItem` )->ele( `cells` ).
            cells->tag( `Text` )->a( n = `text` t = ls_hit-list ).
            cells->tag( `Text` )->a( n = `text` t = |{ ls_hit-row }| ).
            cells->tag( `Text` )->a( n = `text` t = ls_hit-column ).
            cells->tag( `Text` )->a( n = `text` t = ls_hit-value ).
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.

    popup_show( io_client = io_client io_popup = popup io_dialog = dialog ).

  ENDMETHOD.


  METHOD get_lists.

    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.

    IF io_app IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(lo_class) = CAST cl_abap_classdescr( cl_abap_typedescr=>describe_by_object_ref( io_app ) ).

    LOOP AT lo_class->attributes INTO DATA(ls_attr)
         WHERE visibility   = cl_abap_objectdescr=>public
           AND is_class     = abap_false
           AND type_kind    = cl_abap_typedescr=>typekind_table.
      " attributes of an interface (Z2UI5_IF_APP~...) are no lists
      IF ls_attr-name CA `~`.
        CONTINUE.
      ENDIF.

      " flat lines only - a deep line has no place in a list
      DATA(lo_table) = CAST cl_abap_tabledescr( lo_class->get_attribute_type( ls_attr-name ) ).
      DATA(lo_line)  = lo_table->get_table_line_type( ).
      IF lo_line->kind = cl_abap_typedescr=>kind_struct.
        DATA(lv_flat) = abap_true.
        LOOP AT CAST cl_abap_structdescr( lo_line )->get_components( ) INTO DATA(ls_comp).
          IF ls_comp-type->kind <> cl_abap_typedescr=>kind_elem.
            lv_flat = abap_false.
          ENDIF.
        ENDLOOP.
        IF lv_flat = abap_false.
          CONTINUE.
        ENDIF.
      ELSEIF lo_line->kind <> cl_abap_typedescr=>kind_elem.
        CONTINUE.
      ENDIF.

      ASSIGN io_app->(ls_attr-name) TO <lt_table>.
      IF sy-subrc <> 0 OR lines( <lt_table> ) = 0.
        CONTINUE.
      ENDIF.

      APPEND VALUE #( name = ls_attr-name lines = lines( <lt_table> ) ) TO result
             ASSIGNING FIELD-SYMBOL(<ls_list>).
      GET REFERENCE OF <lt_table> INTO <ls_list>-data.
    ENDLOOP.

  ENDMETHOD.


  METHOD row_values.

    CLEAR: et_names, et_values.
    DATA(lo_type) = cl_abap_typedescr=>describe_by_data( is_row ).

    IF lo_type->kind = cl_abap_typedescr=>kind_struct.
      LOOP AT CAST cl_abap_structdescr( lo_type )->components INTO DATA(ls_comp).
        ASSIGN COMPONENT ls_comp-name OF STRUCTURE is_row TO FIELD-SYMBOL(<lv_value>).
        IF sy-subrc = 0.
          APPEND CONV string( ls_comp-name ) TO et_names.
          APPEND condense( |{ <lv_value> }| ) TO et_values.
        ENDIF.
      ENDLOOP.
    ELSE.
      APPEND `LINE` TO et_names.
      APPEND condense( |{ is_row }| ) TO et_values.
    ENDIF.

  ENDMETHOD.


  METHOD find_in_lists.

    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.

    DATA(lv_term) = condense( iv_term ).
    IF lv_term IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT get_lists( io_app ) INTO DATA(ls_list).
      ASSIGN ls_list-data->* TO <lt_table>.
      DATA(lv_row) = 0.
      LOOP AT <lt_table> ASSIGNING FIELD-SYMBOL(<ls_row>).
        lv_row = lv_row + 1.
        row_values( EXPORTING is_row    = <ls_row>
                    IMPORTING et_names  = DATA(lt_names)
                              et_values = DATA(lt_values) ).
        LOOP AT lt_values INTO DATA(lv_value).
          " CS ignores upper and lower case - like the Find of the SAP GUI
          IF lv_value CS lv_term.
            APPEND VALUE #( list   = ls_list-name
                            row    = lv_row
                            column = lt_names[ sy-tabix ]
                            value  = lv_value ) TO result.
            IF lines( result ) >= iv_max.
              RETURN.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.


  METHOD csv_value.

    result = iv_value.
    " a spreadsheet runs = + - @ at the start of a cell as a formula - the
    " leading ' makes it text (CSV injection); plain numbers stay numbers
    IF result IS NOT INITIAL AND result(1) CA `=+-@`
       AND NOT ( result CO `-0123456789.,` AND strlen( result ) > 1 ).
      result = |'{ result }|.
    ENDIF.
    IF result CA |;"\r\n|.
      REPLACE ALL OCCURRENCES OF `"` IN result WITH `""`.
      result = |"{ result }"|.
    ENDIF.

  ENDMETHOD.


  METHOD list_to_csv.

    FIELD-SYMBOLS <lt_table> TYPE ANY TABLE.
    DATA lt_lines TYPE string_table.

    ASSIGN ir_table->* TO <lt_table>.
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    LOOP AT <lt_table> ASSIGNING FIELD-SYMBOL(<ls_row>).
      row_values( EXPORTING is_row    = <ls_row>
                  IMPORTING et_names  = DATA(lt_names)
                            et_values = DATA(lt_values) ).
      IF lt_lines IS INITIAL.
        APPEND concat_lines_of( table = lt_names sep = `;` ) TO lt_lines.
      ENDIF.
      DATA(lt_cells) = VALUE string_table( FOR lv_v IN lt_values ( csv_value( lv_v ) ) ).
      APPEND concat_lines_of( table = lt_cells sep = `;` ) TO lt_lines.
    ENDLOOP.

    result = concat_lines_of( table = lt_lines sep = |\r\n| ).

  ENDMETHOD.


  METHOD save_list.

    " System > List > Save > Local File: a list of the screen as a file
    " for a spreadsheet. With several lists the user picks one.
    running_app( EXPORTING io_client = io_client
                 IMPORTING eo_app    = DATA(lo_app)
                           ev_tcode  = DATA(lv_tcode) ).
    DATA(lt_lists) = get_lists( lo_app ).
    IF iv_list IS NOT INITIAL.
      DELETE lt_lists WHERE name <> to_upper( iv_list ).
    ENDIF.

    IF lt_lists IS INITIAL.
      result-message  = `This screen shows no list that could be saved.`.
      result-msg_type = `Warning`.
      result-outcome  = c_message.
      RETURN.
    ENDIF.

    IF lines( lt_lists ) > 1.
      DATA popup TYPE REF TO z2ui5_cl_ui5_view_builder.
      DATA(dialog) = popup_open( EXPORTING io_client = io_client
                                           iv_title  = `Save List to Local File`
                                           iv_width  = `30rem`
                                 IMPORTING eo_popup  = popup ).
      DATA(box) = dialog->ele( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).
      box->tag( `Text` )->a( n = `text` v = `Which list of the screen do you want to save?` ).
      LOOP AT lt_lists INTO DATA(ls_choice).
        box->tag( `Button`
            )->a( n = `text`  t = |{ ls_choice-name } ({ ls_choice-lines } rows)|
            )->a( n = `icon`  v = `sap-icon://download`
            )->a( n = `width` v = `100%`
            )->a( n = `class` v = `sapUiTinyMarginTop`
            )->a( n = `press` v = io_client->_event( val = c_ev_list_save arg = ls_choice-name ) ).
      ENDLOOP.
      popup_show( io_client = io_client io_popup = popup io_dialog = dialog ).
      result-outcome = c_navigated.
      RETURN.
    ENDIF.

    DATA(ls_list) = lt_lists[ 1 ].
    " UTF-8 with byte order mark, so the spreadsheet reads the umlauts
    DATA lv_xfile TYPE xstring.
    DATA(lv_xcsv) = cl_abap_conv_codepage=>create_out( )->convert( list_to_csv( ls_list-data ) ).
    CONCATENATE cl_abap_char_utilities=>byte_order_mark_utf8 lv_xcsv INTO lv_xfile IN BYTE MODE.
    DATA(lv_b64)  = cl_http_utility=>encode_x_base64( lv_xfile ).
    DATA(lv_file) = |{ COND string( WHEN lv_tcode IS INITIAL THEN `LIST` ELSE lv_tcode ) }_{ ls_list-name }.csv|.

    io_client->follow_up_action( val   = io_client->cs_event-download_b64_file
                                 t_arg = VALUE #( ( |data:text/csv;base64,{ lv_b64 }| ) ( lv_file ) ) ).
    io_client->popup_destroy( ).

    result-message  = |{ ls_list-lines } row(s) saved as { lv_file }.|.
    result-msg_type = `Success`.
    result-outcome  = c_message.

  ENDMETHOD.

ENDCLASS.
