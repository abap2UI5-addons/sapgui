CLASS zcl_st05_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  ST05 - Performance Trace
*
*  Screen titles, menu bar, function texts and all field labels are the
*  original ones of program R_ST05_TRACE_MAIN (RSMPTEXTS / D021T):
*
*    T 0010  ST05 Performance Trace
*      0020  Conditions for Trace Recording
*    M       Performance Trace  Edit  Goto
*    F TRACE_ON   Activate Trace          TRACE_OFF  Deactivate Trace
*      TRACE_ON_F Activate Trace w.Filter TR_OFF_ALL Deactivate Trace on
*                                                    All Instances
*      LIST       Display Trace           LIST_IMM   Display Trace With-
*                                                    out First Deactiv.
*      MORE       Display Detailed Trace List
*      FILTER     Display Filter for Trace Recording
*      SAVE_TRACE Save Trace              READ_TRACE Display Saved Trace
*      DEL_TRACE  Delete Saved Trace      DIR        Display Trace Dir.
*      EXPLAIN_ED Execution Plan          SMEC       Check Measurement
*                                                    Environment
*      ERRORADMIN Trace Kernel Errors     SPRO       Display Profile
*                                                    Parameters f.Trace
*      REFR       Refresh Display         STON/STOF  Act./Deact. Stack
*    Screen 0010 field texts (D021T)
*      TEXT1  Select Trace Type      TEXT2  Configure Trace
*      SQL_TRACE / BUF_TRACE / ENQ_TRACE / RFC_TRACE / HTTP_TRACE /
*      AMC_TRACE / APC_TRACE, STACK + On/Off, PROGRESS + On/Off,
*      SQLTFIELDS-STATE  Trace State of Current Application Server
*                        Instance
*
*  The app reads the real trace state of the own instance with
*  ST05_GET_TRACE_STATE. It never switches a trace on or off, therefore
*  the trace type boxes are a status display and the activation
*  functions stay disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    CONSTANTS c_ro TYPE string VALUE
      `status display - this app never switches a trace on or off`.

    DATA mv_screen     TYPE string.
    DATA mv_command     TYPE string.
    DATA mv_message     TYPE string.
    DATA mv_msgtype    TYPE string.
    DATA mv_show_param TYPE abap_bool.
    DATA ms_state      TYPE zcl_zlk05_sys_api=>ty_s_trace_state.
    DATA mt_param      TYPE zcl_zlk05_sys_api=>ty_t_kv.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_initial.
    METHODS view_filter.
    METHODS on_event.
    METHODS do_refresh.

    METHODS add_check
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_text   TYPE string
                iv_on     TYPE abap_bool
                iv_tip    TYPE string OPTIONAL.

    METHODS add_field
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_label  TYPE string
                iv_value  TYPE string OPTIONAL
                iv_width  TYPE string DEFAULT `18rem`
                iv_tip    TYPE string OPTIONAL.

    METHODS add_block_title
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_text   TYPE string
                iv_first  TYPE abap_bool OPTIONAL.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_st05_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_screen = `0010`.
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
        iv_event   = client->get( )-event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE client->get( )-event.

      WHEN 'REFRESH'.
        do_refresh( ).

      WHEN 'SPRO'.
        " F SPRO - Display Profile Parameters for Trace
        mv_show_param = abap_true.
        mt_param = zcl_zlk05_sys_api=>get_trace_status( ).
        mv_message = |{ lines( mt_param ) } trace relevant profile parameter(s).|.
        mv_msgtype = `Information`.

      WHEN 'FILTER'.
        " F FILTER - Display Filter for Trace Recording -> screen 0020
        mv_screen = `0020`.
        IF ms_state-filter_on = abap_true.
          mv_message = `Filter for trace recording is set.`.
          mv_msgtype = `Information`.
        ELSE.
          mv_message = `No filter is set for trace recording.`.
          mv_msgtype = `Information`.
        ENDIF.

      WHEN 'BACK_0010'.
        mv_screen = `0010`.
        do_refresh( ).

      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_refresh.

    CLEAR ms_state.

    zcl_zlk05_sys_api=>get_trace_state(
      IMPORTING es_state   = ms_state
                ev_message = DATA(lv_msg) ).

    " when the kernel refuses the state, fall back to what can be read -
    " the trace relevant profile parameters
    IF ms_state-state_known = abap_false.
      mv_show_param = abap_true.
    ENDIF.

    IF mv_show_param = abap_true.
      mt_param = zcl_zlk05_sys_api=>get_trace_status( ).
    ENDIF.

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = ms_state-state_text.
      mv_msgtype = COND #( WHEN ms_state-any_on = abap_true THEN `Warning`
                           ELSE `Information` ).
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    CASE mv_screen.
      WHEN `0020`.
        view_filter( ).
      WHEN OTHERS.
        view_initial( ).
    ENDCASE.

  ENDMETHOD.


* =====================================================================
*  Screen 0010 - ST05 Performance Trace
* =====================================================================
  METHOD view_initial.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " M 000001/2/3 - Performance Trace, Edit, Goto
    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Performance Trace` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " T 0010
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `ST05 Performance Trace` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh Display` icon = `sap-icon://refresh`
              tooltip = `Read the trace state of this instance again`
              press = client->_event( `REFRESH` ) )
            ( text = `Display Filter for Trace Recording`
              icon = `sap-icon://filter`
              tooltip = `Conditions for Trace Recording`
              press = client->_event( `FILTER` ) )
            ( text = `Profile Parameters` icon = `sap-icon://action-settings`
              tooltip = `Display Profile Parameters for Trace`
              press = client->_event( `SPRO` ) )
            ( sep = abap_true )
            ( text = `Activate Trace` icon = `sap-icon://media-play`
              tooltip = |Activate Trace - { c_ro }| )
            ( text = `Deactivate Trace` icon = `sap-icon://media-pause`
              tooltip = |Deactivate Trace - { c_ro }| )
            ( text = `Display Trace` icon = `sap-icon://list`
              tooltip = |Display Trace - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://filter-analytics` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate Trace with Filter - { c_ro }| )
            ( icon = `sap-icon://stop` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Deactivate Trace on All Instances - { c_ro }| )
            ( icon = `sap-icon://open-command-field` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Trace Without First Deactivating - { c_na }| )
            ( icon = `sap-icon://detail-more` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Detailed Trace List - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://save` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Save Trace - { c_na }| )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Saved Trace - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Delete Saved Trace - { c_na }| )
            ( icon = `sap-icon://tree` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Trace Directory - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://performance` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Execution Plan - { c_na }| )
            ( icon = `sap-icon://validate` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check Measurement Environment - { c_na }| )
            ( icon = `sap-icon://alert` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Trace Kernel Errors - { c_na }| )
            ( icon = `sap-icon://overview-chart` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate Stack Trace - { c_ro }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " The trace type boxes mirror the kernel state. When the kernel did not
    " tell it, empty boxes would read as "no trace is running" - say so.
    IF ms_state-state_known = abap_false.
      work->tag( `MessageStrip`
          )->a( n = `text`     v = `The trace state of this instance could not be read. ` &&
                                   `The trace type boxes below do NOT show the state of the instance.`
          )->a( n = `type`     v = `Warning`
          )->a( n = `showIcon` v = `true`
          )->a( n = `class`    v = `sapUiTinyMarginBottom` ).
    ENDIF.

    " ----- TEXT1 - Select Trace Type -----
    add_block_title( io_parent = work
                     iv_text   = `Select Trace Type`
                     iv_first  = abap_true ).

    DATA(trow1) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    DATA(lv_tip) = COND #(
        WHEN ms_state-state_known = abap_false
        THEN `trace state unknown - this box does not show the state of the instance` ).

    add_check( io_parent = trow1 iv_text = `SQL Trace`
               iv_on = ms_state-sql_on iv_tip = lv_tip ).
    add_check( io_parent = trow1 iv_text = `Buffer Trace`
               iv_on = ms_state-buf_on iv_tip = lv_tip ).
    add_check( io_parent = trow1 iv_text = `Enqueue Trace`
               iv_on = ms_state-enq_on iv_tip = lv_tip ).
    add_check( io_parent = trow1 iv_text = `RFC Trace`
               iv_on = ms_state-rfc_on iv_tip = lv_tip ).
    trow1->end( ).

    DATA(trow2) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    add_check( io_parent = trow2 iv_text = `HTTP Trace`
               iv_on = ms_state-http_on iv_tip = lv_tip ).
    add_check( io_parent = trow2 iv_text = `AMC Trace`
               iv_on = ms_state-amc_on iv_tip = lv_tip ).
    add_check( io_parent = trow2 iv_text = `APC trace`
               iv_on = ms_state-apc_on iv_tip = lv_tip ).
    trow2->end( ).

    " ----- TEXT2 - Configure Trace -----
    add_block_title( io_parent = work iv_text = `Configure Trace` ).

    DATA(srow) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = srow
                                    iv_text   = `Stack Trace`
                                    iv_width  = `16rem` ).
    srow->tag( `RadioButton`
        )->a( n = `text`     v = `On`
        )->a( n = `selected` b = ms_state-stack_on
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = |Activate Stack Trace - { c_ro }|
        )->tag( `RadioButton`
        )->a( n = `text`     v = `Off`
        )->a( n = `selected` b = xsdbool( ms_state-stack_on = abap_false )
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = |Deactivate Stack Trace - { c_ro }| ).
    srow->end( ).

    DATA(prow) = work->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = prow
                                    iv_text   = `Progress Display`
                                    iv_width  = `16rem` ).
    prow->tag( `RadioButton`
        )->a( n = `text`     v = `On`
        )->a( n = `selected` b = ms_state-progress_on
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = |Switch Progress Display On - { c_ro }|
        )->tag( `RadioButton`
        )->a( n = `text`     v = `Off`
        )->a( n = `selected` b = xsdbool( ms_state-progress_on = abap_false )
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = |Switch Progress Display Off - { c_ro }| ).
    prow->end( ).

    " ----- SQLTFIELDS-STATE -----
    add_block_title( io_parent = work
                     iv_text   = `Trace State of Current Application Server Instance` ).

    add_field( io_parent = work
               iv_label  = `Trace State`
               iv_value  = ms_state-state_text
               iv_width  = `46rem`
               iv_tip    = `Trace State of Current Application Server Instance` ).

    add_field( io_parent = work
               iv_label  = `Instance`
               iv_value  = |{ sy-host }|
               iv_width  = `20rem` ).

    add_field( io_parent = work
               iv_label  = `Filter Active`
               iv_value  = COND #( WHEN ms_state-state_known = abap_false THEN `unknown`
                                   WHEN ms_state-filter_on = abap_true THEN `Yes`
                                   ELSE `No` )
               iv_width  = `20rem`
               iv_tip    = `Display Filter for Trace Recording` ).

    IF ms_state-mod_user IS NOT INITIAL.
      add_field( io_parent = work
                 iv_label  = `Last Change`
                 iv_value  = |{ ms_state-mod_user } { ms_state-mod_date } { ms_state-mod_time }|
                 iv_width  = `30rem` ).
    ENDIF.

    " ----- F SPRO - Display Profile Parameters for Trace -----
    IF mv_show_param = abap_true.

      add_block_title( io_parent = work iv_text = `Profile Parameters for Trace` ).

      DATA(grid) = work->ele( n = `Table` ns = `table`
          )->a( n = `rows`                v = client->_bind( mt_param )
          )->a( n = `visibleRowCountMode` v = `Auto`
          )->a( n = `selectionMode`       v = `None`
          )->a( n = `rowHeight`           v = `26`
          )->a( n = `minAutoRowCount`     v = `5`
          )->a( n = `class`               v = `sapUiTinyMarginTop` ).

      DATA(cols) = grid->ele( n = `columns` ns = `table` ).

      DATA(lt_col) = VALUE string_table(
          ( `Parameter|LABEL|32rem` )
          ( `Value|VALUE|24rem` ) ).

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

      grid->end( ).

    ENDIF.

    work->tag( `Text`
        )->a( n = `text`  v = `Trace state read via ST05_GET_TRACE_STATE - display only`
        )->a( n = `class` v = `sapUiMediumMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


* =====================================================================
*  Screen 0020 - Conditions for Trace Recording
* =====================================================================
  METHOD view_filter.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Performance Trace` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_0010` ) ).

    " T 0020
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Conditions for Trace Recording` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the ST05 initial screen`
              press = client->_event( `BACK_0010` ) )
            ( sep = abap_true )
            ( text = `Update Filter Conditions` icon = `sap-icon://synchronize`
              tooltip = |Update All Filter Conditions - { c_ro }| )
            ( text = `Initialize Filter Conditions` icon = `sap-icon://eraser`
              tooltip = |Initialize All Filter Conditions - { c_ro }| )
            ( text = `Delete Filter Condition` icon = `sap-icon://delete`
              tooltip = |Delete Selected Filter Condition - { c_ro }| )
            ( sep = abap_true )
            ( icon = `sap-icon://filter-analytics` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate Trace with Filter - { c_ro }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " ----- filter conditions, only one of them can be set -----
    add_block_title( io_parent = work
                     iv_text   = `Filters for Trace Recording`
                     iv_first  = abap_true ).

    IF ms_state-state_known = abap_false.
      work->tag( `MessageStrip`
          )->a( n = `text`     v = `The trace state of this instance could not be read. ` &&
                                   `The filter conditions below are therefore unknown, not empty.`
          )->a( n = `type`     v = `Warning`
          )->a( n = `showIcon` v = `true`
          )->a( n = `class`    v = `sapUiTinyMarginBottom` ).
    ENDIF.

    work->tag( `Text`
        )->a( n = `text`  v = `(Only one of these filters can be set)`
        )->a( n = `class` v = `sapUiTinyMarginBottom` ).

    add_field( io_parent = work iv_label = `User Name`
               iv_value = ms_state-trace_user ).
    add_field( io_parent = work iv_label = `Transaction Name`
               iv_value = ms_state-tcode ).
    add_field( io_parent = work iv_label = `Program Name`
               iv_value = ms_state-program iv_width = `26rem` ).
    add_field( io_parent = work iv_label = `RFC Function Name`
               iv_value = ms_state-rfc_function iv_width = `26rem` ).
    add_field( io_parent = work iv_label = `URL`
               iv_value = ms_state-url iv_width = `40rem` ).
    add_field( io_parent = work iv_label = `Process Number`
               iv_value = ms_state-wp_id iv_width = `8rem` ).

    " ----- TAB_NAME - Table Names (Only for SQL Trace) -----
    add_block_title( io_parent = work
                     iv_text   = `Table Names (Only for SQL Trace)` ).

    add_field( io_parent = work iv_label = `Include`
               iv_value = ms_state-incl_tables iv_width = `40rem` ).
    add_field( io_parent = work iv_label = `Exclude`
               iv_value = ms_state-excl_tables iv_width = `40rem` ).

    DATA(mrow) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    add_check( io_parent = mrow
               iv_text   = `Include Statements with Empty Table Names`
               iv_on     = ms_state-incl_missing ).
    mrow->end( ).

    " ----- SCHEDULING -----
    add_block_title( io_parent = work iv_text = `Scheduling` ).

    DATA(schedrow) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    add_check( io_parent = schedrow
               iv_text   = `Schedule Trace Recording`
               iv_on     = abap_false
               iv_tip    = |Schedule Trace Recording - { c_na }| ).
    add_check( io_parent = schedrow
               iv_text   = `Save Trace in DB`
               iv_on     = abap_false
               iv_tip    = |Save Trace in DB - { c_na }| ).
    schedrow->end( ).

    add_field( io_parent = work iv_label = `Start Date`
               iv_width = `12rem` iv_tip = |Start Date - { c_na }| ).
    add_field( io_parent = work iv_label = `Time`
               iv_width = `12rem` iv_tip = |Start Time - { c_na }| ).
    add_field( io_parent = work iv_label = `End Date`
               iv_width = `12rem` iv_tip = |End Date - { c_na }| ).
    add_field( io_parent = work iv_label = `EndTime`
               iv_width = `12rem` iv_tip = |End Time - { c_na }| ).
    add_field( io_parent = work iv_label = `Description`
               iv_width = `40rem` iv_tip = |Description - { c_na }| ).

    work->tag( `Text`
        )->a( n = `text`  v = `Filter values read via ST05_GET_TRACE_STATE - display only. ` &&
                             `Scheduling data are kept by the trace scheduler and are not read here.`
        )->a( n = `class` v = `sapUiMediumMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_0010` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


* =====================================================================
*  Small building blocks of a classic dynpro
* =====================================================================
  METHOD add_check.

    io_parent->tag( `CheckBox`
        )->a( n = `text`     v = iv_text
        )->a( n = `selected` b = iv_on
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = COND #( WHEN iv_tip IS INITIAL
                                         THEN |{ iv_text } - { c_ro }|
                                         ELSE iv_tip ) ).

  ENDMETHOD.


  METHOD add_field.

    DATA(row) = io_parent->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = row
                                    iv_text   = iv_label
                                    iv_width  = `16rem` ).

    row->tag( `Input`
        )->a( n = `value`   v = iv_value
        )->a( n = `enabled` v = `false`
        )->a( n = `width`   v = iv_width
        )->a( n = `tooltip` v = COND #( WHEN iv_tip IS INITIAL THEN iv_label
                                        ELSE iv_tip ) ).

    row->end( ).

  ENDMETHOD.


  METHOD add_block_title.

    io_parent->tag( `Title`
        )->a( n = `text`  v = iv_text
        )->a( n = `level` v = `H4`
        )->a( n = `class` v = COND #( WHEN iv_first = abap_true THEN `sapUiTinyMarginBottom`
                                      ELSE `sapUiMediumMarginTop sapUiTinyMarginBottom` ) ).

  ENDMETHOD.

ENDCLASS.
