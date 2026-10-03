CLASS zcl_zlk05_sys_api_db DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  ZIF_ZLK05_SYS_API on a real system: every method hands over to the
*  area class that reads it (ZCL_ZLK05_API_DEV, _ADM, _MON, _OPS,
*  _REPO, _TRN). Created by ZCL_ZLK05_SYS_API=>api( ) - by name, so
*  that the facade does not depend on the database layer and the unit
*  tests can run without it.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_zlk05_sys_api.

ENDCLASS.



CLASS zcl_zlk05_sys_api_db IMPLEMENTATION.


  METHOD zif_zlk05_sys_api~search_ddic.
    result = zcl_zlk05_api_dev=>search_ddic( iv_pattern = iv_pattern iv_kind = iv_kind iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_table_fields.
    result = zcl_zlk05_api_dev=>get_table_fields( iv_tabname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_dtel_detail.
    result = zcl_zlk05_api_dev=>get_dtel_detail( iv_rollname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_classes.
    result = zcl_zlk05_api_dev=>search_classes( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_class_components.
    result = zcl_zlk05_api_dev=>get_class_components( iv_clsname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_functions.
    result = zcl_zlk05_api_dev=>search_functions( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_function_params.
    result = zcl_zlk05_api_dev=>get_function_params( iv_funcname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_programs.
    result = zcl_zlk05_api_dev=>search_programs( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_program_source.
    result = zcl_zlk05_api_dev=>get_program_source( iv_name ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_jobs.
    result = zcl_zlk05_api_mon=>get_jobs( iv_jobname = iv_jobname iv_user = iv_user iv_status = iv_status iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_job_steps.
    result = zcl_zlk05_api_mon=>get_job_steps( iv_jobname = iv_jobname iv_jobcount = iv_jobcount ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_dumps.
    result = zcl_zlk05_api_mon=>get_dumps( iv_date_from = iv_date_from iv_user = iv_user iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_dump_detail.
    result = zcl_zlk05_api_mon=>get_dump_detail( iv_datum = iv_datum iv_uzeit = iv_uzeit iv_modno = iv_modno ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_users.
    result = zcl_zlk05_api_adm=>search_users( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_user_roles.
    result = zcl_zlk05_api_adm=>get_user_roles( iv_bname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_work_processes.
    zcl_zlk05_api_mon=>get_work_processes( IMPORTING et_wp = et_wp ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_locks.
    zcl_zlk05_api_mon=>get_locks( EXPORTING iv_table = iv_table iv_user = iv_user IMPORTING et_locks = et_locks ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_buffer_stats.
    zcl_zlk05_api_mon=>get_buffer_stats( IMPORTING et_buffer = et_buffer et_memory = et_memory ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_tms_domain.
    zcl_zlk05_api_trn=>get_tms_domain( IMPORTING ev_domain = ev_domain ev_system = ev_system ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_tms_systems.
    result = zcl_zlk05_api_trn=>get_tms_systems( ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_tms_queue.
    result = zcl_zlk05_api_trn=>get_tms_queue( iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_transports.
    result = zcl_zlk05_api_trn=>get_transports( iv_user = iv_user iv_status = iv_status iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_transport_objects.
    result = zcl_zlk05_api_trn=>get_transport_objects( iv_trkorr = iv_trkorr iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_clients.
    result = zcl_zlk05_api_adm=>get_clients( ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_parameters.
    result = zcl_zlk05_api_adm=>search_parameters( iv_pattern = iv_pattern iv_only_dynamic = iv_only_dynamic iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_parameter_detail.
    result = zcl_zlk05_api_adm=>get_parameter_detail( iv_paraname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_syslog.
    zcl_zlk05_api_mon=>get_syslog( EXPORTING iv_date_from = iv_date_from iv_time_from = iv_time_from iv_date_to = iv_date_to iv_time_to = iv_time_to iv_user = iv_user iv_tcode = iv_tcode IMPORTING et_syslog = et_syslog ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_trace_status.
    result = zcl_zlk05_api_mon=>get_trace_status( ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_trace_state.
    zcl_zlk05_api_mon=>get_trace_state( IMPORTING es_state = es_state ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_area_menu_children.
    result = zcl_zlk05_api_repo=>get_area_menu_children( iv_struct_id = iv_struct_id iv_node_id = iv_node_id ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~transaction_exists.
    result = zcl_zlk05_api_repo=>transaction_exists( iv_tcode ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_transaction_text.
    result = zcl_zlk05_api_repo=>get_transaction_text( iv_tcode ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~seuk_text.
    result = zcl_zlk05_api_repo=>seuk_text( iv_key ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_transactions.
    result = zcl_zlk05_api_repo=>get_transactions( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_transaction_detail.
    result = zcl_zlk05_api_repo=>get_transaction_detail( iv_tcode ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_app_logs.
    result = zcl_zlk05_api_mon=>get_app_logs( iv_object = iv_object iv_subobject = iv_subobject iv_user = iv_user iv_date_from = iv_date_from iv_date_to = iv_date_to iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_app_log_messages.
    zcl_zlk05_api_mon=>get_app_log_messages( EXPORTING iv_lognumber = iv_lognumber IMPORTING et_messages = et_messages ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_rfc_destinations.
    result = zcl_zlk05_api_adm=>get_rfc_destinations( iv_pattern = iv_pattern iv_rfctype = iv_rfctype iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~rfc_type_text.
    result = zcl_zlk05_api_adm=>rfc_type_text( iv_rfctype ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_user_sessions.
    zcl_zlk05_api_mon=>get_user_sessions( IMPORTING et_sessions = et_sessions ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_job_log.
    zcl_zlk05_api_mon=>get_job_log( EXPORTING iv_jobname = iv_jobname iv_jobcount = iv_jobcount IMPORTING et_log = et_log ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_table_kind.
    result = zcl_zlk05_api_dev=>get_table_kind( iv_name ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_method_include.
    result = zcl_zlk05_api_dev=>get_method_include( iv_class = iv_class iv_method = iv_method ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_function_include.
    result = zcl_zlk05_api_dev=>get_function_include( iv_funcname ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_auth_failures.
    zcl_zlk05_api_adm=>get_auth_failures( EXPORTING iv_bname = iv_bname iv_seconds = iv_seconds IMPORTING et_fails = et_fails ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_spool_requests.
    result = zcl_zlk05_api_ops=>get_spool_requests( iv_owner = iv_owner iv_date_from = iv_date_from iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_spool_content.
    zcl_zlk05_api_ops=>get_spool_content( EXPORTING iv_rqident = iv_rqident iv_max_lines = iv_max_lines IMPORTING et_lines = et_lines ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_idocs.
    result = zcl_zlk05_api_ops=>get_idocs( iv_docnum = iv_docnum iv_mestyp = iv_mestyp iv_status = iv_status iv_direct = iv_direct iv_date_from = iv_date_from iv_date_to = iv_date_to iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_idoc_detail.
    zcl_zlk05_api_ops=>get_idoc_detail( EXPORTING iv_docnum = iv_docnum IMPORTING es_idoc = es_idoc et_control = et_control et_status = et_status et_segments = et_segments ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_roles.
    result = zcl_zlk05_api_adm=>search_roles( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_role_detail.
    zcl_zlk05_api_adm=>get_role_detail( EXPORTING iv_role = iv_role IMPORTING et_head = et_head et_descr = et_descr et_tcodes = et_tcodes et_auth = et_auth et_users = et_users et_roles = et_roles ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~search_message_classes.
    result = zcl_zlk05_api_dev=>search_message_classes( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_messages.
    zcl_zlk05_api_dev=>get_messages( EXPORTING iv_arbgb = iv_arbgb IMPORTING et_head = et_head et_msgs = et_msgs ev_message = ev_message ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_message_longtext.
    result = zcl_zlk05_api_dev=>get_message_longtext( iv_arbgb = iv_arbgb iv_msgnr = iv_msgnr ).
  ENDMETHOD.


  METHOD zif_zlk05_sys_api~get_system_status.
    result = zcl_zlk05_api_adm=>get_system_status( iv_tcode = iv_tcode iv_program = iv_program ).
  ENDMETHOD.

ENDCLASS.
