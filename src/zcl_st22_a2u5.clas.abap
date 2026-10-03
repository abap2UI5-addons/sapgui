CLASS zcl_st22_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  ST22 - ABAP Runtime Errors
*
*  Like the original transaction this app has three screens, each with
*  its own title from RSMPTEXTS of program RSSHOWRABAX:
*
*    SEL     ABAP Runtime Errors - Client &1      (SELDUMP_CLIENT_SPEC)
*    LIST    List of Selected Runtime Errors      (ALV100)
*    DETAIL  Runtime Error Long Text              (SNAP)
*
*  The buttons of the application function bar carry the original
*  function texts of RSSHOWRABAX. Functions this environment cannot
*  offer are shown the SAP GUI way - present but disabled with a
*  tooltip that says why.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.
    INTERFACES zif_zlk05_start_params.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_errorid   TYPE string.
    DATA mv_date_from TYPE string.
    DATA mv_date_to   TYPE string.
    DATA mv_user      TYPE string.
    DATA mv_command    TYPE string.
    DATA mt_dumps     TYPE zcl_zlk05_sys_api=>ty_t_dump.
    DATA mt_detail    TYPE zcl_zlk05_sys_api=>ty_t_kv.

  PROTECTED SECTION.
    DATA mv_mode      TYPE string.
    DATA mv_current   TYPE string.
    DATA mv_message    TYPE string.
    DATA mv_msgtype   TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_list.
    METHODS view_detail.
    METHODS on_event.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_key TYPE string.
    METHODS render.

    "! Started from another transaction (SM21) with date and user: the
    "! selection runs at once, and Back from the list returns there
    DATA mv_start_date TYPE string.
    DATA mv_start_user TYPE string.
    DATA mv_called     TYPE abap_bool.

  PRIVATE SECTION.
    METHODS date_from_input
      RETURNING VALUE(result) TYPE d.
ENDCLASS.


CLASS zcl_st22_a2u5 IMPLEMENTATION.

  METHOD zif_zlk05_start_params~set_start_params.
    mv_start_date = condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_date ]-value OPTIONAL ) ).
    mv_start_user = to_upper( condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_user ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode      = `SEL`.
      mv_date_from = |{ sy-datum - 7 }|.
      mv_date_to   = |{ sy-datum }|.
      IF mv_start_date IS NOT INITIAL OR mv_start_user IS NOT INITIAL.
        mv_called = abap_true.
        IF mv_start_date IS NOT INITIAL.
          mv_date_from = mv_start_date.
        ENDIF.
        mv_user = mv_start_user.
        do_search( ).
      ENDIF.
      render( ).
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

    DATA(lv_event) = client->get_event( ).
    DATA(lv_arg)   = client->get_event_arg( ).
    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = lv_event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE lv_event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        IF lv_arg IS NOT INITIAL.
          do_open( lv_arg ).
        ENDIF.
      WHEN 'BACK_TO_LIST'.
        mv_mode = `LIST`.
      WHEN 'BACK_TO_SEL'.
        IF mv_called = abap_true.
          client->nav_app_leave( ).
          RETURN.
        ENDIF.
        mv_mode = `SEL`.
      WHEN 'GOTO_PROGRAM'.
        " like the original: jump into the ABAP Editor with the program of
        " the dump - through the router, so SE38 is checked like typed in
        DATA(lv_prog) = VALUE string( mt_detail[ label = `Program` ]-value OPTIONAL ).
        IF lv_prog IS INITIAL.
          mv_message = `The dump does not name a program.`.
          mv_msgtype = `Warning`.
        ELSE.
          DATA(ls_run) = zcl_zlk05_tcode_router=>run(
              iv_command = `SE38`
              io_client  = client
              it_params  = VALUE #( ( name  = zif_zlk05_start_params=>c_program
                                      value = lv_prog ) ) ).
          IF ls_run-outcome = zcl_zlk05_tcode_router=>c_nav.
            RETURN.
          ENDIF.
          mv_message = ls_run-message.
          mv_msgtype = ls_run-msg_type.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD render.

    CASE mv_mode.
      WHEN `DETAIL`.
        view_detail( ).
      WHEN `LIST`.
        view_list( ).
      WHEN OTHERS.
        view_display( ).
    ENDCASE.

  ENDMETHOD.


  METHOD date_from_input.
    " An unusable value falls back to a week ago instead of selecting the
    " whole SNAP table.
    DATA(lv_week_ago) = CONV d( sy-datum - 7 ).
    result = zcl_zlk05_sys_api=>parse_date( iv_in = mv_date_from iv_default = lv_week_ago ).
  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_dumps.

    DATA(lv_from) = date_from_input( ).
    mv_date_from  = |{ lv_from }|.

    mt_dumps = zcl_zlk05_sys_api=>get_dumps( iv_date_from = lv_from
                                             iv_user      = mv_user ).
    mv_mode  = `LIST`.

    IF lines( mt_dumps ) = 0.
      mv_message = |No runtime errors as of { zcl_zlk05_sys_api=>format_date( lv_from ) }.|.
      mv_msgtype = `Success`.
      mv_mode    = `SEL`.
    ELSE.
      mv_message = |{ lines( mt_dumps ) } runtime error(s) selected.|.
      mv_msgtype = `Warning`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_detail.

    " Key format: YYYYMMDD|HHMMSS|MODNO
    SPLIT iv_key AT `|` INTO TABLE DATA(lt_key).
    IF lines( lt_key ) < 3.
      mv_message = `Dump key is incomplete.`.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    DATA lv_date TYPE d.
    DATA lv_time TYPE t.
    lv_date = lt_key[ 1 ].
    lv_time = lt_key[ 2 ].

    mv_current = |{ zcl_zlk05_sys_api=>format_date( lv_date ) } | &&
                 |{ zcl_zlk05_sys_api=>format_time( lv_time ) }|.

    mt_detail = zcl_zlk05_sys_api=>get_dump_detail( iv_datum = lv_date
                                                    iv_uzeit = lv_time
                                                    iv_modno = lt_key[ 3 ] ).

    IF lines( mt_detail ) = 0.
      mv_message = `The dump details could not be read.`.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    mv_mode = `DETAIL`.

  ENDMETHOD.


* ---------------------------------------------------------------------
*  Screen 1 - selection screen
* ---------------------------------------------------------------------
  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Runtime Errors` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |ABAP Runtime Errors - Client { sy-mandt }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display List` icon = `sap-icon://list`
              tooltip = `Select the runtime errors (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( text = `Reorganize` icon = `sap-icon://delete`
              tooltip = |Reorganize - { c_na }| )
            ( text = `Statistics` icon = `sap-icon://bar-chart`
              tooltip = |Statistics - { c_na }| )
            ( text = `Overview` icon = `sap-icon://table-view`
              tooltip = |Overview - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_gold
              tooltip = |Get Variant... - { c_na }| )
            ( icon = `sap-icon://save` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Save as variant - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `false`
        )->a( n = `class`      v = `sapUiSmallMarginBegin` ).

    DATA(panel) = work->ele( `Panel`
        )->a( n = `headerText` v = `Selection`
        )->a( n = `width`      v = `52rem`
        )->a( n = `class`      v = `sapUiSmallMarginTop`
        )->ele( `content`
            )->ele( `VBox`
                )->a( n = `class` v = `sapUiSmallMargin` ).

    " Runtime error - the API selects on the date, not on the error name
    DATA(row) = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Runtime error`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `value`   v = client->_bind( mv_errorid )
        )->a( n = `width`   v = `20rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Selection by runtime error - { c_na }| ).

    row = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Date`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `id`      v = `idDateFrom`
        )->a( n = `value`   v = client->_bind( mv_date_from )
        )->a( n = `width`   v = `9rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` )
        )->a( n = `tooltip` v = `Runtime errors as of this date (YYYYMMDD)` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `to`
                                    iv_width  = `2.5rem` ).
    row->tag( `Input`
        )->a( n = `value`   v = client->_bind( mv_date_to )
        )->a( n = `width`   v = `9rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Upper date limit - { c_na }| ).

    row = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Time`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `width`   v = `9rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Selection by time - { c_na }| ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `to`
                                    iv_width  = `2.5rem` ).
    row->tag( `Input`
        )->a( n = `width`   v = `9rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Selection by time - { c_na }| ).

    row = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `User`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idUser`
        )->a( n = `value`       v = client->_bind( mv_user )
        )->a( n = `width`       v = `12rem`
        )->a( n = `placeholder` v = `* for all users`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    row = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Client`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `value`   t = CONV string( sy-mandt )
        )->a( n = `width`   v = `5rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |The app always reads the own client { sy-mandt }| ).

    row = panel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = `Host`
                                    iv_width  = `11rem` ).
    row->tag( `Input`
        )->a( n = `value`   t = CONV string( sy-host )
        )->a( n = `width`   v = `14rem`
        )->a( n = `enabled` v = `false`
        )->a( n = `tooltip` t = |Selection by host - { c_na }| ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idDateFrom` ) ) ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


* ---------------------------------------------------------------------
*  Screen 2 - ALV list of the selected runtime errors
* ---------------------------------------------------------------------
  METHOD view_list.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Runtime Errors` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_SEL` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `List of Selected Runtime Errors` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Selection` icon = `sap-icon://filter`
              tooltip = `Back to the selection screen`
              press = client->_event( `BACK_TO_SEL` ) )
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Select again`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( text = `Display Long Text` icon = `sap-icon://detail-view`
              tooltip = `Choose a line to display its long text` )
            ( sep = abap_true )
            ( icon = `sap-icon://locked` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Keep/Release - { c_na }| )
            ( icon = `sap-icon://download` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Save to Local File - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print Dump Analysis - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://sort-ascending` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Sort in Ascending Order - { c_na }| )
            ( icon = `sap-icon://sort-descending` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Sort in Descending Order - { c_na }| )
            ( icon = `sap-icon://filter-fields` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Set Filter - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Layout... - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_dumps )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10`
        )->a( n = `cellClick`           v = client->_event(
                  val = `DISPLAY`
                  arg = `${KEY_DATE}|${KEY_TIME}|${KEY_MOD}` ) ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Date|DATUM|6rem` )
        ( `Time|UZEIT|6rem` )
        ( `User|UNAME|9rem` )
        ( `Client|MANDT|4.5rem` )
        ( `Runtime Error|ERRORID|18rem` )
        ( `Program|PROGRAM|20rem` )
        ( `Line|LINE|5rem` ) ).

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

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_SEL`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


* ---------------------------------------------------------------------
*  Screen 3 - long text of one runtime error
* ---------------------------------------------------------------------
  METHOD view_detail.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Runtime Errors` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Runtime Error Long Text`
        iv_hint   = mv_current ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display List` icon = `sap-icon://list`
              tooltip = `Back to the list of runtime errors`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( text = `Go to Affected Program` icon = `sap-icon://source-code`
              tooltip = `Display the terminated program in the ABAP Editor`
              press = client->_event( `GOTO_PROGRAM` ) )
            ( text = `Debugger` icon = `sap-icon://inspect`
              tooltip = |Debugger - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://newspaper` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |SAP Correction Notes - { c_na }| )
            ( icon = `sap-icon://lightbulb` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Recommended Solution - { c_na }| )
            ( icon = `sap-icon://text-align-left` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Unformatted Display - { c_na }| )
            ( icon = `sap-icon://locked` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Keep/Release - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://close-command-field` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |First Page - { c_na }| )
            ( icon = `sap-icon://open-command-field` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Last Page - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `false` ).

    DATA(tab) = work->ele( `Table`
        )->a( n = `items`   v = client->_bind( mt_detail )
        )->a( n = `growing` v = `true`
        )->a( n = `class`   v = `sapUiSizeCompact` ).

    tab->ele( `columns`
        )->ele( `Column`
            )->a( n = `width` v = `18rem`
            )->tag( `Text`
                )->a( n = `text` v = `Attribute`
        )->end(
        )->ele( `Column`
            )->tag( `Text`
                )->a( n = `text` v = `Value`
        )->end(
    )->end(
        )->ele( `items`
            )->ele( `ColumnListItem`
                )->ele( `cells`
                    )->tag( `Text`
                        )->a( n = `text` v = `{LABEL}`
                    )->tag( `Text`
                        )->a( n = `text` v = `{VALUE}` ).

    " the app reads the SNAP header, not the complete dump - say so instead
    " of letting the screen look like the full ST22 long text
    work->tag( `Text`
        )->a( n = `text`  v = `Decoded from the SNAP dump header`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
