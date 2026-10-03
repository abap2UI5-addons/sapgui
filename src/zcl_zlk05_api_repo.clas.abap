CLASS zcl_zlk05_api_repo DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - Area menu and transactions (SE93)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_ZLK05_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    "! Reads the children of one node of an SAP area menu.
    "! iv_struct_id - area menu, S000 is the SAP standard menu
    "! iv_node_id   - parent node, initial returns the top level
    CLASS-METHODS get_area_menu_children
      IMPORTING iv_struct_id  TYPE string DEFAULT 'S000'
                iv_node_id    TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_menu_node.

    "! Does the transaction code exist in this system?
    CLASS-METHODS transaction_exists
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    "! Short text of a transaction as shown by the SAP GUI
    CLASS-METHODS get_transaction_text
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE string.

    "! A text symbol of SAPLSEUK, the program behind SE93. The names of the
    "! transaction types live there (001 Dialog, 002 Report, 003 Parameter,
    "! 019 Variant, 028 Object Transaction), so they are read from the
    "! original instead of being duplicated here.
    CLASS-METHODS seuk_text
      IMPORTING iv_key        TYPE string
      RETURNING VALUE(result) TYPE string.

    "! Transactions of TSTC with their short text and derived type.
    CLASS-METHODS get_transactions
      IMPORTING iv_pattern    TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_tcode.

    "! Everything SE93 shows for one transaction.
    CLASS-METHODS get_transaction_detail
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_s_tcode_detail.

  PROTECTED SECTION.
  PRIVATE SECTION.
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
      CHANGING  cs_detail TYPE zcl_zlk05_sys_api=>ty_s_tcode_detail.

    "! One \TAG= component of the parameter string of an OO transaction.
    "! LSEUKF01, FORM split_parameters_comp.
    CLASS-METHODS oo_component
      IMPORTING iv_param      TYPE string
                iv_tag        TYPE string
      RETURNING VALUE(result) TYPE string.

ENDCLASS.



CLASS zcl_zlk05_api_repo IMPLEMENTATION.



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

      DATA ls_node TYPE zcl_zlk05_sys_api=>ty_s_menu_node.
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

    SELECT SINGLE @abap_true FROM tstc WHERE tcode = @lv_tcode INTO @result.

  ENDMETHOD.

  METHOD get_transaction_text.

    DATA(lv_tcode) = CONV tcode( to_upper( condense( iv_tcode ) ) ).
    IF lv_tcode IS INITIAL.
      RETURN.
    ENDIF.

    " logon language first, English as the fallback - like the SAP GUI
    SELECT SINGLE ttext FROM tstct
      WHERE sprsl = @sy-langu AND tcode = @lv_tcode
      INTO @result.
    IF sy-subrc <> 0 OR result IS INITIAL.
      SELECT SINGLE ttext FROM tstct
        WHERE sprsl = 'E' AND tcode = @lv_tcode
        INTO @result ##SUBRC_OK.
    ENDIF.

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
        WHEN `CLASS`.
          cs_detail-classname = ls_param-value.
        WHEN `METHOD`.
          cs_detail-method    = ls_param-value.
        WHEN `UPDATE_MODE`.
          cs_detail-upd_mode = COND string(
              WHEN ls_param-value = `S` THEN `S`
              WHEN ls_param-value = `U` THEN `U`
              ELSE `L` ).
      ENDCASE.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_transactions.

    DATA(lv_like) = zcl_zlk05_sys_api=>to_like_pattern( iv_pattern ).

    SELECT FROM tstc AS t
      LEFT OUTER JOIN tstct AS x
        ON  x~tcode = t~tcode
        AND x~sprsl = @sy-langu
      LEFT OUTER JOIN tstcp AS p
        ON  p~tcode = t~tcode
      FIELDS t~tcode, t~pgmna, t~dypno, t~cinfo, x~ttext, p~param
      WHERE t~tcode LIKE @lv_like ESCAPE '#'
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

    SELECT SINGLE ttext FROM tstct
      WHERE sprsl = @sy-langu AND tcode = @lv_tcode
      INTO @result-ttext ##SUBRC_OK.

    SELECT SINGLE param FROM tstcp
      WHERE tcode = @lv_tcode
      INTO @DATA(lv_param) ##SUBRC_OK.

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
      INTO @DATA(ls_tstcc) ##SUBRC_OK.

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
