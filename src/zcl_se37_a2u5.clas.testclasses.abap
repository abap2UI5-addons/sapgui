CLASS ltcl_se37_a2u5 DEFINITION DEFERRED.
CLASS zcl_se37_a2u5 DEFINITION LOCAL FRIENDS ltcl_se37_a2u5.

CLASS ltcl_se37_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_se37_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_hitlist.
    METHODS given_function_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane           FOR TESTING.
    METHODS list_original_title    FOR TESTING.
    METHODS list_selection_screen  FOR TESTING.
    METHODS list_back_nav_wired    FOR TESTING.
    METHODS list_status_bar        FOR TESTING.
    METHODS list_has_gui_frame     FOR TESTING.
    METHODS list_keys_registered   FOR TESTING.
    METHODS list_command_field     FOR TESTING.
    METHODS list_drilldown_wired   FOR TESTING.
    METHODS list_unavailable_shown FOR TESTING.
    METHODS list_empty_is_sane     FOR TESTING.
    METHODS message_reaches_view   FOR TESTING.

    METHODS detail_is_sane         FOR TESTING.
    METHODS detail_title           FOR TESTING.
    METHODS detail_all_param_kinds FOR TESTING.
    METHODS detail_group_named     FOR TESTING.
    METHODS detail_back_to_list    FOR TESTING.
    METHODS detail_f3_stays_inside FOR TESTING.
    METHODS detail_has_gui_frame   FOR TESTING.
    METHODS detail_source_wired    FOR TESTING.
    METHODS source_fm_to_se38      FOR TESTING.
    METHODS source_unknown_fm      FOR TESTING.
ENDCLASS.


CLASS ltcl_se37_a2u5 IMPLEMENTATION.

  METHOD setup.
    zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_hitlist.
    mo_cut->mv_funcname  = `BAPI_*`.
    mo_cut->mt_functions = VALUE #(
        ( funcname = `BAPI_MATERIAL_GET_DETAIL` area = `MATERIAL_BAPI`
          stext = `Material Detail` rfc = `X` )
        ( funcname = `POPUP_TO_CONFIRM` area = `SPO1`
          stext = `Confirmation Popup` rfc = `` ) ).
  ENDMETHOD.

  METHOD given_function_detail.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `BAPI_MATERIAL_GET_DETAIL`.
    " all four parameter kinds of the SE37 interface screen
    mo_cut->mt_params  = VALUE #(
        ( pos = `1` kind = `IMPORTING` parameter = `MATERIAL` typing = `TYPE`
          reference = `MATNR` optional = `` default = `` )
        ( pos = `2` kind = `EXPORTING` parameter = `RETURN` typing = `TYPE`
          reference = `BAPIRETURN` optional = `` default = `` )
        ( pos = `3` kind = `CHANGING`  parameter = `CS_DATA` typing = `TYPE`
          reference = `ANY` optional = `X` default = `` )
        ( pos = `4` kind = `TABLES`    parameter = `IT_LINES` typing = `STRUCTURE`
          reference = `BAPI_LINE` optional = `X` default = `` ) ).
  ENDMETHOD.

  METHOD assert_shell_sane.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_ctx }: view is not well formed XML| ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( ) sub = `ROOT ELEMENT` )
        msg = |{ iv_ctx }: expected exactly one root, got { mo_dbl->get_root_name( ) }| ).

    LOOP AT VALUE string_table( ( `columns` ) ( `items` ) ( `cells` )
                                ( `footer` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== initial screen =====================

  METHOD list_is_sane.
    given_hitlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SE37 initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Function Builder: Initial Screen` ) >= 0 )
        msg = 'the original SE37 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idFuncName` ) >= 0 )
        msg = 'the Function Module input field is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Function Module` ) >= 0 )
        msg = 'the Function Module field label is missing' ).
    " the RFC flag is what SE37 users look for in the hit list
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{RFC}` ) >= 0 )
        msg = 'the RFC column is not bound' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_hitlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original texts of the
    " Function Builder
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Function Module` ) ( `Edit` ) ( `Goto` )
                                ( `Utilities` ) ( `Environment` ) ( `System` )
                                ( `Help` ) ( `Display` ) ( `Where-Used List` )
                                ( `Application Hierarchy` ) ( `Documentation` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_keys_registered.
    " the shortcut registry lives in the frontend and survives a transaction
    " switch, so every screen has to state its own binding for every key
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } is not registered for Back| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F8`
                                    iv_event = `EXECUTE` )
        msg = 'F8 is not registered for the Display function' ).
  ENDMETHOD.

  METHOD list_command_field.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD list_drilldown_wired.
    " the module name has to carry the row key, otherwise the drill down
    " opens the wrong function module
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the interface is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `FUNCNAME` )
        msg = 'the drill down does not carry the module of the row' ).
  ENDMETHOD.

  METHOD list_unavailable_shown.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled SE37 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_functions.
    mo_cut->view_display( ).

    assert_shell_sane( `SE37 initial screen without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `Function module Z_UNKNOWN does not exist.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Function module Z_UNKNOWN does not exist.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== display screen =====================

  METHOD detail_is_sane.
    given_function_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SE37 interface display` ).
  ENDMETHOD.

  METHOD detail_title.
    given_function_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `Function Builder: Display Function Module BAPI_MATERIAL_GET_DETAIL` ) >= 0 )
        msg = 'the interface display does not carry the original SE37 title' ).
  ENDMETHOD.

  METHOD detail_group_named.
    " the original display screen names the function group next to the module
    " (dynpro 3001 / 3030) - without it the module has no home
    given_function_detail( ).
    mo_cut->mv_curarea = `MATERIAL_BAPI`.
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Function Group` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `MATERIAL_BAPI` ) >= 0 )
        msg = 'the display screen does not name the function group' ).
  ENDMETHOD.

  METHOD detail_all_param_kinds.
    " SE37 shows IMPORTING / EXPORTING / CHANGING / TABLES in one list -
    " the Kind column has to be bound, otherwise the kinds are indistinguishable
    given_function_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{KIND}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{PARAMETER}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{OPTIONAL}` ) >= 0 )
        msg = 'the parameter list is not bound to the parameter structure' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Associated Type` ) >= 0 )
        msg = 'the Associated Type column is missing' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_function_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the display screen has no back navigation to the initial screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the display screen leaves the app instead of returning to the list' ).
  ENDMETHOD.

  METHOD detail_f3_stays_inside.
    " F3 on a screen INSIDE the transaction has to go back one screen, not
    " leave SE37 - the frame is told the screen event for that
    given_function_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = `BACK_TO_LIST` )
          msg = |{ lv_key } does not return to the initial screen| ).
      cl_abap_unit_assert=>assert_false(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } leaves the transaction instead of the screen| ).
    ENDLOOP.
    " Shift+F3 is Exit in the SAP GUI - it leaves the transaction from
    " every one of its screens, not only one screen back
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `Shift+F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_exit )
        msg = 'Shift+F3 must leave the transaction' ).
  ENDMETHOD.

  METHOD detail_has_gui_frame.
    given_function_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `Function Module` ) ( `Edit` ) ( `Goto` )
                                ( `Utilities` ) ( `Environment` ) ( `Back` )
                                ( `Previous Object` ) ( `Next Object` )
                                ( `Pretty Printer` ) ( `Code Inspector` )
                                ( `Object Directory Entry` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_source_wired.
    given_function_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `SOURCE` ) ).
  ENDMETHOD.

  METHOD source_fm_to_se38.
    given_function_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `SOURCE`.
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SE38_A2U5` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

  METHOD source_unknown_fm.
    given_function_detail( ).
    mo_cut->mv_current   = `Z_NO_SUCH_FUNCTION_X`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `SOURCE`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

ENDCLASS.
