CLASS zcl_su01_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SU01 - User Maintenance
*
*  Screen titles, menu bar and function texts are the original ones of
*  program SAPLSUID_MAINTENANCE (RSMPTEXTS):
*
*    T  START  User Maintenance: Initial Screen
*       MAIND  Display Users            MAIN  Maintain Users
*    M  User  Edit  Goto  Information  Environment
*    F  SHOW Display   CHAN Change   CREA Create User   COPY Copy
*       DELE Delete    LOCK Locks    PASS Change Password
*       SU10 Mass Changes  SUIM Information System
*       TOGL Display/Change  DET Details  MAGR Roles / Users / System
*       MPRO System-Dependent Data  APPL References
*       CD_U Change Documents for Users
*
*  Two screens: the initial screen with the User field and the hit list,
*  and the role assignment of one user. Everything that would change a
*  user is present but disabled - this app never writes to USR02.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    "! Content of the command field of the system function bar
    DATA mv_command TYPE string.

    DATA mv_pattern TYPE string.
    DATA mt_users   TYPE zcl_zlk05_sys_api=>ty_t_user.
    DATA mt_roles   TYPE zcl_zlk05_sys_api=>ty_t_role.

  PROTECTED SECTION.
    DATA mv_mode    TYPE string.
    DATA mv_current TYPE string.
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_detail.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed twice:
    "! after an event that only changed the mode, and - most importantly -
    "! when the transaction is navigated back to from another one, where the
    "! framework supplies no event at all.
    METHODS render.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_bname TYPE string.
    "! The menu bar is the same on both screens of the transaction.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_su01_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      view_display( ).
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
    DATA(lt_arg)   = client->get( )-t_event_arg.
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
        IF lines( lt_arg ) > 0.
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


  METHOD menu_entries.

    result = VALUE #( ( `User` ) ( `Edit` ) ( `Goto` ) ( `Information` )
                      ( `Environment` ) ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_users.
    mt_users = zcl_zlk05_sys_api=>search_users( iv_pattern = mv_pattern ).
    mv_mode  = `LIST`.

    IF lines( mt_users ) = 0.
      mv_message = `No users found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_users ) } user(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_roles.
    mv_current = iv_bname.
    mt_roles   = zcl_zlk05_sys_api=>get_user_roles( iv_bname ).
    mv_mode    = `DETAIL`.

    IF lines( mt_roles ) = 0.
      mv_message = |User { iv_bname } has no roles assigned.|.
      mv_msgtype = `Information`.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar with the command field. This is the entry
    " screen of the transaction, so Back leaves it.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `User Maintenance: Initial Screen` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the users of the selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://add-employee` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create User - { c_na }| )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://locked` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Locks - { c_na }| )
            ( icon = `sap-icon://key` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Password - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://group-2` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Mass Changes - { c_na }| )
            ( icon = `sap-icon://official-service` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Information System - { c_na }| ) ) ).

    " band 5 - work area. The initial screen of SU01 asks for the user name,
    " the hit list below is what the Display function produces.
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = sel
                                   iv_text   = `User` ).

    sel->tag( `Input`
        )->a( n = `id`          v = `idUserName`
        )->a( n = `value`       v = client->_bind( mv_pattern )
        )->a( n = `placeholder` v = `* for all users`
        )->a( n = `width`       v = `18rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idUserName` ) ) ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_users )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `User|BNAME|12rem` )
        ( `Name|FULLNAME|18rem` )
        ( `User Type|USTYPTXT|10rem` )
        ( `Lock Status|LOCKSTATE|10rem` )
        ( `Valid To|VALIDTO|8rem` )
        ( `Last Logon|LASTLOGON|8rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).

      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `BNAME`.
        " the user name drills down to the role assignment, like the double
        " click in the original hit list. The handler has to sit INSIDE the
        " row template - only there does ${BNAME} resolve to the row.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${BNAME}` ) ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 - status bar
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar( io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar. This is the second screen of the
    " transaction, so Back returns to the initial screen instead of
    " leaving SU01.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar. The original title of the display screen is
    " "Display Users", the user and the tab are named next to it.
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Display Users`
        iv_hint   = |User { mv_current } - Roles| ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the initial screen (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://display` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display/Change - { c_na }| )
            ( icon = `sap-icon://detail-view` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Details - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://locked` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Locks - { c_na }| )
            ( icon = `sap-icon://key` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Password - { c_na }| )
            ( icon = `sap-icon://it-system` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |System-Dependent Data - { c_na }| )
            ( icon = `sap-icon://chain-link` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |References - { c_na }| )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Documents for Users - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_roles )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Role|AGR_NAME|30rem` )
        ( `Valid From|FROM_DAT|9rem` )
        ( `Valid To|TO_DAT|9rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  t = |{ lines( mt_roles ) } role(s) assigned - display only|
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " F3 goes back one screen here, not out of the transaction
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
