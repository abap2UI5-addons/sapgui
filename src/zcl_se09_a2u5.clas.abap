CLASS zcl_se09_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE09 / SE10 - Transport Organizer
*
*  Screen titles, menu bar, function and field texts are the original
*  ones of the Transport Organizer (RSMPTEXTS / D021T):
*
*    T  RDDM0001 INITIAL_SCREEN  Transport Organizer
*       SAPLSTR6 100  Display Request/Task
*    M  Request  Edit  Goto  Settings  Environment
*    F  CONTINUE Display Selection   CREA Create...   SRCH Find Requests
*       REFR Refresh Global Information   TOGGLE Transport Organizer (Extended View)
*       ADVANCED Further Settings...   STANDARD Get Standard Settings
*    D  0220  User, Request Status (Modifiable/Released),
*             Request Type (Workbench/Customizing/Transport of Copies/
*             Relocations), Display button
*
*  Two screens: the selection screen with checkboxes for type and status,
*  and the request list with drill-down into the object list of one
*  request. Everything that would change a request is present but disabled.
*
*  SE09 defaults to Workbench Requests checked, SE10 to Customizing.
*  Since the router maps both to this class, both types are always shown.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    "! Content of the command field of the system function bar
    DATA mv_command TYPE string.

    " selection criteria
    DATA mv_user     TYPE string.
    DATA mv_mod      TYPE abap_bool.
    DATA mv_rel      TYPE abap_bool.
    DATA mv_typ_wb   TYPE abap_bool.
    DATA mv_typ_cust TYPE abap_bool.
    DATA mv_typ_cop  TYPE abap_bool.
    DATA mv_typ_move TYPE abap_bool.

    " result tables
    DATA mt_requests TYPE zcl_zlk05_sys_api=>ty_t_transport.
    DATA mt_objects  TYPE zcl_zlk05_sys_api=>ty_t_tr_object.

  PROTECTED SECTION.
    " current view
    DATA mv_mode     TYPE string.
    DATA mv_current  TYPE string.
    DATA mv_message  TYPE string.
    DATA mv_msgtype  TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_detail.
    METHODS on_event.
    METHODS render.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_trkorr TYPE string.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.
    "! Request Status of the selection screen mapped to TRSTATUS. Only one
    "! status can be passed to the API, so a mixed selection means: no
    "! filter, and the status text of every row tells them apart.
    METHODS status_filter
      RETURNING VALUE(result) TYPE string.
    "! Request Type of the selection screen mapped to TRFUNCTION. Tasks are
    "! judged by the type of their own row, the way the original does it:
    "! S/R/X belong to a workbench request, Q to a customizing request.
    METHODS type_selected
      IMPORTING iv_trfunction TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_se09_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_user     = to_upper( sy-uname ).
      mv_mod      = abap_true.
      mv_rel      = abap_false.
      mv_typ_wb   = abap_true.
      mv_typ_cust = abap_true.
      mv_typ_cop  = abap_false.
      mv_typ_move = abap_false.
      mv_mode     = `LIST`.
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get_event( ).
    DATA(lt_arg)   = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msgtype.

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

    result = VALUE #( ( `Request` ) ( `Edit` ) ( `Goto` )
                      ( `Settings` ) ( `Environment` ) ( `System` ) ( `Help` ) ).

  ENDMETHOD.


  METHOD status_filter.

    " D = Modifiable, R = Released (TRSTATUS domain). Both or none checked
    " means no filter - the original then lists both groups as well.
    IF mv_mod = abap_true AND mv_rel = abap_false.
      result = `D`.
    ELSEIF mv_rel = abap_true AND mv_mod = abap_false.
      result = `R`.
    ELSE.
      result = ``.
    ENDIF.

  ENDMETHOD.


  METHOD type_selected.

    " TRFUNCTION domain values behind the four checkboxes of Request Type
    CASE iv_trfunction.
      WHEN `K` OR `S` OR `R`.
        " Workbench Request, Development/Correction, Repair
        result = mv_typ_wb.
      WHEN `W` OR `Q`.
        " Customizing Request, Customizing Task
        result = mv_typ_cust.
      WHEN `T`.
        " Transport of Copies
        result = mv_typ_cop.
      WHEN `C` OR `E` OR `O`.
        " Relocation of objects / of a complete package
        result = mv_typ_move.
      WHEN OTHERS.
        " X unclassified task, piece lists and everything the original
        " leaves to the status selection alone
        result = abap_true.
    ENDCASE.

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_requests.

    " The API filters owner and status in the SELECT, the request type is
    " judged here - E070-TRFUNCTION is not a parameter of the API.
    DATA(lt_all) = zcl_zlk05_sys_api=>get_transports( iv_user   = mv_user
                                                      iv_status = status_filter( )
                                                      iv_max    = 200 ).

    LOOP AT lt_all ASSIGNING FIELD-SYMBOL(<t>).
      IF type_selected( <t>-trfunction ) = abap_false.
        CONTINUE.
      ENDIF.
      APPEND <t> TO mt_requests.
    ENDLOOP.

    mv_mode = `LIST`.

    IF lines( mt_requests ) = 0.
      mv_message = `No requests/tasks found for the selection.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_requests ) } request(s)/task(s) displayed.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    CLEAR mt_objects.
    mv_current = iv_trkorr.

    mt_objects = zcl_zlk05_sys_api=>get_transport_objects( iv_trkorr ).

    IF lines( mt_objects ) = 0.
      mv_message = |Request { iv_trkorr } has no objects.|.
      mv_msgtype = `Warning`.
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

    " band 2 - system function bar
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " band 3 - title bar
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Transport Organizer` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display Selection (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create... - { c_na }| )
            ( icon = `sap-icon://sys-find` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Find Requests - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://refresh` color = zcl_zlk05_gui_frame=>c_green
              tooltip = |Refresh Global Information - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://slim-arrow-right` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Transport Organizer (Extended View) - { c_na }| )
            ( icon = `sap-icon://action-settings` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Further Settings... - { c_na }| )
            ( icon = `sap-icon://undo` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Get Standard Settings - { c_na }| ) ) ).

    " band 5 - work area. Dynpro 0220 of the Transport Organizer: user,
    " request status checkboxes, request type checkboxes, and the hit list.
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " --- selection area ---
    DATA(sel) = work->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " User row
    DATA(row_user) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row_user
                                   iv_text   = `User` ).
    row_user->tag( `Input`
        )->a( n = `id`      v = `idUser`
        )->a( n = `value`   v = client->_bind( mv_user )
        )->a( n = `width`   v = `12rem`
        )->a( n = `submit`  v = client->_event( `EXECUTE` ) ).
    row_user->end( ).

    " Request Status row
    DATA(row_stat) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row_stat
                                   iv_text   = `Request Status` ).
    row_stat->tag( `CheckBox`
        )->a( n = `text`     v = `Modifiable`
        )->a( n = `selected` v = client->_bind( mv_mod ) ).
    row_stat->tag( `CheckBox`
        )->a( n = `text`     v = `Released`
        )->a( n = `selected` v = client->_bind( mv_rel )
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).
    row_stat->end( ).

    " Request Type row
    DATA(row_type) = sel->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row_type
                                   iv_text   = `Request Type` ).
    row_type->tag( `CheckBox`
        )->a( n = `text`     v = `Workbench Requests`
        )->a( n = `selected` v = client->_bind( mv_typ_wb ) ).
    row_type->tag( `CheckBox`
        )->a( n = `text`     v = `Customizing Requests`
        )->a( n = `selected` v = client->_bind( mv_typ_cust )
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).
    row_type->tag( `CheckBox`
        )->a( n = `text`     v = `Transport of Copies`
        )->a( n = `selected` v = client->_bind( mv_typ_cop )
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).
    row_type->tag( `CheckBox`
        )->a( n = `text`     v = `Relocations`
        )->a( n = `selected` v = client->_bind( mv_typ_move )
        )->a( n = `class`    v = `sapUiSmallMarginBegin` ).
    row_type->end( ).

    " the Display pushbutton of the dynpro itself - D021T 0220
    " %_AUTOTEXT028 "@3M\\QDisplay selection@ Display"
    sel->tag( `Button`
        )->a( n = `text`    v = `Display`
        )->a( n = `icon`    v = `sap-icon://display`
        )->a( n = `type`    v = `Transparent`
        )->a( n = `width`   v = `8rem`
        )->a( n = `class`   v = `sapUiTinyMarginTop`
        )->a( n = `tooltip` v = `Display selection`
        )->a( n = `press`   v = client->_event( `EXECUTE` ) ).

    sel->end( ).

    " --- result table ---
    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_requests )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `8` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Request/Task|TRKORR|12rem` )
        ( `Type|FUNCTXT|14rem` )
        ( `Status|STATUSTXT|10rem` )
        ( `Owner|AS4USER|10rem` )
        ( `Date|AS4DATE|9rem` )
        ( `Target|TARSYSTEM|8rem` )
        ( `Short Description|AS4TEXT|36rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   v = lv_fld
          )->a( n = `filterProperty` v = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).

      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      IF lv_fld = `TRKORR`.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = `DISPLAY`
                                                  arg = `${TRKORR}` ) ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    " function keys
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

    " band 2 - system function bar. Second screen, Back returns to the list.
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " band 3 - title bar. SAPLSTR6 title 100 carries no placeholder, so the
    " title is the plain original text - the request number stands in the
    " Request/task field of the screen, exactly like in the original.
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Display Request/Task` ).

    " band 4 - application function bar
    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the selection (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://display` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display Object - { c_na }| )
            ( icon = `sap-icon://detail-view` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Object Attributes - { c_na }| )
            ( icon = `sap-icon://list` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Object List - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display <-> Change - { c_na }| )
            ( icon = `sap-icon://locked` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Lock Overview - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Documentation - { c_na }| )
            ( icon = `sap-icon://sys-help` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Information - { c_na }| ) ) ).

    " band 5 - work area
    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    " header fields of the request (SAPLSTR6 Dynpro 0100)
    DATA(hdr) = work->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " find the request in the result list for header info
    DATA(ls_req) = VALUE zcl_zlk05_sys_api=>ty_s_transport(
        mt_requests[ trkorr = mv_current ] OPTIONAL ).

    DATA(row1) = hdr->ele( `HBox` )->a( n = `alignItems` v = `Center` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row1 iv_text = `Request/task` ).
    row1->tag( `Text` )->a( n = `text` t = mv_current ).
    row1->end( ).

    DATA(row2) = hdr->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `Request type` ).
    row2->tag( `Text` )->a( n = `text` t = ls_req-functxt ).
    row2->end( ).

    DATA(row3) = hdr->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row3 iv_text = `Status` ).
    row3->tag( `Text` )->a( n = `text` t = ls_req-statustxt ).
    row3->end( ).

    DATA(row4) = hdr->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row4 iv_text = `Owner` ).
    row4->tag( `Text` )->a( n = `text` t = ls_req-as4user ).
    row4->end( ).

    DATA(row5) = hdr->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row5 iv_text = `Last changed` ).
    row5->tag( `Text` )->a( n = `text` t = |{ ls_req-as4date } { ls_req-as4time }| ).
    row5->end( ).

    IF ls_req-strkorr IS NOT INITIAL.
      DATA(row6) = hdr->ele( `HBox`
          )->a( n = `alignItems` v = `Center`
          )->a( n = `class`      v = `sapUiTinyMarginTop` ).
      zcl_zlk05_gui_frame=>add_label( io_parent = row6 iv_text = `Parent Request` ).
      row6->tag( `Text` )->a( n = `text` t = ls_req-strkorr ).
      row6->end( ).
    ENDIF.

    IF ls_req-tarsystem IS NOT INITIAL.
      DATA(row7) = hdr->ele( `HBox`
          )->a( n = `alignItems` v = `Center`
          )->a( n = `class`      v = `sapUiTinyMarginTop` ).
      zcl_zlk05_gui_frame=>add_label( io_parent = row7 iv_text = `Target` ).
      row7->tag( `Text` )->a( n = `text` t = ls_req-tarsystem ).
      row7->end( ).
    ENDIF.

    IF ls_req-as4text IS NOT INITIAL.
      DATA(row8) = hdr->ele( `HBox`
          )->a( n = `alignItems` v = `Center`
          )->a( n = `class`      v = `sapUiTinyMarginTop` ).
      zcl_zlk05_gui_frame=>add_label( io_parent = row8 iv_text = `Short Description` ).
      row8->tag( `Text` )->a( n = `text` t = ls_req-as4text ).
      row8->end( ).
    ENDIF.

    hdr->end( ).

    " object list of the request
    work->tag( `Title`
        )->a( n = `text`  v = `Object List`
        )->a( n = `level` v = `H5`
        )->a( n = `class` v = `sapUiSmallMarginBegin sapUiSmallMarginTop` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_objects )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `None`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `6` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Prog. ID|PGMID|8rem` )
        ( `Object Type|OBJECT|10rem` )
        ( `Object Name|OBJ_NAME|36rem` )
        ( `Function|OBJFUNC|8rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   v = lv_fld
          )->a( n = `filterProperty` v = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    DATA(lv_count) = lines( mt_objects ).
    work->tag( `Text`
        )->a( n = `text`  t = |{ lv_count } object(s) - display only|
        )->a( n = `class` v = `sapUiTinyMargin` ).

    " F3 goes back one screen
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
