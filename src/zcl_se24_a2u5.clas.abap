CLASS zcl_se24_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE24 - Class Builder
*
*  Screen titles, menu bar, function and field texts are the original
*  ones of program SAPLSEOD (RSMPTEXTS / D021T):
*
*    T  CIT        Class Builder: Initial Screen
*       CLDISPLAY  Class Builder: Display Class &
*       IFDISPLAY  Class Builder: Display Interface &
*    M  Class  Edit  Goto  Utilities  Environment
*    F  WB_BACK_TB Previous object   WB_FORWARD Next object
*       TRSE Find      TRS+ Find Next      PRI Print
*       WB_MODULE_TEST Unit Tests          GO_VERS Version Management
*       GO_LOCALS_IMP Local Definitions/Implementations
*       GOLC Local Types   WB_COPY Copy Class/Interface
*       WB_DELETE Delete Class/Interface   CI_RENAME Rename Class/Interface
*    D  1000  Object Type / Class / Interface / Display / Change / Create
*       2000  Class/Interface, tabs Properties Interfaces Friends
*             Attributes Methods Events Types Aliases Texts
*
*  Two screens: the initial screen with the object name and the hit
*  list, and the component list of one class or interface. Everything
*  that would change an object is present but disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    "! Content of the command field of the system function bar
    DATA mv_command TYPE string.

    DATA mv_clsname    TYPE string.
    DATA mt_classes    TYPE zcl_zlk05_sys_api=>ty_t_class.
    DATA mt_components TYPE zcl_zlk05_sys_api=>ty_t_component.

  PROTECTED SECTION.
    DATA mv_mode       TYPE string.
    DATA mv_current    TYPE string.
    "! Class or Interface - decides which of the two original display
    "! titles the detail screen carries.
    DATA mv_curtype    TYPE string.
    DATA mv_message    TYPE string.
    DATA mv_msgtype    TYPE string.

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
      IMPORTING iv_clsname TYPE string.
    "! The menu bar is the same on both screens of the transaction.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se24_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

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
      WHEN 'SOURCE'.
        " a double click on a method shows its implementation - in the ABAP
        " Editor, with the method include of the class pool
        SPLIT client->get_event_arg( ) AT `|` INTO DATA(lv_cmp) DATA(lv_kind).
        IF lv_kind <> `Method`.
          mv_message = `Choose a method to display its source code.`.
          mv_msgtype = `Information`.
        ELSE.
          DATA(lv_incl) = zcl_zlk05_sys_api=>get_method_include( iv_class  = mv_current
                                                                iv_method = lv_cmp ).
          IF lv_incl IS INITIAL.
            mv_message = |Method { lv_cmp } has no implementation in { mv_current }.|.
            mv_msgtype = `Warning`.
          ELSE.
          DATA(ls_run) = zcl_zlk05_tcode_router=>run(
                iv_command = `SE38`
                io_client  = client
                it_params  = VALUE #( ( name  = zif_zlk05_start_params=>c_program
                                        value = lv_incl ) ) ).
            IF ls_run-outcome = zcl_zlk05_tcode_router=>c_nav.
              RETURN.
            ENDIF.
            mv_message = ls_run-message.
            mv_msgtype = ls_run-msg_type.
          ENDIF.
        ENDIF.
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

    result = VALUE #( ( `Class` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                      ( `Environment` ) ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_classes.
    mt_classes = zcl_zlk05_sys_api=>search_classes( mv_clsname ).
    mv_mode    = `LIST`.

    IF lines( mt_classes ) = 0.
      mv_message = `No classes or interfaces found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_classes ) } object(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_components.
    mv_current    = iv_clsname.
    mt_components = zcl_zlk05_sys_api=>get_class_components( iv_clsname ).

    " SE24 has one display title for a class and another one for an
    " interface - the hit list already knows which one this is
    mv_curtype = `Class`.
    READ TABLE mt_classes INTO DATA(ls_cls) WITH KEY clsname = iv_clsname.
    IF sy-subrc = 0 AND ls_cls-clstype IS NOT INITIAL.
      mv_curtype = ls_cls-clstype.
    ENDIF.

    IF lines( mt_components ) = 0.
      mv_message = |{ iv_clsname } has no components.|.
      mv_msgtype = `Warning`.
      RETURN.
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
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar. Entry screen of the transaction, so
    " Back leaves it.
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Class Builder: Initial Screen` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the object of the selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy Class/Interface - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete Class/Interface - { c_na }| )
            ( icon = `sap-icon://text-formatting` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Rename Class/Interface - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print - { c_na }| ) ) ).

    " band 5 - work area. The initial screen of SE24 is the Object Type
    " group with the name and the Class / Interface radio buttons.
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(sel) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = sel
                                   iv_text   = `Object Type` ).

    sel->tag( `Input`
        )->a( n = `id`          v = `idClsName`
        )->a( n = `value`       v = client->_bind( mv_clsname )
        )->a( n = `placeholder` v = `e.g. CL_GUI_ALV_GRID or ZCL_*`
        )->a( n = `width`       v = `24rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    " the two radio buttons of the original screen - the app always reads
    " both kinds, so they are shown selected and disabled
    sel->tag( `CheckBox`
        )->a( n = `text`     v = `Class`
        )->a( n = `selected` v = `true`
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = `Classes are always included` ).

    sel->tag( `CheckBox`
        )->a( n = `text`     v = `Interface`
        )->a( n = `selected` v = `true`
        )->a( n = `enabled`  v = `false`
        )->a( n = `tooltip`  v = `Interfaces are always included` ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idClsName` ) ) ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_classes )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Object Name|CLSNAME|30rem` )
        ( `Type|CLSTYPE|9rem` )
        ( `Description|DESCR|40rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).

      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `CLSNAME`.
        " the object name drills down to the component list. The handler has
        " to sit INSIDE the row template - only there does ${CLSNAME} resolve
        " to the row.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${CLSNAME}` ) ).
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
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = page
                                        it_entries = menu_entries( ) ).

    " band 2 - system function bar. Second screen of the transaction, so
    " Back returns to the initial screen instead of leaving SE24.
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar. Class Builder: Display Class & / Interface &
    DATA(lv_type) = COND string( WHEN mv_curtype IS NOT INITIAL
                                 THEN mv_curtype ELSE `Class` ).
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Class Builder: Display { lv_type } { mv_current }| ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the initial screen (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://navigation-left-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Previous object - { c_na }| )
            ( icon = `sap-icon://navigation-right-arrow` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Next object - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check - { c_na }| )
            ( icon = `sap-icon://lab` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Unit Tests - { c_na }| )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Version Management - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://source-code` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Local Definitions/Implementations - { c_na }| )
            ( icon = `sap-icon://tree` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Local Types - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| )
            ( icon = `sap-icon://print` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Print - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " the Class/Interface field of dynpro 2000
    DATA(hdr) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = hdr
                                   iv_text   = `Class/Interface` ).

    hdr->tag( `Text`
        )->a( n = `text` t = mv_current ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_components )
        )->a( n = `cellClick`           v = client->_event( val = `SOURCE`
                                                            arg = `${CMPNAME}|${CMPTYPE}` )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Component|CMPNAME|30rem` )
        ( `Kind|CMPTYPE|10rem` )
        ( `Method Type|MTDTYPE|14rem` )
        ( `Visibility|EXPOSURE|10rem` )
        ( `Redefined|REDEFIN|8rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   t = lv_fld
          )->a( n = `filterProperty` t = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  t = |{ lines( mt_components ) } component(s) - display only|
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " F3 goes back one screen here, not out of the transaction
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
