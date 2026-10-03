CLASS ltcl_st05 DEFINITION DEFERRED.
CLASS zcl_sapgui_st05 DEFINITION LOCAL FRIENDS ltcl_st05.

CLASS ltcl_st05 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_st05.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_trace_off.
    METHODS given_trace_on_with_filter.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    " ---- screen 0010 - ST05 Performance Trace ----
    METHODS view_is_sane            FOR TESTING.
    METHODS view_original_title     FOR TESTING.
    METHODS view_trace_type_texts   FOR TESTING.
    METHODS view_configure_block    FOR TESTING.
    METHODS view_state_off          FOR TESTING.
    METHODS view_state_on           FOR TESTING.
    METHODS view_boxes_are_readonly FOR TESTING.
    METHODS view_refresh_wired      FOR TESTING.
    METHODS view_filter_wired       FOR TESTING.
    METHODS view_param_wired        FOR TESTING.
    METHODS view_param_section      FOR TESTING.
    METHODS view_source_stated      FOR TESTING.
    METHODS view_back_nav_wired     FOR TESTING.
    METHODS view_has_gui_frame      FOR TESTING.
    METHODS view_disabled_tooltips  FOR TESTING.

    " ---- screen 0020 - Conditions for Trace Recording ----
    METHODS filter_is_sane          FOR TESTING.
    METHODS filter_original_title   FOR TESTING.
    METHODS filter_field_texts      FOR TESTING.
    METHODS filter_values_shown     FOR TESTING.
    METHODS filter_back_wired       FOR TESTING.

    " ---- navigation between the two dynpros ----
    METHODS event_filter_opens_0020 FOR TESTING.
    METHODS message_reaches_view    FOR TESTING.

    " ---- kernel refused the state ----
    METHODS unknown_state_flagged   FOR TESTING.
    METHODS unknown_state_filter    FOR TESTING.
ENDCLASS.


CLASS ltcl_st05 IMPLEMENTATION.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client    = mo_dbl.
    mo_cut->mv_screen = `0010`.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_trace_off.
    " what ST05_GET_TRACE_STATE returns on an idle instance
    mo_cut->ms_state = VALUE #( any_on      = abap_false
                                state_known = abap_true
                                state_text  = `Trace is switched off` ).
    mo_cut->mv_message = mo_cut->ms_state-state_text.
    mo_cut->mv_msgtype = `Information`.
  ENDMETHOD.

  METHOD given_trace_on_with_filter.
    mo_cut->ms_state = VALUE #(
        state_known  = abap_true
        sql_on       = abap_true
        buf_on       = abap_true
        stack_on     = abap_true
        progress_on  = abap_true
        filter_on    = abap_true
        any_on       = abap_true
        trace_user   = `DEVELOPER`
        tcode        = `VA01`
        program      = `SAPMV45A`
        rfc_function = `RFC_PING`
        url          = `/sap/bc/adt`
        wp_id        = `007`
        incl_tables  = `VBAK, VBAP`
        excl_tables  = `TRDIR`
        incl_missing = abap_true
        mod_user     = `DEVELOPER`
        mod_date     = `31.07.2026`
        mod_time     = `10:15:00`
        state_text   = `Trace is switched on: SQL Trace, Buffer Trace ` &&
                       `(switched on by DEVELOPER 31.07.2026 10:15:00)` ).
    mo_cut->mv_message = mo_cut->ms_state-state_text.
    mo_cut->mv_msgtype = `Warning`.
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

* =====================================================================
*  Screen 0010
* =====================================================================
  METHOD view_is_sane.
    given_trace_off( ).
    mo_cut->view_display( ).

    assert_shell_sane( `ST05 initial screen` ).
  ENDMETHOD.

  METHOD view_original_title.
    given_trace_off( ).
    mo_cut->view_display( ).

    " T 0010 of R_ST05_TRACE_MAIN
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `ST05 Performance Trace` ) >= 0 )
        msg = 'the original ST05 screen title is missing' ).
  ENDMETHOD.

  METHOD view_trace_type_texts.
    " D021T texts of screen 0010 - every trace type of the original screen
    given_trace_off( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Select Trace Type` ) ( `SQL Trace` )
                                ( `Buffer Trace` ) ( `Enqueue Trace` )
                                ( `RFC Trace` ) ( `HTTP Trace` )
                                ( `AMC Trace` ) ( `APC trace` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST05 field text '{ lv_text }' is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_configure_block.
    " TEXT2 Configure Trace with the two On/Off radio groups
    given_trace_off( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Configure Trace` ) ( `Stack Trace` )
                                ( `Progress Display` )
                                ( `Trace State of Current Application Server Instance` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST05 field text '{ lv_text }' is missing| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( mo_dbl->count_children( `RadioButton` ) >= 0 )
        msg = 'the On/Off radio groups of Configure Trace are missing' ).
  ENDMETHOD.

  METHOD view_state_off.
    given_trace_off( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Trace is switched off` ) >= 0 )
        msg = 'the trace state of the instance is not shown' ).

    " no trace type box may be flagged when nothing is recording
    LOOP AT VALUE string_table( ( `SQL Trace` ) ( `Buffer Trace` )
                               ( `Enqueue Trace` ) ( `RFC Trace` )
                               ( `HTTP Trace` ) ( `AMC Trace` ) ( `APC trace` ) )
         INTO DATA(lv_type).
      cl_abap_unit_assert=>assert_equals(
          exp = -1
          act = find( val = mo_dbl->mv_view
                      sub = |text="{ lv_type }" selected="true"| )
          msg = |'{ lv_type }' is flagged although no trace is running| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_state_on.
    " the boxes mirror the real kernel state - SQL and buffer trace are on
    given_trace_on_with_filter( ).
    mo_cut->view_display( ).

    " exactly the two recording traces are flagged, the others are not
    LOOP AT VALUE string_table( ( `SQL Trace` ) ( `Buffer Trace` ) )
         INTO DATA(lv_on).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view
                               sub = |text="{ lv_on }" selected="true"| ) >= 0 )
          msg = |the running trace '{ lv_on }' is not flagged| ).
    ENDLOOP.

    LOOP AT VALUE string_table( ( `Enqueue Trace` ) ( `RFC Trace` )
                               ( `HTTP Trace` ) ( `AMC Trace` ) ( `APC trace` ) )
         INTO DATA(lv_off).
      cl_abap_unit_assert=>assert_equals(
          exp = -1
          act = find( val = mo_dbl->mv_view
                      sub = |text="{ lv_off }" selected="true"| )
          msg = |'{ lv_off }' is flagged although it is not recording| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Trace is switched on: SQL Trace, Buffer Trace` ) >= 0 )
        msg = 'the state text of the running trace is missing' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `DEVELOPER` ) >= 0 )
        msg = 'the user who switched the trace on is not shown' ).
  ENDMETHOD.

  METHOD view_boxes_are_readonly.
    " the app must never suggest that it can switch a trace on
    given_trace_on_with_filter( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `enabled="false"` ) >= 0 )
        msg = 'the trace type boxes are not read only' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `this app never switches a trace on or off` ) >= 0 )
        msg = 'the read only nature of the app is not explained' ).
  ENDMETHOD.

  METHOD view_refresh_wired.
    given_trace_off( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `REFRESH` )
        msg = 'Refresh Display is not wired to the REFRESH event' ).
  ENDMETHOD.

  METHOD view_filter_wired.
    given_trace_off( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `FILTER` )
        msg = 'Display Filter for Trace Recording is not wired' ).
  ENDMETHOD.

  METHOD view_param_wired.
    given_trace_off( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `SPRO` )
        msg = 'Display Profile Parameters for Trace is not wired' ).
  ENDMETHOD.

  METHOD view_param_section.
    " after SPRO the trace relevant profile parameters are listed
    given_trace_off( ).
    mo_cut->mv_show_param = abap_true.
    mo_cut->mt_param = VALUE #(
        ( label = `Trace File Directory (rstr/file)` value = `/usr/sap/S4H/D00/log/TRACE` )
        ( label = `Buffer Trace (rsdb/staton)`       value = `1` ) ).
    mo_cut->view_display( ).

    assert_shell_sane( `ST05 with profile parameters` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Profile Parameters for Trace` ) >= 0 )
        msg = 'the profile parameter section is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{LABEL}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{VALUE}` ) >= 0 )
        msg = 'the profile parameter table is not bound' ).
  ENDMETHOD.

  METHOD view_source_stated.
    " naming the function module makes the state verifiable
    given_trace_off( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `ST05_GET_TRACE_STATE` ) >= 0 )
        msg = 'the data source of the trace state is not stated' ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    given_trace_off( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD view_has_gui_frame.
    " menu bar and application function bar carry the original texts of
    " R_ST05_TRACE_MAIN (RSMPTEXTS)
    given_trace_off( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Performance Trace` ) ( `Edit` ) ( `Goto` )
                                ( `System` ) ( `Help` )
                                ( `Refresh Display` ) ( `Activate Trace` )
                                ( `Deactivate Trace` ) ( `Display Trace` )
                                ( `Display Filter for Trace Recording` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST05 text '{ lv_text }' is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_disabled_tooltips.
    " functions that cannot be offered stay visible with an explanation
    given_trace_off( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Deactivate Trace on All Instances` )
                                ( `Display Trace Without First Deactivating` )
                                ( `Display Detailed Trace List` )
                                ( `Save Trace` ) ( `Display Saved Trace` )
                                ( `Delete Saved Trace` )
                                ( `Display Trace Directory` )
                                ( `Execution Plan` )
                                ( `Check Measurement Environment` )
                                ( `Trace Kernel Errors` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST05 function '{ lv_text }' was dropped| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'disabled original functions carry no explaining tooltip' ).
  ENDMETHOD.

* =====================================================================
*  Screen 0020
* =====================================================================
  METHOD filter_is_sane.
    given_trace_on_with_filter( ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    assert_shell_sane( `ST05 conditions for trace recording` ).
  ENDMETHOD.

  METHOD filter_original_title.
    given_trace_on_with_filter( ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    " T 0020 of R_ST05_TRACE_MAIN
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Conditions for Trace Recording` ) >= 0 )
        msg = 'the original title of the ST05 filter screen is missing' ).
  ENDMETHOD.

  METHOD filter_field_texts.
    " D021T texts of screen 0020
    given_trace_on_with_filter( ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `(Only one of these filters can be set)` )
                                ( `User Name` ) ( `Transaction Name` )
                                ( `Program Name` ) ( `RFC Function Name` )
                                ( `URL` ) ( `Process Number` )
                                ( `Table Names (Only for SQL Trace)` )
                                ( `Include` ) ( `Exclude` )
                                ( `Include Statements with Empty Table Names` )
                                ( `Scheduling` ) ( `Schedule Trace Recording` )
                                ( `Start Date` ) ( `End Date` ) ( `EndTime` )
                                ( `Description` ) ( `Save Trace in DB` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST05 filter field '{ lv_text }' is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD filter_values_shown.
    " the filter really in force on the instance has to be visible
    given_trace_on_with_filter( ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `DEVELOPER` ) ( `VA01` ) ( `SAPMV45A` )
                                ( `RFC_PING` ) ( `007` ) ( `VBAK, VBAP` )
                                ( `TRDIR` ) )
         INTO DATA(lv_value).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_value ) >= 0 )
          msg = |the active filter value '{ lv_value }' is not shown| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD filter_back_wired.
    given_trace_on_with_filter( ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_0010` )
        msg = 'F3 does not lead back to the ST05 initial screen' ).
  ENDMETHOD.

* =====================================================================
*  Navigation
* =====================================================================
  METHOD event_filter_opens_0020.
    given_trace_on_with_filter( ).
    mo_dbl->ms_get-event = `FILTER`.

    mo_cut->on_event( ).

    cl_abap_unit_assert=>assert_equals(
        exp = `0020`
        act = mo_cut->mv_screen
        msg = 'FILTER does not switch to the conditions screen' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Conditions for Trace Recording` ) >= 0 )
        msg = 'the conditions screen was not rendered' ).
  ENDMETHOD.

  METHOD unknown_state_flagged.
    " ST05_GET_TRACE_STATE raised NO_AUTHORITY - empty boxes would read as
    " "no trace is running", so the screen has to say that the state is unknown
    mo_cut->ms_state = VALUE #(
        state_known = abap_false
        state_text  = `Trace state of this instance could not be read` ).
    mo_cut->mv_message = `You are not authorized to read the trace state ` &&
                         `(ST05_GET_TRACE_STATE, NO_AUTHORITY).`.
    mo_cut->mv_msgtype = `Warning`.
    mo_cut->view_display( ).

    assert_shell_sane( `ST05 with unknown trace state` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `do NOT show the state of the instance` ) >= 0 )
        msg = 'empty trace type boxes are presented as if no trace was running' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `unknown` ) >= 0 )
        msg = 'the filter state is shown as No although it is unknown' ).
  ENDMETHOD.

  METHOD unknown_state_filter.
    mo_cut->ms_state = VALUE #( state_known = abap_false ).
    mo_cut->mv_screen = `0020`.
    mo_cut->view_display( ).

    assert_shell_sane( `ST05 conditions with unknown trace state` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `unknown, not empty` ) >= 0 )
        msg = 'empty filter fields are presented as if no filter was set' ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `You are not authorized to read the trace state.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `You are not authorized to read the trace state.` ) >= 0 )
        msg = 'the message of the kernel call never reaches the status bar' ).
  ENDMETHOD.

ENDCLASS.
