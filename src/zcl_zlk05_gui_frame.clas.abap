CLASS zcl_zlk05_gui_frame DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  The window frame of the classic SAP GUI, shared by all apps of
*  package $ZLK_05.
*
*  A SAP GUI window is built from six horizontal bands:
*
*    1  menu bar                 Table Display  Edit  Goto  ...
*    2  system function bar      command field + the standard icons
*    3  title bar                SAP logo + screen title
*    4  application function bar screen specific buttons
*    5  work area                the screen itself
*    6  status bar               message + system / server / INS
*
*  Bands 1, 2, 3 and 6 look the same on every screen and are built here.
*  Band 4 is filled by the app, band 5 is the app's own content.
*
*  Everything in this class is presentation only - it never reads or
*  changes system data.
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
    "! through handle_frame_event( ), so the command field and the Back
    "! button work the same way on every screen.
    CONSTANTS c_ev_command TYPE string VALUE `GUI_COMMAND`.
    CONSTANTS c_ev_back    TYPE string VALUE `GUI_BACK`.

    "! Return values of handle_frame_event( )
    CONSTANTS c_not_handled TYPE string VALUE ``.
    CONSTANTS c_navigated   TYPE string VALUE `NAV`.
    CONSTANTS c_message     TYPE string VALUE `MSG`.

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

    "! Opens View / Shell / Page and returns the page, ready for the bands.
    CLASS-METHODS open_window
      IMPORTING io_view       TYPE REF TO z2ui5_cl_ai_xml
      RETURNING VALUE(result) TYPE REF TO z2ui5_cl_ai_xml.

    "! Band 1 - menu bar. The entries carry no menus, they are shown so the
    "! screen is recognisable.
    CLASS-METHODS build_menu_bar
      IMPORTING io_parent  TYPE REF TO z2ui5_cl_ai_xml
                it_entries TYPE string_table.

    "! Band 2 - system function bar with the command field.
    "! iv_cmd_value / iv_cmd_event wire up the command field,
    "! iv_back_event makes the yellow Back arrow (F3) active.
    CLASS-METHODS build_system_bar
      IMPORTING io_parent     TYPE REF TO z2ui5_cl_ai_xml
                iv_cmd_value  TYPE string OPTIONAL
                iv_cmd_event  TYPE string OPTIONAL
                iv_back_event TYPE string OPTIONAL.

    "! Band 3 - title bar with the SAP logo and the screen title.
    CLASS-METHODS build_title_bar
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ai_xml
                iv_title  TYPE string
                iv_hint   TYPE string OPTIONAL.

    "! Band 4 - application function bar.
    CLASS-METHODS build_app_bar
      IMPORTING io_parent  TYPE REF TO z2ui5_cl_ai_xml
                it_buttons TYPE ty_t_button.

    "! Band 6 - status bar. Message on the left, system data on the right.
    "! The system data are passed in by the app so that this class stays free
    "! of system access. When they are omitted the SY fields are used.
    CLASS-METHODS build_status_bar
      IMPORTING io_parent   TYPE REF TO z2ui5_cl_ai_xml
                iv_message  TYPE string OPTIONAL
                iv_msg_type TYPE string OPTIONAL
                iv_sysid    TYPE string OPTIONAL
                iv_client   TYPE string OPTIONAL
                iv_user     TYPE string OPTIONAL
                iv_host     TYPE string OPTIONAL.

    "! Registers the function keys of the SAP GUI on the running app.
    "! F3 / Shift+F3 / F12 fire iv_back_name, F8 the execute event of the
    "! screen and Ctrl+S its save event. Call it from every view method -
    "! the registrations belong to the running app and are dropped as soon
    "! as another app takes over.
    "! iv_back_name is the event the screen wants for Back: the default
    "! c_ev_back leaves the transaction, a screen inside a transaction
    "! passes its own event so that F3 goes back one screen. An empty name
    "! registers no Back key at all (entry screen of the session).
    CLASS-METHODS register_keys
      IMPORTING io_client    TYPE REF TO z2ui5_if_client
                iv_back_name TYPE string DEFAULT c_ev_back
                iv_exec_name TYPE string OPTIONAL
                iv_save_name TYPE string OPTIONAL.

    "! Handles the two events of the frame: the command field starts the
    "! transaction that was typed in, Back leaves the screen. Returns
    "! c_navigated (the caller must return at once), c_message (a message
    "! was placed in cv_message) or c_not_handled.
    CLASS-METHODS handle_frame_event
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                iv_event      TYPE string
                iv_command    TYPE string OPTIONAL
      EXPORTING ev_message    TYPE string
                ev_msg_type   TYPE string
      RETURNING VALUE(result) TYPE string.

    "! A single coloured icon or button inside a toolbar.
    CLASS-METHODS add_button
      IMPORTING io_bar    TYPE REF TO z2ui5_cl_ai_xml
                is_button TYPE ty_s_button.

    "! Label / field row of a classic dynpro selection screen
    CLASS-METHODS add_label
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ai_xml
                iv_text   TYPE string
                iv_width  TYPE string DEFAULT `11rem`.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_zlk05_gui_frame IMPLEMENTATION.

  METHOD open_window.

    result = io_view->open( n = `View` ns = `mvc`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:mvc`  v = `sap.ui.core.mvc`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->a( n = `xmlns:table`  v = `sap.ui.table`
        )->a( n = `xmlns:editor` v = `sap.ui.codeeditor`
        )->a( n = `height`     v = `100%`
        )->open( `Shell`
        )->a( n = `appWidthLimited` v = `false`
        )->open( `Page`
            )->a( n = `showHeader`      v = `false`
            )->a( n = `enableScrolling` v = `false` ).

  ENDMETHOD.


  METHOD build_menu_bar.

    DATA(bar) = io_parent->open( `Toolbar`
        )->a( n = `design` v = `Solid`
        )->a( n = `height` v = `1.85rem` ).

    LOOP AT it_entries INTO DATA(lv_entry).
      bar->leaf( `Text`
          )->a( n = `text`    v = lv_entry
          )->a( n = `class`   v = `sapUiSmallMarginEnd`
          )->a( n = `tooltip` v = |{ lv_entry } - the menu bar is shown for orientation only| ).
    ENDLOOP.

  ENDMETHOD.


  METHOD build_system_bar.

    DATA(bar) = io_parent->open( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.35rem` ).

    " green tick - Enter
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-enter-2`
                                     color   = c_green
                                     tooltip = `Continue (Enter)`
                                     press   = iv_cmd_event ) ).

    " command field - active on every screen, exactly like in the SAP GUI
    IF iv_cmd_event IS NOT INITIAL.
      bar->leaf( `Input`
          )->a( n = `id`      v = `idCommandField`
          )->a( n = `value`   v = iv_cmd_value
          )->a( n = `width`   v = `13rem`
          )->a( n = `tooltip` v = `Command field - enter a transaction code, /nSE80 works as well`
          )->a( n = `submit`  v = iv_cmd_event ).
    ELSE.
      bar->leaf( `Input`
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

    " Back / Exit / Cancel - active when the app passes a back event
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
                                       press   = iv_back_event ) ).
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
                                     tooltip = `Print (Ctrl+P) - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-find`
                                     color   = c_grey
                                     tooltip = `Find (Ctrl+F) - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-find-next`
                                     color   = c_grey
                                     tooltip = `Find next (Ctrl+G) - not available in this environment` ) ).

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-first-page`
                                     color   = c_green
                                     tooltip = `First page (Ctrl+Page up) - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-prev-page`
                                     color   = c_green
                                     tooltip = `Previous page (Page up) - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-next-page`
                                     color   = c_green
                                     tooltip = `Next page (Page down) - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-last-page`
                                     color   = c_green
                                     tooltip = `Last page (Ctrl+Page down) - not available in this environment` ) ).

    add_button( io_bar = bar is_button = VALUE #( sep = abap_true ) ).

    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-monitor`
                                     color   = c_gold
                                     tooltip = `Create new session - not available in this environment` ) ).
    add_button( io_bar    = bar
                is_button = VALUE #( icon    = `sap-icon://sys-help`
                                     color   = c_blue
                                     tooltip = `Help (F1) - not available in this environment` ) ).

  ENDMETHOD.


  METHOD build_title_bar.

    DATA(bar) = io_parent->open( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.5rem` ).

    bar->leaf( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://SAP-logo-shape`
        )->a( n = `size`    v = `1.35rem`
        )->a( n = `color`   v = c_blue
        )->a( n = `tooltip` v = `SAP` ).

    bar->leaf( `Title`
        )->a( n = `text`  v = iv_title
        )->a( n = `level` v = `H2`
        )->a( n = `class` v = `sapUiSmallMarginBegin` ).

    IF iv_hint IS NOT INITIAL.
      bar->leaf( `ToolbarSpacer` ).
      bar->leaf( `Text` )->a( n = `text` v = iv_hint ).
    ENDIF.

  ENDMETHOD.


  METHOD build_app_bar.

    DATA(bar) = io_parent->open( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.1rem` ).

    LOOP AT it_buttons INTO DATA(ls_button).
      add_button( io_bar = bar is_button = ls_button ).
    ENDLOOP.

  ENDMETHOD.


  METHOD build_status_bar.

    DATA(bar) = io_parent->open( `footer`
        )->open( `OverflowToolbar`
        )->a( n = `height` v = `1.95rem` ).

    IF iv_message IS NOT INITIAL.
      bar->leaf( n = `Icon` ns = `core`
          )->a( n = `src`   v = COND string(
                  WHEN iv_msg_type = `Error`   THEN `sap-icon://error`
                  WHEN iv_msg_type = `Warning` THEN `sap-icon://alert`
                  ELSE                              `sap-icon://message-information` )
          )->a( n = `size`  v = `0.875rem`
          )->a( n = `color` v = COND string(
                  WHEN iv_msg_type = `Error`   THEN c_red
                  WHEN iv_msg_type = `Warning` THEN c_yellow
                  ELSE                              c_blue ) ).

      bar->leaf( `Text`
          )->a( n = `text`  v = iv_message
          )->a( n = `class` v = `sapUiTinyMarginBegin` ).
    ENDIF.

    bar->leaf( `ToolbarSpacer` ).

    DATA(lv_sysid)  = COND string( WHEN iv_sysid  IS NOT INITIAL THEN iv_sysid
                                   ELSE CONV string( sy-sysid ) ).
    DATA(lv_client) = COND string( WHEN iv_client IS NOT INITIAL THEN iv_client
                                   ELSE CONV string( sy-mandt ) ).
    DATA(lv_user)   = COND string( WHEN iv_user   IS NOT INITIAL THEN iv_user
                                   ELSE CONV string( sy-uname ) ).
    DATA(lv_host)   = COND string( WHEN iv_host   IS NOT INITIAL THEN iv_host
                                   ELSE CONV string( sy-host ) ).

    bar->leaf( n = `Icon` ns = `core`
        )->a( n = `src`   v = `sap-icon://open-command-field`
        )->a( n = `size`  v = `0.75rem`
        )->a( n = `color` v = c_grey ).

    bar->leaf( `ToolbarSeparator` ).

    " the tooltip carries system, client and user, like the expanded
    " status field of the SAP GUI
    bar->leaf( `Text`
        )->a( n = `text`    v = lv_sysid
        )->a( n = `tooltip` v = |System { lv_sysid } - Client { lv_client } - User { lv_user }| ).

    bar->leaf( `ToolbarSeparator` ).

    bar->leaf( `Text`
        )->a( n = `text`    v = lv_host
        )->a( n = `tooltip` v = |Application server { lv_host }| ).

    bar->leaf( `ToolbarSeparator` ).

    bar->leaf( `Text`
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
    io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                t_arg = VALUE #( ( `F3` ) ( iv_back_name ) ) ).
    io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                t_arg = VALUE #( ( `Shift+F3` ) ( iv_back_name ) ) ).
    io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                t_arg = VALUE #( ( `F12` ) ( iv_back_name ) ) ).

    io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                t_arg = VALUE #( ( `F8` ) ( iv_exec_name ) ) ).

    io_client->follow_up_action( val   = io_client->cs_event-keyboard_shortcut
                                t_arg = VALUE #( ( `Ctrl+S` ) ( iv_save_name ) ) ).

  ENDMETHOD.


  METHOD handle_frame_event.

    " ===== Frame events =====
    CLEAR: ev_message, ev_msg_type.
    result = c_not_handled.
    IF io_client IS INITIAL.
      RETURN.
    ENDIF.

    CASE iv_event.

      WHEN c_ev_back.
        " F3 / Shift+F3 / F12 and the arrows of the system function bar
        io_client->nav_app_leave( ).
        result = c_navigated.

      WHEN c_ev_command.
        DATA lv_result TYPE string.
        zcl_zlk05_tcode_router=>run(
          EXPORTING iv_command  = iv_command
                    io_client   = io_client
          IMPORTING ev_message  = ev_message
                    ev_msg_type = ev_msg_type
          RECEIVING result      = lv_result ).

        CASE lv_result.
          WHEN zcl_zlk05_tcode_router=>c_nav.
            result = c_navigated.
          WHEN zcl_zlk05_tcode_router=>c_msg.
            result = c_message.
          WHEN OTHERS.
            result = c_not_handled.
        ENDCASE.

      WHEN OTHERS.
        result = c_not_handled.

    ENDCASE.

  ENDMETHOD.


  METHOD add_button.

    IF is_button-sep = abap_true.
      io_bar->leaf( `ToolbarSeparator` ).
      RETURN.
    ENDIF.

    " entries with a text are buttons, like Background or All Entries
    IF is_button-text IS NOT INITIAL.
      IF is_button-press IS INITIAL OR is_button-disabled = abap_true.
        io_bar->leaf( `Button`
            )->a( n = `text`    v = is_button-text
            )->a( n = `icon`    v = is_button-icon
            )->a( n = `type`    v = `Transparent`
            )->a( n = `enabled` v = `false`
            )->a( n = `tooltip` v = is_button-tooltip ).
      ELSE.
        io_bar->leaf( `Button`
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
      io_bar->leaf( n = `Icon` ns = `core`
          )->a( n = `src`     v = is_button-icon
          )->a( n = `size`    v = `1.05rem`
          )->a( n = `color`   v = COND string( WHEN is_button-disabled = abap_true
                                               THEN c_grey ELSE is_button-color )
          )->a( n = `tooltip` v = is_button-tooltip
          )->a( n = `class`   v = `sapUiTinyMarginEnd` ).
    ELSE.
      io_bar->leaf( n = `Icon` ns = `core`
          )->a( n = `src`     v = is_button-icon
          )->a( n = `size`    v = `1.05rem`
          )->a( n = `color`   v = is_button-color
          )->a( n = `tooltip` v = is_button-tooltip
          )->a( n = `class`   v = `sapUiTinyMarginEnd`
          )->a( n = `press`   v = is_button-press ).
    ENDIF.

  ENDMETHOD.


  METHOD add_label.

    io_parent->leaf( `Label`
        )->a( n = `text`  v = iv_text
        )->a( n = `width` v = iv_width ).

  ENDMETHOD.

ENDCLASS.
