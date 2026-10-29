CLASS ltcl_sm37_cgui DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut  TYPE REF TO zcl_sapgui_sm37_cgui.
    DATA mo_dbl  TYPE REF TO zcl_sapgui_client_dbl.
    DATA mo_api  TYPE REF TO zcl_sapgui_sys_api_dbl.
    DATA mo_auth TYPE REF TO zcl_sapgui_auth_sys_dbl.

    METHODS setup.
    METHODS teardown.
    METHODS start.
    METHODS event
      IMPORTING iv_event TYPE string
                it_arg   TYPE string_table OPTIONAL.
    METHODS given_jobs.
    METHODS assert_view_has
      IMPORTING iv_text TYPE string
                iv_ctx  TYPE string.

    METHODS selection_screen_original  FOR TESTING.
    METHODS execute_lists_the_jobs     FOR TESTING.
    METHODS no_jobs_is_a_warning       FOR TESTING.
    METHODS click_on_job_lists_steps   FOR TESTING.
    METHODS click_on_step_shows_log    FOR TESTING.
    METHODS back_returns_to_the_jobs   FOR TESTING.
    METHODS no_authorization_no_data   FOR TESTING.

ENDCLASS.


CLASS ltcl_sm37_cgui IMPLEMENTATION.

  METHOD setup.
    mo_api  = zcl_sapgui_sys_api_dbl=>install( ).
    mo_auth = zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut  = NEW #( ).
    mo_dbl  = NEW #( ).
    mo_dbl->mo_app = mo_cut.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD start.
    mo_dbl->mv_on_init = abap_true.
    mo_cut->z2ui5_if_app~main( mo_dbl ).
    mo_dbl->mv_on_init  = abap_false.
    mo_dbl->mv_on_event = abap_true.
  ENDMETHOD.

  METHOD event.
    mo_dbl->ms_get-event       = iv_event.
    mo_dbl->ms_get-t_event_arg = it_arg.
    mo_cut->z2ui5_if_app~main( mo_dbl ).
  ENDMETHOD.

  METHOD given_jobs.
    mo_api->answer( iv_method = `GET_JOBS`
                    iv_value  = VALUE zcl_sapgui_sys_api=>ty_t_job(
                        ( jobname = `ZDEMO_JOB` jobcount = `12345600` status = `F`
                          statustxt = `Finished` state = `Success` owner = `DEVELOPER` )
                        ( jobname = `ZFAILED_JOB` jobcount = `12345601` status = `A`
                          statustxt = `Cancelled` state = `Error` owner = `DEVELOPER` ) ) ).
    mo_api->answer( iv_method = `GET_JOB_STEPS`
                    iv_value  = VALUE zcl_sapgui_sys_api=>ty_t_jobstep(
                        ( stepcount = `1` progname = `ZDEMO_REPORT` variant = `WEEKLY`
                          authcknam = `DEVELOPER` language = `E` status = `Finished` ) ) ).
    mo_api->answer( iv_method = `GET_JOB_LOG`
                    iv_param  = `ET_LOG`
                    iv_value  = VALUE zcl_sapgui_sys_api=>ty_t_joblog(
                        ( enterdate = `01.01.2024` entertime = `01:00:05` msgtype = `S`
                          text = `Job started` msgid = `00` msgno = `516` ) ) ).
  ENDMETHOD.

  METHOD assert_view_has.
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = iv_text ) >= 0 )
        msg = |{ iv_ctx }: "{ iv_text }" is not in the view| ).
  ENDMETHOD.

  METHOD selection_screen_original.
    start( ).

    " T JOV_TITLE and T JSL of the original, its three fields
    assert_view_has( iv_text = `Job Overview`         iv_ctx = `selection screen` ).
    assert_view_has( iv_text = `Simple Job Selection` iv_ctx = `selection screen` ).
    assert_view_has( iv_text = `Job Name`             iv_ctx = `selection screen` ).
    assert_view_has( iv_text = `User Name`            iv_ctx = `selection screen` ).
    assert_view_has( iv_text = `Cancelled`            iv_ctx = `the status listbox` ).
    cl_abap_unit_assert=>assert_equals( exp = `*`
                                        act = mo_cut->p_jobname ).
  ENDMETHOD.

  METHOD execute_lists_the_jobs.
    given_jobs( ).
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( mo_cut->mt_jobs ) ).
    assert_view_has( iv_text = `Job Created By` iv_ctx = `job list` ).
    " the rows are bound - the view names the columns
    assert_view_has( iv_text = `Duration (sec.)` iv_ctx = `job list` ).
  ENDMETHOD.

  METHOD no_jobs_is_a_warning.
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_initial( mo_cut->mt_jobs ).
    assert_view_has( iv_text = `No jobs found for the selection criteria.` iv_ctx = `empty selection` ).
  ENDMETHOD.

  METHOD click_on_job_lists_steps.
    given_jobs( ).
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( iv_event = z2ui5_cl_cgui_alv=>cs_event-line_selection
           it_arg   = VALUE #( ( `/XX/MT_JOBS/0` ) ) ).

    cl_abap_unit_assert=>assert_true( mo_api->was_called( `GET_JOB_STEPS` ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1
                                        act = lines( mo_cut->mt_steps ) ).
    assert_view_has( iv_text = `Step List Overview - ZDEMO_JOB / 12345600` iv_ctx = `step list` ).
  ENDMETHOD.

  METHOD click_on_step_shows_log.
    given_jobs( ).
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( iv_event = z2ui5_cl_cgui_alv=>cs_event-line_selection
           it_arg   = VALUE #( ( `/XX/MT_JOBS/0` ) ) ).
    event( iv_event = z2ui5_cl_cgui_alv=>cs_event-line_selection
           it_arg   = VALUE #( ( `/XX/MT_STEPS/0` ) ) ).

    cl_abap_unit_assert=>assert_true( mo_api->was_called( `GET_JOB_LOG` ) ).
    assert_view_has( iv_text = `Job Log Entries for ZDEMO_JOB / 12345600` iv_ctx = `job log` ).
    assert_view_has( iv_text = `Message Text` iv_ctx = `job log` ).
  ENDMETHOD.

  METHOD back_returns_to_the_jobs.
    given_jobs( ).
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).
    event( iv_event = z2ui5_cl_cgui_alv=>cs_event-line_selection
           it_arg   = VALUE #( ( `/XX/MT_JOBS/0` ) ) ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-back ).

    assert_view_has( iv_text = `Job Created By` iv_ctx = `back from the steps` ).
    cl_abap_unit_assert=>assert_equals( exp = -1
                                        act = find( val = mo_dbl->mv_view sub = `Step List Overview` )
                                        msg = `Back still shows the step list` ).
  ENDMETHOD.

  METHOD no_authorization_no_data.
    given_jobs( ).
    mo_auth->deny( `S_TCODE` ).
    start( ).
    event( z2ui5_cl_cgui_report=>cs_ucomm-execute ).

    cl_abap_unit_assert=>assert_false( mo_api->was_called( `GET_JOBS` ) ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_jobs ).
  ENDMETHOD.

ENDCLASS.
