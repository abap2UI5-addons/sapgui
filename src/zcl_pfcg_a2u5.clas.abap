CLASS zcl_pfcg_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  PFCG - Role Maintenance (display)
*
*  The role field with a hit list, and the role with the tabs of the
*  original: Description, Menu, Authorizations, User - and Roles for a
*  composite role. From the tabs the user goes on like in PFCG: a user
*  to the user maintenance (SU01), a transaction of the menu is started,
*  a single role of a composite role is displayed.
*  Changing, generating and comparing are present but disabled - this
*  app never writes to a role.
*
*  Authorization: S_TCODE PFCG + S_USER_AGR display, and S_USER_AGR
*  display for every single role (ACT_GROUP = role).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.
    INTERFACES zif_zlk05_start_params.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command TYPE string.
    DATA mv_pattern TYPE string.
    DATA mt_roles   TYPE zcl_zlk05_sys_api=>ty_t_agr.

    DATA mt_head    TYPE zcl_zlk05_sys_api=>ty_t_kv.
    DATA mv_descr   TYPE string.
    DATA mt_tcodes  TYPE zcl_zlk05_sys_api=>ty_t_agr_tcode.
    DATA mt_auth    TYPE zcl_zlk05_sys_api=>ty_t_agr_auth.
    DATA mt_users   TYPE zcl_zlk05_sys_api=>ty_t_agr_user.
    DATA mt_single  TYPE zcl_zlk05_sys_api=>ty_t_agr.
    DATA mv_tab     TYPE string.

  PROTECTED SECTION.
    DATA mv_mode    TYPE string.
    DATA mv_current TYPE string.
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    "! Role handed over by another transaction (SU01 ...): shown directly,
    "! and Back returns to the calling transaction
    DATA mv_start_role TYPE string.
    DATA mv_called     TYPE abap_bool.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_event.
    METHODS render.
    METHODS view_list.
    METHODS view_detail.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_role TYPE string.
    METHODS do_jump
      IMPORTING iv_tcode TYPE string
                it_params TYPE zif_zlk05_start_params=>ty_t_param OPTIONAL.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.
    METHODS add_grid
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_rows   TYPE string
                it_cols   TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_pfcg_a2u5 IMPLEMENTATION.


  METHOD zif_zlk05_start_params~set_start_params.
    mv_start_role = to_upper( condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_role ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    " S_TCODE + S_USER_AGR - on EVERY roundtrip, so the app is protected
    " even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      IF mv_start_role IS NOT INITIAL.
        mv_pattern = mv_start_role.
        mv_called  = abap_true.
        do_open( mv_start_role ).
      ENDIF.
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

    DATA(lv_arg) = client->get_event_arg( ).

    CASE client->get_event( ).
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        do_open( lv_arg ).
      WHEN 'DISPLAY_USER'.
        do_jump( iv_tcode  = `SU01`
                 it_params = VALUE #( ( name = zif_zlk05_start_params=>c_user value = lv_arg ) ) ).
        IF mv_msgtype IS INITIAL.
          RETURN.
        ENDIF.
      WHEN 'START_TCODE'.
        " a transaction of the role menu - started like from the user menu,
        " the router checks S_TCODE and whether the environment has it
        do_jump( lv_arg ).
        IF mv_msgtype IS INITIAL.
          RETURN.
        ENDIF.
      WHEN 'BACK_TO_LIST'.
        IF mv_called = abap_true.
          client->nav_app_leave( ).
          RETURN.
        ENDIF.
        mv_mode = `LIST`.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.


  METHOD do_jump.

    IF iv_tcode IS INITIAL.
      RETURN.
    ENDIF.
    DATA(ls_run) = zcl_zlk05_tcode_router=>run( iv_command = iv_tcode
                                                io_client  = client
                                                it_params  = it_params ).
    IF ls_run-outcome = zcl_zlk05_tcode_router=>c_nav.
      CLEAR: mv_message, mv_msgtype.
      RETURN.
    ENDIF.
    mv_message = ls_run-message.
    mv_msgtype = COND #( WHEN ls_run-msg_type IS INITIAL THEN `Warning` ELSE ls_run-msg_type ).

  ENDMETHOD.


  METHOD render.

    IF mv_mode = `DETAIL`.
      view_detail( ).
    ELSE.
      view_list( ).
    ENDIF.

  ENDMETHOD.


  METHOD menu_entries.
    result = VALUE #( ( `Role` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                      ( `Environment` ) ( `System` ) ( `Help` ) ).
  ENDMETHOD.


  METHOD do_search.

    mt_roles = zcl_zlk05_sys_api=>search_roles( iv_pattern = mv_pattern ).
    mv_mode  = `LIST`.
    IF mt_roles IS INITIAL.
      mv_message = `No roles found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_roles ) } role(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    zcl_zlk05_sys_api=>get_role_detail(
      EXPORTING iv_role    = iv_role
      IMPORTING et_head    = DATA(lt_head)
                et_descr   = DATA(lt_descr)
                et_tcodes  = DATA(lt_tcodes)
                et_auth    = DATA(lt_auth)
                et_users   = DATA(lt_users)
                et_roles   = DATA(lt_single)
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    mv_current = to_upper( condense( iv_role ) ).
    mt_head    = lt_head.
    mv_descr   = concat_lines_of( table = lt_descr sep = cl_abap_char_utilities=>newline ).
    mt_tcodes  = lt_tcodes.
    mt_auth    = lt_auth.
    mt_users   = lt_users.
    mt_single  = lt_single.
    mv_tab     = `DESCR`.
    mv_mode    = `DETAIL`.

  ENDMETHOD.


  METHOD add_grid.

    " it_cols: Heading|FIELD|width - link fields open what they name:
    " AGR_NAME a role, UNAME a user (SU01), TCODE starts the transaction;
    " VALIDITY is coloured by the STATE of the row
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
      DATA(lv_event) = SWITCH string( lv_fld WHEN `AGR_NAME` THEN `DISPLAY`
                                             WHEN `UNAME`    THEN `DISPLAY_USER`
                                             WHEN `TCODE`    THEN `START_TCODE` ).
      IF lv_event IS NOT INITIAL.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = lv_event arg = |$\{{ lv_fld }\}| ) ).
      ELSEIF lv_fld = `VALIDITY`.
        tmpl->tag( `ObjectStatus`
            )->a( n = `text`  v = `{VALIDITY}`
            )->a( n = `state` v = `{STATE}` ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
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
        iv_title  = `Role Maintenance` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the roles of the selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://create` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create Single Role - { c_na }| )
            ( icon = `sap-icon://add-folder` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create Composite Role - { c_na }| )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy Role - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete Role - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Role` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idRoleName`
        )->a( n = `value`       v = client->_bind( mv_pattern )
        )->a( n = `placeholder` v = `role or pattern, e.g. SAP_BC_*`
        )->a( n = `width`       v = `24rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row->end( ).

    add_grid( io_parent = work
              iv_rows   = client->_bind( mt_roles )
              it_cols   = VALUE #(
                  ( `Role|AGR_NAME|22rem` )
                  ( `Description|TEXT|28rem` )
                  ( `Type|COMPOSITE|7rem` )
                  ( `Derived From|PARENT|16rem` )
                  ( `Changed By|CHANGED_BY|9rem` )
                  ( `Changed On|CHANGED_ON|7rem` ) ) ).

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
        iv_title  = `Display Roles`
        iv_hint   = |Role { mv_current }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://display` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display <-> Change - { c_na }| )
            ( icon = `sap-icon://synchronize` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |User Comparison - { c_na }| )
            ( icon = `sap-icon://generate-shortcut` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Generate Profile - { c_na }| ) ) ).

    DATA(tabs) = page->ele( `IconTabBar`
        )->a( n = `selectedKey`          v = client->_bind( mv_tab )
        )->a( n = `expandable`           v = `false`
        )->a( n = `stretchContentHeight` v = `true`
        )->a( n = `height`               v = zcl_zlk05_gui_frame=>c_work_height
        )->ele( `items` ).

    " --- Description: the role attributes and its long text
    DATA(c1) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Description`
        )->a( n = `key`  v = `DESCR`
        )->ele( `content` ).
    add_grid( io_parent = c1
              iv_rows   = client->_bind( mt_head )
              it_cols   = VALUE #( ( `Attribute|LABEL|12rem` ) ( `Value|VALUE|40rem` ) ) ).
    c1->tag( `TextArea`
        )->a( n = `value`    v = client->_bind( mv_descr )
        )->a( n = `editable` v = `false`
        )->a( n = `width`    v = `100%`
        )->a( n = `rows`     v = `8` ).

    " --- Menu: the transactions of the role
    DATA(c2) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `Menu`
        )->a( n = `key`   v = `MENU`
        )->a( n = `count` t = |{ lines( mt_tcodes ) }|
        )->ele( `content` ).
    add_grid( io_parent = c2
              iv_rows   = client->_bind( mt_tcodes )
              it_cols   = VALUE #( ( `Transaction|TCODE|10rem` ) ( `Text|TEXT|36rem` ) ) ).

    " --- Authorizations: the active values of the role
    DATA(c3) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `Authorizations`
        )->a( n = `key`   v = `AUTH`
        )->a( n = `count` t = |{ lines( mt_auth ) }|
        )->ele( `content` ).
    add_grid( io_parent = c3
              iv_rows   = client->_bind( mt_auth )
              it_cols   = VALUE #( ( `Object|OBJECT|9rem` ) ( `Authorization|AUTH|10rem` )
                                   ( `Field|FIELD|9rem` ) ( `From|LOW|16rem` )
                                   ( `To|HIGH|16rem` ) ) ).

    " --- User: the assignments and their validity today
    DATA(c4) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `User`
        )->a( n = `key`   v = `USER`
        )->a( n = `count` t = |{ lines( mt_users ) }|
        )->ele( `content` ).
    add_grid( io_parent = c4
              iv_rows   = client->_bind( mt_users )
              it_cols   = VALUE #( ( `User|UNAME|12rem` ) ( `Valid From|FROM_DAT|8rem` )
                                   ( `Valid To|TO_DAT|8rem` ) ( `Validity|VALIDITY|7rem` ) ) ).

    " --- Roles: only a composite role has single roles
    IF mt_single IS NOT INITIAL.
      DATA(c5) = tabs->ele( `IconTabFilter`
          )->a( n = `text`  v = `Roles`
          )->a( n = `key`   v = `ROLES`
          )->a( n = `count` t = |{ lines( mt_single ) }|
          )->ele( `content` ).
      add_grid( io_parent = c5
                iv_rows   = client->_bind( mt_single )
                it_cols   = VALUE #( ( `Single Role|AGR_NAME|22rem` ) ( `Description|TEXT|30rem` ) ) ).
    ENDIF.

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
