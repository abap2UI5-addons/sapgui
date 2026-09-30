CLASS zcl_se80_ui DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE80 - Object Navigator
*
*  Screen title and menu bar are the original ones of program
*  SAPLWB_INITIAL_TOOL (RSMPTEXTS):
*
*    T  WBM  Object Navigator
*    M  Workbench  Edit  Goto  Utilities  Environment  Test  Worklist
*
*  The window uses the shared SAP GUI frame of package $ZLK_05: the
*  application function bar (band 4) carries the object functions the
*  way the classic SE80 has them spanning the whole window, while the
*  quick entry, find/replace and goto-line bars stay inside the editor
*  column where they belong.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    "! Content of the command field of the system function bar
    DATA mv_command      TYPE string.

    DATA mt_tree         TYPE zcl_se80_api=>ty_t_tree.
    DATA mv_cur_package  TYPE devclass VALUE '$ZLK'.
    DATA mv_source       TYPE string.
    DATA mv_source_local TYPE string.
    DATA mv_source_test  TYPE string.
    DATA mv_search       TYPE string.
    DATA mv_search_type  TYPE string VALUE 'ALL'.
    DATA mv_active_tab   TYPE string VALUE 'SRC'.
    DATA mt_methods      TYPE zcl_se80_api=>ty_t_method.
    DATA mt_fields       TYPE zcl_se80_api=>ty_t_field.
    DATA mt_usages       TYPE zcl_se80_api=>ty_t_usage.
    DATA mt_props        TYPE zcl_se80_api=>ty_t_prop.
    DATA mv_edit_mode    TYPE abap_bool.
    DATA mv_text_elem    TYPE string.
    DATA mv_docu         TYPE string.

    " Navigation history
    TYPES:
      BEGIN OF ty_s_history,
        obj_name TYPE sobj_name,
        obj_type TYPE trobjtype,
      END OF ty_s_history.
    DATA mv_find TYPE string.
    DATA mv_replace TYPE string.
    DATA mv_goto_line TYPE string.
    DATA mv_quick_nav  TYPE string.

    " Recent objects
    TYPES:
      BEGIN OF ty_s_recent,
        text  TYPE string,
        key   TYPE string,
        otype TYPE string,
      END OF ty_s_recent.
    "! selectedKey of the "recent objects" dropdown - read on RECENT_CLICK
    DATA mv_recent_key TYPE string.

    " Bottom log panel
    TYPES:
      BEGIN OF ty_s_log,
        icon    TYPE string,
        type    TYPE string,
        line    TYPE string,
        message TYPE string,
      END OF ty_s_log.
    TYPES ty_t_log TYPE STANDARD TABLE OF ty_s_log WITH EMPTY KEY.
    DATA mt_log TYPE ty_t_log.

  PROTECTED SECTION.
    DATA mv_cur_obj_name TYPE sobj_name.
    DATA mv_cur_obj_type TYPE trobjtype.
    DATA mv_object_title TYPE string.
    DATA mv_message      TYPE string.
    DATA mv_msg_type     TYPE string.
    DATA mv_show_whereu  TYPE abap_bool.
    DATA mv_popup_title  TYPE string.
    DATA mv_syntax_mode  TYPE string VALUE 'abap'.
    DATA mv_status       TYPE string.
    DATA mt_history TYPE STANDARD TABLE OF ty_s_history WITH EMPTY KEY.
    DATA mv_hist_pos TYPE i VALUE 0.
    DATA mv_fullscreen TYPE abap_bool.
    DATA mv_dark_theme TYPE abap_bool.
    DATA mv_breadcrumb TYPE string.
    DATA mv_lock_info  TYPE string.
    DATA mt_recent TYPE STANDARD TABLE OF ty_s_recent WITH EMPTY KEY.

    DATA client TYPE REF TO z2ui5_if_client.
    DATA mo_api TYPE REF TO zcl_se80_api.
    METHODS view_display.
    METHODS on_event.
    METHODS load_object.
    "! Repository Browser (left column)
    METHODS build_browser
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    "! Object editor (right column)
    METHODS build_editor
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder.
    "! Band 1 of the frame - the original SE80 menu bar
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.
    "! Band 4 of the frame - the object functions of SE80. A function that
    "! does not apply right now is greyed out, not hidden, exactly like in
    "! the SAP GUI.
    METHODS app_buttons
      RETURNING VALUE(result) TYPE zcl_zlk05_gui_frame=>ty_t_button.
    "! Where-Used List / Used Objects popup - built on its OWN factory so that
    "! stringify( ) returns a single, well formed root element
    METHODS build_popup
      RETURNING VALUE(result) TYPE string.
  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se80_ui IMPLEMENTATION.

  METHOD z2ui5_if_app~main.
    me->client = client.
    IF mo_api IS NOT BOUND.
      mo_api = NEW zcl_se80_api( ).
    ENDIF.
    IF client->check_on_init( ).
      mt_tree = mo_api->get_package_tree( mv_cur_package ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 / the Back arrow and handed
      " control back to this one. The framework supplies an EMPTY event here
      " and check_on_init is already false, so without this branch nothing
      " would be rendered: the response would carry no view and the browser
      " would keep showing the screen of the transaction that was just left.
      " That is what made Back look dead and F3 only work on the second try.
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.
  ENDMETHOD.


  METHOD on_event.
    DATA(lv_event) = client->get_event( ).
    DATA(lt_arg) = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msg_type, mt_log.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = lv_event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msg_type = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE lv_event.
      WHEN 'TREE_CLICK'.
        IF lines( lt_arg ) >= 2.
          IF lt_arg[ 2 ] = 'DEVC'.
            mv_cur_package = lt_arg[ 1 ].
            mt_tree = mo_api->get_package_tree( mv_cur_package ).
            mt_props = mo_api->get_package_info( mv_cur_package ).
            mv_object_title = |Package { mv_cur_package }|.
            mv_active_tab = 'INFO'.
            CLEAR: mv_source, mv_source_local, mv_source_test, mv_cur_obj_name, mt_methods, mt_fields.
          ELSEIF lt_arg[ 2 ] = 'METH'.
            " Method clicked - navigate to class and show signature
            DATA(lv_meth_key) = lt_arg[ 1 ].
            SPLIT lv_meth_key AT '=>' INTO DATA(lv_cls) DATA(lv_mtd).
            mv_cur_obj_name = lv_cls.
            mv_cur_obj_type = 'CLAS'.
            load_object( ).
            " Get method signature and show in fields
            mt_fields = mo_api->get_method_signature(
              iv_classname = mv_cur_obj_name iv_methodname = lv_mtd ).
            " Find method line in source
            DATA(lv_search) = |method { to_lower( lv_mtd ) }|.
            DATA(lv_pos) = find( val = to_lower( mv_source ) sub = lv_search ).
            IF lv_pos >= 0.
              DATA(lv_line) = 1.
              DATA(lv_cnt) = 0.
              DO lv_pos TIMES.
                IF mv_source+lv_cnt(1) = cl_abap_char_utilities=>newline.
                  lv_line = lv_line + 1.
                ENDIF.
                lv_cnt = lv_cnt + 1.
              ENDDO.
              mv_message = |Method { lv_mtd } in line { lv_line }|.
            ELSE.
              mv_message = |Method { lv_mtd } - signature displayed under Properties|.
            ENDIF.
            mv_msg_type = `Information`.
            mv_active_tab = 'INFO'.
          ELSE.
            mv_cur_obj_name = lt_arg[ 1 ].
            mv_cur_obj_type = lt_arg[ 2 ].
            load_object( ).
          ENDIF.
        ENDIF.
      WHEN 'NAV_BACK'.
        IF mv_hist_pos > 1.
          mv_hist_pos = mv_hist_pos - 1.
          mv_cur_obj_name = mt_history[ mv_hist_pos ]-obj_name.
          mv_cur_obj_type = mt_history[ mv_hist_pos ]-obj_type.
          load_object( ).
        ENDIF.
      WHEN 'NAV_FORWARD'.
        IF mv_hist_pos < lines( mt_history ).
          mv_hist_pos = mv_hist_pos + 1.
          mv_cur_obj_name = mt_history[ mv_hist_pos ]-obj_name.
          mv_cur_obj_type = mt_history[ mv_hist_pos ]-obj_type.
          load_object( ).
        ENDIF.
      WHEN 'NAV_UP'.
        SELECT SINGLE parentcl FROM tdevc WHERE devclass = @mv_cur_package INTO @DATA(lv_p).
        IF sy-subrc = 0 AND lv_p IS NOT INITIAL.
          mv_cur_package = lv_p.
          mt_tree = mo_api->get_package_tree( mv_cur_package ).
          CLEAR: mv_source, mv_source_local, mv_source_test, mv_cur_obj_name, mv_object_title, mt_methods, mt_fields, mt_props.
        ELSE.
          mv_message = |Package { mv_cur_package } has no superpackage.|.
          mv_msg_type = `Information`.
        ENDIF.
      WHEN 'SEARCH'.
        IF mv_search IS NOT INITIAL.
          DATA lv_tf TYPE trobjtype.
          IF mv_search_type IS NOT INITIAL AND mv_search_type <> 'ALL'.
            lv_tf = mv_search_type.
          ENDIF.
          mt_tree = mo_api->search_objects( iv_pattern = mv_search iv_type = lv_tf ).
          mv_object_title = |Object list: { lines( mt_tree ) } hits|.
          CLEAR: mv_source, mv_source_local, mv_source_test.
        ELSE.
          mv_message = `Enter an object name.`.
          mv_msg_type = `Warning`.
        ENDIF.
      WHEN 'TOGGLE_EDIT'.
        mv_edit_mode = xsdbool( mv_edit_mode = abap_false ).
      WHEN 'SAVE'.
        IF mv_source IS INITIAL.
          mv_message = `Source code is empty.`.
          mv_msg_type = `Error`.
        ELSE.
          DATA(ls_s) = mo_api->save_source( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type iv_source = mv_source ).
          mv_message = ls_s-message.
          mv_msg_type = COND #( WHEN ls_s-success = abap_true THEN `Success` ELSE `Error` ).
          APPEND VALUE ty_s_log(
            icon = COND #( WHEN ls_s-success = abap_true THEN `sap-icon://sys-enter-2` ELSE `sap-icon://error` )
            type = COND #( WHEN ls_s-success = abap_true THEN `Success` ELSE `Error` )
            message = ls_s-message ) TO mt_log.
        ENDIF.
      WHEN 'ACTIVATE'.
        DATA(ls_a) = mo_api->activate_object( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
        mv_message = ls_a-message.
        mv_msg_type = COND #( WHEN ls_a-success = abap_true THEN `Success` ELSE `Error` ).
        APPEND VALUE ty_s_log(
          icon = COND #( WHEN ls_a-success = abap_true THEN `sap-icon://sys-enter-2` ELSE `sap-icon://error` )
          type = COND #( WHEN ls_a-success = abap_true THEN `Success` ELSE `Error` )
          message = ls_a-message ) TO mt_log.
        IF ls_a-success = abap_true.
          load_object( ).
        ENDIF.
      WHEN 'CHECK'.
        DATA(lt_c) = mo_api->check_syntax( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type iv_source = mv_source ).
        IF lt_c IS NOT INITIAL.
          mv_message = lt_c[ 1 ]-message.
          mv_msg_type = COND #( WHEN lt_c[ 1 ]-type = 'E' THEN `Error` ELSE `Warning` ).
          " Fill log panel
          LOOP AT lt_c ASSIGNING FIELD-SYMBOL(<chk>).
            APPEND VALUE ty_s_log(
              icon    = COND #( WHEN <chk>-type = 'E' THEN `sap-icon://error`
                                WHEN <chk>-type = 'W' THEN `sap-icon://alert` ELSE `sap-icon://sys-enter-2` )
              type    = COND #( WHEN <chk>-type = 'E' THEN `Error` WHEN <chk>-type = 'W' THEN `Warning` ELSE `Success` )
              line    = COND #( WHEN <chk>-line > 0 THEN |Line { <chk>-line }| )
              message = <chk>-message
            ) TO mt_log.
          ENDLOOP.
        ELSE.
          mv_message = `No syntax errors found.`.
          mv_msg_type = `Success`.
          APPEND VALUE ty_s_log( icon = `sap-icon://sys-enter-2` type = `Success` message = `No syntax errors found.` ) TO mt_log.
        ENDIF.
      WHEN 'PRETTY_PRINT'.
        mv_source = mo_api->pretty_print( mv_source ).
        mv_message = `Pretty Printer executed.`.
        mv_msg_type = `Success`.
      WHEN 'WHERE_USED'.
        mt_usages = mo_api->get_where_used( mv_cur_obj_name ).
        mv_popup_title = |Where-Used List: { mv_cur_obj_name }|.
        mv_show_whereu = abap_true.
      WHEN 'CLOSE_WHEREU'.
        mv_show_whereu = abap_false.
        client->popup_destroy( ).
      WHEN 'USAGE_CLICK'.
        IF lines( lt_arg ) >= 2.
          mv_cur_obj_name = lt_arg[ 1 ].
          mv_cur_obj_type = lt_arg[ 2 ].
          mv_show_whereu = abap_false.
          client->popup_destroy( ).
          load_object( ).
        ENDIF.
      WHEN 'CREATE_OBJ'.
        " Create program or class (based on search type filter)
        IF mv_search IS NOT INITIAL.
          DATA(lv_new_name) = CONV sobj_name( to_upper( mv_search ) ).
          DATA ls_cr TYPE zcl_se80_api=>ty_s_result.
          IF mv_search_type = 'CLAS'.
            ls_cr = mo_api->create_class( iv_name = lv_new_name iv_package = mv_cur_package ).
            IF ls_cr-success = abap_true.
              mv_cur_obj_type = 'CLAS'.
            ENDIF.
          ELSEIF mv_search_type = 'INTF'.
            ls_cr = mo_api->create_interface( iv_name = lv_new_name iv_package = mv_cur_package ).
            IF ls_cr-success = abap_true.
              mv_cur_obj_type = 'INTF'.
            ENDIF.
          ELSE.
            ls_cr = mo_api->create_program( iv_name = lv_new_name iv_package = mv_cur_package ).
            IF ls_cr-success = abap_true.
              mv_cur_obj_type = 'PROG'.
            ENDIF.
          ENDIF.
          mv_message = ls_cr-message.
          mv_msg_type = COND #( WHEN ls_cr-success = abap_true THEN `Success` ELSE `Error` ).
          IF ls_cr-success = abap_true.
            mt_tree = mo_api->get_package_tree( mv_cur_package ).
            mv_cur_obj_name = lv_new_name.
            load_object( ).
          ENDIF.
        ELSE.
          mv_message = `Enter the object name in the search field and choose the object type.`.
          mv_msg_type = `Warning`.
        ENDIF.
      WHEN 'CONFIRM_DELETE'.
        " Actually delete after confirmation
        DATA(ls_del) = mo_api->delete_object( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
        mv_message = ls_del-message.
        mv_msg_type = COND #( WHEN ls_del-success = abap_true THEN `Success` ELSE `Error` ).
        APPEND VALUE ty_s_log(
          icon = COND #( WHEN ls_del-success = abap_true THEN `sap-icon://sys-enter-2` ELSE `sap-icon://error` )
          type = COND #( WHEN ls_del-success = abap_true THEN `Success` ELSE `Error` )
          message = ls_del-message ) TO mt_log.
        IF ls_del-success = abap_true.
          CLEAR: mv_source, mv_source_local, mv_source_test, mv_cur_obj_name, mv_object_title, mt_methods, mt_fields, mt_props, mv_status.
          mt_tree = mo_api->get_package_tree( mv_cur_package ).
        ENDIF.
      WHEN 'QUICK_NAV'.
        IF mv_quick_nav IS NOT INITIAL.
          " Try to load object directly by name
          DATA(lv_qn) = to_upper( mv_quick_nav ).
          SELECT SINGLE object, obj_name FROM tadir
            WHERE pgmid = 'R3TR' AND obj_name = @lv_qn
            INTO @DATA(ls_qn).
          IF sy-subrc = 0.
            mv_cur_obj_name = ls_qn-obj_name.
            mv_cur_obj_type = ls_qn-object.
            load_object( ).
          ELSE.
            mv_message = |Object { mv_quick_nav } does not exist.|.
            mv_msg_type = `Warning`.
          ENDIF.
        ENDIF.
      WHEN 'TOGGLE_THEME'.
        mv_dark_theme = xsdbool( mv_dark_theme = abap_false ).
      WHEN 'GOTO_LINE'.
        IF mv_goto_line IS NOT INITIAL.
          mv_message = |Position on line { mv_goto_line } (use Ctrl+G inside the editor).|.
          mv_msg_type = `Information`.
        ENDIF.
      WHEN 'FULLSCREEN'.
        mv_fullscreen = xsdbool( mv_fullscreen = abap_false ).
      WHEN 'REPLACE_ALL'.
        IF mv_find IS NOT INITIAL AND mv_edit_mode = abap_true.
          DATA lv_rep_count TYPE i.
          mo_api->search_replace_source(
            EXPORTING iv_source = mv_source iv_search = mv_find iv_replace = mv_replace
            IMPORTING ev_source = mv_source ev_count = lv_rep_count ).
          mv_message = |{ lv_rep_count } replacement(s) carried out.|.
          mv_msg_type = COND #( WHEN lv_rep_count > 0 THEN `Success` ELSE `Warning` ).
        ELSEIF mv_edit_mode = abap_false.
          mv_message = `Switch to change mode first.`.
          mv_msg_type = `Warning`.
        ENDIF.
      WHEN 'COMPARE'.
        DATA(lv_diff) = mo_api->compare_versions( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
        IF lv_diff IS NOT INITIAL.
          mv_source = lv_diff.
          mv_active_tab = 'SRC'.
          mv_message = `Version comparison displayed.`.
          mv_msg_type = `Information`.
        ELSE.
          mv_message = `No other version found.`.
          mv_msg_type = `Warning`.
        ENDIF.
      WHEN 'FIND_IN_SOURCE'.
        IF mv_find IS NOT INITIAL AND mv_source IS NOT INITIAL.
          DATA(lv_fl) = to_lower( mv_find ).
          DATA(lv_sl) = to_lower( mv_source ).
          DATA lv_cnt2 TYPE i.
          DATA lv_fline TYPE i.
          DATA lv_o TYPE i.
          DO.
            FIND lv_fl IN SECTION OFFSET lv_o OF lv_sl MATCH OFFSET DATA(lv_mo).
            IF sy-subrc <> 0.
              EXIT.
            ENDIF.
            lv_cnt2 = lv_cnt2 + 1.
            IF lv_fline = 0.
              DATA lv_nl TYPE i.
              FIND ALL OCCURRENCES OF cl_abap_char_utilities=>newline IN lv_sl(lv_mo) MATCH COUNT lv_nl.
              lv_fline = lv_nl + 1.
            ENDIF.
            lv_o = lv_mo + 1.
          ENDDO.
          mv_message = COND #( WHEN lv_cnt2 > 0 THEN |{ lv_cnt2 } hit(s), first one in line { lv_fline }| ELSE |{ mv_find } not found.| ).
          mv_msg_type = COND #( WHEN lv_cnt2 > 0 THEN `Success` ELSE `Warning` ).
        ENDIF.
      WHEN 'RECENT_CLICK'.
        " Object selected from the "recent objects" dropdown. The selected key is
        " read from the two-way bound selectedKey, not from an event argument.
        IF mv_recent_key IS NOT INITIAL.
          READ TABLE mt_recent WITH KEY key = mv_recent_key ASSIGNING FIELD-SYMBOL(<recent>).
          IF sy-subrc = 0.
            mv_cur_obj_name = <recent>-key.
            mv_cur_obj_type = <recent>-otype.
            load_object( ).
          ENDIF.
        ENDIF.
      WHEN 'DELETE_OBJ'.
        " Show confirmation - just set flag, actual delete in CONFIRM_DELETE
        mv_message = |Delete object { mv_cur_obj_name }? Choose Delete again to confirm.|.
        mv_msg_type = `Warning`.
      WHEN 'SHOW_DEPS'.
        " Show object dependencies
        mt_usages = mo_api->get_object_dependencies( mv_cur_obj_name ).
        mv_popup_title = |Used Objects: { mv_cur_obj_name }|.
        mv_show_whereu = abap_true.
      WHEN 'REFRESH'.
        mt_tree = mo_api->get_package_tree( mv_cur_package ).
      WHEN OTHERS.
    ENDCASE.
    view_display( ).
  ENDMETHOD.


  METHOD load_object.
    mv_object_title = |{ mv_cur_obj_type } { mv_cur_obj_name }|.
    " Add to recent objects (max 20, no duplicates)
    DELETE mt_recent WHERE key = mv_cur_obj_name.
    INSERT VALUE ty_s_recent(
      text  = |{ mv_cur_obj_name } [{ mv_cur_obj_type }]|
      key   = mv_cur_obj_name
      otype = mv_cur_obj_type
    ) INTO mt_recent INDEX 1.
    IF lines( mt_recent ) > 20.
      DELETE mt_recent FROM 21 TO lines( mt_recent ).
    ENDIF.
    mv_recent_key = mv_cur_obj_name.
    " Add to navigation history
    IF mv_hist_pos = 0 OR
       ( mv_hist_pos > 0 AND mt_history[ mv_hist_pos ]-obj_name <> mv_cur_obj_name ).
      " Truncate forward history
      IF mv_hist_pos < lines( mt_history ).
        DELETE mt_history FROM mv_hist_pos + 1.
      ENDIF.
      APPEND VALUE ty_s_history( obj_name = mv_cur_obj_name obj_type = mv_cur_obj_type ) TO mt_history.
      mv_hist_pos = lines( mt_history ).
    ENDIF.
    DATA(ls) = mo_api->load_source( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
    mv_source = ls-source.
    mv_source_local = ls-source_local.
    mv_source_test = ls-source_test.
    mv_syntax_mode = ls-syntax_mode.
    IF ls-success = abap_false AND ls-message IS NOT INITIAL.
      mv_message = ls-message.
      mv_msg_type = `Warning`.
    ENDIF.
    mo_api->get_metadata( EXPORTING iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type
                          IMPORTING et_methods = mt_methods et_fields = mt_fields ).
    mt_props = mo_api->get_properties( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type iv_source = mv_source ).
    " Add program attributes for PROG
    IF mv_cur_obj_type = 'PROG' OR mv_cur_obj_type = 'FUGR'.
      DATA(lt_pattr) = mo_api->get_program_attributes( mv_cur_obj_name ).
      LOOP AT lt_pattr ASSIGNING FIELD-SYMBOL(<pa>).
        APPEND VALUE zcl_se80_api=>ty_s_field( name = <pa>-name type = <pa>-type ) TO mt_fields.
      ENDLOOP.
      " Variants
      DATA(lt_vars) = mo_api->get_variants( mv_cur_obj_name ).
      LOOP AT lt_vars ASSIGNING FIELD-SYMBOL(<var>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <var>-name keyflag = `VAR` type = <var>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " Add events + constants for classes
    IF mv_cur_obj_type = 'CLAS' OR mv_cur_obj_type = 'INTF'.
      DATA(lt_events) = mo_api->get_class_events( mv_cur_obj_name ).
      LOOP AT lt_events ASSIGNING FIELD-SYMBOL(<evt>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <evt>-name keyflag = <evt>-keyflag type = <evt>-type ) TO mt_fields.
      ENDLOOP.
      DATA(lt_const) = mo_api->get_class_constants( mv_cur_obj_name ).
      LOOP AT lt_const ASSIGNING FIELD-SYMBOL(<co2>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <co2>-name keyflag = <co2>-keyflag
          typtype = <co2>-typtype type = <co2>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " FM exceptions
    IF mv_cur_obj_type = 'FUNC'.
      DATA(lt_exc) = mo_api->get_fm_exceptions( mv_cur_obj_name ).
      LOOP AT lt_exc ASSIGNING FIELD-SYMBOL(<exc>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <exc>-name keyflag = <exc>-keyflag type = <exc>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " Table foreign keys + append structures
    IF mv_cur_obj_type = 'TABL'.
      DATA(lt_fk) = mo_api->get_table_foreign_keys( mv_cur_obj_name ).
      LOOP AT lt_fk ASSIGNING FIELD-SYMBOL(<fk2>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <fk2>-name keyflag = <fk2>-keyflag type = <fk2>-type ) TO mt_fields.
      ENDLOOP.
      DATA(lt_app) = mo_api->get_table_append_structures( mv_cur_obj_name ).
      LOOP AT lt_app ASSIGNING FIELD-SYMBOL(<app2>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <app2>-name keyflag = <app2>-keyflag type = <app2>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " Class friends + redefined methods
    IF mv_cur_obj_type = 'CLAS'.
      DATA(lt_fr) = mo_api->get_class_friends( mv_cur_obj_name ).
      LOOP AT lt_fr ASSIGNING FIELD-SYMBOL(<fr2>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <fr2>-name type = <fr2>-type ) TO mt_fields.
      ENDLOOP.
      DATA(lt_red) = mo_api->get_redefined_methods( mv_cur_obj_name ).
      LOOP AT lt_red ASSIGNING FIELD-SYMBOL(<red>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <red>-name keyflag = <red>-keyflag type = <red>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " Class types
    IF mv_cur_obj_type = 'CLAS' OR mv_cur_obj_type = 'INTF'.
      DATA(lt_types) = mo_api->get_class_types( mv_cur_obj_name ).
      LOOP AT lt_types ASSIGNING FIELD-SYMBOL(<tp>).
        APPEND VALUE zcl_se80_api=>ty_s_field(
          name = <tp>-name keyflag = <tp>-keyflag type = <tp>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    " Table content preview
    IF mv_cur_obj_type = 'TABL' AND mv_source IS INITIAL.
      mv_source = mo_api->get_table_content( iv_name = mv_cur_obj_name iv_maxrows = 10 ).
      mv_syntax_mode = `text`.
    ENDIF.
    " Source statistics
    IF mv_source IS NOT INITIAL.
      DATA(lt_stats) = mo_api->get_source_statistics( mv_source ).
      LOOP AT lt_stats ASSIGNING FIELD-SYMBOL(<st>).
        APPEND VALUE zcl_se80_api=>ty_s_field( name = <st>-name type = <st>-type ) TO mt_fields.
      ENDLOOP.
    ENDIF.
    mv_text_elem = mo_api->get_text_elements( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
    mv_docu = mo_api->get_documentation( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
    mv_status = mo_api->get_object_status( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
    mv_lock_info = mo_api->get_lock_info( iv_name = mv_cur_obj_name iv_type = mv_cur_obj_type ).
    mv_breadcrumb = mo_api->get_package_path( mv_cur_package ).
    mv_active_tab = 'SRC'.
  ENDMETHOD.


  METHOD menu_entries.

    result = VALUE #( ( `Workbench` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                      ( `Environment` ) ( `Test` ) ( `Worklist` )
                      ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD app_buttons.

    DATA(lv_has)  = xsdbool( mv_cur_obj_name IS INITIAL ).
    DATA(lv_disp) = xsdbool( mv_edit_mode = abap_false ).

    result = VALUE #(
        ( text     = COND string( WHEN mv_edit_mode = abap_true
                                  THEN `Display` ELSE `Change` )
          icon     = COND string( WHEN mv_edit_mode = abap_true
                                  THEN `sap-icon://display` ELSE `sap-icon://edit` )
          tooltip  = `Display <-> Change`
          press    = client->_event( `TOGGLE_EDIT` )
          disabled = lv_has )
        ( icon     = `sap-icon://save`     tooltip = `Save`
          press    = client->_event( `SAVE` )    disabled = lv_disp )
        ( icon     = `sap-icon://syntax`   tooltip = `Check`
          press    = client->_event( `CHECK` )   disabled = lv_has )
        ( icon     = `sap-icon://activate` tooltip = `Activate`
          press    = client->_event( `ACTIVATE` ) disabled = lv_has )
        ( icon     = `sap-icon://text-formatting` tooltip = `Pretty Printer`
          press    = client->_event( `PRETTY_PRINT` ) disabled = lv_has )
        ( icon     = `sap-icon://compare`  tooltip = `Compare Versions`
          press    = client->_event( `COMPARE` ) disabled = lv_has )
        ( sep      = abap_true )
        ( icon     = `sap-icon://nav-back` tooltip = `Back`
          press    = client->_event( `NAV_BACK` )
          disabled = xsdbool( mv_hist_pos <= 1 ) )
        ( icon     = `sap-icon://forward` tooltip = `Forward`
          press    = client->_event( `NAV_FORWARD` )
          disabled = xsdbool( mv_hist_pos >= lines( mt_history ) ) )
        ( sep      = abap_true )
        ( icon     = `sap-icon://search`   tooltip = `Where-Used List`
          press    = client->_event( `WHERE_USED` ) disabled = lv_has )
        ( icon     = `sap-icon://chain-link` tooltip = `Used Objects`
          press    = client->_event( `SHOW_DEPS` ) disabled = lv_has )
        ( icon     = `sap-icon://refresh`  tooltip = `Refresh`
          press    = client->_event( `REFRESH` ) )
        ( sep      = abap_true )
        ( icon     = `sap-icon://create`   tooltip = `Create`
          press    = client->_event( `CREATE_OBJ` ) )
        ( icon     = `sap-icon://delete`   color = zcl_zlk05_gui_frame=>c_red
          tooltip  = `Delete`
          press    = COND string( WHEN mv_msg_type = `Warning` AND mv_message CS `Delete`
                                  THEN client->_event( `CONFIRM_DELETE` )
                                  ELSE client->_event( `DELETE_OBJ` ) )
          disabled = lv_has )
        ( sep      = abap_true )
        ( icon     = `sap-icon://copy`
          tooltip  = `Copy Source Code to Clipboard`
          press    = client->follow_up_action(
                         val   = client->cs_event-clipboard_copy
                         t_arg = VALUE #( ( client->_bind( val = mv_source path = `X` ) ) ) ) )
        ( icon     = COND string( WHEN mv_fullscreen = abap_true
                                  THEN `sap-icon://exit-full-screen`
                                  ELSE `sap-icon://full-screen` )
          tooltip  = `Full Screen On/Off`
          press    = client->_event( `FULLSCREEN` ) ) ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msg_type ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar with the command field
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar. The object currently loaded is named next to the
    " original screen title.
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Object Navigator`
        iv_hint   = COND string( WHEN mv_object_title IS NOT INITIAL
                                 THEN COND string( WHEN mv_status IS NOT INITIAL
                                                   THEN |{ mv_object_title } - { mv_status }|
                                                   ELSE mv_object_title ) ) ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar( io_parent  = page
                                       it_buttons = app_buttons( ) ).

    " band 5 - work area: repository browser and object editor side by side
    DATA(flex) = page->ele( `HBox`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `width`      v = `100%`
        )->a( n = `alignItems` v = `Stretch` ).

    IF mv_fullscreen = abap_false.
      build_browser( flex ).
    ENDIF.
    build_editor( flex ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and Ctrl+S
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_save_name = `SAVE` ).

    " The Where-Used List / Used Objects popup lives on its own factory, so the
    " main view keeps exactly one root element.
    IF mv_show_whereu = abap_true.
      client->popup_display( build_popup( ) ).
    ELSE.
      client->view_display( view->stringify( ) ).
    ENDIF.

  ENDMETHOD.


  METHOD build_browser.

    " ===== Repository Browser (left column) =====
    DATA(col) = io_parent->ele( `VBox` )->a( n = `width` v = `320px` ).

    " --- Package with navigation ---
    DATA(bar1) = col->ele( `Toolbar` )->a( n = `height` v = `2.5rem` ).
    bar1->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://nav-back`
        )->a( n = `tooltip` v = `Superpackage`
        )->a( n = `press`   v = client->_event( `NAV_UP` )
        )->a( n = `type`    v = `Transparent`
        )->tag( `Input`
            )->a( n = `value`       v = client->_bind( mv_cur_package )
            )->a( n = `submit`      v = client->_event( `REFRESH` )
            )->a( n = `width`       v = `200px`
            )->a( n = `placeholder` v = `Package`
        )->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://display`
            )->a( n = `tooltip` v = `Display`
            )->a( n = `press`   v = client->_event( `REFRESH` )
            )->a( n = `type`    v = `Transparent` ).

    " --- Object search ---
    DATA(bar2) = col->ele( `Toolbar` )->a( n = `height` v = `2.5rem` ).
    bar2->tag( `SearchField`
        )->a( n = `placeholder` v = `Object name`
        )->a( n = `value`       v = client->_bind( mv_search )
        )->a( n = `search`      v = client->_event( `SEARCH` )
        )->a( n = `width`       v = `200px` ).
    DATA(type_sel) = bar2->ele( `Select`
        )->a( n = `selectedKey` v = client->_bind( mv_search_type )
        )->a( n = `width`       v = `105px`
        )->a( n = `tooltip`     v = `Object type` ).
    DATA(type_items) = type_sel->ele( `items` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `ALL`  )->a( n = `text` v = `All` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `CLAS` )->a( n = `text` v = `Class` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `INTF` )->a( n = `text` v = `Interface` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `PROG` )->a( n = `text` v = `Program` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `FUGR` )->a( n = `text` v = `Func.Group` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `TABL` )->a( n = `text` v = `Table` ).
    type_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `DDLS` )->a( n = `text` v = `CDS View` ).

    " --- Recent objects + tree expand/collapse ---
    DATA(bar3) = col->ele( `Toolbar` )->a( n = `height` v = `2rem` ).
    IF mt_recent IS NOT INITIAL.
      DATA(rec_sel) = bar3->ele( `Select`
          )->a( n = `width`       v = `160px`
          )->a( n = `tooltip`     v = `Recently used objects`
          )->a( n = `selectedKey` v = client->_bind( mv_recent_key )
          )->a( n = `change`      v = client->_event( `RECENT_CLICK` ) ).
      DATA(rec_items) = rec_sel->ele( `items` ).
      LOOP AT mt_recent ASSIGNING FIELD-SYMBOL(<rc>).
        rec_items->tag( n = `Item` ns = `core`
            )->a( n = `key`  t = <rc>-key
            )->a( n = `text` v = <rc>-text ).
      ENDLOOP.
    ENDIF.
    bar3->tag( `ToolbarSpacer`
        )->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://expand-group`
            )->a( n = `tooltip` v = `Expand`
            )->a( n = `type`    v = `Transparent`
            )->a( n = `press`   v = client->follow_up_action(
                val   = client->cs_event-control_by_id
                t_arg = VALUE #( ( `se80Tree` ) ( `expandToLevel` ) ( `3` ) ) )
        )->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://collapse-group`
            )->a( n = `tooltip` v = `Collapse`
            )->a( n = `type`    v = `Transparent`
            )->a( n = `press`   v = client->follow_up_action(
                val   = client->cs_event-control_by_id
                t_arg = VALUE #( ( `se80Tree` ) ( `collapseAll` ) ) ) ).

    " --- Object tree ---
    DATA(lv_bind) = |\{path:'{ client->_bind( val = mt_tree path = abap_true ) }', parameters:\{arrayNames:['NODES']\}\}|.

    DATA(scroll) = col->ele( `ScrollContainer`
        )->a( n = `height`   v = `calc(100vh - 140px)`
        )->a( n = `vertical` v = `true` ).
    scroll->ele( `Tree`
        )->a( n = `id`             v = `se80Tree`
        )->a( n = `items`          v = lv_bind
        )->a( n = `noDataText`     v = `No objects found`
        )->ele( `StandardTreeItem`
            )->a( n = `title` v = `{TEXT}`
            )->a( n = `icon`  v = `{ICON}`
            )->a( n = `type`  v = `Active`
            )->a( n = `press` v = client->_event( val   = `TREE_CLICK`
                                                  t_arg = VALUE #( ( `${KEY}` ) ( `${OTYPE}` ) ) ) ).

  ENDMETHOD.


  METHOD build_editor.

    DATA(col) = io_parent->ele( `VBox`
        )->a( n = `height` v = `100%`
        )->a( n = `width`  v = `100%` ).

    " the object functions moved up into band 4 of the frame, only the
    " editor local bars are left here

    " ===== Object entry / package path / lock information =====
    DATA(bar2) = col->ele( `Toolbar` )->a( n = `height` v = `2rem` ).
    bar2->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_quick_nav )
        )->a( n = `width`       v = `160px`
        )->a( n = `placeholder` v = `Other object`
        )->a( n = `submit`      v = client->_event( `QUICK_NAV` ) ).
    IF mv_breadcrumb IS NOT INITIAL.
      bar2->tag( `Text` )->a( n = `text` t = mv_breadcrumb ).
    ENDIF.
    IF mv_lock_info IS NOT INITIAL.
      bar2->tag( `ObjectStatus`
          )->a( n = `text`  t = mv_lock_info
          )->a( n = `state` v = `Warning` ).
    ENDIF.
    bar2->tag( `ToolbarSpacer`
        )->tag( `Button`
            )->a( n = `icon`    v = COND #( WHEN mv_dark_theme = abap_true
                                            THEN `sap-icon://lightbulb` ELSE `sap-icon://background` )
            )->a( n = `tooltip` v = `Switch Editor Colors`
            )->a( n = `press`   v = client->_event( `TOGGLE_THEME` )
            )->a( n = `type`    v = `Transparent` ).

    " ===== Find / Replace / Goto line =====
    DATA(bar3) = col->ele( `Toolbar` )->a( n = `height` v = `2rem` ).
    bar3->tag( `Label`
        )->a( n = `text` v = `Find`
        )->tag( `Input`
            )->a( n = `value`       v = client->_bind( mv_find )
            )->a( n = `width`       v = `130px`
            )->a( n = `placeholder` v = `Search term`
            )->a( n = `submit`      v = client->_event( `FIND_IN_SOURCE` )
        )->tag( `Button`
            )->a( n = `icon`    v = `sap-icon://search`
            )->a( n = `tooltip` v = `Find`
            )->a( n = `press`   v = client->_event( `FIND_IN_SOURCE` )
            )->a( n = `type`    v = `Transparent`
        )->tag( `Label`
            )->a( n = `text` v = `Replace`
        )->tag( `Input`
            )->a( n = `value`       v = client->_bind( mv_replace )
            )->a( n = `width`       v = `130px`
            )->a( n = `placeholder` v = `Replace with`
            )->a( n = `submit`      v = client->_event( `REPLACE_ALL` )
        )->tag( `Button`
            )->a( n = `text`    v = `Replace All`
            )->a( n = `tooltip` v = `Replace All`
            )->a( n = `press`   v = client->_event( `REPLACE_ALL` )
            )->a( n = `type`    v = `Transparent`
            )->a( n = `enabled` b = mv_edit_mode
        )->tag( `ToolbarSeparator`
        )->tag( `Label`
            )->a( n = `text` v = `Line`
        )->tag( `Input`
            )->a( n = `value`  v = client->_bind( mv_goto_line )
            )->a( n = `width`  v = `60px`
            )->a( n = `type`   v = `Number`
            )->a( n = `submit` v = client->_event( `GOTO_LINE` ) ).

    " ===== Status message =====
    IF mv_message IS NOT INITIAL.
      col->tag( `MessageStrip`
          )->a( n = `text`            t = mv_message
          )->a( n = `type`            v = mv_msg_type
          )->a( n = `showCloseButton` v = `true` ).
    ENDIF.

    " ===== Tab strip =====
    DATA(tabs) = col->ele( `IconTabBar`
        )->a( n = `selectedKey`          v = client->_bind( mv_active_tab )
        )->a( n = `expandable`           v = `false`
        )->a( n = `stretchContentHeight` v = `true`
        )->ele( `items` ).

    " --- Source Code ---
    DATA(t1) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Source Code`
        )->a( n = `key`  v = `SRC`
        )->a( n = `icon` v = `sap-icon://syntax` ).
    DATA(c1) = t1->ele( `content` ).
    IF mv_edit_mode = abap_true.
      c1->tag( `TextArea`
          )->a( n = `value`   v = client->_bind( mv_source )
          )->a( n = `height`  v = `calc(100vh - 190px)`
          )->a( n = `width`   v = `100%`
          )->a( n = `growing` v = `false` ).
    ELSE.
      c1->tag( n = `CodeEditor` ns = `editor`
          )->a( n = `value`      v = client->_bind( mv_source )
          )->a( n = `type`       t = mv_syntax_mode
          )->a( n = `height`     v = `calc(100vh - 190px)`
          )->a( n = `width`      v = `100%`
          )->a( n = `editable`   v = `false`
          )->a( n = `colorTheme` v = COND #( WHEN mv_dark_theme = abap_true THEN `tomorrow_night` ELSE `tomorrow` ) ).
    ENDIF.

    " --- Local Definitions/Implementations ---
    DATA(t2) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Local Definitions/Implementations`
        )->a( n = `key`  v = `LOC`
        )->a( n = `icon` v = `sap-icon://detail-view` ).
    DATA(c2) = t2->ele( `content` ).
    IF mv_edit_mode = abap_true.
      c2->tag( `TextArea`
          )->a( n = `value`   v = client->_bind( mv_source_local )
          )->a( n = `height`  v = `calc(100vh - 190px)`
          )->a( n = `width`   v = `100%`
          )->a( n = `growing` v = `false` ).
    ELSE.
      c2->tag( n = `CodeEditor` ns = `editor`
          )->a( n = `value`      v = client->_bind( mv_source_local )
          )->a( n = `type`       v = `abap`
          )->a( n = `height`     v = `calc(100vh - 190px)`
          )->a( n = `width`      v = `100%`
          )->a( n = `editable`   v = `false`
          )->a( n = `colorTheme` v = COND #( WHEN mv_dark_theme = abap_true THEN `tomorrow_night` ELSE `tomorrow` ) ).
    ENDIF.

    " --- Local Test Classes ---
    DATA(t3) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Local Test Classes`
        )->a( n = `key`  v = `TST`
        )->a( n = `icon` v = `sap-icon://lab` ).
    DATA(c3) = t3->ele( `content` ).
    IF mv_edit_mode = abap_true.
      c3->tag( `TextArea`
          )->a( n = `value`   v = client->_bind( mv_source_test )
          )->a( n = `height`  v = `calc(100vh - 190px)`
          )->a( n = `width`   v = `100%`
          )->a( n = `growing` v = `false` ).
    ELSE.
      c3->tag( n = `CodeEditor` ns = `editor`
          )->a( n = `value`      v = client->_bind( mv_source_test )
          )->a( n = `type`       v = `abap`
          )->a( n = `height`     v = `calc(100vh - 190px)`
          )->a( n = `width`      v = `100%`
          )->a( n = `editable`   v = `false`
          )->a( n = `colorTheme` v = COND #( WHEN mv_dark_theme = abap_true THEN `tomorrow_night` ELSE `tomorrow` ) ).
    ENDIF.

    " --- Text Elements ---
    tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Text Elements`
        )->a( n = `key`  v = `TXT`
        )->a( n = `icon` v = `sap-icon://text`
        )->ele( `content`
            )->tag( n = `CodeEditor` ns = `editor`
                )->a( n = `value`    v = client->_bind( mv_text_elem )
                )->a( n = `type`     v = `text`
                )->a( n = `height`   v = `calc(100vh - 190px)`
                )->a( n = `width`    v = `100%`
                )->a( n = `editable` v = `false` ).

    " --- Documentation ---
    tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Documentation`
        )->a( n = `key`  v = `DOC`
        )->a( n = `icon` v = `sap-icon://document`
        )->ele( `content`
            )->tag( n = `CodeEditor` ns = `editor`
                )->a( n = `value`    v = client->_bind( mv_docu )
                )->a( n = `type`     v = `text`
                )->a( n = `height`   v = `calc(100vh - 190px)`
                )->a( n = `width`    v = `100%`
                )->a( n = `editable` v = `false` ).

    " --- Properties ---
    DATA(t4) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Properties`
        )->a( n = `key`  v = `INFO`
        )->a( n = `icon` v = `sap-icon://hint` ).
    DATA(info) = t4->ele( `content` ).

    IF mt_props IS NOT INITIAL.
      DATA(prop_list) = info->ele( `List`
          )->a( n = `headerText` v = `Properties`
          )->a( n = `items`      v = client->_bind( mt_props ) ).
      prop_list->ele( `items`
          )->ele( `DisplayListItem`
              )->a( n = `label` v = `{LABEL}`
              )->a( n = `value` v = `{VALUE}` ).
    ENDIF.

    IF mt_methods IS NOT INITIAL.
      DATA(meth_tab) = info->ele( `Table`
          )->a( n = `headerText` t = |Methods ({ lines( mt_methods ) })|
          )->a( n = `items`      v = client->_bind( mt_methods ) ).
      DATA(meth_cols) = meth_tab->ele( `columns` ).
      meth_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Method` ).
      meth_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Visibility` ).
      meth_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Type` ).
      meth_tab->ele( `items`
          )->ele( `ColumnListItem`
              )->ele( `cells`
                  )->tag( `Text` )->a( n = `text` v = `{CMPNAME}`
                  )->tag( `Text` )->a( n = `text` v = `{EXPOSURE}`
                  )->tag( `Text` )->a( n = `text` v = `{MTDTYPE}` ).
    ENDIF.

    IF mt_fields IS NOT INITIAL.
      DATA(fld_tab) = info->ele( `Table`
          )->a( n = `headerText` t = |Attributes ({ lines( mt_fields ) })|
          )->a( n = `items`      v = client->_bind( mt_fields ) ).
      DATA(fld_cols) = fld_tab->ele( `columns` ).
      fld_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Name` ).
      fld_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Key` ).
      fld_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Category` ).
      fld_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Type` ).
      fld_tab->ele( `items`
          )->ele( `ColumnListItem`
              )->ele( `cells`
                  )->tag( `Text` )->a( n = `text` v = `{NAME}`
                  )->tag( `Text` )->a( n = `text` v = `{KEYFLAG}`
                  )->tag( `Text` )->a( n = `text` v = `{TYPTYPE}`
                  )->tag( `Text` )->a( n = `text` v = `{TYPE}` ).
    ENDIF.

    " ===== Message list =====
    IF mt_log IS NOT INITIAL.
      DATA(log_panel) = col->ele( `Panel`
          )->a( n = `headerText` t = |Messages ({ lines( mt_log ) })|
          )->a( n = `expandable` v = `true`
          )->a( n = `expanded`   v = `true`
          )->a( n = `height`     v = `150px` ).
      DATA(log_list) = log_panel->ele( `List`
          )->a( n = `items` v = client->_bind( mt_log ) ).
      log_list->ele( `items`
          )->ele( `StandardListItem`
              )->a( n = `title`     v = `{MESSAGE}`
              )->a( n = `info`      v = `{LINE}`
              )->a( n = `icon`      v = `{ICON}`
              )->a( n = `infoState` v = `{TYPE}` ).
    ENDIF.

  ENDMETHOD.


  METHOD build_popup.

    " popup_display( ) expects a fragment definition as root element, exactly
    " like z2ui5_cl_xml_view=>factory_popup( ) produces it.
    DATA(popup) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(dialog) = popup->ele( n = `FragmentDefinition` ns = `core`
        )->a( n = `xmlns`      v = `sap.m`
        )->a( n = `xmlns:core` v = `sap.ui.core`
        )->ele( `Dialog`
            )->a( n = `title`         t = mv_popup_title
            )->a( n = `contentWidth`  v = `600px`
            )->a( n = `contentHeight` v = `400px` ).

    IF mt_usages IS NOT INITIAL.
      DATA(list) = dialog->ele( `List`
          )->a( n = `items` v = client->_bind( mt_usages ) ).
      list->ele( `items`
          )->ele( `StandardListItem`
              )->a( n = `title`       v = `{OBJ_NAME}`
              )->a( n = `description` v = `{OBJECT}`
              )->a( n = `type`        v = `Active`
              )->a( n = `press`       v = client->_event( val   = `USAGE_CLICK`
                                                          t_arg = VALUE #( ( `${OBJ_NAME}` ) ( `${OBJECT}` ) ) ) ).
    ELSE.
      dialog->tag( `MessageStrip`
          )->a( n = `text` v = `No usage found.`
          )->a( n = `type` v = `Information` ).
    ENDIF.

    dialog->ele( `endButton`
        )->tag( `Button`
            )->a( n = `text`  v = `Continue`
            )->a( n = `press` v = client->_event( `CLOSE_WHEREU` ) ).

    result = popup->stringify( ).

  ENDMETHOD.

ENDCLASS.
