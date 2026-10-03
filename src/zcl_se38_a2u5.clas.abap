CLASS zcl_se38_a2u5 DEFINITION PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.
    INTERFACES zif_zlk05_start_params.

    DATA mv_progname TYPE string.
    DATA mv_source   TYPE string.
    DATA mv_command   TYPE string.
    DATA mt_programs TYPE zcl_zlk05_sys_api=>ty_t_program.

  PROTECTED SECTION.
    DATA mv_mode     TYPE string.
    DATA mv_current  TYPE string.
    DATA mv_message   TYPE string.
    DATA mv_msgtype  TYPE string.
    "! Program handed over by another transaction (ST22 ...). SE38 then
    "! opens it directly, and Back returns to the calling transaction.
    DATA mv_start_program TYPE string.
    DATA mv_called        TYPE abap_bool.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_source.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed twice:
    "! after an event that only changed the mode, and - most importantly -
    "! when the transaction is navigated back to from another one, where the
    "! framework supplies no event at all.
    METHODS render.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_name TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se38_a2u5 IMPLEMENTATION.

  METHOD zif_zlk05_start_params~set_start_params.
    mv_start_program = to_upper( condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_program ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      IF mv_start_program IS NOT INITIAL.
        mv_progname = mv_start_program.
        mv_called   = abap_true.
        do_open( mv_start_program ).
      ENDIF.
      render( ).
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 / the Back arrow and handed
      " control back to this one. The framework supplies an EMPTY event here
      " and check_on_init is already false, so without this branch nothing
      " would be rendered: the response would carry no view and the browser
      " would keep showing the screen of the transaction that was just left.
      " That is what made Back look dead and F3 only work on the second try.
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get_event( ).
    DATA(lv_arg)   = client->get_event_arg( ).
    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = lv_event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE lv_event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        IF lv_arg IS NOT INITIAL.
          do_open( lv_arg ).
        ENDIF.
      WHEN 'DISPLAY_DIRECT'.
        IF mv_progname IS NOT INITIAL.
          do_open( to_upper( condense( mv_progname ) ) ).
        ENDIF.
      WHEN 'BACK_TO_LIST'.
        " opened from another transaction: Back goes back there, the way
        " the SAP GUI returns from CALL TRANSACTION
        IF mv_called = abap_true.
          client->nav_app_leave( ).
          RETURN.
        ENDIF.
        mv_mode = `LIST`.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.

  METHOD render.

    IF mv_mode = `SOURCE`.
      view_source( ).
    ELSE.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_programs.
    mt_programs = zcl_zlk05_sys_api=>search_programs( mv_progname ).
    mv_mode     = `LIST`.

    IF lines( mt_programs ) = 0.
      mv_message = `No programs found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_programs ) } program(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mv_source.

    " S_DEVELOP display for the concrete program - the generic check of
    " the transaction only says that the user may use the editor at all
    DATA(ls_auth) = zcl_zlk05_auth=>check_program_display( iv_name ).
    IF ls_auth-allowed = abap_false.
      mv_message = ls_auth-message.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    mv_current = iv_name.
    mv_source  = zcl_zlk05_sys_api=>get_program_source( iv_name ).

    IF mv_source IS INITIAL.
      mv_message = |Program { iv_name } has no source code.|.
      mv_msgtype = `Warning`.
      RETURN.
    ENDIF.

    mv_mode = `SOURCE`.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE string_table(
            ( `Program` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
            ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client io_parent = page
                                          iv_title  = `ABAP Editor: Initial Screen` ).

    " Application function bar. This app reads the repository, so none of
    " the editor functions can be served - they are shown the SAP GUI way.
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE zcl_zlk05_gui_frame=>ty_t_button(
            ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Other object - not available in this environment` )
            ( icon = `sap-icon://wrench` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Wizard - not available in this environment` )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Execute - programs cannot be started from here` )
            ( icon = `sap-icon://outbox` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Where-used list - not available in this environment` )
            ( icon = `sap-icon://org-chart` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Object list - not available in this environment` )
            ( icon = `sap-icon://hint` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Information - not available in this environment` )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Delete - this app never changes the repository` )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Copy - this app never changes the repository` )
            ( icon = `sap-icon://text-formatting` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Rename - this app never changes the repository` )
            ( sep = abap_true )
            ( text = `Debugging` icon = `sap-icon://detail-view`
              tooltip = `Debugging - not available in this environment` )
            ( text = `With Variant` icon = `sap-icon://history`
              tooltip = `Execute with variant - not available in this environment` )
            ( text = `Variants` icon = `sap-icon://copy`
              tooltip = `Variants - not available in this environment` ) ) ).

    " ----- Work area: the SE38 initial dynpro -----
    DATA(work) = page->ele( `VBox`
        )->a( n = `class`  v = `sapUiSmallMargin`
        )->a( n = `height` v = zcl_zlk05_gui_frame=>c_work_height ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Program` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idProgName`
        )->a( n = `value`       v = client->_bind( mv_progname )
        )->a( n = `width`       v = `17rem`
        )->a( n = `placeholder` v = `e.g. RSUSR002 or Z*`
        )->a( n = `submit`      v = client->_event( `DISPLAY_DIRECT` ) ).
    row->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://value-help`
        )->a( n = `size`    v = `1rem`
        )->a( n = `color`   v = zcl_zlk05_gui_frame=>c_blue
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Search for a program - use * as a wildcard`
        )->a( n = `press`   v = client->_event( `EXECUTE` ) ).
    row->tag( `Button`
        )->a( n = `text`    v = `Create`
        )->a( n = `icon`   v = `sap-icon://add-document`
        )->a( n = `enabled` v = `false`
        )->a( n = `class`   v = `sapUiMediumMarginBegin`
        )->a( n = `tooltip` v = `Create - this app never changes the repository` ).

    " ----- Subobjects -----
    work->tag( `Title`
        )->a( n = `text`  v = `Subobjects`
        )->a( n = `level` v = `H4`
        )->a( n = `class` v = `sapUiMediumMarginTop` ).

    " Only the source code can be read, the other subobjects would need
    " repository APIs that are not released here.
    DATA(sub) = work->ele( `Panel`
        )->a( n = `width` v = `26rem`
        )->ele( `RadioButtonGroup`
            )->a( n = `columns`       v = `1`
            )->a( n = `selectedIndex` v = `0`
            )->ele( `buttons` ).

    sub->tag( `RadioButton` )->a( n = `text` v = `Source Code` ).
    sub->tag( `RadioButton`
        )->a( n = `text`    v = `Variants`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Variants - not available in this environment` ).
    sub->tag( `RadioButton`
        )->a( n = `text`    v = `Attributes`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Attributes - not available in this environment` ).
    sub->tag( `RadioButton`
        )->a( n = `text`    v = `Text elements`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Text elements - not available in this environment` ).
    sub->tag( `RadioButton`
        )->a( n = `text`    v = `Documentation`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `Documentation - not available in this environment` ).

    " ----- Display / Change -----
    DATA(btn) = work->ele( `HBox`
        )->a( n = `class` v = `sapUiSmallMarginTop` ).
    btn->tag( `Button`
        )->a( n = `text`  v = `Display`
        )->a( n = `icon`  v = `sap-icon://display`
        )->a( n = `type`  v = `Emphasized`
        )->a( n = `press` v = client->_event( `DISPLAY_DIRECT` ) ).
    btn->tag( `Button`
        )->a( n = `text`    v = `Change`
        )->a( n = `icon`    v = `sap-icon://edit`
        )->a( n = `enabled` v = `false`
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Change - this app displays source code only` ).

    " ----- Hit list -----
    " The original screen has no hit list. It is shown here because a
    " generic pattern like Z* has to lead somewhere.
    IF mt_programs IS NOT INITIAL.
      DATA(tab) = work->ele( `Table`
          )->a( n = `items`   v = client->_bind( mt_programs )
          )->a( n = `sticky`  v = `ColumnHeaders`
          )->a( n = `growing` v = `true`
          )->a( n = `class`   v = `sapUiSizeCompact sapUiMediumMarginTop` ).

      DATA(cols) = tab->ele( `columns` ).
      cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Program` ).
      cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Type` ).
      cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Package` ).
      cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Author` ).
      cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Changed On` ).

      DATA(cells) = tab->ele( `items`
          )->ele( `ColumnListItem`
              )->a( n = `type`  v = `Navigation`
              )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                    arg = `${NAME}` )
              )->ele( `cells` ).
      cells->tag( `Text` )->a( n = `text` v = `{NAME}` ).
      cells->tag( `Text` )->a( n = `text` v = `{KIND}` ).
      cells->tag( `Text` )->a( n = `text` v = `{PACKAGE}` ).
      cells->tag( `Text` )->a( n = `text` v = `{AUTHOR}` ).
      cells->tag( `Text` )->a( n = `text` v = `{CHDATE}` ).
    ENDIF.

    " the cursor sits in the program field, exactly like the SAP GUI
    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idProgName` ) ) ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_source.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE string_table(
            ( `Program` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
            ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |ABAP Editor: Display Report { mv_current }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE zcl_zlk05_gui_frame=>ty_t_button(
            ( icon = `sap-icon://arrow-left` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Back to the initial screen`
              press   = client->_event( `BACK_TO_LIST` ) )
            ( icon = `sap-icon://arrow-right` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = `Forward - not available in this environment` )
            ( sep = abap_true )
            ( icon = `sap-icon://validate` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Check - not available in this environment` )
            ( icon = `sap-icon://activate` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Activate - this app never changes the repository` )
            ( icon = `sap-icon://request` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Where-used list - not available in this environment` )
            ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Other object - use the program list on the left` )
            ( icon = `sap-icon://hint` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Information - not available in this environment` )
            ( sep = abap_true )
            ( text = `Pattern`  tooltip = `Pattern - the editor is read-only` )
            ( text = `Insert`   tooltip = `Insert - the editor is read-only` )
            ( text = `Replace`  tooltip = `Replace - the editor is read-only` )
            ( text = `Delete`   tooltip = `Delete - the editor is read-only` )
            ( text = `Undo`     tooltip = `Undo - the editor is read-only` )
            ( text = `Text Elements`
              tooltip = `Text elements - not available in this environment` ) ) ).

    " ----- Work area: repository browser on the left, editor on the right -----
    DATA(split) = page->ele( `HBox`
        )->a( n = `width`      v = `100%`
        )->a( n = `alignItems` v = `Stretch`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height ).

    DATA(browser) = split->ele( `VBox` )->a( n = `width` v = `26%` ).

    DATA(brow_head) = browser->ele( `Toolbar`
        )->a( n = `design` v = `Info`
        )->a( n = `height` v = `1.9rem` ).
    brow_head->tag( n = `Icon` ns = `core`
        )->a( n = `src`   v = `sap-icon://tree`
        )->a( n = `size`  v = `0.9rem`
        )->a( n = `color` v = zcl_zlk05_gui_frame=>c_blue ).
    brow_head->tag( `Text` )->a( n = `text` v = `Repository Browser` ).

    DATA(brow_row) = browser->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    brow_row->tag( `Input`
        )->a( n = `value`  v = client->_bind( mv_progname )
        )->a( n = `width`  v = `12rem`
        )->a( n = `submit` v = client->_event( `EXECUTE` ) ).
    brow_row->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://display`
        )->a( n = `size`    v = `1rem`
        )->a( n = `color`   v = zcl_zlk05_gui_frame=>c_blue
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Display the program`
        )->a( n = `press`   v = client->_event( `DISPLAY_DIRECT` ) ).
    brow_row->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://search`
        )->a( n = `size`    v = `1rem`
        )->a( n = `color`   v = zcl_zlk05_gui_frame=>c_blue
        )->a( n = `class`   v = `sapUiTinyMarginBegin`
        )->a( n = `tooltip` v = `Search for programs`
        )->a( n = `press`   v = client->_event( `EXECUTE` ) ).

    IF mt_programs IS NOT INITIAL.
      DATA(brow_tab) = browser->ele( `Table`
          )->a( n = `items`  v = client->_bind( mt_programs )
          )->a( n = `sticky` v = `ColumnHeaders`
          )->a( n = `class`  v = `sapUiSizeCompact` ).

      DATA(brow_cols) = brow_tab->ele( `columns` ).
      brow_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Object Name` ).
      brow_cols->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Type` ).

      DATA(brow_cells) = brow_tab->ele( `items`
          )->ele( `ColumnListItem`
              )->a( n = `type`  v = `Active`
              )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                    arg = `${NAME}` )
              )->ele( `cells` ).
      brow_cells->tag( `Text` )->a( n = `text` v = `{NAME}` ).
      brow_cells->tag( `Text` )->a( n = `text` v = `{KIND}` ).
    ENDIF.

    " ----- Editor -----
    DATA(editor) = split->ele( `VBox`
        )->a( n = `width` v = `74%`
        )->a( n = `class` v = `sapUiTinyMarginBegin` ).

    DATA(head) = editor->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = head iv_text = `Report` ).
    head->tag( `Input`
        )->a( n = `value`   t = mv_current
        )->a( n = `width`   v = `17rem`
        )->a( n = `enabled` v = `false` ).
    head->tag( `Text`
        )->a( n = `text`  v = `Active`
        )->a( n = `class` v = `sapUiMediumMarginBegin` ).

    editor->tag( n = `CodeEditor` ns = `editor`
        )->a( n = `value`       v = client->_bind( mv_source )
        )->a( n = `type`        v = `abap`
        )->a( n = `height`      v = `calc(100vh - 17rem)`
        )->a( n = `editable`    v = `false`
        )->a( n = `lineNumbers` v = `true` ).

    " the editor status line of SE38
    DATA(foot) = editor->ele( `Toolbar`
        )->a( n = `design` v = `Transparent`
        )->a( n = `height` v = `1.9rem` ).
    foot->tag( `Text` )->a( n = `text` v = `Scope: >` ).
    foot->tag( `ToolbarSpacer` ).
    foot->tag( `Text`
        )->a( n = `text`    v = `Display mode - source is read-only`
        )->a( n = `tooltip` v = `This app has no write path into the repository` ).
    foot->tag( `ToolbarSeparator` ).
    foot->tag( `Text` )->a( n = `text` t = |{ count( val = mv_source sub = cl_abap_char_utilities=>newline ) + 1 } lines| ).
    foot->tag( `ToolbarSeparator` ).
    foot->tag( `Text` )->a( n = `text` v = `ABAP` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
