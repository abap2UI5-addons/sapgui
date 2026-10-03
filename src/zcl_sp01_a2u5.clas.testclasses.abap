CLASS ltcl_sp01_a2u5 DEFINITION DEFERRED.
CLASS zcl_sp01_a2u5 DEFINITION LOCAL FRIENDS ltcl_sp01_a2u5.

CLASS ltcl_sp01_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sp01_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_list.

    METHODS list_is_wellformed    FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_all_columns      FOR TESTING.
    METHODS list_selection_fields FOR TESTING.
    METHODS list_display_wired    FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS list_read_only_stated FOR TESTING.
    METHODS list_empty_is_sane    FOR TESTING.
    METHODS content_is_wellformed FOR TESTING.
    METHODS content_back_to_list  FOR TESTING.
    METHODS open_invalid_number   FOR TESTING.
    METHODS open_unknown_request  FOR TESTING.
    METHODS start_param_owner     FOR TESTING.
    METHODS search_own_requests   FOR TESTING.
    METHODS date_input_guarded    FOR TESTING.

ENDCLASS.


CLASS ltcl_sp01_a2u5 IMPLEMENTATION.

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

  METHOD given_list.
    mo_cut->mv_owner = `DEVELOPER`.
    mo_cut->mt_spool = VALUE #(
        ( rqident = `31999` doctype = `LIST` date = `27.09.2026` time = `04:38`
          status = `Compl.` state = `Success` pages = `2` title = `LIST1S LP01 FIN_EDI_EXTR`
          owner = `DEVELOPER` dest = `LP01` )
        ( rqident = `32000` doctype = `OTF` date = `27.09.2026` time = `04:39`
          status = `-` state = `None` pages = `1` title = `Smart Form`
          owner = `DEVELOPER` dest = `LP01` ) ).
  ENDMETHOD.

  METHOD list_is_wellformed.
    given_list( ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD list_original_title.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Output Controller: List of Spool Requests*` ).
  ENDMETHOD.

  METHOD list_all_columns.
    given_list( ).
    mo_cut->view_list( ).
    LOOP AT VALUE string_table( ( `{RQIDENT}` ) ( `{DOCTYPE}` ) ( `{DATE}` ) ( `{TIME}` )
                                ( `{STATUS}` ) ( `{STATE}` ) ( `{PAGES}` ) ( `{TITLE}` )
                                ( `{OWNER}` ) ( `{DEST}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_selection_fields.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idSpoolOwner*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idSpoolDate*` ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `EXECUTE` ) ).
  ENDMETHOD.

  METHOD list_display_wired.
    given_list( ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${RQIDENT}` ] ) )
        msg = 'the spool number must open the content' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD list_read_only_stated.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Display only*` ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD content_is_wellformed.
    mo_cut->mv_mode    = `CONTENT`.
    mo_cut->mv_current = `31999`.
    mo_cut->mv_content = |line 1{ cl_abap_char_utilities=>newline }line 2 with <xml> & braces \{x\}|.
    mo_cut->mv_lines   = 2.
    mo_cut->render( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Spool Request 31999*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*CodeEditor*` ).
  ENDMETHOD.

  METHOD content_back_to_list.
    mo_cut->mv_mode      = `CONTENT`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_LIST`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
  ENDMETHOD.

  METHOD open_invalid_number.
    mo_api->answer( iv_method = `GET_SPOOL_CONTENT` iv_param = `EV_MESSAGE` iv_key = `12ab`
                    iv_value  = `Enter a valid spool request number` ).
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `12ab` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST`  act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD open_unknown_request.
    mo_api->answer( iv_method = `GET_SPOOL_CONTENT` iv_param = `EV_MESSAGE` iv_key = `2147483000`
                    iv_value  = `Spool request 2147483000 does not exist` ).
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `2147483000` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*does not exist*` ).
  ENDMETHOD.

  METHOD start_param_owner.
    mo_cut->zif_zlk05_start_params~set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_user value = ` developer ` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `DEVELOPER` act = mo_cut->mv_owner ).
  ENDMETHOD.

  METHOD search_own_requests.
    " the own spool requests are always visible - list or a clean warning
    mo_cut->mv_owner     = CONV string( sy-uname ).
    mo_cut->mv_date_from = `20200101`.
    mo_cut->do_search( ).
    cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    LOOP AT mo_cut->mt_spool INTO DATA(ls).
      cl_abap_unit_assert=>assert_equals( exp = CONV string( sy-uname ) act = ls-owner ).
      cl_abap_unit_assert=>assert_not_initial( ls-status ).
    ENDLOOP.
  ENDMETHOD.

  METHOD date_input_guarded.
    mo_cut->mv_date_from = `not a date`.
    cl_abap_unit_assert=>assert_equals( exp = sy-datum act = mo_cut->date_from_input( ) ).
    mo_cut->mv_date_from = `01.02.2026`.
    " the German format of the status bar date is understood as well
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260201' ) act = mo_cut->date_from_input( ) ).
    mo_cut->mv_date_from = `20261399`.
    cl_abap_unit_assert=>assert_equals( exp = sy-datum act = mo_cut->date_from_input( ) ).
    mo_cut->mv_date_from = `2026-02-01`.
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260201' ) act = mo_cut->date_from_input( ) ).
  ENDMETHOD.

ENDCLASS.
