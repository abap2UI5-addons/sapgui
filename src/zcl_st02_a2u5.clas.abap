CLASS zcl_st02_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  ST02 - Tune Summary
*
*  Screen title, menu bar and function texts are the original ones of
*  program RSTUNE50 (RSMPTEXTS):
*
*    T 000    Tune Summary (&)
*      001    Tune: Detail Analysis (&)
*      100    Tune: Detail Analysis Menu (&)
*    M        List  Edit  Goto  Environment
*    F  &NTE  Refresh              &ETA  Details
*       SHMN  Shared Memory Detail SHMT  Shared Memory Technical
*       ST03N Response times       TUNE  Tune setups/buffers
*       NEWA  Other tune           CTLGA Catalog
*
*  The app reads the buffer and memory statistics of the own instance.
*  It never changes a buffer parameter.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command  TYPE string.

    DATA mt_buffer  TYPE zcl_zlk05_sys_api=>ty_t_buffer.
    DATA mt_memory  TYPE zcl_zlk05_sys_api=>ty_t_kv.

  PROTECTED SECTION.
    DATA mv_message  TYPE string.
    DATA mv_msgtype TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS on_event.
    METHODS do_refresh.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_st02_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      do_refresh( ).
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
        iv_event   = client->get_event( )
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE client->get_event( ).
      WHEN 'REFRESH'.
        do_refresh( ).
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_refresh.

    CLEAR: mt_buffer, mt_memory.

    zcl_zlk05_sys_api=>get_buffer_stats(
      IMPORTING et_buffer  = mt_buffer
                et_memory  = mt_memory
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_buffer ) } buffer(s) monitored.|.
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
        it_entries = VALUE #( ( `List` ) ( `Edit` ) ( `Goto` )
                              ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " T 000 - Tune Summary (&)
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Tune Summary ({ sy-host })| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read the buffer statistics again`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Detail analysis` icon = `sap-icon://detail-view`
              tooltip = |Tune: Detail Analysis Menu - { c_na }| )
            ( text = `Current parameters` icon = `sap-icon://action-settings`
              tooltip = |Tune setups/buffers - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://database` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Shared Memory Detail - { c_na }| )
            ( icon = `sap-icon://technical-object` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Shared Memory Technical - { c_na }| )
            ( icon = `sap-icon://performance` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Response times (ST03N) - { c_na }| )
            ( icon = `sap-icon://it-instance` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Other tune - { c_na }| )
            ( icon = `sap-icon://tree` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Catalog - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://sort-ascending` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| )
            ( icon = `sap-icon://excel-attachment` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Spreadsheet - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " ===== Buffer statistics =====
    work->tag( `Title`
        )->a( n = `text`  v = `Buffer`
        )->a( n = `level` v = `H4` ).

    DATA(bgrid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_buffer )
        )->a( n = `visibleRowCountMode` v = `Fixed`
        )->a( n = `visibleRowCount`     v = `12`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `class`               v = `sapUiTinyMarginTop` ).

    DATA(bcols) = bgrid->ele( n = `columns` ns = `table` ).

    " the column sequence of the original ST02 buffer list
    DATA(lt_bcol) = VALUE string_table(
        ( `Buffer|NAME|16rem` )
        ( `HitRatio %|HITRATIO|7rem` )
        ( `Alloc. KB|ALLOC_SIZE|8rem` )
        ( `Free space KB|FREE_SPACE|9rem` )
        ( `Dir. entries used|DIR_USED|10rem` )
        ( `Dir. entries free|DIR_FREE|10rem` )
        ( `Swaps|SWAPS|7rem` )
        ( `DB accesses|DB_ACCESS|9rem` ) ).

    LOOP AT lt_bcol INTO DATA(lv_bcol).
      SPLIT lv_bcol AT `|` INTO DATA(lv_bhead) DATA(lv_bfld) DATA(lv_bwid).
      DATA(bcol) = bcols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_bwid
          )->a( n = `sortProperty`   t = lv_bfld
          )->a( n = `filterProperty` t = lv_bfld ).
      bcol->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_bhead )->end( )->end( ).
      bcol->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_bfld }\}|
              )->a( n = `wrapping` v = `false` ).
      bcol->end( ).
    ENDLOOP.

    bgrid->end( ).

    " ===== SAP memory =====
    work->tag( `Title`
        )->a( n = `text`  v = `SAP Memory`
        )->a( n = `level` v = `H4`
        )->a( n = `class` v = `sapUiMediumMarginTop` ).

    DATA(mgrid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_memory )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `None`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `6`
        )->a( n = `class`               v = `sapUiTinyMarginTop` ).

    DATA(mcols) = mgrid->ele( n = `columns` ns = `table` ).

    DATA(lt_mcol) = VALUE string_table(
        ( `Key Figure|LABEL|24rem` )
        ( `Value|VALUE|14rem` ) ).

    LOOP AT lt_mcol INTO DATA(lv_mcol).
      SPLIT lv_mcol AT `|` INTO DATA(lv_mhead) DATA(lv_mfld) DATA(lv_mwid).
      DATA(mcol) = mcols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_mwid
          )->a( n = `sortProperty`   t = lv_mfld
          )->a( n = `filterProperty` t = lv_mfld ).
      mcol->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_mhead )->end( )->end( ).
      mcol->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_mfld }\}|
              )->a( n = `wrapping` v = `false` ).
      mcol->end( ).
    ENDLOOP.

    mgrid->end( ).

    work->tag( `Text`
        )->a( n = `text`  v = `Read via SAPTUNE_GET_SUMMARY_STATISTIC - display only`
        )->a( n = `class` v = `sapUiTinyMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
