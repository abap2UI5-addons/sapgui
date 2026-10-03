CLASS zcl_sapgui_sm30 DEFINITION PUBLIC
  INHERITING FROM zcl_sapgui_screen.

* ---------------------------------------------------------------------
*  SM30 - Call View Maintenance (display)
*
*  The entry screen of SM30: a table or view name and Display. This
*  environment does not maintain table entries, so Display hands the
*  table to the Data Browser (SE16N) - through the router, i.e. with
*  the S_TCODE check of SE16N and the S_TABU_DIS / S_TABU_NAM check of
*  the table there. Maintenance views (view class C) have no database
*  object of their own and are answered with a message.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_table   TYPE string.

  PROTECTED SECTION.

    METHODS view_display.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_display.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sapgui_sm30 IMPLEMENTATION.


  METHOD on_init.

    view_display( ).

  ENDMETHOD.


  METHOD render.
    view_display( ).
  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN 'DISPLAY'.
        do_display( ).
        IF mv_msgtype IS INITIAL.
          RETURN.     " the Data Browser took over
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_display.

    DATA(lv_table) = to_upper( condense( mv_table ) ).
    IF lv_table IS INITIAL.
      mv_message = `Enter a table or view name.`.
      mv_msgtype = `Warning`.
      RETURN.
    ENDIF.

    CASE zcl_sapgui_sys_api=>get_table_kind( lv_table ).

      WHEN zcl_sapgui_sys_api=>c_table_kind-table
        OR zcl_sapgui_sys_api=>c_table_kind-db_view.
        DATA(ls_run) = zcl_sapgui_router=>run(
            iv_command = `SE16N`
            io_client  = client
            it_params  = VALUE #( ( name  = zif_sapgui_start_params=>c_table
                                    value = lv_table ) ) ).
        IF ls_run-outcome <> zcl_sapgui_router=>c_nav.
          mv_message = ls_run-message.
          mv_msgtype = COND #( WHEN ls_run-msg_type IS INITIAL THEN `Error` ELSE ls_run-msg_type ).
        ENDIF.

      WHEN zcl_sapgui_sys_api=>c_table_kind-maint_view
        OR zcl_sapgui_sys_api=>c_table_kind-other_view.
        mv_message = |{ lv_table } is a maintenance view - it can only be displayed in the SAP GUI.|.
        mv_msgtype = `Warning`.

      WHEN zcl_sapgui_sys_api=>c_table_kind-structure.
        mv_message = |{ lv_table } is a structure and has no entries.|.
        mv_msgtype = `Error`.

      WHEN OTHERS.
        mv_message = |Table/view { lv_table } does not exist.|.
        mv_msgtype = `Error`.

    ENDCASE.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_sapgui_frame=>open_window( view ).

    zcl_sapgui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_sapgui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Table View` ) ( `Edit` ) ( `Goto` ) ( `Utilities(M)` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_sapgui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_sapgui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Maintain Table Views: Initial Screen` ).

    zcl_sapgui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the entries in the Data Browser`
              press = client->_event( `DISPLAY` ) )
            ( text = `Maintain` icon = `sap-icon://edit`
              tooltip = |Maintain - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://customize` color = zcl_sapgui_frame=>c_grey
              tooltip = |Customizing - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`   v = zcl_sapgui_frame=>c_work_height
        )->a( n = `vertical` v = `true`
        )->ele( `VBox`
            )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_sapgui_frame=>add_label( io_parent = row iv_text = `Table/View` ).
    row->tag( `Input`
        )->a( n = `id`     v = `idTableView`
        )->a( n = `value`  v = client->_bind( mv_table )
        )->a( n = `width`  v = `20rem`
        )->a( n = `submit` v = client->_event( `DISPLAY` ) ).
    row->end( ).

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - Display opens the entries in the Data Browser (SE16N). No entry is maintained here`
        )->a( n = `class` v = `sapUiSmallMarginTop` ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idTableView` ) ) ).

    zcl_sapgui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_sapgui_frame=>c_ev_back
        iv_exec_name = `DISPLAY` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
