CLASS zcl_sapgui_a2ui5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SAP Easy Access - the entry screen of the SAP GUI look-alike apps.
*
*  The screen follows the classic SAP GUI layout:
*    menu bar - system function bar with the command field - title bar -
*    application function bar - tree / image work area - status bar
*
*  The tree on the left shows the real SAP area menu (structure S000,
*  the same hierarchy the SAP GUI reads) plus a Favorites folder with
*  the transactions implemented in this environment. Folders are
*  expanded on the server, so only the visible part of the menu is read.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    TYPES:
      BEGIN OF ty_s_tcode,
        tcode TYPE string,
        text  TYPE string,
        icon  TYPE string,
        class TYPE string,
      END OF ty_s_tcode.
    TYPES ty_t_tcode TYPE STANDARD TABLE OF ty_s_tcode WITH EMPTY KEY.

    DATA mv_command    TYPE string.
    DATA mt_favorites  TYPE ty_t_tcode.
    DATA mt_all_tcodes TYPE ty_t_tcode.
    DATA mv_message    TYPE string.
    DATA mv_msg_type   TYPE string.
    DATA mv_username   TYPE string.
    DATA mv_sysid      TYPE string.
    DATA mv_client     TYPE string.
    DATA mv_host       TYPE string.
    "! Keys of the expanded tree folders
    DATA mt_expanded   TYPE string_table.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    CONSTANTS c_key_fav   TYPE string VALUE `#FAVORITES`.
    CONSTANTS c_key_menu  TYPE string VALUE `#SAPMENU`.
    CONSTANTS c_area_menu TYPE string VALUE `S000`.
    CONSTANTS c_max_depth TYPE i VALUE 12.

    " Colours of the classic SAP GUI toolbar icons
    CONSTANTS c_col_blue   TYPE string VALUE `#0a6ed1`.
    CONSTANTS c_col_grey   TYPE string VALUE `#6a6d70`.
    CONSTANTS c_col_gold   TYPE string VALUE `#e9a800`.

    METHODS view_display.
    METHODS on_event.
    METHODS init_menu.
    METHODS normalize_command
      IMPORTING iv_command    TYPE string
      RETURNING VALUE(result) TYPE string.
    "! Starts the transaction. result = abap_true when the framework was
    "! asked to navigate to another app - in that case the caller must NOT
    "! render a view any more.
    METHODS start_transaction
      IMPORTING iv_tcode      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    " --- tree state ---
    METHODS toggle_node
      IMPORTING iv_key TYPE string.
    METHODS is_expanded
      IMPORTING iv_key        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    " The menu bar, system function bar, title bar and status bar are the
    " same on every screen and come from ZCL_ZLK05_GUI_FRAME. Only the work
    " area is specific to this screen.
    METHODS build_work_area
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder.

    " --- tree rendering ---
    METHODS build_tree_items
      IMPORTING io_items TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS build_menu_level
      IMPORTING io_items     TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_struct_id TYPE string
                iv_node_id   TYPE string
                iv_level     TYPE i
                it_path      TYPE string_table.
    METHODS add_tree_row
      IMPORTING io_items      TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_level      TYPE i
                iv_state      TYPE string
                iv_icon       TYPE string
                iv_icon_color TYPE string
                iv_text       TYPE string
                iv_as_link    TYPE abap_bool DEFAULT abap_false
                iv_suffix     TYPE string OPTIONAL
                iv_press      TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sapgui_a2ui5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_username = CONV string( sy-uname ).
      mv_sysid    = CONV string( sy-sysid ).
      mv_client   = CONV string( sy-mandt ).
      mv_host     = CONV string( sy-host ).
      init_menu( ).
      " Favorites and SAP Menu start expanded, like the SAP GUI does
      mt_expanded = VALUE #( ( c_key_fav ) ( c_key_menu ) ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      " A transaction was left with F3 / the Back arrow and handed control
      " back to the entry screen. The framework supplies an EMPTY event here
      " and check_on_init is already false, so without this branch nothing
      " would be rendered: the response would carry no view and the browser
      " would keep showing the screen of the transaction that was just left.
      " That is what made Back look dead and F3 only work on the second try.
      view_display( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD init_menu.

    " The list of transactions lives in the router - the command field of
    " every screen dispatches through the same table.
    mt_all_tcodes = CORRESPONDING #( zcl_zlk05_tcode_router=>get_apps( ) ).
    mt_favorites  = CORRESPONDING #( zcl_zlk05_tcode_router=>get_favorites( ) ).

  ENDMETHOD.


  METHOD normalize_command.

    " Command field syntax of the SAP GUI - the router owns the rules
    result = zcl_zlk05_tcode_router=>normalize_command( iv_command ).

  ENDMETHOD.


  METHOD is_expanded.

    result = xsdbool( line_exists( mt_expanded[ table_line = iv_key ] ) ).

  ENDMETHOD.


  METHOD toggle_node.

    IF iv_key IS INITIAL.
      RETURN.
    ENDIF.

    READ TABLE mt_expanded TRANSPORTING NO FIELDS WITH KEY table_line = iv_key.
    IF sy-subrc = 0.
      DELETE mt_expanded INDEX sy-tabix.
    ELSE.
      APPEND iv_key TO mt_expanded.
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get( )-event.
    DATA(lt_arg)   = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msg_type.

    CASE lv_event.
      WHEN zcl_zlk05_gui_frame=>c_ev_command.
        " command field - Enter in the field or the green tick
        IF start_transaction( mv_command ) = abap_true.
          RETURN.
        ENDIF.

      WHEN 'TCODE_CLICK'.
        IF lines( lt_arg ) > 0.
          IF start_transaction( to_upper( lt_arg[ 1 ] ) ) = abap_true.
            RETURN.
          ENDIF.
        ENDIF.

      WHEN 'TREE_TOGGLE'.
        IF lines( lt_arg ) > 0.
          toggle_node( lt_arg[ 1 ] ).
        ENDIF.

      WHEN OTHERS.
    ENDCASE.

    view_display( ).

  ENDMETHOD.


  METHOD start_transaction.

    " Starting a transaction is the job of the router - it is reached from
    " the command field, from the tree and from every other screen.
    DATA(ls_run) = zcl_zlk05_tcode_router=>run( iv_command = iv_tcode
                                                io_client  = client ).
    mv_message  = ls_run-message.
    mv_msg_type = ls_run-msg_type.

    result = xsdbool( ls_run-outcome = zcl_zlk05_tcode_router=>c_nav ).
    IF result = abap_true.
      CLEAR mv_command.
    ENDIF.

  ENDMETHOD.


  METHOD view_display.
    " ===== View =====

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).

    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    " band 6 first - the status bar lives in the footer aggregation
    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                           iv_message  = mv_message
                                           iv_msg_type = mv_msg_type
                                           iv_sysid    = mv_sysid
                                           iv_client   = mv_client
                                           iv_user     = mv_username
                                           iv_host     = mv_host ).

    " band 1 - menu bar
    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE string_table(
            ( `Menu` ) ( `Edit` ) ( `Favorites` ) ( `Extras` ) ( `System` ) ( `Help` ) ) ).

    " band 2 - system function bar. The command field is active here, Back
    " is not - the SAP Easy Access screen is the root of the session.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent    = page
        iv_cmd_value = client->_bind( mv_command )
        iv_cmd_event = client->_event( zcl_zlk05_gui_frame=>c_ev_command ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar( io_parent = page
                                          iv_title  = `SAP Easy Access` ).

    " band 4 - application function bar. Maintaining favorites needs write
    " access, so these buttons are display only.
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE zcl_zlk05_gui_frame=>ty_t_button(
            ( icon = `sap-icon://person-placeholder` color = c_col_blue
              tooltip = `User menu - not available in this environment` )
            ( icon = `sap-icon://open-folder` color = c_col_gold
              tooltip = `Other menu - not available in this environment` )
            ( icon = `sap-icon://add-folder` color = c_col_gold
              tooltip = `Create role - not available in this environment` )
            ( sep = abap_true )
            ( icon = `sap-icon://add-favorite` color = c_col_gold
              tooltip = `Add to favorites - not available in this environment` )
            ( icon = `sap-icon://delete` color = c_col_grey
              tooltip = `Delete favorites - not available in this environment` )
            ( icon = `sap-icon://edit` color = c_col_grey
              tooltip = `Change favorites - not available in this environment` )
            ( sep = abap_true )
            ( icon = `sap-icon://navigation-down-arrow` color = c_col_grey
              tooltip = `Move favorites down - not available in this environment` )
            ( icon = `sap-icon://navigation-up-arrow` color = c_col_grey
              tooltip = `Move favorites up - not available in this environment` ) ) ).

    " band 5 - work area
    build_work_area( page ).

    " the cursor sits in the command field, exactly like the SAP GUI
    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idCommandField` ) ) ).

    " F3 and friends - the entry screen is the root of the session, so
    " Back is not registered here
    zcl_zlk05_gui_frame=>register_keys( io_client    = client
                                        iv_back_name = `` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD build_work_area.

    " Work area - menu tree on the left, logon image area on the right.
    " Both halves carry FlexItemData: without it the flex box shrinks the
    " tree column down to the width of its shortest line.
    DATA(flex) = io_parent->ele( `HBox`
        )->a( n = `width`      v = `100%`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `alignItems` v = `Stretch`
        )->a( n = `renderType` v = `Bare` ).

    DATA(scroll) = flex->ele( `ScrollContainer`
        )->a( n = `height`     v = `100%`
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    scroll->ele( `layoutData`
        )->tag( `FlexItemData`
        )->a( n = `growFactor`   v = `0`
        )->a( n = `shrinkFactor` v = `0`
        )->a( n = `baseSize`     v = `30rem` ).

    DATA(list) = scroll->ele( `List`
        )->a( n = `showSeparators`   v = `None`
        )->a( n = `backgroundDesign` v = `Solid`
        )->a( n = `mode`             v = `None`
        )->a( n = `noDataText`       v = `The SAP menu could not be read` ).

    build_tree_items( list->ele( `items` ) ).

    " The SAP GUI shows the logon image here. That image is delivered by the
    " SAP GUI installation and not by the server, so this area shows the SAP
    " logo as a watermark and says so.
    DATA(image_area) = flex->ele( `VBox`
        )->a( n = `height`         v = `100%`
        )->a( n = `justifyContent` v = `Center`
        )->a( n = `alignItems`     v = `Center` ).

    image_area->ele( `layoutData`
        )->tag( `FlexItemData`
        )->a( n = `growFactor`   v = `1`
        )->a( n = `shrinkFactor` v = `1`
        )->a( n = `baseSize`     v = `0%` ).

    image_area->tag( n = `Icon` ns = `core`
        )->a( n = `src`     v = `sap-icon://SAP-logo-shape`
        )->a( n = `size`    v = `9rem`
        )->a( n = `color`   v = `#d5dce3`
        )->a( n = `tooltip` v = `Logon image - delivered by the SAP GUI installation, not by the server` ).

    image_area->tag( `Text`
        )->a( n = `text`      v = `Logon image of the SAP GUI installation - not available in this environment`
        )->a( n = `textAlign` v = `Center`
        )->a( n = `class`    v = `sapUiSmallMarginTop` ).

  ENDMETHOD.


  METHOD build_tree_items.
    " ===== Tree =====

    " ----- Favorites -----
    DATA(lv_fav_open) = is_expanded( c_key_fav ).

    add_tree_row(
        io_items      = io_items
        iv_level      = 0
        iv_state      = COND string( WHEN lv_fav_open = abap_true THEN `OPEN` ELSE `CLOSED` )
        iv_icon       = COND string( WHEN lv_fav_open = abap_true
                                     THEN `sap-icon://open-folder` ELSE `sap-icon://folder-blank` )
        iv_icon_color = c_col_gold
        iv_text       = `Favorites`
        iv_press      = client->_event( val   = `TREE_TOGGLE`
                                        t_arg = VALUE #( ( c_key_fav ) ) ) ).

    IF lv_fav_open = abap_true.
      LOOP AT mt_favorites ASSIGNING FIELD-SYMBOL(<fav>).
        add_tree_row(
            io_items      = io_items
            iv_level      = 1
            iv_state      = `LEAF`
            iv_icon       = `sap-icon://favorite`
            iv_icon_color = c_col_gold
            iv_text       = |{ <fav>-tcode } - { <fav>-text }|
            iv_as_link    = abap_true
            iv_press      = client->_event( val   = `TCODE_CLICK`
                                            t_arg = VALUE #( ( <fav>-tcode ) ) ) ).
      ENDLOOP.
    ENDIF.

    " ----- SAP Menu -----
    DATA(lv_menu_open) = is_expanded( c_key_menu ).

    add_tree_row(
        io_items      = io_items
        iv_level      = 0
        iv_state      = COND string( WHEN lv_menu_open = abap_true THEN `OPEN` ELSE `CLOSED` )
        iv_icon       = COND string( WHEN lv_menu_open = abap_true
                                     THEN `sap-icon://open-folder` ELSE `sap-icon://folder-blank` )
        iv_icon_color = c_col_blue
        iv_text       = `SAP Menu`
        iv_press      = client->_event( val   = `TREE_TOGGLE`
                                        t_arg = VALUE #( ( c_key_menu ) ) ) ).

    IF lv_menu_open = abap_true.
      build_menu_level(
          io_items     = io_items
          iv_struct_id = c_area_menu
          iv_node_id   = ``
          iv_level     = 1
          it_path      = VALUE #( ( c_area_menu ) ) ).
    ENDIF.

  ENDMETHOD.


  METHOD build_menu_level.

    IF iv_level > c_max_depth.
      RETURN.
    ENDIF.

    DATA(lt_nodes) = zcl_zlk05_sys_api=>get_area_menu_children(
        iv_struct_id = iv_struct_id
        iv_node_id   = iv_node_id ).

    LOOP AT lt_nodes ASSIGNING FIELD-SYMBOL(<nd>).

      " '+xxx' entries are area menu placeholders, the SAP GUI hides them too
      IF <nd>-tcode CP `+*`.
        CONTINUE.
      ENDIF.

      IF <nd>-is_folder = abap_false.
        add_tree_row(
            io_items      = io_items
            iv_level      = iv_level
            iv_state      = `LEAF`
            iv_icon       = `sap-icon://document-text`
            iv_icon_color = c_col_grey
            iv_text       = <nd>-text
            iv_as_link    = abap_true
            iv_suffix     = <nd>-tcode
            iv_press      = client->_event( val   = `TCODE_CLICK`
                                            t_arg = VALUE #( ( <nd>-tcode ) ) ) ).
        CONTINUE.
      ENDIF.

      DATA(lv_open) = is_expanded( <nd>-node_key ).

      add_tree_row(
          io_items      = io_items
          iv_level      = iv_level
          iv_state      = COND string( WHEN lv_open = abap_true THEN `OPEN` ELSE `CLOSED` )
          iv_icon       = COND string( WHEN lv_open = abap_true
                                       THEN `sap-icon://open-folder` ELSE `sap-icon://folder-blank` )
          iv_icon_color = c_col_blue
          iv_text       = <nd>-text
          iv_press      = client->_event( val   = `TREE_TOGGLE`
                                          t_arg = VALUE #( ( <nd>-node_key ) ) ) ).

      IF lv_open = abap_false.
        CONTINUE.
      ENDIF.

      " children either live in the same structure or in a referenced one
      DATA lv_struct TYPE string.
      DATA lv_node   TYPE string.
      IF <nd>-sub_tree IS NOT INITIAL.
        lv_struct = <nd>-sub_tree.
        lv_node   = <nd>-sub_node.
      ELSE.
        lv_struct = <nd>-struct_id.
        lv_node   = <nd>-node_id.
      ENDIF.

      " a structure must not be entered twice on the same path
      IF lv_struct <> iv_struct_id AND line_exists( it_path[ table_line = lv_struct ] ).
        CONTINUE.
      ENDIF.

      DATA lt_path TYPE string_table.
      lt_path = it_path.
      IF NOT line_exists( lt_path[ table_line = lv_struct ] ).
        APPEND lv_struct TO lt_path.
      ENDIF.

      build_menu_level(
          io_items     = io_items
          iv_struct_id = lv_struct
          iv_node_id   = lv_node
          iv_level     = iv_level + 1
          it_path      = lt_path ).

    ENDLOOP.

  ENDMETHOD.


  METHOD add_tree_row.

    DATA(item) = io_items->ele( `CustomListItem` ).

    " Folders react on the whole row, transactions on the link - that keeps
    " the press events apart and matches the look of the SAP GUI tree.
    IF iv_as_link = abap_true.
      item->a( n = `type` v = `Inactive` ).
    ELSE.
      item->a( n = `type`  v = `Active`
          )->a( n = `press` v = iv_press ).
    ENDIF.

    DATA(row) = item->ele( `HBox` )->a( n = `alignItems` v = `Center` ).

    " indentation of the tree level
    row->tag( `HBox` )->a( n = `width` v = |{ 4 + iv_level * 18 }px| ).

    " expander
    CASE iv_state.
      WHEN `OPEN`.
        row->tag( n = `Icon` ns = `core`
            )->a( n = `src`   v = `sap-icon://navigation-down-arrow`
            )->a( n = `size`  v = `0.7rem`
            )->a( n = `color` v = c_col_grey ).
      WHEN `CLOSED`.
        row->tag( n = `Icon` ns = `core`
            )->a( n = `src`   v = `sap-icon://navigation-right-arrow`
            )->a( n = `size`  v = `0.7rem`
            )->a( n = `color` v = c_col_grey ).
      WHEN OTHERS.
        row->tag( `HBox` )->a( n = `width` v = `0.7rem` ).
    ENDCASE.

    row->tag( n = `Icon` ns = `core`
        )->a( n = `src`   v = iv_icon
        )->a( n = `size`  v = `0.875rem`
        )->a( n = `color` v = iv_icon_color
        )->a( n = `class` v = `sapUiTinyMarginBegin` ).

    " wrapping off - a tree line of the SAP GUI is one line, never two
    IF iv_as_link = abap_true.
      row->tag( `Link`
          )->a( n = `text`     v = iv_text
          )->a( n = `press`    v = iv_press
          )->a( n = `wrapping` v = `false`
          )->a( n = `class`    v = `sapUiTinyMarginBegin` ).
    ELSE.
      row->tag( `Text`
          )->a( n = `text`     v = iv_text
          )->a( n = `wrapping` v = `false`
          )->a( n = `class`    v = `sapUiTinyMarginBegin` ).
    ENDIF.

    IF iv_suffix IS NOT INITIAL.
      row->tag( `Text`
          )->a( n = `text`     v = |({ iv_suffix })|
          )->a( n = `wrapping` v = `false`
          )->a( n = `class`    v = `sapUiTinyMarginBegin`
          )->a( n = `tooltip`  v = |Transaction { iv_suffix }| ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
