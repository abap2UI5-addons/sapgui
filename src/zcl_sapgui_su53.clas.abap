CLASS zcl_sapgui_su53 DEFINITION PUBLIC
  INHERITING FROM zcl_sapgui_screen.

* ---------------------------------------------------------------------
*  SU53 - Evaluation of Authorization Check
*
*  Lists the failed authorization checks of a user during the last three
*  hours, read like the original (SAPMS01GNEW) with SUSR_USER_SU53_READ
*  from the SU53 buffer of all application server instances.
*
*  Authorization: S_TCODE SU53. The own checks need nothing more, the
*  checks of another user need S_USER_GRP 03 for his user group.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_sapgui_start_params.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_user    TYPE string.
    DATA mt_fails   TYPE zcl_sapgui_sys_api=>ty_t_authfail.

  PROTECTED SECTION.
    "! the user whose checks the list shows
    DATA mv_shown   TYPE string.

    METHODS view_display.
    METHODS on_event REDEFINITION.
    METHODS on_init REDEFINITION.
    METHODS render REDEFINITION.
    METHODS do_read.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sapgui_su53 IMPLEMENTATION.


  METHOD zif_sapgui_start_params~set_start_params.
    mv_user = to_upper( condense( VALUE #(
        it_params[ name = zif_sapgui_start_params=>c_user ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD on_init.

    IF mv_user IS INITIAL.
      mv_user = sy-uname.
    ENDIF.
    do_read( ).
    view_display( ).

  ENDMETHOD.


  METHOD render.
    view_display( ).
  ENDMETHOD.


  METHOD on_event.

    CASE client->get_event( ).
      WHEN 'REFRESH'.
        do_read( ).
      WHEN 'DISPLAY_USER'.
        " the user master of the user whose checks are shown
        IF mv_shown IS NOT INITIAL.
          DATA(ls_run) = zcl_sapgui_router=>run(
              iv_command = `SU01`
              io_client  = client
              it_params  = VALUE #( ( name  = zif_sapgui_start_params=>c_user
                                      value = mv_shown ) ) ).
          IF ls_run-outcome = zcl_sapgui_router=>c_nav.
            RETURN.
          ENDIF.
          mv_message = ls_run-message.
          mv_msgtype = ls_run-msg_type.
        ENDIF.
      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD do_read.

    mv_user = to_upper( condense( mv_user ) ).
    IF mv_user IS INITIAL.
      mv_user = sy-uname.
    ENDIF.

    zcl_sapgui_sys_api=>get_auth_failures(
      EXPORTING iv_bname   = mv_user
      IMPORTING et_fails   = mt_fails
                ev_message = DATA(lv_msg) ).
    mv_shown = mv_user.

    IF mt_fails IS NOT INITIAL.
      mv_message = |{ lines( mt_fails ) } failed authorization check(s) for { mv_user }.|.
      mv_msgtype = `Warning`.
    ELSEIF lv_msg CP `No failed*`.
      mv_message = lv_msg.
      mv_msgtype = `Success`.
    ELSE.
      " refused (S_USER_GRP) or unknown user - the list stays empty
      mv_message = lv_msg.
      mv_msgtype = `Error`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_sapgui_frame=>open_window( view ).

    zcl_sapgui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_sapgui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Authorization Values` ) ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_sapgui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_sapgui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_sapgui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Evaluation of Authorization Check` ).

    zcl_sapgui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Refresh` icon = `sap-icon://refresh`
              tooltip = `Read the failed checks again`
              press = client->_event( `REFRESH` ) )
            ( sep = abap_true )
            ( text = `User` icon = `sap-icon://person-placeholder`
              tooltip = `Display the user in User Maintenance (SU01)`
              press = client->_event( `DISPLAY_USER` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://download` color = zcl_sapgui_frame=>c_grey
              tooltip = |Download - { c_na }| )
            ( icon = `sap-icon://history` color = zcl_sapgui_frame=>c_grey
              tooltip = |Read From Database - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_sapgui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " the user field of the original screen: own user or another one
    DATA(hdr) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_sapgui_frame=>add_label( io_parent = hdr
                                   iv_text   = `User` ).

    hdr->tag( `Input`
        )->a( n = `id`     v = `idSu53User`
        )->a( n = `value`  v = client->_bind( mv_user )
        )->a( n = `width`  v = `12rem`
        )->a( n = `submit` v = client->_event( `REFRESH` ) ).

    hdr->tag( `Text`
        )->a( n = `text`  v = `Failed authorization checks of the last 3 hours, all instances`
        )->a( n = `class` v = `sapUiSmallMarginBegin` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_fails )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the columns of the SU53 list: when, which object with which values,
    " why it failed and where the check was made
    DATA(lt_col) = VALUE string_table(
        ( `Date|DATE|6rem` )
        ( `Time|TIME|5rem` )
        ( `Auth. Object|OBJCT|8rem` )
        ( `Object Text|OBJTEXT|14rem` )
        ( `Checked Values|FIELDS|28rem` )
        ( `RC|RC|3rem` )
        ( `Reason|REASON|16rem` )
        ( `Transaction|TCODE|7rem` )
        ( `Program|PROGRAM|14rem` )
        ( `Line|LINE|4rem` )
        ( `Instance|INSTANCE|12rem` ) ).

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

    zcl_sapgui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_sapgui_frame=>c_ev_back ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
