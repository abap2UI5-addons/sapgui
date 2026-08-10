CLASS zcl_se37_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE37 - Function Builder
*
*  Screen titles, menu bar, function and field texts are the original
*  ones of the Function Builder (RSMPTEXTS / D021T):
*
*    T  SAPLSFUNCTION_BUILDER 001  Function Builder: Initial Screen
*       SAPMS38L 003  Function Builder: Display Function Module &
*    M  Function Module  Edit  Goto  Utilities  Environment
*    F  WB_DISPLAY Display   WB_EDIT Change   WB_DELETE Delete
*       SEAR Find            WB_DOCUMENTATION Documentation
*       WB_WHERE_USED_LIST Where-Used List   APPH Application Hierarchy
*       WB_DISP_EDIT_TOGGLE Display <-> Change   WB_CHECK Check
*       ED_PRETTY_PRINT Pretty Printer  WB_CODE_INSPECTOR Code Inspector
*       WB_MULTI_OBJECT_PREV/NEXT Previous Object / Next Object
*       WB_TADIR_EDIT Object Directory Entry   WB_PRINT Print...
*    D  1008  Function Module      3001  Function Module:
*       3030  Function Group
*
*  Two screens: the initial screen with the function module name and the
*  hit list, and the interface of one function module. Everything that
*  would change a function module is present but disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    "! Content of the command field of the system function bar
    DATA mv_command   TYPE string.

    DATA mv_funcname  TYPE string.
    DATA mv_mode      TYPE string.
    DATA mv_current   TYPE string.
    "! Function group of the function module on the display screen - the
    "! original screen shows it next to the name.
    DATA mv_curarea   TYPE string.
    DATA mv_message   TYPE string.
    DATA mv_msgtype   TYPE string.
    DATA mt_functions TYPE zcl_zlk05_sys_api=>ty_t_function.
    DATA mt_params    TYPE zcl_zlk05_sys_api=>ty_t_fparam.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_detail.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed twice:
    "! after an event that only changed the mode, and - most importantly -
    "! when the transaction is navigated back to from another one, where the
    "! framework supplies no event at all.
    METHODS render.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_funcname TYPE string.
    "! The menu bar is the same on both screens of the transaction.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se37_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      view_display( ).
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

    DATA(lv_event) = client->get( )-event.
    DATA(lt_arg)   = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA lv_frame TYPE string.
    zcl_zlk05_gui_frame=>handle_frame_event(
      EXPORTING io_client   = client
                iv_event    = lv_event
                iv_command  = mv_command
      IMPORTING ev_message  = mv_message
                ev_msg_type = mv_msgtype
      RECEIVING result      = lv_frame ).
    IF lv_frame = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE lv_event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        IF lines( lt_arg ) > 0.
          do_open( lt_arg[ 1 ] ).
        ENDIF.
      WHEN 'BACK_TO_LIST'.
        mv_mode = `LIST`.
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


  METHOD do_search.

    CLEAR mt_functions.
    mt_functions = zcl_zlk05_sys_api=>search_functions( mv_funcname ).
    mv_mode      = `LIST`.

    IF lines( mt_functions ) = 0.
      mv_message = `No function modules found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_functions ) } function module(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_params.
    mv_current = iv_funcname.
    mt_params  = zcl_zlk05_sys_api=>get_function_params( iv_funcname ).

    " the display screen names the function group next to the module, the
    " hit list already carries it
    CLEAR mv_curarea.
    READ TABLE mt_functions INTO DATA(ls_fun) WITH KEY funcname = iv_funcname.
    IF sy-subrc = 0.
      mv_curarea = ls_fun-area.
    ENDIF.

    IF lines( mt_params ) = 0.
      mv_message = |{ iv_funcname } has no interface parameters.|.
      mv_msgtype = `Information`.
    ENDIF.

    mv_mode = `DETAIL`.

  ENDMETHOD.


  METHOD menu_entries.

    result = VALUE #( ( `Function Module` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                      ( `Environment` ) ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar. Entry screen of the transaction, so
    " Back leaves it.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Function Builder: Initial Screen` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the function modules of the selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Documentation - { c_na }| )
            ( icon = `sap-icon://chain-link` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://tree` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Application Hierarchy - { c_na }| ) ) ).

    " band 5 - work area. The initial screen of SE37 asks for the function
    " module, the hit list below is what the Display function produces.
    DATA(work) = page->open( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->open( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = sel
                                   iv_text   = `Function Module`
                                   iv_width  = `13rem` ).

    sel->leaf( `Input`
        )->a( n = `id`          v = `idFuncName`
        )->a( n = `value`       v = client->_bind( mv_funcname )
        )->a( n = `placeholder` v = `e.g. BAPI_* or POPUP_TO_CONFIRM`
        )->a( n = `width`       v = `24rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idFuncName` ) ) ).

    DATA(grid) = work->open( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_functions )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->open( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Function Module|FUNCNAME|30rem` )
        ( `Function Group|AREA|14rem` )
        ( `RFC|RFC|4rem` )
        ( `Short Text|STEXT|40rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->open( n = `Column` ns = `table`
          )->a( n = `width` v = lv_wid ).
      col->open( n = `label` ns = `table`
          )->leaf( `Label` )->a( n = `text` v = lv_head )->shut( )->shut( ).

      DATA(tmpl) = col->open( n = `template` ns = `table` ).
      IF lv_fld = `FUNCNAME`.
        " the module name drills down to its interface. The handler has to sit
        " INSIDE the row template - only there does ${FUNCNAME} resolve to
        " the row.
        tmpl->leaf( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val   = `DISPLAY`
                                                 t_arg = VALUE #( ( `${FUNCNAME}` ) ) ) ).
      ELSE.
        tmpl->leaf( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->shut( ).
    ENDLOOP.

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar. Second screen of the transaction, so
    " Back returns to the initial screen instead of leaving SE37.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar, original title 003 of SAPMS38L
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = |Function Builder: Display Function Module { mv_current }| ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the initial screen (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://navigation-left-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Previous Object - { c_na }| )
            ( icon = `sap-icon://navigation-right-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Next Object - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://display` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display <-> Change - { c_na }| )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check - { c_na }| )
            ( icon = `sap-icon://indent` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Pretty Printer - { c_na }| )
            ( icon = `sap-icon://quality-issue` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Code Inspector - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Documentation - { c_na }| )
            ( icon = `sap-icon://chain-link` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| )
            ( icon = `sap-icon://form` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Object Directory Entry - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print... - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->open( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " the header fields of dynpro 3001 / 3030
    DATA(hdr) = work->open( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = hdr
                                   iv_text   = `Function Module:`
                                   iv_width  = `13rem` ).

    hdr->leaf( `Text`
        )->a( n = `text`  v = mv_current
        )->a( n = `class` v = `sapUiSmallMarginEnd` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = hdr
                                   iv_text   = `Function Group`
                                   iv_width  = `11rem` ).

    hdr->leaf( `Text`
        )->a( n = `text` v = mv_curarea ).

    DATA(grid) = work->open( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_params )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->open( n = `columns` ns = `table` ).

    " IMPORTING / EXPORTING / CHANGING / TABLES / EXCEPTIONS in one list,
    " the way the SE37 interface tabs read together
    DATA(lt_col) = VALUE string_table(
        ( `Kind|KIND|11rem` )
        ( `Parameter|PARAMETER|22rem` )
        ( `Typing|TYPING|7rem` )
        ( `Associated Type|REFERENCE|22rem` )
        ( `Optional|OPTIONAL|6rem` )
        ( `Default Value|DEFAULT|16rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->open( n = `Column` ns = `table`
          )->a( n = `width` v = lv_wid ).
      col->open( n = `label` ns = `table`
          )->leaf( `Label` )->a( n = `text` v = lv_head )->shut( )->shut( ).
      col->open( n = `template` ns = `table`
          )->leaf( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->shut( ).
    ENDLOOP.

    work->leaf( `Text`
        )->a( n = `text`  v = |{ lines( mt_params ) } parameter(s) - display only|
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " F3 goes back one screen here, not out of the transaction
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
