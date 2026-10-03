CLASS ltcl_sm04 DEFINITION DEFERRED.
CLASS zcl_sapgui_sm04 DEFINITION LOCAL FRIENDS ltcl_sm04.

CLASS ltcl_sm04 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_sm04.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_sessions.

    METHODS view_is_wellformed   FOR TESTING.
    METHODS view_original_title  FOR TESTING.
    METHODS view_all_columns     FOR TESTING.
    METHODS view_refresh_wired   FOR TESTING.
    METHODS view_back_nav_wired  FOR TESTING.
    METHODS view_read_only_stated FOR TESTING.
    METHODS view_empty_is_sane   FOR TESTING.

    METHODS view_click_opens_user    FOR TESTING.
    METHODS click_jumps_to_su01      FOR TESTING.

ENDCLASS.


CLASS ltcl_sm04 IMPLEMENTATION.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_sessions.
    mo_cut->mt_sessions = VALUE #(
        ( client = `100` bname = `DEVELOPER` tcode = `SE80` term = `PC4711`
          zeit = `10:15:00` sessions = `2` typetext = `GUI` hostadr = `10.0.0.1` ) ).
  ENDMETHOD.

  METHOD view_is_wellformed.
    given_sessions( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD view_original_title.
    given_sessions( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = |*User List of AS Instance { sy-host }*| ).
  ENDMETHOD.

  METHOD view_all_columns.
    given_sessions( ).
    mo_cut->view_display( ).
    LOOP AT VALUE string_table( ( `{CLIENT}` ) ( `{BNAME}` ) ( `{TERM}` ) ( `{TCODE}` )
                                ( `{ZEIT}` ) ( `{SESSIONS}` ) ( `{TYPETEXT}` ) ( `{HOSTADR}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_refresh_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `REFRESH` ) ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD view_read_only_stated.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*no session is ended here*` ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD view_click_opens_user.
    given_sessions( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY_USER|${BNAME}` ] ) )
        msg = 'a click on a session must open its user' ).
  ENDMETHOD.

  METHOD click_jumps_to_su01.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `DISPLAY_USER`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( CONV string( sy-uname ) ) ).
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SU01` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
