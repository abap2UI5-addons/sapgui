CLASS zcl_zlk05_sys_api DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  Shared system API for the SAP GUI look-alike apps of package $ZLK_05
*
*  All database and function module access lives here. The abap2UI5
*  apps (ZCL_SM37_A2U5, ZCL_ST22_A2U5, ...) only build views and
*  dispatch events - they never read the system directly.
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
      RETURNING VALUE(result) TYPE ty_t_tr_object.

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

    CLASS-METHODS format_date
      IMPORTING iv_date       TYPE d
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS format_time
      IMPORTING iv_time       TYPE t
      RETURNING VALUE(result) TYPE string.

    "! Reads a single profile parameter value from the kernel
    CLASS-METHODS get_param_value
      IMPORTING iv_name       TYPE string
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

  PRIVATE SECTION.

    CLASS-METHODS job_status_text
      IMPORTING iv_status     TYPE btcstatus
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS job_state_text
      IMPORTING iv_status     TYPE btcstatus
      RETURNING VALUE(result) TYPE string.

* ---------------------------------------------------------------------
*  Area menu - buffered hierarchy read
* ---------------------------------------------------------------------
    TYPES ty_t_hier_node TYPE STANDARD TABLE OF hier_iface WITH EMPTY KEY.
    TYPES ty_t_hier_ref  TYPE STANDARD TABLE OF hier_ref WITH EMPTY KEY.
    TYPES ty_t_hier_text TYPE STANDARD TABLE OF hier_texts WITH EMPTY KEY.
    TYPES:
      BEGIN OF ty_s_hierarchy,
        struct_id TYPE string,
        nodes     TYPE ty_t_hier_node,
        refs      TYPE ty_t_hier_ref,
        texts     TYPE ty_t_hier_text,
      END OF ty_s_hierarchy.
    TYPES ty_t_hierarchy TYPE STANDARD TABLE OF ty_s_hierarchy WITH EMPTY KEY.

    " Read buffer, filled per structure on first access
    CLASS-DATA mt_hier_buffer TYPE ty_t_hierarchy.

    CLASS-METHODS read_hierarchy
      IMPORTING iv_struct_id  TYPE string
      RETURNING VALUE(result) TYPE ty_s_hierarchy.

    CLASS-METHODS menu_text
      IMPORTING it_texts      TYPE ty_t_hier_text
                iv_node_id    TYPE hier_guid
      RETURNING VALUE(result) TYPE string.

* ---------------------------------------------------------------------
*  SE93 - transaction type, derived the way SAPLSEUK derives it
* ---------------------------------------------------------------------
    " Bits of TSTC-CINFO, taken from LSEUKTOP
    CONSTANTS c_cinfo_men TYPE x LENGTH 1 VALUE '01'.  " area menu
    CONSTANTS c_cinfo_par TYPE x LENGTH 1 VALUE '02'.  " parameter trans.
    CONSTANTS c_cinfo_chk TYPE x LENGTH 1 VALUE '04'.  " with check object
    CONSTANTS c_cinfo_obj TYPE x LENGTH 1 VALUE '08'.  " object transaction
    CONSTANTS c_cinfo_rpv TYPE x LENGTH 1 VALUE '10'.  " report with variant
    CONSTANTS c_cinfo_enq TYPE x LENGTH 1 VALUE '20'.  " locked via SM01
    CONSTANTS c_cinfo_rep TYPE x LENGTH 1 VALUE '80'.  " report transaction

    "! Transaction that carries the OO framework - LSEUKTOP c_oo_tcode
    CONSTANTS c_oo_tcode TYPE string VALUE `OS_APPLICATION`.

    " Text pool of SAPLSEUK, read on first access
    CLASS-DATA mt_seuk_text TYPE STANDARD TABLE OF textpool WITH EMPTY KEY.

    CLASS-METHODS tcode_type_text
      IMPORTING iv_cinfo      TYPE tstc-cinfo
                iv_param      TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    "! LSEUKF01, FORM split_parameters
    CLASS-METHODS split_tcode_parameters
      IMPORTING iv_param  TYPE string
      CHANGING  cs_detail TYPE ty_s_tcode_detail.

    "! One \TAG= component of the parameter string of an OO transaction.
    "! LSEUKF01, FORM split_parameters_comp.
    CLASS-METHODS oo_component
      IMPORTING iv_param      TYPE string
                iv_tag        TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS zcl_zlk05_sys_api IMPLEMENTATION.

  METHOD to_like_pattern.

    result = to_upper( condense( iv_pattern ) ).
    IF result IS INITIAL.
      result = '%'.
      RETURN.
    ENDIF.
    " SAP GUI wildcards -> SQL wildcards
    REPLACE ALL OCCURRENCES OF '*' IN result WITH '%'.
    REPLACE ALL OCCURRENCES OF '+' IN result WITH '_'.
    IF result NA '%_'.
      result = |{ result }%|.
    ENDIF.

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

  METHOD get_param_value.

    DATA lv_name  TYPE spfl_parameter_name.
    DATA lv_value TYPE string.

    lv_name = iv_name.
    TRY.
        DATA(lv_rc) = cl_spfl_profile_parameter=>get_value(
                          EXPORTING name  = lv_name
                          IMPORTING value = lv_value ).
        IF lv_rc = 0.
          result = lv_value.
        ENDIF.
      CATCH cx_root.
        CLEAR result.
    ENDTRY.

  ENDMETHOD.

  METHOD search_ddic.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    IF to_upper( iv_kind ) = 'DTEL'.

      SELECT FROM dd04l AS d
        LEFT OUTER JOIN dd04t AS t
          ON  t~rollname   = d~rollname
          AND t~ddlanguage = @sy-langu
          AND t~as4local   = 'A'
        FIELDS d~rollname, d~datatype, d~leng, d~as4user, d~as4date,
               t~ddtext
        WHERE d~rollname LIKE @lv_like
          AND d~as4local = 'A'
        ORDER BY d~rollname
        INTO TABLE @DATA(lt_dtel)
        UP TO @iv_max ROWS.

      LOOP AT lt_dtel ASSIGNING FIELD-SYMBOL(<d>).
        APPEND VALUE #( name     = <d>-rollname
                        kind     = `DTEL`
                        tabclass = |{ <d>-datatype } { <d>-leng ALPHA = OUT }|
                        descr    = <d>-ddtext
                        author   = <d>-as4user
                        chdate   = format_date( <d>-as4date ) ) TO result.
      ENDLOOP.

    ELSE.

      SELECT FROM dd02l AS d
        LEFT OUTER JOIN dd02t AS t
          ON  t~tabname    = d~tabname
          AND t~ddlanguage = @sy-langu
          AND t~as4local   = 'A'
        FIELDS d~tabname, d~tabclass, d~as4user, d~as4date, t~ddtext
        WHERE d~tabname LIKE @lv_like
          AND d~as4local = 'A'
        ORDER BY d~tabname
        INTO TABLE @DATA(lt_tab)
        UP TO @iv_max ROWS.

      LOOP AT lt_tab ASSIGNING FIELD-SYMBOL(<t>).
        APPEND VALUE #( name     = <t>-tabname
                        kind     = `TABL`
                        tabclass = <t>-tabclass
                        descr    = <t>-ddtext
                        author   = <t>-as4user
                        chdate   = format_date( <t>-as4date ) ) TO result.
      ENDLOOP.

    ENDIF.

  ENDMETHOD.

  METHOD get_table_fields.

    DATA(lv_tab) = CONV tabname( to_upper( condense( iv_tabname ) ) ).

    SELECT FROM dd03l AS f
      LEFT OUTER JOIN dd04t AS t
        ON  t~rollname   = f~rollname
        AND t~ddlanguage = @sy-langu
        AND t~as4local   = 'A'
      FIELDS f~position, f~fieldname, f~keyflag, f~rollname,
             f~datatype, f~leng, f~decimals, t~ddtext
      WHERE f~tabname    = @lv_tab
        AND f~as4local   = 'A'
        AND f~fieldname NOT LIKE '.%'
      ORDER BY f~position
      INTO TABLE @DATA(lt_fields).

    LOOP AT lt_fields ASSIGNING FIELD-SYMBOL(<f>).
      APPEND VALUE #( pos       = |{ <f>-position ALPHA = OUT }|
                      fieldname = <f>-fieldname
                      keyflag   = COND string( WHEN <f>-keyflag = 'X'
                                               THEN `X` ELSE `` )
                      rollname  = <f>-rollname
                      datatype  = <f>-datatype
                      leng      = |{ <f>-leng ALPHA = OUT }|
                      decimals  = |{ <f>-decimals ALPHA = OUT }|
                      descr     = <f>-ddtext ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_dtel_detail.

    DATA(lv_roll) = CONV rollname( to_upper( condense( iv_rollname ) ) ).

    SELECT SINGLE FROM dd04l AS d
      LEFT OUTER JOIN dd04t AS t
        ON  t~rollname   = d~rollname
        AND t~ddlanguage = @sy-langu
        AND t~as4local   = 'A'
      FIELDS d~rollname, d~domname, d~datatype, d~leng, d~decimals,
             d~outputlen, d~lowercase, d~signflag, d~convexit,
             d~shlpname, d~as4user, d~as4date,
             t~ddtext, t~scrtext_s, t~scrtext_m, t~scrtext_l
      WHERE d~rollname = @lv_roll
        AND d~as4local = 'A'
      INTO @DATA(ls_d).

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    result = VALUE #(
      ( label = `Data Element`    value = CONV string( ls_d-rollname ) )
      ( label = `Short Descr.`    value = CONV string( ls_d-ddtext ) )
      ( label = `Domain`          value = CONV string( ls_d-domname ) )
      ( label = `Data Type`       value = CONV string( ls_d-datatype ) )
      ( label = `Length`          value = |{ ls_d-leng ALPHA = OUT }| )
      ( label = `Decimals`        value = |{ ls_d-decimals ALPHA = OUT }| )
      ( label = `Output Length`   value = |{ ls_d-outputlen ALPHA = OUT }| )
      ( label = `Lowercase`       value = CONV string( ls_d-lowercase ) )
      ( label = `Sign`            value = CONV string( ls_d-signflag ) )
      ( label = `Conversion Exit` value = CONV string( ls_d-convexit ) )
      ( label = `Search Help`     value = CONV string( ls_d-shlpname ) )
      ( label = `Short Label`     value = CONV string( ls_d-scrtext_s ) )
      ( label = `Medium Label`    value = CONV string( ls_d-scrtext_m ) )
      ( label = `Long Label`      value = CONV string( ls_d-scrtext_l ) )
      ( label = `Last Changed By` value = CONV string( ls_d-as4user ) )
      ( label = `Changed On`      value = format_date( ls_d-as4date ) ) ).

  ENDMETHOD.

  METHOD search_classes.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    SELECT FROM seoclass AS c
      LEFT OUTER JOIN seoclasstx AS t
        ON  t~clsname = c~clsname
        AND t~langu   = @sy-langu
      FIELDS c~clsname, c~clstype, t~descript
      WHERE c~clsname LIKE @lv_like
      ORDER BY c~clsname
      INTO TABLE @DATA(lt_cls)
      UP TO @iv_max ROWS.

    LOOP AT lt_cls ASSIGNING FIELD-SYMBOL(<c>).
      APPEND VALUE #( clsname = <c>-clsname
                      clstype = COND string( WHEN <c>-clstype = '0'
                                             THEN `Class` ELSE `Interface` )
                      descr   = <c>-descript ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_class_components.

    DATA(lv_cls) = CONV seoclsname( to_upper( condense( iv_clsname ) ) ).

    SELECT FROM seocompo AS c
      LEFT OUTER JOIN seocompodf AS d
        ON  d~clsname = c~clsname
        AND d~cmpname = c~cmpname
        AND d~version = '1'
      FIELDS c~cmpname, c~cmptype, c~mtdtype, d~exposure, d~redefin
      WHERE c~clsname = @lv_cls
      ORDER BY c~cmptype, c~cmpname
      INTO TABLE @DATA(lt_cmp).

    LOOP AT lt_cmp ASSIGNING FIELD-SYMBOL(<c>).
      APPEND VALUE #(
        cmpname  = <c>-cmpname
        cmptype  = SWITCH string( <c>-cmptype
                     WHEN '0' THEN `Attribute`
                     WHEN '1' THEN `Method`
                     WHEN '2' THEN `Event`
                     WHEN '3' THEN `Type`
                     WHEN '4' THEN `Interface`
                     ELSE CONV string( <c>-cmptype ) )
        mtdtype  = SWITCH string( <c>-mtdtype
                     WHEN '0' THEN `Instance`
                     WHEN '1' THEN `Static`
                     WHEN '2' THEN `Constructor`
                     ELSE `` )
        exposure = SWITCH string( <c>-exposure
                     WHEN '0' THEN `Private`
                     WHEN '1' THEN `Protected`
                     WHEN '2' THEN `Public`
                     ELSE `` )
        redefin  = COND string( WHEN <c>-redefin = 'X'
                                THEN `X` ELSE `` ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD search_functions.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    SELECT FROM tfdir AS f
      LEFT OUTER JOIN enlfdir AS e
        ON e~funcname = f~funcname
      LEFT OUTER JOIN tftit AS t
        ON  t~funcname = f~funcname
        AND t~spras    = @sy-langu
      FIELDS f~funcname, f~fmode, e~area, t~stext
      WHERE f~funcname LIKE @lv_like
      ORDER BY f~funcname
      INTO TABLE @DATA(lt_fm)
      UP TO @iv_max ROWS.

    LOOP AT lt_fm ASSIGNING FIELD-SYMBOL(<f>).
      APPEND VALUE #( funcname = <f>-funcname
                      area     = <f>-area
                      stext    = <f>-stext
                      rfc      = COND string( WHEN <f>-fmode = 'R'
                                              THEN `RFC` ELSE `` ) ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_function_params.

    DATA(lv_fm) = CONV rs38l_fnam( to_upper( condense( iv_funcname ) ) ).

    SELECT pposition, paramtype, parameter, structure, reference,
           optional, type, defaultval
      FROM fupararef
      WHERE funcname = @lv_fm
        AND r3state  = 'A'
      ORDER BY paramtype, pposition
      INTO TABLE @DATA(lt_p).

    LOOP AT lt_p ASSIGNING FIELD-SYMBOL(<p>).
      APPEND VALUE #(
        pos       = |{ <p>-pposition }|
        kind      = SWITCH string( <p>-paramtype
                      WHEN 'I' THEN `IMPORTING`
                      WHEN 'E' THEN `EXPORTING`
                      WHEN 'C' THEN `CHANGING`
                      WHEN 'T' THEN `TABLES`
                      WHEN 'X' THEN `EXCEPTION`
                      ELSE CONV string( <p>-paramtype ) )
        parameter = <p>-parameter
        typing    = SWITCH string( <p>-type
                      WHEN 'X' THEN `TYPE`
                      ELSE `LIKE` )
        reference = COND string( WHEN <p>-structure IS NOT INITIAL
                                 THEN CONV string( <p>-structure )
                                 ELSE CONV string( <p>-reference ) )
        optional  = COND string( WHEN <p>-optional = 'X'
                                 THEN `X` ELSE `` )
        default   = <p>-defaultval ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD search_programs.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    SELECT FROM trdir AS d
      LEFT OUTER JOIN tadir AS a
        ON  a~pgmid    = 'R3TR'
        AND a~object   = 'PROG'
        AND a~obj_name = d~name
      FIELDS d~name, d~subc, d~cnam, d~udat, a~devclass
      WHERE d~name LIKE @lv_like
      ORDER BY d~name
      INTO TABLE @DATA(lt_prog)
      UP TO @iv_max ROWS.

    LOOP AT lt_prog ASSIGNING FIELD-SYMBOL(<p>).
      APPEND VALUE #(
        name    = <p>-name
        subc    = <p>-subc
        kind    = SWITCH string( <p>-subc
                    WHEN '1' THEN `Executable Program`
                    WHEN 'I' THEN `Include`
                    WHEN 'M' THEN `Module Pool`
                    WHEN 'F' THEN `Function Group`
                    WHEN 'K' THEN `Class Pool`
                    WHEN 'J' THEN `Interface Pool`
                    WHEN 'S' THEN `Subroutine Pool`
                    WHEN 'T' THEN `Type Pool`
                    ELSE CONV string( <p>-subc ) )
        author  = <p>-cnam
        chdate  = format_date( <p>-udat )
        package = <p>-devclass ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_program_source.

    DATA lt_source TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lv_name   TYPE syrepid.

    lv_name = to_upper( condense( iv_name ) ).
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    TRY.
        READ REPORT lv_name INTO lt_source.
        IF sy-subrc <> 0.
          result = |Program { lv_name } does not exist or has no source.|.
          RETURN.
        ENDIF.
      CATCH cx_root.
        result = |Program { lv_name } cannot be read.|.
        RETURN.
    ENDTRY.

    CONCATENATE LINES OF lt_source INTO result
                SEPARATED BY cl_abap_char_utilities=>newline.

  ENDMETHOD.

  METHOD get_jobs.

    DATA(lv_like) = to_like_pattern( iv_jobname ).
    DATA(lv_user) = to_like_pattern( iv_user ).
    DATA(lv_stat) = CONV btcstatus( to_upper( condense( iv_status ) ) ).

    SELECT jobname, jobcount, status, sdldate, sdltime,
           strtdate, strttime, enddate, endtime,
           sdluname, execserver, periodic
      FROM tbtco
      WHERE jobname   LIKE @lv_like
        AND sdluname  LIKE @lv_user
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
                      sdldate   = format_date( <j>-sdldate )
                      sdltime   = format_time( <j>-sdltime )
                      strtdate  = format_date( <j>-strtdate )
                      strttime  = format_time( <j>-strttime )
                      enddate   = format_date( <j>-enddate )
                      endtime   = format_time( <j>-endtime )
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

    DATA(lv_from) = iv_date_from.
    IF lv_from IS INITIAL.
      lv_from = sy-datum - 7.
    ENDIF.
    DATA(lv_user) = to_like_pattern( iv_user ).

    SELECT datum, uzeit, uname, mandt, ahost, modno, flist
      FROM snap
      WHERE seqno  = '000'
        AND datum >= @lv_from
        AND uname LIKE @lv_user
      ORDER BY datum DESCENDING, uzeit DESCENDING
      INTO TABLE @DATA(lt_snap)
      UP TO @iv_max ROWS.

    LOOP AT lt_snap ASSIGNING FIELD-SYMBOL(<s>).

      DATA(lt_tags) = parse_flist( CONV string( <s>-flist ) ).

      APPEND VALUE #(
        datum    = format_date( <s>-datum )
        uzeit    = format_time( <s>-uzeit )
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

    DATA(lt_tags) = parse_flist( lv_all ).

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

  METHOD search_users.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    SELECT FROM usr02 AS u
      LEFT OUTER JOIN usr21 AS p
        ON p~bname = u~bname
      LEFT OUTER JOIN adrp AS a
        ON  a~persnumber = p~persnumber
        AND a~nation     = @space
      FIELDS u~bname, u~ustyp, u~uflag, u~gltgv, u~gltgb,
             u~trdat, u~aname, a~name_first, a~name_last
      WHERE u~bname LIKE @lv_like
      ORDER BY u~bname
      INTO TABLE @DATA(lt_users)
      UP TO @iv_max ROWS.

    LOOP AT lt_users ASSIGNING FIELD-SYMBOL(<u>).

      DATA(lv_full) = condense( |{ <u>-name_first } { <u>-name_last }| ).

      APPEND VALUE #(
        bname     = <u>-bname
        fullname  = lv_full
        ustyp     = <u>-ustyp
        ustyptxt  = SWITCH string( <u>-ustyp
                      WHEN 'A' THEN `Dialog`
                      WHEN 'B' THEN `System`
                      WHEN 'C' THEN `Communication`
                      WHEN 'L' THEN `Reference`
                      WHEN 'S' THEN `Service`
                      ELSE CONV string( <u>-ustyp ) )
        lockstate = COND string( WHEN <u>-uflag IS INITIAL
                                 THEN `Unlocked` ELSE `Locked` )
        validfrom = format_date( <u>-gltgv )
        validto   = format_date( <u>-gltgb )
        lastlogon = format_date( <u>-trdat )
        createdby = <u>-aname ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_user_roles.

    DATA(lv_user) = CONV xubname( to_upper( condense( iv_bname ) ) ).

    SELECT agr_name, from_dat, to_dat
      FROM agr_users
      WHERE uname = @lv_user
      ORDER BY agr_name
      INTO TABLE @DATA(lt_roles).

    LOOP AT lt_roles ASSIGNING FIELD-SYMBOL(<r>).
      APPEND VALUE #( agr_name = <r>-agr_name
                      from_dat = format_date( <r>-from_dat )
                      to_dat   = format_date( <r>-to_dat ) ) TO result.
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

  METHOD get_tms_domain.

    CLEAR: ev_domain, ev_system, ev_message.

*   The own system is the one TMSCSYS marks as real system (SYSTYP R)
*   and that carries the RFC destination of the domain controller.
    SELECT SINGLE domnam, sysnam
      FROM tmscsys
      WHERE sysnam = @sy-sysid
      INTO ( @DATA(lv_dom), @DATA(lv_sys) ).

    IF sy-subrc <> 0.
      ev_message = |System { sy-sysid } is not included in a transport domain.|.
      RETURN.
    ENDIF.

    ev_domain = lv_dom.
    ev_system = lv_sys.

  ENDMETHOD.


  METHOD get_tms_systems.

    SELECT sysnam, systxt, systyp, comsys, tmscfg, desadm, moddat, modusr
      FROM tmscsys
      ORDER BY sysnam
      INTO TABLE @DATA(lt_sys).

    LOOP AT lt_sys ASSIGNING FIELD-SYMBOL(<s>).
      APPEND VALUE #(
        sysnam = <s>-sysnam
        systxt = <s>-systxt
*       fixed values of domain TMSSYSTYP
        systyp = SWITCH string( <s>-systyp
                   WHEN 'R' THEN `Real system`
                   WHEN 'V' THEN `Virtual system`
                   WHEN 'E' THEN `External system`
                   WHEN 'I' THEN `Imported from other domain`
                   WHEN 'C' THEN `System cluster`
                   WHEN 'N' THEN `Non-ABAP system`
                   ELSE CONV string( <s>-systyp ) )
        comsys = <s>-comsys
*       fixed values of domain TMSCFGSTAT
        cfgstat = SWITCH string( <s>-tmscfg
                    WHEN 'A' THEN `System is active`
                    WHEN 'I' THEN `TMS is not active for this system`
                    WHEN 'L' THEN `System locked`
                    WHEN 'D' THEN `System was deleted from transport domain`
                    WHEN 'F' THEN `Communication system deleted`
                    WHEN 'C' THEN `Communication system is locked`
                    WHEN 'W' THEN `System is waiting for inclusion in transport domain`
                    WHEN 'R' THEN `System was not included in domain`
                    ELSE CONV string( <s>-tmscfg ) )
        desadm = <s>-desadm
        moddat = COND string( WHEN <s>-moddat IS NOT INITIAL
                              THEN format_date( <s>-moddat ) )
        modusr = <s>-modusr ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_tms_queue.

    SELECT sysnam, bufpos, trkorr, owner, tarcli, maxrc, text
      FROM tmsbuffer
      ORDER BY sysnam, bufpos
      INTO TABLE @DATA(lt_buf).

    LOOP AT lt_buf ASSIGNING FIELD-SYMBOL(<b>).
      APPEND VALUE #(
        sysnam = <b>-sysnam
        bufpos = <b>-bufpos
        trkorr = <b>-trkorr
        owner  = <b>-owner
        tarcli = <b>-tarcli
        maxrc  = <b>-maxrc
        text   = <b>-text ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_transports.

    DATA(lv_user) = to_like_pattern( iv_user ).
    DATA(lv_stat) = CONV trstatus( to_upper( condense( iv_status ) ) ).

    SELECT FROM e070 AS h
      LEFT OUTER JOIN e07t AS t
        ON  t~trkorr = h~trkorr
        AND t~langu  = @sy-langu
      FIELDS h~trkorr, h~trfunction, h~trstatus, h~tarsystem,
             h~as4user, h~as4date, h~as4time, h~strkorr, t~as4text
      WHERE h~as4user LIKE @lv_user
        AND ( h~trstatus = @lv_stat OR @lv_stat = '' )
      ORDER BY h~as4date DESCENDING, h~as4time DESCENDING
      INTO TABLE @DATA(lt_tr)
      UP TO @iv_max ROWS.

    LOOP AT lt_tr ASSIGNING FIELD-SYMBOL(<t>).
      APPEND VALUE #(
        trkorr     = <t>-trkorr
        trfunction = <t>-trfunction
        functxt    = SWITCH string( <t>-trfunction
                       WHEN 'K' THEN `Workbench Request`
                       WHEN 'W' THEN `Customizing Request`
                       WHEN 'T' THEN `Transport of Copies`
                       WHEN 'S' THEN `Development/Correction`
                       WHEN 'R' THEN `Repair`
                       WHEN 'X' THEN `Unclassified Task`
                       WHEN 'Q' THEN `Customizing Task`
                       ELSE CONV string( <t>-trfunction ) )
        trstatus   = <t>-trstatus
        statustxt  = SWITCH string( <t>-trstatus
                       WHEN 'D' THEN `Modifiable`
                       WHEN 'L' THEN `Modifiable, locked`
                       WHEN 'O' THEN `Release started`
                       WHEN 'R' THEN `Released`
                       WHEN 'N' THEN `Released (import protection)`
                       ELSE CONV string( <t>-trstatus ) )
        as4user    = <t>-as4user
        as4date    = format_date( <t>-as4date )
        as4time    = format_time( <t>-as4time )
        tarsystem  = <t>-tarsystem
        as4text    = <t>-as4text
        strkorr    = <t>-strkorr ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_transport_objects.

    DATA(lv_tr) = CONV trkorr( to_upper( condense( iv_trkorr ) ) ).

    SELECT pgmid, object, obj_name, objfunc
      FROM e071
      WHERE trkorr = @lv_tr
      ORDER BY pgmid, object, obj_name
      INTO TABLE @DATA(lt_obj).

    LOOP AT lt_obj ASSIGNING FIELD-SYMBOL(<o>).
      APPEND VALUE #( pgmid    = <o>-pgmid
                      object   = <o>-object
                      obj_name = <o>-obj_name
                      objfunc  = <o>-objfunc ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_clients.

    SELECT mandt, mtext, ort01, mwaer, cccategory, cccoractiv,
           ccnocliind, ccnocascad, changeuser, changedate, logsys
      FROM t000
      ORDER BY mandt
      INTO TABLE @DATA(lt_cl).

    LOOP AT lt_cl ASSIGNING FIELD-SYMBOL(<c>).
      APPEND VALUE #(
        mandt      = <c>-mandt
        mtext      = <c>-mtext
        ort01      = <c>-ort01
        mwaer      = <c>-mwaer
        category   = <c>-cccategory
        cattxt     = SWITCH string( <c>-cccategory
                       WHEN 'P' THEN `Production`
                       WHEN 'T' THEN `Test`
                       WHEN 'C' THEN `Customizing`
                       WHEN 'D' THEN `Demo`
                       WHEN 'E' THEN `Training/Education`
                       WHEN 'S' THEN `SAP Reference`
                       ELSE `Not specified` )
        cccoractiv = <c>-cccoractiv
        coracttxt  = SWITCH string( <c>-cccoractiv
                       WHEN ' ' THEN `Changes without automatic recording`
                       WHEN '1' THEN `Automatic recording of changes`
                       WHEN '2' THEN `No changes allowed`
                       WHEN '3' THEN `No transports allowed`
                       ELSE CONV string( <c>-cccoractiv ) )
        ccnocliind = <c>-ccnocliind
        ccnocascad = <c>-ccnocascad
        changeuser = <c>-changeuser
        changedate = format_date( <c>-changedate )
        logsys     = <c>-logsys ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD search_parameters.

*   The documentation table TPFYPROPTY is empty on this system, so the
*   list is built from the kernel metadata instead - the same source the
*   original RZ11 (program RSPFLDOC) reads through
*   CL_SPFL_PROFILE_PARAMETER.

    DATA lt_meta TYPE spfl_parameter_metadata_list_t.

    DATA(lv_pattern) = to_upper( condense( iv_pattern ) ).
    IF lv_pattern IS INITIAL.
      lv_pattern = `*`.
    ENDIF.

    cl_spfl_profile_parameter=>get_all_metadata( IMPORTING metadata = lt_meta ).

    SORT lt_meta BY name AS TEXT.

    LOOP AT lt_meta ASSIGNING FIELD-SYMBOL(<m>).

      IF NOT to_upper( <m>-name ) CP lv_pattern.
        CONTINUE.
      ENDIF.

*     Original function ALLDYN - All Dynamic Parameters
      IF iv_only_dynamic = abap_true AND <m>-is_dynamic <> 1.
        CONTINUE.
      ENDIF.

      APPEND VALUE #(
        paraname = <m>-name
        value    = get_param_value( <m>-name )
        grp      = <m>-pgroup
        ptype    = param_type_text( <m>-type )
        dynamic  = COND string( WHEN <m>-is_dynamic = 1 THEN `X` ELSE `` )
        descr    = <m>-description ) TO result.

      IF lines( result ) >= iv_max.
        EXIT.
      ENDIF.

    ENDLOOP.

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

*   The attribute labels are the text elements of RSPFLDOC, so the list
*   reads like the original attribute display of RZ11:
*     502 Name              503 Type            504 Further Selection Criteria
*     505 Unit              506 Parameter Group 507 Parameter Description
*     508 CSN Component     509 System-Wide Parameter
*     510 Dynamic Parameter 513 Vector Parameter
*     514 Has Subparameters 515 Check Function Exists
*     501 Value             521 Resulting Source
*     542 Recommended Value 543 Associated Note

    DATA ls_meta TYPE spfl_parameter_metadata.
    DATA lv_name TYPE spfl_parameter_name.

    lv_name = condense( iv_paraname ).

    DATA(lv_rc) = cl_spfl_profile_parameter=>get_metadata(
                      EXPORTING name     = lv_name
                      IMPORTING metadata = ls_meta ).

    IF lv_rc <> 0 OR ls_meta-name IS INITIAL.
      result = VALUE #(
        ( label = `Name`  value = lv_name )
        ( label = `Value`
          value = |Parameter { lv_name } is not known to this instance.| ) ).
      RETURN.
    ENDIF.

    DATA lv_origin TYPE i.
    cl_spfl_profile_parameter=>get_origin(
      EXPORTING name   = lv_name
      IMPORTING origin = lv_origin ).

    DATA lv_rec  TYPE spfl_parameter_value.
    DATA lv_note TYPE spfl_note_number.
    cl_spfl_profile_parameter=>get_recommended_value(
      EXPORTING name  = lv_name
      IMPORTING value = lv_rec
                note  = lv_note ).

    DATA(lv_restr) = ls_meta-restriction_values.
    IF ls_meta-type = 203 OR ls_meta-type = 204.
      SPLIT lv_restr AT ` ` INTO DATA(lv_low) DATA(lv_high).
      lv_restr = |Interval [{ lv_low },{ lv_high }]|.
    ENDIF.

    result = VALUE #(
      ( label = `Name`                     value = ls_meta-name )
      ( label = `Value`                    value = get_param_value( ls_meta-name ) )
      ( label = `Resulting Source`         value = param_origin_text( lv_origin ) )
      ( label = `Type`                     value = param_type_text( ls_meta-type ) )
      ( label = `Further Selection Criteria` value = lv_restr )
      ( label = `Unit`                     value = ls_meta-unit )
      ( label = `Parameter Group`          value = ls_meta-pgroup )
      ( label = `Parameter Description`    value = ls_meta-description )
      ( label = `CSN Component`            value = ls_meta-csn_component )
      ( label = `System-Wide Parameter`    value = yes_no( ls_meta-is_system ) )
      ( label = `Dynamic Parameter`        value = yes_no( ls_meta-is_dynamic ) )
      ( label = `Vector Parameter`         value = yes_no( ls_meta-is_vector ) )
      ( label = `Has Subparameters`        value = yes_no( ls_meta-has_subparameters ) )
      ( label = `Check Function Exists`    value = yes_no( ls_meta-is_check_fct_defined ) ) ).

    IF lv_rec IS NOT INITIAL.
      APPEND VALUE #( label = `Recommended Value`
                      value = CONV string( lv_rec ) ) TO result.
    ENDIF.
    IF lv_note IS NOT INITIAL.
      APPEND VALUE #( label = `Associated Note`
                      value = CONV string( lv_note ) ) TO result.
    ENDIF.

  ENDMETHOD.


  METHOD yes_no.

*   RSPFLDOC text elements 511 / 512
    result = COND string( WHEN iv_flag = 1 THEN `Yes` ELSE `No` ).

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
      APPEND VALUE #( date   = format_date( lv_logdate )
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
        value = get_param_value( `rdisp/myname` ) )
      ( label = `Trace Directory (DIR_ATRA)`
        value = get_param_value( `DIR_ATRA` ) )
      ( label = `SQL Trace Ring Buffer (rstr/buffer_size_kB)`
        value = get_param_value( `rstr/buffer_size_kB` ) )
      ( label = `Maximum Trace File Size (rstr/max_filesize_MB)`
        value = get_param_value( `rstr/max_filesize_MB` ) )
      ( label = `Number of Trace Files (rstr/max_files)`
        value = get_param_value( `rstr/max_files` ) )
      ( label = `Maximum Disk Space (rstr/max_diskspace)`
        value = get_param_value( `rstr/max_diskspace` ) )
      ( label = `Accept Remote Trace (rstr/accept_remote_trace)`
        value = get_param_value( `rstr/accept_remote_trace` ) )
      ( label = `Table Buffer Trace (rsdb/staton)`
        value = get_param_value( `rsdb/staton` ) )
      ( label = `Developer Trace Level (rdisp/TRACE)`
        value = get_param_value( `rdisp/TRACE` ) ) ).

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
    es_state-sql_on  = COND #( WHEN ls_raw-trace_types-sql_on  IS NOT INITIAL THEN abap_true ).
    es_state-buf_on  = COND #( WHEN ls_raw-trace_types-buf_on  IS NOT INITIAL THEN abap_true ).
    es_state-enq_on  = COND #( WHEN ls_raw-trace_types-enq_on  IS NOT INITIAL THEN abap_true ).
    es_state-rfc_on  = COND #( WHEN ls_raw-trace_types-rfc_on  IS NOT INITIAL THEN abap_true ).
    es_state-http_on = COND #( WHEN ls_raw-trace_types-http_on IS NOT INITIAL THEN abap_true ).
    es_state-amc_on  = COND #( WHEN ls_raw-trace_types-amc_on  IS NOT INITIAL THEN abap_true ).
    es_state-apc_on  = COND #( WHEN ls_raw-trace_types-apc_on  IS NOT INITIAL THEN abap_true ).
    es_state-auth_on = COND #( WHEN ls_raw-trace_types-auth_on IS NOT INITIAL THEN abap_true ).
    es_state-stack_on     = COND #( WHEN ls_raw-stack_trace_on IS NOT INITIAL THEN abap_true ).
    es_state-progress_on  = COND #( WHEN ls_raw-progress_indicator_on IS NOT INITIAL THEN abap_true ).
    es_state-filter_on    = COND #( WHEN ls_raw-filter_on IS NOT INITIAL THEN abap_true ).
    es_state-incl_missing = COND #( WHEN ls_raw-include_missing_table_name_on IS NOT INITIAL
                                    THEN abap_true ).

    es_state-trace_user   = ls_raw-trace_user.
    es_state-tcode        = ls_raw-transaction_code.
    es_state-program      = ls_raw-program.
    es_state-rfc_function = ls_raw-rfc_function.
    es_state-url          = ls_raw-url.
    es_state-wp_id        = ls_raw-wp_id.
    es_state-mod_user     = ls_raw-modification_user.

    IF ls_raw-modification_date IS NOT INITIAL.
      es_state-mod_date = format_date( ls_raw-modification_date ).
      es_state-mod_time = format_time( ls_raw-modification_time ).
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

    IF es_state-sql_on  = abap_true. APPEND `SQL Trace`     TO lt_active. ENDIF.
    IF es_state-buf_on  = abap_true. APPEND `Buffer Trace`  TO lt_active. ENDIF.
    IF es_state-enq_on  = abap_true. APPEND `Enqueue Trace` TO lt_active. ENDIF.
    IF es_state-rfc_on  = abap_true. APPEND `RFC Trace`     TO lt_active. ENDIF.
    IF es_state-http_on = abap_true. APPEND `HTTP Trace`    TO lt_active. ENDIF.
    IF es_state-amc_on  = abap_true. APPEND `AMC Trace`     TO lt_active. ENDIF.
    IF es_state-apc_on  = abap_true. APPEND `APC trace`     TO lt_active. ENDIF.

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

  METHOD read_hierarchy.

    " SAP Easy Access - area menu.
    " A banner comment between ENDMETHOD and METHOD cannot be stored by
    " ADT and gets dropped on the next edit there, so it lives in here.
    " already read in this roll area?
    READ TABLE mt_hier_buffer INTO result WITH KEY struct_id = iv_struct_id.
    IF sy-subrc = 0.
      RETURN.
    ENDIF.

    CLEAR result.
    result-struct_id = iv_struct_id.

    IF iv_struct_id IS INITIAL.
      RETURN.
    ENDIF.

    DATA ls_msg TYPE hier_mess.

    " Reading with ALL_LANGUAGES is what makes the English texts show up -
    " the master language of the SAP standard menu is German and a plain
    " LANGUAGE = 'E' read falls back to the master language texts.
    CALL FUNCTION 'STREE_HIERARCHY_READ'
      EXPORTING
        structure_id       = CONV ttree-id( iv_struct_id )
        read_also_texts    = 'X'
        language           = 'E'
        all_languages      = 'X'
      IMPORTING
        message            = ls_msg
      TABLES
        list_of_nodes      = result-nodes
        list_of_references = result-refs
        list_of_texts      = result-texts.

    IF ls_msg-msgid IS NOT INITIAL.
      " structure does not exist or cannot be read
      CLEAR: result-nodes, result-refs, result-texts.
    ENDIF.

    APPEND result TO mt_hier_buffer.

  ENDMETHOD.

  METHOD menu_text.

    result = VALUE #( it_texts[ node_id = iv_node_id spras = 'E' ]-text OPTIONAL ).
    IF result IS INITIAL.
      " not translated - take whatever language is available
      result = VALUE #( it_texts[ node_id = iv_node_id ]-text OPTIONAL ).
    ENDIF.
    result = condense( result ).

  ENDMETHOD.

  METHOD get_area_menu_children.

    DATA(ls_hier) = read_hierarchy( iv_struct_id ).
    IF ls_hier-nodes IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_parent TYPE hier_guid.
    IF iv_node_id IS INITIAL.
      " top level - children of the structure root
      LOOP AT ls_hier-nodes ASSIGNING FIELD-SYMBOL(<root>) WHERE parent_id IS INITIAL.
        lv_parent = <root>-node_id.
        EXIT.
      ENDLOOP.
    ELSE.
      lv_parent = iv_node_id.
    ENDIF.

    " The sequence delivered by the hierarchy read is the display sequence
    " of the area menu, so it is deliberately kept unsorted here.
    LOOP AT ls_hier-nodes ASSIGNING FIELD-SYMBOL(<n>)
         WHERE parent_id  = lv_parent
           AND no_display IS INITIAL
           AND hidden_fl  IS INITIAL.

      DATA ls_node TYPE ty_s_menu_node.
      CLEAR ls_node.
      ls_node-struct_id = iv_struct_id.
      ls_node-node_id   = <n>-node_id.
      ls_node-node_key  = |{ iv_struct_id }:{ <n>-node_id }|.
      ls_node-text      = menu_text( it_texts   = ls_hier-texts
                                     iv_node_id = <n>-node_id ).
      ls_node-tcode     = condense( CONV string(
          VALUE #( ls_hier-refs[ node_id = <n>-node_id ref_type = 'TCOD' ]-ref_object OPTIONAL ) ) ).
      ls_node-sub_tree  = condense( CONV string(
          VALUE #( ls_hier-refs[ node_id = <n>-node_id ref_type = 'TREE' ]-ref_object OPTIONAL ) ) ).

      " reference nodes point into another structure
      IF ls_node-sub_tree IS INITIAL AND <n>-reftree_id IS NOT INITIAL.
        ls_node-sub_tree = <n>-reftree_id.
        ls_node-sub_node = <n>-refnode_id.
      ENDIF.

      DATA(lv_children) = REDUCE i( INIT x = 0
                                    FOR w IN ls_hier-nodes
                                    WHERE ( parent_id = <n>-node_id )
                                    NEXT x = x + 1 ).

      IF ls_node-tcode IS INITIAL
         AND ( lv_children > 0
               OR ls_node-sub_tree IS NOT INITIAL
               OR <n>-w_subnodes = abap_true ).
        ls_node-is_folder = abap_true.
      ENDIF.

      IF ls_node-text IS INITIAL.
        ls_node-text = ls_node-tcode.
      ENDIF.

      " entries without any text and without a transaction are of no use
      IF ls_node-text IS INITIAL AND ls_node-is_folder = abap_false.
        CONTINUE.
      ENDIF.

      APPEND ls_node TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD transaction_exists.

    DATA(lv_tcode) = CONV tcode( to_upper( condense( iv_tcode ) ) ).
    IF lv_tcode IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE @abap_true FROM tstc INTO @result WHERE tcode = @lv_tcode.

  ENDMETHOD.

  METHOD get_transaction_text.

    DATA(lv_tcode) = CONV tcode( to_upper( condense( iv_tcode ) ) ).
    IF lv_tcode IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE ttext FROM tstct INTO @result
      WHERE sprsl = 'E' AND tcode = @lv_tcode.

  ENDMETHOD.

  METHOD seuk_text.

    " SE93 - Maintain Transaction
    IF mt_seuk_text IS INITIAL.
      READ TEXTPOOL 'SAPLSEUK' INTO mt_seuk_text LANGUAGE sy-langu.
      IF mt_seuk_text IS INITIAL.
        " the text pool is not translated into the logon language
        READ TEXTPOOL 'SAPLSEUK' INTO mt_seuk_text LANGUAGE 'E'.
      ENDIF.
    ENDIF.

    DATA lv_key TYPE textpool-key.
    lv_key = iv_key.
    result = VALUE #( mt_seuk_text[ id = 'I' key = lv_key ]-entry OPTIONAL ).

  ENDMETHOD.


  METHOD tcode_type_text.

    " LSEUKF01, FORM select_tstc_tables. The order of the checks is the one
    " of the original and it matters: a report transaction with a variant
    " carries the report bit as well, and an object transaction built on the
    " OO framework is stored as a parameter transaction.
    IF iv_cinfo O c_cinfo_rep.
      result = seuk_text( `002` ).            " Report Transaction

    ELSEIF iv_cinfo O c_cinfo_obj.
      result = seuk_text( `028` ).            " Object Transaction

    ELSEIF iv_cinfo O c_cinfo_par.
      IF iv_param IS NOT INITIAL AND iv_param(1) = '@'.
        result = seuk_text( `019` ).          " Variant Transaction
      ELSEIF iv_param CS c_oo_tcode.
        result = seuk_text( `028` ).          " Object Transaction, framework
      ELSE.
        result = seuk_text( `003` ).          " Parameter Transaction
      ENDIF.

    ELSEIF iv_cinfo O c_cinfo_men.
      " area menu - the original shows no transaction type for it
      CLEAR result.

    ELSE.
      result = seuk_text( `001` ).            " Dialog Transaction
    ENDIF.

  ENDMETHOD.


  METHOD oo_component.

    " The value of \TAG= runs up to the next backslash or to the end.
    DATA(lv_pos) = find( val = iv_param sub = iv_tag ).
    IF lv_pos < 0.
      RETURN.
    ENDIF.

    result = substring( val = iv_param off = lv_pos + strlen( iv_tag ) ).

    DATA(lv_end) = find( val = result sub = '\' ).
    IF lv_end >= 0.
      result = substring( val = result len = lv_end ).
    ENDIF.

  ENDMETHOD.


  METHOD split_tcode_parameters.

    " LSEUKF01, FORM split_parameters. The first character of TSTCP-PARAM
    " decides how the rest of the string is read.
    DATA(lv_rest) = iv_param.
    IF lv_rest IS INITIAL.
      RETURN.
    ENDIF.

    CASE lv_rest(1).

      WHEN '\'.
        " object transaction without the OO framework
        DATA(lv_prog) = oo_component( iv_param = lv_rest iv_tag = '\PROGRAM=' ).
        IF lv_prog IS NOT INITIAL.
          cs_detail-pgmna = lv_prog.
        ENDIF.
        cs_detail-classname = oo_component( iv_param = lv_rest iv_tag = '\CLASS=' ).
        cs_detail-method    = oo_component( iv_param = lv_rest iv_tag = '\METHOD=' ).
        " a program in the parameter string means: class local to it
        cs_detail-s_local   = xsdbool( cs_detail-pgmna IS NOT INITIAL ).
        RETURN.

      WHEN '@'.
        " transaction variant, @@ marks a cross-client one
        DATA(lv_off) = 1.
        IF strlen( lv_rest ) >= 2 AND lv_rest(2) = '@@'.
          cs_detail-s_ind_vari = abap_true.
          lv_off = 2.
        ENDIF.
        DATA(lv_vari) = substring( val = lv_rest off = lv_off ).
        SPLIT lv_vari AT ` ` INTO cs_detail-call_tcode cs_detail-variant.
        RETURN.

      WHEN '/'.
        " parameter transaction that starts another transaction. The second
        " character is a flag, * of it skips the initial screen, and the
        " transaction code always starts at offset 2.
        cs_detail-start_tcode = abap_true.
        IF strlen( lv_rest ) >= 2 AND substring( val = lv_rest off = 1 len = 1 ) = '*'.
          cs_detail-skip_first = abap_true.
        ENDIF.
        IF strlen( lv_rest ) <= 2.
          RETURN.
        ENDIF.
        DATA(lv_call) = substring( val = lv_rest off = 2 ).
        SPLIT lv_call AT ` ` INTO cs_detail-call_tcode lv_rest.

      WHEN OTHERS.
        " parameter transaction that starts a program and screen
    ENDCASE.

    " what is left is the list of default values, field=value;field=value
    SPLIT lv_rest AT ';' INTO TABLE DATA(lt_pair).
    LOOP AT lt_pair INTO DATA(lv_pair).
      IF lv_pair NS '='.
        CONTINUE.
      ENDIF.
      SPLIT lv_pair AT '=' INTO DATA(lv_field) DATA(lv_value).
      lv_field = condense( lv_field ).
      IF lv_field IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( field = lv_field
                      value = condense( lv_value ) ) TO cs_detail-params.
    ENDLOOP.

    " object transaction on the OO framework - class, method and update mode
    " travel as ordinary default values
    IF cs_detail-call_tcode <> c_oo_tcode.
      RETURN.
    ENDIF.

    cs_detail-s_trframe = abap_true.
    LOOP AT cs_detail-params INTO DATA(ls_param).
      CASE ls_param-field.
        WHEN `CLASS`.  cs_detail-classname = ls_param-value.
        WHEN `METHOD`. cs_detail-method    = ls_param-value.
        WHEN `UPDATE_MODE`.
          cs_detail-upd_mode = COND string(
              WHEN ls_param-value = `S` THEN `S`
              WHEN ls_param-value = `U` THEN `U`
              ELSE `L` ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_transactions.

    DATA(lv_like) = to_like_pattern( iv_pattern ).

    SELECT FROM tstc AS t
      LEFT OUTER JOIN tstct AS x
        ON  x~tcode = t~tcode
        AND x~sprsl = @sy-langu
      LEFT OUTER JOIN tstcp AS p
        ON  p~tcode = t~tcode
      FIELDS t~tcode, t~pgmna, t~dypno, t~cinfo, x~ttext, p~param
      WHERE t~tcode LIKE @lv_like
      ORDER BY t~tcode
      INTO TABLE @DATA(lt_raw)
      UP TO @iv_max ROWS.

    LOOP AT lt_raw ASSIGNING FIELD-SYMBOL(<r>).
      APPEND VALUE #(
          tcode   = <r>-tcode
          ttext   = <r>-ttext
          pgmna   = <r>-pgmna
          dypno   = COND string( WHEN <r>-dypno IS INITIAL
                                 THEN `` ELSE |{ <r>-dypno }| )
          tc_type = tcode_type_text( iv_cinfo = <r>-cinfo
                                     iv_param = CONV string( <r>-param ) ) )
          TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_transaction_detail.

    DATA(lv_tcode) = CONV tcode( to_upper( condense( iv_tcode ) ) ).
    IF lv_tcode IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE FROM tstc
      FIELDS tcode, pgmna, dypno, cinfo, arbgb
      WHERE tcode = @lv_tcode
      INTO @DATA(ls_tstc).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    result-found = abap_true.
    result-tcode = ls_tstc-tcode.
    result-pgmna = ls_tstc-pgmna.

    SELECT SINGLE ttext FROM tstct INTO @result-ttext
      WHERE sprsl = @sy-langu AND tcode = @lv_tcode.

    SELECT SINGLE param FROM tstcp INTO @DATA(lv_param)
      WHERE tcode = @lv_tcode.

    DATA(lv_par_str) = CONV string( lv_param ).
    result-tc_type = tcode_type_text( iv_cinfo = ls_tstc-cinfo
                                      iv_param = lv_par_str ).

    " Start options - LSEUKF01, FORM select_tstc_tables. ARBGB '&&' switches
    " the standard transaction variant off.
    IF ls_tstc-cinfo O c_cinfo_enq.
      result-locked_sm01 = abap_true.
    ENDIF.
    result-trans_var = xsdbool( ls_tstc-arbgb <> '&&' ).

    " A report transaction without a screen number runs on 1000.
    IF ls_tstc-dypno IS NOT INITIAL.
      result-dypno = |{ ls_tstc-dypno }|.
    ELSEIF ls_tstc-cinfo O c_cinfo_rep.
      result-dypno = `1000`.
    ENDIF.

    IF ls_tstc-cinfo O c_cinfo_rep.
      " the variant of a report transaction is the whole parameter string
      IF ls_tstc-cinfo O c_cinfo_rpv.
        result-repo_vari = lv_par_str.
      ENDIF.
    ELSEIF ls_tstc-cinfo O c_cinfo_obj OR ls_tstc-cinfo O c_cinfo_par.
      split_tcode_parameters( EXPORTING iv_param  = lv_par_str
                              CHANGING  cs_detail = result ).
    ENDIF.

    " authorization object with its check values
    IF ls_tstc-cinfo O c_cinfo_chk.
      SELECT objct, field, value FROM tstca
        WHERE tcode = @lv_tcode
        ORDER BY field
        INTO TABLE @DATA(lt_auth).
      LOOP AT lt_auth ASSIGNING FIELD-SYMBOL(<a>).
        result-auth_objct = <a>-objct.
        APPEND VALUE #( objct = <a>-objct
                        field = <a>-field
                        value = <a>-value ) TO result-auth.
      ENDLOOP.
    ENDIF.

    " classification - LSEUKF01, FORM select_tstcc
    SELECT SINGLE FROM tstcc
      FIELDS s_webgui, s_win32, s_platin
      WHERE tcode = @lv_tcode
      INTO @DATA(ls_tstcc).

    result-s_win32  = xsdbool( ls_tstcc-s_win32  IS NOT INITIAL ).
    result-s_platin = xsdbool( ls_tstcc-s_platin IS NOT INITIAL ).
    CASE ls_tstcc-s_webgui.
      WHEN '1'.
        result-s_webgui   = abap_true.
        result-profi_tran = abap_true.
      WHEN '2'.
        result-s_webgui = abap_true.
        result-iac_ewt  = abap_true.
      WHEN OTHERS.
        result-profi_tran = abap_true.
    ENDCASE.

  ENDMETHOD.

ENDCLASS.
