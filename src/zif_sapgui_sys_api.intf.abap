INTERFACE zif_sapgui_sys_api PUBLIC.

* ---------------------------------------------------------------------
*  Everything the apps read from the system, as an interface.
*
*  The apps keep calling the static facade ZCL_SAPGUI_SYS_API; it hands
*  each of these methods to an instance of this interface:
*    ZCL_SAPGUI_SYS_API_DB   on a system - reads tables and calls the
*                           function modules, through ZCL_SAPGUI_API_*
*    ZCL_SAPGUI_SYS_API_DBL  in the unit tests - canned answers, no
*                           database at all
*  The types live in ZCL_SAPGUI_SYS_API, where the apps already find them.
* ---------------------------------------------------------------------

  "! Search tables/views (kind = TABL) or data elements (kind = DTEL)
  METHODS search_ddic
    IMPORTING iv_pattern    TYPE string
              iv_kind       TYPE string DEFAULT 'TABL'
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_ddic_obj.

  METHODS get_table_fields
    IMPORTING iv_tabname    TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_ddic_field.

  METHODS get_dtel_detail
    IMPORTING iv_rollname   TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_kv.

  METHODS search_classes
    IMPORTING iv_pattern    TYPE string
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_class.

  METHODS get_class_components
    IMPORTING iv_clsname    TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_component.

  METHODS search_functions
    IMPORTING iv_pattern    TYPE string
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_function.

  METHODS get_function_params
    IMPORTING iv_funcname   TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_fparam.

  METHODS search_programs
    IMPORTING iv_pattern    TYPE string
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_program.

  "! Reads the source of a report / include via READ REPORT
  METHODS get_program_source
    IMPORTING iv_name       TYPE string
    RETURNING VALUE(result) TYPE string.

  METHODS get_jobs
    IMPORTING iv_jobname    TYPE string OPTIONAL
              iv_user       TYPE string OPTIONAL
              iv_status     TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_job.

  METHODS get_job_steps
    IMPORTING iv_jobname    TYPE string
              iv_jobcount   TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_jobstep.

  METHODS get_dumps
    IMPORTING iv_date_from  TYPE d OPTIONAL
              iv_user       TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_dump.

  METHODS get_dump_detail
    IMPORTING iv_datum      TYPE d
              iv_uzeit      TYPE t
              iv_modno      TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_kv.

  METHODS search_users
    IMPORTING iv_pattern    TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_user.

  METHODS get_user_roles
    IMPORTING iv_bname      TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_role.

  METHODS get_work_processes
    EXPORTING et_wp         TYPE zcl_sapgui_sys_api=>ty_t_wp
              ev_message    TYPE string.

  METHODS get_locks
    IMPORTING iv_table      TYPE string OPTIONAL
              iv_user       TYPE string OPTIONAL
    EXPORTING et_locks      TYPE zcl_sapgui_sys_api=>ty_t_lock
              ev_message    TYPE string.

  METHODS get_buffer_stats
    EXPORTING et_buffer     TYPE zcl_sapgui_sys_api=>ty_t_buffer
              et_memory     TYPE zcl_sapgui_sys_api=>ty_t_kv
              ev_message    TYPE string.

  "! Transport domain and the own system, read from TMSCSYS
  METHODS get_tms_domain
    EXPORTING ev_domain  TYPE string
              ev_system  TYPE string
              ev_message TYPE string.

  "! All systems of the transport domain (TMSCSYS)
  METHODS get_tms_systems
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tms_system.

  "! Import queue of every system of the domain (TMSBUFFER)
  METHODS get_tms_queue
    IMPORTING iv_max        TYPE i DEFAULT 5000
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tms_queue.

  METHODS get_transports
    IMPORTING iv_user       TYPE string OPTIONAL
              iv_status     TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_transport.

  METHODS get_transport_objects
    IMPORTING iv_trkorr     TYPE string
              iv_max        TYPE i DEFAULT 5000
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tr_object.

  "! Requests and tasks that contain an object (E071) - SE03, Search for
  "! Objects in Requests/Tasks. iv_obj_name takes * and +, iv_object
  "! empty means every object type. Newest first.
  METHODS search_object_in_requests
    IMPORTING iv_obj_name   TYPE string
              iv_object     TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 500
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_object_request.

  METHODS get_clients
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_client.

  METHODS search_parameters
    IMPORTING iv_pattern       TYPE string OPTIONAL
              iv_only_dynamic  TYPE abap_bool DEFAULT abap_false
              iv_max           TYPE i DEFAULT 300
    RETURNING VALUE(result)    TYPE zcl_sapgui_sys_api=>ty_t_param.

  METHODS get_parameter_detail
    IMPORTING iv_paraname   TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_kv.

  METHODS get_syslog
    IMPORTING iv_date_from  TYPE d OPTIONAL
              iv_time_from  TYPE t OPTIONAL
              iv_date_to    TYPE d OPTIONAL
              iv_time_to    TYPE t OPTIONAL
              iv_user       TYPE string OPTIONAL
              iv_tcode      TYPE string OPTIONAL
    EXPORTING et_syslog     TYPE zcl_sapgui_sys_api=>ty_t_syslog
              ev_message    TYPE string.

  "! ST05 trace evaluation is a kernel service without a released
  "! read API. This returns the trace relevant profile parameters so
  "! the app can show the current trace configuration.
  METHODS get_trace_status
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_kv.

  "! Reads the real trace state of the own application server instance
  "! via ST05_GET_TRACE_STATE. Display only - it never switches a trace
  "! on or off.
  METHODS get_trace_state
    EXPORTING es_state   TYPE zcl_sapgui_sys_api=>ty_s_trace_state
              ev_message TYPE string.

  "! Reads the children of one node of an SAP area menu.
  "! iv_struct_id - area menu, S000 is the SAP standard menu
  "! iv_node_id   - parent node, initial returns the top level
  METHODS get_area_menu_children
    IMPORTING iv_struct_id  TYPE string DEFAULT 'S000'
              iv_node_id    TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_menu_node.

  "! Does the transaction code exist in this system?
  METHODS transaction_exists
    IMPORTING iv_tcode      TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! Short text of a transaction as shown by the SAP GUI
  METHODS get_transaction_text
    IMPORTING iv_tcode      TYPE string
    RETURNING VALUE(result) TYPE string.

  "! A text symbol of SAPLSEUK, the program behind SE93. The names of the
  "! transaction types live there (001 Dialog, 002 Report, 003 Parameter,
  "! 019 Variant, 028 Object Transaction), so they are read from the
  "! original instead of being duplicated here.
  METHODS seuk_text
    IMPORTING iv_key        TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Transactions of TSTC with their short text and derived type.
  METHODS get_transactions
    IMPORTING iv_pattern    TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tcode.

  "! Everything SE93 shows for one transaction.
  METHODS get_transaction_detail
    IMPORTING iv_tcode      TYPE string
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_s_tcode_detail.

  "! Logs of BALHDR. Only logs the user may display (S_APPL_LOG) are returned.
  METHODS get_app_logs
    IMPORTING iv_object     TYPE string OPTIONAL
              iv_subobject  TYPE string OPTIONAL
              iv_user       TYPE string OPTIONAL
              iv_date_from  TYPE d OPTIONAL
              iv_date_to    TYPE d OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_applog.

  "! Messages of one log, read with BAL_DB_LOAD / BAL_LOG_MSG_READ
  METHODS get_app_log_messages
    IMPORTING iv_lognumber  TYPE string
    EXPORTING et_messages   TYPE zcl_sapgui_sys_api=>ty_t_applog_msg
              ev_message    TYPE string.

  "! RFC destinations of RFCDES the user may display (S_RFC_ADM)
  METHODS get_rfc_destinations
    IMPORTING iv_pattern    TYPE string OPTIONAL
              iv_rfctype    TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 500
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_rfcdest.

  "! Text of an RFC connection type (domain RFCTYPE)
  METHODS rfc_type_text
    IMPORTING iv_rfctype    TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Users logged on to the own instance
  METHODS get_user_sessions
    EXPORTING et_sessions TYPE zcl_sapgui_sys_api=>ty_t_session
              ev_message  TYPE string.

  "! Job log of one job (BP_JOBLOG_READ). Logs of other users' jobs need
  "! S_BTCH_JOB PROT or S_BTCH_ADM, like SM37.
  METHODS get_job_log
    IMPORTING iv_jobname  TYPE string
              iv_jobcount TYPE string
    EXPORTING et_log      TYPE zcl_sapgui_sys_api=>ty_t_joblog
              ev_message  TYPE string.

  "! Kind of a dictionary object (DD02L-TABCLASS / DD25L-VIEWCLASS)
  METHODS get_table_kind
    IMPORTING iv_name       TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Include that holds the implementation of a class method
  "! (ZCL_X=====CM001). Initial when the method has no implementation.
  METHODS get_method_include
    IMPORTING iv_class      TYPE string
              iv_method     TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Include that holds the source of a function module (LxxxUnn)
  METHODS get_function_include
    IMPORTING iv_funcname   TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Failed authorization checks of a user during the last iv_seconds,
  "! read like SU53 with SUSR_USER_SU53_READ. Other users need S_USER_GRP.
  METHODS get_auth_failures
    IMPORTING iv_bname   TYPE string
              iv_seconds TYPE i DEFAULT 10800
    EXPORTING et_fails   TYPE zcl_sapgui_sys_api=>ty_t_authfail
              ev_message TYPE string.

  "! Spool requests of the logon client, newest first, that the user may
  "! see (RSPO_CHECK_JOB_PERMISSION BASE). Owner: user name or pattern.
  METHODS get_spool_requests
    IMPORTING iv_owner      TYPE string OPTIONAL
              iv_date_from  TYPE d OPTIONAL
              iv_max        TYPE i DEFAULT 200
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_spool.

  "! Content of an ABAP list spool request (RSPO_RETURN_ABAP_SPOOLJOB),
  "! after RSPO_CHECK_JOB_PERMISSION DISP
  METHODS get_spool_content
    IMPORTING iv_rqident   TYPE string
              iv_max_lines TYPE i DEFAULT 5000
    EXPORTING et_lines     TYPE string_table
              ev_message   TYPE string.

  "! IDocs of EDIDC the user may see (S_IDOCMONI + BAdI, as WE02)
  METHODS get_idocs
    IMPORTING iv_docnum     TYPE string OPTIONAL
              iv_mestyp     TYPE string OPTIONAL
              iv_status     TYPE string OPTIONAL
              iv_direct     TYPE string OPTIONAL
              iv_date_from  TYPE d OPTIONAL
              iv_date_to    TYPE d OPTIONAL
              iv_max        TYPE i DEFAULT 500
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_idoc.

  "! One IDoc with control record, status records and data records
  "! (IDOC_READ_COMPLETELY), after the WE02 authorization check
  METHODS get_idoc_detail
    IMPORTING iv_docnum   TYPE string
    EXPORTING es_idoc     TYPE zcl_sapgui_sys_api=>ty_s_idoc
              et_control  TYPE zcl_sapgui_sys_api=>ty_t_kv
              et_status   TYPE zcl_sapgui_sys_api=>ty_t_idoc_status
              et_segments TYPE zcl_sapgui_sys_api=>ty_t_idoc_seg
              ev_message  TYPE string.

  "! Roles of AGR_DEFINE the user may display (S_USER_AGR 03)
  METHODS search_roles
    IMPORTING iv_pattern    TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 300
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_agr.

  "! The tabs of a role in PFCG: description, menu, authorizations,
  "! user assignment, and the single roles of a composite role
  METHODS get_role_detail
    IMPORTING iv_role     TYPE string
    EXPORTING et_head     TYPE zcl_sapgui_sys_api=>ty_t_kv
              et_descr    TYPE string_table
              et_tcodes   TYPE zcl_sapgui_sys_api=>ty_t_agr_tcode
              et_auth     TYPE zcl_sapgui_sys_api=>ty_t_agr_auth
              et_users    TYPE zcl_sapgui_sys_api=>ty_t_agr_user
              et_roles    TYPE zcl_sapgui_sys_api=>ty_t_agr
              ev_message  TYPE string.

  "! Message classes of T100A the user may display (S_DEVELOP MSAG)
  METHODS search_message_classes
    IMPORTING iv_pattern    TYPE string OPTIONAL
              iv_max        TYPE i DEFAULT 300
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_msgclass.

  "! Attributes and messages of a message class in the logon language
  "! (master language when a text is not translated)
  METHODS get_messages
    IMPORTING iv_arbgb    TYPE string
    EXPORTING et_head     TYPE zcl_sapgui_sys_api=>ty_t_kv
              et_msgs     TYPE zcl_sapgui_sys_api=>ty_t_msg
              ev_message  TYPE string.

  "! Long text of a message (document class NA) as plain lines
  METHODS get_message_longtext
    IMPORTING iv_arbgb      TYPE string
              iv_msgnr      TYPE string
    RETURNING VALUE(result) TYPE string_table.

  "! The data of the System: Status dialog - usage data, repository data
  "! of the running transaction, SAP, host and database data
  METHODS get_system_status
    IMPORTING iv_tcode      TYPE string OPTIONAL
              iv_program    TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_status.

ENDINTERFACE.
