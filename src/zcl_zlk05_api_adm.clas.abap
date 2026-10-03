CLASS zcl_zlk05_api_adm DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - Administration (SU01/SCC4/RZ11)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_ZLK05_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    "! Reads a single profile parameter value from the kernel
    CLASS-METHODS get_param_value
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS search_users
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_user.

    CLASS-METHODS get_user_roles
      IMPORTING iv_bname      TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_role.

    CLASS-METHODS get_clients
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_client.

    CLASS-METHODS search_parameters
      IMPORTING iv_pattern       TYPE string OPTIONAL
                iv_only_dynamic  TYPE abap_bool DEFAULT abap_false
                iv_max           TYPE i DEFAULT 300
      RETURNING VALUE(result)    TYPE zcl_zlk05_sys_api=>ty_t_param.

    CLASS-METHODS get_parameter_detail
      IMPORTING iv_paraname   TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_kv.

    "! RFC destinations of RFCDES the user may display (S_RFC_ADM)
    CLASS-METHODS get_rfc_destinations
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_rfctype    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 500
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_rfcdest.

    "! Text of an RFC connection type (fixed values of domain RFCTYPE)
    CLASS-METHODS rfc_type_text
      IMPORTING iv_rfctype    TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Failed authorization checks of a user (SUSR_USER_SU53_READ)
    CLASS-METHODS get_auth_failures
      IMPORTING iv_bname   TYPE string
                iv_seconds TYPE i DEFAULT 10800
      EXPORTING et_fails   TYPE zcl_zlk05_sys_api=>ty_t_authfail
                ev_message TYPE string.

    "! Roles of AGR_DEFINE the user may display (S_USER_AGR 03)
    CLASS-METHODS search_roles
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 300
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_agr.

    "! The tabs of a role in PFCG (display)
    CLASS-METHODS get_role_detail
      IMPORTING iv_role     TYPE string
      EXPORTING et_head     TYPE zcl_zlk05_sys_api=>ty_t_kv
                et_descr    TYPE string_table
                et_tcodes   TYPE zcl_zlk05_sys_api=>ty_t_agr_tcode
                et_auth     TYPE zcl_zlk05_sys_api=>ty_t_agr_auth
                et_users    TYPE zcl_zlk05_sys_api=>ty_t_agr_user
                et_roles    TYPE zcl_zlk05_sys_api=>ty_t_agr
                ev_message  TYPE string.

    "! The data of the System: Status dialog of the SAP GUI
    CLASS-METHODS get_system_status
      IMPORTING iv_tcode      TYPE string OPTIONAL
                iv_program    TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_status.

  PROTECTED SECTION.

  PRIVATE SECTION.
    " fixed values of domain SUTRREASON, read on first access
    CLASS-DATA mt_reason_text TYPE STANDARD TABLE OF dd07v WITH EMPTY KEY.
    " fixed values of domain RFCTYPE, read on first access
    CLASS-DATA mt_rfctype_text TYPE STANDARD TABLE OF dd07v WITH EMPTY KEY.


ENDCLASS.


CLASS zcl_zlk05_api_adm IMPLEMENTATION.


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


  METHOD search_users.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    SELECT FROM usr02 AS u
      LEFT OUTER JOIN usr21 AS p
        ON p~bname = u~bname
      LEFT OUTER JOIN adrp AS a
        ON  a~persnumber = p~persnumber
        AND a~nation     = @space
      FIELDS u~bname, u~ustyp, u~uflag, u~gltgv, u~gltgb,
             u~trdat, u~aname, u~class, a~name_first, a~name_last
      WHERE u~bname LIKE @lv_like ESCAPE '#'
      ORDER BY u~bname
      INTO TABLE @DATA(lt_users)
      UP TO @iv_max ROWS.

    LOOP AT lt_users ASSIGNING FIELD-SYMBOL(<u>).

      " like SU01: a user is only shown when the viewer may display users
      " of the user's group
      IF zcl_zlk05_auth=>check_user_group( CONV string( <u>-class ) )-allowed = abap_false.
        CONTINUE.
      ENDIF.

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
        validfrom = zcl_zlk05_sys_api=>format_date( <u>-gltgv )
        validto   = zcl_zlk05_sys_api=>format_date( <u>-gltgb )
        lastlogon = zcl_zlk05_sys_api=>format_date( <u>-trdat )
        createdby = <u>-aname ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_user_roles.

    DATA(lv_user) = CONV xubname( to_upper( condense( iv_bname ) ) ).

    " the roles of a user are as protected as the user himself
    SELECT SINGLE class FROM usr02 WHERE bname = @lv_user INTO @DATA(lv_group) ##SUBRC_OK.
    IF zcl_zlk05_auth=>check_user_group( CONV string( lv_group ) )-allowed = abap_false.
      RETURN.
    ENDIF.

    SELECT agr_name, from_dat, to_dat
      FROM agr_users
      WHERE uname = @lv_user
      ORDER BY agr_name
      INTO TABLE @DATA(lt_roles).

    LOOP AT lt_roles ASSIGNING FIELD-SYMBOL(<r>).
      APPEND VALUE #( agr_name = <r>-agr_name
                      from_dat = zcl_zlk05_sys_api=>format_date( <r>-from_dat )
                      to_dat   = zcl_zlk05_sys_api=>format_date( <r>-to_dat ) ) TO result.
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
        changedate = zcl_zlk05_sys_api=>format_date( <c>-changedate )
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

      IF to_upper( <m>-name ) NP lv_pattern.
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
        ptype    = zcl_zlk05_sys_api=>param_type_text( <m>-type )
        dynamic  = COND string( WHEN <m>-is_dynamic = 1 THEN `X` ELSE `` )
        descr    = <m>-description ) TO result.

      IF lines( result ) >= iv_max.
        EXIT.
      ENDIF.

    ENDLOOP.

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
      ( label = `Resulting Source`         value = zcl_zlk05_sys_api=>param_origin_text( lv_origin ) )
      ( label = `Type`                     value = zcl_zlk05_sys_api=>param_type_text( ls_meta-type ) )
      ( label = `Further Selection Criteria` value = lv_restr )
      ( label = `Unit`                     value = ls_meta-unit )
      ( label = `Parameter Group`          value = ls_meta-pgroup )
      ( label = `Parameter Description`    value = ls_meta-description )
      ( label = `CSN Component`            value = ls_meta-csn_component )
      ( label = `System-Wide Parameter`    value = zcl_zlk05_sys_api=>yes_no( ls_meta-is_system ) )
      ( label = `Dynamic Parameter`        value = zcl_zlk05_sys_api=>yes_no( ls_meta-is_dynamic ) )
      ( label = `Vector Parameter`         value = zcl_zlk05_sys_api=>yes_no( ls_meta-is_vector ) )
      ( label = `Has Subparameters`        value = zcl_zlk05_sys_api=>yes_no( ls_meta-has_subparameters ) )
      ( label = `Check Function Exists`    value = zcl_zlk05_sys_api=>yes_no( ls_meta-is_check_fct_defined ) ) ).

    IF lv_rec IS NOT INITIAL.
      APPEND VALUE #( label = `Recommended Value`
                      value = CONV string( lv_rec ) ) TO result.
    ENDIF.
    IF lv_note IS NOT INITIAL.
      APPEND VALUE #( label = `Associated Note`
                      value = CONV string( lv_note ) ) TO result.
    ENDIF.

  ENDMETHOD.

  METHOD get_rfc_destinations.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).
    DATA(lv_type) = to_upper( condense( iv_rfctype ) ).

    " RFCOPTIONS is read only to take the target host and the system
    " number out of it - user, client and password fields are never read
    SELECT d~rfcdest, d~rfctype, d~rfcoptions, t~rfcdoc1
      FROM rfcdes AS d
      LEFT OUTER JOIN rfcdoc AS t
        ON t~rfcdest = d~rfcdest
       AND t~rfclang = @sy-langu
      WHERE d~rfcdest LIKE @lv_like ESCAPE '#'
      ORDER BY d~rfcdest
      INTO TABLE @DATA(lt_dest)
      UP TO @iv_max ROWS.

    LOOP AT lt_dest ASSIGNING FIELD-SYMBOL(<d>).
      IF lv_type IS NOT INITIAL AND <d>-rfctype <> lv_type.
        CONTINUE.
      ENDIF.
      IF zcl_zlk05_auth=>check_rfc_dest( iv_rfctype = CONV string( <d>-rfctype )
                                         iv_rfcdest = CONV string( <d>-rfcdest ) )-allowed = abap_false.
        CONTINUE.
      ENDIF.

      DATA(lv_opt) = CONV string( <d>-rfcoptions ).
      APPEND VALUE #(
        rfcdest  = <d>-rfcdest
        rfctype  = <d>-rfctype
        typetext = rfc_type_text( CONV string( <d>-rfctype ) )
        target   = zcl_zlk05_sys_api=>rfc_option( iv_options = lv_opt iv_key = `H` )
        sysnr    = zcl_zlk05_sys_api=>rfc_option( iv_options = lv_opt iv_key = `S` )
        descr    = <d>-rfcdoc1 ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD rfc_type_text.

    IF mt_rfctype_text IS INITIAL.
      CALL FUNCTION 'DD_DOMVALUES_GET'
      EXPORTING
        domname        = 'RFCTYPE'
        text           = abap_true
        langu          = sy-langu
      TABLES
        dd07v_tab      = mt_rfctype_text
      EXCEPTIONS
        wrong_textflag = 1
        OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR mt_rfctype_text.
      ENDIF.
    ENDIF.
    result = VALUE #( mt_rfctype_text[ domvalue_l = to_upper( iv_rfctype ) ]-ddtext OPTIONAL ).
    IF result IS INITIAL.
      result = iv_rfctype.
    ENDIF.

  ENDMETHOD.


  METHOD get_auth_failures.

    DATA lv_bname TYPE xubname.
    DATA lv_from  TYPE timestampl.
    DATA lt_fails TYPE usr07_ext_tt.
    DATA ls_ret   TYPE bapiret2.
    DATA lt_rfc   TYPE bapirettab.
    DATA lv_date  TYPE d.
    DATA lv_time  TYPE t.
    DATA lt_pairs TYPE string_table.

    CLEAR: et_fails, ev_message.
    lv_bname = to_upper( condense( iv_bname ) ).
    IF lv_bname IS INITIAL.
      lv_bname = sy-uname.
    ENDIF.

    " the checks of another user are as protected as the user himself -
    " SUSR_USER_SU53_READ checks S_USER_GRP too, this gives the message
    IF lv_bname <> sy-uname.
      DATA(ls_auth) = zcl_zlk05_auth=>check_user_display( CONV string( lv_bname ) ).
      IF ls_auth-allowed = abap_false.
        ev_message = ls_auth-message.
        RETURN.
      ENDIF.
    ENDIF.

    GET TIME STAMP FIELD lv_from.
    TRY.
        lv_from = cl_abap_tstmp=>subtractsecs( tstmp = lv_from secs = iv_seconds ).
      CATCH cx_parameter_invalid_range cx_parameter_invalid_type.
        CLEAR lv_from.
    ENDTRY.

    CALL FUNCTION 'SUSR_USER_SU53_READ'
      EXPORTING
        iv_bname              = lv_bname
        iv_from               = lv_from
        iv_all_servers        = abap_true
        iv_convert_app_name   = abap_true
        iv_max_server_entries = 100
      IMPORTING
        et_usr07_ext          = lt_fails
        es_return             = ls_ret
        et_rfc_error          = lt_rfc.

    IF ls_ret-type CA 'EAX'.
      ev_message = ls_ret-message.
      RETURN.
    ENDIF.

    IF mt_reason_text IS INITIAL.
      CALL FUNCTION 'DD_DOMVALUES_GET'
        EXPORTING
          domname        = 'SUTRREASON'
          text           = abap_true
          langu          = sy-langu
        TABLES
          dd07v_tab      = mt_reason_text
        EXCEPTIONS
          wrong_textflag = 1
          OTHERS         = 2.
      IF sy-subrc <> 0.
        CLEAR mt_reason_text.
      ENDIF.
    ENDIF.

    SORT lt_fails BY timestamp DESCENDING.

    " texts of the authorization objects, read once for the whole list
    IF lt_fails IS NOT INITIAL.
      SELECT object, ttext FROM tobjt
        FOR ALL ENTRIES IN @lt_fails
        WHERE langu = @sy-langu AND object = @lt_fails-objct
        INTO TABLE @DATA(lt_objtext).
    ENDIF.

    LOOP AT lt_fails ASSIGNING FIELD-SYMBOL(<f>).
      CONVERT TIME STAMP <f>-timestamp TIME ZONE sy-zonlo INTO DATE lv_date TIME lv_time.

      " FIELD = value pairs of the check, in the order of the object
      CLEAR lt_pairs.
      DATA(lt_fld) = VALUE string_table( ( CONV #( <f>-fiel1 ) ) ( CONV #( <f>-fiel2 ) )
                                         ( CONV #( <f>-fiel3 ) ) ( CONV #( <f>-fiel4 ) )
                                         ( CONV #( <f>-fiel5 ) ) ( CONV #( <f>-fiel6 ) )
                                         ( CONV #( <f>-fiel7 ) ) ( CONV #( <f>-fiel8 ) )
                                         ( CONV #( <f>-fiel9 ) ) ( CONV #( <f>-fiel0 ) ) ).
      DATA(lt_val) = VALUE string_table( ( CONV #( <f>-val01 ) ) ( CONV #( <f>-val02 ) )
                                         ( CONV #( <f>-val03 ) ) ( CONV #( <f>-val04 ) )
                                         ( CONV #( <f>-val05 ) ) ( CONV #( <f>-val06 ) )
                                         ( CONV #( <f>-val07 ) ) ( CONV #( <f>-val08 ) )
                                         ( CONV #( <f>-val09 ) ) ( CONV #( <f>-val10 ) ) ).
      LOOP AT lt_fld INTO DATA(lv_fld) WHERE table_line IS NOT INITIAL.
        APPEND |{ lv_fld } = { lt_val[ sy-tabix ] }| TO lt_pairs.
      ENDLOOP.

      APPEND VALUE #(
        date     = zcl_zlk05_sys_api=>format_date( lv_date )
        time     = zcl_zlk05_sys_api=>format_time( lv_time )
        instance = <f>-instance
        objct    = <f>-objct
        objtext  = VALUE #( lt_objtext[ object = <f>-objct ]-ttext OPTIONAL )
        fields   = concat_lines_of( table = lt_pairs sep = `, ` )
        rc       = condense( CONV string( <f>-rc ) )
        reason   = VALUE #( mt_reason_text[ domvalue_l = <f>-reason ]-ddtext OPTIONAL )
        tcode    = <f>-p_tcode
        program  = <f>-abapprog
        line     = condense( CONV string( <f>-abapline ) ) ) TO et_fails.
    ENDLOOP.

    IF et_fails IS INITIAL.
      ev_message = |No failed authorization checks for { lv_bname } in the last { iv_seconds DIV 3600 } hours.|.
    ENDIF.

  ENDMETHOD.

  METHOD search_roles.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    " short text: logon language, English where it is not translated
    SELECT d~agr_name, d~parent_agr, d~change_usr, d~change_dat,
           coalesce( t~text, e~text ) AS text
      FROM agr_define AS d
      LEFT OUTER JOIN agr_texts AS t
        ON t~agr_name = d~agr_name AND t~spras = @sy-langu AND t~line = 0
      LEFT OUTER JOIN agr_texts AS e
        ON e~agr_name = d~agr_name AND e~spras = 'E' AND e~line = 0
      WHERE d~agr_name LIKE @lv_like ESCAPE '#'
      ORDER BY d~agr_name
      INTO TABLE @DATA(lt_roles)
      UP TO @iv_max ROWS.

    IF lt_roles IS INITIAL.
      RETURN.
    ENDIF.

    SELECT agr_name FROM agr_flags
      FOR ALL ENTRIES IN @lt_roles
      WHERE agr_name   = @lt_roles-agr_name
        AND flag_type  = 'COLL_AGR'
        AND flag_value = 'X'
      INTO TABLE @DATA(lt_coll).
    SORT lt_coll BY agr_name.

    LOOP AT lt_roles ASSIGNING FIELD-SYMBOL(<r>).
      IF zcl_zlk05_auth=>check_role( CONV string( <r>-agr_name ) )-allowed = abap_false.
        CONTINUE.
      ENDIF.
      READ TABLE lt_coll WITH KEY agr_name = <r>-agr_name BINARY SEARCH TRANSPORTING NO FIELDS.
      DATA(lv_coll) = xsdbool( sy-subrc = 0 ).
      APPEND VALUE #(
        agr_name   = <r>-agr_name
        text       = <r>-text
        composite  = COND #( WHEN lv_coll = abap_true THEN `Composite`
                             WHEN <r>-parent_agr IS NOT INITIAL THEN `Derived`
                             ELSE `Single` )
        parent     = <r>-parent_agr
        changed_by = <r>-change_usr
        changed_on = zcl_zlk05_sys_api=>format_date( <r>-change_dat ) ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_role_detail.

    CLEAR: et_head, et_descr, et_tcodes, et_auth, et_users, et_roles, ev_message.

    DATA(lv_role) = CONV agr_name( to_upper( condense( iv_role ) ) ).
    IF lv_role IS INITIAL.
      ev_message = `Enter a role`.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM agr_define WHERE agr_name = @lv_role INTO @DATA(ls_def).
    IF sy-subrc <> 0.
      ev_message = |Role { lv_role } does not exist|.
      RETURN.
    ENDIF.

    DATA(ls_auth) = zcl_zlk05_auth=>check_role( CONV string( lv_role ) ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    " --- description tab: short text (line 0) and long text (lines 1..n)
    SELECT spras, line, text FROM agr_texts
      WHERE agr_name = @lv_role AND ( spras = @sy-langu OR spras = 'E' )
      ORDER BY spras, line
      INTO TABLE @DATA(lt_text).
    DATA(lv_lang) = COND spras( WHEN line_exists( lt_text[ spras = sy-langu ] ) THEN sy-langu ELSE 'E' ).
    DATA(lv_short) = VALUE string( ).
    LOOP AT lt_text INTO DATA(ls_text) WHERE spras = lv_lang.
      IF ls_text-line = 0.
        lv_short = ls_text-text.
      ELSE.
        APPEND CONV string( ls_text-text ) TO et_descr.
      ENDIF.
    ENDLOOP.

    SELECT SINGLE @abap_true FROM agr_flags
      WHERE agr_name = @lv_role AND flag_type = 'COLL_AGR' AND flag_value = 'X'
      INTO @DATA(lv_coll).

    SELECT profile, generated FROM agr_1016
      WHERE agr_name = @lv_role
      ORDER BY counter
      INTO TABLE @DATA(lt_prof).
    DATA(lv_prof) = VALUE string( ).
    LOOP AT lt_prof INTO DATA(ls_prof).
      lv_prof = condense( |{ lv_prof } { ls_prof-profile }| ).
    ENDLOOP.

    et_head = VALUE #(
      ( label = `Role`          value = lv_role )
      ( label = `Description`   value = lv_short )
      ( label = `Role type`     value = COND #( WHEN lv_coll = abap_true THEN `Composite role`
                                                WHEN ls_def-parent_agr IS NOT INITIAL THEN `Derived role`
                                                ELSE `Single role` ) )
      ( label = `Derived from`  value = ls_def-parent_agr )
      ( label = `Created by`    value = |{ ls_def-create_usr } { zcl_zlk05_sys_api=>format_date( ls_def-create_dat ) }| )
      ( label = `Last changed`  value = |{ ls_def-change_usr } { zcl_zlk05_sys_api=>format_date( ls_def-change_dat ) }| )
      ( label = `Profiles`      value = COND #( WHEN lv_prof IS INITIAL THEN `no profile generated` ELSE lv_prof ) ) ).

    " --- menu tab: the transactions of the role
    SELECT a~tcode, coalesce( t~ttext, e~ttext ) AS ttext
      FROM agr_tcodes AS a
      LEFT OUTER JOIN tstct AS t ON t~tcode = a~tcode AND t~sprsl = @sy-langu
      LEFT OUTER JOIN tstct AS e ON e~tcode = a~tcode AND e~sprsl = 'E'
      WHERE a~agr_name = @lv_role AND a~type = 'TR'
      ORDER BY a~tcode
      INTO TABLE @DATA(lt_tc).
    LOOP AT lt_tc INTO DATA(ls_tc).
      APPEND VALUE #( tcode = ls_tc-tcode text = ls_tc-ttext ) TO et_tcodes.
    ENDLOOP.

    " --- authorizations tab: the active values of the role
    SELECT object, auth, field, low, high FROM agr_1251
      WHERE agr_name = @lv_role AND deleted = ''
      ORDER BY object, auth, field, counter
      INTO TABLE @DATA(lt_auth).
    LOOP AT lt_auth INTO DATA(ls_auth_line).
      APPEND VALUE #( object = ls_auth_line-object auth = ls_auth_line-auth
                      field  = ls_auth_line-field  low  = ls_auth_line-low
                      high   = ls_auth_line-high ) TO et_auth.
    ENDLOOP.

    " --- user tab: assignments and their validity today
    SELECT uname, from_dat, to_dat FROM agr_users
      WHERE agr_name = @lv_role
      ORDER BY uname, from_dat
      INTO TABLE @DATA(lt_usr).
    LOOP AT lt_usr INTO DATA(ls_usr).
      DATA(lv_valid) = COND string( WHEN ls_usr-to_dat < sy-datum THEN `Expired`
                                    WHEN ls_usr-from_dat > sy-datum THEN `Future`
                                    ELSE `Valid` ).
      APPEND VALUE #( uname    = ls_usr-uname
                      from_dat = zcl_zlk05_sys_api=>format_date( ls_usr-from_dat )
                      to_dat   = zcl_zlk05_sys_api=>format_date( ls_usr-to_dat )
                      validity = lv_valid
                      state    = SWITCH #( lv_valid WHEN `Valid` THEN `Success`
                                                    WHEN `Expired` THEN `Error`
                                                    ELSE `Warning` ) ) TO et_users.
    ENDLOOP.

    " --- roles tab of a composite role: its single roles
    IF lv_coll = abap_true.
      SELECT a~child_agr, coalesce( t~text, e~text ) AS text
        FROM agr_agrs AS a
        LEFT OUTER JOIN agr_texts AS t
          ON t~agr_name = a~child_agr AND t~spras = @sy-langu AND t~line = 0
        LEFT OUTER JOIN agr_texts AS e
          ON e~agr_name = a~child_agr AND e~spras = 'E' AND e~line = 0
        WHERE a~agr_name = @lv_role
        ORDER BY a~child_agr
        INTO TABLE @DATA(lt_child).
      LOOP AT lt_child INTO DATA(ls_child).
        APPEND VALUE #( agr_name = ls_child-child_agr text = ls_child-text
                        composite = `Single` ) TO et_roles.
      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD get_system_status.

    DATA lv_tzone TYPE ttzcu-tzonesys.

    " --- Usage data
    result = VALUE #(
      ( group = `Usage Data` label = `Client`        value = sy-mandt )
      ( group = `Usage Data` label = `User`          value = sy-uname )
      ( group = `Usage Data` label = `Language`      value = sy-langu )
      ( group = `Usage Data` label = `Date (user)`   value = zcl_zlk05_sys_api=>format_date( sy-datlo ) )
      ( group = `Usage Data` label = `Time (user)`   value = zcl_zlk05_sys_api=>format_time( sy-timlo ) )
      ( group = `Usage Data` label = `Time zone (user)` value = sy-zonlo ) ).

    " --- Repository data of the running transaction
    APPEND VALUE #( group = `Repository Data` label = `Transaction`
                    value = COND #( WHEN iv_tcode IS INITIAL THEN `SMEN` ELSE to_upper( iv_tcode ) ) ) TO result.
    IF iv_program IS NOT INITIAL.
      APPEND VALUE #( group = `Repository Data` label = `Program (app class)`
                      value = to_upper( iv_program ) ) TO result.
      SELECT SINGLE devclass FROM tadir
        WHERE pgmid = 'R3TR' AND object = 'CLAS' AND obj_name = @iv_program
        INTO @DATA(lv_devclass).
      IF sy-subrc = 0.
        APPEND VALUE #( group = `Repository Data` label = `Package` value = lv_devclass ) TO result.
      ENDIF.
    ENDIF.

    " --- SAP data: release and the main software components (CVERS)
    APPEND VALUE #( group = `SAP Data` label = `SAP release` value = sy-saprl ) TO result.
    SELECT component, release, extrelease FROM cvers
      WHERE component IN ('SAP_BASIS', 'SAP_ABA', 'SAP_UI', 'S4CORE')
      ORDER BY component
      INTO TABLE @DATA(lt_comp).
    LOOP AT lt_comp INTO DATA(ls_comp).
      APPEND VALUE #( group = `SAP Data` label = |Component { ls_comp-component }|
                      value = |Release { ls_comp-release }, SP level { ls_comp-extrelease }| ) TO result.
    ENDLOOP.

    " --- Host and database data
    SELECT SINGLE tzonesys FROM ttzcu INTO @lv_tzone ##SUBRC_OK.
    result = VALUE #( BASE result
      ( group = `Host Data`     label = `System ID`          value = sy-sysid )
      ( group = `Host Data`     label = `Application server` value = sy-host )
      ( group = `Host Data`     label = `Operating system`   value = sy-opsys )
      ( group = `Host Data`     label = `System time zone`   value = lv_tzone )
      ( group = `Database Data` label = `Database system`    value = sy-dbsys ) ).

  ENDMETHOD.

ENDCLASS.
