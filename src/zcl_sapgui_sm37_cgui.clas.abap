CLASS zcl_sapgui_sm37_cgui DEFINITION PUBLIC
  INHERITING FROM z2ui5_cl_cgui_report
  FINAL
  CREATE PUBLIC.

* ---------------------------------------------------------------------
*  SM37 - Job Overview, written on abap-cloud-gui (pilot)
*
*  The same transaction as ZCL_SAPGUI_SM37, as a classic report:
*  the selection screen of T JSL Simple Job Selection, the job list as
*  an ALV, a click on a job its step list, a click on a step the job
*  log - Back returns one level, as in the SAP GUI. The data comes
*  through ZCL_SAPGUI_SYS_API like every screen, the authorization
*  through ZCL_SAPGUI_AUTH.
*
*  What the report runtime brings and ZCL_SAPGUI_SM37 builds by hand:
*  the selection screen, the grid with sorting, filter, layouts and
*  export, the list levels and Back, the status bar messages, variants
*  of the selection. What it does not bring: the SAP GUI window of
*  ZCL_SAPGUI_FRAME (menu bar, system bar, Easy Access) - the report
*  runtime has its own shell - and the command field starts report
*  classes only, not the other screens of this repository.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    " selection screen - T JSL Simple Job Selection
    DATA p_jobname TYPE string.
    DATA p_user    TYPE string.
    DATA p_status  TYPE string.

    " the three list levels: jobs, the steps of one job, its log
    DATA mt_jobs   TYPE zcl_sapgui_sys_api=>ty_t_job.
    DATA mt_steps  TYPE zcl_sapgui_sys_api=>ty_t_jobstep.
    DATA mt_joblog TYPE zcl_sapgui_sys_api=>ty_t_joblog.

  PROTECTED SECTION.
    METHODS authority_check REDEFINITION.
    METHODS initialization REDEFINITION.
    METHODS selection_screen REDEFINITION.
    METHODS start_of_selection REDEFINITION.
    METHODS at_line_selection REDEFINITION.

  PRIVATE SECTION.
    " the job whose steps are shown - the job log is of this one
    DATA mv_jobname  TYPE string.
    DATA mv_jobcount TYPE string.

    METHODS show_steps
      IMPORTING
        is_job TYPE zcl_sapgui_sys_api=>ty_s_job.

    METHODS show_joblog.

ENDCLASS.


CLASS zcl_sapgui_sm37_cgui IMPLEMENTATION.

  METHOD authority_check.

    " S_TCODE and the basic check of SM37, as the router asks them
    DATA(ls_check) = zcl_sapgui_auth=>check_transaction( `SM37` ).
    IF ls_check-allowed = abap_false.
      message( text = ls_check-message
               type = `E` ).
    ENDIF.
    result = ls_check-allowed.

  ENDMETHOD.

  METHOD initialization.

    " T JOV_TITLE - Job Overview
    set_title( `Job Overview` ).
    p_jobname = `*`.
    p_user    = sy-uname.

  ENDMETHOD.

  METHOD selection_screen.

    screen->block_begin( `Simple Job Selection`
        )->parameter( val  = p_jobname
                      text = `Job Name`
        )->parameter( val  = p_user
                      text = `User Name`
        )->parameter( val        = p_status
                      text       = `Job Status`
                      as_listbox = abap_true
        )->block_end( ).

    screen->set_listbox_values( name   = `P_STATUS`
                                values = VALUE #( ( key = ``  text = `All statuses` )
                                                  ( key = `P` text = `Scheduled` )
                                                  ( key = `S` text = `Released` )
                                                  ( key = `R` text = `Active` )
                                                  ( key = `F` text = `Finished` )
                                                  ( key = `A` text = `Cancelled` ) ) ).

  ENDMETHOD.

  METHOD start_of_selection.

    mt_jobs = zcl_sapgui_sys_api=>get_jobs( iv_jobname = p_jobname
                                           iv_user    = p_user
                                           iv_status  = p_status ).
    IF mt_jobs IS INITIAL.
      message( text = `No jobs found for the selection criteria.`
               type = `W` ).
      RETURN.
    ENDIF.

    alv( mt_jobs
        )->set_title( `Job Overview`
        )->set_column_text( name = `JOBNAME`
                            text = `Job Name`
        )->set_column_text( name = `JOBCOUNT`
                            text = `Job Count`
        )->set_column_text( name = `STATUSTXT`
                            text = `Status`
        )->set_column_text( name = `SDLDATE`
                            text = `Planned Date`
        )->set_column_text( name = `SDLTIME`
                            text = `Planned Time`
        )->set_column_text( name = `STRTDATE`
                            text = `Start Date`
        )->set_column_text( name = `STRTTIME`
                            text = `Start Time`
        )->set_column_text( name = `ENDDATE`
                            text = `End Date`
        )->set_column_text( name = `ENDTIME`
                            text = `End Time`
        )->set_column_text( name = `DURATION`
                            text = `Duration (sec.)`
        )->set_column_text( name = `OWNER`
                            text = `Job Created By`
        )->set_column_text( name = `SERVER`
                            text = `Server`
        )->set_column_hidden( `STATUS`
        )->set_column_hidden( `STATE`
        )->set_line_selection( ).
    message( |{ lines( mt_jobs ) } job(s) selected.| ).

  ENDMETHOD.

  METHOD at_line_selection.

    " the level the click writes, as SY-LSIND in AT LINE-SELECTION: 1 for
    " a click on the job list - its steps -, 2 for one on the steps - the log
    IF lsind( ) <= 1.
      READ TABLE mt_jobs INTO DATA(ls_job) INDEX row.
      IF sy-subrc = 0.
        show_steps( ls_job ).
      ENDIF.
    ELSE.
      show_joblog( ).
    ENDIF.

  ENDMETHOD.

  METHOD show_steps.

    mv_jobname  = is_job-jobname.
    mv_jobcount = is_job-jobcount.
    mt_steps = zcl_sapgui_sys_api=>get_job_steps( iv_jobname  = is_job-jobname
                                                 iv_jobcount = is_job-jobcount ).
    IF mt_steps IS INITIAL.
      message( text = |Job { is_job-jobname } has no steps.|
               type = `W` ).
      RETURN.
    ENDIF.

    " T STEP_TITLE - Step List Overview
    alv( mt_steps
        )->set_title( |Step List Overview - { is_job-jobname } / { is_job-jobcount }|
        )->set_column_text( name = `STEPCOUNT`
                            text = `No.`
        )->set_column_text( name = `PROGNAME`
                            text = `Program Name`
        )->set_column_text( name = `VARIANT`
                            text = `Variant`
        )->set_column_text( name = `AUTHCKNAM`
                            text = `User`
        )->set_column_text( name = `LANGUAGE`
                            text = `Language`
        )->set_column_text( name = `STATUS`
                            text = `Status`
        )->set_line_selection( ).
    message( `Click a step for the job log.` ).

  ENDMETHOD.

  METHOD show_joblog.

    DATA lv_message TYPE string.

    zcl_sapgui_sys_api=>get_job_log( EXPORTING iv_jobname  = mv_jobname
                                               iv_jobcount = mv_jobcount
                                     IMPORTING et_log      = mt_joblog
                                               ev_message  = lv_message ).
    IF lv_message IS NOT INITIAL.
      message( text = lv_message
               type = `W` ).
      RETURN.
    ENDIF.

    alv( mt_joblog
        )->set_title( |Job Log Entries for { mv_jobname } / { mv_jobcount }|
        )->set_column_text( name = `ENTERDATE`
                            text = `Date`
        )->set_column_text( name = `ENTERTIME`
                            text = `Time`
        )->set_column_text( name = `TEXT`
                            text = `Message Text`
        )->set_column_text( name = `MSGID`
                            text = `Message Class`
        )->set_column_text( name = `MSGNO`
                            text = `No.`
        )->set_column_text( name = `MSGTYPE`
                            text = `Type`
        )->set_column_hidden( `STATE` ).
    message( |{ lines( mt_joblog ) } line(s) in the job log.| ).

  ENDMETHOD.

ENDCLASS.
