CLASS ltcl_se24_a2u5 DEFINITION DEFERRED.
CLASS zcl_se24_a2u5 DEFINITION LOCAL FRIENDS ltcl_se24_a2u5.

CLASS ltcl_se24_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_se24_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_hitlist.
    METHODS given_class_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane           FOR TESTING.
    METHODS list_original_title    FOR TESTING.
    METHODS list_selection_screen  FOR TESTING.
    METHODS list_back_nav_wired    FOR TESTING.
    METHODS list_status_bar        FOR TESTING.
    METHODS list_has_gui_frame     FOR TESTING.
    METHODS list_keys_registered   FOR TESTING.
    METHODS list_command_field     FOR TESTING.
    METHODS list_drilldown_wired   FOR TESTING.
    METHODS list_unavailable_shown FOR TESTING.
    METHODS list_empty_is_sane     FOR TESTING.
    METHODS message_reaches_view   FOR TESTING.

    METHODS detail_is_sane         FOR TESTING.
    METHODS detail_title           FOR TESTING.
    METHODS detail_title_interface FOR TESTING.
    METHODS detail_components      FOR TESTING.
    METHODS detail_object_named    FOR TESTING.
    METHODS detail_back_to_list    FOR TESTING.
    METHODS detail_f3_stays_inside FOR TESTING.
    METHODS detail_has_gui_frame   FOR TESTING.
    METHODS detail_click_wired     FOR TESTING.
    METHODS source_attribute_hint  FOR TESTING.
    METHODS source_method_to_se38  FOR TESTING.
    METHODS source_unknown_method  FOR TESTING.
ENDCLASS.


CLASS ltcl_se24_a2u5 IMPLEMENTATION.

  METHOD setup.
    zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_hitlist.
    mo_cut->mv_clsname = `ZCL_*`.
    mo_cut->mt_classes = VALUE #(
        ( clsname = `ZCL_SE11_A2U5` clstype = `Class`     descr = `ABAP Dictionary (abap2UI5)` )
        ( clsname = `ZIF_DEMO`      clstype = `Interface` descr = `Demo Interface` ) ).
  ENDMETHOD.

  METHOD given_class_detail.
    mo_cut->mv_mode       = `DETAIL`.
    mo_cut->mv_current    = `ZCL_SE11_A2U5`.
    mo_cut->mt_components = VALUE #(
        ( cmpname = `VIEW_DISPLAY` cmptype = `Method`    mtdtype = `Instance Method`
          exposure = `Protected` redefin = `` )
        ( cmpname = `MV_OBJNAME`   cmptype = `Attribute` mtdtype = ``
          exposure = `Public`    redefin = `` ) ).
  ENDMETHOD.

  METHOD assert_shell_sane.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_ctx }: view is not well formed XML| ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( ) sub = `ROOT ELEMENT` )
        msg = |{ iv_ctx }: expected exactly one root, got { mo_dbl->get_root_name( ) }| ).

    LOOP AT VALUE string_table( ( `columns` ) ( `items` ) ( `cells` )
                                ( `footer` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== initial screen =====================

  METHOD list_is_sane.
    given_hitlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SE24 initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Class Builder: Initial Screen` ) >= 0 )
        msg = 'the original SE24 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idClsName` ) >= 0 )
        msg = 'the selection screen (subHeader) is empty' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Object Type` ) >= 0 )
        msg = 'the Object Type field label is missing' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_hitlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'the Back arrow of the system function bar is not wired to leave' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_classes.
    mo_cut->view_display( ).

    assert_shell_sane( `SE24 initial screen without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `Class ZCL_UNKNOWN does not exist.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Class ZCL_UNKNOWN does not exist.` ) >= 0 )
        msg = 'the message text never reaches the selection screen' ).
  ENDMETHOD.

  " ===================== display screen =====================

  METHOD detail_is_sane.
    given_class_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SE24 class display` ).
  ENDMETHOD.

  METHOD detail_title.
    " original title CLDISPLAY: Class Builder: Display Class &
    given_class_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Class Builder: Display Class ZCL_SE11_A2U5` ) >= 0 )
        msg = 'the class display does not carry the original SE24 title' ).
  ENDMETHOD.

  METHOD detail_title_interface.
    " SE24 has a separate title for an interface (IFDISPLAY) - showing
    " "Display Class" above an interface would be plain wrong
    given_class_detail( ).
    mo_cut->mv_curtype = `Interface`.
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Class Builder: Display Interface ZCL_SE11_A2U5` ) >= 0 )
        msg = 'an interface is announced as a class' ).
  ENDMETHOD.

  METHOD detail_object_named.
    " dynpro 2000 labels the object with Class/Interface - without it the
    " component list does not say what it belongs to
    given_class_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Class/Interface` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `ZCL_SE11_A2U5` ) >= 0 )
        msg = 'the display screen does not name the object it shows' ).
  ENDMETHOD.

  METHOD detail_components.
    " the component list is the payload of the class display
    given_class_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{CMPNAME}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{EXPOSURE}` ) >= 0 )
        msg = 'the component list is not bound to the component structure' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Visibility` ) >= 0 )
        msg = 'the visibility column is missing' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_class_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the display screen has no back navigation to the initial screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the display screen leaves the app instead of returning to the list' ).
  ENDMETHOD.

  METHOD detail_f3_stays_inside.
    " F3 on a screen INSIDE the transaction has to go back one screen, not
    " leave SE24 - the frame is told the screen event for that
    given_class_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = `BACK_TO_LIST` )
          msg = |{ lv_key } does not return to the initial screen| ).
      cl_abap_unit_assert=>assert_false(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } leaves the transaction instead of the screen| ).
    ENDLOOP.
    " Shift+F3 is Exit in the SAP GUI - it leaves the transaction from
    " every one of its screens, not only one screen back
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `Shift+F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_exit )
        msg = 'Shift+F3 must leave the transaction' ).
  ENDMETHOD.

  METHOD detail_has_gui_frame.
    given_class_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `Class` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                                ( `Environment` ) ( `Back` ) ( `Previous object` )
                                ( `Next object` ) ( `Unit Tests` )
                                ( `Version Management` ) ( `Local Types` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original texts of
    " SAPLSEOD
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Class` ) ( `Edit` ) ( `Goto` ) ( `Utilities` )
                                ( `Environment` ) ( `System` ) ( `Help` )
                                ( `Object Type` ) ( `Interface` ) ( `Display` )
                                ( `Copy Class/Interface` )
                                ( `Delete Class/Interface` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_keys_registered.
    " the shortcut registry lives in the frontend and survives a transaction
    " switch, so every screen has to state its own binding for every key
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } is not registered for Back| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F8`
                                    iv_event = `EXECUTE` )
        msg = 'F8 is not registered for the Display function' ).
  ENDMETHOD.

  METHOD list_command_field.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD list_drilldown_wired.
    " the object name has to carry the row key, otherwise the drill down
    " opens the wrong class
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the component list is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `CLSNAME` )
        msg = 'the drill down does not carry the object of the row' ).
  ENDMETHOD.

  METHOD list_unavailable_shown.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled SE24 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD detail_click_wired.
    given_class_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `SOURCE|${CMPNAME}|${CMPTYPE}` ] ) )
        msg = 'a click on a component must be able to open its source' ).
  ENDMETHOD.

  METHOD source_attribute_hint.
    given_class_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `SOURCE`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `MV_OBJNAME|Attribute` ) ).
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_equals( exp = `Information` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD source_method_to_se38.
    given_class_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `SOURCE`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `VIEW_DISPLAY|Method` ) ).
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SE38_A2U5` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

  METHOD source_unknown_method.
    given_class_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `SOURCE`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `NO_SUCH_METHOD_X|Method` ) ).
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

ENDCLASS.
