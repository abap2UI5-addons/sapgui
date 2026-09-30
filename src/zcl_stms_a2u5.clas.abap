CLASS zcl_stms_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  STMS - Transport Management System
*
*  Screen titles, menu bar, group box and function texts are the
*  original ones of function group SAPLTMSU (RSMPTEXTS / D021T):
*
*    T 100    Transport Management System
*    T SYS    System Overview: Domain &
*    T IMP    Import Overview: Domain &
*    M        Overview  Extras  Environment
*    D 0100   Transp. Domain / System
*    F IMPO   Imports          F SYSO  Systems / System Overview
*    F REFR   Refresh          F LEGE  Legend
*
*  The three screens read the local TMS configuration - TMSCSYS for the
*  systems of the domain and TMSBUFFER for the import queues. The
*  original STMS asks the domain controller by RFC, this app does not:
*  it says so on the screen instead of pretending the queues were read
*  from the whole domain.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    " one line of the import overview - system plus number of requests
    TYPES:
      BEGIN OF ty_s_overview,
        sysnam TYPE string,
        systxt TYPE string,
        reqs   TYPE string,
        status TYPE string,
      END OF ty_s_overview.
    TYPES ty_t_overview TYPE STANDARD TABLE OF ty_s_overview WITH EMPTY KEY.

    DATA mt_overview TYPE ty_t_overview.
    DATA mv_mode    TYPE string.
    DATA mv_domain  TYPE string.
    DATA mv_system  TYPE string.
    DATA mv_command  TYPE string.
    DATA mv_message  TYPE string.
    DATA mv_msgtype TYPE string.
    DATA mt_systems TYPE zcl_zlk05_sys_api=>ty_t_tms_system.
    DATA mt_queue   TYPE zcl_zlk05_sys_api=>ty_t_tms_queue.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_start.
    METHODS view_systems.
    METHODS view_imports.
    METHODS on_event.
    METHODS do_read_domain.
    METHODS do_read_systems.
    METHODS do_read_queue.
    METHODS build_overview.
    METHODS render.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_stms_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `START`.
      do_read_domain( ).
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
      WHEN 'SYSO'.
        mv_mode = `SYSTEMS`.
        do_read_systems( ).
      WHEN 'IMPO'.
        mv_mode = `IMPORTS`.
        do_read_systems( ).
        do_read_queue( ).
      WHEN 'REFRESH'.
        do_read_domain( ).
        CASE mv_mode.
          WHEN `SYSTEMS`.
            do_read_systems( ).
          WHEN `IMPORTS`.
            do_read_systems( ).
            do_read_queue( ).
        ENDCASE.
      WHEN 'BACK_TO_START'.
        mv_mode = `START`.
        do_read_domain( ).
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD render.

    CASE mv_mode.
      WHEN `SYSTEMS`.
        view_systems( ).
      WHEN `IMPORTS`.
        view_imports( ).
      WHEN OTHERS.
        view_start( ).
    ENDCASE.

  ENDMETHOD.


  METHOD do_read_domain.

    zcl_zlk05_sys_api=>get_tms_domain(
      IMPORTING ev_domain  = mv_domain
                ev_system  = mv_system
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
    ENDIF.

  ENDMETHOD.


  METHOD do_read_systems.

    mt_systems = zcl_zlk05_sys_api=>get_tms_systems( ).

    IF lines( mt_systems ) = 0.
      mv_message = `No systems are configured in the transport domain.`.
      mv_msgtype = `Warning`.
    ELSEIF mv_message IS INITIAL.
      mv_message = |{ lines( mt_systems ) } system(s) in domain { mv_domain }.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD do_read_queue.

    mt_queue = zcl_zlk05_sys_api=>get_tms_queue( ).

    IF lines( mt_queue ) = 0.
      " an empty import queue is a real state - say it instead of showing
      " an empty list that could mean anything
      mv_message = |No transport requests are waiting in the import queues | &&
                   |of domain { mv_domain }.|.
      mv_msgtype = `Information`.
    ELSE.
      mv_message = |{ lines( mt_queue ) } request(s) in the import queues | &&
                   |of domain { mv_domain }.|.
      mv_msgtype = `Success`.
    ENDIF.

    build_overview( ).

  ENDMETHOD.


  METHOD build_overview.

*   One line per system of the domain with the number of waiting
*   requests - the layout of the original import overview.
    CLEAR mt_overview.

    LOOP AT mt_systems INTO DATA(ls_sys).
      DATA(lv_cnt) = REDUCE i( INIT n = 0
                               FOR ls_q IN mt_queue
                               WHERE ( sysnam = ls_sys-sysnam )
                               NEXT n = n + 1 ).
      APPEND VALUE #( sysnam = ls_sys-sysnam
                      systxt = ls_sys-systxt
                      reqs   = |{ lv_cnt }|
                      status = ls_sys-cfgstat ) TO mt_overview.
    ENDLOOP.

  ENDMETHOD.


  METHOD view_start.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Overview` ) ( `Extras` ) ( `Environment` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Transport Management System` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Imports` icon = `sap-icon://download-from-cloud`
              tooltip = `Import Overview`
              press = client->_event( `IMPO` ) )
            ( text = `Systems` icon = `sap-icon://it-system`
              tooltip = `System Overview`
              press = client->_event( `SYSO` ) )
            ( sep = abap_true )
            ( text = `Transport Routes` icon = `sap-icon://org-chart`
              tooltip = |Transport Routes - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://refresh` color = zcl_zlk05_gui_frame=>c_blue
              tooltip = `Refresh`
              press = client->_event( `REFRESH` ) )
            ( icon = `sap-icon://key` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Legend - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |TMS Configuration - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`   v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical` v = `true` ).

    " the two fields of dynpro 0100
    DATA(box) = work->ele( `Panel`
        )->a( n = `headerText` v = `Transport Management System`
        )->a( n = `class`      v = `sapUiTinyMargin`
        )->ele( `content`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    DATA(row1) = box->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row1
                                    iv_text   = `Transp. Domain`
                                    iv_width  = `12rem` ).
    row1->tag( `Text` )->a( n = `text` v = mv_domain ).
    row1->end( ).

    DATA(row2) = box->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2
                                    iv_text   = `System`
                                    iv_width  = `12rem` ).
    row2->tag( `Text` )->a( n = `text` v = mv_system ).
    row2->end( ).

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no import and no configuration change here`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_systems.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `SAP System` ) ( `Edit` ) ( `Goto` ) ( `Extras` )
                              ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_START` ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = |System Overview: Domain { mv_domain }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Refresh`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Display` icon = `sap-icon://display`
              tooltip = |Display TMS Configuration - { c_na }| )
            ( icon = `sap-icon://key` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Legend - { c_na }| )
            ( icon = `sap-icon://validate` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Consistency Check - { c_na }| )
            ( icon = `sap-icon://share` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Distribute and Activate Configuration - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_systems )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `6` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `System|SYSNAM|7rem` )
        ( `Description|SYSTXT|18rem` )
        ( `Type|SYSTYP|16rem` )
        ( `Communication System|COMSYS|11rem` )
        ( `Status|CFGSTAT|22rem` )
        ( `RFC Destination|DESADM|20rem` )
        ( `Changed On|MODDAT|8rem` )
        ( `Changed By|MODUSR|10rem` ) ).

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
        )->a( n = `text`  v = `Read from the local TMS configuration (TMSCSYS) - ` &&
                              `the domain controller is not called`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_START` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_imports.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Queue` ) ( `Edit` ) ( `Goto` ) ( `Extras` )
                              ( `Environment` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_START` ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = |Import Overview: Domain { mv_domain }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Refresh`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `Import Queue` icon = `sap-icon://list`
              tooltip = |Import Queue: System - { c_na }| )
            ( text = `Start Import` icon = `sap-icon://play`
              tooltip = |Start Import - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Import History - { c_na }| )
            ( icon = `sap-icon://key` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Legend - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_overview )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `6` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `System|SYSNAM|7rem` )
        ( `Description|SYSTXT|18rem` )
        ( `Number of Requests|REQS|9rem` )
        ( `Status|STATUS|24rem` ) ).

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
        )->a( n = `text`  v = `Read from the local import buffer (TMSBUFFER) - ` &&
                              `no RFC call to the systems of the domain`
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_START` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
