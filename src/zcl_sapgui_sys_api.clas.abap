CLASS zcl_sapgui_sys_api DEFINITION PUBLIC FINAL CREATE PUBLIC
  GLOBAL FRIENDS zcl_sapgui_sys_api_dbl.

* ---------------------------------------------------------------------
*  Shared system API for the SAP GUI look-alike apps of package $ZLK_05
*
*  All database and function module access lives here. The abap2UI5
*  apps (ZCL_SAPGUI_SM37, ZCL_SAPGUI_ST22, ...) only build views and
*  dispatch events - they never read the system directly.
*
*  This class is the single entry point: it owns all types and the
*  helpers that only compute, and hands every method that reads the
*  system to an instance of ZIF_SAPGUI_SYS_API - see api( ):
*    ZCL_SAPGUI_SYS_API_DB   on a system; it delegates to one class per
*                           area: ZCL_SAPGUI_API_DEV (workbench), _ADM
*                           (administration), _MON (monitoring), _OPS
*                           (output, IDocs), _REPO (area menu, SE93),
*                           _TRN (transport)
*    ZCL_SAPGUI_SYS_API_DBL  in the unit tests, installed by the test
*                           class (a global friend, FOR TESTING)
*
*  Every method is READ-ONLY. Nothing in this class changes system
*  state or persists data.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

* =====================================================================
*  Generic types
* =====================================================================
    " Generic label/value pair used for all detail screens
    TYPES:
      BEGIN OF ty_s_kv,
        label TYPE string,
        value TYPE string,
      END OF ty_s_kv.
    TYPES ty_t_kv TYPE STANDARD TABLE OF ty_s_kv WITH EMPTY KEY.

* =====================================================================
*  SE11 - ABAP Dictionary
* =====================================================================
    TYPES:
      BEGIN OF ty_s_ddic_obj,
        name     TYPE string,
        kind     TYPE string,
        tabclass TYPE string,
        descr    TYPE string,
        author   TYPE string,
        chdate   TYPE string,
      END OF ty_s_ddic_obj.
    TYPES ty_t_ddic_obj TYPE STANDARD TABLE OF ty_s_ddic_obj WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_ddic_field,
        pos       TYPE string,
        fieldname TYPE string,
        keyflag   TYPE string,
        rollname  TYPE string,
        datatype  TYPE string,
        leng      TYPE string,
        decimals  TYPE string,
        descr     TYPE string,
      END OF ty_s_ddic_field.
    TYPES ty_t_ddic_field TYPE STANDARD TABLE OF ty_s_ddic_field WITH EMPTY KEY.

* =====================================================================
*  SE24 - Class Builder
* =====================================================================
    TYPES:
      BEGIN OF ty_s_class,
        clsname TYPE string,
        clstype TYPE string,
        descr   TYPE string,
      END OF ty_s_class.
    TYPES ty_t_class TYPE STANDARD TABLE OF ty_s_class WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_component,
        cmpname  TYPE string,
        cmptype  TYPE string,
        mtdtype  TYPE string,
        exposure TYPE string,
        redefin  TYPE string,
      END OF ty_s_component.
    TYPES ty_t_component TYPE STANDARD TABLE OF ty_s_component WITH EMPTY KEY.

* =====================================================================
*  SE37 - Function Builder
* =====================================================================
    TYPES:
      BEGIN OF ty_s_function,
        funcname TYPE string,
        area     TYPE string,
        stext    TYPE string,
        rfc      TYPE string,
      END OF ty_s_function.
    TYPES ty_t_function TYPE STANDARD TABLE OF ty_s_function WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_fparam,
        pos       TYPE string,
        kind      TYPE string,
        parameter TYPE string,
        typing    TYPE string,
        reference TYPE string,
        optional  TYPE string,
        default   TYPE string,
      END OF ty_s_fparam.
    TYPES ty_t_fparam TYPE STANDARD TABLE OF ty_s_fparam WITH EMPTY KEY.

* =====================================================================
*  SE38 - ABAP Editor
* =====================================================================
    TYPES:
      BEGIN OF ty_s_program,
        name    TYPE string,
        subc    TYPE string,
        kind    TYPE string,
        author  TYPE string,
        chdate  TYPE string,
        package TYPE string,
      END OF ty_s_program.
    TYPES ty_t_program TYPE STANDARD TABLE OF ty_s_program WITH EMPTY KEY.

* =====================================================================
*  SM37 - Job Overview
* =====================================================================
    TYPES:
      BEGIN OF ty_s_job,
        jobname   TYPE string,
        jobcount  TYPE string,
        status    TYPE string,
        statustxt TYPE string,
        state     TYPE string,
        sdldate   TYPE string,
        sdltime   TYPE string,
        strtdate  TYPE string,
        strttime  TYPE string,
        enddate   TYPE string,
        endtime   TYPE string,
        duration  TYPE string,
        owner     TYPE string,
        server    TYPE string,
        periodic  TYPE string,
      END OF ty_s_job.
    TYPES ty_t_job TYPE STANDARD TABLE OF ty_s_job WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_jobstep,
        stepcount TYPE string,
        progname  TYPE string,
        variant   TYPE string,
        authcknam TYPE string,
        language  TYPE string,
        status    TYPE string,
      END OF ty_s_jobstep.
    TYPES ty_t_jobstep TYPE STANDARD TABLE OF ty_s_jobstep WITH EMPTY KEY.

* =====================================================================
*  ST22 - ABAP Dump Analysis
* =====================================================================
    TYPES:
      BEGIN OF ty_s_dump,
        datum    TYPE string,
        uzeit    TYPE string,
        uname    TYPE string,
        mandt    TYPE string,
        ahost    TYPE string,
        modno    TYPE string,
        errorid  TYPE string,
        program  TYPE string,
        incl     TYPE string,
        line     TYPE string,
        key_date TYPE d,
        key_time TYPE t,
        key_mod  TYPE string,
      END OF ty_s_dump.
    TYPES ty_t_dump TYPE STANDARD TABLE OF ty_s_dump WITH EMPTY KEY.

* =====================================================================
*  SU01 - User Maintenance
* =====================================================================
    TYPES:
      BEGIN OF ty_s_user,
        bname     TYPE string,
        fullname  TYPE string,
        ustyp     TYPE string,
        ustyptxt  TYPE string,
        lockstate TYPE string,
        validfrom TYPE string,
        validto   TYPE string,
        lastlogon TYPE string,
        createdby TYPE string,
      END OF ty_s_user.
    TYPES ty_t_user TYPE STANDARD TABLE OF ty_s_user WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_role,
        agr_name TYPE string,
        from_dat TYPE string,
        to_dat   TYPE string,
      END OF ty_s_role.
    TYPES ty_t_role TYPE STANDARD TABLE OF ty_s_role WITH EMPTY KEY.

* =====================================================================
*  SM50 / SM66 - Work Process Overview
* =====================================================================
    TYPES:
      BEGIN OF ty_s_wp,
        wp_no     TYPE string,
        wp_typ    TYPE string,
        wp_pid    TYPE string,
        wp_status TYPE string,
        wp_reason TYPE string,
        wp_start  TYPE string,
        wp_err    TYPE string,
        wp_sem    TYPE string,
        wp_cpu    TYPE string,
        wp_time   TYPE string,
        wp_report TYPE string,
        wp_client TYPE string,
        wp_user   TYPE string,
        wp_action TYPE string,
        wp_table  TYPE string,
      END OF ty_s_wp.
    TYPES ty_t_wp TYPE STANDARD TABLE OF ty_s_wp WITH EMPTY KEY.

* =====================================================================
*  SM12 - Lock Entries
* =====================================================================
    TYPES:
      BEGIN OF ty_s_lock,
        guname   TYPE string,
        gclient  TYPE string,
        gname    TYPE string,
        garg     TYPE string,
        gmode    TYPE string,
        gusecnt  TYPE string,
        gbcktype TYPE string,
        gtdate   TYPE string,
        gttime   TYPE string,
        gthost   TYPE string,
      END OF ty_s_lock.
    TYPES ty_t_lock TYPE STANDARD TABLE OF ty_s_lock WITH EMPTY KEY.

* =====================================================================
*  ST02 - Buffer Statistics
* =====================================================================
    TYPES:
      BEGIN OF ty_s_buffer,
        name       TYPE string,
        hitratio   TYPE string,
        alloc_size TYPE string,
        free_space TYPE string,
        dir_used   TYPE string,
        dir_free   TYPE string,
        swaps      TYPE string,
        db_access  TYPE string,
      END OF ty_s_buffer.
    TYPES ty_t_buffer TYPE STANDARD TABLE OF ty_s_buffer WITH EMPTY KEY.

* =====================================================================
*  STMS - Transport Requests
* =====================================================================
    TYPES:
      BEGIN OF ty_s_transport,
        trkorr     TYPE string,
        trfunction TYPE string,
        functxt    TYPE string,
        trstatus   TYPE string,
        statustxt  TYPE string,
        as4user    TYPE string,
        as4date    TYPE string,
        as4time    TYPE string,
        tarsystem  TYPE string,
        as4text    TYPE string,
        strkorr    TYPE string,
      END OF ty_s_transport.
    TYPES ty_t_transport TYPE STANDARD TABLE OF ty_s_transport WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_tr_object,
        pgmid    TYPE string,
        object   TYPE string,
        obj_name TYPE string,
        objfunc  TYPE string,
      END OF ty_s_tr_object.
    TYPES ty_t_tr_object TYPE STANDARD TABLE OF ty_s_tr_object WITH EMPTY KEY.

    TYPES:
      "! One request or task that contains an object (SE03)
      BEGIN OF ty_s_object_request,
        trkorr     TYPE string,
        strkorr    TYPE string,
        trfunction TYPE string,
        functxt    TYPE string,
        trstatus   TYPE string,
        statustxt  TYPE string,
        as4user    TYPE string,
        as4date    TYPE string,
        as4text    TYPE string,
        pgmid      TYPE string,
        object     TYPE string,
        obj_name   TYPE string,
      END OF ty_s_object_request.
    TYPES ty_t_object_request TYPE STANDARD TABLE OF ty_s_object_request WITH EMPTY KEY.

* =====================================================================
*  SCC4 - Client Maintenance
* =====================================================================
    TYPES:
      BEGIN OF ty_s_client,
        mandt      TYPE string,
        mtext      TYPE string,
        ort01      TYPE string,
        mwaer      TYPE string,
        category   TYPE string,
        cattxt     TYPE string,
        cccoractiv TYPE string,
        coracttxt  TYPE string,
        ccnocliind TYPE string,
        ccnocascad TYPE string,
        changeuser TYPE string,
        changedate TYPE string,
        logsys     TYPE string,
      END OF ty_s_client.
    TYPES ty_t_client TYPE STANDARD TABLE OF ty_s_client WITH EMPTY KEY.

* =====================================================================
*  STMS - Transport Management System
* =====================================================================
    TYPES:
      BEGIN OF ty_s_tms_system,
        sysnam  TYPE string,
        systxt  TYPE string,
        systyp  TYPE string,
        comsys  TYPE string,
        cfgstat TYPE string,
        desadm  TYPE string,
        moddat  TYPE string,
        modusr  TYPE string,
      END OF ty_s_tms_system.
    TYPES ty_t_tms_system TYPE STANDARD TABLE OF ty_s_tms_system WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_tms_queue,
        sysnam TYPE string,
        bufpos TYPE string,
        trkorr TYPE string,
        owner  TYPE string,
        tarcli TYPE string,
        maxrc  TYPE string,
        text   TYPE string,
      END OF ty_s_tms_queue.
    TYPES ty_t_tms_queue TYPE STANDARD TABLE OF ty_s_tms_queue WITH EMPTY KEY.

* =====================================================================
*  RZ10 / RZ11 - Profile Parameters
* =====================================================================
    TYPES:
      BEGIN OF ty_s_param,
        paraname TYPE string,
        value    TYPE string,
        grp      TYPE string,
        ptype    TYPE string,
        dynamic  TYPE string,
        descr    TYPE string,
      END OF ty_s_param.
    TYPES ty_t_param TYPE STANDARD TABLE OF ty_s_param WITH EMPTY KEY.

* =====================================================================
*  SM21 - System Log
* =====================================================================
    TYPES:
      BEGIN OF ty_s_syslog,
        date   TYPE string,
        time   TYPE string,
        instid TYPE string,
        task   TYPE string,
        mand   TYPE string,
        user   TYPE string,
        tcode  TYPE string,
        repna  TYPE string,
        clasid TYPE string,
        text   TYPE string,
      END OF ty_s_syslog.
    TYPES ty_t_syslog TYPE STANDARD TABLE OF ty_s_syslog WITH EMPTY KEY.

* =====================================================================
*  ST05 - Performance Trace, state of the own instance
*  The fields follow structure ST05_TRACE_STATE of function module
*  ST05_GET_TRACE_STATE.
* =====================================================================
    TYPES:
      BEGIN OF ty_s_trace_state,
        sql_on       TYPE abap_bool,
        buf_on       TYPE abap_bool,
        enq_on       TYPE abap_bool,
        rfc_on       TYPE abap_bool,
        http_on      TYPE abap_bool,
        amc_on       TYPE abap_bool,
        apc_on       TYPE abap_bool,
        auth_on      TYPE abap_bool,
        stack_on     TYPE abap_bool,
        progress_on  TYPE abap_bool,
        filter_on    TYPE abap_bool,
        incl_missing TYPE abap_bool,
        any_on       TYPE abap_bool,
        "! abap_false when the kernel refused to tell the state - the
        "! flags above are then meaningless and must not be shown as "off"
        state_known  TYPE abap_bool,
        trace_user   TYPE string,
        tcode        TYPE string,
        program      TYPE string,
        rfc_function TYPE string,
        url          TYPE string,
        wp_id        TYPE string,
        incl_tables  TYPE string,
        excl_tables  TYPE string,
        mod_user     TYPE string,
        mod_date     TYPE string,
        mod_time     TYPE string,
        state_text   TYPE string,
      END OF ty_s_trace_state.

* =====================================================================
*  Methods - SE11 ABAP Dictionary
* =====================================================================
    "! Search tables/views (kind = TABL) or data elements (kind = DTEL)
    CLASS-METHODS search_ddic
      IMPORTING iv_pattern    TYPE string
                iv_kind       TYPE string DEFAULT 'TABL'
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_ddic_obj.

    CLASS-METHODS get_table_fields
      IMPORTING iv_tabname    TYPE string
      RETURNING VALUE(result) TYPE ty_t_ddic_field.

    CLASS-METHODS get_dtel_detail
      IMPORTING iv_rollname   TYPE string
      RETURNING VALUE(result) TYPE ty_t_kv.

* =====================================================================
*  Methods - SE24 Class Builder
* =====================================================================
    CLASS-METHODS search_classes
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_class.

    CLASS-METHODS get_class_components
      IMPORTING iv_clsname    TYPE string
      RETURNING VALUE(result) TYPE ty_t_component.

* =====================================================================
*  Methods - SE37 Function Builder
* =====================================================================
    CLASS-METHODS search_functions
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_function.

    CLASS-METHODS get_function_params
      IMPORTING iv_funcname   TYPE string
      RETURNING VALUE(result) TYPE ty_t_fparam.

* =====================================================================
*  Methods - SE38 ABAP Editor
* =====================================================================
    CLASS-METHODS search_programs
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_program.

    "! Reads the source of a report / include via READ REPORT
    CLASS-METHODS get_program_source
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  Methods - SM37 Job Overview
* =====================================================================
    CLASS-METHODS get_jobs
      IMPORTING iv_jobname    TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_job.

    CLASS-METHODS get_job_steps
      IMPORTING iv_jobname    TYPE string
                iv_jobcount   TYPE string
      RETURNING VALUE(result) TYPE ty_t_jobstep.

* =====================================================================
*  Methods - ST22 Dump Analysis
* =====================================================================
    CLASS-METHODS get_dumps
      IMPORTING iv_date_from  TYPE d OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_dump.

    CLASS-METHODS get_dump_detail
      IMPORTING iv_datum      TYPE d
                iv_uzeit      TYPE t
                iv_modno      TYPE string
      RETURNING VALUE(result) TYPE ty_t_kv.

    " Parses the tag/length/value encoded SNAP-FLIST field.
    " Format: 2 char tag + 3 digit length + value, repeated.
    CLASS-METHODS parse_flist
      IMPORTING iv_flist      TYPE string
      RETURNING VALUE(result) TYPE ty_t_kv.

* =====================================================================
*  Methods - SU01 User Maintenance
* =====================================================================
    CLASS-METHODS search_users
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_user.

    CLASS-METHODS get_user_roles
      IMPORTING iv_bname      TYPE string
      RETURNING VALUE(result) TYPE ty_t_role.

* =====================================================================
*  Methods - SM50 / SM66 Work Processes
* =====================================================================
    CLASS-METHODS get_work_processes
      EXPORTING et_wp         TYPE ty_t_wp
                ev_message    TYPE string.

* =====================================================================
*  Methods - SM12 Lock Entries
* =====================================================================
    CLASS-METHODS get_locks
      IMPORTING iv_table      TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
      EXPORTING et_locks      TYPE ty_t_lock
                ev_message    TYPE string.

* =====================================================================
*  Methods - ST02 Buffer & Memory
* =====================================================================
    CLASS-METHODS get_buffer_stats
      EXPORTING et_buffer     TYPE ty_t_buffer
                et_memory     TYPE ty_t_kv
                ev_message    TYPE string.

* =====================================================================
*  Methods - STMS Transport Requests
* =====================================================================
    CLASS-METHODS get_transports
      IMPORTING iv_user       TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_transport.

    CLASS-METHODS get_transport_objects
      IMPORTING iv_trkorr     TYPE string
                iv_max        TYPE i DEFAULT 5000
      RETURNING VALUE(result) TYPE ty_t_tr_object.

    "! Requests and tasks that contain an object (E071) - SE03, Search for
    "! Objects in Requests/Tasks. iv_obj_name takes * and +, iv_object
    "! empty means every object type. Newest first.
    CLASS-METHODS search_object_in_requests
      IMPORTING iv_obj_name   TYPE string
                iv_object     TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 500
      RETURNING VALUE(result) TYPE ty_t_object_request.

* =====================================================================
*  Methods - STMS Transport Management System
* =====================================================================
    "! Transport domain and the own system, read from TMSCSYS
    CLASS-METHODS get_tms_domain
      EXPORTING ev_domain  TYPE string
                ev_system  TYPE string
                ev_message TYPE string.

    "! All systems of the transport domain (TMSCSYS)
    CLASS-METHODS get_tms_systems
      RETURNING VALUE(result) TYPE ty_t_tms_system.

    "! Import queue of every system of the domain (TMSBUFFER)
    CLASS-METHODS get_tms_queue
      IMPORTING iv_max        TYPE i DEFAULT 5000
      RETURNING VALUE(result) TYPE ty_t_tms_queue.

* =====================================================================
*  Methods - SCC4 Client Maintenance
* =====================================================================
    CLASS-METHODS get_clients
      RETURNING VALUE(result) TYPE ty_t_client.

* =====================================================================
*  Methods - RZ10 / RZ11 Profile Parameters
* =====================================================================
    CLASS-METHODS search_parameters
      IMPORTING iv_pattern       TYPE string OPTIONAL
                iv_only_dynamic  TYPE abap_bool DEFAULT abap_false
                iv_max           TYPE i DEFAULT 300
      RETURNING VALUE(result)    TYPE ty_t_param.

    CLASS-METHODS get_parameter_detail
      IMPORTING iv_paraname   TYPE string
      RETURNING VALUE(result) TYPE ty_t_kv.

* =====================================================================
*  Methods - SM21 System Log
* =====================================================================
    CLASS-METHODS get_syslog
      IMPORTING iv_date_from  TYPE d OPTIONAL
                iv_time_from  TYPE t OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_time_to    TYPE t OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_tcode      TYPE string OPTIONAL
      EXPORTING et_syslog     TYPE ty_t_syslog
                ev_message    TYPE string.

* =====================================================================
*  Methods - ST05 Performance Trace
* =====================================================================
    "! ST05 trace evaluation is a kernel service without a released
    "! read API. This returns the trace relevant profile parameters so
    "! the app can show the current trace configuration.
    CLASS-METHODS get_trace_status
      RETURNING VALUE(result) TYPE ty_t_kv.

    "! Reads the real trace state of the own application server instance
    "! via ST05_GET_TRACE_STATE. Display only - it never switches a trace
    "! on or off.
    CLASS-METHODS get_trace_state
      EXPORTING es_state   TYPE ty_s_trace_state
                ev_message TYPE string.

* =====================================================================
*  Shared helpers
* =====================================================================
    "! Turns SAP GUI style patterns into an SQL LIKE pattern
    CLASS-METHODS to_like_pattern
      IMPORTING iv_pattern    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Date input of a selection screen (YYYYMMDD, YYYY-MM-DD, DD.MM.YYYY);
    "! iv_default when the input is no calendar date
    CLASS-METHODS parse_date
      IMPORTING iv_in         TYPE string
                iv_default    TYPE d
      RETURNING VALUE(result) TYPE d.

    CLASS-METHODS format_date
      IMPORTING iv_date       TYPE d
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS format_time
      IMPORTING iv_time       TYPE t
      RETURNING VALUE(result) TYPE string.

    "! Kernel parameter type number -> the text RSPFLDOC shows
    CLASS-METHODS param_type_text
      IMPORTING iv_type       TYPE spfl_parameter_type
      RETURNING VALUE(result) TYPE string.

    "! Parameter origin -> the resulting source text RSPFLDOC shows
    CLASS-METHODS param_origin_text
      IMPORTING iv_origin     TYPE i
      RETURNING VALUE(result) TYPE string.

    "! Numeric metadata flag -> Yes / No
    CLASS-METHODS yes_no
      IMPORTING iv_flag       TYPE n
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SAP Easy Access - area menu (SE43 hierarchy)
* =====================================================================
    TYPES:
      "! One entry of an SAP area menu. Folders carry either children
      "! inside the same structure or a reference to a sub structure,
      "! transactions carry a transaction code.
      BEGIN OF ty_s_menu_node,
        node_key  TYPE string,       " structure + node, unique per entry
        struct_id TYPE string,
        node_id   TYPE string,
        text      TYPE string,
        tcode     TYPE string,       " filled for transaction entries
        sub_tree  TYPE string,       " referenced sub structure
        sub_node  TYPE string,       " node inside the referenced structure
        is_folder TYPE abap_bool,
      END OF ty_s_menu_node.
    TYPES ty_t_menu_node TYPE STANDARD TABLE OF ty_s_menu_node WITH EMPTY KEY.

    "! Reads the children of one node of an SAP area menu.
    "! iv_struct_id - area menu, S000 is the SAP standard menu
    "! iv_node_id   - parent node, initial returns the top level
    CLASS-METHODS get_area_menu_children
      IMPORTING iv_struct_id  TYPE string DEFAULT 'S000'
                iv_node_id    TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ty_t_menu_node.

    "! Does the transaction code exist in this system?
    CLASS-METHODS transaction_exists
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! Short text of a transaction as shown by the SAP GUI
    CLASS-METHODS get_transaction_text
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SE93 - Maintain Transaction
* =====================================================================
    TYPES:
      "! One row of the transaction hit list
      BEGIN OF ty_s_tcode,
        tcode   TYPE string,
        ttext   TYPE string,
        pgmna   TYPE string,
        dypno   TYPE string,
        tc_type TYPE string,
      END OF ty_s_tcode.
    TYPES ty_t_tcode TYPE STANDARD TABLE OF ty_s_tcode WITH EMPTY KEY.

    TYPES:
      "! One default value of a parameter transaction (TSTCP-PARAM)
      BEGIN OF ty_s_tc_param,
        field TYPE string,
        value TYPE string,
      END OF ty_s_tc_param.
    TYPES ty_t_tc_param TYPE STANDARD TABLE OF ty_s_tc_param WITH EMPTY KEY.

    TYPES:
      "! One authorization check value of a transaction (TSTCA)
      BEGIN OF ty_s_tc_auth,
        objct TYPE string,
        field TYPE string,
        value TYPE string,
      END OF ty_s_tc_auth.
    TYPES ty_t_tc_auth TYPE STANDARD TABLE OF ty_s_tc_auth WITH EMPTY KEY.

    TYPES:
      "! Everything SE93 shows for one transaction. Which fields carry a
      "! value depends on TC_TYPE - the original has one display screen per
      "! type (SAPLSEUK 0310 dialog, 0320 report, 0330 parameter,
      "! 0331 variant, 0360 object).
      BEGIN OF ty_s_tcode_detail,
        found       TYPE abap_bool,
        tcode       TYPE string,
        ttext       TYPE string,
        tc_type     TYPE string,
        " dialog and report transaction
        pgmna       TYPE string,
        dypno       TYPE string,
        repo_vari   TYPE string,
        " object transaction
        classname   TYPE string,
        method      TYPE string,
        s_local     TYPE abap_bool,
        s_trframe   TYPE abap_bool,
        "! S synchronous, U asynchronous, L local - LSEUKTOP c_oo_synchron
        upd_mode    TYPE string,
        " parameter and variant transaction
        call_tcode  TYPE string,
        variant     TYPE string,
        s_ind_vari  TYPE abap_bool,
        skip_first  TYPE abap_bool,
        start_tcode TYPE abap_bool,
        params      TYPE ty_t_tc_param,
        " start options
        locked_sm01 TYPE abap_bool,
        trans_var   TYPE abap_bool,
        " authorization object
        auth_objct  TYPE string,
        auth        TYPE ty_t_tc_auth,
        " classification (TSTCC)
        profi_tran  TYPE abap_bool,
        iac_ewt     TYPE abap_bool,
        s_win32     TYPE abap_bool,
        s_platin    TYPE abap_bool,
        s_webgui    TYPE abap_bool,
      END OF ty_s_tcode_detail.

    "! Transactions of TSTC with their short text and derived type.
    CLASS-METHODS get_transactions
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_tcode.

    "! Everything SE93 shows for one transaction.
    CLASS-METHODS get_transaction_detail
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE ty_s_tcode_detail.

    "! A text symbol of SAPLSEUK, the program behind SE93. The names of the
    "! transaction types live there (001 Dialog, 002 Report, 003 Parameter,
    "! 019 Variant, 028 Object Transaction), so they are read from the
    "! original instead of being duplicated here.
    CLASS-METHODS seuk_text
      IMPORTING iv_key        TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SLG1 - Application Log
* =====================================================================
    TYPES:
      "! One log of the hit list (BALHDR)
      BEGIN OF ty_s_applog,
        lognumber TYPE string,
        object    TYPE string,
        subobject TYPE string,
        extnumber TYPE string,
        aldate    TYPE string,
        altime    TYPE string,
        aluser    TYPE string,
        altcode   TYPE string,
        alprog    TYPE string,
        msg_all   TYPE string,
        msg_err   TYPE string,
        msg_warn  TYPE string,
        handle    TYPE string,
        "! Error / Warning / Success - the traffic light of SLG1
        state     TYPE string,
      END OF ty_s_applog.
    TYPES ty_t_applog TYPE STANDARD TABLE OF ty_s_applog WITH EMPTY KEY.

    TYPES:
      "! One message of a log
      BEGIN OF ty_s_applog_msg,
        msgno    TYPE string,
        severity TYPE string,
        sevtext  TYPE string,
        state    TYPE string,
        text     TYPE string,
        tstamp   TYPE string,
      END OF ty_s_applog_msg.
    TYPES ty_t_applog_msg TYPE STANDARD TABLE OF ty_s_applog_msg WITH EMPTY KEY.

    "! Logs of BALHDR. Only logs the user may display (S_APPL_LOG) are returned.
    CLASS-METHODS get_app_logs
      IMPORTING iv_object     TYPE string OPTIONAL
                iv_subobject  TYPE string OPTIONAL
                iv_user       TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_applog.

    "! Messages of one log, read with BAL_DB_LOAD / BAL_LOG_MSG_READ
    CLASS-METHODS get_app_log_messages
      IMPORTING iv_lognumber  TYPE string
      EXPORTING et_messages   TYPE ty_t_applog_msg
                ev_message    TYPE string.

* =====================================================================
*  SM59 - RFC Destinations
* =====================================================================
    TYPES:
      "! One RFC destination. Logon data (user, password, client) is never
      "! read - only the technical target.
      BEGIN OF ty_s_rfcdest,
        rfcdest  TYPE string,
        rfctype  TYPE string,
        typetext TYPE string,
        target   TYPE string,
        sysnr    TYPE string,
        descr    TYPE string,
      END OF ty_s_rfcdest.
    TYPES ty_t_rfcdest TYPE STANDARD TABLE OF ty_s_rfcdest WITH EMPTY KEY.

    "! RFC destinations of RFCDES the user may display (S_RFC_ADM)
    CLASS-METHODS get_rfc_destinations
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_rfctype    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 500
      RETURNING VALUE(result) TYPE ty_t_rfcdest.

    "! Text of an RFC connection type (domain RFCTYPE)
    CLASS-METHODS rfc_type_text
      IMPORTING iv_rfctype    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Value of one KEY= component of RFCDES-RFCOPTIONS (H=host,S=00,...)
    CLASS-METHODS rfc_option
      IMPORTING iv_options    TYPE string
                iv_key        TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SM04 - User List
* =====================================================================
    TYPES:
      "! One user session of the own instance (TH_USER_LIST, UINFO)
      BEGIN OF ty_s_session,
        client   TYPE string,
        bname    TYPE string,
        tcode    TYPE string,
        term     TYPE string,
        zeit     TYPE string,
        sessions TYPE string,
        typetext TYPE string,
        hostadr  TYPE string,
      END OF ty_s_session.
    TYPES ty_t_session TYPE STANDARD TABLE OF ty_s_session WITH EMPTY KEY.

    "! Users logged on to the own instance
    CLASS-METHODS get_user_sessions
      EXPORTING et_sessions TYPE ty_t_session
                ev_message  TYPE string.

* =====================================================================
*  SM37 - Job Log
* =====================================================================
    TYPES:
      "! One line of a job log (TBTC5)
      BEGIN OF ty_s_joblog,
        enterdate TYPE string,
        entertime TYPE string,
        msgtype   TYPE string,
        state     TYPE string,
        text      TYPE string,
        msgid     TYPE string,
        msgno     TYPE string,
      END OF ty_s_joblog.
    TYPES ty_t_joblog TYPE STANDARD TABLE OF ty_s_joblog WITH EMPTY KEY.

    "! Job log of one job (BP_JOBLOG_READ). Logs of other users' jobs need
    "! S_BTCH_JOB PROT or S_BTCH_ADM, like SM37.
    CLASS-METHODS get_job_log
      IMPORTING iv_jobname  TYPE string
                iv_jobcount TYPE string
      EXPORTING et_log      TYPE ty_t_joblog
                ev_message  TYPE string.

* =====================================================================
*  SM30 - what kind of dictionary object a name is
* =====================================================================
    CONSTANTS:
      BEGIN OF c_table_kind,
        table     TYPE string VALUE `TABLE`,
        db_view   TYPE string VALUE `DBVIEW`,
        maint_view TYPE string VALUE `MAINTVIEW`,
        other_view TYPE string VALUE `VIEW`,
        structure TYPE string VALUE `STRUCTURE`,
        none      TYPE string VALUE `NONE`,
      END OF c_table_kind.

    "! Kind of a dictionary object (DD02L-TABCLASS / DD25L-VIEWCLASS)
    CLASS-METHODS get_table_kind
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SE24 / SE37 - source include of a method / function module
* =====================================================================
    "! Include that holds the implementation of a class method
    "! (ZCL_X=====CM001). Initial when the method has no implementation.
    CLASS-METHODS get_method_include
      IMPORTING iv_class      TYPE string
                iv_method     TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Include that holds the source of a function module (LxxxUnn)
    CLASS-METHODS get_function_include
      IMPORTING iv_funcname   TYPE string
      RETURNING VALUE(result) TYPE string.

* =====================================================================
*  SU53 - failed authorization checks
* =====================================================================
    TYPES:
      "! One failed authorization check (USR07_EXT)
      BEGIN OF ty_s_authfail,
        date     TYPE string,
        time     TYPE string,
        instance TYPE string,
        objct    TYPE string,
        objtext  TYPE string,
        "! FIELD = value, FIELD = value ... as SU53 lists them
        fields   TYPE string,
        rc       TYPE string,
        reason   TYPE string,
        tcode    TYPE string,
        program  TYPE string,
        line     TYPE string,
      END OF ty_s_authfail.
    TYPES ty_t_authfail TYPE STANDARD TABLE OF ty_s_authfail WITH EMPTY KEY.

    "! Failed authorization checks of a user during the last iv_seconds,
    "! read like SU53 with SUSR_USER_SU53_READ. Other users need S_USER_GRP.
    CLASS-METHODS get_auth_failures
      IMPORTING iv_bname   TYPE string
                iv_seconds TYPE i DEFAULT 10800
      EXPORTING et_fails   TYPE ty_t_authfail
                ev_message TYPE string.

* =====================================================================
*  SP01 - Output Controller (spool requests)
* =====================================================================
    TYPES:
      BEGIN OF ty_s_spool,
        rqident TYPE string,
        doctype TYPE string,
        date    TYPE string,
        time    TYPE string,
        "! status text of the SP01 list: -, +, Waiting, Compl., Error ...
        status  TYPE string,
        "! UI5 value state of the status: Success / Warning / Error / None
        state   TYPE string,
        pages   TYPE string,
        title   TYPE string,
        owner   TYPE string,
        dest    TYPE string,
      END OF ty_s_spool.
    TYPES ty_t_spool TYPE STANDARD TABLE OF ty_s_spool WITH EMPTY KEY.

    "! Spool requests of the logon client, newest first, that the user may
    "! see (RSPO_CHECK_JOB_PERMISSION BASE). Owner: user name or pattern.
    CLASS-METHODS get_spool_requests
      IMPORTING iv_owner      TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE ty_t_spool.

    "! Content of an ABAP list spool request (RSPO_RETURN_ABAP_SPOOLJOB),
    "! after RSPO_CHECK_JOB_PERMISSION DISP
    CLASS-METHODS get_spool_content
      IMPORTING iv_rqident   TYPE string
                iv_max_lines TYPE i DEFAULT 5000
      EXPORTING et_lines     TYPE string_table
                ev_message   TYPE string.

* =====================================================================
*  WE02 / WE05 - IDoc List
* =====================================================================
    TYPES:
      BEGIN OF ty_s_idoc,
        docnum   TYPE string,
        status   TYPE string,
        stattext TYPE string,
        "! traffic light of the status (STACUST / STALIGHT) as value state
        state    TYPE string,
        direct   TYPE string,
        mestyp   TYPE string,
        idoctp   TYPE string,
        partner  TYPE string,
        credat   TYPE string,
        cretim   TYPE string,
        upddat   TYPE string,
        updtim   TYPE string,
      END OF ty_s_idoc.
    TYPES ty_t_idoc TYPE STANDARD TABLE OF ty_s_idoc WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_idoc_status,
        counter TYPE string,
        status  TYPE string,
        state   TYPE string,
        stattext TYPE string,
        message TYPE string,
        date    TYPE string,
        time    TYPE string,
        user    TYPE string,
        program TYPE string,
      END OF ty_s_idoc_status.
    TYPES ty_t_idoc_status TYPE STANDARD TABLE OF ty_s_idoc_status WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_idoc_seg,
        segnum TYPE string,
        segnam TYPE string,
        hlevel TYPE string,
        "! the segment name indented by its hierarchy level
        tree   TYPE string,
        sdata  TYPE string,
      END OF ty_s_idoc_seg.
    TYPES ty_t_idoc_seg TYPE STANDARD TABLE OF ty_s_idoc_seg WITH EMPTY KEY.

    "! IDocs of EDIDC the user may see (S_IDOCMONI + BAdI, as WE02)
    CLASS-METHODS get_idocs
      IMPORTING iv_docnum     TYPE string OPTIONAL
                iv_mestyp     TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_direct     TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 500
      RETURNING VALUE(result) TYPE ty_t_idoc.

    "! One IDoc with control record, status records and data records
    "! (IDOC_READ_COMPLETELY), after the WE02 authorization check
    CLASS-METHODS get_idoc_detail
      IMPORTING iv_docnum   TYPE string
      EXPORTING es_idoc     TYPE ty_s_idoc
                et_control  TYPE ty_t_kv
                et_status   TYPE ty_t_idoc_status
                et_segments TYPE ty_t_idoc_seg
                ev_message  TYPE string.

* =====================================================================
*  PFCG - Role Maintenance (display)
* =====================================================================
    TYPES:
      BEGIN OF ty_s_agr,
        agr_name  TYPE string,
        text      TYPE string,
        composite TYPE string,
        parent    TYPE string,
        changed_by TYPE string,
        changed_on TYPE string,
      END OF ty_s_agr.
    TYPES ty_t_agr TYPE STANDARD TABLE OF ty_s_agr WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_agr_tcode,
        tcode TYPE string,
        text  TYPE string,
      END OF ty_s_agr_tcode.
    TYPES ty_t_agr_tcode TYPE STANDARD TABLE OF ty_s_agr_tcode WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_agr_auth,
        object TYPE string,
        auth   TYPE string,
        field  TYPE string,
        low    TYPE string,
        high   TYPE string,
      END OF ty_s_agr_auth.
    TYPES ty_t_agr_auth TYPE STANDARD TABLE OF ty_s_agr_auth WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_agr_user,
        uname    TYPE string,
        from_dat TYPE string,
        to_dat   TYPE string,
        "! Valid / Expired / Future - against today
        validity TYPE string,
        state    TYPE string,
      END OF ty_s_agr_user.
    TYPES ty_t_agr_user TYPE STANDARD TABLE OF ty_s_agr_user WITH EMPTY KEY.

    "! Roles of AGR_DEFINE the user may display (S_USER_AGR 03)
    CLASS-METHODS search_roles
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 300
      RETURNING VALUE(result) TYPE ty_t_agr.

    "! The tabs of a role in PFCG: description, menu, authorizations,
    "! user assignment, and the single roles of a composite role
    CLASS-METHODS get_role_detail
      IMPORTING iv_role     TYPE string
      EXPORTING et_head     TYPE ty_t_kv
                et_descr    TYPE string_table
                et_tcodes   TYPE ty_t_agr_tcode
                et_auth     TYPE ty_t_agr_auth
                et_users    TYPE ty_t_agr_user
                et_roles    TYPE ty_t_agr
                ev_message  TYPE string.

* =====================================================================
*  SE91 - Message Maintenance (display)
* =====================================================================
    TYPES:
      BEGIN OF ty_s_msgclass,
        arbgb    TYPE string,
        stext    TYPE string,
        devclass TYPE string,
      END OF ty_s_msgclass.
    TYPES ty_t_msgclass TYPE STANDARD TABLE OF ty_s_msgclass WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_msg,
        msgnr    TYPE string,
        text     TYPE string,
        selfdef  TYPE string,
        longtext TYPE string,
      END OF ty_s_msg.
    TYPES ty_t_msg TYPE STANDARD TABLE OF ty_s_msg WITH EMPTY KEY.

    "! Message classes of T100A the user may display (S_DEVELOP MSAG)
    CLASS-METHODS search_message_classes
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 300
      RETURNING VALUE(result) TYPE ty_t_msgclass.

    "! Attributes and messages of a message class in the logon language
    "! (master language when a text is not translated)
    CLASS-METHODS get_messages
      IMPORTING iv_arbgb    TYPE string
      EXPORTING et_head     TYPE ty_t_kv
                et_msgs     TYPE ty_t_msg
                ev_message  TYPE string.

    "! Long text of a message (document class NA) as plain lines
    CLASS-METHODS get_message_longtext
      IMPORTING iv_arbgb      TYPE string
                iv_msgnr      TYPE string
      RETURNING VALUE(result) TYPE string_table.

* =====================================================================
*  System > Status of the SAP GUI
* =====================================================================
    TYPES:
      BEGIN OF ty_s_status,
        group TYPE string,
        label TYPE string,
        value TYPE string,
      END OF ty_s_status.
    TYPES ty_t_status TYPE STANDARD TABLE OF ty_s_status WITH EMPTY KEY.

    "! The data of the System: Status dialog - usage data, repository data
    "! of the running transaction, SAP, host and database data
    CLASS-METHODS get_system_status
      IMPORTING iv_tcode      TYPE string OPTIONAL
                iv_program    TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ty_t_status.

  PRIVATE SECTION.

    "! The implementation on a real system. Created by name, so that this
    "! class - and every app - does not depend on the database layer:
    "! the unit tests run transpiled without it (README, Development).
    CONSTANTS c_db_class TYPE string VALUE `ZCL_SAPGUI_SYS_API_DB`.

    "! Set by ZCL_SAPGUI_SYS_API_DBL in a unit test, else created by api( )
    CLASS-DATA go_api TYPE REF TO zif_sapgui_sys_api.

    "! The instance every reading method hands over to
    CLASS-METHODS api
      RETURNING VALUE(result) TYPE REF TO zif_sapgui_sys_api.

ENDCLASS.


CLASS zcl_sapgui_sys_api IMPLEMENTATION.


  METHOD api.

    IF go_api IS NOT BOUND.
      CREATE OBJECT go_api TYPE (c_db_class).
    ENDIF.
    result = go_api.

  ENDMETHOD.


  METHOD to_like_pattern.

    DATA(lv_in) = to_upper( condense( iv_pattern ) ).
    IF lv_in IS INITIAL.
      result = '%'.
      RETURN.
    ENDIF.

    " _ and % in a name are literal characters (SAP_BC_BASIS_ADMIN,
    " /ABC/...) - masked with #, every caller selects with ESCAPE '#'.
    " Only the SAP GUI wildcards * and + become SQL wildcards.
    result = lv_in.
    REPLACE ALL OCCURRENCES OF '#' IN result WITH '##'.
    REPLACE ALL OCCURRENCES OF '_' IN result WITH '#_'.
    REPLACE ALL OCCURRENCES OF '%' IN result WITH '#%'.
    REPLACE ALL OCCURRENCES OF '*' IN result WITH '%'.
    REPLACE ALL OCCURRENCES OF '+' IN result WITH '_'.
    IF lv_in NA '*+'.
      result = |{ result }%|.
    ENDIF.

  ENDMETHOD.


  METHOD parse_date.

    DATA lv_date TYPE d.

    " YYYYMMDD, YYYY-MM-DD, YYYY.MM.DD or the German DD.MM.YYYY; anything
    " that is no calendar date gives the default - never an open selection
    result = iv_default.
    DATA(lv_in) = condense( iv_in ).
    IF lv_in CP '++.++.++++' AND strlen( lv_in ) = 10.
      lv_in = |{ lv_in+6(4) }{ lv_in+3(2) }{ lv_in(2) }|.
    ELSE.
      REPLACE ALL OCCURRENCES OF `.` IN lv_in WITH ``.
      REPLACE ALL OCCURRENCES OF `-` IN lv_in WITH ``.
      REPLACE ALL OCCURRENCES OF `/` IN lv_in WITH ``.
    ENDIF.
    IF strlen( lv_in ) <> 8 OR lv_in CN `0123456789`.
      RETURN.
    ENDIF.

    " the calendar check of DATE_CHECK_PLAUSIBILITY, computed here so
    " that a selection screen needs no function module
    DATA(lv_year)  = CONV i( lv_in(4) ).
    DATA(lv_month) = CONV i( lv_in+4(2) ).
    DATA(lv_day)   = CONV i( lv_in+6(2) ).
    IF lv_year < 1 OR lv_month < 1 OR lv_month > 12 OR lv_day < 1.
      RETURN.
    ENDIF.
    DATA(lv_leap) = xsdbool( ( lv_year MOD 4 = 0 AND lv_year MOD 100 <> 0 ) OR lv_year MOD 400 = 0 ).
    DATA(lv_last) = SWITCH i( lv_month
                      WHEN 2 THEN COND #( WHEN lv_leap = abap_true THEN 29 ELSE 28 )
                      WHEN 4 OR 6 OR 9 OR 11 THEN 30
                      ELSE 31 ).
    IF lv_day > lv_last.
      RETURN.
    ENDIF.

    lv_date = lv_in.
    result = lv_date.

  ENDMETHOD.


  METHOD format_date.

    IF iv_date IS INITIAL.
      RETURN.
    ENDIF.
    result = |{ iv_date+6(2) }.{ iv_date+4(2) }.{ iv_date(4) }|.

  ENDMETHOD.


  METHOD format_time.

    IF iv_time IS INITIAL.
      RETURN.
    ENDIF.
    result = |{ iv_time(2) }:{ iv_time+2(2) }:{ iv_time+4(2) }|.

  ENDMETHOD.


  METHOD search_ddic.
    result = api( )->search_ddic( iv_pattern = iv_pattern iv_kind = iv_kind iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_table_fields.
    result = api( )->get_table_fields( iv_tabname ).
  ENDMETHOD.


  METHOD get_dtel_detail.
    result = api( )->get_dtel_detail( iv_rollname ).
  ENDMETHOD.


  METHOD search_classes.
    result = api( )->search_classes( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_class_components.
    result = api( )->get_class_components( iv_clsname ).
  ENDMETHOD.


  METHOD search_functions.
    result = api( )->search_functions( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_function_params.
    result = api( )->get_function_params( iv_funcname ).
  ENDMETHOD.


  METHOD search_programs.
    result = api( )->search_programs( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_program_source.
    result = api( )->get_program_source( iv_name ).
  ENDMETHOD.


  METHOD get_jobs.
    result = api( )->get_jobs( iv_jobname = iv_jobname iv_user = iv_user iv_status = iv_status iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_job_steps.
    result = api( )->get_job_steps( iv_jobname = iv_jobname iv_jobcount = iv_jobcount ).
  ENDMETHOD.


  METHOD parse_flist.

    DATA(lv_len) = strlen( iv_flist ).
    DATA(lv_off) = 0.

    WHILE lv_off + 5 <= lv_len.

      DATA(lv_tag)  = substring( val = iv_flist off = lv_off len = 2 ).
      DATA(lv_size) = substring( val = iv_flist off = lv_off + 2 len = 3 ).

      IF lv_size CN '0123456789'.
        EXIT.
      ENDIF.

      DATA(lv_vlen) = CONV i( lv_size ).
      lv_off = lv_off + 5.
      IF lv_off + lv_vlen > lv_len.
        lv_vlen = lv_len - lv_off.
      ENDIF.
      IF lv_vlen <= 0.
        EXIT.
      ENDIF.

      APPEND VALUE #( label = lv_tag
                      value = substring( val = iv_flist
                                         off = lv_off
                                         len = lv_vlen ) ) TO result.
      lv_off = lv_off + lv_vlen.

    ENDWHILE.

  ENDMETHOD.


  METHOD get_dumps.
    result = api( )->get_dumps( iv_date_from = iv_date_from iv_user = iv_user iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_dump_detail.
    result = api( )->get_dump_detail( iv_datum = iv_datum iv_uzeit = iv_uzeit iv_modno = iv_modno ).
  ENDMETHOD.


  METHOD search_users.
    result = api( )->search_users( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_user_roles.
    result = api( )->get_user_roles( iv_bname ).
  ENDMETHOD.


  METHOD get_work_processes.
    api( )->get_work_processes( IMPORTING et_wp = et_wp ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_locks.
    api( )->get_locks( EXPORTING iv_table = iv_table iv_user = iv_user IMPORTING et_locks = et_locks ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_buffer_stats.
    api( )->get_buffer_stats( IMPORTING et_buffer = et_buffer et_memory = et_memory ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_tms_domain.
    api( )->get_tms_domain( IMPORTING ev_domain = ev_domain ev_system = ev_system ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_tms_systems.
    result = api( )->get_tms_systems( ).
  ENDMETHOD.


  METHOD get_tms_queue.
    result = api( )->get_tms_queue( iv_max ).
  ENDMETHOD.


  METHOD get_transports.
    result = api( )->get_transports( iv_user = iv_user iv_status = iv_status iv_max = iv_max ).
  ENDMETHOD.


  METHOD search_object_in_requests.
    result = api( )->search_object_in_requests( iv_obj_name = iv_obj_name iv_object = iv_object iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_transport_objects.
    result = api( )->get_transport_objects( iv_trkorr = iv_trkorr iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_clients.
    result = api( )->get_clients( ).
  ENDMETHOD.


  METHOD search_parameters.
    result = api( )->search_parameters( iv_pattern = iv_pattern iv_only_dynamic = iv_only_dynamic iv_max = iv_max ).
  ENDMETHOD.


  METHOD param_type_text.

*   The parameter type numbers come from the kernel enum in sapparam.h,
*   the texts are the ones RSPFLDOC uses (text elements 530 - 536).
    result = SWITCH string( iv_type
               WHEN 200 THEN `String`
               WHEN 201 THEN `Integer`
               WHEN 202 THEN `Double`
               WHEN 203 THEN `Integer Interval`
               WHEN 204 THEN `Double Interval`
               WHEN 205 THEN `Enumeration`
               WHEN 206 THEN `Boolean Value`
               ELSE |{ iv_type }| ).

  ENDMETHOD.


  METHOD param_origin_text.

*   Text of the resulting source, exactly as RSPFLDOC maps it
*   (text elements 538, 519, 520, 539, 544).
    result = SWITCH string( iv_origin
               WHEN 0  THEN `Kernel Default`
               WHEN 1  THEN `Default Profile`
               WHEN 2  THEN `Instance Profile`
               WHEN 3  THEN `Dynamic Switching`
               WHEN 4  THEN `Kernel (Corrected)`
               ELSE `` ).

  ENDMETHOD.


  METHOD get_parameter_detail.
    result = api( )->get_parameter_detail( iv_paraname ).
  ENDMETHOD.


  METHOD yes_no.

*   RSPFLDOC text elements 511 / 512
    result = COND string( WHEN iv_flag = 1 THEN `Yes` ELSE `No` ).

  ENDMETHOD.


  METHOD get_syslog.
    api( )->get_syslog( EXPORTING iv_date_from = iv_date_from iv_time_from = iv_time_from iv_date_to = iv_date_to iv_time_to = iv_time_to iv_user = iv_user iv_tcode = iv_tcode IMPORTING et_syslog = et_syslog ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_trace_status.
    result = api( )->get_trace_status( ).
  ENDMETHOD.


  METHOD get_trace_state.
    api( )->get_trace_state( IMPORTING es_state = es_state ev_message = ev_message ).
  ENDMETHOD.


  METHOD get_area_menu_children.
    result = api( )->get_area_menu_children( iv_struct_id = iv_struct_id iv_node_id = iv_node_id ).
  ENDMETHOD.


  METHOD transaction_exists.
    result = api( )->transaction_exists( iv_tcode ).
  ENDMETHOD.


  METHOD get_transaction_text.
    result = api( )->get_transaction_text( iv_tcode ).
  ENDMETHOD.


  METHOD seuk_text.
    result = api( )->seuk_text( iv_key ).
  ENDMETHOD.


  METHOD get_transactions.
    result = api( )->get_transactions( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.


  METHOD get_transaction_detail.
    result = api( )->get_transaction_detail( iv_tcode ).
  ENDMETHOD.

  METHOD get_app_logs.
    result = api( )->get_app_logs( iv_object = iv_object iv_subobject = iv_subobject iv_user = iv_user iv_date_from = iv_date_from iv_date_to = iv_date_to iv_max = iv_max ).
  ENDMETHOD.

  METHOD get_app_log_messages.
    api( )->get_app_log_messages( EXPORTING iv_lognumber = iv_lognumber IMPORTING et_messages = et_messages ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_rfc_destinations.
    result = api( )->get_rfc_destinations( iv_pattern = iv_pattern iv_rfctype = iv_rfctype iv_max = iv_max ).
  ENDMETHOD.

  METHOD rfc_type_text.
    result = api( )->rfc_type_text( iv_rfctype ).
  ENDMETHOD.

  METHOD rfc_option.

    " RFCOPTIONS is a comma separated list of KEY=value pairs. Only the
    " keys asked for are returned - the caller decides what is shown.
    DATA(lv_key) = |{ to_upper( iv_key ) }=|.
    SPLIT iv_options AT `,` INTO TABLE DATA(lt_parts).
    LOOP AT lt_parts INTO DATA(lv_part).
      IF strlen( lv_part ) > strlen( lv_key )
         AND to_upper( substring( val = lv_part len = strlen( lv_key ) ) ) = lv_key.
        result = substring( val = lv_part off = strlen( lv_key ) ).
        RETURN.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_user_sessions.
    api( )->get_user_sessions( IMPORTING et_sessions = et_sessions ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_job_log.
    api( )->get_job_log( EXPORTING iv_jobname = iv_jobname iv_jobcount = iv_jobcount IMPORTING et_log = et_log ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_table_kind.
    result = api( )->get_table_kind( iv_name ).
  ENDMETHOD.

  METHOD get_method_include.
    result = api( )->get_method_include( iv_class = iv_class iv_method = iv_method ).
  ENDMETHOD.

  METHOD get_function_include.
    result = api( )->get_function_include( iv_funcname ).
  ENDMETHOD.

  METHOD get_auth_failures.
    api( )->get_auth_failures( EXPORTING iv_bname = iv_bname iv_seconds = iv_seconds IMPORTING et_fails = et_fails ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_spool_requests.
    result = api( )->get_spool_requests( iv_owner = iv_owner iv_date_from = iv_date_from iv_max = iv_max ).
  ENDMETHOD.

  METHOD get_spool_content.
    api( )->get_spool_content( EXPORTING iv_rqident = iv_rqident iv_max_lines = iv_max_lines IMPORTING et_lines = et_lines ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_idocs.
    result = api( )->get_idocs( iv_docnum = iv_docnum iv_mestyp = iv_mestyp iv_status = iv_status iv_direct = iv_direct iv_date_from = iv_date_from iv_date_to = iv_date_to iv_max = iv_max ).
  ENDMETHOD.

  METHOD get_idoc_detail.
    api( )->get_idoc_detail( EXPORTING iv_docnum = iv_docnum IMPORTING es_idoc = es_idoc et_control = et_control et_status = et_status et_segments = et_segments ev_message = ev_message ).
  ENDMETHOD.

  METHOD search_roles.
    result = api( )->search_roles( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.

  METHOD get_role_detail.
    api( )->get_role_detail( EXPORTING iv_role = iv_role IMPORTING et_head = et_head et_descr = et_descr et_tcodes = et_tcodes et_auth = et_auth et_users = et_users et_roles = et_roles ev_message = ev_message ).
  ENDMETHOD.

  METHOD search_message_classes.
    result = api( )->search_message_classes( iv_pattern = iv_pattern iv_max = iv_max ).
  ENDMETHOD.

  METHOD get_messages.
    api( )->get_messages( EXPORTING iv_arbgb = iv_arbgb IMPORTING et_head = et_head et_msgs = et_msgs ev_message = ev_message ).
  ENDMETHOD.

  METHOD get_message_longtext.
    result = api( )->get_message_longtext( iv_arbgb = iv_arbgb iv_msgnr = iv_msgnr ).
  ENDMETHOD.

  METHOD get_system_status.
    result = api( )->get_system_status( iv_tcode = iv_tcode iv_program = iv_program ).
  ENDMETHOD.

ENDCLASS.
