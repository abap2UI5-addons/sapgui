CLASS zcl_se80_api DEFINITION PUBLIC.

  PUBLIC SECTION.

    " ===== Types =====
    TYPES:
      BEGIN OF ty_s_source_result,
        source       TYPE string,
        source_local TYPE string,
        source_test  TYPE string,
        syntax_mode  TYPE string,
        lines        TYPE i,
        success      TYPE abap_bool,
        message      TYPE string,
      END OF ty_s_source_result.

    TYPES:
      BEGIN OF ty_s_method,
        cmpname  TYPE string,
        exposure TYPE string,
        mtdtype  TYPE string,
      END OF ty_s_method.
    TYPES ty_t_method TYPE STANDARD TABLE OF ty_s_method WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_field,
        name    TYPE string,
        keyflag TYPE string,
        typtype TYPE string,
        type    TYPE string,
      END OF ty_s_field.
    TYPES ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_prop,
        label TYPE string,
        value TYPE string,
      END OF ty_s_prop.
    TYPES ty_t_prop TYPE STANDARD TABLE OF ty_s_prop WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_usage,
        object   TYPE string,
        obj_name TYPE string,
      END OF ty_s_usage.
    TYPES ty_t_usage TYPE STANDARD TABLE OF ty_s_usage WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_tree_leaf,
        text  TYPE string,
        icon  TYPE string,
        key   TYPE string,
        otype TYPE string,
      END OF ty_s_tree_leaf.
    TYPES:
      BEGIN OF ty_s_tree_child,
        text  TYPE string,
        icon  TYPE string,
        key   TYPE string,
        otype TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_tree_leaf WITH EMPTY KEY,
      END OF ty_s_tree_child.
    TYPES:
      BEGIN OF ty_s_tree_node,
        text  TYPE string,
        icon  TYPE string,
        key   TYPE string,
        otype TYPE string,
        nodes TYPE STANDARD TABLE OF ty_s_tree_child WITH EMPTY KEY,
      END OF ty_s_tree_node.
    TYPES ty_t_tree TYPE STANDARD TABLE OF ty_s_tree_node WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_check_msg,
        type    TYPE string,
        line    TYPE i,
        col     TYPE i,
        message TYPE string,
      END OF ty_s_check_msg.
    TYPES ty_t_check_msg TYPE STANDARD TABLE OF ty_s_check_msg WITH EMPTY KEY.

    TYPES:
      BEGIN OF ty_s_result,
        success TYPE abap_bool,
        message TYPE string,
      END OF ty_s_result.

    " ===== Navigation =====
    METHODS get_package_tree
      IMPORTING iv_package    TYPE devclass
      RETURNING VALUE(result) TYPE ty_t_tree.

    METHODS search_objects
      IMPORTING iv_pattern    TYPE string
                iv_type       TYPE trobjtype OPTIONAL
      RETURNING VALUE(result) TYPE ty_t_tree.

    " ===== Source Reading =====
    METHODS load_source
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_s_source_result.

    " ===== Source Writing =====
    METHODS save_source
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
                iv_source     TYPE string
      RETURNING VALUE(result) TYPE ty_s_result.

    " ===== Activation =====
    METHODS activate_object
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_s_result.

    " ===== Syntax Check =====
    METHODS check_syntax
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
                iv_source     TYPE string
      RETURNING VALUE(result) TYPE ty_t_check_msg.

    " ===== Pretty Printer =====
    METHODS pretty_print
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
                iv_source     TYPE string
      RETURNING VALUE(result) TYPE string.

    " ===== Metadata =====
    METHODS get_metadata
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      EXPORTING et_methods    TYPE ty_t_method
                et_fields     TYPE ty_t_field.

    " ===== Properties =====
    METHODS get_properties
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
                iv_source     TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE ty_t_prop.

    " ===== Where-Used =====
    METHODS get_where_used
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_usage.

    " ===== Utilities =====
    METHODS get_object_icon
      IMPORTING iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS get_text_elements
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS get_documentation
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS get_includes
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_object_status
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS delete_object
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS lock_in_transport
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
                iv_transport  TYPE trkorr
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS create_program
      IMPORTING iv_name       TYPE sobj_name
                iv_package    TYPE devclass
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS create_class
      IMPORTING iv_name       TYPE sobj_name
                iv_package    TYPE devclass
                iv_superclass TYPE seoclsname OPTIONAL
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS create_interface
      IMPORTING iv_name       TYPE sobj_name
                iv_package    TYPE devclass
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS get_subclasses
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_usage.

    METHODS get_implementations
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_usage.

    METHODS get_method_signature
      IMPORTING iv_classname  TYPE sobj_name
                iv_methodname TYPE string
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_class_events
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_source_statistics
      IMPORTING iv_source     TYPE string
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_variants
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_table_content
      IMPORTING iv_name       TYPE sobj_name
                iv_maxrows    TYPE i DEFAULT 10
      RETURNING VALUE(result) TYPE string.

    METHODS get_class_types
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS rename_object
      IMPORTING iv_old_name   TYPE sobj_name
                iv_new_name   TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_s_result.

    METHODS get_fm_exceptions
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_class_constants
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_table_foreign_keys
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_package_info
      IMPORTING iv_package    TYPE devclass
      RETURNING VALUE(result) TYPE ty_t_prop.

    METHODS get_table_append_structures
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_class_friends
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_redefined_methods
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_lock_info
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS get_package_path
      IMPORTING iv_package    TYPE devclass
      RETURNING VALUE(result) TYPE string.

    METHODS copy_object
      IMPORTING iv_source_name TYPE sobj_name
                iv_source_type TYPE trobjtype
                iv_target_name TYPE sobj_name
                iv_package     TYPE devclass
      RETURNING VALUE(result)  TYPE ty_s_result.

    METHODS get_table_tech_settings
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS compare_versions
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE string.

    METHODS get_program_attributes
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_t_field.

    METHODS get_object_dependencies
      IMPORTING iv_name       TYPE sobj_name
                iv_type       TYPE trobjtype
      RETURNING VALUE(result) TYPE ty_t_usage.

    METHODS search_replace_source
      IMPORTING iv_source     TYPE string
                iv_search     TYPE string
                iv_replace    TYPE string
      EXPORTING ev_source     TYPE string
                ev_count      TYPE i.

    METHODS get_object_description
      IMPORTING iv_type       TYPE trobjtype
                iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.

    METHODS read_class_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS read_program_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS read_func_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS read_fugr_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS read_ddls_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS read_bsp_source
      IMPORTING iv_name       TYPE sobj_name
      RETURNING VALUE(result) TYPE ty_s_source_result.

    METHODS count_lines
      IMPORTING iv_source     TYPE string
      RETURNING VALUE(result) TYPE i.

ENDCLASS.


CLASS zcl_se80_api IMPLEMENTATION.

  METHOD get_package_tree.
    " Sub-packages
    SELECT d~devclass, t~ctext
      FROM tdevc AS d
      LEFT JOIN tdevct AS t ON t~devclass = d~devclass AND t~spras = 'E'
      WHERE d~parentcl = @iv_package
      ORDER BY d~devclass
      INTO TABLE @DATA(lt_pkgs) UP TO 50 ROWS.

    " Objects for sub-packages (one query)
    DATA lt_rng TYPE RANGE OF devclass.
    LOOP AT lt_pkgs ASSIGNING FIELD-SYMBOL(<pkg>).
      APPEND VALUE #( sign = 'I' option = 'EQ' low = <pkg>-devclass ) TO lt_rng.
    ENDLOOP.

    DATA lt_objs TYPE STANDARD TABLE OF tadir WITH EMPTY KEY.
    IF lt_rng IS NOT INITIAL.
      SELECT object, obj_name, devclass FROM tadir
        WHERE devclass IN @lt_rng AND pgmid = 'R3TR'
        ORDER BY devclass, object, obj_name
        INTO TABLE @lt_objs UP TO 500 ROWS.
    ENDIF.

    " Build package nodes
    LOOP AT lt_pkgs ASSIGNING <pkg>.
      DATA(ls_node) = VALUE ty_s_tree_node(
        text  = COND #( WHEN <pkg>-ctext IS NOT INITIAL
                        THEN |{ <pkg>-devclass } ({ <pkg>-ctext })|
                        ELSE CONV string( <pkg>-devclass ) )
        icon  = `sap-icon://folder-blank`
        key   = CONV string( <pkg>-devclass )
        otype = `DEVC` ).
      LOOP AT lt_objs ASSIGNING FIELD-SYMBOL(<obj>) WHERE devclass = <pkg>-devclass.
        APPEND VALUE #(
          text  = CONV string( <obj>-obj_name )
          icon  = get_object_icon( <obj>-object )
          key   = CONV string( <obj>-obj_name )
          otype = CONV string( <obj>-object )
        ) TO ls_node-nodes.
      ENDLOOP.
      APPEND ls_node TO result.
      CLEAR ls_node.
    ENDLOOP.

    " Objects in current package - grouped by type
    SELECT object, obj_name FROM tadir
      WHERE devclass = @iv_package AND pgmid = 'R3TR'
      ORDER BY object, obj_name
      INTO TABLE @DATA(lt_cur) UP TO 200 ROWS.

    DATA lt_types TYPE SORTED TABLE OF trobjtype WITH UNIQUE KEY table_line.
    LOOP AT lt_cur ASSIGNING FIELD-SYMBOL(<c>).
      INSERT <c>-object INTO TABLE lt_types.
    ENDLOOP.

    IF lines( lt_cur ) > 5 AND lines( lt_types ) > 1.
      LOOP AT lt_types ASSIGNING FIELD-SYMBOL(<type>).
        DATA(ls_grp) = VALUE ty_s_tree_node(
          icon  = get_object_icon( <type> )
          key   = CONV string( iv_package )
          otype = `DEVC` ).
        LOOP AT lt_cur ASSIGNING <c> WHERE object = <type>.
          DATA(ls_child) = VALUE ty_s_tree_child(
            text  = CONV string( <c>-obj_name )
            icon  = get_object_icon( <c>-object )
            key   = CONV string( <c>-obj_name )
            otype = CONV string( <c>-object ) ).
          " For classes: add methods as sub-items
          IF <c>-object = 'CLAS' OR <c>-object = 'INTF'.
            SELECT cmpname FROM seocompodf
              WHERE clsname = @<c>-obj_name
              AND version = 1 AND mtddecltyp > 0
              ORDER BY cmpname
              INTO TABLE @DATA(lt_mtds)
              UP TO 30 ROWS.
            LOOP AT lt_mtds ASSIGNING FIELD-SYMBOL(<mtd>).
              APPEND VALUE #(
                text  = CONV string( <mtd>-cmpname )
                icon  = `sap-icon://action`
                key   = |{ <c>-obj_name }=>{ <mtd>-cmpname }|
                otype = `METH`
              ) TO ls_child-nodes.
            ENDLOOP.
          ENDIF.
          " For function groups: add FMs as sub-items
          IF <c>-object = 'FUGR'.
            SELECT funcname FROM enlfdir
              WHERE area = @<c>-obj_name
              ORDER BY funcname
              INTO TABLE @DATA(lt_fmods)
              UP TO 20 ROWS.
            LOOP AT lt_fmods ASSIGNING FIELD-SYMBOL(<fmod>).
              APPEND VALUE #(
                text  = CONV string( <fmod>-funcname )
                icon  = `sap-icon://wrench`
                key   = CONV string( <fmod>-funcname )
                otype = `FUNC`
              ) TO ls_child-nodes.
            ENDLOOP.
          ENDIF.
          APPEND ls_child TO ls_grp-nodes.
          CLEAR ls_child.
        ENDLOOP.
        " SE80-style group names
        ls_grp-text = SWITCH #( <type>
          WHEN 'CLAS' THEN |Class Library ({ lines( ls_grp-nodes ) })|
          WHEN 'INTF' THEN |Interfaces ({ lines( ls_grp-nodes ) })|
          WHEN 'PROG' THEN |Programs ({ lines( ls_grp-nodes ) })|
          WHEN 'FUGR' THEN |Function Groups ({ lines( ls_grp-nodes ) })|
          WHEN 'TABL' THEN |Database Tables ({ lines( ls_grp-nodes ) })|
          WHEN 'VIEW' THEN |Views ({ lines( ls_grp-nodes ) })|
          WHEN 'DDLS' THEN |Core Data Services ({ lines( ls_grp-nodes ) })|
          WHEN 'DTEL' THEN |Data Elements ({ lines( ls_grp-nodes ) })|
          WHEN 'DOMA' THEN |Domains ({ lines( ls_grp-nodes ) })|
          WHEN 'TTYP' THEN |Table Types ({ lines( ls_grp-nodes ) })|
          WHEN 'MSAG' THEN |Message Classes ({ lines( ls_grp-nodes ) })|
          WHEN 'ENHO' THEN |Enhancements ({ lines( ls_grp-nodes ) })|
          WHEN 'SRVD' THEN |Service Definitions ({ lines( ls_grp-nodes ) })|
          WHEN 'SRVB' THEN |Service Bindings ({ lines( ls_grp-nodes ) })|
          WHEN 'BDEF' THEN |Behavior Definitions ({ lines( ls_grp-nodes ) })|
          WHEN 'WAPA' THEN |BSP Applications ({ lines( ls_grp-nodes ) })|
          WHEN 'SICF' THEN |ICF Services ({ lines( ls_grp-nodes ) })|
          ELSE |{ <type> } ({ lines( ls_grp-nodes ) })| ).
        APPEND ls_grp TO result.
        CLEAR ls_grp.
      ENDLOOP.
    ELSE.
      LOOP AT lt_cur ASSIGNING <c>.
        APPEND VALUE #(
          text  = CONV string( <c>-obj_name )
          icon  = get_object_icon( <c>-object )
          key   = CONV string( <c>-obj_name )
          otype = CONV string( <c>-object )
        ) TO result.
      ENDLOOP.
    ENDIF.
  ENDMETHOD.


  METHOD search_objects.
    DATA(lv_pat) = |%{ to_upper( iv_pattern ) }%|.
    IF iv_type IS NOT INITIAL.
      SELECT object, obj_name FROM tadir
        WHERE obj_name LIKE @lv_pat AND pgmid = 'R3TR' AND object = @iv_type
        ORDER BY object, obj_name
        INTO TABLE @DATA(lt_f) UP TO 50 ROWS.
    ELSE.
      SELECT object, obj_name FROM tadir
        WHERE obj_name LIKE @lv_pat AND pgmid = 'R3TR'
        ORDER BY object, obj_name
        INTO TABLE @lt_f UP TO 50 ROWS.
    ENDIF.
    LOOP AT lt_f ASSIGNING FIELD-SYMBOL(<f>).
      APPEND VALUE #(
        text  = |{ <f>-obj_name } [{ <f>-object }]|
        icon  = get_object_icon( <f>-object )
        key   = CONV string( <f>-obj_name )
        otype = CONV string( <f>-object )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD load_source.
    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        result = read_class_source( iv_name ).
      WHEN 'PROG'.
        result = read_program_source( iv_name ).
      WHEN 'FUNC'.
        result = read_func_source( iv_name ).
      WHEN 'FUGR'.
        result = read_fugr_source( iv_name ).
      WHEN 'DDLS'.
        result = read_ddls_source( iv_name ).
      WHEN 'WAPA'.
        result = read_bsp_source( iv_name ).
      WHEN 'XSLT'.
        result-syntax_mode = `xml`.
        DATA lt_xslt TYPE STANDARD TABLE OF string.
        DATA lv_xn TYPE syrepid.
        lv_xn = iv_name.
        READ REPORT lv_xn INTO lt_xslt.
        IF sy-subrc = 0.
          result-source = concat_lines_of( table = lt_xslt sep = cl_abap_char_utilities=>newline ).
          result-success = abap_true.
        ELSE.
          result-message = |XSLT { iv_name } not found.|.
        ENDIF.

      WHEN 'TYPE'.
        result-syntax_mode = `abap`.
        DATA lt_tp TYPE STANDARD TABLE OF string.
        DATA lv_tp TYPE syrepid.
        lv_tp = iv_name.
        READ REPORT lv_tp INTO lt_tp.
        IF sy-subrc = 0.
          result-source = concat_lines_of( table = lt_tp sep = cl_abap_char_utilities=>newline ).
          result-success = abap_true.
        ELSE.
          result-message = |Type pool { iv_name } not found.|.
        ENDIF.

      WHEN OTHERS.
        result-syntax_mode = `abap`.
        DATA lt_src TYPE STANDARD TABLE OF string.
        DATA lv_rep TYPE syrepid.
        lv_rep = iv_name.
        READ REPORT lv_rep INTO lt_src.
        IF sy-subrc = 0.
          result-source = concat_lines_of( table = lt_src sep = cl_abap_char_utilities=>newline ).
          result-success = abap_true.
        ELSE.
          result-message = |No source for type { iv_type }|.
        ENDIF.
    ENDCASE.
    result-lines = count_lines( result-source ).
  ENDMETHOD.


  METHOD read_class_source.
    result-syntax_mode = `abap`.
    TRY.
        DATA(lo_settings) = cl_oo_clif_source_settings=>create_instance( ).
        DATA(lo_src) = cl_oo_clif_source=>create_instance(
          clif_name = iv_name
          version   = 'A'
          settings  = lo_settings ).
        DATA lt_source TYPE STANDARD TABLE OF string.
        lo_src->if_oo_clif_source~get_source( IMPORTING source = lt_source ).
        result-source = concat_lines_of( table = lt_source sep = cl_abap_char_utilities=>newline ).

        " Local Types
        DATA(lv_cls) = CONV seoclsname( iv_name ).
        DATA lt_loc TYPE STANDARD TABLE OF string.
        DATA(lv_ccdef) = cl_oo_classname_service=>get_ccdef_name( lv_cls ).
        READ REPORT lv_ccdef INTO lt_loc.
        DATA lt_imp TYPE STANDARD TABLE OF string.
        DATA(lv_ccimp) = cl_oo_classname_service=>get_ccimp_name( lv_cls ).
        READ REPORT lv_ccimp INTO lt_imp.
        IF lt_imp IS NOT INITIAL.
          IF lt_loc IS NOT INITIAL.
            APPEND `` TO lt_loc.
          ENDIF.
          APPEND LINES OF lt_imp TO lt_loc.
        ENDIF.
        result-source_local = concat_lines_of( table = lt_loc sep = cl_abap_char_utilities=>newline ).

        " Test Classes
        DATA lt_tst TYPE STANDARD TABLE OF string.
        DATA(lv_tst) = cl_oo_classname_service=>get_local_testclasses_include( lv_cls ).
        READ REPORT lv_tst INTO lt_tst.
        result-source_test = concat_lines_of( table = lt_tst sep = cl_abap_char_utilities=>newline ).

        result-success = abap_true.
      CATCH cx_root INTO DATA(lx).
        result-message = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD read_program_source.
    DATA lt_src TYPE STANDARD TABLE OF string.
    result-syntax_mode = `abap`.
    READ REPORT iv_name INTO lt_src.
    IF sy-subrc = 0.
      result-source = concat_lines_of( table = lt_src sep = cl_abap_char_utilities=>newline ).
      result-success = abap_true.
    ELSE.
      result-message = |Program { iv_name } not found.|.
    ENDIF.
  ENDMETHOD.


  METHOD read_func_source.
    DATA lt_src TYPE STANDARD TABLE OF string.
    result-syntax_mode = `abap`.
    SELECT SINGLE include FROM tfdir WHERE funcname = @iv_name INTO @DATA(lv_incl).
    IF sy-subrc = 0 AND lv_incl IS NOT INITIAL.
      READ REPORT lv_incl INTO lt_src.
      IF sy-subrc = 0.
        result-source = concat_lines_of( table = lt_src sep = cl_abap_char_utilities=>newline ).
        result-success = abap_true.
      ELSE.
        result-message = |Could not read FM include { lv_incl }.|.
      ENDIF.
    ELSE.
      result-message = |FM { iv_name } not found in TFDIR.|.
    ENDIF.
  ENDMETHOD.


  METHOD read_fugr_source.
    DATA lt_src TYPE STANDARD TABLE OF string.
    result-syntax_mode = `abap`.
    DATA(lv_prog) = CONV syrepid( |SAPL{ iv_name }| ).
    READ REPORT lv_prog INTO lt_src.
    IF sy-subrc = 0.
      result-source = concat_lines_of( table = lt_src sep = cl_abap_char_utilities=>newline ).
      result-success = abap_true.
    ELSE.
      result-message = |Function group { iv_name } not readable.|.
    ENDIF.
  ENDMETHOD.


  METHOD read_ddls_source.
    result-syntax_mode = `sql`.
    SELECT SINGLE source FROM ddddlsrc
      WHERE ddlname = @iv_name AND as4local = 'A'
      INTO @DATA(lv_ddl).
    IF sy-subrc = 0.
      result-source = lv_ddl.
      result-success = abap_true.
    ELSE.
      result-message = |CDS { iv_name } not found.|.
    ENDIF.
  ENDMETHOD.


  METHOD read_bsp_source.
    result-syntax_mode = `html`.
    TRY.
        SELECT applname, pagekey, pagename FROM o2pagdir
          WHERE applname = @iv_name
          ORDER BY pagename
          INTO TABLE @DATA(lt_pages).
        IF lt_pages IS NOT INITIAL.
          DATA lo_page TYPE REF TO cl_o2_api_pages.
          DATA(ls_key) = VALUE o2pagkey(
            applname = lt_pages[ 1 ]-applname
            pagekey  = lt_pages[ 1 ]-pagekey ).
          cl_o2_api_pages=>load(
            EXPORTING p_pagekey = ls_key p_version = 'A'
            IMPORTING p_page = lo_page
            EXCEPTIONS OTHERS = 1 ).
          IF sy-subrc = 0 AND lo_page IS BOUND.
            DATA lt_content TYPE o2pageline_table.
            lo_page->get_page( IMPORTING p_content = lt_content EXCEPTIONS OTHERS = 0 ).
            DATA lt_src TYPE STANDARD TABLE OF string.
            LOOP AT lt_content ASSIGNING FIELD-SYMBOL(<l>).
              APPEND CONV string( <l>-line ) TO lt_src.
            ENDLOOP.
            result-source = concat_lines_of( table = lt_src sep = cl_abap_char_utilities=>newline ).
          ENDIF.
          result-success = abap_true.
        ELSE.
          result-message = |No pages found for BSP { iv_name }.|.
        ENDIF.
      CATCH cx_root INTO DATA(lx).
        result-message = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD save_source.
    DATA lt_source TYPE STANDARD TABLE OF string.
    SPLIT iv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_source.

    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        TRY.
            DATA(lo_settings) = cl_oo_clif_source_settings=>create_instance( ).
            DATA(lo_src) = cl_oo_clif_source=>create_instance(
              clif_name = iv_name
              version   = 'I'
              settings  = lo_settings ).
            " Try to get the lock. Local ($TMP) objects cannot always be locked,
            " so the save is still attempted - but the problem is REPORTED and no
            " longer swallowed, otherwise another user's changes could silently be
            " overwritten.
            DATA lv_lock_warn TYPE string.
            CLEAR lv_lock_warn.
            TRY.
                lo_src->access_permission( access_mode = seok_access_modify ).
              CATCH cx_oo_access_permission INTO DATA(lx_lock).
                lv_lock_warn = | Warning: object could not be locked ({ lx_lock->get_text( ) }).|.
            ENDTRY.
            " Read current source to initialize internal state
            DATA lt_old TYPE STANDARD TABLE OF string.
            lo_src->if_oo_clif_source~get_source( IMPORTING source = lt_old ).
            " Set new source and save
            lo_src->if_oo_clif_source~set_source( lt_source ).
            lo_src->if_oo_clif_source~save( ).
            COMMIT WORK AND WAIT.
            result-success = abap_true.
            result-message = |{ iv_name } saved ({ lines( lt_source ) } lines).{ lv_lock_warn }|.
          CATCH cx_root INTO DATA(lx).
            result-message = |{ iv_name } could not be saved: { lx->get_text( ) }|.
        ENDTRY.

      WHEN 'PROG' OR 'FUNC'.
        DATA lv_rep TYPE syrepid.
        IF iv_type = 'FUNC'.
          SELECT SINGLE include FROM tfdir WHERE funcname = @iv_name INTO @lv_rep.
        ELSE.
          lv_rep = iv_name.
        ENDIF.
        IF lv_rep IS NOT INITIAL.
          INSERT REPORT lv_rep FROM lt_source.
          IF sy-subrc = 0.
            COMMIT WORK.
            result-success = abap_true.
            result-message = |{ iv_name } saved.|.
          ELSE.
            result-message = |Save failed (rc={ sy-subrc }).|.
          ENDIF.
        ELSE.
          result-message = `Cannot determine report name.`.
        ENDIF.

      WHEN OTHERS.
        result-message = |Save not supported for { iv_type }.|.
    ENDCASE.
  ENDMETHOD.


  METHOD activate_object.
    DATA lt_objects TYPE STANDARD TABLE OF dwinactiv.
    DATA ls_obj TYPE dwinactiv.

    ls_obj-object = SWITCH #( iv_type
      WHEN 'CLAS' THEN 'CLAS'
      WHEN 'INTF' THEN 'INTF'
      WHEN 'PROG' THEN 'REPS'
      WHEN 'FUNC' THEN 'FUNC'
      ELSE iv_type ).
    ls_obj-obj_name = iv_name.
    APPEND ls_obj TO lt_objects.

    CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
      EXPORTING
        activate_ddic_objects = abap_true
        with_popup            = abap_false
      TABLES
        objects               = lt_objects
      EXCEPTIONS
        excecution_error      = 1
        cancelled             = 2
        OTHERS                = 3.

    IF sy-subrc = 0.
      result-success = abap_true.
      result-message = |{ iv_name } activated.|.
    ELSE.
      result-message = |Activation failed (rc={ sy-subrc }).|.
    ENDIF.
  ENDMETHOD.


  METHOD check_syntax.
    DATA lt_source TYPE STANDARD TABLE OF string.
    SPLIT iv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_source.

    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        TRY.
            DATA(lo_settings) = cl_oo_clif_source_settings=>create_instance( ).
            DATA(lo_src) = cl_oo_clif_source=>create_instance(
              clif_name = iv_name
              version   = 'A'
              settings  = lo_settings ).
            DATA(ls_check) = lo_src->check( ).
            LOOP AT ls_check-errors ASSIGNING FIELD-SYMBOL(<err>).
              APPEND VALUE #(
                type = `E`
                line = <err>-line
                col  = <err>-col
                message = |Line { <err>-line }: { <err>-message }|
              ) TO result.
            ENDLOOP.
            LOOP AT ls_check-warnings ASSIGNING FIELD-SYMBOL(<wrn>).
              APPEND VALUE #(
                type = `W`
                line = <wrn>-line
                col  = <wrn>-col
                message = |Line { <wrn>-line }: { <wrn>-message }|
              ) TO result.
            ENDLOOP.
            IF result IS INITIAL.
              APPEND VALUE #( type = `S` message = `Syntax check OK.` ) TO result.
            ENDIF.
          CATCH cx_root INTO DATA(lx).
            APPEND VALUE #( type = `E` message = lx->get_text( ) ) TO result.
        ENDTRY.

      WHEN 'PROG' OR 'FUNC'.
        DATA lv_rep TYPE syrepid.
        IF iv_type = 'FUNC'.
          SELECT SINGLE include FROM tfdir WHERE funcname = @iv_name INTO @lv_rep.
        ELSE.
          lv_rep = iv_name.
        ENDIF.
        DATA lv_mess TYPE string.
        DATA lv_lin TYPE i.
        DATA lv_wrd TYPE string.
        SYNTAX-CHECK FOR lt_source MESSAGE lv_mess LINE lv_lin WORD lv_wrd PROGRAM lv_rep.
        IF sy-subrc <> 0.
          APPEND VALUE #( type = `E` line = lv_lin col = 0
            message = |Line { lv_lin }: { lv_mess } ("{ lv_wrd }")| ) TO result.
        ELSE.
          APPEND VALUE #( type = `S` message = `Syntax check OK.` ) TO result.
        ENDIF.

      WHEN OTHERS.
        APPEND VALUE #( type = `W` message = |Syntax check not supported for { iv_type }| ) TO result.
    ENDCASE.
  ENDMETHOD.


  METHOD pretty_print.
    " For classes, use CL_OO_CLIF_SOURCE pretty print
    " For programs, use PRETTY_PRINTER function
    DATA lt_source TYPE STANDARD TABLE OF string.
    SPLIT iv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_source.

    CALL FUNCTION 'PRETTY_PRINTER'
      EXPORTING
        inctoo = abap_false
      TABLES
        ntext  = lt_source
        otext  = lt_source
      EXCEPTIONS
        OTHERS = 0.

    result = concat_lines_of( table = lt_source sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD get_metadata.
    CLEAR: et_methods, et_fields.

    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        " Methods
        SELECT cmpname, exposure, mtddecltyp FROM seocompodf
          WHERE clsname = @iv_name AND version = 1 AND mtddecltyp > 0
          ORDER BY exposure DESCENDING, cmpname
          INTO TABLE @DATA(lt_m).
        LOOP AT lt_m ASSIGNING FIELD-SYMBOL(<m>).
          APPEND VALUE #(
            cmpname  = CONV string( <m>-cmpname )
            exposure = SWITCH #( <m>-exposure WHEN 0 THEN `Priv` WHEN 1 THEN `Prot` WHEN 2 THEN `Pub` ELSE `?` )
            mtdtype  = SWITCH #( <m>-mtddecltyp WHEN 0 THEN `Inst` WHEN 1 THEN `Static` ELSE `` )
          ) TO et_methods.
        ENDLOOP.
        " Attributes
        SELECT cmpname, exposure, typtype, type FROM seocompodf
          WHERE clsname = @iv_name AND version = 1 AND attdecltyp > 0
          ORDER BY exposure DESCENDING, cmpname
          INTO TABLE @DATA(lt_a).
        LOOP AT lt_a ASSIGNING FIELD-SYMBOL(<a>).
          APPEND VALUE #(
            name    = CONV string( <a>-cmpname )
            keyflag = SWITCH #( <a>-exposure WHEN 2 THEN `Pub` WHEN 1 THEN `Prot` ELSE `Priv` )
            typtype = SWITCH #( <a>-typtype WHEN 1 THEN `TYPE` WHEN 3 THEN `REF TO` ELSE `` )
            type    = CONV string( <a>-type )
          ) TO et_fields.
        ENDLOOP.

      WHEN 'TABL'.
        " Fields
        SELECT fieldname, keyflag, datatype, rollname, leng FROM dd03l
          WHERE tabname = @iv_name AND as4local = 'A' AND fieldname NOT LIKE '.%'
          ORDER BY position INTO TABLE @DATA(lt_fld).
        LOOP AT lt_fld ASSIGNING FIELD-SYMBOL(<fld>).
          APPEND VALUE #(
            name    = CONV string( <fld>-fieldname )
            keyflag = COND #( WHEN <fld>-keyflag = 'X' THEN `🔑` )
            typtype = CONV string( <fld>-datatype )
            type    = COND #( WHEN <fld>-rollname IS NOT INITIAL
                              THEN CONV string( <fld>-rollname )
                              ELSE |{ <fld>-datatype }({ <fld>-leng })| )
          ) TO et_fields.
        ENDLOOP.
        " Technical Settings + Indexes
        DATA(lt_tech) = get_table_tech_settings( iv_name ).
        APPEND LINES OF lt_tech TO et_fields.

      WHEN 'FUGR'.
        SELECT funcname FROM enlfdir WHERE area = @iv_name ORDER BY funcname
          INTO TABLE @DATA(lt_fms).
        LOOP AT lt_fms ASSIGNING FIELD-SYMBOL(<fm>).
          APPEND VALUE #( name = CONV string( <fm>-funcname ) typtype = `FUNC` type = `Function Module` ) TO et_fields.
        ENDLOOP.

      WHEN 'FUNC'.
        SELECT parameter, paramtype, structure, optional FROM fupararef
          WHERE funcname = @iv_name AND r3state = 'A'
          ORDER BY paramtype, pposition INTO TABLE @DATA(lt_par).
        LOOP AT lt_par ASSIGNING FIELD-SYMBOL(<p>).
          APPEND VALUE #(
            name    = CONV string( <p>-parameter )
            keyflag = SWITCH #( <p>-paramtype WHEN 'I' THEN `IMP` WHEN 'E' THEN `EXP` WHEN 'C' THEN `CHG` WHEN 'T' THEN `TBL` ELSE <p>-paramtype )
            typtype = COND #( WHEN <p>-optional = 'X' THEN `Optional` )
            type    = CONV string( <p>-structure )
          ) TO et_fields.
        ENDLOOP.

      WHEN 'DTEL'.
        SELECT SINGLE domname, routputlen, memoryid FROM dd04l
          WHERE rollname = @iv_name AND as4local = 'A' INTO @DATA(ls_d).
        IF sy-subrc = 0.
          APPEND VALUE #( name = `Domain` type = CONV string( ls_d-domname ) ) TO et_fields.
          APPEND VALUE #( name = `Output Len` type = CONV string( ls_d-routputlen ) ) TO et_fields.
          APPEND VALUE #( name = `Param ID` type = CONV string( ls_d-memoryid ) ) TO et_fields.
        ENDIF.
        SELECT SINGLE ddtext, reptext, scrtext_s, scrtext_m, scrtext_l FROM dd04t
          WHERE rollname = @iv_name AND ddlanguage = 'E' AND as4local = 'A' INTO @DATA(ls_dt).
        IF sy-subrc = 0.
          APPEND VALUE #( name = `Description` type = CONV string( ls_dt-ddtext ) ) TO et_fields.
          APPEND VALUE #( name = `Short` type = CONV string( ls_dt-scrtext_s ) ) TO et_fields.
          APPEND VALUE #( name = `Medium` type = CONV string( ls_dt-scrtext_m ) ) TO et_fields.
          APPEND VALUE #( name = `Long` type = CONV string( ls_dt-scrtext_l ) ) TO et_fields.
        ENDIF.

      WHEN 'DOMA'.
        SELECT SINGLE datatype, leng, decimals FROM dd01l
          WHERE domname = @iv_name AND as4local = 'A' INTO @DATA(ls_dom).
        IF sy-subrc = 0.
          APPEND VALUE #( name = `Data Type` type = CONV string( ls_dom-datatype ) ) TO et_fields.
          APPEND VALUE #( name = `Length` type = CONV string( ls_dom-leng ) ) TO et_fields.
          APPEND VALUE #( name = `Decimals` type = CONV string( ls_dom-decimals ) ) TO et_fields.
        ENDIF.
        SELECT domvalue_l, ddtext FROM dd07t
          WHERE domname = @iv_name AND ddlanguage = 'E' AND as4local = 'A'
          ORDER BY valpos INTO TABLE @DATA(lt_fv).
        LOOP AT lt_fv ASSIGNING FIELD-SYMBOL(<fv>).
          APPEND VALUE #( name = CONV string( <fv>-domvalue_l ) type = CONV string( <fv>-ddtext ) ) TO et_fields.
        ENDLOOP.

      WHEN 'MSAG'.
        SELECT msgnr, text FROM t100 WHERE sprsl = 'E' AND arbgb = @iv_name
          ORDER BY msgnr INTO TABLE @DATA(lt_msg).
        LOOP AT lt_msg ASSIGNING FIELD-SYMBOL(<msg>).
          APPEND VALUE #( name = CONV string( <msg>-msgnr ) type = CONV string( <msg>-text ) ) TO et_fields.
        ENDLOOP.

      WHEN 'VIEW'.
        " Database view fields
        SELECT viewfield, tabname, fieldname FROM dd27s
          WHERE viewname = @iv_name AND as4local = 'A'
          ORDER BY objpos
          INTO TABLE @DATA(lt_vf).
        LOOP AT lt_vf ASSIGNING FIELD-SYMBOL(<vf>).
          APPEND VALUE #(
            name    = CONV string( <vf>-viewfield )
            typtype = CONV string( <vf>-tabname )
            type    = CONV string( <vf>-fieldname )
          ) TO et_fields.
        ENDLOOP.

      WHEN 'SHLP'.
        SELECT fieldname, shlplispos FROM dd32s
          WHERE shlpname = @iv_name AND as4local = 'A'
          ORDER BY shlplispos INTO TABLE @DATA(lt_sh).
        LOOP AT lt_sh ASSIGNING FIELD-SYMBOL(<sh>).
          APPEND VALUE #(
            name = CONV string( <sh>-fieldname )
            keyflag = CONV string( <sh>-shlplispos )
            type = `Search Help Param`
          ) TO et_fields.
        ENDLOOP.

      WHEN 'ENQU'.
        " Lock object - show basic info
        APPEND VALUE #( name = `Lock Object` type = CONV string( iv_name ) ) TO et_fields.

      WHEN 'WAPA'.
        SELECT pagename, implclass FROM o2pagdir WHERE applname = @iv_name
          ORDER BY pagename INTO TABLE @DATA(lt_bpg).
        LOOP AT lt_bpg ASSIGNING FIELD-SYMBOL(<bpg>).
          APPEND VALUE #(
            name = CONV string( <bpg>-pagename )
            type = COND #( WHEN <bpg>-implclass IS NOT INITIAL THEN CONV string( <bpg>-implclass ) ELSE `BSP Page` )
          ) TO et_fields.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.


  METHOD get_properties.
    SELECT SINGLE author, devclass, created_on FROM tadir
      WHERE pgmid = 'R3TR' AND object = @iv_type AND obj_name = @iv_name
      INTO @DATA(ls).
    IF sy-subrc = 0.
      APPEND VALUE #( label = `Package` value = CONV string( ls-devclass ) ) TO result.
      APPEND VALUE #( label = `Author` value = CONV string( ls-author ) ) TO result.
      APPEND VALUE #( label = `Created` value = CONV string( ls-created_on ) ) TO result.
    ENDIF.
    " Last changed info from TRDIR
    IF iv_type = 'PROG' OR iv_type = 'CLAS' OR iv_type = 'FUGR'.
      DATA lv_pn TYPE syrepid.
      lv_pn = iv_name.
      SELECT SINGLE unam, udat FROM trdir WHERE name = @lv_pn INTO @DATA(ls_ch).
      IF sy-subrc = 0 AND ls_ch-unam IS NOT INITIAL.
        APPEND VALUE #( label = `Changed by` value = CONV string( ls_ch-unam ) ) TO result.
        APPEND VALUE #( label = `Changed on` value = CONV string( ls_ch-udat ) ) TO result.
      ENDIF.
    ENDIF.
    " Description
    DATA(lv_desc) = get_object_description( iv_type = iv_type iv_name = iv_name ).
    IF lv_desc IS NOT INITIAL.
      INSERT VALUE #( label = `Description` value = lv_desc ) INTO result INDEX 1.
    ENDIF.
    " Transport
    SELECT SINGLE trkorr FROM e071
      WHERE pgmid = 'R3TR' AND object = @iv_type AND obj_name = @iv_name
      INTO @DATA(lv_tr).
    IF sy-subrc = 0 AND lv_tr IS NOT INITIAL.
      APPEND VALUE #( label = `Transport` value = CONV string( lv_tr ) ) TO result.
    ENDIF.
    " Class/Interface specific
    IF iv_type = 'CLAS' OR iv_type = 'INTF'.
      " Superclass
      IF iv_type = 'CLAS'.
        SELECT SINGLE refclsname FROM seometarel
          WHERE clsname = @iv_name AND version = 1 AND state = 1 INTO @DATA(lv_sup).
        IF sy-subrc = 0 AND lv_sup IS NOT INITIAL.
          APPEND VALUE #( label = `Superclass` value = CONV string( lv_sup ) ) TO result.
        ENDIF.
        " Check abstract/final
        SELECT SINGLE clsabstrct, clsfinal FROM vseoclass
          WHERE clsname = @iv_name INTO @DATA(ls_cf).
        IF sy-subrc = 0.
          IF ls_cf-clsabstrct = 'X'.
            APPEND VALUE #( label = `Abstract` value = `Yes` ) TO result.
          ENDIF.
          IF ls_cf-clsfinal = 'X'.
            APPEND VALUE #( label = `Final` value = `Yes` ) TO result.
          ENDIF.
        ENDIF.
      ENDIF.
      " Interfaces
      SELECT refclsname FROM vseoimplem
        WHERE clsname = @iv_name AND version = 1 INTO TABLE @DATA(lt_if).
      IF lt_if IS NOT INITIAL.
        DATA(lv_ifs) = ``.
        LOOP AT lt_if ASSIGNING FIELD-SYMBOL(<if>).
          lv_ifs = COND #( WHEN lv_ifs IS INITIAL THEN <if>-refclsname ELSE |{ lv_ifs }, { <if>-refclsname }| ).
        ENDLOOP.
        APPEND VALUE #( label = `Interfaces` value = lv_ifs ) TO result.
      ENDIF.
      " Subclasses / Implementations count
      IF iv_type = 'CLAS'.
        DATA(lt_subs) = get_subclasses( iv_name ).
        IF lt_subs IS NOT INITIAL.
          APPEND VALUE #( label = `Subclasses` value = CONV string( lines( lt_subs ) ) ) TO result.
        ENDIF.
      ELSEIF iv_type = 'INTF'.
        DATA(lt_impls) = get_implementations( iv_name ).
        IF lt_impls IS NOT INITIAL.
          APPEND VALUE #( label = `Implementations` value = CONV string( lines( lt_impls ) ) ) TO result.
        ENDIF.
      ENDIF.
    ENDIF.
    " Line count
    IF iv_source IS SUPPLIED AND iv_source IS NOT INITIAL.
      APPEND VALUE #( label = `Lines` value = CONV string( count_lines( iv_source ) ) ) TO result.
    ENDIF.
  ENDMETHOD.


  METHOD get_where_used.
    DATA(lv_like) = |%{ iv_name }%|.
    SELECT otype, include FROM wbcrossgt
      WHERE name LIKE @lv_like
      ORDER BY otype, include INTO TABLE @DATA(lt_r) UP TO 100 ROWS.
    LOOP AT lt_r ASSIGNING FIELD-SYMBOL(<r>).
      APPEND VALUE #( object = CONV string( <r>-otype ) obj_name = CONV string( <r>-include ) ) TO result.
    ENDLOOP.
    SORT result BY obj_name.
    DELETE ADJACENT DUPLICATES FROM result COMPARING obj_name.
  ENDMETHOD.


  METHOD get_object_icon.
    result = SWITCH #( iv_type
      WHEN 'CLAS' THEN `sap-icon://course-book`
      WHEN 'INTF' THEN `sap-icon://interface`
      WHEN 'PROG' THEN `sap-icon://document-text`
      WHEN 'FUGR' THEN `sap-icon://group`
      WHEN 'FUNC' THEN `sap-icon://wrench`
      WHEN 'TABL' THEN `sap-icon://grid`
      WHEN 'DTEL' THEN `sap-icon://detail-view`
      WHEN 'DOMA' THEN `sap-icon://value-help`
      WHEN 'DDLS' THEN `sap-icon://database`
      WHEN 'SRVD' THEN `sap-icon://connected`
      WHEN 'SRVB' THEN `sap-icon://world`
      WHEN 'DEVC' THEN `sap-icon://folder-blank`
      WHEN 'MSAG' THEN `sap-icon://message-popup`
      WHEN 'TTYP' THEN `sap-icon://table-view`
      WHEN 'WAPA' THEN `sap-icon://globe`
      WHEN 'ENHO' THEN `sap-icon://add-activity`
      WHEN 'BDEF' THEN `sap-icon://action-settings`
      WHEN 'DDLX' THEN `sap-icon://customize`
      ELSE `sap-icon://document` ).
  ENDMETHOD.


  METHOD get_program_attributes.
    SELECT SINGLE subc, rstat, appl, fixpt FROM trdir
      WHERE name = @iv_name
      INTO @DATA(ls_tr).
    IF sy-subrc = 0.
      APPEND VALUE #( name = `Program Type` type = SWITCH #( ls_tr-subc
        WHEN '1' THEN `Executable`
        WHEN 'I' THEN `Include`
        WHEN 'M' THEN `Module Pool`
        WHEN 'S' THEN `Subroutine Pool`
        WHEN 'F' THEN `Function Group`
        WHEN 'K' THEN `Class Pool`
        ELSE CONV string( ls_tr-subc ) ) ) TO result.
      APPEND VALUE #( name = `Status` type = SWITCH #( ls_tr-rstat
        WHEN 'K' THEN `Customer Prod`
        WHEN 'T' THEN `Test`
        WHEN 'P' THEN `SAP Production`
        ELSE CONV string( ls_tr-rstat ) ) ) TO result.
      APPEND VALUE #( name = `Application` type = CONV string( ls_tr-appl ) ) TO result.
      APPEND VALUE #( name = `Fixed Point` type = COND #(
        WHEN ls_tr-fixpt = 'X' THEN `Yes` ELSE `No` ) ) TO result.
    ENDIF.
  ENDMETHOD.


  METHOD get_object_dependencies.
    " Find what this object USES (forward dependencies)
    DATA(lv_like) = |%{ iv_name }%|.
    SELECT DISTINCT name, otype FROM wbcrossgt
      WHERE include LIKE @lv_like
      ORDER BY otype, name
      INTO TABLE @DATA(lt_deps)
      UP TO 100 ROWS.
    LOOP AT lt_deps ASSIGNING FIELD-SYMBOL(<dep>).
      APPEND VALUE #(
        object   = CONV string( <dep>-otype )
        obj_name = CONV string( <dep>-name )
      ) TO result.
    ENDLOOP.
    SORT result BY obj_name.
    DELETE ADJACENT DUPLICATES FROM result COMPARING obj_name.
  ENDMETHOD.


  METHOD search_replace_source.
    ev_source = iv_source.
    ev_count = 0.
    IF iv_search IS INITIAL.
      RETURN.
    ENDIF.
    REPLACE ALL OCCURRENCES OF iv_search IN ev_source WITH iv_replace REPLACEMENT COUNT ev_count.
  ENDMETHOD.


  METHOD compare_versions.
    " Compare active vs inactive version (for classes)
    DATA lt_active TYPE STANDARD TABLE OF string.
    DATA lt_inactive TYPE STANDARD TABLE OF string.
    DATA lt_diff TYPE STANDARD TABLE OF string.

    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        TRY.
            DATA(lo_s) = cl_oo_clif_source_settings=>create_instance( ).
            DATA(lo_act) = cl_oo_clif_source=>create_instance(
              clif_name = iv_name version = 'A' settings = lo_s ).
            lo_act->if_oo_clif_source~get_source( IMPORTING source = lt_active ).
            DATA(lo_inact) = cl_oo_clif_source=>create_instance(
              clif_name = iv_name version = 'I' settings = lo_s ).
            lo_inact->if_oo_clif_source~get_source( IMPORTING source = lt_inactive ).
          CATCH cx_root INTO DATA(lx).
            result = |Error: { lx->get_text( ) }|.
            RETURN.
        ENDTRY.
      WHEN 'PROG'.
        READ REPORT iv_name INTO lt_active STATE 'A'.
        READ REPORT iv_name INTO lt_inactive STATE 'I'.
      WHEN OTHERS.
        result = `Comparison not supported for this type.`.
        RETURN.
    ENDCASE.

    IF lt_inactive IS INITIAL.
      result = `No inactive version exists.`.
      RETURN.
    ENDIF.

    " Simple line-by-line diff
    DATA(lv_max) = nmax( val1 = lines( lt_active ) val2 = lines( lt_inactive ) ).
    DATA lv_diffs TYPE i.
    APPEND |* === VERSION COMPARISON: { iv_name } ===| TO lt_diff.
    APPEND |* Active: { lines( lt_active ) } lines, Inactive: { lines( lt_inactive ) } lines| TO lt_diff.
    APPEND `` TO lt_diff.
    DO lv_max TIMES.
      DATA(lv_i) = sy-index.
      DATA(lv_act_line) = VALUE string( ).
      DATA(lv_inact_line) = VALUE string( ).
      IF lv_i <= lines( lt_active ).
        lv_act_line = lt_active[ lv_i ].
      ENDIF.
      IF lv_i <= lines( lt_inactive ).
        lv_inact_line = lt_inactive[ lv_i ].
      ENDIF.
      IF lv_act_line <> lv_inact_line.
        lv_diffs = lv_diffs + 1.
        APPEND |* Line { lv_i } CHANGED:| TO lt_diff.
        IF lv_act_line IS NOT INITIAL.
          APPEND |- { lv_act_line }| TO lt_diff.
        ENDIF.
        IF lv_inact_line IS NOT INITIAL.
          APPEND |+ { lv_inact_line }| TO lt_diff.
        ENDIF.
      ENDIF.
      IF lv_diffs > 50.
        APPEND |* ... (more than 50 differences, truncated)| TO lt_diff.
        EXIT.
      ENDIF.
    ENDDO.
    APPEND `` TO lt_diff.
    APPEND |* Total differences: { lv_diffs } line(s)| TO lt_diff.

    result = concat_lines_of( table = lt_diff sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD get_method_signature.
    " Get method parameters from SEOSUBCODF
    SELECT sconame, pardecltyp, parpasstyp, type FROM seosubcodf
      WHERE clsname = @iv_classname
      AND cmpname = @iv_methodname
      AND version = 1
      ORDER BY pardecltyp, sconame
      INTO TABLE @DATA(lt_par).
    LOOP AT lt_par ASSIGNING FIELD-SYMBOL(<p>).
      APPEND VALUE #(
        name    = CONV string( <p>-sconame )
        keyflag = SWITCH #( <p>-pardecltyp
          WHEN 0 THEN `IMP` WHEN 1 THEN `EXP` WHEN 2 THEN `CHG` WHEN 3 THEN `RET` ELSE `?` )
        typtype = SWITCH #( <p>-parpasstyp
          WHEN 0 THEN `BY REF` WHEN 1 THEN `BY VAL` ELSE `` )
        type    = CONV string( <p>-type )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_events.
    " Get events defined in a class
    SELECT cmpname, exposure FROM seocompodf
      WHERE clsname = @iv_name AND version = 1
      AND evtdecltyp > 0
      ORDER BY cmpname
      INTO TABLE @DATA(lt_evt).
    LOOP AT lt_evt ASSIGNING FIELD-SYMBOL(<e>).
      APPEND VALUE #(
        name = CONV string( <e>-cmpname )
        keyflag = SWITCH #( <e>-exposure WHEN 2 THEN `Pub` WHEN 1 THEN `Prot` ELSE `Priv` )
        type = `Event`
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_source_statistics.
    IF iv_source IS INITIAL.
      RETURN.
    ENDIF.
    DATA(lv_total) = count_lines( iv_source ).
    DATA lv_comments TYPE i.
    DATA lv_blanks TYPE i.
    DATA lt_lines TYPE STANDARD TABLE OF string.
    SPLIT iv_source AT cl_abap_char_utilities=>newline INTO TABLE lt_lines.
    LOOP AT lt_lines ASSIGNING FIELD-SYMBOL(<line>).
      DATA(lv_trimmed) = condense( <line> ).
      IF lv_trimmed IS INITIAL.
        lv_blanks = lv_blanks + 1.
      ELSEIF lv_trimmed(1) = '*' OR lv_trimmed CP '"*'.
        lv_comments = lv_comments + 1.
      ENDIF.
    ENDLOOP.
    DATA(lv_code) = lv_total - lv_comments - lv_blanks.
    APPEND VALUE #( name = `Total Lines` type = CONV string( lv_total ) ) TO result.
    APPEND VALUE #( name = `Code Lines` type = CONV string( lv_code ) ) TO result.
    APPEND VALUE #( name = `Comments` type = CONV string( lv_comments ) ) TO result.
    APPEND VALUE #( name = `Blank Lines` type = CONV string( lv_blanks ) ) TO result.
  ENDMETHOD.


  METHOD get_variants.
    SELECT varid~variant, varit~vtext FROM varid
      INNER JOIN varit ON varit~report = varid~report
        AND varit~variant = varid~variant AND varit~langu = 'E'
      WHERE varid~report = @iv_name
      ORDER BY varid~variant
      INTO TABLE @DATA(lt_var).
    LOOP AT lt_var ASSIGNING FIELD-SYMBOL(<v>).
      APPEND VALUE #(
        name = CONV string( <v>-variant )
        type = CONV string( <v>-vtext )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_table_content.
    " Preview first N rows of a table
    DATA lt_lines TYPE STANDARD TABLE OF string.
    TRY.
        DATA(lv_sql) = |SELECT * FROM { iv_name } UP TO { iv_maxrows } ROWS|.
        " Use dynamic SELECT
        DATA lt_result TYPE REF TO data.
        CREATE DATA lt_result TYPE STANDARD TABLE OF (iv_name).
        FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
        ASSIGN lt_result->* TO <tab>.
        SELECT * FROM (iv_name) INTO TABLE @<tab> UP TO @iv_maxrows ROWS.
        IF sy-subrc = 0.
          APPEND |* Table: { iv_name } - { lines( <tab> ) } rows (max { iv_maxrows })| TO lt_lines.
          APPEND |* { repeat( val = '-' occ = 70 ) }| TO lt_lines.
          " Get field names for header
          DATA(lo_struct) = CAST cl_abap_structdescr(
            CAST cl_abap_tabledescr( cl_abap_typedescr=>describe_by_data( <tab> ) )->get_table_line_type( ) ).
          DATA(lt_comp) = lo_struct->get_components( ).
          DATA lv_header TYPE string.
          LOOP AT lt_comp ASSIGNING FIELD-SYMBOL(<comp>).
            IF lv_header IS NOT INITIAL.
              lv_header = lv_header && ` | `.
            ENDIF.
            lv_header = lv_header && <comp>-name.
          ENDLOOP.
          APPEND lv_header TO lt_lines.
          APPEND |{ repeat( val = '-' occ = strlen( lv_header ) ) }| TO lt_lines.
          " Data rows
          LOOP AT <tab> ASSIGNING FIELD-SYMBOL(<row>).
            DATA lv_row TYPE string.
            CLEAR lv_row.
            DO lines( lt_comp ) TIMES.
              ASSIGN COMPONENT sy-index OF STRUCTURE <row> TO FIELD-SYMBOL(<val>).
              IF lv_row IS NOT INITIAL.
                lv_row = lv_row && ` | `.
              ENDIF.
              lv_row = lv_row && CONV string( <val> ).
            ENDDO.
            APPEND lv_row TO lt_lines.
          ENDLOOP.
        ELSE.
          APPEND |* No data in { iv_name }| TO lt_lines.
        ENDIF.
      CATCH cx_root INTO DATA(lx).
        APPEND |* Error: { lx->get_text( ) }| TO lt_lines.
    ENDTRY.
    result = concat_lines_of( table = lt_lines sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD get_class_types.
    " Get types defined in a class
    SELECT cmpname, exposure, type FROM seocompodf
      WHERE clsname = @iv_name AND version = 1
      AND typtype > 0 AND attdecltyp = 0 AND mtddecltyp = 0 AND evtdecltyp = 0
      ORDER BY cmpname
      INTO TABLE @DATA(lt_typ).
    LOOP AT lt_typ ASSIGNING FIELD-SYMBOL(<t>).
      APPEND VALUE #(
        name    = CONV string( <t>-cmpname )
        keyflag = SWITCH #( <t>-exposure WHEN 2 THEN `Pub` WHEN 1 THEN `Prot` ELSE `Priv` )
        type    = CONV string( <t>-type )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD rename_object.
    CASE iv_type.
      WHEN 'PROG'.
        " Copy source to new name, delete old
        DATA lt_source TYPE STANDARD TABLE OF string.
        READ REPORT iv_old_name INTO lt_source.
        IF sy-subrc = 0.
          INSERT REPORT iv_new_name FROM lt_source.
          IF sy-subrc = 0.
            " Register new
            SELECT SINGLE devclass FROM tadir
              WHERE pgmid = 'R3TR' AND object = 'PROG'
              AND obj_name = @iv_old_name INTO @DATA(lv_pkg).
            IF lv_pkg IS NOT INITIAL.
              CALL FUNCTION 'TR_TADIR_INTERFACE'
                EXPORTING
                  wi_tadir_pgmid    = 'R3TR'
                  wi_tadir_object   = 'PROG'
                  wi_tadir_obj_name = iv_new_name
                  wi_tadir_devclass = lv_pkg
                  wi_test_modus     = space
                EXCEPTIONS OTHERS = 0.
            ENDIF.
            " Delete old
            CALL FUNCTION 'RS_DELETE_PROGRAM'
              EXPORTING
                program   = iv_old_name
                suppress_popup = abap_true
              EXCEPTIONS OTHERS = 0.
            COMMIT WORK.
            result-success = abap_true.
            result-message = |Renamed { iv_old_name } to { iv_new_name }.|.
          ELSE.
            result-message = `Could not create new program.`.
          ENDIF.
        ELSE.
          result-message = |Source { iv_old_name } not found.|.
        ENDIF.
      WHEN OTHERS.
        result-message = |Rename not supported for { iv_type }.|.
    ENDCASE.
  ENDMETHOD.


  METHOD get_package_info.
    SELECT SINGLE d~devclass, d~parentcl, d~dlvunit, d~component, t~ctext
      FROM tdevc AS d
      LEFT JOIN tdevct AS t ON t~devclass = d~devclass AND t~spras = 'E'
      WHERE d~devclass = @iv_package
      INTO @DATA(ls_pkg).
    IF sy-subrc = 0.
      APPEND VALUE #( label = `Package` value = CONV string( ls_pkg-devclass ) ) TO result.
      IF ls_pkg-ctext IS NOT INITIAL.
        APPEND VALUE #( label = `Description` value = CONV string( ls_pkg-ctext ) ) TO result.
      ENDIF.
      IF ls_pkg-parentcl IS NOT INITIAL.
        APPEND VALUE #( label = `Parent Package` value = CONV string( ls_pkg-parentcl ) ) TO result.
      ENDIF.
      IF ls_pkg-dlvunit IS NOT INITIAL.
        APPEND VALUE #( label = `Software Component` value = CONV string( ls_pkg-dlvunit ) ) TO result.
      ENDIF.
      IF ls_pkg-component IS NOT INITIAL.
        APPEND VALUE #( label = `Application Component` value = CONV string( ls_pkg-component ) ) TO result.
      ENDIF.
    ENDIF.
    " Count objects
    SELECT COUNT(*) FROM tadir
      WHERE devclass = @iv_package AND pgmid = 'R3TR'
      INTO @DATA(lv_cnt).
    APPEND VALUE #( label = `Object Count` value = CONV string( lv_cnt ) ) TO result.
    " Count sub-packages
    SELECT COUNT(*) FROM tdevc
      WHERE parentcl = @iv_package
      INTO @DATA(lv_sub).
    APPEND VALUE #( label = `Sub-Packages` value = CONV string( lv_sub ) ) TO result.
  ENDMETHOD.


  METHOD get_table_append_structures.
    " Find append structures for a table
    SELECT tabname FROM dd03l
      WHERE fieldname = '.APPEND' AND precfield = @iv_name AND as4local = 'A'
      INTO TABLE @DATA(lt_app).
    LOOP AT lt_app ASSIGNING FIELD-SYMBOL(<app>).
      APPEND VALUE #(
        name = CONV string( <app>-tabname )
        keyflag = `APP`
        type = `Append Structure`
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_lock_info.
    " Check if object is locked by someone
    DATA lv_user TYPE syuname.
    CASE iv_type.
      WHEN 'PROG'.
        CALL FUNCTION 'ENQUEUE_READ'
          EXPORTING
            gclient = sy-mandt
            gname   = 'TRDIR'
            garg    = CONV eqegraarg( iv_name )
          IMPORTING
            guname  = lv_user
          EXCEPTIONS
            OTHERS  = 1.
      WHEN 'CLAS' OR 'INTF'.
        CALL FUNCTION 'ENQUEUE_READ'
          EXPORTING
            gclient = sy-mandt
            gname   = 'SEOCLASS'
            garg    = CONV eqegraarg( iv_name )
          IMPORTING
            guname  = lv_user
          EXCEPTIONS
            OTHERS  = 1.
      WHEN OTHERS.
        CLEAR lv_user.
    ENDCASE.
    IF lv_user IS NOT INITIAL.
      result = |Locked by { lv_user }|.
    ENDIF.
  ENDMETHOD.


  METHOD get_package_path.
    " Build full package hierarchy path
    DATA lv_pkg TYPE devclass.
    DATA lt_path TYPE STANDARD TABLE OF devclass.
    lv_pkg = iv_package.
    DO 10 TIMES.
      INSERT lv_pkg INTO lt_path INDEX 1.
      SELECT SINGLE parentcl FROM tdevc
        WHERE devclass = @lv_pkg INTO @DATA(lv_parent).
      IF sy-subrc <> 0 OR lv_parent IS INITIAL.
        EXIT.
      ENDIF.
      lv_pkg = lv_parent.
    ENDDO.
    LOOP AT lt_path ASSIGNING FIELD-SYMBOL(<p>).
      IF result IS NOT INITIAL.
        result = result && ` > `.
      ENDIF.
      result = result && <p>.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_friends.
    " Friends - simplified (table structure varies by release)
    CLEAR result.
  ENDMETHOD.


  METHOD get_redefined_methods.
    SELECT cmpname FROM seocompodf
      WHERE clsname = @iv_name AND version = 1
      AND redefin = 'X'
      ORDER BY cmpname
      INTO TABLE @DATA(lt_red).
    LOOP AT lt_red ASSIGNING FIELD-SYMBOL(<rd>).
      APPEND VALUE #(
        name = CONV string( <rd>-cmpname )
        keyflag = `RED`
        type = `Redefined`
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_fm_exceptions.
    " Function module exceptions
    SELECT parameter FROM fupararef
      WHERE funcname = @iv_name AND r3state = 'A' AND paramtype = 'X'
      ORDER BY pposition
      INTO TABLE @DATA(lt_exc).
    LOOP AT lt_exc ASSIGNING FIELD-SYMBOL(<x>).
      APPEND VALUE #(
        name = CONV string( <x>-parameter )
        keyflag = `EXC`
        type = `Exception`
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_class_constants.
    " Get constants defined in a class
    SELECT cmpname, exposure, attvalue, type FROM seocompodf
      WHERE clsname = @iv_name AND version = 1
      AND attdecltyp = 2
      ORDER BY cmpname
      INTO TABLE @DATA(lt_con).
    LOOP AT lt_con ASSIGNING FIELD-SYMBOL(<con>).
      APPEND VALUE #(
        name    = CONV string( <con>-cmpname )
        keyflag = SWITCH #( <con>-exposure WHEN 2 THEN `Pub` WHEN 1 THEN `Prot` ELSE `Priv` )
        typtype = CONV string( <con>-type )
        type    = CONV string( <con>-attvalue )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_table_foreign_keys.
    " Foreign keys for a table
    SELECT fieldname, checktable FROM dd03l
      WHERE tabname = @iv_name AND as4local = 'A'
      AND checktable IS NOT INITIAL AND checktable <> '*'
      AND fieldname NOT LIKE '.%'
      ORDER BY position
      INTO TABLE @DATA(lt_fk).
    LOOP AT lt_fk ASSIGNING FIELD-SYMBOL(<fk>).
      APPEND VALUE #(
        name    = CONV string( <fk>-fieldname )
        keyflag = `FK`
        type    = CONV string( <fk>-checktable )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_interface.
    TRY.
        DATA ls_intf TYPE vseointerf.
        ls_intf-clsname = iv_name.
        ls_intf-langu = sy-langu.
        ls_intf-descript = |Interface { iv_name }|.
        ls_intf-state = 1.
        ls_intf-exposure = 2.
        CALL FUNCTION 'SEO_INTERFACE_CREATE_COMPLETE'
          EXPORTING
            devclass  = iv_package
            overwrite = space
          CHANGING
            interface = ls_intf
          EXCEPTIONS
            existing  = 1
            db_error  = 2
            OTHERS    = 3.
        IF sy-subrc = 0.
          COMMIT WORK.
          result-success = abap_true.
          result-message = |Interface { iv_name } created.|.
        ELSE.
          result-message = |Interface creation failed (rc={ sy-subrc }).|.
        ENDIF.
      CATCH cx_root INTO DATA(lx).
        result-message = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD get_subclasses.
    " Find all direct subclasses
    SELECT clsname FROM seometarel
      WHERE refclsname = @iv_name AND version = 1
      ORDER BY clsname
      INTO TABLE @DATA(lt_sub).
    LOOP AT lt_sub ASSIGNING FIELD-SYMBOL(<s>).
      APPEND VALUE #(
        object = `CLAS`
        obj_name = CONV string( <s>-clsname )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD get_implementations.
    " Find all classes implementing this interface
    SELECT clsname FROM vseoimplem
      WHERE refclsname = @iv_name AND version = 1
      ORDER BY clsname
      INTO TABLE @DATA(lt_impl).
    LOOP AT lt_impl ASSIGNING FIELD-SYMBOL(<i>).
      APPEND VALUE #(
        object = `CLAS`
        obj_name = CONV string( <i>-clsname )
      ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_class.
    TRY.
        DATA(ls_class) = VALUE vseoclass(
          clsname  = iv_name
          langu    = sy-langu
          descript = |Class { iv_name }|
          state    = 1
          clsccincl = 'X'
          fixpt    = 'X'
          unicode  = 'X'
          exposure = 2 ).
        IF iv_superclass IS NOT INITIAL.
          CALL FUNCTION 'SEO_CLASS_CREATE_COMPLETE'
            EXPORTING
              devclass    = iv_package
              overwrite   = space
            CHANGING
              class       = ls_class
            EXCEPTIONS
              existing    = 1
              is_interface = 2
              db_error    = 3
              OTHERS      = 4.
        ELSE.
          CALL FUNCTION 'SEO_CLASS_CREATE_COMPLETE'
            EXPORTING
              devclass    = iv_package
              overwrite   = space
            CHANGING
              class       = ls_class
            EXCEPTIONS
              existing    = 1
              is_interface = 2
              db_error    = 3
              OTHERS      = 4.
        ENDIF.
        IF sy-subrc = 0.
          COMMIT WORK.
          result-success = abap_true.
          result-message = |Class { iv_name } created.|.
        ELSE.
          result-message = |Class creation failed (rc={ sy-subrc }).|.
        ENDIF.
      CATCH cx_root INTO DATA(lx).
        result-message = lx->get_text( ).
    ENDTRY.
  ENDMETHOD.


  METHOD copy_object.
    CASE iv_source_type.
      WHEN 'PROG'.
        DATA lt_source TYPE STANDARD TABLE OF string.
        READ REPORT iv_source_name INTO lt_source.
        IF sy-subrc = 0.
          INSERT REPORT iv_target_name FROM lt_source.
          IF sy-subrc = 0.
            CALL FUNCTION 'TR_TADIR_INTERFACE'
              EXPORTING
                wi_tadir_pgmid    = 'R3TR'
                wi_tadir_object   = 'PROG'
                wi_tadir_obj_name = iv_target_name
                wi_tadir_devclass = iv_package
                wi_test_modus     = space
              EXCEPTIONS
                OTHERS            = 1.
            COMMIT WORK.
            result-success = abap_true.
            result-message = |Copied to { iv_target_name }.|.
          ELSE.
            result-message = `Copy failed.`.
          ENDIF.
        ELSE.
          result-message = |Source { iv_source_name } not readable.|.
        ENDIF.
      WHEN OTHERS.
        result-message = |Copy not supported for { iv_source_type }.|.
    ENDCASE.
  ENDMETHOD.


  METHOD get_table_tech_settings.
    " Read DD09L for technical settings
    SELECT SINGLE tabkat, tabart, bufallow, schfeldanz FROM dd09l
      WHERE tabname = @iv_name AND as4local = 'A'
      INTO @DATA(ls_tech).
    IF sy-subrc = 0.
      APPEND VALUE #( name = `Size Category` type = CONV string( ls_tech-tabkat ) ) TO result.
      APPEND VALUE #( name = `Storage Type` type = CONV string( ls_tech-tabart ) ) TO result.
      APPEND VALUE #( name = `Buffering` type = SWITCH #( ls_tech-bufallow
        WHEN 'X' THEN `Buffering allowed`
        WHEN 'N' THEN `Not buffered`
        ELSE CONV string( ls_tech-bufallow ) ) ) TO result.
      APPEND VALUE #( name = `Key Fields for Buffer` type = CONV string( ls_tech-schfeldanz ) ) TO result.
    ENDIF.
    " Indexes
    SELECT indexname FROM dd12l
      WHERE sqltab = @iv_name AND as4local = 'A'
      ORDER BY indexname INTO TABLE @DATA(lt_idx).
    LOOP AT lt_idx ASSIGNING FIELD-SYMBOL(<idx>).
      APPEND VALUE #( name = |Index: { <idx>-indexname }| keyflag = `IDX` type = `Secondary Index` ) TO result.
    ENDLOOP.
  ENDMETHOD.


  METHOD create_program.
    DATA lt_source TYPE STANDARD TABLE OF string.
    APPEND |REPORT { iv_name }.| TO lt_source.

    INSERT REPORT iv_name FROM lt_source.
    IF sy-subrc = 0.
      " Register in TADIR
      CALL FUNCTION 'TR_TADIR_INTERFACE'
        EXPORTING
          wi_tadir_pgmid    = 'R3TR'
          wi_tadir_object   = 'PROG'
          wi_tadir_obj_name = iv_name
          wi_tadir_devclass = iv_package
          wi_test_modus     = space
        EXCEPTIONS
          OTHERS            = 1.
      IF sy-subrc = 0.
        COMMIT WORK.
        result-success = abap_true.
        result-message = |Program { iv_name } created.|.
      ELSE.
        result-message = |Created but TADIR registration failed.|.
        result-success = abap_true.
      ENDIF.
    ELSE.
      result-message = |Creation failed (rc={ sy-subrc }).|.
    ENDIF.
  ENDMETHOD.


  METHOD get_object_status.
    " Simple status check
    result = `Active`.
    SELECT SINGLE obj_name FROM tadir
      WHERE pgmid = 'R3TR' AND object = @iv_type
      AND obj_name = @iv_name
      INTO @DATA(lv_found).
    IF sy-subrc <> 0.
      result = `Unknown`.
      RETURN.
    ENDIF.
    " Show transport if locked
    SELECT SINGLE trkorr FROM e071
      WHERE pgmid = 'R3TR' AND object = @iv_type
      AND obj_name = @iv_name
      INTO @DATA(lv_tr).
    IF sy-subrc = 0 AND lv_tr IS NOT INITIAL.
      result = |Active ({ lv_tr })|.
    ENDIF.
  ENDMETHOD.


  METHOD delete_object.
    CASE iv_type.
      WHEN 'PROG'.
        CALL FUNCTION 'RS_DELETE_PROGRAM'
          EXPORTING
            program            = iv_name
            suppress_popup     = abap_true
            skip_no_release_check = abap_true
          EXCEPTIONS
            enqueue_lock       = 1
            object_not_found   = 2
            permission_failure = 3
            reject_deletion    = 4
            OTHERS             = 5.
        IF sy-subrc = 0.
          result-success = abap_true.
          result-message = |{ iv_name } deleted.|.
        ELSE.
          result-message = |Delete failed (rc={ sy-subrc }).|.
        ENDIF.

      WHEN 'CLAS' OR 'INTF'.
        TRY.
            CALL FUNCTION 'SEO_CLASS_DELETE_COMPLETE'
              EXPORTING
                clskey = VALUE seoclskey( clsname = iv_name )
              EXCEPTIONS
                not_existing     = 1
                is_interface     = 2
                not_deleted      = 3
                db_error         = 4
                OTHERS           = 5.
            IF sy-subrc = 0.
              COMMIT WORK.
              result-success = abap_true.
              result-message = |{ iv_name } deleted.|.
            ELSE.
              result-message = |Delete failed (rc={ sy-subrc }).|.
            ENDIF.
          CATCH cx_root INTO DATA(lx).
            result-message = lx->get_text( ).
        ENDTRY.

      WHEN OTHERS.
        result-message = |Delete not supported for { iv_type }.|.
    ENDCASE.
  ENDMETHOD.


  METHOD lock_in_transport.
    DATA ls_e071 TYPE e071.
    DATA lt_e071 TYPE STANDARD TABLE OF e071.
    ls_e071-pgmid = 'R3TR'.
    ls_e071-object = iv_type.
    ls_e071-obj_name = iv_name.
    APPEND ls_e071 TO lt_e071.

    CALL FUNCTION 'TRINT_INSERT_NEW_COMM'
      EXPORTING
        wi_kuession = iv_transport
        wi_trtype   = 'K'
      TABLES
        wt_e071     = lt_e071
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc = 0.
      COMMIT WORK.
      result-success = abap_true.
      result-message = |{ iv_name } added to { iv_transport }.|.
    ELSE.
      result-message = |Transport assignment failed.|.
    ENDIF.
  ENDMETHOD.


  METHOD get_documentation.
    DATA lt_lines TYPE STANDARD TABLE OF string.
    DATA lt_doc TYPE STANDARD TABLE OF tline.

    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        CALL FUNCTION 'DOCU_GET'
          EXPORTING
            id     = 'CL'
            langu  = 'E'
            object = CONV doku_obj( iv_name )
          TABLES
            line   = lt_doc
          EXCEPTIONS
            OTHERS = 1.
      WHEN 'PROG'.
        CALL FUNCTION 'DOCU_GET'
          EXPORTING
            id     = 'RE'
            langu  = 'E'
            object = CONV doku_obj( iv_name )
          TABLES
            line   = lt_doc
          EXCEPTIONS
            OTHERS = 1.
      WHEN OTHERS.
        APPEND `* Documentation not available for this type.` TO lt_lines.
    ENDCASE.

    IF lt_doc IS NOT INITIAL.
      LOOP AT lt_doc ASSIGNING FIELD-SYMBOL(<d>).
        APPEND CONV string( <d>-tdline ) TO lt_lines.
      ENDLOOP.
    ENDIF.
    IF lt_lines IS INITIAL.
      APPEND `* No documentation found.` TO lt_lines.
    ENDIF.
    result = concat_lines_of( table = lt_lines sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD get_includes.
    CASE iv_type.
      WHEN 'FUGR'.
        " List function modules as includes
        SELECT funcname FROM enlfdir
          WHERE area = @iv_name ORDER BY funcname
          INTO TABLE @DATA(lt_fms).
        LOOP AT lt_fms ASSIGNING FIELD-SYMBOL(<fm>).
          APPEND VALUE #(
            name = CONV string( <fm>-funcname )
            keyflag = `FM`
            type = `Function Module`
          ) TO result.
        ENDLOOP.
      WHEN 'PROG'.
        " List includes of program
        DATA(lv_like_inc) = CONV sobj_name( |{ iv_name }%| ).
        SELECT obj_name FROM tadir
          WHERE pgmid = 'LIMU' AND object = 'REPS'
          AND obj_name LIKE @lv_like_inc
          ORDER BY obj_name
          INTO TABLE @DATA(lt_incs)
          UP TO 50 ROWS.
        LOOP AT lt_incs ASSIGNING FIELD-SYMBOL(<inc>).
          APPEND VALUE #(
            name = CONV string( <inc>-obj_name )
            keyflag = `INC`
            type = `Include`
          ) TO result.
        ENDLOOP.
    ENDCASE.
  ENDMETHOD.


  METHOD get_text_elements.
    DATA lt_lines TYPE STANDARD TABLE OF string.
    CASE iv_type.
      WHEN 'PROG' OR 'CLAS' OR 'FUGR'.
        DATA lt_textpool TYPE STANDARD TABLE OF textpool.
        DATA lv_prog TYPE syrepid.
        lv_prog = iv_name.
        READ TEXTPOOL lv_prog INTO lt_textpool LANGUAGE 'E'.
        IF sy-subrc <> 0.
          READ TEXTPOOL lv_prog INTO lt_textpool LANGUAGE sy-langu.
        ENDIF.
        LOOP AT lt_textpool ASSIGNING FIELD-SYMBOL(<t>).
          APPEND |{ <t>-id } { <t>-key }: { <t>-entry }| TO lt_lines.
        ENDLOOP.
        IF lt_lines IS INITIAL.
          APPEND `* No text elements found.` TO lt_lines.
        ENDIF.
      WHEN OTHERS.
        APPEND `* Text elements not applicable.` TO lt_lines.
    ENDCASE.
    result = concat_lines_of( table = lt_lines sep = cl_abap_char_utilities=>newline ).
  ENDMETHOD.


  METHOD get_object_description.
    CASE iv_type.
      WHEN 'CLAS' OR 'INTF'.
        SELECT SINGLE descript FROM seoclasstx WHERE clsname = @iv_name AND langu = 'E' INTO @result.
      WHEN 'PROG'.
        SELECT SINGLE text FROM trdirt WHERE name = @iv_name AND sprsl = 'E' INTO @result.
      WHEN 'TABL' OR 'VIEW'.
        SELECT SINGLE ddtext FROM dd02t WHERE tabname = @iv_name AND ddlanguage = 'E' INTO @result.
      WHEN 'DTEL'.
        SELECT SINGLE ddtext FROM dd04t WHERE rollname = @iv_name AND ddlanguage = 'E' INTO @result.
      WHEN 'DOMA'.
        SELECT SINGLE ddtext FROM dd01t WHERE domname = @iv_name AND ddlanguage = 'E' INTO @result.
      WHEN 'FUGR'.
        SELECT SINGLE areat FROM tlibt WHERE area = @iv_name AND spras = 'E' INTO @result.
      WHEN 'MSAG'.
        SELECT SINGLE stext FROM t100a WHERE arbgb = @iv_name INTO @result.
      WHEN OTHERS.
        CLEAR result.
    ENDCASE.
  ENDMETHOD.


  METHOD count_lines.
    IF iv_source IS INITIAL.
      result = 0.
    ELSE.
      FIND ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN iv_source MATCH COUNT result.
      result = result + 1.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
