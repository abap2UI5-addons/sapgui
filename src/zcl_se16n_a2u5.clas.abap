CLASS zcl_se16n_a2u5 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_max_cols    TYPE i VALUE 50.
    CONSTANTS c_default_max TYPE i VALUE 200.
    CONSTANTS c_max_cap     TYPE i VALUE 10000.

    " --- Step 1 ---
    DATA mv_table_name TYPE string.
    DATA mv_max_hits   TYPE string VALUE `200`.

    " --- Step 2: Field metadata ---
    TYPES: BEGIN OF ty_s_field,
             fname   TYPE string,
             label   TYPE string,
             ftype   TYPE string,
             col_id  TYPE string,
             visible TYPE abap_bool,
             sort    TYPE string,
             " The selection values are entered in the line of the field
             " itself, exactly like the selection criteria of SE16N.
             opt     TYPE string,
             low     TYPE string,
             high    TYPE string,
           END OF ty_s_field,
           ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH EMPTY KEY.
    DATA mt_fields TYPE ty_t_field.

    " --- Step 2: Selection criteria ---
    TYPES: BEGIN OF ty_s_crit,
             key   TYPE string,
             fname TYPE string,
             sign  TYPE string,
             opt   TYPE string,
             low   TYPE string,
             high  TYPE string,
           END OF ty_s_crit,
           ty_t_crit TYPE STANDARD TABLE OF ty_s_crit WITH EMPTY KEY.

    " --- Step 3: Result (fixed-width 50 string columns) ---
    TYPES: BEGIN OF ty_s_row,
             c01 TYPE string, c02 TYPE string, c03 TYPE string, c04 TYPE string, c05 TYPE string,
             c06 TYPE string, c07 TYPE string, c08 TYPE string, c09 TYPE string, c10 TYPE string,
             c11 TYPE string, c12 TYPE string, c13 TYPE string, c14 TYPE string, c15 TYPE string,
             c16 TYPE string, c17 TYPE string, c18 TYPE string, c19 TYPE string, c20 TYPE string,
             c21 TYPE string, c22 TYPE string, c23 TYPE string, c24 TYPE string, c25 TYPE string,
             c26 TYPE string, c27 TYPE string, c28 TYPE string, c29 TYPE string, c30 TYPE string,
             c31 TYPE string, c32 TYPE string, c33 TYPE string, c34 TYPE string, c35 TYPE string,
             c36 TYPE string, c37 TYPE string, c38 TYPE string, c39 TYPE string, c40 TYPE string,
             c41 TYPE string, c42 TYPE string, c43 TYPE string, c44 TYPE string, c45 TYPE string,
             c46 TYPE string, c47 TYPE string, c48 TYPE string, c49 TYPE string, c50 TYPE string,
           END OF ty_s_row,
           ty_t_row TYPE STANDARD TABLE OF ty_s_row WITH EMPTY KEY.
    DATA mt_rows       TYPE ty_t_row.

    " --- Status message ---
    DATA mv_command      TYPE string.

    " --- Value help suggestions ---
    TYPES: BEGIN OF ty_s_suggest,
             tabname TYPE string,
             ddtext  TYPE string,
           END OF ty_s_suggest,
           ty_t_suggest TYPE STANDARD TABLE OF ty_s_suggest WITH EMPTY KEY.
    DATA mt_suggestions TYPE ty_t_suggest.

    " --- Find in result list ---
    DATA mv_search     TYPE string.

    " --- Variants (persisted in ZSE16N_A2U5_VAR) ---
    TYPES: BEGIN OF ty_s_variant_list,
             id   TYPE string,
             name TYPE string,
           END OF ty_s_variant_list,
           ty_t_variant_list TYPE STANDARD TABLE OF ty_s_variant_list WITH EMPTY KEY.
    " payload that is stored as JSON in ZSE16N_A2U5_VAR-JSON_DATA
    TYPES: BEGIN OF ty_s_variant_data,
             table_name TYPE string,
             max_hits   TYPE string,
             fields     TYPE ty_t_field,
             criteria   TYPE ty_t_crit,
           END OF ty_s_variant_data.
    DATA mv_variant_name TYPE string.
    "! selectedKey of the "Get Variant" dropdown
    DATA mv_variant_sel  TYPE string.

  PROTECTED SECTION.
    " Step state: 1=table name, 2=selection screen, 3=result list
    DATA mv_step       TYPE i VALUE 1.
    DATA mt_crit TYPE ty_t_crit.
    DATA mv_total_rows TYPE i.
    DATA mv_message      TYPE string.
    DATA mv_message_type TYPE string VALUE `Information`.
    DATA mv_show_shell TYPE abap_bool VALUE abap_true.
    DATA mt_variant_list TYPE ty_t_variant_list.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_step_1.
    METHODS view_step_2.
    METHODS view_step_3.
    "! Selection screen of SE16N. The screen looks the same before and after
    "! the table metadata have been read - only the field list is filled.
    METHODS view_selection
      IMPORTING iv_loaded TYPE abap_bool.
    "! Derives the selection criteria from the values entered in the field
    "! lines of the selection screen. Called before every database read.
    METHODS crit_from_fields.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed in three
    "! places: after an unknown event, after a command-field message and -
    "! most importantly - when the transaction is navigated back to from
    "! another one, where the framework supplies no event at all.
    METHODS render.
    METHODS load_metadata.
    METHODS execute_query.
    METHODS search_tables
      IMPORTING iv_term TYPE string.
    "! one SQL condition for a single selection line (sign not evaluated here)
    METHODS build_condition
      IMPORTING is_crit       TYPE ty_s_crit
      RETURNING VALUE(result) TYPE string.
    "! complete WHERE clause - include lines of one field are OR-combined,
    "! exclude lines are negated, different fields are AND-combined
    METHODS build_where
      RETURNING VALUE(result) TYPE string.
    METHODS count_entries.
    METHODS variant_save.
    METHODS variant_load
      IMPORTING iv_id TYPE string.
    METHODS variant_delete
      IMPORTING iv_id TYPE string.
    METHODS variant_list_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se16n_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.
    IF client->check_on_init( ).
      view_step_1( ).
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 and handed control back to this
      " one. The framework supplies an EMPTY event here and check_on_init is
      " already false, so without this branch nothing would be rendered: the
      " response would carry no view and the browser would keep showing the
      " screen of the transaction that was just left - Back and F3 look dead.
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    " the command field and Back belong to the frame - they work the same
    " way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = client->get_event( )
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_message_type = ls_frame-msg_type.

    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_message.
      " the message of the command field belongs on the current screen
      render( ).
      RETURN.
    ENDIF.

    CASE client->get_event( ).

      WHEN `LOAD_METADATA`.
        load_metadata( ).
        IF mv_step = 2.
          variant_list_refresh( ).
          view_step_2( ).
        ELSE.
          view_step_1( ).
        ENDIF.

      WHEN `ADD_CRIT`.
        TRY.
            DATA(lv_uuid) = CONV string( cl_system_uuid=>create_uuid_c32_static( ) ).
          CATCH cx_uuid_error.
            lv_uuid = |{ sy-uzeit }{ lines( mt_crit ) }|.
        ENDTRY.
        APPEND VALUE #(
            key  = lv_uuid
            sign = `I`
            opt  = `EQ` ) TO mt_crit.

      WHEN `DEL_CRIT`.
        DATA(lv_key) = client->get_event_arg( ).
        DELETE mt_crit WHERE key = lv_key.

      WHEN `EXECUTE`.
        execute_query( ).
        IF mv_step = 3.
          view_step_3( ).
        ELSE.
          " re-render step 2 - the MessageStrip carries a static text and would
          " never appear with a plain view_model_update( )
          view_step_2( ).
        ENDIF.

      WHEN `COUNT`.
        count_entries( ).
        view_step_2( ).

      WHEN `SUGGEST`.
        DATA(lv_term) = client->get_event_arg( ).
        search_tables( lv_term ).

      WHEN `SEARCH_RESULT`.
        DATA(lv_search) = to_upper( mv_search ).
        " Re-read the data, then filter in the result list
        execute_query( ).
        IF mv_step <> 3.
          view_step_2( ).
          RETURN.
        ENDIF.
        IF lv_search IS NOT INITIAL.
          DATA lt_keep TYPE ty_t_row.
          LOOP AT mt_rows ASSIGNING FIELD-SYMBOL(<row>).
            DATA lv_found TYPE abap_bool.
            lv_found = abap_false.
            LOOP AT mt_fields ASSIGNING FIELD-SYMBOL(<sf>).
              ASSIGN COMPONENT <sf>-col_id OF STRUCTURE <row> TO FIELD-SYMBOL(<cv>).
              IF <cv> IS ASSIGNED AND <cv> CS lv_search.
                lv_found = abap_true.
                EXIT.
              ENDIF.
              UNASSIGN <cv>.
            ENDLOOP.
            IF lv_found = abap_true.
              APPEND <row> TO lt_keep.
            ENDIF.
          ENDLOOP.
          mt_rows       = lt_keep.
          mv_total_rows = lines( mt_rows ).
          mv_message      = |{ mv_total_rows } entries contain { lv_search }.|.
          mv_message_type = COND #( WHEN mv_total_rows = 0 THEN `Warning` ELSE `Success` ).
        ENDIF.
        view_step_3( ).

      WHEN `TOGGLE_SHELL`.
        mv_show_shell = xsdbool( mv_show_shell = abap_false ).
        view_step_3( ).

      WHEN `SAVE_VARIANT`.
        variant_save( ).
        view_step_2( ).

      WHEN `LOAD_VARIANT`.
        variant_load( mv_variant_sel ).
        view_step_2( ).

      WHEN `DEL_VARIANT`.
        variant_delete( mv_variant_sel ).
        view_step_2( ).

      WHEN `BACK_TO_INPUT`.
        CLEAR: mt_fields, mt_crit, mt_rows, mv_message, mv_total_rows, mv_search.
        mv_message_type = `Information`.
        mv_step         = 1.
        view_step_1( ).

      WHEN `BACK_TO_SEL`.
        mv_step = 2.
        CLEAR: mt_rows, mv_total_rows, mv_message, mv_search.
        view_step_2( ).

      WHEN OTHERS.
        render( ).

    ENDCASE.

  ENDMETHOD.


  METHOD render.

    CASE mv_step.
      WHEN 3.
        view_step_3( ).
      WHEN 2.
        view_step_2( ).
      WHEN OTHERS.
        view_step_1( ).
    ENDCASE.

  ENDMETHOD.


  METHOD view_step_1.

    " Before and after reading the metadata SE16N shows the same screen.
    view_selection( abap_false ).

  ENDMETHOD.


  METHOD view_step_2.

    view_selection( abap_true ).

  ENDMETHOD.


  METHOD crit_from_fields.

    CLEAR mt_crit.

    LOOP AT mt_fields ASSIGNING FIELD-SYMBOL(<f>).
      IF <f>-low IS INITIAL AND <f>-high IS INITIAL.
        CONTINUE.
      ENDIF.
      APPEND VALUE ty_s_crit(
          key   = <f>-fname
          fname = <f>-fname
          sign  = `I`
          opt   = COND string( WHEN <f>-opt IS INITIAL THEN `EQ` ELSE <f>-opt )
          low   = <f>-low
          high  = <f>-high ) TO mt_crit.
    ENDLOOP.

  ENDMETHOD.


  METHOD view_selection.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_message_type ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE string_table(
            ( `Table Display` ) ( `Edit` ) ( `Goto` ) ( `Extras` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = COND string( WHEN iv_loaded = abap_true
                                     THEN client->_event( `BACK_TO_INPUT` )
                                     ELSE client->_event_nav_app_leave( ) ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_parent = page
                                          iv_title  = `General Table Display` ).

    " Application function bar. Only the buttons that this app can serve are
    " active, the remaining ones are shown the way the SAP GUI shows them.
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE zcl_zlk05_gui_frame=>ty_t_button(
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Background - not available in this environment` )
            ( text = `Background` icon = ``
              tooltip = `Execute in background - not available in this environment` )
            ( text = `Number of Entries` icon = ``
              tooltip = COND string( WHEN iv_loaded = abap_true
                                     THEN `Number of Entries`
                                     ELSE `Number of Entries - enter a table first` )
              press   = COND string( WHEN iv_loaded = abap_true
                                     THEN client->_event( `COUNT` ) ) )
            ( sep = abap_true )
            ( icon = `sap-icon://multi-select` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Choose fields - use the Output column below` )
            ( icon = `sap-icon://table-view` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Select all fields - not available in this environment` )
            ( icon = `sap-icon://grid` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Deselect all fields - not available in this environment` )
            ( sep = abap_true )
            ( text = `All Entries` icon = ``
              tooltip = COND string( WHEN iv_loaded = abap_true
                                     THEN `Display all entries up to the maximum number of hits`
                                     ELSE `All Entries - enter a table first` )
              press   = COND string( WHEN iv_loaded = abap_true
                                     THEN client->_event( `EXECUTE` ) ) )
            ( sep = abap_true )
            ( icon = `sap-icon://zoom-out` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Delete selection criteria - clear the value fields` )
            ( icon = `sap-icon://zoom-in` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Selection criteria - not available in this environment` ) ) ).

    " ----- Work area: the classic dynpro selection screen -----
    DATA(work) = page->ele( `VBox`
        )->a( n = `class`  v = `sapUiSmallMargin`
        )->a( n = `height` v = zcl_zlk05_gui_frame=>c_work_height ).

    " Table
    DATA(row) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Table` ).
    DATA(tab_input) = row->ele( `Input`
        )->a( n = `id`              v = `idTableInput`
        )->a( n = `value`           v = client->_bind( mv_table_name )
        )->a( n = `width`           v = `17rem`
        )->a( n = `showSuggestion`  v = `true`
        )->a( n = `suggestionItems` v = client->_bind( mt_suggestions )
        )->a( n = `suggest`         v = client->_event(
                  val = `SUGGEST`
                  arg = `${$parameters>/suggestValue}` )
        )->a( n = `submit`          v = client->_event( `LOAD_METADATA` ) ).
    tab_input->ele( `suggestionItems`
        )->tag( n = `Item` ns = `core`
            )->a( n = `text`           v = `{TABNAME}`
            )->a( n = `additionalText` v = `{DDTEXT}` ).
    row->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://arrow-right`
        )->a( n = `size`    v = `1rem`
        )->a( n = `color`   v = zcl_zlk05_gui_frame=>c_yellow
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Read the table definition`
        )->a( n = `press`   v = client->_event( `LOAD_METADATA` ) ).
    row->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://search`
        )->a( n = `size`    v = `1rem`
        )->a( n = `color`   v = zcl_zlk05_gui_frame=>c_blue
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Search for a table - type a part of the name in the field` ).

    " Text Table / No Texts
    row = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Text Table` ).
    row->tag( `Input`
        )->a( n = `width`   v = `17rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Text table - not evaluated in this environment` ).
    row->tag( `CheckBox`
        )->a( n = `text`    v = `No Texts`
        )->a( n = `enabled` v = `false`
        )->a( n = `class`   v = `sapUiMediumMarginBegin`
        )->a( n = `tooltip` v = `No texts - not available in this environment` ).

    " Displ. Variant - here the variants of this app are maintained
    row = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Displ. Variant` ).
    row->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_variant_name )
        )->a( n = `width`       v = `9rem`
        )->a( n = `placeholder` v = `Variant`
        )->a( n = `tooltip`     v = `Name of the variant that is saved` ).
    row->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://save`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` v = `Save the selection as a variant`
        )->a( n = `press`   v = client->_event( `SAVE_VARIANT` ) ).
    DATA(var_sel) = row->ele( `Select`
        )->a( n = `width`       v = `13rem`
        )->a( n = `selectedKey` v = client->_bind( mv_variant_sel )
        )->a( n = `tooltip`     v = `Get variant`
        )->a( n = `change`      v = client->_event( `LOAD_VARIANT` ) ).
    DATA(var_items) = var_sel->ele( `items` ).
    var_items->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` v = `Get Variant...` ).
    LOOP AT mt_variant_list ASSIGNING FIELD-SYMBOL(<vl>).
      var_items->tag( n = `Item` ns = `core`
          )->a( n = `key`  t = <vl>-id
          )->a( n = `text` t = <vl>-name ).
    ENDLOOP.
    row->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://delete`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `tooltip` v = `Delete the selected variant`
        )->a( n = `press`   v = client->_event( `DEL_VARIANT` ) ).

    " Max. Number of Hits / Maintain Entries
    row = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Max. Number of Hits` ).
    row->tag( `Input`
        )->a( n = `value`   v = client->_bind( mv_max_hits )
        )->a( n = `width`   v = `6rem`
        )->a( n = `tooltip` t = |Default { c_default_max }, maximum { c_max_cap }| ).
    row->tag( `CheckBox`
        )->a( n = `text`    v = `Maintain Entries`
        )->a( n = `enabled` v = `false`
        )->a( n = `class`   v = `sapUiMediumMarginBegin`
        )->a( n = `tooltip` v = `Maintain entries - this app reads data only` ).

    " Get Field
    row = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Get Field` ).
    row->tag( `Input`
        )->a( n = `width`   v = `17rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Get field - not available in this environment` ).

    " ----- Selection Criteria -----
    work->tag( `Title`
        )->a( n = `text`  v = `Selection Criteria`
        )->a( n = `level` v = `H4`
        )->a( n = `class` v = `sapUiSmallMarginTop` ).

    DATA(scroll) = work->ele( `ScrollContainer`
        )->a( n = `width`    v = `100%`
        )->a( n = `height`   v = `calc(100vh - 27rem)`
        )->a( n = `vertical` v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(crit) = scroll->ele( `Table`
        )->a( n = `items`      v = client->_bind( mt_fields )
        )->a( n = `sticky`     v = `ColumnHeaders`
        )->a( n = `noDataText` v = `Enter a table name and choose Continue` ).

    DATA(cols) = crit->ele( `columns` ).
    cols->ele( `Column` )->a( n = `width` v = `14rem`
        )->tag( `Text` )->a( n = `text` v = `Fld Name` ).
    cols->ele( `Column` )->a( n = `width` v = `7rem`
        )->tag( `Text` )->a( n = `text` v = `O.` ).
    cols->ele( `Column` )->a( n = `width` v = `11rem`
        )->tag( `Text` )->a( n = `text` v = `Frm-Val.` ).
    cols->ele( `Column` )->a( n = `width` v = `11rem`
        )->tag( `Text` )->a( n = `text` v = `To-Value` ).
    cols->ele( `Column` )->a( n = `width` v = `4rem`
        )->tag( `Text` )->a( n = `text` v = `More` ).
    cols->ele( `Column` )->a( n = `width` v = `5rem`
        )->tag( `Text` )->a( n = `text` v = `Output` ).
    cols->ele( `Column` )->a( n = `width` v = `11rem`
        )->tag( `Text` )->a( n = `text` v = `Technical Name` ).
    cols->ele( `Column` )->a( n = `width` v = `8rem`
        )->tag( `Text` )->a( n = `text` v = `Sort` ).

    DATA(cells) = crit->ele( `items`
        )->ele( `ColumnListItem`
        )->ele( `cells` ).

    cells->tag( `Text` )->a( n = `text` v = `{LABEL}` ).

    DATA(opt_sel) = cells->ele( `Select`
        )->a( n = `selectedKey` v = `{OPT}`
        )->a( n = `width`       v = `6.5rem`
        )->a( n = `tooltip`     v = `Selection option` ).
    DATA(opt_items) = opt_sel->ele( `items` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `EQ` )->a( n = `text` v = `=` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `NE` )->a( n = `text` v = `<>` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `BT` )->a( n = `text` v = `Between` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `CP` )->a( n = `text` v = `Pattern` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `GT` )->a( n = `text` v = `>` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `LT` )->a( n = `text` v = `<` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `GE` )->a( n = `text` v = `>=` ).
    opt_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `LE` )->a( n = `text` v = `<=` ).

    cells->tag( `Input` )->a( n = `value` v = `{LOW}` ).
    cells->tag( `Input` )->a( n = `value` v = `{HIGH}` ).

    cells->tag( `Button`
        )->a( n = `icon`    v = `sap-icon://multiselect-all`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Multiple selection - not available in this environment` ).

    cells->tag( `CheckBox` )->a( n = `selected` v = `{VISIBLE}` ).
    cells->tag( `Text`     )->a( n = `text`     v = `{FNAME}` ).

    " The sort column is not part of the original screen. It is kept here
    " because this app has no sortable ALV grid.
    DATA(sort_sel) = cells->ele( `Select`
        )->a( n = `selectedKey` v = `{SORT}`
        )->a( n = `width`       v = `7rem` ).
    DATA(sort_items) = sort_sel->ele( `items` ).
    sort_items->tag( n = `Item` ns = `core` )->a( n = `key` v = ``  )->a( n = `text` v = `` ).
    sort_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `A` )->a( n = `text` v = `Ascending` ).
    sort_items->tag( n = `Item` ns = `core` )->a( n = `key` v = `D` )->a( n = `text` v = `Descending` ).

    " The cursor sits in the table field, exactly like the SAP GUI
    IF iv_loaded = abap_false.
      client->follow_up_action(
          val   = client->cs_event-set_focus
          t_arg = VALUE #( ( `idTableInput` ) ) ).
    ENDIF.

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = COND string( WHEN iv_loaded = abap_true
                                       THEN `BACK_TO_INPUT`
                                       ELSE zcl_zlk05_gui_frame=>c_ev_back )
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_step_3.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_message_type ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE string_table(
            ( `Table Entry` ) ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_SEL` ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = |{ to_upper( mv_table_name ) }: Display of Entries Found| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE zcl_zlk05_gui_frame=>ty_t_button(
            ( icon = `sap-icon://refresh` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Refresh`
              press   = client->_event( `EXECUTE` ) )
            ( icon = `sap-icon://wrench` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Settings - not available in this environment` )
            ( icon = `sap-icon://group-2` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Check table - not available in this environment` )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Technical information - not available in this environment` ) ) ).

    " ----- Work area -----
    DATA(work) = page->ele( `VBox`
        )->a( n = `class`  v = `sapUiSmallMargin`
        )->a( n = `height` v = zcl_zlk05_gui_frame=>c_work_height ).

    DATA(row) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Search in Table` ).
    row->tag( `Text` )->a( n = `text` v = to_upper( mv_table_name ) ).

    row = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Number of Hits` ).
    row->tag( `Text` )->a( n = `text` t = |{ mv_total_rows }| ).

    row = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Runtime` ).
    row->tag( `Text`
        )->a( n = `text`    v = `0`
        )->a( n = `tooltip` v = `Runtime is not measured in this environment` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Maximum No. of Hits`
                                    iv_width  = `13rem` ).
    row->tag( `Input`
        )->a( n = `value` v = client->_bind( mv_max_hits )
        )->a( n = `width` v = `6rem` ).

    row = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Insert Column` ).
    row->tag( `Input`
        )->a( n = `width`   v = `17rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Insert column - use the Output column of the selection screen` ).

    " ----- ALV grid toolbar -----
    DATA(alv_bar) = work->ele( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `2.1rem` ).

    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( icon = `sap-icon://table-view` color = zcl_zlk05_gui_frame=>c_blue
                             tooltip = `Choose layout - not available in this environment` ) ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( icon = `sap-icon://sort` color = zcl_zlk05_gui_frame=>c_blue
                             tooltip = `Sort - use the Sort column of the selection screen` ) ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( icon = `sap-icon://filter` color = zcl_zlk05_gui_frame=>c_blue
                             tooltip = `Filter - use the selection criteria` ) ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( sep = abap_true ) ).

    " Find - the SAP GUI opens a dialog here, the field is shown directly
    alv_bar->tag( n = `Icon` ns = `core`
        )->a( n = `src`   v = `sap-icon://search`
        )->a( n = `size`  v = `1.05rem`
        )->a( n = `color` v = zcl_zlk05_gui_frame=>c_blue
        )->a( n = `class` v = `sapUiTinyMarginEnd`
        )->a( n = `tooltip` v = `Find` ).
    alv_bar->tag( `SearchField`
        )->a( n = `value`       v = client->_bind( mv_search )
        )->a( n = `placeholder` v = `Find in entries`
        )->a( n = `width`       v = `15rem`
        )->a( n = `search`      v = client->_event( `SEARCH_RESULT` ) ).

    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( sep = abap_true ) ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
                             tooltip = `Print - not available in this environment` ) ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #( icon = `sap-icon://excel-attachment` color = zcl_zlk05_gui_frame=>c_grey
                             tooltip = `Export - not available in this environment` ) ).

    alv_bar->tag( `ToolbarSpacer` ).

    alv_bar->tag( `Text` )->a( n = `text` t = |{ mv_total_rows } Entries| ).
    alv_bar->tag( `ToolbarSeparator` ).
    zcl_zlk05_gui_frame=>add_button( io_bar = alv_bar
        is_button = VALUE #(
            icon    = COND string( WHEN mv_show_shell = abap_true
                                   THEN `sap-icon://full-screen`
                                   ELSE `sap-icon://exit-full-screen` )
            color   = zcl_zlk05_gui_frame=>c_blue
            tooltip = `Full screen on/off`
            press   = client->_event( `TOGGLE_SHELL` ) ) ).

    " ----- ALV grid -----
    " Which fields have to be displayed
    DATA(lv_any_visible) = abap_false.
    LOOP AT mt_fields TRANSPORTING NO FIELDS WHERE visible = abap_true.
      lv_any_visible = abap_true.
      EXIT.
    ENDLOOP.

    " sap.ui.table.Table gives an ALV like grid with horizontal scrolling.
    " visibleRowCountMode=Auto fills the available height - a visibleRowCount
    " must NOT be supplied in addition.
    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `xmlns:table`         v = `sap.ui.table`
        )->a( n = `rows`                v = client->_bind( mt_rows )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `None`
        )->a( n = `rowHeight`           v = `28`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(grid_cols) = grid->ele( n = `columns` ns = `table` ).
    LOOP AT mt_fields ASSIGNING FIELD-SYMBOL(<col>).
      IF lv_any_visible = abap_true AND <col>-visible = abap_false.
        CONTINUE.
      ENDIF.
      DATA(grid_col) = grid_cols->ele( n = `Column` ns = `table`
          )->a( n = `width`          v = `8rem`
          )->a( n = `sortProperty`   t = <col>-col_id
          )->a( n = `filterProperty` t = <col>-col_id ).
      grid_col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = <col>-fname ).
      grid_col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ <col>-col_id }\}|
              )->a( n = `wrapping` v = `false` ).
    ENDLOOP.

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_SEL`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD load_metadata.

    DATA: lo_struct    TYPE REF TO cl_abap_structdescr,
          lo_table     TYPE REF TO cl_abap_tabledescr,
          lo_typedescr TYPE REF TO cl_abap_typedescr.

    CLEAR: mt_fields, mt_crit, mt_rows, mv_message.
    mv_total_rows = 0.

    CONDENSE mv_table_name NO-GAPS.
    mv_table_name = to_upper( mv_table_name ).

    IF mv_table_name IS INITIAL.
      mv_message      = `Enter a table name.`.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.

    TRY.
        lo_typedescr = cl_abap_typedescr=>describe_by_name( mv_table_name ).
        CASE lo_typedescr->kind.
          WHEN cl_abap_typedescr=>kind_table.
            lo_table  ?= lo_typedescr.
            lo_struct ?= lo_table->get_table_line_type( ).
          WHEN cl_abap_typedescr=>kind_struct.
            lo_struct ?= lo_typedescr.
          WHEN OTHERS.
            mv_message      = |{ mv_table_name } is not a table or a structure.|.
            mv_message_type = `Error`.
            RETURN.
        ENDCASE.
      CATCH cx_root INTO DATA(lx).
        mv_message      = |Table { mv_table_name } does not exist: { lx->get_text( ) }|.
        mv_message_type = `Error`.
        RETURN.
    ENDTRY.

    " get_ddic_field_list flattens includes and supplies the field labels.
    " Careful: the method raises CLASSIC exceptions (not_found / no_ddic_type).
    " A TRY / CATCH cx_root does NOT catch those - a non DDIC type would end in
    " a runtime abortion instead of reaching the RTTI fallback.
    DATA lv_idx  TYPE i.
    DATA lt_ddic TYPE ddfields.
    lo_struct->get_ddic_field_list(
      RECEIVING  p_field_list = lt_ddic
      EXCEPTIONS not_found    = 1
                 no_ddic_type = 2
                 OTHERS       = 3 ).

    IF sy-subrc = 0.
      LOOP AT lt_ddic ASSIGNING FIELD-SYMBOL(<dd>).
        IF <dd>-fieldname CP `.INCLU*`.
          CONTINUE.
        ENDIF.
        lv_idx = lv_idx + 1.
        IF lv_idx > c_max_cols.
          EXIT.
        ENDIF.
        DATA(lv_label) = COND string(
            WHEN <dd>-scrtext_m IS NOT INITIAL THEN <dd>-scrtext_m
            WHEN <dd>-scrtext_s IS NOT INITIAL THEN <dd>-scrtext_s
            WHEN <dd>-fieldtext IS NOT INITIAL THEN <dd>-fieldtext
            ELSE <dd>-fieldname ).
        APPEND VALUE #(
            fname   = <dd>-fieldname
            label   = |{ <dd>-fieldname } ({ lv_label })|
            ftype   = |{ <dd>-datatype }({ <dd>-leng })|
            col_id  = |C{ lv_idx WIDTH = 2 PAD = '0' ALIGN = RIGHT }|
            visible = abap_true
            sort    = ``
            opt     = `EQ` ) TO mt_fields.
      ENDLOOP.
    ELSE.
      " Fallback for non-DDIC types: flatten the includes manually
      DATA(lt_comp) = lo_struct->get_components( ).
      LOOP AT lt_comp ASSIGNING FIELD-SYMBOL(<comp>).
        IF <comp>-type IS NOT BOUND.
          CONTINUE.
        ENDIF.
        IF <comp>-type->kind = cl_abap_typedescr=>kind_struct.
          DATA(lo_nested) = CAST cl_abap_structdescr( <comp>-type ).
          LOOP AT lo_nested->get_components( ) ASSIGNING FIELD-SYMBOL(<nc>).
            lv_idx = lv_idx + 1.
            IF lv_idx > c_max_cols.
              EXIT.
            ENDIF.
            APPEND VALUE #(
                fname   = <nc>-name
                label   = <nc>-name
                ftype   = COND #( WHEN <nc>-type IS BOUND THEN <nc>-type->absolute_name ELSE `?` )
                col_id  = |C{ lv_idx WIDTH = 2 PAD = '0' ALIGN = RIGHT }|
                visible = abap_true
                sort    = ``
                opt     = `EQ` ) TO mt_fields.
          ENDLOOP.
        ELSE.
          lv_idx = lv_idx + 1.
          IF lv_idx > c_max_cols.
            EXIT.
          ENDIF.
          APPEND VALUE #(
              fname   = <comp>-name
              label   = <comp>-name
              ftype   = <comp>-type->absolute_name
              col_id  = |C{ lv_idx WIDTH = 2 PAD = '0' ALIGN = RIGHT }|
              visible = abap_true
              sort    = ``
              opt     = `EQ` ) TO mt_fields.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF mt_fields IS INITIAL.
      mv_message      = |No fields found for { mv_table_name }.|.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.

    mv_message = |{ lines( mt_fields ) } fields read. Maintain the selection criteria and choose Execute.|.
    mv_message_type = `Success`.
    mv_step         = 2.

  ENDMETHOD.


  METHOD build_condition.

    DATA(lv_low) = is_crit-low.
    REPLACE ALL OCCURRENCES OF `'` IN lv_low WITH `''`.

    CASE is_crit-opt.
      WHEN `EQ`.
        result = |{ is_crit-fname } = '{ lv_low }'|.
      WHEN `NE`.
        result = |{ is_crit-fname } <> '{ lv_low }'|.
      WHEN `GT`.
        result = |{ is_crit-fname } > '{ lv_low }'|.
      WHEN `GE`.
        result = |{ is_crit-fname } >= '{ lv_low }'|.
      WHEN `LT`.
        result = |{ is_crit-fname } < '{ lv_low }'|.
      WHEN `LE`.
        result = |{ is_crit-fname } <= '{ lv_low }'|.
      WHEN `CP`.
        DATA(lv_like) = lv_low.
        REPLACE ALL OCCURRENCES OF `*` IN lv_like WITH `%`.
        REPLACE ALL OCCURRENCES OF `+` IN lv_like WITH `_`.
        result = |{ is_crit-fname } LIKE '{ lv_like }'|.
      WHEN `BT`.
        DATA(lv_high) = is_crit-high.
        REPLACE ALL OCCURRENCES OF `'` IN lv_high WITH `''`.
        result = |{ is_crit-fname } BETWEEN '{ lv_low }' AND '{ lv_high }'|.
      WHEN OTHERS.
        result = |{ is_crit-fname } = '{ lv_low }'|.
    ENDCASE.

  ENDMETHOD.


  METHOD build_where.

    DATA lt_field TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_and   TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_incl  TYPE STANDARD TABLE OF string WITH EMPTY KEY.
    DATA lt_excl  TYPE STANDARD TABLE OF string WITH EMPTY KEY.

    " distinct field names in the order of the selection screen
    LOOP AT mt_crit ASSIGNING FIELD-SYMBOL(<c>) WHERE fname IS NOT INITIAL.
      IF <c>-low IS INITIAL AND <c>-high IS INITIAL.
        CONTINUE.
      ENDIF.
      IF NOT line_exists( lt_field[ table_line = <c>-fname ] ).
        APPEND <c>-fname TO lt_field.
      ENDIF.
    ENDLOOP.

    LOOP AT lt_field INTO DATA(lv_fname).
      CLEAR: lt_incl, lt_excl.
      LOOP AT mt_crit ASSIGNING <c> WHERE fname = lv_fname.
        IF <c>-low IS INITIAL AND <c>-high IS INITIAL.
          CONTINUE.
        ENDIF.
        DATA(lv_cond) = build_condition( <c> ).
        IF lv_cond IS INITIAL.
          CONTINUE.
        ENDIF.
        IF <c>-sign = `E`.
          APPEND lv_cond TO lt_excl.
        ELSE.
          APPEND lv_cond TO lt_incl.
        ENDIF.
      ENDLOOP.
      IF lt_incl IS NOT INITIAL.
        APPEND |( { concat_lines_of( table = lt_incl sep = ` OR ` ) } )| TO lt_and.
      ENDIF.
      IF lt_excl IS NOT INITIAL.
        APPEND |NOT ( { concat_lines_of( table = lt_excl sep = ` OR ` ) } )| TO lt_and.
      ENDIF.
    ENDLOOP.

    IF lt_and IS INITIAL.
      result = `1 = 1`.
    ELSE.
      result = concat_lines_of( table = lt_and sep = ` AND ` ).
    ENDIF.

  ENDMETHOD.


  METHOD count_entries.

    CLEAR mv_message.

    IF mv_table_name IS INITIAL.
      mv_message      = `Enter a table name.`.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.

    " Exactly the same WHERE clause as Execute, so that the number of entries
    " always matches the result list.
    crit_from_fields( ).
    DATA(lv_where) = build_where( ).
    DATA lv_count TYPE i.

    TRY.
        SELECT COUNT(*) FROM (mv_table_name) WHERE (lv_where) INTO @lv_count.
        mv_message      = |Number of entries: { lv_count }|.
        mv_message_type = `Success`.
      CATCH cx_root INTO DATA(lx).
        mv_message      = |Number of entries could not be determined: { lx->get_text( ) }|.
        mv_message_type = `Error`.
    ENDTRY.

  ENDMETHOD.


  METHOD execute_query.

    DATA: lr_data TYPE REF TO data,
          lv_max  TYPE i.

    CLEAR: mt_rows, mv_message.
    mv_total_rows = 0.

    crit_from_fields( ).
    DATA(lv_where) = build_where( ).

    " Maximum number of hits
    TRY.
        lv_max = mv_max_hits.
      CATCH cx_root.
        lv_max = c_default_max.
    ENDTRY.
    IF lv_max <= 0.
      lv_max = c_default_max.
    ENDIF.
    IF lv_max > c_max_cap.
      lv_max = c_max_cap.
    ENDIF.

    " Sort order
    DATA lt_order TYPE string_table.
    LOOP AT mt_fields ASSIGNING FIELD-SYMBOL(<sf>) WHERE sort = 'A' OR sort = 'D'.
      APPEND |{ <sf>-fname } { COND #( WHEN <sf>-sort = 'A' THEN `ASCENDING` ELSE `DESCENDING` ) }| TO lt_order.
    ENDLOOP.
    DATA(lv_order) = concat_lines_of( table = lt_order sep = `, ` ).

    TRY.
        CREATE DATA lr_data TYPE STANDARD TABLE OF (mv_table_name) WITH EMPTY KEY.
        ASSIGN lr_data->* TO FIELD-SYMBOL(<lt_data>).

        IF lv_order IS INITIAL.
          SELECT * FROM (mv_table_name) WHERE (lv_where)
            INTO TABLE @<lt_data> UP TO @lv_max ROWS.
        ELSE.
          SELECT * FROM (mv_table_name) WHERE (lv_where) ORDER BY (lv_order)
            INTO TABLE @<lt_data> UP TO @lv_max ROWS.
        ENDIF.
      CATCH cx_root INTO DATA(lx).
        mv_message      = |Selection could not be executed: { lx->get_text( ) }|.
        mv_message_type = `Error`.
        RETURN.
    ENDTRY.

    mv_total_rows = lines( <lt_data> ).

    " Map the result to the fixed-width string structure
    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<ls_row>).
      DATA ls_out TYPE ty_s_row.
      CLEAR ls_out.
      LOOP AT mt_fields ASSIGNING FIELD-SYMBOL(<fld>).
        ASSIGN COMPONENT <fld>-fname  OF STRUCTURE <ls_row> TO FIELD-SYMBOL(<val>).
        ASSIGN COMPONENT <fld>-col_id OF STRUCTURE ls_out   TO FIELD-SYMBOL(<dst>).
        IF <val> IS ASSIGNED AND <dst> IS ASSIGNED.
          <dst> = |{ <val> }|.
        ENDIF.
        UNASSIGN: <val>, <dst>.
      ENDLOOP.
      APPEND ls_out TO mt_rows.
    ENDLOOP.

    mv_step         = 3.
    mv_message      = |{ mv_total_rows } entries read (maximum { lv_max }).|.
    mv_message_type = COND #( WHEN mv_total_rows = 0 THEN `Warning` ELSE `Success` ).

  ENDMETHOD.


  METHOD search_tables.

    CLEAR mt_suggestions.
    IF iv_term IS INITIAL OR strlen( iv_term ) < 2.
      RETURN.
    ENDIF.

    DATA(lv_pattern) = |{ to_upper( iv_term ) }%|.

    SELECT dd~tabname, dt~ddtext
      FROM dd02l AS dd
      LEFT OUTER JOIN dd02t AS dt
        ON dt~tabname    = dd~tabname
       AND dt~ddlanguage = @sy-langu
       AND dt~as4local   = 'A'
      WHERE dd~tabname  LIKE @lv_pattern
        AND dd~as4local = 'A'
        AND dd~tabclass IN ( 'TRANSP', 'VIEW', 'CLUSTER', 'POOL' )
      ORDER BY dd~tabname
      INTO TABLE @DATA(lt_result)
      UP TO 20 ROWS.

    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<r>).
      APPEND VALUE #(
          tabname = <r>-tabname
          ddtext  = COND #( WHEN <r>-ddtext IS NOT INITIAL THEN <r>-ddtext ELSE <r>-tabname )
      ) TO mt_suggestions.
    ENDLOOP.

  ENDMETHOD.


  METHOD variant_save.

    mv_variant_name = condense( mv_variant_name ).

    IF mv_variant_name IS INITIAL.
      mv_message      = `Enter a variant name.`.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.
    IF mv_table_name IS INITIAL.
      mv_message      = `No table selected.`.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.

    " FIELDS already carries the selection values. CRITERIA is filled as well
    " so that a variant can still be read by an older version of this app.
    crit_from_fields( ).

    DATA(ls_payload) = VALUE ty_s_variant_data(
        table_name = mv_table_name
        max_hits   = mv_max_hits
        fields     = mt_fields
        criteria   = mt_crit ).

    DATA lv_json TYPE string.
    TRY.
        " abap2ui5lint-disable-next-line non-released-api -- the stored variants are in this format, see README
        lv_json = z2ui5_cl_util=>json_stringify( ls_payload ).
      CATCH cx_root INTO DATA(lx_json).
        mv_message      = |Variant could not be serialized: { lx_json->get_text( ) }|.
        mv_message_type = `Error`.
        RETURN.
    ENDTRY.

    DATA ls_db TYPE zse16n_a2u5_var.
    DATA lv_tab  TYPE zse16n_a2u5_var-table_name.
    DATA lv_name TYPE zse16n_a2u5_var-variant_name.
    lv_tab  = mv_table_name.
    lv_name = mv_variant_name.

    " Saving under an existing name overwrites that variant
    SELECT SINGLE variant_id FROM zse16n_a2u5_var
      WHERE uname        = @sy-uname
        AND table_name   = @lv_tab
        AND variant_name = @lv_name
      INTO @ls_db-variant_id.
    IF sy-subrc <> 0.
      TRY.
          ls_db-variant_id = cl_system_uuid=>create_uuid_c32_static( ).
        CATCH cx_uuid_error.
          ls_db-variant_id = |{ sy-datum }{ sy-uzeit }{ sy-tabix }|.
      ENDTRY.
    ENDIF.

    ls_db-uname        = sy-uname.
    ls_db-table_name   = lv_tab.
    ls_db-variant_name = lv_name.
    ls_db-json_data    = lv_json.
    GET TIME STAMP FIELD ls_db-created_at.

    MODIFY zse16n_a2u5_var FROM @ls_db.
    IF sy-subrc = 0.
      " The abap2UI5 request handler rolls back every non-sticky LUW after the
      " round trip, so the variant has to be committed explicitly.
      COMMIT WORK AND WAIT.
      mv_variant_sel  = CONV string( ls_db-variant_id ).
      mv_message      = |Variant { mv_variant_name } saved.|.
      mv_message_type = `Success`.
    ELSE.
      ROLLBACK WORK.
      mv_message      = |Variant { mv_variant_name } could not be saved.|.
      mv_message_type = `Error`.
    ENDIF.

    variant_list_refresh( ).

  ENDMETHOD.


  METHOD variant_load.

    IF iv_id IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_id TYPE zse16n_a2u5_var-variant_id.
    lv_id = iv_id.

    SELECT SINGLE variant_name, json_data FROM zse16n_a2u5_var
      WHERE variant_id = @lv_id
        AND uname      = @sy-uname
      INTO @DATA(ls_db).
    IF sy-subrc <> 0.
      mv_message      = `Variant does not exist.`.
      mv_message_type = `Error`.
      RETURN.
    ENDIF.

    DATA ls_payload TYPE ty_s_variant_data.
    TRY.
        z2ui5_cl_util=>json_parse(
          EXPORTING val  = ls_db-json_data
          CHANGING  data = ls_payload ).
      CATCH cx_root INTO DATA(lx).
        mv_message      = |Variant could not be read: { lx->get_text( ) }|.
        mv_message_type = `Error`.
        RETURN.
    ENDTRY.

    IF ls_payload-table_name IS INITIAL.
      mv_message      = `Variant contains no data.`.
      mv_message_type = `Warning`.
      RETURN.
    ENDIF.

    mv_table_name   = ls_payload-table_name.
    mv_max_hits     = ls_payload-max_hits.
    mt_fields       = ls_payload-fields.
    mt_crit         = ls_payload-criteria.

    " Variants saved before the selection values moved into the field lines
    " carry their values in CRITERIA - move them over so they stay visible.
    LOOP AT mt_crit ASSIGNING FIELD-SYMBOL(<vc>) WHERE fname IS NOT INITIAL.
      ASSIGN mt_fields[ fname = <vc>-fname ] TO FIELD-SYMBOL(<vf>).
      IF sy-subrc <> 0 OR ( <vf>-low IS NOT INITIAL OR <vf>-high IS NOT INITIAL ).
        CONTINUE.
      ENDIF.
      <vf>-opt  = <vc>-opt.
      <vf>-low  = <vc>-low.
      <vf>-high = <vc>-high.
    ENDLOOP.
    mv_variant_name = CONV string( ls_db-variant_name ).
    CLEAR: mt_rows, mv_total_rows.
    mv_step         = 2.
    mv_message      = |Variant { mv_variant_name } loaded.|.
    mv_message_type = `Success`.

  ENDMETHOD.


  METHOD variant_delete.

    IF iv_id IS INITIAL.
      mv_message      = `Choose a variant first.`.
      mv_message_type = `Warning`.
      RETURN.
    ENDIF.

    DATA lv_id TYPE zse16n_a2u5_var-variant_id.
    lv_id = iv_id.

    DELETE FROM zse16n_a2u5_var
      WHERE variant_id = @lv_id
        AND uname      = @sy-uname.
    IF sy-subrc = 0.
      COMMIT WORK AND WAIT.
      mv_message      = `Variant deleted.`.
      mv_message_type = `Success`.
      CLEAR mv_variant_sel.
    ELSE.
      ROLLBACK WORK.
      mv_message      = `Variant does not exist.`.
      mv_message_type = `Error`.
    ENDIF.

    variant_list_refresh( ).

  ENDMETHOD.


  METHOD variant_list_refresh.

    CLEAR mt_variant_list.

    IF mv_table_name IS INITIAL.
      RETURN.
    ENDIF.

    DATA lv_tab TYPE zse16n_a2u5_var-table_name.
    lv_tab = mv_table_name.

    SELECT variant_id, variant_name
      FROM zse16n_a2u5_var
      WHERE uname      = @sy-uname
        AND table_name = @lv_tab
      ORDER BY variant_name
      INTO TABLE @DATA(lt_db).

    LOOP AT lt_db ASSIGNING FIELD-SYMBOL(<db>).
      APPEND VALUE #(
          id   = <db>-variant_id
          name = <db>-variant_name
      ) TO mt_variant_list.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
