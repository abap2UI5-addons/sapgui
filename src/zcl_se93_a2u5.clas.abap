CLASS zcl_se93_a2u5 DEFINITION PUBLIC
  INHERITING FROM zcl_zlk05_screen.

* ---------------------------------------------------------------------
*  SE93 - Maintain Transaction
*
*  Screen titles, menu bars, toolbars and field texts are the original
*  ones of SAPLSEUK, the program behind SE93. They were not typed in by
*  hand but read out of the system:
*
*    T  390       Maintain Transaction        (title of the entry screen)
*       TSH       Display $                   ($ = RSSTCD-TC_TYPE)
*    C  390_SELE  entry screen, GUI status - carries NO application
*                 toolbar, only the three pushbuttons of the dynpro
*       SHW_TCOD / SHW_PARA / SHW_VARI  the display screens
*    M  entry screen   Transaction Code  Edit  Goto  Utilities
*                      Environment
*       display screen Transaction code  Edit  Goto  Utilities
*                      Environment
*                 The capital C of the entry screen is not a typo, the
*                 two menu bars really differ (CUA 000080 vs 0054).
*    D  0390      @10@ Display   @0Z@ Change   @0Y@ Create
*       0310      dialog      Program, Screen number
*       0320      report      Program, Selection screen, Start with variant
*       0330      parameter   Transaction, Skip initial screen, Default Values
*       0331      variant     Transaction, Transaction variant, Cross-client
*       0360      object      Method, Local in program, Update Mode
*       0370      Classification, GUI support
*
*  The transaction type names come from the text pool of SAPLSEUK, so
*  they stay in sync with the original - see ZCL_ZLK05_SYS_API=>seuk_text.
*
*  Two screens: the entry screen with the transaction code and a hit
*  list, and the display screen, whose work area follows the type of the
*  transaction the way the original switches between its five dynpros.
*  Everything that would change a transaction is present but disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    " entry screen
    DATA mv_tcode TYPE string.

    " results
    DATA mt_tcodes TYPE zcl_zlk05_sys_api=>ty_t_tcode.
    DATA ms_detail TYPE zcl_zlk05_sys_api=>ty_s_tcode_detail.

  PROTECTED SECTION.
    " current view
    DATA mv_mode    TYPE string.

    METHODS view_display.
    METHODS view_detail.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_tcode TYPE string.

    "! Menu bar of the two screens. The entry screen and the display
    "! screens carry different ones - CUA menus 000080.. and 0054..
    METHODS menu_entries
      IMPORTING iv_entry      TYPE abap_bool DEFAULT abap_false
      RETURNING VALUE(result) TYPE string_table.

    "! The application toolbar of SHW_TCOD / SHW_PARA / SHW_VARI, read
    "! from the CUA of SAPLSEUK. Everything is display only here, so all
    "! entries are greyed out - only Back has a handler.
    METHODS detail_buttons
      RETURNING VALUE(result) TYPE zcl_zlk05_gui_frame=>ty_t_button.

    "! Label and value of one row of a classic dynpro
    METHODS add_row
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_label  TYPE string
                iv_value  TYPE string.

    "! Checkbox of a classic dynpro in display mode - the text is the
    "! label of the checkbox, not a separate one
    METHODS add_flag
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_text   TYPE string
                iv_flag   TYPE abap_bool.

    "! Group box of a classic dynpro
    METHODS add_group
      IMPORTING io_parent     TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_title      TYPE string
      RETURNING VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Work area of the display screen, one block per transaction type
    METHODS build_type_block
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder.

    "! Update mode of an object transaction. The codes are the ones of
    "! LSEUKTOP (S synchronous, U asynchronous), the texts those of
    "! dynpro 0360.
    METHODS upd_mode_text
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se93_a2u5 IMPLEMENTATION.

  METHOD on_init.

    mv_mode = `LIST`.
    view_display( ).

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get_event( ).
    DATA(lv_arg)   = client->get_event_arg( ).
    CASE lv_event.

      WHEN 'EXECUTE'.
        do_search( ).

      WHEN 'DISPLAY'.
        IF lv_arg IS NOT INITIAL.
          do_open( lv_arg ).
        ENDIF.

      WHEN 'BACK_TO_LIST'.
        mv_mode = `LIST`.

      WHEN 'TEST_TCODE'.
        " SE93 Test: start the transaction itself - the router answers for
        " transactions this environment does not implement
        IF ms_detail-tcode IS NOT INITIAL.
          DATA(ls_test) = zcl_zlk05_tcode_router=>run( iv_command = ms_detail-tcode
                                                       io_client  = client ).
          IF ls_test-outcome = zcl_zlk05_tcode_router=>c_nav.
            RETURN.
          ENDIF.
          mv_message = ls_test-message.
          mv_msgtype = ls_test-msg_type.
        ENDIF.

      WHEN 'GOTO_PROGRAM'.
        IF ms_detail-pgmna IS NOT INITIAL.
          DATA(ls_run) = zcl_zlk05_tcode_router=>run(
              iv_command = `SE38`
              io_client  = client
              it_params  = VALUE #( ( name  = zif_zlk05_start_params=>c_program
                                      value = ms_detail-pgmna ) ) ).
          IF ls_run-outcome = zcl_zlk05_tcode_router=>c_nav.
            RETURN.
          ENDIF.
          mv_message = ls_run-message.
          mv_msgtype = ls_run-msg_type.
        ENDIF.

      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD render.

    IF mv_mode = `DETAIL`.
      view_detail( ).
    ELSE.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD menu_entries.

    " CUA of SAPLSEUK: menu bar 000028 of status 390_SELE against menu
    " bar 0007 of the display statuses. The fifth menu of both is a CUA
    " include of SAPLWB_INITIAL_TOOL / WB_ENVIRONMENT - Environment.
    IF iv_entry = abap_true.
      result = VALUE #( ( `Transaction Code` ) ).
    ELSE.
      result = VALUE #( ( `Transaction code` ) ).
    ENDIF.

    APPEND LINES OF VALUE string_table(
        ( `Edit` ) ( `Goto` ) ( `Utilities` ) ( `Environment` )
        ( `System` ) ( `Help` ) ) TO result.

  ENDMETHOD.


  METHOD detail_buttons.

    " Toolbar 0047 of SHW_TCOD, in the original order. A RSMPE_BUT row
    " with PFNO 'S' is a separator.
    result = VALUE #(
        ( text = `Back` icon = `sap-icon://nav-back`
          tooltip = `Back to the entry screen (F3)`
          press = client->_event( `BACK_TO_LIST` ) )
        ( sep = abap_true )
        ( text = `Test` icon = `sap-icon://begin`
          tooltip = `Test - start the transaction`
          press = client->_event( `TEST_TCODE` ) )
        ( text = `Display Program` icon = `sap-icon://source-code`
          tooltip = `Display the program of the transaction in the ABAP Editor`
          press = client->_event( `GOTO_PROGRAM` )
          disabled = xsdbool( ms_detail-pgmna IS INITIAL ) )
        ( sep = abap_true )
        ( icon = `sap-icon://navigation-left-arrow`
          color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Previous object - { c_na }| )
        ( icon = `sap-icon://navigation-right-arrow`
          color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Next object - { c_na }| )
        ( sep = abap_true )
        ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Display <-> Change - { c_na }| )
        ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Other object... - { c_na }| )
        ( sep = abap_true )
        ( icon = `sap-icon://validate` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Check - { c_na }| )
        ( icon = `sap-icon://play` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Object - { c_na }| )
        ( icon = `sap-icon://tree` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Where-used list - { c_na }| )
        ( sep = abap_true )
        ( icon = `sap-icon://list` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Display object list - { c_na }| )
        ( icon = `sap-icon://compare` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Display navigation window - { c_na }| )
        ( icon = `sap-icon://full-screen` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Full Screen - { c_na }| )
        ( icon = `sap-icon://sys-help` color = zcl_zlk05_gui_frame=>c_grey
          tooltip = |Online manual - { c_na }| ) ).

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_tcodes.
    mt_tcodes = zcl_zlk05_sys_api=>get_transactions( iv_pattern = mv_tcode
                                                     iv_max     = 200 ).
    mv_mode = `LIST`.

    IF lines( mt_tcodes ) = 0.
      mv_message = `No transaction found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_tcodes ) } transaction(s) displayed.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    ms_detail = zcl_zlk05_sys_api=>get_transaction_detail( iv_tcode ).

    IF ms_detail-found = abap_false.
      mv_message = |Transaction { to_upper( iv_tcode ) } does not exist.|.
      mv_msgtype = `Error`.
      mv_mode    = `LIST`.
      RETURN.
    ENDIF.

    mv_mode = `DETAIL`.

  ENDMETHOD.


  METHOD add_row.

    DATA(row) = io_parent->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                   iv_text   = iv_label
                                   iv_width  = `16rem` ).
    row->tag( `Text` )->a( n = `text` t = iv_value ).
    row->end( ).

  ENDMETHOD.


  METHOD add_flag.

    " display mode: the checkbox keeps its tick but takes no input, the
    " way the original greys its fields out
    io_parent->tag( `CheckBox`
        )->a( n = `text`     v = iv_text
        )->a( n = `selected` v = COND string( WHEN iv_flag = abap_true
                                              THEN `true` ELSE `false` )
        )->a( n = `enabled`  v = `false` ).

  ENDMETHOD.


  METHOD add_group.

    " group box of a classic dynpro - a framed block with a heading
    DATA(box) = io_parent->ele( `Panel`
        )->a( n = `headerText` v = iv_title
        )->a( n = `class`      v = `sapUiSmallMarginTop` ).
    result = box->ele( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).

  ENDMETHOD.


  METHOD upd_mode_text.

    " texts of dynpro 0360
    CASE ms_detail-upd_mode.
      WHEN `S`.
        result = `Synchronous update`.
      WHEN `U`.
        result = `Asynchronous update`.
      WHEN `L`.
        result = `Local Update`.
      WHEN OTHERS.
        CLEAR result.
    ENDCASE.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( abap_true ) ).

    " band 2 - system function bar
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Maintain Transaction` ).

    " band 4 - GUI status 390_SELE carries no application toolbar at all,
    " its functions sit as pushbuttons in the work area

    " band 5 - work area, dynpro 0390
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(row_tc) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row_tc
                                   iv_text   = `Transaction Code` ).
    row_tc->tag( `Input`
        )->a( n = `id`     v = `idTcode`
        )->a( n = `value`  v = client->_bind( mv_tcode )
        )->a( n = `width`  v = `20rem`
        )->a( n = `submit` v = client->_event( `EXECUTE` ) ).
    row_tc->end( ).

    " the three pushbuttons of dynpro 0390. Change and Create would write,
    " so they are shown the way the SAP GUI shows a function that does not
    " apply: present and greyed out.
    DATA(btns) = sel->ele( `HBox`
        )->a( n = `class` v = `sapUiSmallMarginTop` ).
    btns->tag( `Button`
        )->a( n = `text`  v = `Display`
        )->a( n = `icon`  v = `sap-icon://display`
        )->a( n = `type`  v = `Transparent`
        )->a( n = `width` v = `9rem`
        )->a( n = `press` v = client->_event( `EXECUTE` ) ).
    btns->tag( `Button`
        )->a( n = `text`    v = `Change`
        )->a( n = `icon`    v = `sap-icon://edit`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `width`   v = `9rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Change - { c_na }| ).
    btns->tag( `Button`
        )->a( n = `text`    v = `Create`
        )->a( n = `icon`    v = `sap-icon://create`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `width`   v = `9rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Create - { c_na }| ).
    btns->end( ).

    sel->end( ).

    " hit list
    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_tcodes )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `8` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Transaction Code|TCODE|14rem` )
        ( `Text|TTEXT|32rem` )
        ( `Program|PGMNA|18rem` )
        ( `Screen|DYPNO|7rem` )
        ( `Type|TC_TYPE|15rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label`
              )->a( n = `text` t = lv_head
      )->end(
      )->end( ).

      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `TCODE`.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${TCODE}` ) ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar of the display statuses
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar, Back returns to the entry screen
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar. Title TSH is 'Display $' and the original fills
    " the placeholder with the transaction type.
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Display { ms_detail-tc_type }| ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar( io_parent  = page
                                       it_buttons = detail_buttons( ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(hdr) = work->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " every display dynpro starts with these two
    add_row( io_parent = hdr
             iv_label  = `Transaction code`
             iv_value  = ms_detail-tcode ).
    add_row( io_parent = hdr
             iv_label  = `Transaction text`
             iv_value  = ms_detail-ttext ).

    build_type_block( hdr ).

    " Start Options. D021T has the frame on dynpros 0310 / 0320 / 0331 /
    " 0360 only - dynpro 0330 of the parameter transaction carries the lock
    " flag on its own and frames its default values instead. And only
    " dynpro 0310 offers the standard transaction variant.
    IF ms_detail-tc_type = zcl_zlk05_sys_api=>seuk_text( `003` ).
      DATA(lock) = hdr->ele( `VBox`
          )->a( n = `class` v = `sapUiSmallMarginTop` ).
      add_flag( io_parent = lock
                iv_text   = `Transaction is locked (in transaction SM01 DEF)`
                iv_flag   = ms_detail-locked_sm01 ).
      lock->end( ).
    ELSE.
      DATA(opt) = add_group( io_parent = hdr
                             iv_title  = `Start Options` ).
      add_flag( io_parent = opt
                iv_text   = `Transaction is locked (in transaction SM01 DEF)`
                iv_flag   = ms_detail-locked_sm01 ).
      IF ms_detail-tc_type = zcl_zlk05_sys_api=>seuk_text( `001` )
         OR ms_detail-tc_type IS INITIAL.
        add_flag( io_parent = opt
                  iv_text   = `Editing of standard transaction variant allowed`
                  iv_flag   = ms_detail-trans_var ).
      ENDIF.
      opt->end( )->end( ).
    ENDIF.

    " authorization object with its check values - dynpro 0310 field
    " TSTCA-OBJCT, values in the popup titled 'Values of Check Object'
    IF ms_detail-auth_objct IS NOT INITIAL.
      DATA(auth) = add_group( io_parent = hdr
                              iv_title  = `Values of Check Object` ).
      add_row( io_parent = auth
               iv_label  = `Authorization Object`
               iv_value  = ms_detail-auth_objct ).

      DATA(agrid) = auth->ele( n = `Table` ns = `table`
          )->a( n = `rows`                v = client->_bind( ms_detail-auth )
          )->a( n = `visibleRowCountMode` v = `Auto`
          )->a( n = `selectionMode`       v = `None`
          )->a( n = `rowHeight`           v = `26`
          )->a( n = `minAutoRowCount`     v = `3`
          )->a( n = `class`               v = `sapUiTinyMarginTop` ).
      DATA(acols) = agrid->ele( n = `columns` ns = `table` ).
      LOOP AT VALUE string_table( ( `Field name|FIELD|16rem` )
                                  ( `Value|VALUE|16rem` ) ) INTO DATA(lv_ac).
        SPLIT lv_ac AT `|` INTO DATA(lv_ah) DATA(lv_af) DATA(lv_aw).
        DATA(acol) = acols->ele( n = `Column` ns = `table`
            )->a( n = `width` t = lv_aw
            )->a( n = `sortProperty`   t = lv_af
            )->a( n = `filterProperty` t = lv_af ).
        acol->ele( n = `label` ns = `table`
            )->tag( `Label`
                )->a( n = `text` t = lv_ah
        )->end(
        )->end( ).
        acol->ele( n = `template` ns = `table`
            )->tag( `Text`
                )->a( n = `text` v = |\{{ lv_af }\}| ).
        acol->end( ).
      ENDLOOP.
      auth->end( )->end( ).
    ENDIF.

    " Classification - dynpro 0370
    DATA(cls) = add_group( io_parent = hdr
                           iv_title  = `Classification` ).
    cls->tag( `Label` )->a( n = `text` v = `Transaction classification` ).
    add_flag( io_parent = cls
              iv_text   = `Professional User Transaction`
              iv_flag   = ms_detail-profi_tran ).
    add_flag( io_parent = cls
              iv_text   = `Easy Web Transaction`
              iv_flag   = ms_detail-iac_ewt ).
    cls->tag( `Label`
        )->a( n = `text`  v = `GUI support`
        )->a( n = `class` v = `sapUiTinyMarginTop` ).
    add_flag( io_parent = cls
              iv_text   = `SAP GUI for Windows`
              iv_flag   = ms_detail-s_win32 ).
    add_flag( io_parent = cls
              iv_text   = `SAP GUI for Java`
              iv_flag   = ms_detail-s_platin ).
    add_flag( io_parent = cls
              iv_text   = `SAP GUI for HTML`
              iv_flag   = ms_detail-s_webgui ).
    cls->end( )->end( ).

    hdr->end( ).

    " F3 goes back one screen
    zcl_zlk05_gui_frame=>register_keys( io_client    = client
                                       iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD build_type_block.

    " The original has one dynpro per transaction type and switches to it
    " in FORM transaction_ct_next_screen. The type names come from the
    " text pool of SAPLSEUK, so they are compared against it.
    DATA(lv_report)    = zcl_zlk05_sys_api=>seuk_text( `002` ).
    DATA(lv_parameter) = zcl_zlk05_sys_api=>seuk_text( `003` ).
    DATA(lv_variant)   = zcl_zlk05_sys_api=>seuk_text( `019` ).
    DATA(lv_object)    = zcl_zlk05_sys_api=>seuk_text( `028` ).

    CASE ms_detail-tc_type.

      WHEN lv_report.
        " dynpro 0320
        add_row( io_parent = io_parent
                 iv_label  = `Program`
                 iv_value  = ms_detail-pgmna ).
        add_row( io_parent = io_parent
                 iv_label  = `Selection screen`
                 iv_value  = ms_detail-dypno ).
        add_row( io_parent = io_parent
                 iv_label  = `Start with variant`
                 iv_value  = ms_detail-repo_vari ).

      WHEN lv_object.
        " dynpro 0360
        add_row( io_parent = io_parent
                 iv_label  = `Class`
                 iv_value  = ms_detail-classname ).
        add_row( io_parent = io_parent
                 iv_label  = `Method`
                 iv_value  = ms_detail-method ).
        IF ms_detail-pgmna IS NOT INITIAL.
          add_row( io_parent = io_parent
                   iv_label  = `Program`
                   iv_value  = ms_detail-pgmna ).
        ENDIF.
        DATA(loc) = io_parent->ele( `VBox`
            )->a( n = `class` v = `sapUiTinyMarginTop` ).
        add_flag( io_parent = loc
                  iv_text   = `Local in program`
                  iv_flag   = ms_detail-s_local ).
        loc->end( ).
        IF upd_mode_text( ) IS NOT INITIAL.
          add_row( io_parent = io_parent
                   iv_label  = `Update Mode`
                   iv_value  = upd_mode_text( ) ).
        ENDIF.

      WHEN lv_variant.
        " dynpro 0331
        add_row( io_parent = io_parent
                 iv_label  = `Transaction`
                 iv_value  = ms_detail-call_tcode ).
        add_row( io_parent = io_parent
                 iv_label  = `Transaction variant`
                 iv_value  = ms_detail-variant ).
        DATA(cro) = io_parent->ele( `VBox`
            )->a( n = `class` v = `sapUiTinyMarginTop` ).
        add_flag( io_parent = cro
                  iv_text   = `Cross-client`
                  iv_flag   = ms_detail-s_ind_vari ).
        cro->end( ).

      WHEN lv_parameter.
        " dynpro 0330
        IF ms_detail-start_tcode = abap_true.
          add_row( io_parent = io_parent
                   iv_label  = `Transaction`
                   iv_value  = ms_detail-call_tcode ).
        ELSE.
          add_row( io_parent = io_parent
                   iv_label  = `From module pool`
                   iv_value  = ms_detail-pgmna ).
          add_row( io_parent = io_parent
                   iv_label  = `Screen`
                   iv_value  = ms_detail-dypno ).
        ENDIF.
        DATA(skp) = io_parent->ele( `VBox`
            )->a( n = `class` v = `sapUiTinyMarginTop` ).
        add_flag( io_parent = skp
                  iv_text   = `Skip initial screen`
                  iv_flag   = ms_detail-skip_first ).
        skp->end( ).

        DATA(par) = add_group( io_parent = io_parent
                               iv_title  = `Default Values` ).
        DATA(pgrid) = par->ele( n = `Table` ns = `table`
            )->a( n = `rows`                v = client->_bind( ms_detail-params )
            )->a( n = `visibleRowCountMode` v = `Auto`
            )->a( n = `selectionMode`       v = `None`
            )->a( n = `rowHeight`           v = `26`
            )->a( n = `minAutoRowCount`     v = `3` ).
        DATA(pcols) = pgrid->ele( n = `columns` ns = `table` ).
        LOOP AT VALUE string_table( ( `Name of screen field|FIELD|20rem` )
                                    ( `Value|VALUE|28rem` ) ) INTO DATA(lv_pc).
          SPLIT lv_pc AT `|` INTO DATA(lv_ph) DATA(lv_pf) DATA(lv_pw).
          DATA(pcol) = pcols->ele( n = `Column` ns = `table`
              )->a( n = `width` t = lv_pw
              )->a( n = `sortProperty`   t = lv_pf
              )->a( n = `filterProperty` t = lv_pf ).
          pcol->ele( n = `label` ns = `table`
              )->tag( `Label`
                  )->a( n = `text` t = lv_ph
          )->end(
          )->end( ).
          pcol->ele( n = `template` ns = `table`
              )->tag( `Text`
                  )->a( n = `text` v = |\{{ lv_pf }\}| ).
          pcol->end( ).
        ENDLOOP.
        par->end( )->end( ).

      WHEN OTHERS.
        " dynpro 0310 - the dialog transaction, and the area menu, for
        " which the original shows no type at all
        add_row( io_parent = io_parent
                 iv_label  = `Program`
                 iv_value  = ms_detail-pgmna ).
        add_row( io_parent = io_parent
                 iv_label  = `Screen number`
                 iv_value  = ms_detail-dypno ).

    ENDCASE.

  ENDMETHOD.

ENDCLASS.
