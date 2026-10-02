CLASS zcl_zlk05_tcode_router DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

* ---------------------------------------------------------------------
*  The command field of the SAP GUI is not bound to one screen - a
*  transaction code typed into it starts that transaction from wherever
*  the user currently is. This class is that dispatcher: it holds the
*  list of transactions implemented in this environment and starts the
*  app behind a code, so every screen can offer the command field.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES:
      "! One transaction of this environment. An initial CLASS means the
      "! transaction is listed in the menu but not implemented here.
      BEGIN OF ty_s_app,
        tcode TYPE string,
        text  TYPE string,
        icon  TYPE string,
        class TYPE string,
      END OF ty_s_app.
    TYPES ty_t_app TYPE STANDARD TABLE OF ty_s_app WITH EMPTY KEY.

    TYPES:
      "! Result of run( ): the outcome and the message for the status bar
      BEGIN OF ty_s_result,
        outcome  TYPE string,
        message  TYPE string,
        msg_type TYPE string,
      END OF ty_s_result.

    "! Outcome of run( ) - nothing done, app started, or message returned
    CONSTANTS c_none TYPE string VALUE ``.
    CONSTANTS c_nav  TYPE string VALUE `NAV`.
    CONSTANTS c_msg  TYPE string VALUE `MSG`.

    "! All transactions known to this environment
    CLASS-METHODS get_apps
      RETURNING VALUE(result) TYPE ty_t_app.

    "! Every transaction of this environment that has an app behind it.
    "! The entry screen lists them under Favorites, so all of them are
    "! reachable with one click instead of only through the SAP menu.
    CLASS-METHODS get_favorites
      RETURNING VALUE(result) TYPE ty_t_app.

    "! Command field syntax of the SAP GUI: SE80, /nSE80, /oSE80
    CLASS-METHODS normalize_command
      IMPORTING iv_command    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Starts the transaction typed into the command field.
    "! The outcome is c_nav when an app was started - the caller must
    "! return immediately then - or c_msg when only a message was produced.
    CLASS-METHODS run
      IMPORTING iv_command    TYPE string
                io_client     TYPE REF TO z2ui5_if_client
      RETURNING VALUE(result) TYPE ty_s_result.

  PRIVATE SECTION.

    "! /o, /i, /h ... - session commands that need a real SAP GUI
    CLASS-METHODS session_command_text
      IMPORTING iv_command    TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_zlk05_tcode_router IMPLEMENTATION.

  METHOD get_apps.

    " Transaction code, standard SAP transaction text, implementing app.
    result = VALUE #(
      " ----- Tools - ABAP Workbench - Development -----
      ( tcode = `SE80`  text = `Object Navigator`              icon = `sap-icon://tree`               class = `ZCL_SE80_UI` )
      ( tcode = `SE38`  text = `ABAP Editor`                   icon = `sap-icon://document-text`      class = `ZCL_SE38_A2U5` )
      ( tcode = `SE11`  text = `ABAP Dictionary`               icon = `sap-icon://database`           class = `ZCL_SE11_A2U5` )
      ( tcode = `SE24`  text = `Class Builder`                 icon = `sap-icon://course-book`        class = `ZCL_SE24_A2U5` )
      ( tcode = `SE37`  text = `Function Builder`              icon = `sap-icon://wrench`             class = `ZCL_SE37_A2U5` )
      ( tcode = `SE16N` text = `General Table Display`         icon = `sap-icon://table-view`         class = `ZCL_SE16N_A2U5` )
      ( tcode = `SE16`  text = `Data Browser`                  icon = `sap-icon://grid`               class = `ZCL_SE16N_A2U5` )
      " ----- Tools - Administration - Monitor -----
      ( tcode = `SM21`  text = `Online System Log Analysis`    icon = `sap-icon://newspaper`          class = `ZCL_SM21_A2U5` )
      ( tcode = `SM37`  text = `Overview of Job Selection`     icon = `sap-icon://history`            class = `ZCL_SM37_A2U5` )
      ( tcode = `SM50`  text = `Work Process Overview`         icon = `sap-icon://performance`        class = `ZCL_SM50_A2U5` )
      ( tcode = `SM66`  text = `Global Work Process Overview`  icon = `sap-icon://performance`        class = `ZCL_SM50_A2U5` )
      ( tcode = `SM12`  text = `Display and Delete Locks`      icon = `sap-icon://locked`             class = `ZCL_SM12_A2U5` )
      ( tcode = `ST22`  text = `ABAP Dump Analysis`            icon = `sap-icon://alert`              class = `ZCL_ST22_A2U5` )
      ( tcode = `ST02`  text = `Setups/Tune Buffers`           icon = `sap-icon://database`           class = `ZCL_ST02_A2U5` )
      ( tcode = `ST05`  text = `Performance Trace`             icon = `sap-icon://measuring-point`    class = `ZCL_ST05_A2U5` )
      " ----- Tools - Administration - User & Client -----
      ( tcode = `SU01`  text = `User Maintenance`              icon = `sap-icon://person-placeholder` class = `ZCL_SU01_A2U5` )
      ( tcode = `SCC4`  text = `Client Administration`         icon = `sap-icon://official-service`   class = `ZCL_SCC4_A2U5` )
      ( tcode = `RZ10`  text = `Edit Profiles`                 icon = `sap-icon://action-settings`    class = `ZCL_RZ11_A2U5` )
      ( tcode = `RZ11`  text = `Profile Parameter Maintenance` icon = `sap-icon://action-settings`    class = `ZCL_RZ11_A2U5` )
      " ----- Tools - Transport -----
      ( tcode = `STMS`  text = `Transport Management System`   icon = `sap-icon://shipping-status`    class = `ZCL_STMS_A2U5` )
      ( tcode = `SE09`  text = `Transport Organizer`           icon = `sap-icon://request`            class = `ZCL_SE09_A2U5` )
      ( tcode = `SE10`  text = `Transport Organizer`           icon = `sap-icon://request`            class = `ZCL_SE09_A2U5` )
      ( tcode = `SE93`  text = `Maintain Transaction`           icon = `sap-icon://action-settings`     class = `ZCL_SE93_A2U5` )
      " ----- Listed in the menu, not implemented here -----
      ( tcode = `SE01`  text = `Transport Organizer (Extended)` icon = `sap-icon://request`           class = `` )
      ( tcode = `SE03`  text = `Transport Organizer Tools`     icon = `sap-icon://wrench`             class = `` )
      ( tcode = `SM30`  text = `Call View Maintenance`         icon = `sap-icon://table-view`         class = `` ) ).

  ENDMETHOD.


  METHOD get_favorites.

    " Every transaction this environment can really start, in the order of
    " the list above - the entry screen shows them all under Favorites so
    " that none of them is buried somewhere deep in the SAP menu tree.
    " Transactions that are only listed stay out: a favorite that answers
    " with "not available" would be a dead entry.
    DATA(lt_apps) = get_apps( ).

    LOOP AT lt_apps INTO DATA(ls_app) WHERE class IS NOT INITIAL.
      APPEND ls_app TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD normalize_command.

    result = to_upper( condense( iv_command ) ).
    IF result CP `/N*` OR result CP `/O*`.
      result = substring( val = result off = 2 ).
    ELSEIF result CP `/*`.
      result = substring( val = result off = 1 ).
    ENDIF.
    CONDENSE result NO-GAPS.

  ENDMETHOD.


  METHOD session_command_text.

    " The original commands of the command field that need a real GUI
    " session. They are answered instead of being silently ignored.
    result = SWITCH #( to_upper( condense( iv_command ) )
      WHEN `/N`    THEN `Command /n - cancel the current transaction - needs a SAP GUI session.`
      WHEN `/O`    THEN `Command /o - session overview - needs a SAP GUI session.`
      WHEN `/I`    THEN `Command /i - delete the current session - needs a SAP GUI session.`
      WHEN `/H`    THEN `Command /h - start the debugger - needs a SAP GUI session.`
      WHEN `/$SYNC` OR `/$TAB` OR `/$CUA` OR `/$NAM` OR `/$DYN`
                   THEN `Buffer reset commands are not available in this environment.`
      WHEN `/NEX` OR `/NEND` OR `/I3`
                   THEN `Logoff commands are not available in this environment.`
      ELSE `` ).

  ENDMETHOD.


  METHOD run.

    result-outcome = c_none.

    IF io_client IS INITIAL.
      RETURN.
    ENDIF.

    " session commands first - /o and friends carry no transaction code
    DATA(lv_session) = session_command_text( iv_command ).
    IF lv_session IS NOT INITIAL.
      result-message  = lv_session.
      result-msg_type = `Warning`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    DATA(lv_tcode) = normalize_command( iv_command ).
    IF lv_tcode IS INITIAL.
      result-message  = `Enter a transaction code.`.
      result-msg_type = `Warning`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    DATA(lt_apps) = get_apps( ).
    READ TABLE lt_apps WITH KEY tcode = lv_tcode INTO DATA(ls_app).
    IF sy-subrc <> 0.
      " tell "unknown transaction" apart from "exists but not built here"
      IF zcl_zlk05_sys_api=>transaction_exists( lv_tcode ) = abap_true.
        result-message  = |Transaction { lv_tcode } is not available in this environment.|.
        result-msg_type = `Warning`.
      ELSE.
        result-message  = |Transaction { lv_tcode } does not exist.|.
        result-msg_type = `Error`.
      ENDIF.
      result-outcome = c_msg.
      RETURN.
    ENDIF.

    IF ls_app-class IS INITIAL.
      result-message  = |Transaction { lv_tcode } is not available in this environment.|.
      result-msg_type = `Warning`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    TRY.
        DATA lo_app TYPE REF TO z2ui5_if_app.
        CREATE OBJECT lo_app TYPE (ls_app-class).
        io_client->nav_app_call( lo_app ).
        result-outcome = c_nav.
      CATCH cx_root INTO DATA(lx).
        result-message  = |Error starting transaction { lv_tcode }: { lx->get_text( ) }|.
        result-msg_type = `Error`.
        result-outcome  = c_msg.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.
