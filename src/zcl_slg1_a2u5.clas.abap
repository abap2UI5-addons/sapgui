CLASS zcl_slg1_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SLG1 - Analyze Application Log
*
*  Screen 1: selection (object, subobject, user, date) and the list of
*            logs found in BALHDR, with the traffic light of SLG1.
*  Screen 2: the messages of one log, read with BAL_DB_LOAD and
*            BAL_LOG_MSG_READ like the original.
*
*  Deleting or archiving logs is not possible here.
*
*  Authorization: S_TCODE SLG1 + S_APPL_LOG 03, and S_APPL_LOG 03 for
*  the object / subobject of every single log (ZCL_ZLK05_AUTH).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command   TYPE string.
    DATA mv_object    TYPE string.
    DATA mv_subobject TYPE string.
    DATA mv_user      TYPE string.
    DATA mv_date_from TYPE string.
    DATA mv_date_to   TYPE string.

    DATA mt_logs     TYPE zcl_zlk05_sys_api=>ty_t_applog.
    DATA mt_messages TYPE zcl_zlk05_sys_api=>ty_t_applog_msg.

  PROTECTED SECTION.
    DATA mv_cur_log  TYPE string.
    DATA mv_cur_text TYPE string.

    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.
    DATA mv_mode    TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS render.
    METHODS view_display.
    METHODS view_detail.
    METHODS on_event.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_lognumber TYPE string.
    METHODS add_grid
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_rows   TYPE string
                it_cols   TYPE string_table
                iv_click  TYPE string OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_slg1_a2u5 IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      " SLG1 starts with the logs of today
      mv_date_from = sy-datum.
      mv_date_to   = sy-datum.
      mv_mode      = `LIST`.
      do_search( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get_event( ).
    DATA(lt_arg)   = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msgtype.

    " F3 on the message screen goes back to the list, not out of SLG1
    IF lv_event = zcl_zlk05_gui_frame=>c_ev_back AND mv_mode = `DETAIL`.
      mv_mode = `LIST`.
      render( ).
      RETURN.
    ENDIF.

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
        mv_mode = `LIST`.
        do_search( ).
      WHEN 'DISPLAY'.
        IF lines( lt_arg ) >= 1.
          do_open( lt_arg[ 1 ] ).
        ENDIF.
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
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD do_search.

    DATA lv_from TYPE d.
    DATA lv_to   TYPE d.

    " the date fields are bound to the browser - only take plain dates
    IF matches( val = mv_date_from pcre = `\d{8}` ).
      lv_from = mv_date_from.
    ENDIF.
    IF matches( val = mv_date_to pcre = `\d{8}` ).
      lv_to = mv_date_to.
    ENDIF.

    mt_logs = zcl_zlk05_sys_api=>get_app_logs( iv_object    = mv_object
                                               iv_subobject = mv_subobject
                                               iv_user      = mv_user
                                               iv_date_from = lv_from
                                               iv_date_to   = lv_to ).
    IF mt_logs IS INITIAL.
      mv_message = `No logs found for the selection criteria.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_logs ) } log(s) found.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    zcl_zlk05_sys_api=>get_app_log_messages(
      EXPORTING iv_lognumber = iv_lognumber
      IMPORTING et_messages  = mt_messages
                ev_message   = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Error`.
      mv_mode    = `LIST`.
      RETURN.
    ENDIF.

    mv_cur_log = iv_lognumber.
    READ TABLE mt_logs WITH KEY lognumber = iv_lognumber INTO DATA(ls_log).
    mv_cur_text = COND #( WHEN sy-subrc = 0
                          THEN |{ ls_log-object } / { ls_log-subobject } - { ls_log-aldate } { ls_log-altime } - { ls_log-aluser }|
                          ELSE iv_lognumber ).
    mv_mode    = `DETAIL`.
    mv_message = |{ lines( mt_messages ) } message(s) in log { iv_lognumber }.|.
    mv_msgtype = `Information`.

  ENDMETHOD.


  METHOD add_grid.

    DATA(grid) = io_parent->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = iv_rows
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `8` ).
    IF iv_click IS NOT INITIAL.
      grid->a( n = `cellClick` v = iv_click ).
    ENDIF.

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    LOOP AT it_cols INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table` ).
      " the traffic light column carries the state of the row
      IF lv_fld = `STATE`.
        " a coloured dot - the traffic light of SLG1
        col->tag( `ObjectStatus`
            )->a( n = `icon`  v = `sap-icon://circle-task-2`
            )->a( n = `state` v = `{STATE}` ).
      ELSEIF lv_fld = `SEVTEXT`.
        col->tag( `ObjectStatus`
            )->a( n = `text`  v = `{SEVTEXT}`
            )->a( n = `state` v = `{STATE}` ).
      ELSE.
        col->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Program` ) ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Analyze Application Log` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Execute` icon = `sap-icon://begin`
              tooltip = `Select the logs (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete Logs - { c_na }| )
            ( icon = `sap-icon://attachment-zip-file` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Archive Logs - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    work->tag( `Title`
        )->a( n = `text`  v = `Log Selection`
        )->a( n = `level` v = `H4` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Object` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idLogObject`
        )->a( n = `value`       v = client->_bind( mv_object )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `12rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Subobject` ).
    row->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_subobject )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `12rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `User` ).
    row->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_user )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `10rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row->end( ).

    DATA(row2) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `From Date` ).
    row2->tag( `DatePicker`
        )->a( n = `value`        v = client->_bind( mv_date_from )
        )->a( n = `valueFormat`  v = `yyyyMMdd`
        )->a( n = `displayFormat` v = `dd.MM.yyyy`
        )->a( n = `width`        v = `10rem` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `To Date` ).
    row2->tag( `DatePicker`
        )->a( n = `value`        v = client->_bind( mv_date_to )
        )->a( n = `valueFormat`  v = `yyyyMMdd`
        )->a( n = `displayFormat` v = `dd.MM.yyyy`
        )->a( n = `width`        v = `10rem` ).
    row2->end( ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idLogObject` ) ) ).

    add_grid(
        io_parent = work
        iv_rows   = client->_bind( mt_logs )
        iv_click  = client->_event( val = `DISPLAY` arg = `${LOGNUMBER}` )
        it_cols   = VALUE #(
            ( `|STATE|3rem` )
            ( `Object|OBJECT|10rem` )
            ( `Subobject|SUBOBJECT|12rem` )
            ( `External ID|EXTNUMBER|14rem` )
            ( `Date|ALDATE|7rem` )
            ( `Time|ALTIME|6rem` )
            ( `User|ALUSER|9rem` )
            ( `Transaction|ALTCODE|7rem` )
            ( `Program|ALPROG|14rem` )
            ( `Messages|MSG_ALL|6rem` )
            ( `Errors|MSG_ERR|5rem` )
            ( `Warnings|MSG_WARN|6rem` )
            ( `Log Number|LOGNUMBER|11rem` ) ) ).

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - choose a log to see its messages. No log is deleted or archived here`
        )->a( n = `class` v = `sapUiTinyMarginTop` ).

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

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Log` ) ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Display Logs - { mv_cur_log }|
        iv_hint   = mv_cur_text ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back to List` icon = `sap-icon://nav-back`
              tooltip = `Back to the log list (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://message-information` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Long Text - { c_na }| )
            ( icon = `sap-icon://technical-object` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Technical Information - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    add_grid(
        io_parent = work
        iv_rows   = client->_bind( mt_messages )
        it_cols   = VALUE #(
            ( `Type|SEVTEXT|9rem` )
            ( `Message Text|TEXT|50rem` )
            ( `Time Stamp|TSTAMP|14rem` )
            ( `No.|MSGNO|4rem` ) ) ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
