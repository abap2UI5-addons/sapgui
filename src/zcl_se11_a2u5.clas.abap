CLASS zcl_se11_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE11 - ABAP Dictionary
*
*  Screen titles, menu bar, function and field texts are the original
*  ones of the Dictionary (RSMPTEXTS / D021T):
*
*    T  SAPLSD_ENTRY DD_ENTRY  ABAP Dictionary: Initial Screen
*       SAPLSEDS TS1  Dictionary: Display Table &
*       SAPLSEDS ES1  Dictionary: Display Data Element &
*    M  Dictionary Object  Edit  Goto  Utilities  Environment
*    F  WB_DISPLAY Display   WB_EDIT Change   WB_CREATE Create
*       WB_DELETE Delete     WB_CHECK Check   WB_ACTIVATE Activate
*       WB_WHERE_USED_LIST Where-Used List
*       DD_FURTHER_OBJECTS Other Dictionary Objects...
*       DD_DBASE_UTILITY Database Utility
*       DD_ACT_PROTOCOL Activation Log     WB_PRINT Print...
*    D  1000  Database table / View / Domain / Search help /
*             Lock object / Type Group, buttons Display Change Create
*
*  Two screens: the initial screen with the object name and the hit
*  list, and the field list of a table or the properties of a data
*  element. Everything that would change an object is present but
*  disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    "! Content of the command field of the system function bar
    DATA mv_command TYPE string.

    DATA mv_objname TYPE string.
    DATA mv_kind    TYPE string.
    DATA mt_objects TYPE zcl_zlk05_sys_api=>ty_t_ddic_obj.
    DATA mt_fields  TYPE zcl_zlk05_sys_api=>ty_t_ddic_field.
    DATA mt_detail  TYPE zcl_zlk05_sys_api=>ty_t_kv.

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
      IMPORTING iv_name TYPE string.
    "! The menu bar is the same on both screens of the transaction.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se11_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_kind = `TABL`.
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

    result = VALUE #( ( `Dictionary Object` ) ( `Edit` ) ( `Goto` )
                      ( `Utilities` ) ( `Environment` ) ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_objects.

    mt_objects = zcl_zlk05_sys_api=>search_ddic( iv_pattern = mv_objname
                                                 iv_kind    = mv_kind ).
    mv_mode = `LIST`.

    IF lines( mt_objects ) = 0.
      mv_message = `No dictionary objects found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_objects ) } object(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR: mt_fields, mt_detail.
    mv_current = iv_name.

    IF mv_kind = `DTEL`.
      mt_detail = zcl_zlk05_sys_api=>get_dtel_detail( iv_name ).
      IF lines( mt_detail ) = 0.
        mv_message = |Data element { iv_name } could not be read.|.
        mv_msgtype = `Error`.
        RETURN.
      ENDIF.
    ELSE.
      mt_fields = zcl_zlk05_sys_api=>get_table_fields( iv_name ).
      IF lines( mt_fields ) = 0.
        mv_message = |Table { iv_name } has no active field list.|.
        mv_msgtype = `Warning`.
        RETURN.
      ENDIF.
    ENDIF.

    mv_mode = `DETAIL`.

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

    " band 2 - system function bar. Entry screen of the transaction, so
    " Back leaves it.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `ABAP Dictionary: Initial Screen` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the objects of the selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check - { c_na }| )
            ( icon = `sap-icon://accept` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate - { c_na }| )
            ( icon = `sap-icon://chain-link` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://database` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Database Utility - { c_na }| )
            ( icon = `sap-icon://activity-items` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activation Log - { c_na }| )
            ( icon = `sap-icon://open-folder` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Other Dictionary Objects... - { c_na }| ) ) ).

    " band 5 - work area. The initial screen of SE11 is the list of object
    " kinds - Database table, View, Data type, Type Group, Domain,
    " Search help, Lock object - with one name field each. This app reads
    " tables/views and data elements, so the kind is a drop down.
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = sel
                                   iv_text   = `Object Name` ).

    sel->tag( `Input`
        )->a( n = `id`          v = `idObjName`
        )->a( n = `value`       v = client->_bind( mv_objname )
        )->a( n = `placeholder` v = `e.g. MARA or MAR*`
        )->a( n = `width`       v = `18rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    DATA(seg) = sel->ele( `Select`
        )->a( n = `selectedKey` v = client->_bind( mv_kind )
        )->a( n = `width`       v = `15rem` ).
    DATA(segi) = seg->ele( `items` ).
    segi->tag( n = `Item` ns = `core`
        )->a( n = `key`        v = `TABL`
        )->a( n = `text`       v = `Database Table / View`
        )->tag( n = `Item` ns = `core`
            )->a( n = `key`  v = `DTEL`
            )->a( n = `text` v = `Data Element` ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idObjName` ) ) ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_objects )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Name|NAME|20rem` )
        ( `Type|TABCLASS|12rem` )
        ( `Short Description|DESCR|40rem` )
        ( `Last Changed By|AUTHOR|12rem` )
        ( `Changed On|CHDATE|9rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).

      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `NAME`.
        " the object name drills down to the field list. The handler has to
        " sit INSIDE the row template - only there does ${NAME} resolve to
        " the row.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${NAME}` ) ).
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

    " band 2 - system function bar. Second screen of the transaction, so
    " Back returns to the initial screen instead of leaving SE11.
    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar. The Dictionary has one title per object kind:
    " TS1 Dictionary: Display Table & / ES1 ... Data Element &
    DATA(lv_title) = COND string(
        WHEN mv_kind = `DTEL`
        THEN |Dictionary: Display Data Element { mv_current }|
        ELSE |Dictionary: Display Table { mv_current }| ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = lv_title ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the initial screen (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check - { c_na }| )
            ( icon = `sap-icon://accept` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://chain-link` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| )
            ( icon = `sap-icon://database` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Database Utility - { c_na }| )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Version Management - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://form` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Object Directory Entry - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print... - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(hdr) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label(
        io_parent = hdr
        iv_text   = COND string( WHEN mv_kind = `DTEL`
                                 THEN `Data element` ELSE `Database table` ) ).

    hdr->tag( `Text` )->a( n = `text` t = mv_current ).

    DATA lt_col TYPE string_table.

    IF mv_kind = `DTEL`.
      " the property list of a data element
      lt_col = VALUE #( ( `Property|LABEL|20rem` )
                        ( `Value|VALUE|40rem` ) ).
    ELSE.
      " the field list of a table, in the column order of the original
      lt_col = VALUE #( ( `Pos.|POS|4rem` )
                        ( `Field|FIELDNAME|18rem` )
                        ( `Key|KEYFLAG|4rem` )
                        ( `Data element|ROLLNAME|18rem` )
                        ( `Type|DATATYPE|6rem` )
                        ( `Length|LENG|6rem` )
                        ( `Dec.|DECIMALS|5rem` )
                        ( `Short Description|DESCR|36rem` ) ).
    ENDIF.

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = COND #( WHEN mv_kind = `DTEL`
                                                    THEN client->_bind( mt_detail )
                                                    ELSE client->_bind( mt_fields ) )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

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

    DATA(lv_count) = COND i( WHEN mv_kind = `DTEL`
                             THEN lines( mt_detail ) ELSE lines( mt_fields ) ).
    work->tag( `Text`
        )->a( n = `text`  t = |{ lv_count } row(s) - display only|
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " F3 goes back one screen here, not out of the transaction
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
