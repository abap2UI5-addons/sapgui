CLASS zcl_sapgui_sys_api_dbl DEFINITION PUBLIC FINAL FOR TESTING CREATE PRIVATE.

* ---------------------------------------------------------------------
*  ZIF_SAPGUI_SYS_API without a database, for the unit tests.
*
*  install( ) puts a new double in front of ZCL_SAPGUI_SYS_API (whose
*  global friend this class is), uninstall( ) takes it away again - call
*  them in setup( ) and teardown( ). Every method answers what answer( )
*  stored for it - for its first IMPORTING parameter (iv_key), or for
*  every call when no key was given - and an initial value otherwise:
*
*    DATA(lo_api) = zcl_sapgui_sys_api_dbl=>install( ).
*    lo_api->answer( iv_method = `GET_JOBS` iv_value = lt_jobs ).
*    lo_api->answer( iv_method = `GET_JOB_LOG` iv_param = `EV_MESSAGE`
*                    iv_value  = `No authorization` ).
*    lo_api->answer( iv_method = `SEUK_TEXT` iv_key = `102`
*                    iv_value  = `Transaction code` ).
*
*  mt_calls lists the methods the app called, in order. FOR TESTING:
*  only a test class can use it, so no productive code can replace the
*  system reads.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_sapgui_sys_api.

    "! Methods of ZIF_SAPGUI_SYS_API called so far, upper case, in order
    DATA mt_calls TYPE string_table READ-ONLY.

    "! A new double, installed as the system API of every app
    CLASS-METHODS install
      RETURNING VALUE(result) TYPE REF TO zcl_sapgui_sys_api_dbl.

    "! Back to the system API of the system (or of the next install( ))
    CLASS-METHODS uninstall.

    "! What iv_method answers from now on: its result, or the EXPORTING
    "! parameter iv_param - when called with iv_key as its first IMPORTING
    "! parameter, or for any call when iv_key is not given
    METHODS answer
      IMPORTING iv_method TYPE string
                iv_param  TYPE string DEFAULT `RESULT`
                iv_key    TYPE string OPTIONAL
                iv_value  TYPE any.

    "! Was iv_method called at least once?
    METHODS was_called
      IMPORTING iv_method     TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_answer,
        method TYPE string,
        param  TYPE string,
        arg    TYPE string,
        value  TYPE REF TO data,
      END OF ty_s_answer.

    DATA mt_answers TYPE HASHED TABLE OF ty_s_answer WITH UNIQUE KEY method param arg.

    METHODS reply
      IMPORTING iv_method TYPE string
                iv_param  TYPE string DEFAULT `RESULT`
                iv_key    TYPE string OPTIONAL
      CHANGING  cv_value  TYPE any.

ENDCLASS.



CLASS zcl_sapgui_sys_api_dbl IMPLEMENTATION.


  METHOD install.
    result = NEW #( ).
    zcl_sapgui_sys_api=>go_api = result.
  ENDMETHOD.


  METHOD uninstall.
    CLEAR zcl_sapgui_sys_api=>go_api.
  ENDMETHOD.


  METHOD answer.
    DATA ls_answer TYPE ty_s_answer.
    FIELD-SYMBOLS <lv_value> TYPE any.

    ls_answer-method = to_upper( iv_method ).
    ls_answer-param  = to_upper( iv_param ).
    ls_answer-arg    = iv_key.
    CREATE DATA ls_answer-value LIKE iv_value.
    ASSIGN ls_answer-value->* TO <lv_value>.
    <lv_value> = iv_value.
    " WHERE, not WITH TABLE KEY: the transpiler compares only the first
    " component of a multi-component key there (@abaplint/transpiler 2.13)
    DELETE mt_answers WHERE method = ls_answer-method AND param = ls_answer-param AND arg = ls_answer-arg.
    INSERT ls_answer INTO TABLE mt_answers.
  ENDMETHOD.


  METHOD was_called.
    result = xsdbool( line_exists( mt_calls[ table_line = to_upper( iv_method ) ] ) ).
  ENDMETHOD.


  METHOD reply.
    FIELD-SYMBOLS <lv_value> TYPE any.

    IF iv_param = `RESULT`.
      APPEND iv_method TO mt_calls.
    ENDIF.
    CLEAR cv_value.
    READ TABLE mt_answers INTO DATA(ls_answer)
         WITH TABLE KEY method = iv_method param = iv_param arg = iv_key.
    IF sy-subrc <> 0 AND iv_key IS NOT INITIAL.
      READ TABLE mt_answers INTO ls_answer
           WITH TABLE KEY method = iv_method param = iv_param arg = ``.
    ENDIF.
    IF sy-subrc = 0.
      ASSIGN ls_answer-value->* TO <lv_value>.
      cv_value = <lv_value>.
    ENDIF.
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_ddic.
    reply( EXPORTING iv_method = `SEARCH_DDIC` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_table_fields.
    reply( EXPORTING iv_method = `GET_TABLE_FIELDS` iv_key = |{ iv_tabname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_dtel_detail.
    reply( EXPORTING iv_method = `GET_DTEL_DETAIL` iv_key = |{ iv_rollname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_classes.
    reply( EXPORTING iv_method = `SEARCH_CLASSES` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_class_components.
    reply( EXPORTING iv_method = `GET_CLASS_COMPONENTS` iv_key = |{ iv_clsname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_functions.
    reply( EXPORTING iv_method = `SEARCH_FUNCTIONS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_function_params.
    reply( EXPORTING iv_method = `GET_FUNCTION_PARAMS` iv_key = |{ iv_funcname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_programs.
    reply( EXPORTING iv_method = `SEARCH_PROGRAMS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_program_source.
    reply( EXPORTING iv_method = `GET_PROGRAM_SOURCE` iv_key = |{ iv_name }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_jobs.
    reply( EXPORTING iv_method = `GET_JOBS` iv_key = |{ iv_jobname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_job_steps.
    reply( EXPORTING iv_method = `GET_JOB_STEPS` iv_key = |{ iv_jobname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_dumps.
    reply( EXPORTING iv_method = `GET_DUMPS` iv_key = |{ iv_date_from }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_dump_detail.
    reply( EXPORTING iv_method = `GET_DUMP_DETAIL` iv_key = |{ iv_datum }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_users.
    reply( EXPORTING iv_method = `SEARCH_USERS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_user_roles.
    reply( EXPORTING iv_method = `GET_USER_ROLES` iv_key = |{ iv_bname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_work_processes.
    APPEND `GET_WORK_PROCESSES` TO mt_calls.
    reply( EXPORTING iv_method = `GET_WORK_PROCESSES` iv_param = `ET_WP` CHANGING cv_value = et_wp ).
    reply( EXPORTING iv_method = `GET_WORK_PROCESSES` iv_param = `EV_MESSAGE` CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_locks.
    APPEND `GET_LOCKS` TO mt_calls.
    reply( EXPORTING iv_method = `GET_LOCKS` iv_param = `ET_LOCKS` iv_key = |{ iv_table }| CHANGING cv_value = et_locks ).
    reply( EXPORTING iv_method = `GET_LOCKS` iv_param = `EV_MESSAGE` iv_key = |{ iv_table }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_buffer_stats.
    APPEND `GET_BUFFER_STATS` TO mt_calls.
    reply( EXPORTING iv_method = `GET_BUFFER_STATS` iv_param = `ET_BUFFER` CHANGING cv_value = et_buffer ).
    reply( EXPORTING iv_method = `GET_BUFFER_STATS` iv_param = `ET_MEMORY` CHANGING cv_value = et_memory ).
    reply( EXPORTING iv_method = `GET_BUFFER_STATS` iv_param = `EV_MESSAGE` CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_tms_domain.
    APPEND `GET_TMS_DOMAIN` TO mt_calls.
    reply( EXPORTING iv_method = `GET_TMS_DOMAIN` iv_param = `EV_DOMAIN` CHANGING cv_value = ev_domain ).
    reply( EXPORTING iv_method = `GET_TMS_DOMAIN` iv_param = `EV_SYSTEM` CHANGING cv_value = ev_system ).
    reply( EXPORTING iv_method = `GET_TMS_DOMAIN` iv_param = `EV_MESSAGE` CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_tms_systems.
    reply( EXPORTING iv_method = `GET_TMS_SYSTEMS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_tms_queue.
    reply( EXPORTING iv_method = `GET_TMS_QUEUE` iv_key = |{ iv_max }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_transports.
    reply( EXPORTING iv_method = `GET_TRANSPORTS` iv_key = |{ iv_user }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_transport_objects.
    reply( EXPORTING iv_method = `GET_TRANSPORT_OBJECTS` iv_key = |{ iv_trkorr }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_object_in_requests.
    reply( EXPORTING iv_method = `SEARCH_OBJECT_IN_REQUESTS` iv_key = |{ iv_obj_name }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_clients.
    reply( EXPORTING iv_method = `GET_CLIENTS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_parameters.
    reply( EXPORTING iv_method = `SEARCH_PARAMETERS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_parameter_detail.
    reply( EXPORTING iv_method = `GET_PARAMETER_DETAIL` iv_key = |{ iv_paraname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_syslog.
    APPEND `GET_SYSLOG` TO mt_calls.
    reply( EXPORTING iv_method = `GET_SYSLOG` iv_param = `ET_SYSLOG` iv_key = |{ iv_date_from }| CHANGING cv_value = et_syslog ).
    reply( EXPORTING iv_method = `GET_SYSLOG` iv_param = `EV_MESSAGE` iv_key = |{ iv_date_from }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_trace_status.
    reply( EXPORTING iv_method = `GET_TRACE_STATUS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_trace_state.
    APPEND `GET_TRACE_STATE` TO mt_calls.
    reply( EXPORTING iv_method = `GET_TRACE_STATE` iv_param = `ES_STATE` CHANGING cv_value = es_state ).
    reply( EXPORTING iv_method = `GET_TRACE_STATE` iv_param = `EV_MESSAGE` CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_area_menu_children.
    reply( EXPORTING iv_method = `GET_AREA_MENU_CHILDREN` iv_key = |{ iv_struct_id }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~transaction_exists.
    reply( EXPORTING iv_method = `TRANSACTION_EXISTS` iv_key = |{ iv_tcode }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_transaction_text.
    reply( EXPORTING iv_method = `GET_TRANSACTION_TEXT` iv_key = |{ iv_tcode }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~seuk_text.
    reply( EXPORTING iv_method = `SEUK_TEXT` iv_key = |{ iv_key }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_transactions.
    reply( EXPORTING iv_method = `GET_TRANSACTIONS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_transaction_detail.
    reply( EXPORTING iv_method = `GET_TRANSACTION_DETAIL` iv_key = |{ iv_tcode }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_app_logs.
    reply( EXPORTING iv_method = `GET_APP_LOGS` iv_key = |{ iv_object }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_app_log_messages.
    APPEND `GET_APP_LOG_MESSAGES` TO mt_calls.
    reply( EXPORTING iv_method = `GET_APP_LOG_MESSAGES` iv_param = `ET_MESSAGES` iv_key = |{ iv_lognumber }| CHANGING cv_value = et_messages ).
    reply( EXPORTING iv_method = `GET_APP_LOG_MESSAGES` iv_param = `EV_MESSAGE` iv_key = |{ iv_lognumber }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_rfc_destinations.
    reply( EXPORTING iv_method = `GET_RFC_DESTINATIONS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~rfc_type_text.
    reply( EXPORTING iv_method = `RFC_TYPE_TEXT` iv_key = |{ iv_rfctype }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_user_sessions.
    APPEND `GET_USER_SESSIONS` TO mt_calls.
    reply( EXPORTING iv_method = `GET_USER_SESSIONS` iv_param = `ET_SESSIONS` CHANGING cv_value = et_sessions ).
    reply( EXPORTING iv_method = `GET_USER_SESSIONS` iv_param = `EV_MESSAGE` CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_job_log.
    APPEND `GET_JOB_LOG` TO mt_calls.
    reply( EXPORTING iv_method = `GET_JOB_LOG` iv_param = `ET_LOG` iv_key = |{ iv_jobname }| CHANGING cv_value = et_log ).
    reply( EXPORTING iv_method = `GET_JOB_LOG` iv_param = `EV_MESSAGE` iv_key = |{ iv_jobname }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_table_kind.
    reply( EXPORTING iv_method = `GET_TABLE_KIND` iv_key = |{ iv_name }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_method_include.
    reply( EXPORTING iv_method = `GET_METHOD_INCLUDE` iv_key = |{ iv_class }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_function_include.
    reply( EXPORTING iv_method = `GET_FUNCTION_INCLUDE` iv_key = |{ iv_funcname }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_auth_failures.
    APPEND `GET_AUTH_FAILURES` TO mt_calls.
    reply( EXPORTING iv_method = `GET_AUTH_FAILURES` iv_param = `ET_FAILS` iv_key = |{ iv_bname }| CHANGING cv_value = et_fails ).
    reply( EXPORTING iv_method = `GET_AUTH_FAILURES` iv_param = `EV_MESSAGE` iv_key = |{ iv_bname }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_spool_requests.
    reply( EXPORTING iv_method = `GET_SPOOL_REQUESTS` iv_key = |{ iv_owner }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_spool_content.
    APPEND `GET_SPOOL_CONTENT` TO mt_calls.
    reply( EXPORTING iv_method = `GET_SPOOL_CONTENT` iv_param = `ET_LINES` iv_key = |{ iv_rqident }| CHANGING cv_value = et_lines ).
    reply( EXPORTING iv_method = `GET_SPOOL_CONTENT` iv_param = `EV_MESSAGE` iv_key = |{ iv_rqident }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_idocs.
    reply( EXPORTING iv_method = `GET_IDOCS` iv_key = |{ iv_docnum }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_idoc_detail.
    APPEND `GET_IDOC_DETAIL` TO mt_calls.
    reply( EXPORTING iv_method = `GET_IDOC_DETAIL` iv_param = `ES_IDOC` iv_key = |{ iv_docnum }| CHANGING cv_value = es_idoc ).
    reply( EXPORTING iv_method = `GET_IDOC_DETAIL` iv_param = `ET_CONTROL` iv_key = |{ iv_docnum }| CHANGING cv_value = et_control ).
    reply( EXPORTING iv_method = `GET_IDOC_DETAIL` iv_param = `ET_STATUS` iv_key = |{ iv_docnum }| CHANGING cv_value = et_status ).
    reply( EXPORTING iv_method = `GET_IDOC_DETAIL` iv_param = `ET_SEGMENTS` iv_key = |{ iv_docnum }| CHANGING cv_value = et_segments ).
    reply( EXPORTING iv_method = `GET_IDOC_DETAIL` iv_param = `EV_MESSAGE` iv_key = |{ iv_docnum }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_roles.
    reply( EXPORTING iv_method = `SEARCH_ROLES` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_role_detail.
    APPEND `GET_ROLE_DETAIL` TO mt_calls.
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_HEAD` iv_key = |{ iv_role }| CHANGING cv_value = et_head ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_DESCR` iv_key = |{ iv_role }| CHANGING cv_value = et_descr ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_TCODES` iv_key = |{ iv_role }| CHANGING cv_value = et_tcodes ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_AUTH` iv_key = |{ iv_role }| CHANGING cv_value = et_auth ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_USERS` iv_key = |{ iv_role }| CHANGING cv_value = et_users ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `ET_ROLES` iv_key = |{ iv_role }| CHANGING cv_value = et_roles ).
    reply( EXPORTING iv_method = `GET_ROLE_DETAIL` iv_param = `EV_MESSAGE` iv_key = |{ iv_role }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~search_message_classes.
    reply( EXPORTING iv_method = `SEARCH_MESSAGE_CLASSES` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_messages.
    APPEND `GET_MESSAGES` TO mt_calls.
    reply( EXPORTING iv_method = `GET_MESSAGES` iv_param = `ET_HEAD` iv_key = |{ iv_arbgb }| CHANGING cv_value = et_head ).
    reply( EXPORTING iv_method = `GET_MESSAGES` iv_param = `ET_MSGS` iv_key = |{ iv_arbgb }| CHANGING cv_value = et_msgs ).
    reply( EXPORTING iv_method = `GET_MESSAGES` iv_param = `EV_MESSAGE` iv_key = |{ iv_arbgb }| CHANGING cv_value = ev_message ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_message_longtext.
    reply( EXPORTING iv_method = `GET_MESSAGE_LONGTEXT` iv_key = |{ iv_arbgb }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_sys_api~get_system_status.
    reply( EXPORTING iv_method = `GET_SYSTEM_STATUS` iv_key = |{ iv_tcode }| CHANGING cv_value = result ).
  ENDMETHOD.

ENDCLASS.
