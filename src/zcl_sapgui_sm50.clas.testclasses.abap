CLASS ltcl_sm50 DEFINITION DEFERRED.
CLASS zcl_sapgui_sm50 DEFINITION LOCAL FRIENDS ltcl_sm50.

CLASS ltcl_sm50 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_sm50.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_wp_list.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS view_is_sane          FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_instance_stated  FOR TESTING.
    METHODS view_refresh_wired    FOR TESTING.
    METHODS view_all_wp_columns   FOR TESTING.
    METHODS view_read_only_stated FOR TESTING.
    METHODS view_back_nav_wired   FOR TESTING.
    METHODS view_has_gui_frame    FOR TESTING.
    METHODS view_unavailable_shown FOR TESTING.
    METHODS view_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
ENDCLASS.


CLASS ltcl_sm50 IMPLEMENTATION.

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

  METHOD given_wp_list.
    mo_cut->mt_wp = VALUE #(
        ( wp_no = `0` wp_typ = `DIA` wp_pid = `4711` wp_status = `Waiting`
          wp_reason = `` wp_start = `Yes` wp_err = `0` wp_sem = ``
          wp_cpu = `0:01` wp_time = `` wp_report = `` wp_client = ``
          wp_user = `` wp_action = `` wp_table = `` )
        ( wp_no = `1` wp_typ = `BTC` wp_pid = `4712` wp_status = `Running`
          wp_reason = `` wp_start = `Yes` wp_err = `0` wp_sem = ``
          wp_cpu = `0:42` wp_time = `37` wp_report = `ZDEMO_REPORT`
          wp_client = `100` wp_user = `DEVELOPER` wp_action = `Sequential Read`
          wp_table = `MARA` ) ).
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
                                ( `footer` ) ( `subHeader` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== process overview =====================

  METHOD view_is_sane.
    given_wp_list( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SM50 process overview` ).
  ENDMETHOD.

  METHOD view_original_title.
    given_wp_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = |Work Processes of AS Instance { sy-host }| ) >= 0 )
        msg = 'the original SM50 screen title is missing' ).
  ENDMETHOD.

  METHOD view_instance_stated.
    " SM50 is always instance local - without naming the instance the numbers
    " are meaningless on a multi instance system
    given_wp_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |Instance { sy-host }| ) >= 0 )
        msg = 'the app does not state which instance the processes belong to' ).
  ENDMETHOD.

  METHOD view_refresh_wired.
    " a process overview without a refresh is useless
    given_wp_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `REFRESH` )
        msg = 'the Refresh button is not wired to the REFRESH event' ).
  ENDMETHOD.

  METHOD view_all_wp_columns.
    " the SAP GUI process overview shows 14 columns - all of them have to be
    " bound, a dropped one silently hides information
    given_wp_list( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `{WP_NO}` ) ( `{WP_TYP}` ) ( `{WP_PID}` )
                                ( `{WP_STATUS}` ) ( `{WP_REASON}` ) ( `{WP_START}` )
                                ( `{WP_ERR}` ) ( `{WP_CPU}` ) ( `{WP_TIME}` )
                                ( `{WP_CLIENT}` ) ( `{WP_USER}` ) ( `{WP_REPORT}` )
                                ( `{WP_ACTION}` ) ( `{WP_TABLE}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |the work process column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_read_only_stated.
    " the real SM50 can cancel a work process - this app deliberately cannot
    given_wp_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `Display only - no process can be cancelled here` ) >= 0 )
        msg = 'the read-only restriction of the app is not stated on screen' ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    given_wp_list( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD view_has_gui_frame.
    " menu bar and application function bar carry the original SM50 texts
    given_wp_list( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `List` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                                ( `Administration` ) ( `System` ) ( `Help` )
                                ( `Refresh` ) ( `Details` ) ( `System-Wide List` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_unavailable_shown.
    " cancelling a process and the trace functions stay visible but disabled
    given_wp_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the missing SM50 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    CLEAR mo_cut->mt_wp.
    mo_cut->view_display( ).

    assert_shell_sane( `SM50 process overview without processes` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    " TH_WPINFO reports its own failures - they must not be swallowed
    mo_cut->mv_message = `Work process information could not be read.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Work process information could not be read.` ) >= 0 )
        msg = 'the message from the kernel call never reaches the status bar' ).
  ENDMETHOD.

ENDCLASS.
