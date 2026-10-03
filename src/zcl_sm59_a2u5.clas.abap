CLASS zcl_sm59_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SM59 - Configuration of RFC Connections (display)
*
*  Lists the RFC destinations of RFCDES with their connection type and
*  technical target. Logon data - user, client, password - is never
*  read or shown. Creating, changing, deleting and testing a connection
*  are present in the toolbar but disabled.
*
*  Authorization: S_TCODE SM59 + S_RFC_ADM 03, and S_RFC_ADM 03 for
*  every single destination of the list (ZCL_ZLK05_AUTH).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command TYPE string.
    DATA mv_pattern TYPE string.
    DATA mv_type    TYPE string.
    DATA mt_dest    TYPE zcl_zlk05_sys_api=>ty_t_rfcdest.

    TYPES:
      BEGIN OF ty_s_type,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_type.
    TYPES ty_t_type TYPE STANDARD TABLE OF ty_s_type WITH EMPTY KEY.
    DATA mt_types TYPE ty_t_type.

  PROTECTED SECTION.
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS do_search.
    METHODS init_types.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_sm59_a2u5 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      init_types( ).
      do_search( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD init_types.

    " the connection types the SAP GUI tree of SM59 shows as folders
    mt_types = VALUE #( ( key = `` text = `All connection types` ) ).
    LOOP AT VALUE string_table( ( `3` ) ( `G` ) ( `H` ) ( `I` ) ( `L` ) ( `T` ) ( `W` ) )
         INTO DATA(lv_key).
      APPEND VALUE #( key  = lv_key
                      text = |{ lv_key } - { zcl_zlk05_sys_api=>rfc_type_text( lv_key ) }| )
             TO mt_types.
    ENDLOOP.

  ENDMETHOD.


  METHOD on_event.

    CLEAR: mv_message, mv_msgtype.

    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = client->get_event( )
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_search.

    mt_dest = zcl_zlk05_sys_api=>get_rfc_destinations( iv_pattern = mv_pattern
                                                       iv_rfctype = mv_type ).
    IF mt_dest IS INITIAL.
      mv_message = `No RFC destinations found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_dest ) } RFC destination(s) displayed.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Connection` ) ( `Edit` ) ( `Goto` ) ( `Utilities(M)` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Configuration of RFC Connections` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Search` icon = `sap-icon://search`
              tooltip = `Select the RFC destinations (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://create` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create - { c_na }| )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( sep = abap_true )
            ( text = `Connection Test` icon = `sap-icon://connected`
              tooltip = |Connection Test - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `RFC Destination` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idRfcDest`
        )->a( n = `value`       v = client->_bind( mv_pattern )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `16rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Connection Type` ).
    DATA(sel) = row->ele( `Select`
        )->a( n = `selectedKey` v = client->_bind( mv_type )
        )->a( n = `items`       v = client->_bind( mt_types )
        )->a( n = `width`       v = `18rem` ).
    sel->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `{KEY}`
        )->a( n = `text` v = `{TEXT}` ).
    sel->end( ).
    row->end( ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_dest )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `RFC Destination|RFCDEST|18rem` )
        ( `Type|RFCTYPE|4rem` )
        ( `Connection Type|TYPETEXT|14rem` )
        ( `Target Host|TARGET|16rem` )
        ( `Instance No.|SYSNR|6rem` )
        ( `Description|DESCR|22rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - logon data is never shown, no connection is changed or tested here`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
