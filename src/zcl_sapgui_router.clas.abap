CLASS zcl_sapgui_router DEFINITION
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
      "! Result of run( ): the outcome and the message for the status bar;
      "! check_start( ) also names the app class that would be started
      BEGIN OF ty_s_result,
        outcome  TYPE string,
        message  TYPE string,
        msg_type TYPE string,
        class    TYPE string,
      END OF ty_s_result.

    TYPES:
      "! A command of the command field, taken apart (parse_command)
      BEGIN OF ty_s_command,
        kind  TYPE string,
        tcode TYPE string,
      END OF ty_s_command.

    "! Kinds of command field input, as the SAP GUI tells them apart
    CONSTANTS c_cmd_none       TYPE string VALUE ``.
    "! SE80 - a transaction code
    CONSTANTS c_cmd_tcode      TYPE string VALUE `TCODE`.
    "! /nSE80, /*SE80 - end the current transaction and start SE80
    CONSTANTS c_cmd_new        TYPE string VALUE `NEW`.
    "! /n - end the current transaction
    CONSTANTS c_cmd_end        TYPE string VALUE `END`.
    "! /o, /oSE80 - new session (with SE80)
    CONSTANTS c_cmd_session    TYPE string VALUE `SESSION`.
    "! /nend - log off after a confirmation
    CONSTANTS c_cmd_logoff     TYPE string VALUE `LOGOFF`.
    "! /nex - log off at once
    CONSTANTS c_cmd_logoff_now TYPE string VALUE `LOGOFF_NOW`.
    "! /i, /h, /$tab ... - answered with a message
    CONSTANTS c_cmd_info       TYPE string VALUE `INFO`.

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

    "! Takes a command field input apart like the SAP GUI: /n, /o, /nend,
    "! /nex, /*TCODE, /i ... and plain transaction codes
    CLASS-METHODS parse_command
      IMPORTING iv_command    TYPE string
      RETURNING VALUE(result) TYPE ty_s_command.

    "! Could iv_tcode be started? All checks of run( ) - known here, has
    "! an app, S_TCODE and the basic authorization - without starting it.
    "! outcome c_none: yes, class is the app; c_msg: no, see message.
    CLASS-METHODS check_start
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_result.

    "! Starts the transaction typed into the command field.
    "! The outcome is c_nav when an app was started - the caller must
    "! return immediately then - or c_msg when only a message was produced.
    "! it_params: start values for the app (ZIF_SAPGUI_START_PARAMS), like
    "! the SPA/GPA parameters of a CALL TRANSACTION. Ignored by apps that
    "! do not take start values.
    CLASS-METHODS run
      IMPORTING iv_command    TYPE string
                io_client     TYPE REF TO z2ui5_if_client
                it_params     TYPE zif_sapgui_start_params=>ty_t_param OPTIONAL
                iv_replace    TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE ty_s_result.
    " iv_replace: /n - the new transaction REPLACES the running one, Back
    " from it does not return there. Default: called on top (a jump).

  PRIVATE SECTION.

    "! /o, /i, /h ... - session commands that need a real SAP GUI
    CLASS-METHODS session_command_text
      IMPORTING iv_command    TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_sapgui_router IMPLEMENTATION.

  METHOD get_apps.

    " Transaction code, standard SAP transaction text, implementing app.
    result = VALUE #(
      " ----- Tools - ABAP Workbench - Development -----
      ( tcode = `SE80`  text = `Object Navigator`              icon = `sap-icon://tree`               class = `ZCL_SAPGUI_SE80` )
      ( tcode = `SE38`  text = `ABAP Editor`                   icon = `sap-icon://document-text`      class = `ZCL_SAPGUI_SE38` )
      ( tcode = `SE11`  text = `ABAP Dictionary`               icon = `sap-icon://database`           class = `ZCL_SAPGUI_SE11` )
      ( tcode = `SE24`  text = `Class Builder`                 icon = `sap-icon://course-book`        class = `ZCL_SAPGUI_SE24` )
      ( tcode = `SE37`  text = `Function Builder`              icon = `sap-icon://wrench`             class = `ZCL_SAPGUI_SE37` )
      ( tcode = `SE91`  text = `Message Maintenance`           icon = `sap-icon://message-popup`      class = `ZCL_SAPGUI_SE91` )
      ( tcode = `SE16N` text = `General Table Display`         icon = `sap-icon://table-view`         class = `ZCL_SAPGUI_SE16N` )
      ( tcode = `SE16`  text = `Data Browser`                  icon = `sap-icon://grid`               class = `ZCL_SAPGUI_SE16N` )
      " ----- Tools - Administration - Monitor -----
      ( tcode = `SM21`  text = `Online System Log Analysis`    icon = `sap-icon://newspaper`          class = `ZCL_SAPGUI_SM21` )
      ( tcode = `SM37`  text = `Overview of Job Selection`     icon = `sap-icon://history`            class = `ZCL_SAPGUI_SM37` )
      ( tcode = `SM50`  text = `Work Process Overview`         icon = `sap-icon://performance`        class = `ZCL_SAPGUI_SM50` )
      ( tcode = `SM66`  text = `Global Work Process Overview`  icon = `sap-icon://performance`        class = `ZCL_SAPGUI_SM50` )
      ( tcode = `SM12`  text = `Display and Delete Locks`      icon = `sap-icon://locked`             class = `ZCL_SAPGUI_SM12` )
      ( tcode = `SM04`  text = `User List`                     icon = `sap-icon://group`              class = `ZCL_SAPGUI_SM04` )
      ( tcode = `SP01`  text = `Output Controller`             icon = `sap-icon://print`              class = `ZCL_SAPGUI_SP01` )
      ( tcode = `WE02`  text = `Display IDoc`                  icon = `sap-icon://inbox`              class = `ZCL_SAPGUI_WE02` )
      ( tcode = `WE05`  text = `IDoc Lists`                    icon = `sap-icon://inbox`              class = `ZCL_SAPGUI_WE02` )
      ( tcode = `SLG1`  text = `Analyze Application Log`       icon = `sap-icon://activity-items`     class = `ZCL_SAPGUI_SLG1` )
      ( tcode = `ST22`  text = `ABAP Dump Analysis`            icon = `sap-icon://alert`              class = `ZCL_SAPGUI_ST22` )
      ( tcode = `ST02`  text = `Setups/Tune Buffers`           icon = `sap-icon://database`           class = `ZCL_SAPGUI_ST02` )
      ( tcode = `ST05`  text = `Performance Trace`             icon = `sap-icon://measuring-point`    class = `ZCL_SAPGUI_ST05` )
      " ----- Tools - Administration - User & Client -----
      ( tcode = `SU01`  text = `User Maintenance`              icon = `sap-icon://person-placeholder` class = `ZCL_SAPGUI_SU01` )
      ( tcode = `SU53`  text = `Evaluation of Authorization Check` icon = `sap-icon://key-user-settings` class = `ZCL_SAPGUI_SU53` )
      ( tcode = `PFCG`  text = `Role Maintenance`              icon = `sap-icon://role`               class = `ZCL_SAPGUI_PFCG` )
      ( tcode = `SCC4`  text = `Client Administration`         icon = `sap-icon://official-service`   class = `ZCL_SAPGUI_SCC4` )
      ( tcode = `RZ10`  text = `Edit Profiles`                 icon = `sap-icon://action-settings`    class = `ZCL_SAPGUI_RZ11` )
      ( tcode = `RZ11`  text = `Profile Parameter Maintenance` icon = `sap-icon://action-settings`    class = `ZCL_SAPGUI_RZ11` )
      ( tcode = `SM59`  text = `Configuration of RFC Connections` icon = `sap-icon://connected`       class = `ZCL_SAPGUI_SM59` )
      " ----- Tools - Transport -----
      ( tcode = `STMS`  text = `Transport Management System`   icon = `sap-icon://shipping-status`    class = `ZCL_SAPGUI_STMS` )
      ( tcode = `SE09`  text = `Transport Organizer`           icon = `sap-icon://request`            class = `ZCL_SAPGUI_SE09` )
      ( tcode = `SE10`  text = `Transport Organizer`           icon = `sap-icon://request`            class = `ZCL_SAPGUI_SE09` )
      ( tcode = `SE93`  text = `Maintain Transaction`           icon = `sap-icon://action-settings`     class = `ZCL_SAPGUI_SE93` )
      " ----- Listed in the menu, not implemented here -----
      ( tcode = `SE01`  text = `Transport Organizer (Extended)` icon = `sap-icon://request`           class = `ZCL_SAPGUI_SE09` )
      ( tcode = `SE03`  text = `Transport Organizer Tools`     icon = `sap-icon://wrench`             class = `ZCL_SAPGUI_SE03` )
      ( tcode = `SM30`  text = `Call View Maintenance`         icon = `sap-icon://table-view`         class = `ZCL_SAPGUI_SM30` ) ).

    " The texts above are the English fallback. The SAP GUI shows the text of
    " the transaction in the logon language (TSTCT) - so does this list.
    LOOP AT result ASSIGNING FIELD-SYMBOL(<app>).
      DATA(lv_text) = zcl_sapgui_sys_api=>get_transaction_text( <app>-tcode ).
      IF lv_text IS NOT INITIAL.
        <app>-text = lv_text.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_favorites.

    " Every transaction this environment can really start, in the order of
    " the list above - the entry screen shows them all under Favorites so
    " that none of them is buried somewhere deep in the SAP menu tree.
    " Transactions that are only listed stay out: a favorite that answers
    " with "not available" would be a dead entry.
    DATA(lt_apps) = get_apps( ).

    " Like the user menu of the SAP GUI, only what the user may start is
    " offered - a favorite that answers "not authorized" is a dead entry too.
    LOOP AT lt_apps INTO DATA(ls_app) WHERE class IS NOT INITIAL.
      IF zcl_sapgui_auth=>check_transaction( ls_app-tcode )-allowed = abap_false.
        CONTINUE.
      ENDIF.
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
      WHEN `/N`    THEN `Command /n ends the current transaction - enter it in the command field.`
      WHEN `/O`    THEN `Command /o opens a new session - enter it in the command field.`
      WHEN `/I`    THEN `Command /i - close the browser tab to end this session.`
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
    result = check_start( lv_tcode ).
    IF result-outcome = c_msg.
      RETURN.
    ENDIF.
    DATA(lv_class) = result-class.
    CLEAR result-class.

    TRY.
        DATA lo_app TYPE REF TO z2ui5_if_app.
        CREATE OBJECT lo_app TYPE (lv_class).
        IF it_params IS NOT INITIAL AND lo_app IS INSTANCE OF zif_sapgui_start_params.
          CAST zif_sapgui_start_params( lo_app )->set_start_params( it_params ).
        ENDIF.
        IF iv_replace = abap_true.
          " /n: the running transaction is ended, the new one takes its
          " place on the stack - Back from it goes where the old one went
          io_client->nav_app_leave( lo_app ).
        ELSE.
          io_client->nav_app_call( lo_app ).
        ENDIF.
        result-outcome = c_nav.
      CATCH cx_root INTO DATA(lx).
        DATA(lv_error) = lx->get_text( ).
        MESSAGE e023(zsapgui) WITH lv_tcode lv_error INTO result-message.
        result-msg_type = `Error`.
        result-outcome  = c_msg.
    ENDTRY.

  ENDMETHOD.


  METHOD check_start.

    result-outcome = c_none.
    DATA(lv_tcode) = to_upper( condense( iv_tcode ) ).

    IF lv_tcode IS INITIAL.
      MESSAGE w022(zsapgui) INTO result-message.
      result-msg_type = `Warning`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    DATA(lt_apps) = get_apps( ).
    READ TABLE lt_apps WITH KEY tcode = lv_tcode INTO DATA(ls_app).
    IF sy-subrc <> 0.
      " tell "unknown transaction" apart from "exists but not built here"
      IF zcl_sapgui_sys_api=>transaction_exists( lv_tcode ) = abap_true.
        MESSAGE w020(zsapgui) WITH lv_tcode INTO result-message.
        result-msg_type = `Warning`.
      ELSE.
        MESSAGE e021(zsapgui) WITH lv_tcode INTO result-message.
        result-msg_type = `Error`.
      ENDIF.
      result-outcome = c_msg.
      RETURN.
    ENDIF.

    IF ls_app-class IS INITIAL.
      MESSAGE w020(zsapgui) WITH lv_tcode INTO result-message.
      result-msg_type = `Warning`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    " S_TCODE + basic object authorization, exactly as the SAP GUI asks
    " before it starts the transaction. The app checks again on its own -
    " this check only gives the user the message in the status bar of the
    " screen he typed the code in.
    DATA(ls_auth) = zcl_sapgui_auth=>check_transaction( lv_tcode ).
    IF ls_auth-allowed = abap_false.
      result-message  = ls_auth-message.
      result-msg_type = `Error`.
      result-outcome  = c_msg.
      RETURN.
    ENDIF.

    result-class = ls_app-class.

  ENDMETHOD.


  METHOD parse_command.

    " blanks never belong to a command: "/n se80" is /nSE80
    DATA(lv_cmd) = to_upper( condense( iv_command ) ).
    REPLACE ALL OCCURRENCES OF ` ` IN lv_cmd WITH ``.

    IF lv_cmd IS INITIAL.
      result-kind = c_cmd_none.
      RETURN.
    ENDIF.

    CASE lv_cmd.
      WHEN `/N`.
        result-kind = c_cmd_end.
      WHEN `/NEND`.
        result-kind = c_cmd_logoff.
      WHEN `/NEX`.
        result-kind = c_cmd_logoff_now.
      WHEN `/O`.
        result-kind = c_cmd_session.
      WHEN OTHERS.
        IF lv_cmd CP `/O*`.
          result = VALUE #( kind = c_cmd_session tcode = substring( val = lv_cmd off = 2 ) ).
        ELSEIF lv_cmd CP `/N*` OR lv_cmd CP `/#**`.
          " /*SE38 starts SE38 and skips its initial screen in the SAP GUI -
          " here it starts the transaction like /n
          result = VALUE #( kind = c_cmd_new tcode = substring( val = lv_cmd off = 2 ) ).
        ELSEIF lv_cmd CP `/*`.
          IF session_command_text( lv_cmd ) IS NOT INITIAL.
            result = VALUE #( kind = c_cmd_info tcode = lv_cmd ).
          ELSE.
            result = VALUE #( kind = c_cmd_new tcode = substring( val = lv_cmd off = 1 ) ).
          ENDIF.
        ELSE.
          result = VALUE #( kind = c_cmd_tcode tcode = lv_cmd ).
        ENDIF.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
