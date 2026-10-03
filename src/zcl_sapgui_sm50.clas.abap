CLASS zcl_sapgui_sm50 DEFINITION PUBLIC
  INHERITING FROM zcl_sapgui_screen.

* ---------------------------------------------------------------------
*  SM50 - Work Process Overview
*
*  Screen title and menu bar are the original ones of program
*  RSMON000_ALV_NEW (RSMPTEXTS):
*
*    T 100    Work Processes of AS Instance &1
*    M        List  Edit  Goto  Settings  Administration
*
*  The app reads the work process table of the own instance and shows
*  it in an ALV grid. Everything that would change a work process is
*  present but disabled - this app never touches a process.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mt_wp      TYPE zcl_sapgui_sys_api=>ty_t_wp.

  PROTECTED SECTION.

    METHODS view_display.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sapgui_sm50 IMPLEMENTATION.

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
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_refresh.

    CLEAR mt_wp.

    zcl_sapgui_sys_api=>get_work_processes(
      IMPORTING et_wp      = mt_wp
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_wp ) } work process(es) on this instance.|.
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
        it_entries = VALUE #( ( `List` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                              ( `Administration` ) ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_sapgui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_sapgui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Work Processes of AS Instance { sy-host }| ).

    zcl_sapgui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read the work process table again`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Details` icon = `sap-icon://detail-view`
              tooltip = |Details of Work Process - { c_na }| )
            ( text = `System-Wide List` icon = `sap-icon://it-host`
              tooltip = |Work Processes of All AS Instances - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://stop` color = zcl_sapgui_frame=>c_red
              tooltip = |Cancel Work Process - { c_na }| )
            ( icon = `sap-icon://restart` color = zcl_sapgui_frame=>c_grey
              tooltip = |Restart After Error - { c_na }| )
            ( icon = `sap-icon://write-new-document` color = zcl_sapgui_frame=>c_grey
              tooltip = |Change Trace Components - { c_na }| )
            ( icon = `sap-icon://attachment-text-file` color = zcl_sapgui_frame=>c_grey
              tooltip = |Display Trace File - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_sapgui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://sort-ascending` color = zcl_sapgui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_sapgui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_sapgui_frame=>c_grey
              tooltip = |Change Layout... - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_sapgui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_wp )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the column sequence of the original SM50 list
    DATA(lt_col) = VALUE string_table(
        ( `No.|WP_NO|4rem` )
        ( `Type|WP_TYP|5rem` )
        ( `PID|WP_PID|6rem` )
        ( `Status|WP_STATUS|6rem` )
        ( `Reason|WP_REASON|6rem` )
        ( `Start|WP_START|4.5rem` )
        ( `Err.|WP_ERR|4rem` )
        ( `CPU|WP_CPU|5rem` )
        ( `Time|WP_TIME|5rem` )
        ( `Client|WP_CLIENT|5rem` )
        ( `User|WP_USER|9rem` )
        ( `Report|WP_REPORT|14rem` )
        ( `Action|WP_ACTION|14rem` )
        ( `Table|WP_TABLE|10rem` ) ).

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

    " the app is read only and has to say so - the original SM50 can cancel
    " a work process, this one deliberately cannot
    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no process can be cancelled here`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_sapgui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_sapgui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
