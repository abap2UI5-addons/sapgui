CLASS ltcl_sm37_a2u5 DEFINITION DEFERRED.
CLASS zcl_sm37_a2u5 DEFINITION LOCAL FRIENDS ltcl_sm37_a2u5.

CLASS ltcl_sm37_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sm37_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_joblist.
    METHODS given_step_list.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane            FOR TESTING.
    METHODS list_original_title     FOR TESTING.
    METHODS list_selection_screen   FOR TESTING.
    METHODS list_all_status_values  FOR TESTING.
    METHODS list_status_is_coloured FOR TESTING.
    METHODS list_back_nav_wired     FOR TESTING.
    METHODS list_status_bar         FOR TESTING.
    METHODS list_has_gui_frame      FOR TESTING.
    METHODS list_empty_is_sane      FOR TESTING.
    METHODS message_reaches_view    FOR TESTING.

    METHODS detail_is_sane          FOR TESTING.
    METHODS detail_title            FOR TESTING.
    METHODS detail_step_columns     FOR TESTING.
    METHODS detail_back_to_list     FOR TESTING.

    " --- job log ---
    METHODS joblog_button_wired      FOR TESTING.
    METHODS joblog_view_is_sane      FOR TESTING.
    METHODS joblog_back_to_steps     FOR TESTING.
    METHODS joblog_unknown_job       FOR TESTING.

ENDCLASS.


CLASS ltcl_sm37_a2u5 IMPLEMENTATION.

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

  METHOD given_joblist.
    mo_cut->mv_jobname = `*`.
    mo_cut->mt_jobs = VALUE #(
        ( jobname = `ZDEMO_JOB` jobcount = `12345600` status = `F`
          statustxt = `Finished` state = `Success` sdldate = `01.01.2024`
          sdltime = `01:00:00` strtdate = `01.01.2024` strttime = `01:00:05`
          enddate = `01.01.2024` endtime = `01:00:42` duration = `37`
          owner = `DEVELOPER` server = `s4h_S4H_00` periodic = `` )
        ( jobname = `ZFAILED_JOB` jobcount = `12345601` status = `A`
          statustxt = `Cancelled` state = `Error` sdldate = `01.01.2024`
          sdltime = `02:00:00` strtdate = `01.01.2024` strttime = `02:00:01`
          enddate = `01.01.2024` endtime = `02:00:03` duration = `2`
          owner = `DEVELOPER` server = `s4h_S4H_00` periodic = `X` ) ).
  ENDMETHOD.

  METHOD given_step_list.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `ZDEMO_JOB`.
    mo_cut->mt_steps   = VALUE #(
        ( stepcount = `1` progname = `ZDEMO_REPORT` variant = `WEEKLY`
          authcknam = `DEVELOPER` language = `E` status = `Finished` ) ).
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

  " ===================== job selection =====================

  METHOD list_is_sane.
    given_joblist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SM37 job selection` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_joblist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Simple Job Selection` ) >= 0 )
        msg = 'the original SM37 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    given_joblist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idJobName` ) >= 0 )
        msg = 'the selection block of the work area is empty' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Job Name` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `User Name` ) >= 0 )
        msg = 'the SM37 selection fields Job Name / User Name are missing' ).
  ENDMETHOD.

  METHOD list_all_status_values.
    " SM37 filters by job status - all five BTC states plus the catch-all
    " have to be offered, otherwise jobs silently disappear from the list
    given_joblist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `All statuses` ) ( `Scheduled` ) ( `Released` )
                                ( `Active` ) ( `Finished` ) ( `Cancelled` ) )
         INTO DATA(lv_status).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_status ) >= 0 )
          msg = |the status filter does not offer '{ lv_status }'| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_status_is_coloured.
    " the SAP GUI job overview colours the status - a cancelled job has to be
    " visually distinguishable, so the state has to be bound as well
    given_joblist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `ObjectStatus` ) >= 0 )
        msg = 'the job status is rendered as plain text instead of ObjectStatus' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{STATE}` ) >= 0 )
        msg = 'the status colour (state) is not bound - all jobs look alike' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_joblist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " the yellow Back arrow of the system function bar carries the event
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_joblist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_jobs.
    mo_cut->view_display( ).

    assert_shell_sane( `SM37 job selection without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `No jobs found for the selection.`.
    mo_cut->mv_msgtype = `Information`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `No jobs found for the selection.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original SM37 texts
    " of SAPLBTCH (RSMPTEXTS)
    given_joblist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Job` ) ( `Edit` ) ( `Goto` ) ( `Extras` )
                                ( `Settings` ) ( `System` ) ( `Help` )
                                ( `Job Overview` ) ( `Simple Job Selection` )
                                ( `Job details` ) ( `Release` ) ( `Job log` )
                                ( `Spool list` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original SM37 text '{ lv_text }' is missing| ).
    ENDLOOP.

    " releasing or cancelling a job must not even look possible here
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'disabled original functions carry no explaining tooltip' ).
  ENDMETHOD.

  " ===================== step list =====================

  METHOD detail_is_sane.
    given_step_list( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SM37 step list` ).
  ENDMETHOD.

  METHOD detail_title.
    given_step_list( ).
    mo_cut->view_detail( ).

    " T STEP_TITLE plus the job name as the hint of the title bar
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Step List Overview` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Job ZDEMO_JOB` ) >= 0 )
        msg = 'the step list does not carry the original SM37 title' ).
  ENDMETHOD.

  METHOD detail_step_columns.
    " program and variant are the two fields an operator looks for when a
    " job fails - both have to be bound
    given_step_list( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{PROGNAME}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{VARIANT}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{AUTHCKNAM}` ) >= 0 )
        msg = 'the step list is not bound to the job step structure' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_step_list( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the step list has no back navigation' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the step list leaves the app instead of returning to the job list' ).
  ENDMETHOD.


  METHOD joblog_button_wired.
    given_step_list( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `JOBLOG` )
        msg = 'Job log is not wired on the step list' ).
  ENDMETHOD.

  METHOD joblog_view_is_sane.
    given_step_list( ).
    mo_cut->mv_cur_jobcount = `12345678`.
    mo_cut->mt_joblog = VALUE #(
        ( enterdate = `02.10.2026` entertime = `10:00:00` msgtype = `S` state = `Success`
          text = `Job started` msgid = `00` msgno = `516` ) ).
    mo_cut->view_joblog( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Job Log Entries for ZDEMO_JOB / 12345678*` ).
    LOOP AT VALUE string_table( ( `{ENTERDATE}` ) ( `{ENTERTIME}` ) ( `{TEXT}` )
                                ( `{MSGID}` ) ( `{MSGNO}` ) ( `{MSGTYPE}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `BACK_TO_STEPS` ) ).
  ENDMETHOD.

  METHOD joblog_back_to_steps.
    given_step_list( ).
    mo_cut->mv_mode = `LOG`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_STEPS`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `DETAIL` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_false( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD joblog_unknown_job.
    given_step_list( ).
    mo_api->answer( iv_method = `GET_JOB_LOG` iv_param = `EV_MESSAGE` iv_key = `ZZLK05_NO_SUCH_JOB`
                    iv_value  = `Job ZZLK05_NO_SUCH_JOB does not exist.` ).
    mo_cut->mv_current      = `ZZLK05_NO_SUCH_JOB`.
    mo_cut->mv_cur_jobcount = `99999999`.
    mo_cut->do_joblog( ).
    cl_abap_unit_assert=>assert_equals( exp = `DETAIL` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

ENDCLASS.
