CLASS zcl_zlk05_api_dev DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - ABAP Workbench (SE11/SE24/SE37/SE38)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_ZLK05_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    "! Search tables/views (kind = TABL) or data elements (kind = DTEL)
    CLASS-METHODS search_ddic
      IMPORTING iv_pattern    TYPE string
                iv_kind       TYPE string DEFAULT 'TABL'
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_ddic_obj.

    CLASS-METHODS get_table_fields
      IMPORTING iv_tabname    TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_ddic_field.

    CLASS-METHODS get_dtel_detail
      IMPORTING iv_rollname   TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_kv.

    CLASS-METHODS search_classes
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_class.

    CLASS-METHODS get_class_components
      IMPORTING iv_clsname    TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_component.

    CLASS-METHODS search_functions
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_function.

    CLASS-METHODS get_function_params
      IMPORTING iv_funcname   TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_fparam.

    CLASS-METHODS search_programs
      IMPORTING iv_pattern    TYPE string
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_program.

    "! Reads the source of a report / include via READ REPORT
    CLASS-METHODS get_program_source
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Kind of a dictionary object - see ZCL_ZLK05_SYS_API=>C_TABLE_KIND
    CLASS-METHODS get_table_kind
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS get_method_include
      IMPORTING iv_class      TYPE string
                iv_method     TYPE string
      RETURNING VALUE(result) TYPE string.

    CLASS-METHODS get_function_include
      IMPORTING iv_funcname   TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Message classes of T100A the user may display (S_DEVELOP MSAG)
    CLASS-METHODS search_message_classes
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 300
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_msgclass.

    "! Attributes and messages of a message class
    CLASS-METHODS get_messages
      IMPORTING iv_arbgb    TYPE string
      EXPORTING et_head     TYPE zcl_zlk05_sys_api=>ty_t_kv
                et_msgs     TYPE zcl_zlk05_sys_api=>ty_t_msg
                ev_message  TYPE string.

    "! Long text of a message (document class NA) as plain lines
    CLASS-METHODS get_message_longtext
      IMPORTING iv_arbgb      TYPE string
                iv_msgnr      TYPE string
      RETURNING VALUE(result) TYPE string_table.

  PROTECTED SECTION.

  PRIVATE SECTION.

    "! DOKIL / DOCU_GET object of a message long text: the message class
    "! directly followed by the 3 digit number (00311, SPRX083 ...)
    CLASS-METHODS msg_doc_object
      IMPORTING iv_arbgb      TYPE arbgb
                iv_msgnr      TYPE msgnr
      RETURNING VALUE(result) TYPE doku_obj.

ENDCLASS.



CLASS zcl_zlk05_api_dev IMPLEMENTATION.



  METHOD search_ddic.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    IF to_upper( iv_kind ) = 'DTEL'.

      SELECT FROM dd04l AS d
        LEFT OUTER JOIN dd04t AS t
          ON  t~rollname   = d~rollname
          AND t~ddlanguage = @sy-langu
          AND t~as4local   = 'A'
        FIELDS d~rollname, d~datatype, d~leng, d~as4user, d~as4date,
               t~ddtext
        WHERE d~rollname LIKE @lv_like ESCAPE '#'
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
                        chdate   = zcl_zlk05_sys_api=>format_date( <d>-as4date ) ) TO result.
      ENDLOOP.

    ELSE.

      SELECT FROM dd02l AS d
        LEFT OUTER JOIN dd02t AS t
          ON  t~tabname    = d~tabname
          AND t~ddlanguage = @sy-langu
          AND t~as4local   = 'A'
        FIELDS d~tabname, d~tabclass, d~as4user, d~as4date, t~ddtext
        WHERE d~tabname LIKE @lv_like ESCAPE '#'
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
                        chdate   = zcl_zlk05_sys_api=>format_date( <t>-as4date ) ) TO result.
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
      ( label = `Changed On`      value = zcl_zlk05_sys_api=>format_date( ls_d-as4date ) ) ).

  ENDMETHOD.

  METHOD search_classes.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    SELECT FROM seoclass AS c
      LEFT OUTER JOIN seoclasstx AS t
        ON  t~clsname = c~clsname
        AND t~langu   = @sy-langu
      FIELDS c~clsname, c~clstype, t~descript
      WHERE c~clsname LIKE @lv_like ESCAPE '#'
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

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    SELECT FROM tfdir AS f
      LEFT OUTER JOIN enlfdir AS e
        ON e~funcname = f~funcname
      LEFT OUTER JOIN tftit AS t
        ON  t~funcname = f~funcname
        AND t~spras    = @sy-langu
      FIELDS f~funcname, f~fmode, e~area, t~stext
      WHERE f~funcname LIKE @lv_like ESCAPE '#'
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

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    SELECT FROM trdir AS d
      LEFT OUTER JOIN tadir AS a
        ON  a~pgmid    = 'R3TR'
        AND a~object   = 'PROG'
        AND a~obj_name = d~name
      FIELDS d~name, d~subc, d~cnam, d~udat, a~devclass
      WHERE d~name LIKE @lv_like ESCAPE '#'
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
        chdate  = zcl_zlk05_sys_api=>format_date( <p>-udat )
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

  METHOD get_table_kind.

    DATA(lv_name) = CONV tabname( to_upper( condense( iv_name ) ) ).
    result = zcl_zlk05_sys_api=>c_table_kind-none.
    IF lv_name IS INITIAL.
      RETURN.
    ENDIF.

    SELECT SINGLE tabclass FROM dd02l
      WHERE tabname = @lv_name AND as4local = 'A'
      INTO @DATA(lv_class).
    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    CASE lv_class.
      WHEN 'TRANSP' OR 'CLUSTER' OR 'POOL'.
        result = zcl_zlk05_sys_api=>c_table_kind-table.
      WHEN 'VIEW'.
        SELECT SINGLE viewclass FROM dd25l
          WHERE viewname = @lv_name AND as4local = 'A'
          INTO @DATA(lv_viewclass) ##SUBRC_OK.
        result = SWITCH #( lv_viewclass
                   WHEN 'D' THEN zcl_zlk05_sys_api=>c_table_kind-db_view
                   WHEN 'C' THEN zcl_zlk05_sys_api=>c_table_kind-maint_view
                   ELSE zcl_zlk05_sys_api=>c_table_kind-other_view ).
      WHEN OTHERS.
        result = zcl_zlk05_sys_api=>c_table_kind-structure.
    ENDCASE.

  ENDMETHOD.

  METHOD get_method_include.

    DATA ls_key TYPE seocpdkey.
    ls_key-clsname = to_upper( condense( iv_class ) ).
    ls_key-cpdname = to_upper( condense( iv_method ) ).
    IF ls_key-clsname IS INITIAL OR ls_key-cpdname IS INITIAL.
      RETURN.
    ENDIF.

    cl_oo_classname_service=>get_method_include(
      EXPORTING
        mtdkey              = ls_key
      RECEIVING
        result              = DATA(lv_include)
      EXCEPTIONS
        class_not_existing  = 1
        method_not_existing = 2
        OTHERS              = 3 ).
    IF sy-subrc = 0.
      result = lv_include.
    ENDIF.

  ENDMETHOD.


  METHOD get_function_include.

    DATA lv_funcname TYPE rs38l-name.
    DATA lv_include  TYPE rs38l-include.

    lv_funcname = to_upper( condense( iv_funcname ) ).
    IF lv_funcname IS INITIAL.
      RETURN.
    ENDIF.

    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = lv_funcname
      IMPORTING
        include            = lv_include
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc = 0.
      result = lv_include.
    ENDIF.

  ENDMETHOD.

  METHOD msg_doc_object.
    result = |{ iv_arbgb }{ iv_msgnr }|.
  ENDMETHOD.


  METHOD search_message_classes.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    " the package comes with the search, so the S_DEVELOP check per
    " message class needs no further read
    SELECT a~arbgb, coalesce( t~stext, a~stext ) AS stext, d~devclass
      FROM t100a AS a
      LEFT OUTER JOIN t100t AS t
        ON t~arbgb = a~arbgb AND t~sprsl = @sy-langu
      LEFT OUTER JOIN tadir AS d
        ON d~pgmid = 'R3TR' AND d~object = 'MSAG' AND d~obj_name = a~arbgb
      WHERE a~arbgb LIKE @lv_like ESCAPE '#'
      ORDER BY a~arbgb
      INTO TABLE @DATA(lt_cls)
      UP TO @iv_max ROWS.

    LOOP AT lt_cls ASSIGNING FIELD-SYMBOL(<c>).
      IF zcl_zlk05_auth=>check_develop( iv_actvt   = zcl_zlk05_auth=>c_actvt_display
                                        iv_package = CONV #( <c>-devclass )
                                        iv_objtype = `MSAG`
                                        iv_objname = CONV #( <c>-arbgb ) )-allowed = abap_false.
        CONTINUE.
      ENDIF.
      APPEND VALUE #( arbgb = <c>-arbgb stext = <c>-stext devclass = <c>-devclass ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_messages.

    DATA lr_obj TYPE RANGE OF dokil-object.

    CLEAR: et_head, et_msgs, ev_message.

    DATA(lv_arbgb) = CONV arbgb( to_upper( condense( iv_arbgb ) ) ).
    IF lv_arbgb IS INITIAL.
      ev_message = `Enter a message class`.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM t100a WHERE arbgb = @lv_arbgb INTO @DATA(ls_head).
    IF sy-subrc <> 0.
      ev_message = |Message class { lv_arbgb } does not exist|.
      RETURN.
    ENDIF.

    DATA(ls_auth) = zcl_zlk05_auth=>check_message_class( CONV string( lv_arbgb ) ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    SELECT SINGLE stext FROM t100t
      WHERE arbgb = @lv_arbgb AND sprsl = @sy-langu
      INTO @DATA(lv_stext).
    IF sy-subrc <> 0.
      lv_stext = ls_head-stext.
    ENDIF.
    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = 'MSAG' AND obj_name = @lv_arbgb
      INTO @DATA(lv_devclass) ##SUBRC_OK.

    et_head = VALUE #(
      ( label = `Message class`      value = lv_arbgb )
      ( label = `Short text`         value = lv_stext )
      ( label = `Package`            value = lv_devclass )
      ( label = `Original language`  value = ls_head-masterlang )
      ( label = `Person responsible` value = ls_head-respuser )
      ( label = `Last changed by`    value = |{ ls_head-lastuser } { zcl_zlk05_sys_api=>format_date( ls_head-ldate ) } { zcl_zlk05_sys_api=>format_time( ls_head-ltime ) }| ) ).

    " messages in the logon language, the original language where a
    " message is not translated - like SE91 shows them
    SELECT sprsl, msgnr, text FROM t100
      WHERE arbgb = @lv_arbgb AND ( sprsl = @sy-langu OR sprsl = @ls_head-masterlang )
      ORDER BY msgnr
      INTO TABLE @DATA(lt_t100).
    SELECT msgnr, selfdef FROM t100u
      WHERE arbgb = @lv_arbgb
      INTO TABLE @DATA(lt_self).
    SORT lt_self BY msgnr.

    DATA(lt_nr) = lt_t100.
    SORT lt_nr BY msgnr.
    DELETE ADJACENT DUPLICATES FROM lt_nr COMPARING msgnr.

    LOOP AT lt_nr INTO DATA(ls_nr).
      APPEND VALUE #( sign = 'I' option = 'EQ'
                      low = msg_doc_object( iv_arbgb = lv_arbgb iv_msgnr = ls_nr-msgnr ) ) TO lr_obj.
    ENDLOOP.
    IF lr_obj IS NOT INITIAL.
      SELECT DISTINCT object FROM dokil
        WHERE id = 'NA' AND object IN @lr_obj
        INTO TABLE @DATA(lt_doc).
      SORT lt_doc BY object.
    ENDIF.

    LOOP AT lt_nr INTO ls_nr.
      READ TABLE lt_t100 INTO DATA(ls_t100) WITH KEY sprsl = sy-langu msgnr = ls_nr-msgnr.
      IF sy-subrc <> 0.
        " any language, but never the text of the previous message
        READ TABLE lt_t100 INTO ls_t100 WITH KEY msgnr = ls_nr-msgnr.
        IF sy-subrc <> 0.
          CLEAR ls_t100.
        ENDIF.
      ENDIF.
      READ TABLE lt_self INTO DATA(ls_self) WITH KEY msgnr = ls_nr-msgnr BINARY SEARCH.
      DATA(lv_self) = xsdbool( sy-subrc = 0 AND ls_self-selfdef IS NOT INITIAL ).
      READ TABLE lt_doc WITH KEY object = msg_doc_object( iv_arbgb = lv_arbgb iv_msgnr = ls_nr-msgnr )
        BINARY SEARCH TRANSPORTING NO FIELDS.
      DATA(lv_doc) = xsdbool( sy-subrc = 0 ).
      APPEND VALUE #( msgnr    = ls_nr-msgnr
                      text     = ls_t100-text
                      selfdef  = COND #( WHEN lv_self = abap_true THEN `Yes` ELSE `` )
                      longtext = COND #( WHEN lv_doc = abap_true THEN `Yes` ELSE `` ) ) TO et_msgs.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_message_longtext.

    DATA lt_line TYPE STANDARD TABLE OF tline WITH EMPTY KEY.
    DATA lv_lang TYPE sy-langu.

    DATA(lv_arbgb) = CONV arbgb( to_upper( condense( iv_arbgb ) ) ).
    DATA(lv_msgnr) = CONV msgnr( condense( iv_msgnr ) ).

    IF zcl_zlk05_auth=>check_message_class( CONV string( lv_arbgb ) )-allowed = abap_false.
      RETURN.
    ENDIF.

    SELECT SINGLE masterlang FROM t100a WHERE arbgb = @lv_arbgb INTO @DATA(lv_master) ##SUBRC_OK.

    " logon language, English, the original language - the first one that has the text
    LOOP AT VALUE string_table( ( CONV string( sy-langu ) ) ( `E` ) ( CONV string( lv_master ) ) )
         INTO DATA(lv_try).
      lv_lang = lv_try.
      CLEAR lt_line.
      CALL FUNCTION 'DOCU_GET'
        EXPORTING
          id                = 'NA'
          langu             = lv_lang
          object            = msg_doc_object( iv_arbgb = lv_arbgb iv_msgnr = lv_msgnr )
        TABLES
          line              = lt_line
        EXCEPTIONS
          no_docu_on_screen = 1
          no_docu_self_def  = 2
          no_docu_temp      = 3
          ret_code          = 4
          OTHERS            = 5.
      IF sy-subrc = 0 AND lt_line IS NOT INITIAL.
        EXIT.
      ENDIF.
    ENDLOOP.

    " SAPscript to plain text: paragraphs, the standard headings of a
    " message long text, no formatting tags
    LOOP AT lt_line INTO DATA(ls_line).
      DATA(lv_text) = CONV string( ls_line-tdline ).
      REPLACE ALL OCCURRENCES OF REGEX `<[^>]*>` IN lv_text WITH `` ##REGEX_POSIX.
      REPLACE ALL OCCURRENCES OF `&CAUSE&`            IN lv_text WITH `Diagnosis`.
      REPLACE ALL OCCURRENCES OF `&SYSTEM_RESPONSE&`  IN lv_text WITH `System Response`.
      REPLACE ALL OCCURRENCES OF `&WHAT_TO_DO&`       IN lv_text WITH `Procedure`.
      REPLACE ALL OCCURRENCES OF `&SYS_ADMIN&`        IN lv_text WITH `Procedure for System Administration`.
      IF ( ls_line-tdformat = '=' OR ls_line-tdformat = ' ' ) AND result IS NOT INITIAL.
        DATA(lv_last) = lines( result ).
        result[ lv_last ] = |{ result[ lv_last ] } { lv_text }|.
      ELSE.
        IF ls_line-tdformat(1) = 'U' AND result IS NOT INITIAL.
          APPEND `` TO result.
        ENDIF.
        APPEND lv_text TO result.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
