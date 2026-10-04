CLASS zcl_sapgui_se03 DEFINITION PUBLIC
  INHERITING FROM zcl_sapgui_screen.

* ---------------------------------------------------------------------
*  SE03 - Transport Organizer Tools: Search for Objects in
*  Requests/Tasks (report RSWBO040), the tool of SE03 that is used most.
*
*  Selection by object type and object name (* and + as wildcards), the
*  list of every request and task whose object list (E071) contains a
*  matching object, newest first. A request number opens the request in
*  the Transport Organizer (SE09), through the router. The other tools
*  of SE03 - changing object directory entries, merging, unlocking -
*  change the system and are not offered.
*
*  Authorization: S_TCODE SE03 + S_TRANSPRT 03 (ZCL_SAPGUI_AUTH).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    DATA mv_object   TYPE string.
    DATA mv_obj_name TYPE string.
    DATA mt_hits     TYPE zcl_sapgui_sys_api=>ty_t_object_request.

  PROTECTED SECTION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS on_event REDEFINITION.
    METHODS do_search.
    "! Opens the request in SE09; abap_true when that took the roundtrip
    METHODS do_open
      IMPORTING iv_trkorr     TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_sapgui_se03 IMPLEMENTATION.


  METHOD on_init.
    render( ).
  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        IF do_open( client->get_event_arg( ) ) = abap_true.
          RETURN.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_hits.
    IF condense( mv_obj_name ) = ``.
      mv_message = `Enter an object name - * and + are wildcards.`.
      mv_msgtype = `Warning`.
      RETURN.
    ENDIF.

    mt_hits = zcl_sapgui_sys_api=>search_object_in_requests( iv_obj_name = mv_obj_name
                                                             iv_object   = mv_object ).
    IF mt_hits IS INITIAL.
      mv_message = `No requests or tasks contain an object of this selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_hits ) } entry/entries found.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    IF iv_trkorr IS INITIAL.
      RETURN.
    ENDIF.

    " the request in the Transport Organizer, the way SE03 hands over to SE09
    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = `SE09`
        io_client  = client
        it_params  = VALUE #( ( name  = zif_sapgui_start_params=>c_request
                                value = iv_trkorr ) ) ).
    IF ls_run-outcome = zcl_sapgui_router=>c_nav.
      result = abap_true.
    ELSE.
      mv_message = ls_run-message.
      mv_msgtype = ls_run-msg_type.
    ENDIF.

  ENDMETHOD.


  METHOD render.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_sapgui_frame=>open_window( view ).

    zcl_sapgui_frame=>build_status_bar( io_parent   = page
                                        iv_message  = mv_message
                                        iv_msg_type = mv_msgtype ).

    zcl_sapgui_frame=>build_menu_bar(
        io_client  = client
        io_parent  = page
        it_entries = VALUE #( ( `Program` ) ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar(
        io_client     = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_sapgui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_sapgui_frame=>build_title_bar(
        io_client = client
        io_parent = page
        iv_title  = `Search for Objects in Requests/Tasks` ).

    zcl_sapgui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Execute` icon = `sap-icon://process`
              tooltip = `Execute (F8)`
              press = client->_event( `EXECUTE` ) ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_sapgui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->ele( `VBox`
        )->a( n = `class` v = `sapUiTinyMargin` ).
    DATA(row_type) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_sapgui_frame=>add_label( io_parent = row_type
                                 iv_text   = `Object Type` ).
    row_type->tag( `Input`
        )->a( n = `id`          v = `idSe03Object`
        )->a( n = `value`       v = client->_bind( mv_object )
        )->a( n = `placeholder` v = `PROG, CLAS, TABL ... - empty for all`
        )->a( n = `width`       v = `16rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row_type->end( ).
    DATA(row_name) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_sapgui_frame=>add_label( io_parent = row_name
                                 iv_text   = `Object Name` ).
    row_name->tag( `Input`
        )->a( n = `id`          v = `idSe03ObjName`
        )->a( n = `value`       v = client->_bind( mv_obj_name )
        )->a( n = `placeholder` v = `* and + are wildcards`
        )->a( n = `width`       v = `24rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row_name->end( ).
    sel->end( ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_hits )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `None`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Request/Task|TRKORR|9rem` )
        ( `Request|STRKORR|9rem` )
        ( `Type|FUNCTXT|12rem` )
        ( `Status|STATUSTXT|10rem` )
        ( `Owner|AS4USER|9rem` )
        ( `Date|AS4DATE|7rem` )
        ( `Short Description|AS4TEXT|22rem` )
        ( `Program ID|PGMID|6rem` )
        ( `Object Type|OBJECT|6rem` )
        ( `Object Name|OBJ_NAME|20rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width`          t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label`
              )->a( n = `text` t = lv_head
      )->end(
      )->end( ).
      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `TRKORR`.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${TRKORR}` ) ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    zcl_sapgui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_sapgui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
