CLASS zcl_sapgui_sm04 DEFINITION PUBLIC
  INHERITING FROM zcl_sapgui_screen.

* ---------------------------------------------------------------------
*  SM04 - User List
*
*  Shows the users logged on to the own application server instance,
*  read with TH_USER_LIST (the same kernel call the original uses).
*  Ending a session is present in the toolbar but disabled - this app
*  never touches a session.
*
*  Authorization: S_TCODE SM04 + S_RZL_ADM 03 (ZCL_SAPGUI_AUTH).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mt_sessions TYPE zcl_sapgui_sys_api=>ty_t_session.

  PROTECTED SECTION.

    METHODS view_display.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sapgui_sm04 IMPLEMENTATION.


  METHOD on_init.

    do_refresh( ).
    view_display( ).

  ENDMETHOD.


  METHOD render.
    view_display( ).
  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN 'REFRESH'.
        do_refresh( ).
      WHEN 'DISPLAY_USER'.
        " like the original user list: from a session to the user master
        DATA(lv_user) = client->get_event_arg( ).
        IF lv_user IS NOT INITIAL.
          DATA(ls_run) = zcl_sapgui_router=>run(
              iv_command = `SU01`
              io_client  = client
              it_params  = VALUE #( ( name  = zif_sapgui_start_params=>c_user
                                      value = lv_user ) ) ).
          IF ls_run-outcome = zcl_sapgui_router=>c_nav.
            RETURN.
          ENDIF.
          mv_message = ls_run-message.
          mv_msgtype = ls_run-msg_type.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_refresh.

    zcl_sapgui_sys_api=>get_user_sessions(
      IMPORTING et_sessions = mt_sessions
                ev_message  = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_sessions ) } session(s) on this instance.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_sapgui_frame=>open_window( view ).

    zcl_sapgui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_sapgui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `User` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_sapgui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_sapgui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |User List of AS Instance { sy-host }| ).

    zcl_sapgui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read the user list again`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Sessions` icon = `sap-icon://detail-view`
              tooltip = |Sessions of the User - { c_na }| )
            ( icon = `sap-icon://log` color = zcl_sapgui_frame=>c_red
              tooltip = |End Session - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://sort-ascending` color = zcl_sapgui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_sapgui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_sapgui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_sessions )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10`
        )->a( n = `cellClick`           v = client->_event( val = `DISPLAY_USER`
                                                            arg = `${BNAME}` ) ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the column sequence of the original SM04 list
    DATA(lt_col) = VALUE string_table(
        ( `Client|CLIENT|5rem` )
        ( `User|BNAME|10rem` )
        ( `Terminal|TERM|14rem` )
        ( `Transaction|TCODE|9rem` )
        ( `Time|ZEIT|6rem` )
        ( `Sessions|SESSIONS|6rem` )
        ( `Type|TYPETEXT|7rem` )
        ( `Host Address|HOSTADR|10rem` ) ).

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
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no session is ended here. Choose a line to display the user`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    zcl_sapgui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_sapgui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
