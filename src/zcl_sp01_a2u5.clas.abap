CLASS zcl_sp01_a2u5 DEFINITION PUBLIC
  INHERITING FROM zcl_zlk05_screen.

* ---------------------------------------------------------------------
*  SP01 - Output Controller (display)
*
*  Selection of spool requests (created by, created as of) and the list
*  of the original with status, pages and title. The status column is
*  computed like RSPO_RSTATUS_FOR_SPOOLREQ. A click on a spool request
*  shows its content as text (RSPO_RETURN_ABAP_SPOOLJOB, ABAP lists).
*  Printing, deleting and changing attributes are present in the toolbar
*  but disabled - this app never touches a spool request.
*
*  Authorization: S_TCODE SP01, then per spool request exactly what SP01
*  asks for - RSPO_CHECK_JOB_PERMISSION BASE for the list and DISP for
*  the content (S_ADMI_FCD SP0R / SP01 and S_SPO_ACT for other users).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_zlk05_start_params.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_owner     TYPE string.
    DATA mv_date_from TYPE string.
    DATA mt_spool     TYPE zcl_zlk05_sys_api=>ty_t_spool.
    DATA mv_content   TYPE string.

  PROTECTED SECTION.
    DATA mv_mode    TYPE string.
    DATA mv_current TYPE string.
    DATA mv_lines   TYPE i.

    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS view_list.
    METHODS view_content.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_rqident TYPE string.
    METHODS date_from_input
      RETURNING VALUE(result) TYPE d.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sp01_a2u5 IMPLEMENTATION.


  METHOD zif_zlk05_start_params~set_start_params.
    " SP01 for another user - e.g. from the user maintenance
    mv_owner = to_upper( condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_user ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD on_init.

    mv_mode = `LIST`.
    IF mv_owner IS INITIAL.
      mv_owner = sy-uname.
    ENDIF.
    " the selection screen of SP01 proposes today
    mv_date_from = |{ sy-datum }|.
    do_search( ).
    render( ).

  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN 'EXECUTE' OR 'REFRESH'.
        do_search( ).
      WHEN 'DISPLAY'.
        do_open( client->get_event_arg( ) ).
      WHEN 'BACK_TO_LIST'.
        mv_mode = `LIST`.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD render.

    IF mv_mode = `CONTENT`.
      view_content( ).
    ELSE.
      view_list( ).
    ENDIF.

  ENDMETHOD.


  METHOD menu_entries.
    result = VALUE #( ( `Spool Request` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                      ( `System` ) ( `Help` ) ).
  ENDMETHOD.


  METHOD date_from_input.
    " an unusable value falls back to today, never to an open selection
    result = zcl_zlk05_sys_api=>parse_date( iv_in = mv_date_from iv_default = sy-datum ).
  ENDMETHOD.


  METHOD do_search.

    DATA(lv_from) = date_from_input( ).
    mv_date_from  = |{ lv_from }|.
    mv_owner      = to_upper( condense( mv_owner ) ).

    mt_spool = zcl_zlk05_sys_api=>get_spool_requests( iv_owner     = mv_owner
                                                      iv_date_from = lv_from ).
    mv_mode = `LIST`.

    IF mt_spool IS INITIAL.
      mv_message = |No spool requests of { mv_owner } as of { zcl_zlk05_sys_api=>format_date( lv_from ) }.|.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_spool ) } spool request(s) displayed.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR: mv_content, mv_lines.

    zcl_zlk05_sys_api=>get_spool_content(
      EXPORTING iv_rqident = iv_rqident
      IMPORTING et_lines   = DATA(lt_lines)
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    mv_current = iv_rqident.
    mv_lines   = lines( lt_lines ).
    mv_content = concat_lines_of( table = lt_lines sep = cl_abap_char_utilities=>newline ).
    mv_mode    = `CONTENT`.
    mv_message = |Spool request { iv_rqident }: { mv_lines } line(s) displayed in character format.|.
    mv_msgtype = `Information`.

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
        iv_title  = `Output Controller: List of Spool Requests` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Execute` icon = `sap-icon://begin`
              tooltip = `Select the spool requests (F8)`
              press = client->_event( `EXECUTE` ) )
            ( icon = `sap-icon://refresh`
              tooltip = `Refresh`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print Directly - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Attributes - { c_na }| )
            ( icon = `sap-icon://pdf-attachment` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display as PDF - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " the selection screen of SP01: Created By and Date Created
    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Created By` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idSpoolOwner`
        )->a( n = `value`       v = client->_bind( mv_owner )
        )->a( n = `placeholder` v = `user, * for all`
        )->a( n = `width`       v = `12rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Date Created` ).
    row->tag( `Input`
        )->a( n = `id`      v = `idSpoolDate`
        )->a( n = `value`   v = client->_bind( mv_date_from )
        )->a( n = `width`   v = `9rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` )
        )->a( n = `tooltip` v = `Spool requests created as of this date (YYYYMMDD)` ).
    row->end( ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_spool )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the columns of the SP01 list
    DATA(lt_col) = VALUE string_table(
        ( `Spool No.|RQIDENT|7rem` )
        ( `Type|DOCTYPE|5rem` )
        ( `Date|DATE|6rem` )
        ( `Time|TIME|5rem` )
        ( `Status|STATUS|7rem` )
        ( `Pages|PAGES|4rem` )
        ( `Title|TITLE|24rem` )
        ( `Created By|OWNER|9rem` )
        ( `Output Device|DEST|8rem` ) ).

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
      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      CASE lv_fld.
        WHEN `RQIDENT`.
          " the spool request number opens its content, like the
          " Display Contents function of the original
          tmpl->tag( `Link`
              )->a( n = `text`  v = `{RQIDENT}`
              )->a( n = `press` v = client->_event( val = `DISPLAY` arg = `${RQIDENT}` ) ).
        WHEN `STATUS`.
          tmpl->tag( `ObjectStatus`
              )->a( n = `text`  v = `{STATUS}`
              )->a( n = `state` v = `{STATE}` ).
        WHEN OTHERS.
          tmpl->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      ENDCASE.
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no spool request is printed, changed or deleted here. Choose a spool number to display its content`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_content.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    " second screen: Back returns to the list
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Spool Request { mv_current }|
        iv_hint   = |{ mv_lines } line(s)| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the list (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print - { c_na }| )
            ( icon = `sap-icon://download` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Download - { c_na }| ) ) ).

    " the list in character format - fixed width, like the SAP GUI list
    page->tag( n = `CodeEditor` ns = `editor`
        )->a( n = `value`    v = client->_bind( mv_content )
        )->a( n = `type`     v = `text`
        )->a( n = `height`   v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `width`    v = `100%`
        )->a( n = `editable` v = `false` ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
