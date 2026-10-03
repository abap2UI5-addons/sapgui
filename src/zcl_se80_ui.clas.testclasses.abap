CLASS ltcl_se80_ui DEFINITION DEFERRED.
CLASS zcl_se80_ui DEFINITION LOCAL FRIENDS ltcl_se80_ui.

CLASS ltcl_se80_ui DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_se80_ui.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_object_loaded.

    " --- main view ---
    METHODS view_wellformed      FOR TESTING.
    METHODS view_single_root     FOR TESTING.
    METHODS view_fullscreen      FOR TESTING.
    METHODS toolbars_are_filled  FOR TESTING.
    METHODS back_button_wired    FOR TESTING.
    METHODS has_gui_frame        FOR TESTING.
    METHODS keys_registered      FOR TESTING.
    METHODS command_field_wired  FOR TESTING.
    METHODS app_bar_greys_out    FOR TESTING.
    METHODS message_reaches_bar  FOR TESTING.

    " --- Where-Used / Used Objects popup ---
    METHODS popup_single_root    FOR TESTING.
    METHODS popup_wellformed     FOR TESTING.
    METHODS popup_without_usages FOR TESTING.
ENDCLASS.


CLASS ltcl_se80_ui IMPLEMENTATION.

  METHOD setup.
    zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
    mo_cut->mo_api = NEW zcl_se80_api_dbl( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_object_loaded.
    mo_cut->mv_cur_package  = '$ZLK_05'.
    mo_cut->mv_cur_obj_name = 'ZCL_SE16N_A2U5'.
    mo_cut->mv_cur_obj_type = 'CLAS'.
    mo_cut->mv_object_title = `Class ZCL_SE16N_A2U5`.
    mo_cut->mv_status       = `Active`.
    mo_cut->mv_source       = |CLASS zcl_x DEFINITION PUBLIC.\nENDCLASS.|.
  ENDMETHOD.

  " ===================== main view =====================

  METHOD view_wellformed.
    given_object_loaded( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = 'the Object Navigator view is not well formed XML' ).
  ENDMETHOD.

  METHOD view_single_root.
    given_object_loaded( ).
    mo_cut->view_display( ).

    " stringify( ) always renders from the factory root - a second element
    " next to mvc:View would produce XML that UI5 cannot parse
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( ) sub = `ROOT ELEMENT` )
        msg = |expected exactly one root element, got: { mo_dbl->get_root_name( ) }| ).
  ENDMETHOD.

  METHOD view_fullscreen.
    " Full Screen On/Off hides the repository browser - both states must render
    given_object_loaded( ).
    mo_cut->mv_fullscreen = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = 'the full screen view is not well formed XML' ).
  ENDMETHOD.

  METHOD toolbars_are_filled.
    given_object_loaded( ).
    mo_cut->view_display( ).

    " Every Toolbar has to carry its buttons. An empty Toolbar means the
    " return value of open( ) was dropped and the children ended up as
    " siblings of the toolbar instead of inside it.
    cl_abap_unit_assert=>assert_equals(
        exp = 0
        act = mo_dbl->count_empty_elements( `Toolbar` )
        msg = 'a Toolbar rendered without any child - toolbar nesting is broken' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( mo_dbl->count_children( `Toolbar` ) > 0 )
        msg = 'the first Toolbar carries no child element' ).
  ENDMETHOD.

  METHOD back_button_wired.
    given_object_loaded( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " F3 / back arrow to the calling app (SAP Easy Access)
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'the Back arrow of the system function bar is not wired to leave' ).
  ENDMETHOD.

  METHOD has_gui_frame.
    " the window sits in the shared frame: original screen title and the
    " original SE80 menu bar of SAPLWB_INITIAL_TOOL
    given_object_loaded( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Object Navigator` ) ( `Workbench` ) ( `Edit` )
                                ( `Goto` ) ( `Utilities` ) ( `Environment` )
                                ( `Test` ) ( `Worklist` ) ( `System` ) ( `Help` )
                                ( `idCommandField` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.

    " the loaded object is named next to the title
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Class ZCL_SE16N_A2U5` ) >= 0 )
        msg = 'the title bar does not name the object that is loaded' ).
  ENDMETHOD.

  METHOD keys_registered.
    " the shortcut registry lives in the frontend and survives a transaction
    " switch, so every screen has to state its own binding for every key
    given_object_loaded( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } is not registered for Back| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `Ctrl+S`
                                    iv_event = `SAVE` )
        msg = 'Ctrl+S is not registered for Save' ).
  ENDMETHOD.

  METHOD command_field_wired.
    given_object_loaded( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD app_bar_greys_out.
    " Without an object loaded the object functions do not apply. The SAP GUI
    " greys them out - a handler that still fires would run against an empty
    " object name.
    CLEAR mo_cut->mv_cur_obj_name.
    mo_cut->view_display( ).

    DATA(lt_btn) = mo_cut->app_buttons( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_btn[ tooltip = `Activate` ] ) )
        msg = 'the Activate function disappeared instead of being greyed out' ).
    cl_abap_unit_assert=>assert_equals(
        exp = abap_true
        act = lt_btn[ tooltip = `Activate` ]-disabled
        msg = 'Activate is offered although no object is loaded' ).

    " Refresh works without an object and has to stay usable
    cl_abap_unit_assert=>assert_equals(
        exp = abap_false
        act = lt_btn[ tooltip = `Refresh` ]-disabled
        msg = 'Refresh was greyed out although it needs no object' ).
  ENDMETHOD.

  METHOD message_reaches_bar.
    given_object_loaded( ).
    mo_cut->mv_message  = `Object ZCL_X is locked by DEVELOPER.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Object ZCL_X is locked by DEVELOPER.` ) >= 0 )
        msg = 'the message never reaches the screen' ).
  ENDMETHOD.

  " ===================== popup =====================

  METHOD popup_single_root.
    mo_cut->mv_popup_title = `Where-Used List`.
    mo_cut->mt_usages = VALUE #( ( object = 'CLAS' obj_name = 'ZCL_CALLER' ) ).

    DATA(lv_xml) = mo_cut->build_popup( ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( lv_xml ) sub = `ROOT ELEMENT` )
        msg = |popup needs exactly one root, got: { mo_dbl->get_root_name( lv_xml ) }| ).
  ENDMETHOD.

  METHOD popup_wellformed.
    mo_cut->mv_popup_title = `Where-Used List`.
    mo_cut->mt_usages = VALUE #( ( object = 'CLAS' obj_name = 'ZCL_CALLER' )
                                 ( object = 'PROG' obj_name = 'ZREPORT' ) ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( mo_cut->build_popup( ) )
        msg = 'the Where-Used popup is not well formed XML' ).
  ENDMETHOD.

  METHOD popup_without_usages.
    " no hits: the popup shows a message strip and still has to be valid
    mo_cut->mv_popup_title = `Where-Used List`.
    CLEAR mo_cut->mt_usages.

    DATA(lv_xml) = mo_cut->build_popup( ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( lv_xml )
        msg = 'the empty Where-Used popup is not well formed XML' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = lv_xml sub = `No usage found.` ) >= 0 )
        msg = 'the empty popup does not tell the user that there are no hits' ).
  ENDMETHOD.

ENDCLASS.
