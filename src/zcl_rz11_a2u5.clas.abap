CLASS zcl_rz11_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  RZ11 - Profile Parameter Maintenance
*
*  Screen titles, menu bar, group box and function texts are the
*  original ones of program RSPFLDOC (RSMPTEXTS / D021T):
*
*    T 100    Edit Profile Parameters
*    T 110    Display Profile Parameter Attributes
*    M        Edit  Goto
*    D 1000   group box  Profile Parameter Maintenance
*             field      Parameter Name
*    F PDIS   Display              F DDIS  Display Documentation
*    F VCHG   Change Value         F DCHA  Change Documentation
*    F ALLDYN All Dynamic Parameters
*    F PFRECOMM All Recommended Values
*
*  The values come from the kernel through CL_SPFL_PROFILE_PARAMETER -
*  the same source the original RZ11 uses. Everything that would change
*  a parameter is present but disabled.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_pattern TYPE string.
    DATA mv_mode    TYPE string.
    DATA mv_current TYPE string.
    DATA mv_dynonly TYPE abap_bool.
    DATA mv_command  TYPE string.
    DATA mv_message  TYPE string.
    DATA mv_msgtype TYPE string.
    DATA mt_params  TYPE zcl_zlk05_sys_api=>ty_t_param.
    DATA mt_detail  TYPE zcl_zlk05_sys_api=>ty_t_kv.

  PROTECTED SECTION.
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
      IMPORTING iv_paraname TYPE string.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_rz11_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode    = `LIST`.
      mv_pattern = `rdisp/*`.
      do_search( ).
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

    DATA(lv_event) = client->get( )-event.
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
        mv_dynonly = abap_false.
        do_search( ).
      WHEN 'ALLDYN'.
        mv_dynonly = abap_true.
        mv_pattern = `*`.
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


  METHOD do_search.

    CLEAR mt_params.
    mt_params = zcl_zlk05_sys_api=>search_parameters(
                    iv_pattern      = mv_pattern
                    iv_only_dynamic = mv_dynonly ).
    mv_mode   = `LIST`.

    IF lines( mt_params ) = 0.
      mv_message = `No profile parameters found for the selection.`.
      mv_msgtype = `Warning`.
    ELSEIF mv_dynonly = abap_true.
      mv_message = |{ lines( mt_params ) } dynamically switchable parameter(s).|.
      mv_msgtype = `Success`.
    ELSE.
      mv_message = |{ lines( mt_params ) } parameter(s) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_detail.
    mv_current = iv_paraname.
    mt_detail  = zcl_zlk05_sys_api=>get_parameter_detail( iv_paraname ).
    mv_mode    = `DETAIL`.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Edit Profile Parameters` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display parameter`
              press = client->_event( `EXECUTE` ) )
            ( text = `All Dynamic Parameters` icon = `sap-icon://switch-classes`
              tooltip = `All Dynamic Parameters`
              press = client->_event( `ALLDYN` ) )
            ( sep = abap_true )
            ( text = `Display Documentation` icon = `sap-icon://document-text`
              tooltip = |Display Documentation - { c_na }| )
            ( text = `Change Value` icon = `sap-icon://edit`
              tooltip = |Change Value - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://request` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |All Recommended Values - { c_na }| )
            ( icon = `sap-icon://formula` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |All Formula Parameters - { c_na }| )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Activate / Deactivate Vector Parameter - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://download` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Download - { c_na }| )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " group box of dynpro 1000 - Profile Parameter Maintenance
    DATA(sel) = work->ele( `Panel`
        )->a( n = `headerText` v = `Profile Parameter Maintenance`
        )->a( n = `class`      v = `sapUiTinyMargin`
        )->ele( `content`
        )->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMargin` ).

    zcl_zlk05_gui_frame=>add_label( io_parent = sel
                                    iv_text   = `Parameter Name`
                                    iv_width  = `10rem` ).

    sel->tag( `Input`
        )->a( n = `id`          v = `idParaName`
        )->a( n = `value`       v = client->_bind( mv_pattern )
        )->a( n = `placeholder` v = `e.g. rdisp/* or login/*`
        )->a( n = `width`       v = `22rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idParaName` ) ) ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_params )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " column texts of RSPFLDOC (502 Name, 501 Value, 503 Type,
    " 510 Dynamic Parameter, 506 Parameter Group, 507 Description)
    DATA(lt_col) = VALUE string_table(
        ( `Name|PARANAME|22rem` )
        ( `Value|VALUE|14rem` )
        ( `Type|PTYPE|9rem` )
        ( `Dynamic Parameter|DYNAMIC|5rem` )
        ( `Parameter Group|GRP|8rem` )
        ( `Parameter Description|DESCR|28rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` v = lv_wid ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` v = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Link`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `press`    v = client->_event( val   = `DISPLAY`
                                                      t_arg = VALUE #( ( `${PARANAME}` ) ) )
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no parameter is changed here`
        )->a( n = `class` v = `sapUiTinyMargin` ).

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

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = |Parameter { mv_current }|
                                          iv_msg_type = `Information` ).

    zcl_zlk05_gui_frame=>build_menu_bar(
        io_parent  = page
        it_entries = VALUE #( ( `Edit` ) ( `Goto` )
                              ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar(
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    zcl_zlk05_gui_frame=>build_title_bar(
        io_parent = page
        iv_title  = `Display Profile Parameter Attributes` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( text = `Change Value` icon = `sap-icon://edit`
              tooltip = |Change Parameter Value - { c_na }| )
            ( text = `Display Documentation` icon = `sap-icon://document-text`
              tooltip = |Documentation for Parameter { mv_current } - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://detail-view` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Profile Parameter Details - { c_na }| )
            ( icon = `sap-icon://history` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change History - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`   v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical` v = `true` ).

    " group box text of dynpro 1001 - Parameter Properties
    DATA(tab) = work->ele( `Panel`
        )->a( n = `headerText` v = `Parameter Properties`
        )->a( n = `class`      v = `sapUiTinyMargin`
        )->ele( `content`
        )->ele( `Table`
            )->a( n = `items`   v = client->_bind( mt_detail )
            )->a( n = `growing` v = `true`
            )->a( n = `class`   v = `sapUiSizeCompact` ).

    tab->ele( `columns`
        )->ele( `Column` )->a( n = `width` v = `18rem`
            )->tag( `Text` )->a( n = `text` v = `Attribute` )->end(
        )->ele( `Column` )->tag( `Text` )->a( n = `text` v = `Value` )->end(
        )->end( )->ele( `items`
            )->ele( `ColumnListItem` )->ele( `cells`
                )->tag( `Text` )->a( n = `text` v = `{LABEL}`
                )->tag( `Text` )->a( n = `text` v = `{VALUE}` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
