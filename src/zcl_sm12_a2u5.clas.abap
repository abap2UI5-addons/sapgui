CLASS zcl_sm12_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SM12 - Lock Entries
*
*  Two screens with the original titles of program RSSM_SM12_OLD:
*
*    SEL   Select Lock Entries   (T SEL)
*    LIST  Lock Entry List       (T ENQ)
*
*  Deleting a lock entry is what makes SM12 dangerous - that function is
*  shown as a disabled original button, it is not implemented.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_table   TYPE string.
    DATA mv_user    TYPE string.
    DATA mv_arg     TYPE string.
    DATA mv_mode    TYPE string.
    DATA mv_command  TYPE string.
    DATA mv_message  TYPE string.
    DATA mv_msgtype TYPE string.
    DATA mt_locks   TYPE zcl_zlk05_sys_api=>ty_t_lock.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_list.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed twice:
    "! after an event that only changed the mode, and - most importantly -
    "! when the transaction is navigated back to from another one, where the
    "! framework supplies no event at all.
    METHODS render.
    METHODS do_search.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sm12_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `SEL`.
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

    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA lv_frame TYPE string.
    zcl_zlk05_gui_frame=>handle_frame_event(
      EXPORTING io_client   = client
                iv_event    = client->get( )-event
                iv_command  = mv_command
      IMPORTING ev_message  = mv_message
                ev_msg_type = mv_msgtype
      RECEIVING result      = lv_frame ).
    IF lv_frame = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE client->get( )-event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'BACK_TO_SEL'.
        mv_mode = `SEL`.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.

  METHOD render.

    IF mv_mode = `LIST`.
      view_list( ).
    ELSE.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_locks.

    zcl_zlk05_sys_api=>get_locks(
      EXPORTING iv_table   = mv_table
                iv_user    = mv_user
      IMPORTING et_locks   = mt_locks
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
      mv_mode    = `SEL`.
      RETURN.
    ENDIF.

    IF lines( mt_locks ) = 0.
      mv_message = `No lock entries were selected.`.
      mv_msgtype = `Information`.
      mv_mode    = `SEL`.
    ELSE.
      mv_message = |{ lines( mt_locks ) } lock entry(s) selected.|.
      mv_msgtype = `Information`.
      mv_mode    = `LIST`.
    ENDIF.

  ENDMETHOD.


* ---------------------------------------------------------------------
*  Screen 1 - Select Lock Entries
* ---------------------------------------------------------------------
  METHOD view_display.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `List` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_parent = page
                                          iv_title  = `Select Lock Entries` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `List` icon = `sap-icon://locked`
              tooltip = `Select the lock entries (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_gold
              tooltip = |Get Variant... - { c_na }| ) ) ).

    DATA(work) = page->open( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `false`
        )->a( n = `class`      v = `sapUiSmallMarginBegin` ).

    DATA(panel) = work->open( `Panel`
        )->a( n = `headerText` v = `Lock Entry Selection`
        )->a( n = `width`      v = `44rem`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->open( `content`
        )->open( `VBox` )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(row) = panel->open( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Table Name`
                                    iv_width  = `11rem` ).
    row->leaf( `Input`
        )->a( n = `id`          v = `idLockTab`
        )->a( n = `value`       v = client->_bind( mv_table )
        )->a( n = `placeholder` v = `blank for all`
        )->a( n = `width`       v = `16rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    row = panel->open( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Lock argument`
                                    iv_width  = `11rem` ).
    row->leaf( `Input`
        )->a( n = `value`   v = client->_bind( mv_arg )
        )->a( n = `width`   v = `16rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = |Selection by lock argument - { c_na }| ).

    row = panel->open( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Client`
                                    iv_width  = `11rem` ).
    row->leaf( `Input`
        )->a( n = `value`   v = CONV string( sy-mandt )
        )->a( n = `width`   v = `5rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` v = `The lock table is read for all clients` ).

    row = panel->open( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `User Name`
                                    iv_width  = `11rem` ).
    row->leaf( `Input`
        )->a( n = `value`       v = client->_bind( mv_user )
        )->a( n = `placeholder` v = `blank for all`
        )->a( n = `width`       v = `12rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idLockTab` ) ) ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


* ---------------------------------------------------------------------
*  Screen 2 - Lock Entry List
* ---------------------------------------------------------------------
  METHOD view_list.

    DATA(view) = z2ui5_cl_ai_xml=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `List` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_SEL` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_parent = page
                                          iv_title  = `Lock Entry List` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read the lock table again`
              press = client->_event( `EXECUTE` ) )
            ( text = `Selection` icon = `sap-icon://filter`
              tooltip = `Back to the selection screen`
              press = client->_event( `BACK_TO_SEL` ) )
            ( sep = abap_true )
            ( text = `Details` icon = `sap-icon://detail-view`
              tooltip = |Lock Entry Details - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete lock entry - { c_na }, this app never writes| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://sort-ascending` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Layout... - { c_na }| ) ) ).

    DATA(work) = page->open( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->open( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_locks )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->open( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Client|GCLIENT|5rem` )
        ( `User|GUNAME|10rem` )
        ( `Table|GNAME|12rem` )
        ( `Lock Argument|GARG|26rem` )
        ( `Mode|GMODE|5rem` )
        ( `Count|GUSECNT|5rem` )
        ( `Time|GTTIME|6rem` )
        ( `Host|GTHOST|12rem` ) ).

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
        )->a( n = `text`  v = `Display only - lock entries are not deleted here`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_SEL`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
