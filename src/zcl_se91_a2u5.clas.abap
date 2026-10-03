CLASS zcl_se91_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SE91 - Message Maintenance (display)
*
*  Initial screen with the message class and a hit list, the message
*  class with its tabs Attributes and Messages (logon language, original
*  language where a message is not translated), and the long text of a
*  message (document class NA). Creating and changing are present but
*  disabled - this app never writes to T100.
*
*  Authorization: S_TCODE SE91 + S_DEVELOP display (TSTCA of SE91), and
*  S_DEVELOP display for every message class (object type MSAG).
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.
    INTERFACES zif_zlk05_start_params.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_command  TYPE string.
    DATA mv_pattern  TYPE string.
    DATA mt_classes  TYPE zcl_zlk05_sys_api=>ty_t_msgclass.
    DATA mt_head     TYPE zcl_zlk05_sys_api=>ty_t_kv.
    DATA mt_msgs     TYPE zcl_zlk05_sys_api=>ty_t_msg.
    DATA mv_longtext TYPE string.
    DATA mv_tab      TYPE string.

  PROTECTED SECTION.
    DATA mv_mode    TYPE string.
    DATA mv_current TYPE string.
    DATA mv_msgnr   TYPE string.
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    DATA mv_start_class TYPE string.
    DATA mv_called      TYPE abap_bool.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS on_event.
    METHODS render.
    METHODS view_list.
    METHODS view_detail.
    METHODS view_longtext.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_arbgb TYPE string.
    METHODS do_longtext
      IMPORTING iv_msgnr TYPE string.
    METHODS menu_entries
      RETURNING VALUE(result) TYPE string_table.
    METHODS frame
      IMPORTING iv_title      TYPE string
                iv_hint       TYPE string OPTIONAL
                iv_back       TYPE string
                it_buttons    TYPE zcl_zlk05_gui_frame=>ty_t_button
      RETURNING VALUE(result) TYPE REF TO z2ui5_cl_ui5_view_builder.
    METHODS add_grid
      IMPORTING io_parent TYPE REF TO z2ui5_cl_ui5_view_builder
                iv_rows   TYPE string
                it_cols   TYPE string_table.

    DATA mo_view TYPE REF TO z2ui5_cl_ui5_view_builder.

  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_se91_a2u5 IMPLEMENTATION.


  METHOD zif_zlk05_start_params~set_start_params.
    mv_start_class = to_upper( condense( VALUE #(
        it_params[ name = zif_zlk05_start_params=>c_msgclass ]-value OPTIONAL ) ) ).
  ENDMETHOD.


  METHOD z2ui5_if_app~main.

    " S_TCODE + S_DEVELOP display - on EVERY roundtrip, so the app is
    " protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      IF mv_start_class IS NOT INITIAL.
        mv_pattern = mv_start_class.
        mv_called  = abap_true.
        do_open( mv_start_class ).
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

    CASE client->get_event( ).
      WHEN 'EXECUTE'.
        " a full message class name opens it directly, a pattern lists
        DATA(lv_in) = to_upper( condense( mv_pattern ) ).
        IF lv_in IS NOT INITIAL AND lv_in NA '*+'.
          do_open( lv_in ).
          IF mv_mode <> `DETAIL`.
            do_search( ).
          ENDIF.
        ELSE.
          do_search( ).
        ENDIF.
      WHEN 'DISPLAY'.
        do_open( client->get_event_arg( ) ).
      WHEN 'LONGTEXT'.
        do_longtext( client->get_event_arg( ) ).
      WHEN 'BACK_TO_DETAIL'.
        mv_mode = `DETAIL`.
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


  METHOD render.

    CASE mv_mode.
      WHEN `DETAIL`.
        view_detail( ).
      WHEN `LONGTEXT`.
        view_longtext( ).
      WHEN OTHERS.
        view_list( ).
    ENDCASE.

  ENDMETHOD.


  METHOD menu_entries.
    result = VALUE #( ( `Message Class` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                      ( `Environment` ) ( `System` ) ( `Help` ) ).
  ENDMETHOD.


  METHOD do_search.

    mt_classes = zcl_zlk05_sys_api=>search_message_classes( iv_pattern = mv_pattern ).
    mv_mode    = `LIST`.
    IF mt_classes IS INITIAL.
      mv_message = COND #( WHEN mv_message IS INITIAL THEN `No message classes found for the selection.`
                           ELSE mv_message ).
      mv_msgtype = `Warning`.
    ELSEIF mv_msgtype <> `Error`.
      mv_message = |{ lines( mt_classes ) } message class(es) found.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_open.

    zcl_zlk05_sys_api=>get_messages(
      EXPORTING iv_arbgb   = iv_arbgb
      IMPORTING et_head    = DATA(lt_head)
                et_msgs    = DATA(lt_msgs)
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Error`.
      RETURN.
    ENDIF.

    mv_current = to_upper( condense( iv_arbgb ) ).
    mt_head    = lt_head.
    mt_msgs    = lt_msgs.
    mv_tab     = `MSGS`.
    mv_mode    = `DETAIL`.
    mv_message = |Message class { mv_current }: { lines( mt_msgs ) } message(s).|.
    mv_msgtype = `Information`.

  ENDMETHOD.


  METHOD do_longtext.

    DATA(lv_nr) = condense( iv_msgnr ).
    IF lv_nr IS INITIAL OR NOT line_exists( mt_msgs[ msgnr = lv_nr ] ).
      RETURN.
    ENDIF.

    DATA(lt_lines) = zcl_zlk05_sys_api=>get_message_longtext( iv_arbgb = mv_current
                                                              iv_msgnr = lv_nr ).
    IF lt_lines IS INITIAL.
      mv_message = |Message { mv_current } { lv_nr } has no long text.|.
      mv_msgtype = `Information`.
      RETURN.
    ENDIF.

    mv_msgnr    = lv_nr.
    mv_longtext = |{ mt_msgs[ msgnr = lv_nr ]-text }{ cl_abap_char_utilities=>newline }{ cl_abap_char_utilities=>newline }|
               && concat_lines_of( table = lt_lines sep = cl_abap_char_utilities=>newline ).
    mv_mode     = `LONGTEXT`.

  ENDMETHOD.


  METHOD frame.

    " bands 6, 1, 2, 3 and 4 of the SAP GUI window - the same on all
    " three screens of the transaction
    mo_view = z2ui5_cl_ui5_view_builder=>factory( ).
    result  = zcl_zlk05_gui_frame=>open_window( mo_view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = result
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).
    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client io_parent  = result
                                        it_entries = menu_entries( ) ).
    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = result
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = COND #( WHEN iv_back IS INITIAL THEN client->_event_nav_app_leave( )
                                ELSE client->_event( iv_back ) ) ).
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client io_parent = result
                                         iv_title  = iv_title
                                         iv_hint   = iv_hint ).
    zcl_zlk05_gui_frame=>build_app_bar( io_parent  = result
                                       it_buttons = it_buttons ).

  ENDMETHOD.


  METHOD add_grid.

    " MSGNR opens the long text of the message, ARBGB the message class
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
          )->tag( `Label`
              )->a( n = `text` t = lv_head
      )->end(
      )->end( ).
      DATA(tmpl) = col->ele( n = `template` ns = `table` ).
      DATA(lv_event) = SWITCH string( lv_fld WHEN `ARBGB` THEN `DISPLAY`
                                             WHEN `MSGNR` THEN `LONGTEXT` ).
      IF lv_event IS NOT INITIAL.
        tmpl->tag( `Link`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `press` v = client->_event( val = lv_event arg = |$\{{ lv_fld }\}| ) ).
      ELSE.
        tmpl->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

  ENDMETHOD.


  METHOD view_list.

    DATA(page) = frame(
        iv_title   = `Message Maintenance: Initial Screen`
        iv_back    = ``
        it_buttons = VALUE #(
            ( text = `Display` icon = `sap-icon://display`
              tooltip = `Display the message class (F8)`
              press = client->_event( `EXECUTE` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change - { c_na }| )
            ( icon = `sap-icon://create` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create - { c_na }| )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete - { c_na }| )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiSmallMargin` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Message Class` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idMsgClass`
        )->a( n = `value`       v = client->_bind( mv_pattern )
        )->a( n = `placeholder` v = `message class or pattern, e.g. Z*`
        )->a( n = `width`       v = `20rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row->end( ).

    add_grid( io_parent = work
              iv_rows   = client->_bind( mt_classes )
              it_cols   = VALUE #(
                  ( `Message Class|ARBGB|14rem` )
                  ( `Short Text|STEXT|36rem` )
                  ( `Package|DEVCLASS|14rem` ) ) ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( mo_view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(page) = frame(
        iv_title   = `Display Message Class`
        iv_hint    = |Message class { mv_current }|
        iv_back    = `BACK_TO_LIST`
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Display <-> Change - { c_na }| )
            ( icon = `sap-icon://search` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Where-Used List - { c_na }| ) ) ).

    DATA(tabs) = page->ele( `IconTabBar`
        )->a( n = `selectedKey`          v = client->_bind( mv_tab )
        )->a( n = `expandable`           v = `false`
        )->a( n = `stretchContentHeight` v = `true`
        )->a( n = `height`               v = zcl_zlk05_gui_frame=>c_work_height
        )->ele( `items` ).

    DATA(c1) = tabs->ele( `IconTabFilter`
        )->a( n = `text` v = `Attributes`
        )->a( n = `key`  v = `ATTR`
        )->ele( `content` ).
    add_grid( io_parent = c1
              iv_rows   = client->_bind( mt_head )
              it_cols   = VALUE #( ( `Attribute|LABEL|12rem` ) ( `Value|VALUE|40rem` ) ) ).

    DATA(c2) = tabs->ele( `IconTabFilter`
        )->a( n = `text`  v = `Messages`
        )->a( n = `key`   v = `MSGS`
        )->a( n = `count` t = |{ lines( mt_msgs ) }|
        )->ele( `content` ).
    add_grid( io_parent = c2
              iv_rows   = client->_bind( mt_msgs )
              it_cols   = VALUE #( ( `Message|MSGNR|5rem` )
                                   ( `Message Short Text|TEXT|46rem` )
                                   ( `Self-Explanatory|SELFDEF|8rem` )
                                   ( `Long Text|LONGTEXT|6rem` ) ) ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST` ).

    client->view_display( mo_view->stringify( ) ).

  ENDMETHOD.


  METHOD view_longtext.

    DATA(page) = frame(
        iv_title   = |Long Text of Message { mv_current } { mv_msgnr }|
        iv_back    = `BACK_TO_DETAIL`
        it_buttons = VALUE #(
            ( text = `Back` icon = `sap-icon://nav-back`
              tooltip = `Back to the messages (F3)`
              press = client->_event( `BACK_TO_DETAIL` ) ) ) ).

    page->tag( `TextArea`
        )->a( n = `value`    v = client->_bind( mv_longtext )
        )->a( n = `editable` v = `false`
        )->a( n = `width`    v = `100%`
        )->a( n = `height`   v = zcl_zlk05_gui_frame=>c_work_height ).

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_DETAIL` ).

    client->view_display( mo_view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
