CLASS ltcl_slg1_a2u5 DEFINITION DEFERRED.
CLASS zcl_slg1_a2u5 DEFINITION LOCAL FRIENDS ltcl_slg1_a2u5.

CLASS ltcl_slg1_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_slg1_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_logs.
    METHODS given_messages.

    METHODS list_is_wellformed     FOR TESTING.
    METHODS list_original_title    FOR TESTING.
    METHODS list_columns_bound     FOR TESTING.
    METHODS list_click_opens_log   FOR TESTING.
    METHODS list_execute_wired     FOR TESTING.
    METHODS list_read_only_stated  FOR TESTING.
    METHODS detail_is_wellformed   FOR TESTING.
    METHODS detail_columns_bound   FOR TESTING.
    METHODS detail_f3_back_to_list FOR TESTING.
    METHODS open_unknown_log       FOR TESTING.
    METHODS bad_date_is_ignored    FOR TESTING.
    METHODS api_logs_are_visible   FOR TESTING.
ENDCLASS.


CLASS ltcl_slg1_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_logs.
    mo_cut->mt_logs = VALUE #(
        ( lognumber = `4711` object = `ZTEST` subobject = `SUB` aldate = `02.10.2026`
          altime = `10:00:00` aluser = `DEVELOPER` msg_all = `3` msg_err = `1`
          msg_warn = `1` state = `Error` ) ).
  ENDMETHOD.

  METHOD given_messages.
    mo_cut->mv_cur_log = `4711`.
    mo_cut->mt_messages = VALUE #(
        ( msgno = `1` severity = `E` sevtext = `Error` state = `Error`
          text = `Something failed` tstamp = `2026-10-02 10:00:00` ) ).
  ENDMETHOD.

  METHOD list_is_wellformed.
    given_logs( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD list_original_title.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Analyze Application Log*` ).
  ENDMETHOD.

  METHOD list_columns_bound.
    given_logs( ).
    mo_cut->view_display( ).
    LOOP AT VALUE string_table( ( `{STATE}` ) ( `{OBJECT}` ) ( `{SUBOBJECT}` ) ( `{ALDATE}` )
                                ( `{ALUSER}` ) ( `{MSG_ALL}` ) ( `{LOGNUMBER}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_click_opens_log.
    given_logs( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${LOGNUMBER}` ] ) )
        msg = 'a click on a log must open it with its log number' ).
  ENDMETHOD.

  METHOD list_execute_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `EXECUTE` ) ).
  ENDMETHOD.

  METHOD list_read_only_stated.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*No log is deleted or archived here*` ).
  ENDMETHOD.

  METHOD detail_is_wellformed.
    given_messages( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Display Logs - 4711*` ).
  ENDMETHOD.

  METHOD detail_columns_bound.
    given_messages( ).
    mo_cut->view_detail( ).
    LOOP AT VALUE string_table( ( `{SEVTEXT}` ) ( `{TEXT}` ) ( `{TSTAMP}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_f3_back_to_list.
    " F3 on the message screen returns to the list - it must not leave SLG1
    given_logs( ).
    given_messages( ).
    mo_cut->mv_mode = `DETAIL`.
    mo_dbl->mv_on_event = abap_true.
    mo_dbl->ms_get-event = zcl_zlk05_gui_frame=>c_ev_back.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_false( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD open_unknown_log.
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `99999999999999999999` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD bad_date_is_ignored.
    " the dates come from the browser - something that is not a date must
    " not reach the selection
    mo_cut->mv_object    = `ZZLK05_NO_SUCH_OBJECT`.
    mo_cut->mv_date_from = `1' OR '1'='1`.
    mo_cut->do_search( ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_logs ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD api_logs_are_visible.
    " every log returned carries the fields the list needs
    LOOP AT zcl_zlk05_sys_api=>get_app_logs( iv_max = 5 ) INTO DATA(ls_log).
      cl_abap_unit_assert=>assert_not_initial( ls_log-lognumber ).
      cl_abap_unit_assert=>assert_not_initial( ls_log-state ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
