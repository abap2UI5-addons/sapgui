CLASS ltcl_sm21 DEFINITION DEFERRED.
CLASS zcl_sapgui_sm21 DEFINITION LOCAL FRIENDS ltcl_sm21.

CLASS ltcl_sm21 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_sm21.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_syslog.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS view_is_sane          FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_all_sel_fields   FOR TESTING.
    METHODS view_date_format_hint FOR TESTING.
    METHODS view_log_columns      FOR TESTING.
    METHODS view_back_nav_wired   FOR TESTING.
    METHODS view_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
    METHODS view_has_gui_frame    FOR TESTING.
    METHODS view_click_wired      FOR TESTING.
    METHODS click_no_dump_entry   FOR TESTING.
    METHODS click_dump_to_st22    FOR TESTING.
ENDCLASS.


CLASS ltcl_sm21 IMPLEMENTATION.

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

  METHOD given_syslog.
    mo_cut->mv_date_from = `20240101`.
    mo_cut->mv_date_to   = `20240102`.
    mo_cut->mt_syslog = VALUE #(
        ( date = `01.01.2024` time = `12:00:00` instid = `s4h_S4H_00`
          task = `DIA 000` mand = `100` user = `DEVELOPER` tcode = `SE38`
          repna = `ZDEMO_REPORT` clasid = `BY` text = `Database error 1234` )
        ( date = `01.01.2024` time = `12:05:00` instid = `s4h_S4H_00`
          task = `BTC 001` mand = `100` user = `BATCHUSER` tcode = ``
          repna = `ZDEMO_JOB` clasid = `BZ` text = `Run-time error occurred` ) ).
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

  " ===================== system log =====================

  METHOD view_is_sane.
    given_syslog( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SM21 system log` ).
  ENDMETHOD.

  METHOD view_original_title.
    given_syslog( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `System Log: Local Analysis` ) >= 0 )
        msg = 'the original SM21 screen title is missing' ).
  ENDMETHOD.

  METHOD view_all_sel_fields.
    " SM21 is selected by time window plus optional user and transaction -
    " all four fields have to be on the selection screen
    given_syslog( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idLogFrom` ) >= 0 )
        msg = 'the selection block of the work area is empty' ).

    LOOP AT VALUE string_table( ( `From Date` ) ( `To Date` )
                                ( `User` ) ( `Transaction` ) )
         INTO DATA(lv_label).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_label ) >= 0 )
          msg = |the selection field '{ lv_label }' is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_date_format_hint.
    " the date fields are plain inputs - without the expected format the user
    " cannot guess it, and a wrong entry silently returns nothing
    given_syslog( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `YYYYMMDD` ) >= 0 )
        msg = 'the expected date format is not shown as a placeholder' ).
  ENDMETHOD.

  METHOD view_log_columns.
    " the message text plus its context (user, transaction, program) is the
    " whole point of the system log
    given_syslog( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `{DATE}` ) ( `{TIME}` ) ( `{USER}` )
                                ( `{TCODE}` ) ( `{REPNA}` ) ( `{TEXT}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |the system log column { lv_field } is not bound| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Message Text` ) >= 0 )
        msg = 'the Message Text column header is missing' ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    given_syslog( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " the yellow Back arrow of the system function bar carries the event
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    CLEAR mo_cut->mt_syslog.
    mo_cut->view_display( ).

    assert_shell_sane( `SM21 system log without entries` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `System log could not be read.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `System log could not be read.` ) >= 0 )
        msg = 'the message never reaches the status bar' ).
  ENDMETHOD.

  METHOD view_has_gui_frame.
    " menu bar and application function bar carry the original SM21 texts
    " of RSLG0000 / SAPMSM21 (RSMPTEXTS)
    given_syslog( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `System log` ) ( `Edit` ) ( `Goto` )
                                ( `Environment` ) ( `System` ) ( `Help` )
                                ( `Reread System Log` ) ( `Details` )
                                ( `System Log Documentation` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original SM21 text '{ lv_text }' is missing| ).
    ENDLOOP.

    " what this app cannot do has to say so instead of pretending
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'disabled original functions carry no explaining tooltip' ).
  ENDMETHOD.

  METHOD view_click_wired.
    given_syslog( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `GOTO_DUMP|${DATE}|${USER}|${CLASID}` ] ) )
        msg = 'a click on a log entry must be able to open the dump' ).
  ENDMETHOD.

  METHOD click_no_dump_entry.
    " a database error is no runtime error - no jump, a hint instead
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `GOTO_DUMP`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `01.01.2024|DEVELOPER|BY` ) ).
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_equals( exp = `Information` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD click_dump_to_st22.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `GOTO_DUMP`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( |01.01.2024\|{ sy-uname }\|AB0| ) ).
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_ST22` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
