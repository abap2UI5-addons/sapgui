CLASS zcl_we02_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  WE02 / WE05 - IDoc List (display)
*
*  Selection by creation date, IDoc number, current status, message type
*  and direction (program RSEIDOC2), the IDoc list with the traffic light
*  of the status customizing (STACUST / STALIGHT), and the IDoc display:
*  control record, status records and data records (IDOC_READ_COMPLETELY).
*  Reprocessing and editing an IDoc are present but disabled.
*
*  Authorization: S_TCODE + S_IDOCMONI display for WE02 (or WE05), then
*  per IDoc the S_IDOCMONI check of RSEIDOC2 with direction, message type
*  and partner, and the customer BAdI IDOC_AUTHORITY_RESTRICTION.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command   TYPE string.
    DATA mv_date_from TYPE string.
    DATA mv_date_to   TYPE string.
    DATA mv_docnum    TYPE string.
    DATA mv_status    TYPE string.
    DATA mv_mestyp    TYPE string.
    DATA mv_direct    TYPE string.
    DATA mt_idocs     TYPE zcl_zlk05_sys_api=>ty_t_idoc.

    DATA mt_control   TYPE zcl_zlk05_sys_api=>ty_t_kv.
    DATA mt_status    TYPE zcl_zlk05_sys_api=>ty_t_idoc_status.
    DATA mt_segments  TYPE zcl_zlk05_sys_api=>ty_t_idoc_seg.
    DATA mv_tab       TYPE string.

    TYPES:
      BEGIN OF ty_s_key,
        key  TYPE string,
        text TYPE string,
      END OF ty_s_key.
    TYPES ty_t_key TYPE STANDARD TABLE OF ty_s_key WITH EMPTY KEY.
    DATA mt_directions TYPE ty_t_key.

  PROTECTED SECTION.
    DATA ms_idoc TYPE zcl_zlk05_sys_api=>ty_s_idoc.
    DATA mv_mode    TYPE string.
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_event.
    METHODS render.
    METHODS view_list.
    METHODS view_detail.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_docnum TYPE string.
    METHODS parse_date
      IMPORTING iv_in         TYPE string
                iv_default    TYPE d
      RETURNING VALUE(result) TYPE d.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.
    METHODS add_grid
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_rows   TYPE string
                it_cols   TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_we02_a2u5 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    " S_TCODE + S_IDOCMONI - on EVERY roundtrip, so the app is protected
    " even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode       = `LIST`.
      " the selection screen of RSEIDOC2 proposes today
      mv_date_from  = |{ sy-datum }|.
      mv_date_to    = |{ sy-datum }|.
      mt_directions = VALUE #( ( key = ``  text = `Both directions` )
                               ( key = `1` text = `1 - Outbound` )
                               ( key = `2` text = `2 - Inbound` ) ).
      do_search( ).
      render( ).
    ELSEIF client->check_on_navigated( ).
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

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
      WHEN 'DISPLAY'.
        do_open( client->get_event_arg( ) ).
      WHEN 'REFRESH_DETAIL'.
        do_open( ms_idoc-docnum ).
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
      view_list( ).
    ENDIF.

  ENDMETHOD.


  METHOD menu_entries.
    result = VALUE #( ( `IDoc` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                      ( `System` ) ( `Help` ) ).
  ENDMETHOD.


  METHOD parse_date.
    result = zcl_zlk05_sys_api=>parse_date( iv_in = iv_in iv_default = iv_default ).
  ENDMETHOD.


  METHOD do_search.

    " an IDoc number selects that IDoc whatever its date - otherwise the
    " creation date limits the list, like the selection screen of WE02
    DATA(lv_from) = parse_date( iv_in = mv_date_from iv_default = sy-datum ).
    DATA(lv_to)   = parse_date( iv_in = mv_date_to   iv_default = sy-datum ).
    mv_date_from  = |{ lv_from }|.
    mv_date_to    = |{ lv_to }|.

    DATA(lv_docnum) = condense( mv_docnum ).
    IF lv_docnum IS NOT INITIAL.
      mt_idocs = zcl_zlk05_sys_api=>get_idocs( iv_docnum = mv_docnum ).
    ELSE.
      mt_idocs = zcl_zlk05_sys_api=>get_idocs( iv_mestyp    = mv_mestyp
                                               iv_status    = mv_status
                                               iv_direct    = mv_direct
                                               iv_date_from = lv_from
                                               iv_date_to   = lv_to ).
    ENDIF.
    mv_mode = `LIST`.

    IF mt_idocs IS INITIAL.
      mv_message = `No IDocs selected for the selection criteria.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_idocs ) } IDoc(s) selected.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    zcl_zlk05_sys_api=>get_idoc_detail(
      EXPORTING iv_docnum   = iv_docnum
      IMPORTING es_idoc     = DATA(ls_idoc)
                et_control  = DATA(lt_control)
                et_status   = DATA(lt_status)
                et_segments = DATA(lt_segments)
                ev_message  = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    ms_idoc     = ls_idoc.
    mt_control  = lt_control.
    mt_status   = lt_status.
    mt_segments = lt_segments.
    IF mv_tab IS INITIAL.
      mv_tab = `STATUS`.
    ENDIF.
    mv_mode = `DETAIL`.

  ENDMETHOD.


  METHOD add_grid.

    " it_cols: Heading|FIELD|width - a field STATUS / STATTEXT is shown
    " coloured by the STATE of the row, a field DOCNUM opens the IDoc
    DATA(grid) = io_parent->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = iv_rows
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `8` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    LOOP AT it_cols INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      CASE lv_fld.
        WHEN `DOCNUM`.
          tmpl->tag( `Link`
              )->a( n = `text`  v = `{DOCNUM}`
              )->a( n = `press` v = client->_event( val = `DISPLAY` arg = `${DOCNUM}` ) ).
        WHEN `STATUS` OR `STATTEXT`.
          tmpl->tag( `ObjectStatus`
              )->a( n = `text`  v = |\{{ lv_fld }\}|
              )->a( n = `state` v = `{STATE}` ).
        WHEN OTHERS.
          tmpl->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      ENDCASE.
      col->end( ).
    ENDLOOP.

  ENDMETHOD.


  METHOD view_list.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `IDoc List` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Execute` icon = `sap-icon://begin`
              tooltip = `Select the IDocs (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://process` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Process (BD87) - { c_na }| )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Edit Data Record - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " selection screen of RSEIDOC2 - the most used criteria
    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Created On` ).
    row->tag( `Input`
        )->a( n = `id`      v = `idIdocFrom`
        )->a( n = `value`   v = client->_bind( mv_date_from )
        )->a( n = `width`   v = `8rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` )
        )->a( n = `tooltip` v = `YYYYMMDD` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `to` iv_width = `2.5rem` ).
    row->tag( `Input`
        )->a( n = `id`      v = `idIdocTo`
        )->a( n = `value`   v = client->_bind( mv_date_to )
        )->a( n = `width`   v = `8rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` )
        )->a( n = `tooltip` v = `YYYYMMDD` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `IDoc Number` ).
    row->tag( `Input`
        )->a( n = `id`      v = `idIdocNumber`
        )->a( n = `value`   v = client->_bind( mv_docnum )
        )->a( n = `width`   v = `10rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` )
        )->a( n = `tooltip` v = `An IDoc number selects that IDoc regardless of the other criteria` ).
    row->end( ).

    row = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Current Status` ).
    row->tag( `Input`
        )->a( n = `id`     v = `idIdocStatus`
        )->a( n = `value`  v = client->_bind( mv_status )
        )->a( n = `width`  v = `4rem`
        )->a( n = `submit` v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Message Type` ).
    row->tag( `Input`
        )->a( n = `id`     v = `idIdocMestyp`
        )->a( n = `value`  v = client->_bind( mv_mestyp )
        )->a( n = `width`  v = `12rem`
        )->a( n = `submit` v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Direction` ).
    DATA(sel) = row->ele( `Select`
        )->a( n = `selectedKey` v = client->_bind( mv_direct )
        )->a( n = `items`       v = client->_bind( mt_directions )
        )->a( n = `width`       v = `12rem` ).
    sel->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = `{KEY}`
        )->a( n = `text` v = `{TEXT}` ).
    sel->end( ).
    row->end( ).

    add_grid( io_parent = work
              iv_rows   = client->_bind( mt_idocs )
              it_cols   = VALUE #(
                  ( `IDoc Number|DOCNUM|9rem` )
                  ( `Status|STATUS|4rem` )
                  ( `Status Text|STATTEXT|20rem` )
                  ( `Direction|DIRECT|6rem` )
                  ( `Message Type|MESTYP|10rem` )
                  ( `Basic Type|IDOCTP|10rem` )
                  ( `Partner|PARTNER|11rem` )
                  ( `Created On|CREDAT|6rem` )
                  ( `Time|CRETIM|5rem` )
                  ( `Changed On|UPDDAT|6rem` )
                  ( `Time|UPDTIM|5rem` ) ) ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `IDoc display`
        iv_hint   = |IDoc { ms_idoc-docnum } - { ms_idoc-mestyp } - status { ms_idoc-status }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the IDoc list (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( icon = `sap-icon://refresh`
              tooltip = `Read the IDoc again`
              press = client->_event( `REFRESH_DETAIL` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://process` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Process - { c_na }| )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Edit - { c_na }| ) ) ).

    DATA(tabs) = page->ele( `IconTabBar`
        )->a( n = `selectedKey`          v = client->_bind( mv_tab )
        )->a( n = `expandable`           v = `false`
        )->a( n = `stretchContentHeight` v = `true`
        )->a( n = `height`               v = zcl_zlk05_gui_frame=>c_work_height
        )->ele( `items` ).

    " --- Status records: the history of the IDoc, newest first
    DATA(c1) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `Status Records`
        )->a( n = `key`   v = `STATUS`
        )->a( n = `count` t = |{ lines( mt_status ) }|
        )->ele( `content` ).
    add_grid( io_parent = c1
              iv_rows   = client->_bind( mt_status )
              it_cols   = VALUE #(
                  ( `No.|COUNTER|3rem` )
                  ( `Status|STATUS|4rem` )
                  ( `Status Text|STATTEXT|16rem` )
                  ( `Message|MESSAGE|30rem` )
                  ( `Date|DATE|6rem` )
                  ( `Time|TIME|5rem` )
                  ( `User|USER|8rem` )
                  ( `Program|PROGRAM|12rem` ) ) ).
    c1->end( )->end( ).

    " --- Data records: the segments in their hierarchy
    DATA(c2) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `Data Records`
        )->a( n = `key`   v = `DATA`
        )->a( n = `count` t = |{ lines( mt_segments ) }|
        )->ele( `content` ).
    add_grid( io_parent = c2
              iv_rows   = client->_bind( mt_segments )
              it_cols   = VALUE #(
                  ( `Segment No.|SEGNUM|6rem` )
                  ( `Segment|TREE|16rem` )
                  ( `Level|HLEVEL|3rem` )
                  ( `Segment Data|SDATA|60rem` ) ) ).
    c2->end( )->end( ).

    " --- Control record
    DATA(c3) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Control Record`
        )->a( n = `key`  v = `CONTROL`
        )->ele( `content` ).
    add_grid( io_parent = c3
              iv_rows   = client->_bind( mt_control )
              it_cols   = VALUE #( ( `Field|LABEL|14rem` ) ( `Value|VALUE|40rem` ) ) ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
