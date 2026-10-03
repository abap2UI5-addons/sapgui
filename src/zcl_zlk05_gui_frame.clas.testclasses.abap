*"* use this source file for your ABAP unit test classes

CLASS ltcl_frame DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.

    " ----- function keys -----
    METHODS keys_back_default    FOR TESTING.
    METHODS keys_back_own_event  FOR TESTING.
    METHODS keys_no_back         FOR TESTING.
    METHODS keys_execute_save    FOR TESTING.

    " ----- frame events -----
    METHODS event_back_leaves    FOR TESTING.
    METHODS event_command_starts FOR TESTING.
    METHODS event_command_unknwn FOR TESTING.
    METHODS event_foreign        FOR TESTING.

    " ----- command field in the system function bar -----
    METHODS bar_command_active   FOR TESTING.
    METHODS bar_command_disabled FOR TESTING.

    " ----- application function bar -----
    METHODS bar_app_disabled     FOR TESTING.

    METHODS system_bar_xml
      IMPORTING iv_with_command TYPE abap_bool
      RETURNING VALUE(result)   TYPE string.

    METHODS app_bar_xml
      IMPORTING it_buttons    TYPE zcl_zlk05_gui_frame=>ty_t_button
      RETURNING VALUE(result) TYPE string.

ENDCLASS.


CLASS ltcl_frame IMPLEMENTATION.

  METHOD setup.
    mo_dbl = NEW #( ).
  ENDMETHOD.

  METHOD keys_back_default.

    zcl_zlk05_gui_frame=>register_keys( mo_dbl ).

    " F3, Shift+F3 and F12 all leave the screen, exactly like in the GUI
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_back )
        msg = `F3 was not registered` ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `Shift+F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_back )
        msg = `Shift+F3 was not registered` ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F12`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_back )
        msg = `F12 was not registered` ).

  ENDMETHOD.

  METHOD keys_back_own_event.

    " a screen inside a transaction goes back one screen, not out of it
    zcl_zlk05_gui_frame=>register_keys( io_client    = mo_dbl
                                        iv_back_name = `BACK_TO_SEL` ).

    cl_abap_unit_assert=>assert_true(
        mo_dbl->has_shortcut( iv_keys = `F3` iv_event = `BACK_TO_SEL` ) ).
    cl_abap_unit_assert=>assert_false(
        mo_dbl->has_shortcut( iv_keys  = `F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_back ) ).

  ENDMETHOD.

  METHOD keys_no_back.

    " The entry screen of the session has nowhere to go back to. It must
    " still SEND the three combinations - with an empty event name, which
    " unregisters them in the frontend. Staying silent would leave the Back
    " key of the transaction that was left last armed on the entry screen.
    zcl_zlk05_gui_frame=>register_keys( io_client    = mo_dbl
                                        iv_back_name = `` ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F3`
                                    iv_event = `` )
        msg = `F3 was not unregistered on the entry screen` ).
    cl_abap_unit_assert=>assert_false(
        act = mo_dbl->has_shortcut( iv_keys  = `F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_back )
        msg = `the entry screen must not arm the Back event` ).

  ENDMETHOD.

  METHOD keys_execute_save.

    zcl_zlk05_gui_frame=>register_keys( io_client    = mo_dbl
                                        iv_exec_name = `EXECUTE`
                                        iv_save_name = `SAVE` ).

    cl_abap_unit_assert=>assert_true(
        mo_dbl->has_shortcut( iv_keys = `F8` iv_event = `EXECUTE` ) ).
    cl_abap_unit_assert=>assert_true(
        mo_dbl->has_shortcut( iv_keys = `Ctrl+S` iv_event = `SAVE` ) ).

  ENDMETHOD.

  METHOD event_back_leaves.

    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client = mo_dbl
        iv_event  = zcl_zlk05_gui_frame=>c_ev_back ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_gui_frame=>c_navigated
                                        act = ls_frame-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = abap_true
                                        act = mo_dbl->mv_nav_leave ).

  ENDMETHOD.

  METHOD event_command_starts.

    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = mo_dbl
        iv_event   = zcl_zlk05_gui_frame=>c_ev_command
        iv_command = `/nsm37` ).

    " inside a transaction /n REPLACES the running one, as in the SAP GUI
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_gui_frame=>c_navigated
                                        act = ls_frame-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SM37_A2U5`
                                        act = mo_dbl->mv_nav_replace ).
    cl_abap_unit_assert=>assert_initial( act = mo_dbl->mv_nav_call
                                         msg = '/n must not stack the new transaction' ).

    " from the root of the session it is started on top of the root
    mo_dbl->reset( ).
    ls_frame = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = mo_dbl
        iv_event   = zcl_zlk05_gui_frame=>c_ev_command
        iv_command = `/nsm37`
        iv_root    = abap_true ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SM37_A2U5`
                                        act = mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_initial( act = mo_dbl->mv_nav_replace ).

  ENDMETHOD.

  METHOD event_command_unknwn.

    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = mo_dbl
        iv_event   = zcl_zlk05_gui_frame=>c_ev_command
        iv_command = `ZZ_NO_SUCH_TCODE` ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_gui_frame=>c_message
                                        act = ls_frame-outcome ).
    cl_abap_unit_assert=>assert_not_initial( ls_frame-message ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = ls_frame-msg_type ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).

  ENDMETHOD.

  METHOD event_foreign.

    " an event of the screen itself must pass through untouched
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client = mo_dbl
        iv_event  = `EXECUTE` ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_gui_frame=>c_not_handled
                                        act = ls_frame-outcome ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_leave ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).

  ENDMETHOD.

  METHOD system_bar_xml.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    IF iv_with_command = abap_true.
      zcl_zlk05_gui_frame=>build_system_bar(
          io_parent    = page
          iv_cmd_value = mo_dbl->z2ui5_if_client~_bind( `` )
          iv_cmd_event = mo_dbl->z2ui5_if_client~_event(
                             zcl_zlk05_gui_frame=>c_ev_command ) ).
    ELSE.
      zcl_zlk05_gui_frame=>build_system_bar( page ).
    ENDIF.

    result = view->stringify( ).

  ENDMETHOD.

  METHOD bar_command_active.

    DATA(lv_xml) = system_bar_xml( abap_true ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( lv_xml )
        msg = `the system function bar is not well formed` ).
    cl_abap_unit_assert=>assert_char_cp(
        act = lv_xml exp = `*idCommandField*`
        msg = `the command field is missing` ).
    cl_abap_unit_assert=>assert_char_cp(
        act = lv_xml exp = `*submit*`
        msg = `Enter does not trigger the command field` ).

  ENDMETHOD.

  METHOD bar_command_disabled.

    DATA(lv_xml) = system_bar_xml( abap_false ).

    cl_abap_unit_assert=>assert_char_cp(
        act = lv_xml exp = `*enabled="false"*`
        msg = `without an event the command field must stay disabled` ).

  ENDMETHOD.

  METHOD app_bar_xml.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_app_bar( io_parent  = page
                                       it_buttons = it_buttons ).

    result = view->stringify( ).

  ENDMETHOD.

  METHOD bar_app_disabled.

    " The SAP GUI greys a function out while it does not apply instead of
    " hiding it. A greyed out entry must not keep its handler, otherwise the
    " user can still trigger it - that is what DISABLED is for.
    DATA(lv_xml) = app_bar_xml( VALUE #(
        ( text = `Save` icon = `sap-icon://save` press = `EV_SAVE`
          disabled = abap_true )
        ( icon = `sap-icon://activate` press = `EV_ACT` disabled = abap_true )
        ( text = `Check` icon = `sap-icon://syntax` press = `EV_CHECK` ) ) ).

    cl_abap_unit_assert=>assert_char_cp(
        act = lv_xml exp = `*enabled="false"*`
        msg = `a disabled button is not rendered as disabled` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = lv_xml sub = `EV_SAVE` )
        msg = `a disabled button still carries its handler` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = lv_xml sub = `EV_ACT` )
        msg = `a disabled icon still carries its handler` ).

    " the entry that stays enabled keeps its handler
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = lv_xml sub = `EV_CHECK` ) >= 0 )
        msg = `an enabled button lost its handler` ).

  ENDMETHOD.

ENDCLASS.
