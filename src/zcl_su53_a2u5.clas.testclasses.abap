CLASS ltcl_su53_a2u5 DEFINITION DEFERRED.
CLASS zcl_su53_a2u5 DEFINITION LOCAL FRIENDS ltcl_su53_a2u5.

CLASS ltcl_su53_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_su53_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_fails.

    METHODS view_is_wellformed    FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_all_columns      FOR TESTING.
    METHODS view_user_field_bound FOR TESTING.
    METHODS view_refresh_wired    FOR TESTING.
    METHODS view_back_nav_wired   FOR TESTING.
    METHODS view_empty_is_sane    FOR TESTING.
    METHODS read_own_user_default FOR TESTING.
    METHODS read_unknown_user     FOR TESTING.
    METHODS start_param_user      FOR TESTING.
    METHODS user_jumps_to_su01    FOR TESTING.

ENDCLASS.


CLASS ltcl_su53_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_api = zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_fails.
    mo_cut->mt_fails = VALUE #(
        ( date = `02.10.2026` time = `10:15:00` objct = `S_TCODE`
          objtext = `Transaction Code Check at Transaction Start`
          fields = `TCD = SM59` rc = `12` reason = `No authorization`
          tcode = `SM59` program = `SAPLSMTR_NAVIGATION` line = `42`
          instance = `s4h_S4H_00` ) ).
  ENDMETHOD.

  METHOD view_is_wellformed.
    given_fails( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD view_original_title.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Evaluation of Authorization Check*` ).
  ENDMETHOD.

  METHOD view_all_columns.
    given_fails( ).
    mo_cut->view_display( ).
    LOOP AT VALUE string_table( ( `{DATE}` ) ( `{TIME}` ) ( `{OBJCT}` ) ( `{OBJTEXT}` )
                                ( `{FIELDS}` ) ( `{RC}` ) ( `{REASON}` ) ( `{TCODE}` )
                                ( `{PROGRAM}` ) ( `{LINE}` ) ( `{INSTANCE}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_user_field_bound.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idSu53User*` ).
  ENDMETHOD.

  METHOD view_refresh_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `REFRESH` ) ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `DISPLAY_USER` ) ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD read_own_user_default.
    " the own checks need no further authorization - there is always an
    " answer: a list or the statement that nothing failed
    mo_api->answer( iv_method = `GET_AUTH_FAILURES` iv_param = `EV_MESSAGE`
                    iv_value  = |No failed authorization checks for { sy-uname } in the last 3 hours.| ).
    mo_cut->mv_user = ``.
    mo_cut->do_read( ).
    cl_abap_unit_assert=>assert_equals( exp = CONV string( sy-uname ) act = mo_cut->mv_user ).
    cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( mo_cut->mv_msgtype = `Warning` OR mo_cut->mv_msgtype = `Success` )
        msg = |own checks must be readable: { mo_cut->mv_message }| ).
  ENDMETHOD.

  METHOD read_unknown_user.
    mo_cut->mv_user = `ZZ_NO_SUCH_USER_X`.
    mo_cut->do_read( ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_fails ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD start_param_user.
    mo_cut->zif_zlk05_start_params~set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_user value = ` developer ` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `DEVELOPER` act = mo_cut->mv_user ).
  ENDMETHOD.

  METHOD user_jumps_to_su01.
    mo_cut->mv_shown     = sy-uname.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `DISPLAY_USER`.
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SU01_A2U5` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
