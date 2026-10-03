CLASS ltcl_st22 DEFINITION DEFERRED.
CLASS zcl_sapgui_st22 DEFINITION LOCAL FRIENDS ltcl_st22.

CLASS ltcl_st22 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_st22.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_dumplist.
    METHODS given_dump_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.
    METHODS assert_texts
      IMPORTING it_text TYPE string_table
                iv_ctx  TYPE string.

    " screen 1 - selection screen
    METHODS sel_is_sane           FOR TESTING.
    METHODS sel_original_title    FOR TESTING.
    METHODS sel_selection_fields  FOR TESTING.
    METHODS sel_has_gui_frame     FOR TESTING.
    METHODS sel_unavailable_shown FOR TESTING.
    METHODS sel_back_nav_wired    FOR TESTING.
    METHODS sel_status_bar        FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
    METHODS date_input_guarded    FOR TESTING.
    METHODS start_params_taken    FOR TESTING.
    METHODS called_back_leaves    FOR TESTING.
    METHODS not_called_back_stays FOR TESTING.

    " screen 2 - list of selected runtime errors
    METHODS list_is_sane          FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_error_columns    FOR TESTING.
    METHODS list_compound_key     FOR TESTING.
    METHODS list_has_gui_frame    FOR TESTING.
    METHODS list_back_to_sel      FOR TESTING.
    METHODS list_empty_is_sane    FOR TESTING.

    " screen 3 - long text
    METHODS detail_is_sane        FOR TESTING.
    METHODS detail_title          FOR TESTING.
    METHODS detail_source_stated  FOR TESTING.
    METHODS detail_has_gui_frame  FOR TESTING.
    METHODS detail_goto_wired     FOR TESTING.
    METHODS detail_goto_jumps     FOR TESTING.
    METHODS detail_goto_no_prog   FOR TESTING.
    METHODS detail_back_to_list   FOR TESTING.
ENDCLASS.


CLASS ltcl_st22 IMPLEMENTATION.

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

  METHOD given_dumplist.
    mo_cut->mv_date_from = `20240101`.
    mo_cut->mv_user      = `*`.
    mo_cut->mv_mode      = `LIST`.
    mo_cut->mt_dumps = VALUE #(
        ( datum = `01.01.2024` uzeit = `12:00:00` uname = `DEVELOPER` mandt = `100`
          ahost = `s4h` modno = `0` errorid = `COMPUTE_INT_ZERODIVIDE`
          program = `ZDEMO_REPORT` incl = `ZDEMO_REPORT` line = `42`
          key_date = '20240101' key_time = '120000' key_mod = `0` )
        ( datum = `01.01.2024` uzeit = `13:00:00` uname = `DEVELOPER` mandt = `100`
          ahost = `s4h` modno = `1` errorid = `MESSAGE_TYPE_X`
          program = `SAPLSETX` incl = `LSETXU01` line = `17`
          key_date = '20240101' key_time = '130000' key_mod = `1` ) ).
  ENDMETHOD.

  METHOD detail_goto_wired.
    given_dump_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `GOTO_PROGRAM` )
        msg = '"Go to Affected Program" is not wired' ).
  ENDMETHOD.

  METHOD detail_goto_jumps.
    " the jump goes through the router: SE38 is started - or, without the
    " authorization for SE38, the user gets the router's message
    given_dump_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `GOTO_PROGRAM`.
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE38` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

  METHOD detail_goto_no_prog.
    given_dump_detail( ).
    DELETE mo_cut->mt_detail WHERE label = `Program`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `GOTO_PROGRAM`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD given_dump_detail.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `COMPUTE_INT_ZERODIVIDE`.
    mo_cut->mt_detail  = VALUE #(
        ( label = `Runtime Error` value = `COMPUTE_INT_ZERODIVIDE` )
        ( label = `Program`       value = `ZDEMO_REPORT` )
        ( label = `Line`          value = `42` ) ).
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

  METHOD assert_texts.
    LOOP AT it_text INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |{ iv_ctx } does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  " ============ screen 1 - ABAP Runtime Errors - Client & ============

  METHOD sel_is_sane.
    mo_cut->view_display( ).

    assert_shell_sane( `ST22 selection screen` ).
  ENDMETHOD.

  METHOD sel_original_title.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = |ABAP Runtime Errors - Client { sy-mandt }| ) >= 0 )
        msg = 'the original ST22 screen title is missing' ).
  ENDMETHOD.

  METHOD sel_selection_fields.
    " the field names of the original selection screen, in the original order
    mo_cut->view_display( ).

    assert_texts( iv_ctx  = `the selection screen`
                  it_text = VALUE #( ( `Selection` ) ( `Runtime error` ) ( `Date` )
                                     ( `Time` ) ( `User` ) ( `Client` ) ( `Host` )
                                     ( `idDateFrom` ) ) ).
  ENDMETHOD.

  METHOD sel_has_gui_frame.
    " menu bar and application function bar carry the original ST22 texts
    mo_cut->view_display( ).

    assert_texts( iv_ctx  = `the selection screen`
                  it_text = VALUE #( ( `Runtime Errors` ) ( `Edit` ) ( `Goto` )
                                     ( `System` ) ( `Help` )
                                     ( `Display List` ) ( `Reorganize` )
                                     ( `Statistics` ) ( `Overview` ) ) ).
  ENDMETHOD.

  METHOD sel_unavailable_shown.
    " functions the app cannot offer stay visible but disabled - a user of the
    " real ST22 has to be able to see what is missing
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `enabled="false"` ) >= 0 )
        msg = 'nothing is disabled although several ST22 functions are missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled functions do not explain themselves in a tooltip' ).
  ENDMETHOD.

  METHOD sel_back_nav_wired.
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD sel_status_bar.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = CONV string( sy-sysid ) ) >= 0
                   AND find( val = mo_dbl->mv_view sub = CONV string( sy-mandt ) ) >= 0
                   AND find( val = mo_dbl->mv_view sub = CONV string( sy-uname ) ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD message_reaches_view.
    " the classic status bar shows the message with a type icon
    mo_cut->mv_message = `No runtime errors as of 01.01.2024.`.
    mo_cut->mv_msgtype = `Information`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `No runtime errors as of 01.01.2024.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  METHOD date_input_guarded.
    " a broken date must not turn into a selection over the whole SNAP table
    mo_cut->mv_date_from = `not a date`.
    cl_abap_unit_assert=>assert_equals(
        exp = CONV d( sy-datum - 7 )
        act = mo_cut->date_from_input( )
        msg = 'an unusable date is not caught' ).

    mo_cut->mv_date_from = `2024.01.01`.
    cl_abap_unit_assert=>assert_equals(
        exp = CONV d( '20240101' )
        act = mo_cut->date_from_input( )
        msg = 'a date with separators is not accepted' ).
  ENDMETHOD.

  " ============ screen 2 - List of Selected Runtime Errors ============

  METHOD list_is_sane.
    given_dumplist( ).
    mo_cut->view_list( ).

    assert_shell_sane( `ST22 list of runtime errors` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_dumplist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `List of Selected Runtime Errors` ) >= 0 )
        msg = 'the original title of the ST22 list screen is missing' ).
  ENDMETHOD.

  METHOD list_error_columns.
    " the runtime error name, program and line are the three fields ST22
    " users read first - they come from the decoded SNAP FLIST field
    given_dumplist( ).
    mo_cut->view_list( ).

    assert_texts( iv_ctx  = `the runtime error list`
                  it_text = VALUE #( ( `{ERRORID}` ) ( `{PROGRAM}` ) ( `{LINE}` )
                                     ( `Runtime Error` ) ( `Program` ) ( `Line` ) ) ).
  ENDMETHOD.

  METHOD list_compound_key.
    " a dump is identified by date + time + module number. If the compound key
    " is not passed on, the detail screen cannot find the dump again. The view
    " XML only carries the opaque handler expression, so the argument has to be
    " checked on the registered event itself.
    given_dumplist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `KEY_DATE` )
        msg = 'the dump date is not handed over to the detail event' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `KEY_TIME` )
        msg = 'the dump time is not handed over to the detail event' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `KEY_MOD` )
        msg = 'the module number is not handed over to the detail event' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    given_dumplist( ).
    mo_cut->view_list( ).

    assert_texts( iv_ctx  = `the runtime error list`
                  it_text = VALUE #( ( `Runtime Errors` ) ( `Goto` )
                                     ( `Selection` ) ( `Refresh` )
                                     ( `Display Long Text` ) ) ).
  ENDMETHOD.

  METHOD list_back_to_sel.
    given_dumplist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_SEL` )
        msg = 'F3 on the list does not return to the selection screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the list leaves the app instead of returning to the selection' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_dumps.
    mo_cut->view_list( ).

    assert_shell_sane( `ST22 list without dumps` ).
  ENDMETHOD.

  " ============ screen 3 - Runtime Error Long Text ============

  METHOD detail_is_sane.
    given_dump_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `ST22 long text` ).
  ENDMETHOD.

  METHOD detail_title.
    given_dump_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Runtime Error Long Text` ) >= 0 )
        msg = 'the long text screen does not carry its original title' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `COMPUTE_INT_ZERODIVIDE` ) >= 0 )
        msg = 'the long text screen does not name the runtime error' ).
  ENDMETHOD.

  METHOD detail_source_stated.
    " the detail is decoded from the SNAP header, not from the full dump.
    " The app has to say so instead of pretending to show the whole dump.
    given_dump_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Decoded from the SNAP dump header` ) >= 0 )
        msg = 'the data source restriction is not stated on the detail screen' ).
  ENDMETHOD.

  METHOD detail_has_gui_frame.
    given_dump_detail( ).
    mo_cut->view_detail( ).

    assert_texts( iv_ctx  = `the long text screen`
                  it_text = VALUE #( ( `Runtime Errors` ) ( `Goto` )
                                     ( `Display List` )
                                     ( `Go to Affected Program` ) ( `Debugger` ) ) ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_dump_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the back navigation is not wired to the BACK_TO_LIST event' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the long text leaves the app instead of returning to the list' ).
  ENDMETHOD.

  METHOD start_params_taken.
    mo_cut->zif_sapgui_start_params~set_start_params( VALUE #(
        ( name = zif_sapgui_start_params=>c_date value = ` 20240101 ` )
        ( name = zif_sapgui_start_params=>c_user value = `developer` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `20240101`  act = mo_cut->mv_start_date ).
    cl_abap_unit_assert=>assert_equals( exp = `DEVELOPER` act = mo_cut->mv_start_user ).
  ENDMETHOD.

  METHOD called_back_leaves.
    " started from SM21: Back from the list returns to the system log
    mo_cut->mv_called    = abap_true.
    mo_cut->mv_mode      = `LIST`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_SEL`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD not_called_back_stays.
    mo_cut->mv_mode      = `LIST`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_SEL`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_false( mo_dbl->mv_nav_leave ).
    cl_abap_unit_assert=>assert_equals( exp = `SEL` act = mo_cut->mv_mode ).
  ENDMETHOD.

ENDCLASS.
