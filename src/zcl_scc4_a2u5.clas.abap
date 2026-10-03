CLASS zcl_scc4_a2u5 DEFINITION PUBLIC
  INHERITING FROM zcl_zlk05_screen.

* ---------------------------------------------------------------------
*  SCC4 - Client Maintenance
*
*  SCC4 is a view maintenance (SM30) of view V_T000, so screen title,
*  menu bar and function texts are the generated ones of SAPLSVIM
*  (RSMPTEXTS):
*
*    T        Display View "&": Overview   ->  ..."Clients": Overview
*    M  TABL  Table View     ZEIL  Edit     SPRI  Goto
*       AUSW  Selection      000015 Utilities
*    F  DETA  Details        NEWL  New Entries   KOPE  Copy As...
*       DELE  Delete         AEND  Display -> Change
*       PRST  Print          MKAL  Select All    MKLO  Deselect All
*       POSI  Position Cursor...   DOCU  Configuration Help
*
*  The app reads T000 and shows it in the classic SAP GUI frame. Every
*  function that would change a client is present but disabled - this
*  app never writes to T000.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mt_clients TYPE zcl_zlk05_sys_api=>ty_t_client.

  PROTECTED SECTION.

    METHODS view_display.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_scc4_a2u5 IMPLEMENTATION.

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

    CLEAR mt_clients.
    mt_clients = zcl_zlk05_sys_api=>get_clients( ).

    IF lines( mt_clients ) = 0.
      mv_message = `No clients could be read from table T000.`.
      mv_msgtype = `Error`.
    ELSE.
      mv_message = |{ lines( mt_clients ) } client(s) defined in this system.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar of the generated view maintenance
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Table View` ) ( `Edit` ) ( `Goto` ) ( `Selection` )
                              ( `Utilities` ) ( `System` ) ( `Help` ) ) ).

    " band 2 - system function bar with the command field
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar. The quotes belong to the original title and are
    " escaped by the XML builder.
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Display View "Clients": Overview` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read table T000 again`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Details` icon = `sap-icon://detail-view`
              tooltip = |Details - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |New Entries - { c_na }| )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy As... - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display -> Change - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print - { c_na }| )
            ( icon = `sap-icon://multi-select` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Select All - { c_na }| )
            ( icon = `sap-icon://multiselect-none` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Deselect All - { c_na }| )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Position Cursor... - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://sys-help` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Configuration Help - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_clients )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the column sequence of the generated overview of view V_T000
    DATA(lt_col) = VALUE string_table(
        ( `Client|MANDT|5rem` )
        ( `Name|MTEXT|18rem` )
        ( `City|ORT01|12rem` )
        ( `Currency|MWAER|6rem` )
        ( `Role|CATTXT|12rem` )
        ( `Changes and Transports|CORACTTXT|24rem` )
        ( `Changed By|CHANGEUSER|10rem` )
        ( `Changed On|CHANGEDATE|8rem` ) ).

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

    " the real SCC4 changes the client settings - this app deliberately cannot
    work->tag( `Text`
        )->a( n = `text`  v = `Client maintenance - display only`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
