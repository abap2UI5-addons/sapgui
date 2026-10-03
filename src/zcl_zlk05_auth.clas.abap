CLASS zcl_zlk05_auth DEFINITION PUBLIC FINAL CREATE PUBLIC.

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
*  Every AUTHORITY-CHECK sits inside a TEST-SEAM so that unit tests can
*  simulate a user without the authorization.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_s_check,
        allowed TYPE abap_bool,
        message TYPE string,
      END OF ty_s_check.

    CONSTANTS c_actvt_create  TYPE activ_auth VALUE '01'.
    CONSTANTS c_actvt_change  TYPE activ_auth VALUE '02'.
    CONSTANTS c_actvt_display TYPE activ_auth VALUE '03'.
    CONSTANTS c_actvt_delete  TYPE activ_auth VALUE '06'.
    CONSTANTS c_actvt_activate TYPE activ_auth VALUE '07'.

    "! The entry screen (SAP Easy Access). It has no transaction code of
    "! its own and only shows the menu - every transaction started from it
    "! is checked by the router and by the app itself.
    CONSTANTS c_entry_class TYPE string VALUE `ZCL_SAPGUI_A2UI5`.

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
      IMPORTING iv_actvt      TYPE activ_auth
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
    "!   IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
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

    CLASS-METHODS render_denied
      IMPORTING io_client  TYPE REF TO z2ui5_if_client
                iv_message TYPE string.

    CLASS-METHODS allowed
      RETURNING VALUE(result) TYPE ty_s_check.

    CLASS-METHODS denied
      IMPORTING iv_message    TYPE string
      RETURNING VALUE(result) TYPE ty_s_check.

ENDCLASS.



CLASS zcl_zlk05_auth IMPLEMENTATION.


  METHOD allowed.
    result-allowed = abap_true.
  ENDMETHOD.


  METHOD denied.
    result-allowed = abap_false.
    result-message = iv_message.
  ENDMETHOD.


  METHOD check_tcode.

    DATA lv_tcode TYPE tcode.
    DATA lv_subrc TYPE sy-subrc.

    lv_tcode = to_upper( condense( iv_tcode ) ).
    IF lv_tcode IS INITIAL.
      MESSAGE e011(zlk05) INTO DATA(lv_msg_empty).
      result = denied( lv_msg_empty ).
      RETURN.
    ENDIF.

    TEST-SEAM auth_tcode.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD lv_tcode.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e001(zlk05) WITH lv_tcode INTO DATA(lv_msg).
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
        result = check_develop( iv_actvt = c_actvt_display ).

      WHEN `SM21`.
        TEST-SEAM auth_base_sm21.
          AUTHORITY-CHECK OBJECT 'S_ADMI_FCD' ID 'S_ADMI_FCD' FIELD 'SM21'.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e002(zlk05) INTO DATA(lv_msg_sm21).
          result = denied( lv_msg_sm21 ).
        ENDIF.

      WHEN `RZ10` OR `RZ11` OR `SM04`.
        " SM04: TH_USER_LIST itself asks for S_RZL_ADM 03 from outside
        TEST-SEAM auth_base_rzl.
          AUTHORITY-CHECK OBJECT 'S_RZL_ADM' ID 'ACTVT' FIELD c_actvt_display.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e003(zlk05) INTO DATA(lv_msg_rzl).
          result = denied( lv_msg_rzl ).
        ENDIF.

      WHEN `SU01`.
        TEST-SEAM auth_base_user.
          AUTHORITY-CHECK OBJECT 'S_USER_GRP'
            ID 'CLASS' DUMMY
            ID 'ACTVT' FIELD c_actvt_display.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e004(zlk05) INTO DATA(lv_msg_usr).
          result = denied( lv_msg_usr ).
        ENDIF.

      WHEN `STMS` OR `SE09` OR `SE10`.
        TEST-SEAM auth_base_transport.
          AUTHORITY-CHECK OBJECT 'S_TRANSPRT'
            ID 'TTYPE' DUMMY
            ID 'ACTVT' FIELD c_actvt_display.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e005(zlk05) INTO DATA(lv_msg_tr).
          result = denied( lv_msg_tr ).
        ENDIF.

      WHEN `SLG1`.
        TEST-SEAM auth_base_slg1.
          AUTHORITY-CHECK OBJECT 'S_APPL_LOG'
            ID 'ALG_OBJECT' DUMMY
            ID 'ALG_SUBOBJ' DUMMY
            ID 'ACTVT'      FIELD c_actvt_display.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e015(zlk05) INTO DATA(lv_msg_slg1).
          result = denied( lv_msg_slg1 ).
        ENDIF.

      WHEN `SM59`.
        TEST-SEAM auth_base_sm59.
          AUTHORITY-CHECK OBJECT 'S_RFC_ADM'
            ID 'ACTVT'     FIELD c_actvt_display
            ID 'RFCTYPE'   DUMMY
            ID 'RFCDEST'   DUMMY
            ID 'ICF_VALUE' DUMMY.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e016(zlk05) INTO DATA(lv_msg_sm59).
          result = denied( lv_msg_sm59 ).
        ENDIF.

      WHEN `PFCG`.
        " TSTCA of PFCG: S_USER_AGR - here for display
        TEST-SEAM auth_base_pfcg.
          AUTHORITY-CHECK OBJECT 'S_USER_AGR'
            ID 'ACT_GROUP' DUMMY
            ID 'ACTVT'     FIELD c_actvt_display.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e024(zlk05) INTO DATA(lv_msg_pfcg).
          result = denied( lv_msg_pfcg ).
        ENDIF.

      WHEN `WE02` OR `WE05`.
        " RSEIDOC2, form AUTHORITY_CHECK_RSEIDOC2_DISP: WE02, or the older
        " WE05 authorization
        TEST-SEAM auth_base_idoc.
          AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
            ID 'EDI_TCD' FIELD 'WE02'
            ID 'ACTVT'   FIELD c_actvt_display
            ID 'EDI_DIR' DUMMY
            ID 'EDI_MES' DUMMY
            ID 'EDI_PRN' DUMMY
            ID 'EDI_PRT' DUMMY.
          IF sy-subrc <> 0.
            AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
              ID 'EDI_TCD' FIELD 'WE05'
              ID 'ACTVT'   FIELD c_actvt_display
              ID 'EDI_DIR' DUMMY
              ID 'EDI_MES' DUMMY
              ID 'EDI_PRN' DUMMY
              ID 'EDI_PRT' DUMMY.
          ENDIF.
          lv_subrc = sy-subrc.
        END-TEST-SEAM.
        IF lv_subrc <> 0.
          MESSAGE e025(zlk05) INTO DATA(lv_msg_idoc).
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

    LOOP AT zcl_zlk05_tcode_router=>get_apps( ) INTO DATA(ls_app)
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
      MESSAGE e006(zlk05) WITH lv_class INTO DATA(lv_msg).
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

    DATA lv_table  TYPE tabname.
    DATA lv_cclass TYPE tddat-cclass.
    DATA lv_subrc  TYPE sy-subrc.

    lv_table = to_upper( condense( iv_table ) ).
    IF lv_table IS INITIAL.
      MESSAGE e012(zlk05) INTO DATA(lv_msg_empty).
      result = denied( lv_msg_empty ).
      RETURN.
    ENDIF.

    " 1 - authorization group of the table, &NC& when it has none
    SELECT SINGLE cclass FROM tddat WHERE tabname = @lv_table INTO @lv_cclass.
    IF sy-subrc <> 0 OR lv_cclass IS INITIAL.
      lv_cclass = '&NC&'.
    ENDIF.

    TEST-SEAM auth_tabu_dis.
      AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
        ID 'DICBERCLS' FIELD lv_cclass
        ID 'ACTVT'     FIELD c_actvt_display.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
      RETURN.
    ENDIF.

    " 2 - table by name
    TEST-SEAM auth_tabu_nam.
      AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
        ID 'ACTVT' FIELD c_actvt_display
        ID 'TABLE' FIELD lv_table.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e007(zlk05) WITH lv_table lv_cclass INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_develop.

    DATA lv_subrc   TYPE sy-subrc.
    DATA lv_package TYPE devclass.
    DATA lv_objtype TYPE trobjtype.
    DATA lv_objname TYPE sobj_name.

    IF iv_objname IS INITIAL.

      TEST-SEAM auth_develop_generic.
        AUTHORITY-CHECK OBJECT 'S_DEVELOP'
          ID 'DEVCLASS' DUMMY
          ID 'OBJTYPE'  DUMMY
          ID 'OBJNAME'  DUMMY
          ID 'P_GROUP'  DUMMY
          ID 'ACTVT'    FIELD iv_actvt.
        lv_subrc = sy-subrc.
      END-TEST-SEAM.

    ELSE.

      lv_package = to_upper( iv_package ).
      lv_objtype = to_upper( iv_objtype ).
      lv_objname = to_upper( iv_objname ).

      TEST-SEAM auth_develop_object.
        AUTHORITY-CHECK OBJECT 'S_DEVELOP'
          ID 'DEVCLASS' FIELD lv_package
          ID 'OBJTYPE'  FIELD lv_objtype
          ID 'OBJNAME'  FIELD lv_objname
          ID 'P_GROUP'  DUMMY
          ID 'ACTVT'    FIELD iv_actvt.
        lv_subrc = sy-subrc.
      END-TEST-SEAM.

    ENDIF.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSEIF iv_objname IS INITIAL.
      MESSAGE e008(zlk05) WITH iv_actvt INTO DATA(lv_msg_gen).
      result = denied( lv_msg_gen ).
    ELSE.
      MESSAGE e009(zlk05) WITH iv_objtype iv_objname iv_actvt INTO DATA(lv_msg_obj).
      result = denied( lv_msg_obj ).
    ENDIF.

  ENDMETHOD.


  METHOD check_user_group.

    DATA lv_group TYPE xuclass.
    DATA lv_subrc TYPE sy-subrc.

    lv_group = to_upper( condense( iv_group ) ).

    TEST-SEAM auth_user_group.
      AUTHORITY-CHECK OBJECT 'S_USER_GRP'
        ID 'CLASS' FIELD lv_group
        ID 'ACTVT' FIELD c_actvt_display.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e010(zlk05) WITH lv_group INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_appl_log.

    DATA lv_object TYPE balobj_d.
    DATA lv_subobj TYPE balsubobj.
    DATA lv_subrc  TYPE sy-subrc.

    lv_object = to_upper( condense( iv_object ) ).
    lv_subobj = to_upper( condense( iv_subobject ) ).

    TEST-SEAM auth_appl_log.
      AUTHORITY-CHECK OBJECT 'S_APPL_LOG'
        ID 'ALG_OBJECT' FIELD lv_object
        ID 'ALG_SUBOBJ' FIELD lv_subobj
        ID 'ACTVT'      FIELD c_actvt_display.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e017(zlk05) WITH lv_object lv_subobj INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_rfc_dest.

    DATA lv_type  TYPE rfctype_d.
    DATA lv_dest  TYPE rfcdest.
    DATA lv_subrc TYPE sy-subrc.

    lv_type = to_upper( condense( iv_rfctype ) ).
    lv_dest = to_upper( condense( iv_rfcdest ) ).

    TEST-SEAM auth_rfc_dest.
      AUTHORITY-CHECK OBJECT 'S_RFC_ADM'
        ID 'ACTVT'     FIELD c_actvt_display
        ID 'RFCTYPE'   FIELD lv_type
        ID 'RFCDEST'   FIELD lv_dest
        ID 'ICF_VALUE' DUMMY.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e018(zlk05) WITH lv_dest INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_program_display.

    DATA(lv_prog) = to_upper( condense( iv_program ) ).
    DATA lv_objtype TYPE trobjtype.
    DATA lv_objname TYPE sobj_name.

    IF lv_prog IS INITIAL.
      result = denied( `` ).
      RETURN.
    ENDIF.

    IF lv_prog CA '='.
      " class pool and its includes: ZCL_X======CP, ZCL_X======CM001 ...
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
      SELECT SINGLE @abap_true FROM tadir
        WHERE pgmid = 'R3TR' AND object = 'PROG' AND obj_name = @lv_objname
        INTO @DATA(lv_is_prog).
      IF lv_is_prog = abap_false AND lv_prog CP 'L*' AND strlen( lv_prog ) > 4.
        DATA(lv_group) = substring( val = lv_prog off = 1 len = strlen( lv_prog ) - 4 ).
        SELECT SINGLE @abap_true FROM tadir
          WHERE pgmid = 'R3TR' AND object = 'FUGR' AND obj_name = @lv_group
          INTO @DATA(lv_is_fugr).
        IF lv_is_fugr = abap_true.
          lv_objtype = 'FUGR'.
          lv_objname = lv_group.
        ENDIF.
      ENDIF.
    ENDIF.

    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = @lv_objtype AND obj_name = @lv_objname
      INTO @DATA(lv_devclass).

    result = check_develop( iv_actvt   = c_actvt_display
                            iv_package = CONV #( lv_devclass )
                            iv_objtype = CONV #( lv_objtype )
                            iv_objname = CONV #( lv_objname ) ).

  ENDMETHOD.


  METHOD check_job_log.

    DATA lv_subrc TYPE sy-subrc.

    IF to_upper( condense( iv_owner ) ) = sy-uname.
      result = allowed( ).
      RETURN.
    ENDIF.

    TEST-SEAM auth_job_prot.
      AUTHORITY-CHECK OBJECT 'S_BTCH_JOB'
        ID 'JOBGROUP'  DUMMY
        ID 'JOBACTION' FIELD 'PROT'.
      lv_subrc = sy-subrc.
      IF lv_subrc <> 0.
        AUTHORITY-CHECK OBJECT 'S_BTCH_ADM' ID 'BTCADMIN' FIELD 'Y'.
        lv_subrc = sy-subrc.
      ENDIF.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      DATA(lv_owner) = to_upper( condense( iv_owner ) ).
      MESSAGE e019(zlk05) WITH lv_owner INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_user_display.

    DATA(lv_user) = CONV xubname( to_upper( condense( iv_bname ) ) ).
    SELECT SINGLE class FROM usr02 WHERE bname = @lv_user INTO @DATA(lv_group).
    result = check_user_group( CONV string( lv_group ) ).

  ENDMETHOD.


  METHOD class_name_of.

    IF io_object IS NOT BOUND.
      RETURN.
    ENDIF.

    result = cl_abap_classdescr=>get_class_name( io_object ).
    " \CLASS=ZCL_X -> ZCL_X
    FIND PCRE `=([^=]+)$` IN result SUBMATCHES DATA(lv_name).
    IF sy-subrc = 0.
      result = lv_name.
    ENDIF.

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
       AND io_client->get_event( ) = zcl_zlk05_gui_frame=>c_ev_back.
      io_client->nav_app_leave( ).
      RETURN.
    ENDIF.

    render_denied( io_client  = io_client
                   iv_message = ls_check-message ).

  ENDMETHOD.


  METHOD render_denied.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = iv_message
                                          iv_msg_type = `Error` ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_back_event = io_client->_event( zcl_zlk05_gui_frame=>c_ev_back ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `No Authorization` ).

    page->tag( `MessageStrip`
        )->a( n = `text`  t = iv_message
        )->a( n = `type`  v = `Error`
        )->a( n = `showIcon` b = abap_true
        )->a( n = `class` v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = io_client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    io_client->view_display( view->stringify( ) ).

  ENDMETHOD.

  METHOD check_role.

    DATA lv_role  TYPE agr_name.
    DATA lv_subrc TYPE sy-subrc.

    lv_role = to_upper( condense( iv_role ) ).

    TEST-SEAM auth_role.
      AUTHORITY-CHECK OBJECT 'S_USER_AGR'
        ID 'ACT_GROUP' FIELD lv_role
        ID 'ACTVT'     FIELD c_actvt_display.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e026(zlk05) WITH lv_role INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_idoc.

    DATA lv_subrc TYPE sy-subrc.
    DATA lv_prn   TYPE edi_rcvprn.
    DATA lv_prt   TYPE edi_rcvprt.
    DATA lo_badi  TYPE REF TO idoc_authority_restriction.
    DATA lv_ok    TYPE flag.

    " outbound: the receiver is checked, inbound: the sender
    IF is_edidc-direct = '1'.
      lv_prn = is_edidc-rcvprn.
      lv_prt = is_edidc-rcvprt.
    ELSE.
      lv_prn = is_edidc-sndprn.
      lv_prt = is_edidc-sndprt.
    ENDIF.

    TEST-SEAM auth_idoc.
      AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
        ID 'EDI_TCD' FIELD 'WE02'
        ID 'ACTVT'   FIELD c_actvt_display
        ID 'EDI_DIR' FIELD is_edidc-direct
        ID 'EDI_MES' FIELD is_edidc-mestyp
        ID 'EDI_PRN' FIELD lv_prn
        ID 'EDI_PRT' FIELD lv_prt.
      lv_subrc = sy-subrc.

      " the customer check of RSEIDOC2 on top of the authorization
      IF lv_subrc = 0.
        lv_ok = abap_true.
        TRY.
            GET BADI lo_badi FILTERS mestyp = is_edidc-mestyp.
            CALL BADI lo_badi->is_idoc_access_allowed
              EXPORTING if_docnum       = is_edidc-docnum
                        if_edidc        = is_edidc
              CHANGING  if_authority_ok = lv_ok.
          CATCH cx_badi.
            " no implementation - nothing restricts the access
        ENDTRY.
        IF lv_ok IS INITIAL.
          lv_subrc = 4.
        ENDIF.
      ENDIF.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e027(zlk05) WITH |{ shift_left( val = CONV string( is_edidc-docnum ) sub = `0` ) }| is_edidc-mestyp
        INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_spool.

    DATA lv_subrc  TYPE sy-subrc.
    DATA lv_access TYPE authb-spoaction.

    lv_access = to_upper( iv_access ).

    TEST-SEAM auth_spool.
      CALL FUNCTION 'RSPO_CHECK_JOB_PERMISSION'
        EXPORTING
          access        = lv_access
          spoolreq      = is_tsp01
        EXCEPTIONS
          no_permission = 1
          OTHERS        = 2.
      lv_subrc = sy-subrc.
    END-TEST-SEAM.

    IF lv_subrc = 0.
      result = allowed( ).
    ELSE.
      MESSAGE e028(zlk05) WITH condense( CONV string( is_tsp01-rqident ) ) INTO DATA(lv_msg).
      result = denied( lv_msg ).
    ENDIF.

  ENDMETHOD.


  METHOD check_message_class.

    DATA lv_arbgb TYPE sobj_name.
    lv_arbgb = to_upper( condense( iv_arbgb ) ).

    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'MSAG' AND obj_name = @lv_arbgb
      INTO @DATA(lv_devclass).

    result = check_develop( iv_actvt   = c_actvt_display
                            iv_package = CONV #( lv_devclass )
                            iv_objtype = `MSAG`
                            iv_objname = CONV #( lv_arbgb ) ).

  ENDMETHOD.

ENDCLASS.
