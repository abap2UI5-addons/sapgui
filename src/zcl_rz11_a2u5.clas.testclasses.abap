CLASS ltcl_rz11_a2u5 DEFINITION DEFERRED.
CLASS zcl_rz11_a2u5 DEFINITION LOCAL FRIENDS ltcl_rz11_a2u5.

CLASS ltcl_rz11_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_rz11_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_paramlist.
    METHODS given_param_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane            FOR TESTING.
    METHODS list_original_title     FOR TESTING.
    METHODS list_has_gui_frame      FOR TESTING.
    METHODS list_selection_screen   FOR TESTING.
    METHODS list_param_columns      FOR TESTING.
    METHODS list_display_wired      FOR TESTING.
    METHODS list_alldyn_wired       FOR TESTING.
    METHODS list_unavailable_shown  FOR TESTING.
    METHODS list_read_only_stated   FOR TESTING.
    METHODS list_back_nav_wired     FOR TESTING.
    METHODS list_empty_is_sane      FOR TESTING.
    METHODS message_reaches_view    FOR TESTING.

    METHODS detail_is_sane          FOR TESTING.
    METHODS detail_title            FOR TESTING.
    METHODS detail_attribute_labels FOR TESTING.
    METHODS detail_back_to_list     FOR TESTING.

ENDCLASS.


CLASS ltcl_rz11_a2u5 IMPLEMENTATION.

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

  METHOD given_paramlist.
    mo_cut->mv_pattern = `rdisp/*`.
    mo_cut->mt_params = VALUE #(
        ( paraname = `rdisp/max_wprun_time` value = `600` grp = `Dispatcher`
          ptype = `Integer` dynamic = `X` descr = `Maximum runtime of a dialog step` )
        ( paraname = `rdisp/wp_no_dia` value = `15` grp = `Dispatcher`
          ptype = `Integer Interval` dynamic = `` descr = `Number of dialog work processes` ) ).
  ENDMETHOD.

  METHOD given_param_detail.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `rdisp/wp_no_dia`.
    mo_cut->mt_detail  = VALUE #(
        ( label = `Name`             value = `rdisp/wp_no_dia` )
        ( label = `Value`            value = `15` )
        ( label = `Resulting Source` value = `Instance Profile` ) ).
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
                                ( `footer` ) ( `content` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== parameter list =====================

  METHOD list_is_sane.
    given_paramlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `RZ11 parameter list` ).
  ENDMETHOD.

  METHOD list_original_title.
    " title bar text of RSPFLDOC dynpro 100
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Edit Profile Parameters` ) >= 0 )
        msg = 'the original RZ11 screen title is missing' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original RZ11 texts
    given_paramlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` )
                                ( `Display` ) ( `All Dynamic Parameters` )
                                ( `Profile Parameter Maintenance` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_selection_screen.
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Parameter Name` ) >= 0 )
        msg = 'the Parameter Name field label of dynpro 1000 is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `EXECUTE` )
        msg = 'the parameter name field is not wired to the EXECUTE event' ).
  ENDMETHOD.

  METHOD list_param_columns.
    " the dynamic flag decides whether a parameter can be changed without a
    " restart - it is the key information of the RZ11 list
    given_paramlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `{PARANAME}` ) ( `{VALUE}` ) ( `{PTYPE}` )
                                ( `{DYNAMIC}` ) ( `{GRP}` ) ( `{DESCR}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |the parameter column { lv_field } is not bound| ).
    ENDLOOP.

    " column headers are the RSPFLDOC text elements
    LOOP AT VALUE string_table( ( `Dynamic Parameter` ) ( `Parameter Group` )
                                ( `Parameter Description` ) )
         INTO DATA(lv_head).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_head ) >= 0 )
          msg = |the original column header "{ lv_head }" is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_display_wired.
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the parameter name is not clickable - DISPLAY is not wired' ).
  ENDMETHOD.

  METHOD list_alldyn_wired.
    " ALLDYN is a real RZ11 function and it really works here
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `ALLDYN` )
        msg = 'the All Dynamic Parameters button is not wired' ).
  ENDMETHOD.

  METHOD list_unavailable_shown.
    " changing a value stays visible but disabled
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Change Value` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Display Documentation` ) >= 0
                   AND find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the missing RZ11 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD list_read_only_stated.
    given_paramlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `Display only - no parameter is changed here` ) >= 0 )
        msg = 'the read-only restriction of the app is not stated on screen' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_paramlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_params.
    mo_cut->view_display( ).

    assert_shell_sane( `RZ11 parameter list without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `No profile parameters found for the selection.`.
    mo_cut->mv_msgtype = `Warning`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `No profile parameters found for the selection.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== parameter attributes =====================

  METHOD detail_is_sane.
    given_param_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `RZ11 parameter attributes` ).
  ENDMETHOD.

  METHOD detail_title.
    " title bar text of RSPFLDOC dynpro 110
    given_param_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `Display Profile Parameter Attributes` ) >= 0 )
        msg = 'the attribute screen does not carry the original RZ11 title' ).
  ENDMETHOD.

  METHOD detail_attribute_labels.
    " group box text of dynpro 1001 plus the parameter under display
    given_param_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Parameter Properties` ) >= 0 )
        msg = 'the Parameter Properties group box of dynpro 1001 is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `rdisp/wp_no_dia` ) >= 0 )
        msg = 'the status bar does not name the parameter being displayed' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_param_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the attribute screen has no way back to the list' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the attribute screen leaves the app instead of returning to the list' ).
  ENDMETHOD.

  " ===================== data source =====================

ENDCLASS.
