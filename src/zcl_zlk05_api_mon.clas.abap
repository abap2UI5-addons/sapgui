CLASS zcl_zlk05_api_mon DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - Monitoring (SM37/ST22/SM50/SM12/ST02/SM21/ST05)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_ZLK05_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    CLASS-METHODS get_jobs
      IMPORTING iv_jobname    TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_job.

    CLASS-METHODS get_job_steps
      IMPORTING iv_jobname    TYPE string
                iv_jobcount   TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_jobstep.


    CLASS-METHODS get_dumps
      IMPORTING iv_date_from  TYPE d OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_dump.

    CLASS-METHODS get_dump_detail
      IMPORTING iv_datum      TYPE d
                iv_uzeit      TYPE t
                iv_modno      TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_kv.

    CLASS-METHODS get_work_processes
      EXPORTING et_wp         TYPE zcl_zlk05_sys_api=>ty_t_wp
                ev_message    TYPE string.

    CLASS-METHODS get_locks
      IMPORTING iv_table      TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
      EXPORTING et_locks      TYPE zcl_zlk05_sys_api=>ty_t_lock
                ev_message    TYPE string.

    CLASS-METHODS get_buffer_stats
      EXPORTING et_buffer     TYPE zcl_zlk05_sys_api=>ty_t_buffer
                et_memory     TYPE zcl_zlk05_sys_api=>ty_t_kv
                ev_message    TYPE string.

    CLASS-METHODS get_syslog
      IMPORTING iv_date_from  TYPE d OPTIONAL
                iv_time_from  TYPE t OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_time_to    TYPE t OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_tcode      TYPE string OPTIONAL
      EXPORTING et_syslog     TYPE zcl_zlk05_sys_api=>ty_t_syslog
                ev_message    TYPE string.

    "! ST05 trace evaluation is a kernel service without a released
    "! read API. This returns the trace relevant profile parameters so
    "! the app can show the current trace configuration.
    CLASS-METHODS get_trace_status
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_kv.

    "! Reads the real trace state of the own application server instance
    "! via ST05_GET_TRACE_STATE. Display only - it never switches a trace
    "! on or off.
    CLASS-METHODS get_trace_state
      EXPORTING es_state   TYPE zcl_zlk05_sys_api=>ty_s_trace_state
                ev_message TYPE string.

    "! Logs of BALHDR the user may display (S_APPL_LOG per object)
    CLASS-METHODS get_app_logs
      IMPORTING iv_object     TYPE string OPTIONAL
                iv_subobject  TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_applog.

    "! Messages of one log via the released API CL_BALI_LOG_DB
    CLASS-METHODS get_app_log_messages
      IMPORTING iv_lognumber  TYPE string
      EXPORTING et_messages   TYPE zcl_zlk05_sys_api=>ty_t_applog_msg
                ev_message    TYPE string.

    "! Severity of a message -> text and UI5 value state
    CLASS-METHODS severity_text
      IMPORTING iv_severity   TYPE symsgty
      EXPORTING ev_text       TYPE string
                ev_state      TYPE string.

    "! Users logged on to the own instance (TH_USER_LIST)
    CLASS-METHODS get_user_sessions
      EXPORTING et_sessions TYPE zcl_zlk05_sys_api=>ty_t_session
                ev_message  TYPE string.

    "! Job log of one job (BP_JOBLOG_READ)
    CLASS-METHODS get_job_log
      IMPORTING iv_jobname  TYPE string
                iv_jobcount TYPE string
      EXPORTING et_log      TYPE zcl_zlk05_sys_api=>ty_t_joblog
                ev_message  TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
    CLASS-METHODS job_status_text
      IMPORTING iv_status     TYPE btcstatus
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS job_state_text
      IMPORTING iv_status     TYPE btcstatus
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_zlk05_api_mon IMPLEMENTATION.


  METHOD get_jobs.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_jobname ).
    DATA(lv_user) = zcl_zlk05_sys_api=>to_like_pattern( iv_user ).
    DATA(lv_stat) = CONV btcstatus( to_upper( condense( iv_status ) ) ).

    SELECT jobname, jobcount, status, sdldate, sdltime,
           strtdate, strttime, enddate, endtime,
           sdluname, execserver, periodic
      FROM tbtco
      WHERE jobname   LIKE @lv_like ESCAPE '#'
        AND sdluname  LIKE @lv_user ESCAPE '#'
        AND ( status = @lv_stat OR @lv_stat = '' )
      ORDER BY sdldate DESCENDING, sdltime DESCENDING
      INTO TABLE @DATA(lt_jobs)
      UP TO @iv_max ROWS.

    LOOP AT lt_jobs ASSIGNING FIELD-SYMBOL(<j>).

      DATA(lv_dur) = ``.
      IF <j>-strtdate IS NOT INITIAL AND <j>-enddate IS NOT INITIAL.
        DATA(lv_secs) = ( <j>-enddate - <j>-strtdate ) * 86400
                      + ( <j>-endtime - <j>-strttime ).
        IF lv_secs >= 0.
          lv_dur = |{ lv_secs } s|.
        ENDIF.
      ENDIF.

      APPEND VALUE #( jobname   = <j>-jobname
                      jobcount  = <j>-jobcount
                      status    = <j>-status
                      statustxt = job_status_text( <j>-status )
                      state     = job_state_text( <j>-status )
                      sdldate   = zcl_zlk05_sys_api=>format_date( <j>-sdldate )
                      sdltime   = zcl_zlk05_sys_api=>format_time( <j>-sdltime )
                      strtdate  = zcl_zlk05_sys_api=>format_date( <j>-strtdate )
                      strttime  = zcl_zlk05_sys_api=>format_time( <j>-strttime )
                      enddate   = zcl_zlk05_sys_api=>format_date( <j>-enddate )
                      endtime   = zcl_zlk05_sys_api=>format_time( <j>-endtime )
                      duration  = lv_dur
                      owner     = <j>-sdluname
                      server    = <j>-execserver
                      periodic  = COND string( WHEN <j>-periodic = 'X'
                                               THEN `X` ELSE `` ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD job_status_text.

    result = SWITCH string( iv_status
               WHEN 'P' THEN `Scheduled`
               WHEN 'S' THEN `Released`
               WHEN 'A' THEN `Cancelled`
               WHEN 'R' THEN `Active`
               WHEN 'F' THEN `Finished`
               WHEN 'Y' THEN `Ready`
               WHEN 'Z' THEN `Put active`
               WHEN 'X' THEN `Unknown`
               ELSE CONV string( iv_status ) ).

  ENDMETHOD.

  METHOD job_state_text.

    " Maps to a UI5 ObjectStatus state
    result = SWITCH string( iv_status
               WHEN 'A' THEN `Error`
               WHEN 'F' THEN `Success`
               WHEN 'R' THEN `Warning`
               ELSE `None` ).

  ENDMETHOD.

  METHOD get_job_steps.

    DATA(lv_name)  = CONV btcjob( to_upper( condense( iv_jobname ) ) ).
    DATA(lv_count) = CONV btcjobcnt( condense( iv_jobcount ) ).

    SELECT stepcount, progname, variant, authcknam, language, status
      FROM tbtcp
      WHERE jobname  = @lv_name
        AND jobcount = @lv_count
      ORDER BY stepcount
      INTO TABLE @DATA(lt_steps).

    LOOP AT lt_steps ASSIGNING FIELD-SYMBOL(<s>).
      APPEND VALUE #( stepcount = |{ <s>-stepcount }|
                      progname  = <s>-progname
                      variant   = <s>-variant
                      authcknam = <s>-authcknam
                      language  = <s>-language
                      status    = job_status_text( <s>-status ) ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_dumps.

    DATA(lv_from) = iv_date_from.
    IF lv_from IS INITIAL.
      lv_from = sy-datum - 7.
    ENDIF.
    DATA(lv_user) = zcl_zlk05_sys_api=>to_like_pattern( iv_user ).

    SELECT datum, uzeit, uname, mandt, ahost, modno, flist
      FROM snap
      WHERE seqno  = '000'
        AND datum >= @lv_from
        AND uname LIKE @lv_user ESCAPE '#'
      ORDER BY datum DESCENDING, uzeit DESCENDING
      INTO TABLE @DATA(lt_snap)
      UP TO @iv_max ROWS.

    LOOP AT lt_snap ASSIGNING FIELD-SYMBOL(<s>).

      DATA(lt_tags) = zcl_zlk05_sys_api=>parse_flist( CONV string( <s>-flist ) ).

      APPEND VALUE #(
        datum    = zcl_zlk05_sys_api=>format_date( <s>-datum )
        uzeit    = zcl_zlk05_sys_api=>format_time( <s>-uzeit )
        uname    = <s>-uname
        mandt    = <s>-mandt
        ahost    = <s>-ahost
        modno    = condense( CONV string( <s>-modno ) )
        errorid  = VALUE #( lt_tags[ label = `FC` ]-value OPTIONAL )
        program  = VALUE #( lt_tags[ label = `AP` ]-value OPTIONAL )
        incl     = VALUE #( lt_tags[ label = `AI` ]-value OPTIONAL )
        line     = VALUE #( lt_tags[ label = `AL` ]-value OPTIONAL )
        key_date = <s>-datum
        key_time = <s>-uzeit
        key_mod  = condense( CONV string( <s>-modno ) ) ) TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD get_dump_detail.

    DATA lv_modno TYPE snap-modno.

    lv_modno = iv_modno.

    SELECT flist, flist02, flist03, flist04
      FROM snap
      WHERE datum = @iv_datum
        AND uzeit = @iv_uzeit
        AND modno = @lv_modno
        AND seqno = '000'
      INTO TABLE @DATA(lt_snap)
      UP TO 1 ROWS.

    IF lines( lt_snap ) = 0.
      RETURN.
    ENDIF.

    DATA(lv_all) = |{ lt_snap[ 1 ]-flist }{ lt_snap[ 1 ]-flist02 }| &&
                   |{ lt_snap[ 1 ]-flist03 }{ lt_snap[ 1 ]-flist04 }|.

    DATA(lt_tags) = zcl_zlk05_sys_api=>parse_flist( lv_all ).

    " Map the technical tags to readable labels, keep the rest as-is
    LOOP AT lt_tags ASSIGNING FIELD-SYMBOL(<t>).
      APPEND VALUE #(
        label = SWITCH string( <t>-label
                  WHEN `FC` THEN `Runtime Error`
                  WHEN `AP` THEN `Program`
                  WHEN `AI` THEN `Include`
                  WHEN `AL` THEN `Source Line`
                  WHEN `NX` THEN `Instance`
                  WHEN `TD` THEN `Terminated Session`
                  ELSE |Tag { <t>-label }| )
        value = <t>-value ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_work_processes.

    DATA lt_wplist   TYPE STANDARD TABLE OF wpinfo WITH EMPTY KEY.
    DATA lv_with_cpu TYPE tskh_dummy-with_cpu.

    CLEAR: et_wp, ev_message.

    " The kernel parameter is not an integer - a literal 1 would end up in
    " CX_SY_DYN_CALL_ILLEGAL_TYPE, so use the declared DDIC type.
    lv_with_cpu = 1.

    CALL FUNCTION 'TH_WPINFO'
      EXPORTING
        with_cpu   = lv_with_cpu
      TABLES
        wplist     = lt_wplist
      EXCEPTIONS
        send_error = 1
        OTHERS     = 2.

    IF sy-subrc <> 0.
      ev_message = `Work process list could not be read from the dispatcher.`.
      RETURN.
    ENDIF.

    IF lines( lt_wplist ) = 0.
      ev_message = `No work process data returned. ` &&
                   `TH_WPINFO requires S_ADMI_FCD authorization for SM50.`.
      RETURN.
    ENDIF.

    LOOP AT lt_wplist ASSIGNING FIELD-SYMBOL(<w>).
      APPEND VALUE #( wp_no     = |{ <w>-wp_no }|
                      wp_typ    = <w>-wp_typ
                      wp_pid    = <w>-wp_pid
                      wp_status = <w>-wp_status
                      wp_reason = <w>-wp_waiting
                      wp_start  = <w>-wp_restart
                      wp_err    = <w>-wp_dumps
                      wp_sem    = <w>-wp_sem
                      wp_cpu    = <w>-wp_cpu
                      wp_time   = <w>-wp_eltime
                      wp_report = <w>-wp_report
                      wp_client = <w>-wp_mandt
                      wp_user   = <w>-wp_bname
                      wp_action = <w>-wp_action
                      wp_table  = <w>-wp_table ) TO et_wp.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_locks.

    DATA lt_enq   TYPE STANDARD TABLE OF seqg3 WITH EMPTY KEY.
    DATA lv_gname TYPE seqg3-gname.
    DATA lv_user  TYPE seqg3-guname.

    CLEAR: et_locks, ev_message.

    lv_gname = to_upper( condense( iv_table ) ).
    lv_user  = to_upper( condense( iv_user ) ).

    CALL FUNCTION 'ENQUEUE_READ'
      EXPORTING
        gclient               = sy-mandt
        gname                 = lv_gname
        guname                = lv_user
      TABLES
        enq                   = lt_enq
      EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3.

    IF sy-subrc <> 0.
      ev_message = `Lock table could not be read from the enqueue server.`.
      RETURN.
    ENDIF.

    IF lines( lt_enq ) = 0.
      ev_message = `No lock entries found for the current selection.`.
      RETURN.
    ENDIF.

    LOOP AT lt_enq ASSIGNING FIELD-SYMBOL(<e>).
      APPEND VALUE #( guname   = <e>-guname
                      gclient  = <e>-gclient
                      gname    = <e>-gname
                      garg     = <e>-garg
                      gmode    = <e>-gmode
                      gusecnt  = |{ <e>-guse }|
                      gbcktype = COND string( WHEN <e>-gbcktype = 'X'
                                              THEN `X` ELSE `` )
                      gtdate   = <e>-gtdate
                      gttime   = <e>-gttime
                      gthost   = <e>-gthost ) TO et_locks.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_buffer_stats.

    DATA lt_buf   TYPE STANDARD TABLE OF tunehdwq WITH EMPTY KEY.
    DATA ls_roll  TYPE rlpg_stat.
    DATA ls_page  TYPE rlpg_stat.
    DATA ls_em    TYPE emstatusag.
    DATA ls_heap  TYPE hpstatusag.

    CLEAR: et_buffer, et_memory, ev_message.

    CALL FUNCTION 'SAPTUNE_GET_SUMMARY_STATISTIC'
      IMPORTING
        roll_area             = ls_roll
        paging_area           = ls_page
        extended_memory_usage = ls_em
        heap_memory_usage     = ls_heap
      TABLES
        buffer_statistic      = lt_buf
      EXCEPTIONS
        no_authorization      = 1
        OTHERS                = 2.

    IF sy-subrc <> 0.
      ev_message = `Buffer statistics are not available ` &&
                   `(missing authorization or statistics switched off).`.
      RETURN.
    ENDIF.

    LOOP AT lt_buf ASSIGNING FIELD-SYMBOL(<b>).
      APPEND VALUE #( name       = <b>-name
                      hitratio   = |{ <b>-hitratio }|
                      alloc_size = |{ <b>-alloc_size }|
                      free_space = |{ <b>-avail_size }|
                      dir_used   = |{ <b>-act_objcts }|
                      dir_free   = |{ <b>-max_objcts }|
                      swaps      = |{ <b>-swap }|
                      db_access  = |{ <b>-db_access }| ) TO et_buffer.
    ENDLOOP.

    et_memory = VALUE #(
      ( label = `Roll area size (kB)`       value = |{ ls_roll-area_size }| )
      ( label = `Roll area used (kB)`       value = |{ ls_roll-curr_used }| )
      ( label = `Roll area max used (kB)`   value = |{ ls_roll-max_used }| )
      ( label = `Paging area size (kB)`     value = |{ ls_page-area_size }| )
      ( label = `Paging area used (kB)`     value = |{ ls_page-curr_used }| )
      ( label = `Paging max used (kB)`      value = |{ ls_page-max_used }| )
      ( label = `Extended memory total (kB)` value = |{ ls_em-total }| )
      ( label = `Extended memory used (kB)` value = |{ ls_em-used }| )
      ( label = `Extended memory allocated` value = |{ ls_em-allocated }| )
      ( label = `Heap memory total (kB)`    value = |{ ls_heap-total }| )
      ( label = `Heap memory used (kB)`     value = |{ ls_heap-used }| ) ).

  ENDMETHOD.

  METHOD get_syslog.

    DATA lt_top     TYPE STANDARD TABLE OF kernelstat WITH EMPTY KEY.
    DATA lt_outline TYPE STANDARD TABLE OF ibd_sapmsm2101_alv WITH EMPTY KEY.
    DATA lt_content TYPE STANDARD TABLE OF ibd_sapmsm2103_alv WITH EMPTY KEY.

    CLEAR: et_syslog, ev_message.

    DATA(lv_from_d) = iv_date_from.
    IF lv_from_d IS INITIAL.
      lv_from_d = sy-datum.
    ENDIF.
    DATA(lv_to_d) = iv_date_to.
    IF lv_to_d IS INITIAL.
      lv_to_d = sy-datum.
    ENDIF.
    DATA(lv_to_t) = iv_time_to.
    IF lv_to_t IS INITIAL.
      lv_to_t = '235959'.
    ENDIF.

    DATA lv_user  TYPE sy-uname.
    DATA lv_tcode TYPE rslgtype-tcode.
    lv_user  = to_upper( condense( iv_user ) ).
    lv_tcode = to_upper( condense( iv_tcode ) ).

    CALL FUNCTION 'RSLG_ITSAM_READ_SYSLOG_ALV'
      EXPORTING
        from_date          = lv_from_d
        from_time          = iv_time_from
        to_date            = lv_to_d
        to_time            = lv_to_t
        looking_for_user   = lv_user
        tcode              = lv_tcode
      TABLES
        ext_gt_top         = lt_top
        ext_gt_gen_outline = lt_outline
        ext_gt_contents    = lt_content
      EXCEPTIONS
        invalid_date_time  = 1
        problem_detected   = 2
        OTHERS             = 3.

    IF sy-subrc <> 0.
      ev_message = `System log could not be read ` &&
                   `(invalid selection or log file not accessible).`.
      RETURN.
    ENDIF.

    DATA lv_logdate TYPE d.

    LOOP AT lt_outline ASSIGNING FIELD-SYMBOL(<l>).
      lv_logdate = <l>-date.
      APPEND VALUE #( date   = zcl_zlk05_sys_api=>format_date( lv_logdate )
                      time   = CONV string( <l>-time )
                      instid = <l>-instid
                      task   = <l>-task
                      mand   = <l>-mand
                      user   = <l>-user
                      tcode  = <l>-transcode
                      repna  = <l>-repna
                      clasid = <l>-clasid
                      text   = <l>-text ) TO et_syslog.
    ENDLOOP.

    IF lines( et_syslog ) = 0.
      ev_message = `No system log entries for the selected period.`.
    ENDIF.

  ENDMETHOD.

  METHOD get_trace_status.

    result = VALUE #(
      ( label = `Instance (rdisp/myname)`
        value = zcl_zlk05_api_adm=>get_param_value( `rdisp/myname` ) )
      ( label = `Trace Directory (DIR_ATRA)`
        value = zcl_zlk05_api_adm=>get_param_value( `DIR_ATRA` ) )
      ( label = `SQL Trace Ring Buffer (rstr/buffer_size_kB)`
        value = zcl_zlk05_api_adm=>get_param_value( `rstr/buffer_size_kB` ) )
      ( label = `Maximum Trace File Size (rstr/max_filesize_MB)`
        value = zcl_zlk05_api_adm=>get_param_value( `rstr/max_filesize_MB` ) )
      ( label = `Number of Trace Files (rstr/max_files)`
        value = zcl_zlk05_api_adm=>get_param_value( `rstr/max_files` ) )
      ( label = `Maximum Disk Space (rstr/max_diskspace)`
        value = zcl_zlk05_api_adm=>get_param_value( `rstr/max_diskspace` ) )
      ( label = `Accept Remote Trace (rstr/accept_remote_trace)`
        value = zcl_zlk05_api_adm=>get_param_value( `rstr/accept_remote_trace` ) )
      ( label = `Table Buffer Trace (rsdb/staton)`
        value = zcl_zlk05_api_adm=>get_param_value( `rsdb/staton` ) )
      ( label = `Developer Trace Level (rdisp/TRACE)`
        value = zcl_zlk05_api_adm=>get_param_value( `rdisp/TRACE` ) ) ).

    " a parameter that carries no value is not set - say so instead of
    " leaving an empty cell that reads like a failed read
    LOOP AT result ASSIGNING FIELD-SYMBOL(<r>).
      IF <r>-value IS INITIAL.
        <r>-value = `(not set)`.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_trace_state.

    CLEAR: es_state, ev_message.

    DATA ls_raw TYPE st05_trace_state.

    CALL FUNCTION 'ST05_GET_TRACE_STATE'
      IMPORTING
        trace_state  = ls_raw
      EXCEPTIONS
        no_authority = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      es_state-state_known = abap_false.
      es_state-state_text  = `Trace state of this instance could not be read`.
      IF sy-subrc = 1.
        ev_message = `You are not authorized to read the trace state ` &&
                     `(ST05_GET_TRACE_STATE, NO_AUTHORITY).`.
      ELSE.
        ev_message = |ST05_GET_TRACE_STATE returned { sy-subrc }.|.
      ENDIF.
      RETURN.
    ENDIF.

    es_state-state_known = abap_true.

    " the trace type flags sit in the named sub structure TRACE_TYPES
    es_state-sql_on  = xsdbool( ls_raw-trace_types-sql_on IS NOT INITIAL ).
    es_state-buf_on  = xsdbool( ls_raw-trace_types-buf_on IS NOT INITIAL ).
    es_state-enq_on  = xsdbool( ls_raw-trace_types-enq_on IS NOT INITIAL ).
    es_state-rfc_on  = xsdbool( ls_raw-trace_types-rfc_on IS NOT INITIAL ).
    es_state-http_on = xsdbool( ls_raw-trace_types-http_on IS NOT INITIAL ).
    es_state-amc_on  = xsdbool( ls_raw-trace_types-amc_on IS NOT INITIAL ).
    es_state-apc_on  = xsdbool( ls_raw-trace_types-apc_on IS NOT INITIAL ).
    es_state-auth_on = xsdbool( ls_raw-trace_types-auth_on IS NOT INITIAL ).
    es_state-stack_on     = xsdbool( ls_raw-stack_trace_on IS NOT INITIAL ).
    es_state-progress_on  = xsdbool( ls_raw-progress_indicator_on IS NOT INITIAL ).
    es_state-filter_on    = xsdbool( ls_raw-filter_on IS NOT INITIAL ).
    es_state-incl_missing = xsdbool( ls_raw-include_missing_table_name_on IS NOT INITIAL ).

    es_state-trace_user   = ls_raw-trace_user.
    es_state-tcode        = ls_raw-transaction_code.
    es_state-program      = ls_raw-program.
    es_state-rfc_function = ls_raw-rfc_function.
    es_state-url          = ls_raw-url.
    es_state-wp_id        = ls_raw-wp_id.
    es_state-mod_user     = ls_raw-modification_user.

    IF ls_raw-modification_date IS NOT INITIAL.
      es_state-mod_date = zcl_zlk05_sys_api=>format_date( ls_raw-modification_date ).
      es_state-mod_time = zcl_zlk05_sys_api=>format_time( ls_raw-modification_time ).
    ENDIF.

    LOOP AT ls_raw-included_tables INTO DATA(lv_incl).
      es_state-incl_tables = COND #( WHEN es_state-incl_tables IS INITIAL THEN |{ lv_incl }|
                                     ELSE |{ es_state-incl_tables }, { lv_incl }| ).
    ENDLOOP.

    LOOP AT ls_raw-excluded_tables INTO DATA(lv_excl).
      es_state-excl_tables = COND #( WHEN es_state-excl_tables IS INITIAL THEN |{ lv_excl }|
                                     ELSE |{ es_state-excl_tables }, { lv_excl }| ).
    ENDLOOP.

    " which trace types are recording right now?
    DATA lt_active TYPE string_table.

    IF es_state-sql_on  = abap_true.
      APPEND `SQL Trace`     TO lt_active.
    ENDIF.
    IF es_state-buf_on  = abap_true.
      APPEND `Buffer Trace`  TO lt_active.
    ENDIF.
    IF es_state-enq_on  = abap_true.
      APPEND `Enqueue Trace` TO lt_active.
    ENDIF.
    IF es_state-rfc_on  = abap_true.
      APPEND `RFC Trace`     TO lt_active.
    ENDIF.
    IF es_state-http_on = abap_true.
      APPEND `HTTP Trace`    TO lt_active.
    ENDIF.
    IF es_state-amc_on  = abap_true.
      APPEND `AMC Trace`     TO lt_active.
    ENDIF.
    IF es_state-apc_on  = abap_true.
      APPEND `APC trace`     TO lt_active.
    ENDIF.

    IF lt_active IS INITIAL.
      es_state-any_on     = abap_false.
      es_state-state_text = `Trace is switched off`.
    ELSE.
      es_state-any_on = abap_true.
      LOOP AT lt_active INTO DATA(lv_act).
        es_state-state_text = COND #( WHEN es_state-state_text IS INITIAL THEN lv_act
                                      ELSE |{ es_state-state_text }, { lv_act }| ).
      ENDLOOP.
      es_state-state_text = |Trace is switched on: { es_state-state_text }|.
      IF es_state-mod_user IS NOT INITIAL.
        es_state-state_text = |{ es_state-state_text } | &&
                              |(switched on by { es_state-mod_user } | &&
                              |{ es_state-mod_date } { es_state-mod_time })|.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD get_app_logs.

    DATA lv_from TYPE d.
    DATA lv_to   TYPE d.

    DATA(lv_object) = zcl_zlk05_sys_api=>to_like_pattern( iv_object ).
    DATA(lv_subobj) = zcl_zlk05_sys_api=>to_like_pattern( iv_subobject ).
    DATA(lv_user)   = zcl_zlk05_sys_api=>to_like_pattern( iv_user ).
    lv_from = COND #( WHEN iv_date_from IS INITIAL THEN '19000101' ELSE iv_date_from ).
    lv_to   = COND #( WHEN iv_date_to   IS INITIAL THEN '99991231' ELSE iv_date_to ).

    " more rows than shown are read: logs the user may not see are dropped
    " afterwards, and the list should still be full
    DATA(lv_read) = iv_max * 3.

    SELECT lognumber, object, subobject, extnumber, aldate, altime, aluser,
           altcode, alprog, msg_cnt_al, msg_cnt_e, msg_cnt_a, msg_cnt_w, log_handle
      FROM balhdr
      WHERE object    LIKE @lv_object ESCAPE '#'
        AND subobject LIKE @lv_subobj ESCAPE '#'
        AND aluser    LIKE @lv_user ESCAPE '#'
        AND aldate    BETWEEN @lv_from AND @lv_to
      ORDER BY aldate DESCENDING, altime DESCENDING, lognumber DESCENDING
      INTO TABLE @DATA(lt_hdr)
      UP TO @lv_read ROWS.

    LOOP AT lt_hdr ASSIGNING FIELD-SYMBOL(<h>).
      " like SLG1: a log is only shown with S_APPL_LOG for its object
      IF zcl_zlk05_auth=>check_appl_log( iv_object    = CONV string( <h>-object )
                                         iv_subobject = CONV string( <h>-subobject ) )-allowed = abap_false.
        CONTINUE.
      ENDIF.

      DATA(lv_err) = CONV i( <h>-msg_cnt_e + <h>-msg_cnt_a ).
      APPEND VALUE #(
        lognumber = condense( CONV string( <h>-lognumber ) )
        object    = <h>-object
        subobject = <h>-subobject
        extnumber = <h>-extnumber
        aldate    = zcl_zlk05_sys_api=>format_date( <h>-aldate )
        altime    = zcl_zlk05_sys_api=>format_time( <h>-altime )
        aluser    = <h>-aluser
        altcode   = <h>-altcode
        alprog    = <h>-alprog
        msg_all   = condense( CONV string( <h>-msg_cnt_al ) )
        msg_err   = condense( CONV string( lv_err ) )
        msg_warn  = condense( CONV string( <h>-msg_cnt_w ) )
        handle    = <h>-log_handle
        state     = COND #( WHEN lv_err > 0         THEN `Error`
                            WHEN <h>-msg_cnt_w > 0  THEN `Warning`
                            ELSE `Success` ) ) TO result.

      IF lines( result ) >= iv_max.
        EXIT.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_app_log_messages.

    CLEAR: et_messages, ev_message.

    DATA lv_lognumber TYPE balognr.
    lv_lognumber = |{ iv_lognumber ALPHA = IN }|.

    SELECT SINGLE object, subobject, log_handle FROM balhdr
      WHERE lognumber = @lv_lognumber
      INTO @DATA(ls_hdr).
    IF sy-subrc <> 0.
      ev_message = |Log { iv_lognumber } does not exist.|.
      RETURN.
    ENDIF.

    " the messages are as protected as the log header
    DATA(ls_auth) = zcl_zlk05_auth=>check_appl_log( iv_object    = CONV string( ls_hdr-object )
                                                   iv_subobject = CONV string( ls_hdr-subobject ) ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    TRY.
        DATA(lo_log) = cl_bali_log_db=>get_instance( )->load_log( handle = ls_hdr-log_handle ).
        LOOP AT lo_log->get_all_items( ) INTO DATA(ls_item).
          severity_text( EXPORTING iv_severity = ls_item-item->severity
                         IMPORTING ev_text     = DATA(lv_sevtext)
                                   ev_state    = DATA(lv_state) ).
          APPEND VALUE #(
            msgno    = condense( CONV string( ls_item-log_item_number ) )
            severity = ls_item-item->severity
            sevtext  = lv_sevtext
            state    = lv_state
            text     = ls_item-item->get_message_text( )
            tstamp   = |{ ls_item-item->timestamp TIMESTAMP = SPACE }| ) TO et_messages.
        ENDLOOP.
      CATCH cx_bali_runtime INTO DATA(lx).
        ev_message = lx->get_text( ).
    ENDTRY.

  ENDMETHOD.


  METHOD severity_text.

    CASE iv_severity.
      WHEN 'A' OR 'X'.
        ev_text = `Termination`.
        ev_state = `Error`.
      WHEN 'E'.
        ev_text = `Error`.
        ev_state = `Error`.
      WHEN 'W'.
        ev_text = `Warning`.
        ev_state = `Warning`.
      WHEN 'S'.
        ev_text = `Success`.
        ev_state = `Success`.
      WHEN OTHERS.
        ev_text = `Information`.
        ev_state = `Information`.
    ENDCASE.

  ENDMETHOD.


  METHOD get_user_sessions.

    DATA lt_list TYPE STANDARD TABLE OF uinfo WITH EMPTY KEY.

    CLEAR: et_sessions, ev_message.

    CALL FUNCTION 'TH_USER_LIST'
      TABLES
        list          = lt_list
      EXCEPTIONS
        auth_misssing = 1
        OTHERS        = 2.
    IF sy-subrc <> 0.
      ev_message = |The user list could not be read (rc { sy-subrc }).|.
      RETURN.
    ENDIF.

    LOOP AT lt_list ASSIGNING FIELD-SYMBOL(<u>) WHERE bname IS NOT INITIAL.
      APPEND VALUE #(
        client   = <u>-mandt
        bname    = <u>-bname
        tcode    = <u>-tcode
        term     = <u>-term
        " UINFO-ZEIT is already the display time (CHAR 8, hh:mm:ss)
        zeit     = condense( CONV string( <u>-zeit ) )
        sessions = condense( CONV string( <u>-extmodi ) )
        typetext = SWITCH #( <u>-type
                     WHEN 4  THEN `GUI`
                     WHEN 32 THEN `RFC`
                     WHEN 2  THEN `Plugin HTTP`
                     WHEN 202 THEN `HTTP`
                     ELSE condense( CONV string( <u>-type ) ) )
        hostadr  = <u>-hostadr ) TO et_sessions.
    ENDLOOP.

    SORT et_sessions BY client bname.

  ENDMETHOD.

  METHOD get_job_log.

    DATA lv_jobname  TYPE btcjob.
    DATA lv_jobcount TYPE btcjobcnt.
    DATA lt_log      TYPE STANDARD TABLE OF tbtc5 WITH EMPTY KEY.

    CLEAR: et_log, ev_message.
    lv_jobname  = iv_jobname.
    lv_jobcount = iv_jobcount.

    SELECT SINGLE sdluname FROM tbtco
      WHERE jobname = @lv_jobname AND jobcount = @lv_jobcount
      INTO @DATA(lv_owner).
    IF sy-subrc <> 0.
      ev_message = |Job { iv_jobname } does not exist.|.
      RETURN.
    ENDIF.

    " the log of somebody else's job is protected like in SM37
    DATA(ls_auth) = zcl_zlk05_auth=>check_job_log( CONV string( lv_owner ) ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    CALL FUNCTION 'BP_JOBLOG_READ'
      EXPORTING
        jobcount              = lv_jobcount
        jobname               = lv_jobname
      TABLES
        joblogtbl             = lt_log
      EXCEPTIONS
        cant_read_joblog      = 1
        jobcount_missing      = 2
        joblog_does_not_exist = 3
        joblog_is_empty       = 4
        joblog_name_missing   = 5
        jobname_missing       = 6
        job_does_not_exist    = 7
        OTHERS                = 8.
    CASE sy-subrc.
      WHEN 0.
      WHEN 3 OR 4.
        ev_message = |Job { iv_jobname } has no job log (yet).|.
        RETURN.
      WHEN OTHERS.
        ev_message = |The job log of { iv_jobname } could not be read (rc { sy-subrc }).|.
        RETURN.
    ENDCASE.

    LOOP AT lt_log ASSIGNING FIELD-SYMBOL(<l>).
      severity_text( EXPORTING iv_severity = <l>-msgtype
                     IMPORTING ev_state    = DATA(lv_state) ).
      APPEND VALUE #( enterdate = zcl_zlk05_sys_api=>format_date( <l>-enterdate )
                      entertime = zcl_zlk05_sys_api=>format_time( <l>-entertime )
                      msgtype   = <l>-msgtype
                      state     = lv_state
                      text      = <l>-text
                      msgid     = <l>-msgid
                      msgno     = <l>-msgno ) TO et_log.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
