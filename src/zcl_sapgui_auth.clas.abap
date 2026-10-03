CLASS zcl_sapgui_auth DEFINITION PUBLIC FINAL CREATE PUBLIC
  GLOBAL FRIENDS zcl_sapgui_auth_sys_dbl.

* ---------------------------------------------------------------------
*  Authorization checks of the SAP GUI look-alike apps of $ZLK_05.
*
*  The apps show the same data as the original transactions, so they
*  must ask for the same authorizations. Two layers:
*
*    1  App level   - S_TCODE for the transaction behind the app plus a
*                     basic object authorization (S_DEVELOP display for
*                     the workbench tools, S_ADMI_FCD for SM21, ...).
*                     guard_app( ) runs this check at the start of EVERY
*                     roundtrip of every app. That also covers an app that
*                     is started directly by URL (app_start=...) and never
*                     passed through the command field router.
*    2  Object level - checks that need the concrete object: the table in
*                     SE16N (S_TABU_NAM / S_TABU_DIS), the package and
*                     object in SE80 (S_DEVELOP).
*
*  The AUTHORITY-CHECK statements themselves, and what a check reads
*  from the repository, sit behind ZIF_SAPGUI_AUTH_SYS - see sys( ). On
*  a system that is ZCL_SAPGUI_AUTH_SYS; in the unit tests it is
*  ZCL_SAPGUI_AUTH_SYS_DBL, which a test tells which checks to fail.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_check,
        allowed TYPE abap_bool,
        message TYPE string,
      END OF ty_s_check.

    "! Activity of an authorization field (ACTIV_AUTH)
    TYPES ty_actvt TYPE c LENGTH 2.

    CONSTANTS c_actvt_create  TYPE ty_actvt VALUE '01'.
    CONSTANTS c_actvt_change  TYPE ty_actvt VALUE '02'.
    CONSTANTS c_actvt_display TYPE ty_actvt VALUE '03'.
    CONSTANTS c_actvt_delete  TYPE ty_actvt VALUE '06'.
    CONSTANTS c_actvt_activate TYPE ty_actvt VALUE '07'.

    "! The entry screen (SAP Easy Access). It has no transaction code of
    "! its own and only shows the menu - every transaction started from it
    "! is checked by the router and by the app itself.
    CONSTANTS c_entry_class TYPE string VALUE `ZCL_SAPGUI_START`.

    "! S_TCODE for one transaction code
    CLASS-METHODS check_tcode
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! Basic object authorization the original transaction asks for
    "! right after S_TCODE. Transactions without one are allowed.
    CLASS-METHODS check_tcode_base
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_TCODE + basic check for a transaction - what the router asks
    CLASS-METHODS check_transaction
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! May the user run the app class? Allowed when the user may run at
    "! least one of the transactions the router maps to the class.
    "! Classes the router does not know are refused.
    CLASS-METHODS check_app
      IMPORTING iv_class      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! Display authorization for the content of a table / view, the same
    "! way VIEW_AUTHORITY_CHECK does it: S_TABU_DIS for the authorization
    "! group of the table (TDDAT, &NC& when none), then S_TABU_NAM.
    CLASS-METHODS check_table_display
      IMPORTING iv_table      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_DEVELOP. Without an object name the check is generic (only the
    "! activity is checked) - this is the "may use the workbench at all"
    "! check of SE80 / SE38 / SE11 / ...
    CLASS-METHODS check_develop
      IMPORTING iv_actvt      TYPE ty_actvt
                iv_package    TYPE string OPTIONAL
                iv_objtype    TYPE string OPTIONAL
                iv_objname    TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_USER_GRP display for one user group (USR02-CLASS) - SU01 shows
    "! a user only when this check passes for the group of the user
    CLASS-METHODS check_user_group
      IMPORTING iv_group      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_APPL_LOG display for one log object / subobject - SLG1 shows a
    "! log only when this check passes (TSTCA of SLG1: S_APPL_LOG ACTVT 03)
    CLASS-METHODS check_appl_log
      IMPORTING iv_object     TYPE string
                iv_subobject  TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_RFC_ADM display for one RFC destination (TSTCA of SM59: S_RFC_ADM)
    CLASS-METHODS check_rfc_dest
      IMPORTING iv_rfctype    TYPE string
                iv_rfcdest    TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_DEVELOP display for the repository object a program belongs to:
    "! the program itself, the class of a class pool (...CP / ...CU / ...),
    "! or the function group of SAPL... and its includes.
    CLASS-METHODS check_program_display
      IMPORTING iv_program    TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! Job log of a job of iv_owner: own jobs always, other users' jobs
    "! with S_BTCH_JOB JOBACTION PROT or S_BTCH_ADM BTCADMIN Y (as SM37)
    CLASS-METHODS check_job_log
      IMPORTING iv_owner      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! May the user display iv_bname in SU01? S_USER_GRP display for the
    "! group of that user.
    CLASS-METHODS check_user_display
      IMPORTING iv_bname      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_USER_AGR display for one role - PFCG shows a role only when this
    "! check passes (TSTCA of PFCG: S_USER_AGR)
    CLASS-METHODS check_role
      IMPORTING iv_role       TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! May the user see one IDoc in WE02? Exactly the check of RSEIDOC2:
    "! S_IDOCMONI display for WE02 with direction, message type and the
    "! partner (receiver for outbound, sender for inbound), followed by
    "! the customer BAdI IDOC_AUTHORITY_RESTRICTION.
    CLASS-METHODS check_idoc
      IMPORTING is_edidc      TYPE edidc
      RETURNING VALUE(result) TYPE ty_s_check.

    "! May the user access a spool request? RSPO_CHECK_JOB_PERMISSION -
    "! the standard check of SP01 including its customer exit:
    "! iv_access BASE = see it in the list, DISP = display the content.
    CLASS-METHODS check_spool
      IMPORTING is_tsp01      TYPE tsp01
                iv_access     TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! S_DEVELOP display for a message class (object type MSAG) in its
    "! package - SE91 shows a message class only when this check passes
    CLASS-METHODS check_message_class
      IMPORTING iv_arbgb      TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

    "! Transaction codes the router maps to an app class
    CLASS-METHODS get_tcodes_of_class
      IMPORTING iv_class      TYPE string
      RETURNING VALUE(result) TYPE string_table.

    "! Call as the FIRST statement of z2ui5_if_app~main:
    "!   IF zcl_sapgui_auth=>guard_app( io_client = client io_app = me ) = abap_false.
    "!     RETURN.
    "!   ENDIF.
    "! Returns abap_true when the user may run the app. Otherwise the
    "! "no authorization" screen has been rendered (or Back was handled)
    "! and the app must not do anything else in this roundtrip.
    CLASS-METHODS guard_app
      IMPORTING io_client     TYPE REF TO z2ui5_if_client
                io_app        TYPE REF TO object
      RETURNING VALUE(result) TYPE abap_bool.

    "! Class name of an object reference without the \CLASS= prefix
    CLASS-METHODS class_name_of
      IMPORTING io_object     TYPE REF TO object
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.

    "! The implementation on a real system. Created by name, so that the
    "! checks - and every app - do not depend on it: the unit tests run
    "! transpiled without it (README, Development).
    CONSTANTS c_sys_class TYPE string VALUE `ZCL_SAPGUI_AUTH_SYS`.

    "! Set by ZCL_SAPGUI_AUTH_SYS_DBL in a unit test, else created by sys( )
    CLASS-DATA go_sys TYPE REF TO zif_sapgui_auth_sys.

    "! The AUTHORITY-CHECK statements and repository reads of the checks
    CLASS-METHODS sys
      RETURNING VALUE(result) TYPE REF TO zif_sapgui_auth_sys.

    CLASS-METHODS render_denied
      IMPORTING io_client  TYPE REF TO z2ui5_if_client
                iv_message TYPE string.

    CLASS-METHODS allowed
      RETURNING VALUE(result) TYPE ty_s_check.

    CLASS-METHODS denied
      IMPORTING iv_message    TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

ENDCLASS.



CLASS zcl_sapgui_auth IMPLEMENTATION.


  METHOD sys.

    IF go_sys IS NOT BOUND.
      CREATE OBJECT go_sys TYPE (c_sys_class).
    ENDIF.
    result = go_sys.

  ENDMETHOD.


  METHOD allowed.
    result-allowed = abap_true.
  ENDMETHOD.


  METHOD denied.
    result-allowed = abap_false.
    result-message = iv_message.
  ENDMETHOD.


  METHOD check_tcode.

    DATA lv_tcode TYPE string.
    DATA lv_subrc TYPE sy-subrc.

    lv_tcode = to_upper( condense( iv_tcode ) ).
    IF lv_tcode IS INITIAL.
      MESSAGE e011(zsapgui) INTO DATA(lv_msg_empty).
      result = denied( lv_msg_empty ).
      RETURN.
    ENDIF.

    lv_subrc = sys( )->s_tcode( lv_tcode ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e001(zsapgui) WITH lv_tcode INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_tcode_base.

    DATA lv_subrc TYPE sy-subrc.
    DATA(lv_tcode) = to_upper( condense( iv_tcode ) ).

    result = allowed( ).

    CASE lv_tcode.

      WHEN `SE80` OR `SE38` OR `SE11` OR `SE24` OR `SE37` OR `SE93` OR `SE91`.
        " the workbench tools ask for S_DEVELOP display before anything else
        result = check_develop( c_actvt_display ).

      WHEN `SM21`.
        lv_subrc = sys( )->s_admi_fcd( `SM21` ).
        IF lv_subrc <> 0.
          MESSAGE e002(zsapgui) INTO DATA(lv_msg_sm21).
          result = denied( lv_msg_sm21 ).
        ENDIF.

      WHEN `RZ10` OR `RZ11` OR `SM04`.
        " SM04: TH_USER_LIST itself asks for S_RZL_ADM 03 from outside
        lv_subrc = sys( )->s_rzl_adm( ).
        IF lv_subrc <> 0.
          MESSAGE e003(zsapgui) INTO DATA(lv_msg_rzl).
          result = denied( lv_msg_rzl ).
        ENDIF.

      WHEN `SU01`.
        lv_subrc = sys( )->s_user_grp_any( ).
        IF lv_subrc <> 0.
          MESSAGE e004(zsapgui) INTO DATA(lv_msg_usr).
          result = denied( lv_msg_usr ).
        ENDIF.

      WHEN `STMS` OR `SE09` OR `SE10`.
        lv_subrc = sys( )->s_transprt_any( ).
        IF lv_subrc <> 0.
          MESSAGE e005(zsapgui) INTO DATA(lv_msg_tr).
          result = denied( lv_msg_tr ).
        ENDIF.

      WHEN `SLG1`.
        lv_subrc = sys( )->s_appl_log_any( ).
        IF lv_subrc <> 0.
          MESSAGE e015(zsapgui) INTO DATA(lv_msg_slg1).
          result = denied( lv_msg_slg1 ).
        ENDIF.

      WHEN `SM59`.
        lv_subrc = sys( )->s_rfc_adm_any( ).
        IF lv_subrc <> 0.
          MESSAGE e016(zsapgui) INTO DATA(lv_msg_sm59).
          result = denied( lv_msg_sm59 ).
        ENDIF.

      WHEN `PFCG`.
        " TSTCA of PFCG: S_USER_AGR - here for display
        lv_subrc = sys( )->s_user_agr_any( ).
        IF lv_subrc <> 0.
          MESSAGE e024(zsapgui) INTO DATA(lv_msg_pfcg).
          result = denied( lv_msg_pfcg ).
        ENDIF.

      WHEN `WE02` OR `WE05`.
        " RSEIDOC2, form AUTHORITY_CHECK_RSEIDOC2_DISP: WE02, or the older
        " WE05 authorization
        lv_subrc = sys( )->s_idocmoni_any( ).
        IF lv_subrc <> 0.
          MESSAGE e025(zsapgui) INTO DATA(lv_msg_idoc).
          result = denied( lv_msg_idoc ).
        ENDIF.

      WHEN OTHERS.
        " S_TCODE only - the object level checks follow inside the app

    ENDCASE.

  ENDMETHOD.


  METHOD check_transaction.

    result = check_tcode( iv_tcode ).
    IF result-allowed = abap_true.
      result = check_tcode_base( iv_tcode ).
    ENDIF.

  ENDMETHOD.


  METHOD get_tcodes_of_class.

    DATA(lv_class) = to_upper( condense( iv_class ) ).

    LOOP AT zcl_sapgui_router=>get_apps( ) INTO DATA(ls_app)
         WHERE class = lv_class.
      APPEND ls_app-tcode TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD check_app.

    DATA(lv_class) = to_upper( condense( iv_class ) ).

    IF lv_class = c_entry_class.
      result = allowed( ).
      RETURN.
    ENDIF.

    DATA(lt_tcodes) = get_tcodes_of_class( lv_class ).
    IF lt_tcodes IS INITIAL.
      MESSAGE e006(zsapgui) WITH lv_class INTO DATA(lv_msg).
      result = denied( lv_msg ).
      RETURN.
    ENDIF.

    LOOP AT lt_tcodes INTO DATA(lv_tcode).
      DATA(ls_check) = check_transaction( lv_tcode ).
      IF ls_check-allowed = abap_true.
        result = ls_check.
        RETURN.
      ENDIF.
      IF result-message IS INITIAL.
        result = ls_check.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD check_table_display.

    DATA lv_table  TYPE string.
    DATA lv_cclass TYPE string.
    DATA lv_subrc  TYPE sy-subrc.

    lv_table = to_upper( condense( iv_table ) ).
    IF lv_table IS INITIAL.
      MESSAGE e012(zsapgui) INTO DATA(lv_msg_empty).
      result = denied( lv_msg_empty ).
      RETURN.
    ENDIF.

    " 1 - authorization group of the table, &NC& when it has none
    lv_cclass = sys( )->table_auth_group( lv_table ).
    IF lv_cclass IS INITIAL.
      lv_cclass = '&NC&'.
    ENDIF.

    lv_subrc = sys( )->s_tabu_dis( lv_cclass ).

    IF lv_subrc = 0.
      result = allowed( ).
      RETURN.
    ENDIF.

    " 2 - table by name
    lv_subrc = sys( )->s_tabu_nam( lv_table ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e007(zsapgui) WITH lv_table lv_cclass INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_develop.

    DATA lv_subrc   TYPE sy-subrc.
    DATA lv_package TYPE string.
    DATA lv_objtype TYPE string.
    DATA lv_objname TYPE string.

    IF iv_objname IS INITIAL.

      lv_subrc = sys( )->s_develop_any( CONV #( iv_actvt ) ).

    ELSE.

      lv_package = to_upper( iv_package ).
      lv_objtype = to_upper( iv_objtype ).
      lv_objname = to_upper( iv_objname ).

      lv_subrc = sys( )->s_develop( iv_actvt   = CONV #( iv_actvt )
                                    iv_package = lv_package
                                    iv_objtype = lv_objtype
                                    iv_objname = lv_objname ).

    ENDIF.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSEIF iv_objname IS INITIAL.
      MESSAGE e008(zsapgui) WITH iv_actvt INTO DATA(lv_msg_gen).
      result = denied( lv_msg_gen ).
    ELSE.
      MESSAGE e009(zsapgui) WITH iv_objtype iv_objname iv_actvt INTO DATA(lv_msg_obj).
      result = denied( lv_msg_obj ).
    ENDIF.

  ENDMETHOD.


  METHOD check_user_group.

    DATA lv_group TYPE string.
    DATA lv_subrc TYPE sy-subrc.

    lv_group = to_upper( condense( iv_group ) ).

    lv_subrc = sys( )->s_user_grp( lv_group ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e010(zsapgui) WITH lv_group INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_appl_log.

    DATA lv_object TYPE string.
    DATA lv_subobj TYPE string.
    DATA lv_subrc  TYPE sy-subrc.

    lv_object = to_upper( condense( iv_object ) ).
    lv_subobj = to_upper( condense( iv_subobject ) ).

    lv_subrc = sys( )->s_appl_log( iv_object    = lv_object
                                   iv_subobject = lv_subobj ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e017(zsapgui) WITH lv_object lv_subobj INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_rfc_dest.

    DATA lv_type  TYPE string.
    DATA lv_dest  TYPE string.
    DATA lv_subrc TYPE sy-subrc.

    lv_type = to_upper( condense( iv_rfctype ) ).
    lv_dest = to_upper( condense( iv_rfcdest ) ).

    lv_subrc = sys( )->s_rfc_adm( iv_rfctype = lv_type
                                  iv_rfcdest = lv_dest ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e018(zsapgui) WITH lv_dest INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_program_display.

    DATA(lv_prog) = to_upper( condense( iv_program ) ).
    DATA lv_objtype TYPE string.
    DATA lv_objname TYPE string.

    IF lv_prog IS INITIAL.
      result = denied( `` ).
      RETURN.
    ENDIF.

    IF lv_prog CA '='.
      " class pool and its includes: ZCL_X=========================CP, ZCL_X======CM001 ...
      lv_objtype = 'CLAS'.
      lv_objname = segment( val = lv_prog index = 1 sep = `=` ).
    ELSEIF lv_prog CP 'SAPL*'.
      lv_objtype = 'FUGR'.
      lv_objname = substring( val = lv_prog off = 4 ).
    ELSE.
      lv_objtype = 'PROG'.
      lv_objname = lv_prog.
      " not a program of its own: an include of a function group,
      " L<group><3 characters> - LZFGTOP, LZFGU01, LZFGF01 ...
      IF sys( )->object_exists( iv_object = `PROG` iv_obj_name = lv_objname ) = abap_false AND lv_prog CP 'L*' AND strlen( lv_prog ) > 4.
        DATA(lv_group) = substring( val = lv_prog off = 1 len = strlen( lv_prog ) - 4 ).
        IF sys( )->object_exists( iv_object = `FUGR` iv_obj_name = lv_group ) = abap_true.
          lv_objtype = 'FUGR'.
          lv_objname = lv_group.
        ENDIF.
      ENDIF.
    ENDIF.

    result = check_develop( iv_actvt   = c_actvt_display
                            iv_package = sys( )->object_package( iv_object   = lv_objtype
                                                                 iv_obj_name = lv_objname )
                                                                 iv_objtype = lv_objtype
                                                                 iv_objname = lv_objname ).

  ENDMETHOD.


  METHOD check_job_log.

    DATA lv_subrc TYPE sy-subrc.

    IF to_upper( condense( iv_owner ) ) = sy-uname.
      result = allowed( ).
      RETURN.
    ENDIF.

    lv_subrc = sys( )->s_btch_job_prot( ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      DATA(lv_owner) = to_upper( condense( iv_owner ) ).
      MESSAGE e019(zsapgui) WITH lv_owner INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_user_display.

    result = check_user_group( sys( )->user_group( to_upper( condense( iv_bname ) ) ) ).

  ENDMETHOD.


  METHOD class_name_of.

    IF io_object IS NOT BOUND.
      RETURN.
    ENDIF.

    result = cl_abap_classdescr=>get_class_name( io_object ).
    " \CLASS=ZCL_X -> ZCL_X
    result = segment( val = result index = -1 sep = `=` ).

  ENDMETHOD.


  METHOD guard_app.

    result = abap_false.
    IF io_client IS NOT BOUND.
      RETURN.
    ENDIF.

    DATA(ls_check) = check_app( class_name_of( io_app ) ).
    IF ls_check-allowed = abap_true.
      result = abap_true.
      RETURN.
    ENDIF.

    " The only thing a user without authorization may do is leave
    IF io_client->check_on_init( ) = abap_false
       AND io_client->get_event( ) = zcl_sapgui_frame=>c_ev_back.
      io_client->nav_app_leave( ).
      RETURN.
    ENDIF.

    render_denied( io_client  = io_client
                   iv_message = ls_check-message ).

  ENDMETHOD.


  METHOD render_denied.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_sapgui_frame=>open_window( view ).

    zcl_sapgui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = iv_message
                                          iv_msg_type = `Error` ).

    zcl_sapgui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar(
        io_parent     = page
        iv_back_event = io_client->_event( zcl_sapgui_frame=>c_ev_back ) ).

    zcl_sapgui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `No Authorization` ).

    page->tag( `MessageStrip`
        )->a( n = `text`  t = iv_message
        )->a( n = `type`  v = `Error`
        )->a( n = `showIcon` b = abap_true
        )->a( n = `class` v = `sapUiSmallMargin` ).

    zcl_sapgui_frame=>register_keys(
        io_client    = io_client
        iv_back_name = zcl_sapgui_frame=>c_ev_back ).

    io_client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD check_role.

    DATA lv_role  TYPE string.
    DATA lv_subrc TYPE sy-subrc.

    lv_role = to_upper( condense( iv_role ) ).

    lv_subrc = sys( )->s_user_agr( lv_role ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e026(zsapgui) WITH lv_role INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_idoc.

    DATA lv_subrc TYPE sy-subrc.
    DATA lv_prn   TYPE string.
    DATA lv_prt   TYPE string.

    " outbound: the receiver is checked, inbound: the sender
    IF is_edidc-direct = '1'.
      lv_prn = is_edidc-rcvprn.
      lv_prt = is_edidc-rcvprt.
    ELSE.
      lv_prn = is_edidc-sndprn.
      lv_prt = is_edidc-sndprt.
    ENDIF.

    lv_subrc = sys( )->s_idocmoni( is_edidc        = is_edidc
                                   iv_partner_num  = lv_prn
                                   iv_partner_type = lv_prt ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e027(zsapgui) WITH |{ shift_left( val = CONV string( is_edidc-docnum ) sub = `0` ) }| is_edidc-mestyp
        INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_spool.

    DATA lv_subrc  TYPE sy-subrc.
    DATA lv_access TYPE string.

    lv_access = to_upper( iv_access ).

    lv_subrc = sys( )->spool_permission( is_tsp01  = is_tsp01
                                         iv_access = lv_access ).

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e028(zsapgui) WITH condense( CONV string( is_tsp01-rqident ) ) INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_message_class.

    DATA(lv_arbgb) = to_upper( condense( iv_arbgb ) ).

    result = check_develop( iv_actvt   = c_actvt_display
                            iv_package = sys( )->object_package( iv_object   = `MSAG`
                                                                 iv_obj_name = lv_arbgb )
                                                                 iv_objtype = `MSAG`
                                                                 iv_objname = lv_arbgb ).

  ENDMETHOD.

ENDCLASS.
