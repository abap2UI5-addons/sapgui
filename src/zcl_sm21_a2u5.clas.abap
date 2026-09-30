CLASS zcl_sm21_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SM21 - System Log
*
*  Screen title, menu bar and function texts are the original ones of
*  RSLG0000 / SAPMSM21 (RSMPTEXTS):
*
*    T 100    System Log: Local Analysis of &
*    M        System log  Edit  Goto  Environment
*    F  &ETA  Details      DOC1  System Log Documentation
*       ENT+  Next Entry   ENT-  Previous Entry
*       DVTR  Display Developer Trace
*       SLGN  Use New System Log Transaction
*
*  The app reads the local system log of the own instance. Everything
*  the original screen offers is present - what cannot be done here is
*  shown as a disabled button with a tooltip.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_date_from TYPE string.
    DATA mv_date_to   TYPE string.
    DATA mv_user      TYPE string.
    DATA mv_tcode     TYPE string.
    DATA mv_command    TYPE string.
    DATA mv_message    TYPE string.
    DATA mv_msgtype   TYPE string.
    DATA mt_syslog    TYPE zcl_zlk05_sys_api=>ty_t_syslog.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS do_search.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sm21_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_date_from = CONV string( sy-datum ).
      mv_date_to   = CONV string( sy-datum ).
      do_search( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 / the Back arrow and handed
      " control back to this one. The framework supplies an EMPTY event here
      " and check_on_init is already false, so without this branch nothing
      " would be rendered: the response would carry no view and the browser
      " would keep showing the screen of the transaction that was just left.
      " That is what made Back look dead and F3 only work on the second try.
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = client->get( )-event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE client->get( )-event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_search.

    DATA lv_from TYPE d.
    DATA lv_to   TYPE d.

    CLEAR mt_syslog.

    TRY.
        lv_from = condense( mv_date_from ).
        lv_to   = condense( mv_date_to ).
      CATCH cx_root.
        mv_message = `Please enter the date as YYYYMMDD.`.
        mv_msgtype = `Error`.
        RETURN.
    ENDTRY.

    IF lv_from IS INITIAL.
      lv_from = sy-datum.
    ENDIF.
    IF lv_to IS INITIAL.
      lv_to = sy-datum.
    ENDIF.

    zcl_zlk05_sys_api=>get_syslog(
      EXPORTING iv_date_from = lv_from
                iv_date_to   = lv_to
                iv_user      = mv_user
                iv_tcode     = mv_tcode
      IMPORTING et_syslog    = mt_syslog
                ev_message   = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Information`.
    ELSE.
      mv_message = |{ lines( mt_syslog ) } system log entry/entries selected.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " M - the menu bar of the SM21 entry screen
    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `System log` ) ( `Edit` ) ( `Goto` )
                              ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " T 100 - System Log: Local Analysis of &
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = |System Log: Local Analysis of { sy-host }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Reread System Log` icon = `sap-icon://begin`
              tooltip = `Read the local system log again (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( text = `Details` icon = `sap-icon://detail-view`
              tooltip = |Details - { c_na }| )
            ( text = `System Log Documentation` icon = `sap-icon://document-text`
              tooltip = |System Log Documentation - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://navigation-up-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Previous Entry - { c_na }| )
            ( icon = `sap-icon://navigation-down-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Next Entry - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find String - { c_na }| )
            ( icon = `sap-icon://sort-ascending` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Layout... - { c_na }| )
            ( icon = `sap-icon://excel-attachment` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Local File... - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://detail-more` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Developer Trace - { c_na }| )
            ( icon = `sap-icon://request` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Use New System Log Transaction - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " ----- the selection block of the entry screen -----
    DATA(row) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `From Date/Time` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idLogFrom`
        )->a( n = `value`       v = client->_bind( mv_date_from )
        )->a( n = `placeholder` v = `YYYYMMDD`
        )->a( n = `width`       v = `10rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `To Date/Time` ).
    row->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_date_to )
        )->a( n = `placeholder` v = `YYYYMMDD`
        )->a( n = `width`       v = `10rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row->end( ).

    DATA(row2) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `User` ).
    row2->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_user )
        )->a( n = `placeholder` v = `blank for all`
        )->a( n = `width`       v = `10rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `Transaction Code` ).
    row2->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_tcode )
        )->a( n = `placeholder` v = `blank for all`
        )->a( n = `width`       v = `10rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row2->end( ).

    DATA(row3) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row3 iv_text = `Problem Class` ).
    row3->tag( `Input`
        )->a( n = `value`   v = `All messages`
        )->a( n = `enabled` v = `false`
        )->a( n = `width`   v = `10rem`
        )->a( n = `tooltip` v = |Problem class restriction - { c_na }| ).
    row3->tag( `Button`
        )->a( n = `text`    v = `System Log: Further Restrictions`
        )->a( n = `icon`    v = `sap-icon://filter`
        )->a( n = `enabled` v = `false`
        )->a( n = `class`   v = `sapUiMediumMarginBegin`
        )->a( n = `tooltip` v = |System Log: Further Restrictions - { c_na }| ).
    row3->end( ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idLogFrom` ) ) ).

    " the result list - the original SM21 shows it as an ALV grid
    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_syslog )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the column sequence of the original system log list
    DATA(lt_col) = VALUE string_table(
        ( `Date|DATE|6rem` )
        ( `Time|TIME|5rem` )
        ( `Type|TASK|5rem` )
        ( `Cl.|MAND|4rem` )
        ( `User|USER|9rem` )
        ( `TCode|TCODE|6rem` )
        ( `Program|REPNA|14rem` )
        ( `MNo|CLASID|5rem` )
        ( `Message Text|TEXT|40rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` v = lv_wid ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` v = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = |Local system log of instance { sy-host }|
        )->a( n = `class` v = `sapUiTinyMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
