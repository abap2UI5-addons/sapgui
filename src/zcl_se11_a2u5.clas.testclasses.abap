CLASS ltcl_se11_a2u5 DEFINITION DEFERRED.
CLASS zcl_se11_a2u5 DEFINITION LOCAL FRIENDS ltcl_se11_a2u5.

CLASS ltcl_se11_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_se11_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_hitlist.
    METHODS given_table_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    " --- initial screen (SE11 selection screen) ---
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

    " --- display screens ---
    METHODS detail_table_is_sane   FOR TESTING.
    METHODS detail_table_title     FOR TESTING.
    METHODS detail_dtel_is_sane    FOR TESTING.
    METHODS detail_object_named    FOR TESTING.
    METHODS detail_back_to_list    FOR TESTING.
    METHODS detail_f3_stays_inside FOR TESTING.
    METHODS detail_has_gui_frame   FOR TESTING.
ENDCLASS.


CLASS ltcl_se11_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_hitlist.
    mo_cut->mv_objname = `MAR*`.
    mo_cut->mv_kind    = `TABL`.
    mo_cut->mt_objects = VALUE #(
        ( name = `MARA` kind = `TABL` tabclass = `TRANSP`
          descr = `General Material Data` author = `SAP` chdate = `01.01.2020` )
        ( name = `MARC` kind = `TABL` tabclass = `TRANSP`
          descr = `Plant Data for Material` author = `SAP` chdate = `01.01.2020` ) ).
  ENDMETHOD.

  METHOD given_table_detail.
    mo_cut->mv_kind    = `TABL`.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `MARA`.
    mo_cut->mt_fields  = VALUE #(
        ( pos = `1` fieldname = `MANDT` keyflag = `X` rollname = `MANDT`
          datatype = `CLNT` leng = `3` decimals = `0` descr = `Client` )
        ( pos = `2` fieldname = `MATNR` keyflag = `X` rollname = `MATNR`
          datatype = `CHAR` leng = `40` decimals = `0` descr = `Material Number` ) ).
  ENDMETHOD.

  " Structural invariants shared by every SAP GUI look-alike view:
  " parsable XML, exactly one root element, and no container that lost its
  " children because the return value of open( ) was dropped.
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

    assert_shell_sane( `SE11 initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    " the app has to carry the original SAP GUI screen title
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `ABAP Dictionary: Initial Screen` ) >= 0 )
        msg = 'the original SE11 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    " the selection fields live in the work area of the frame, the way the
    " SE11 entry dynpro has them
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idObjName` ) >= 0 )
        msg = 'the Object Name input field is missing' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Object Name` ) >= 0 )
        msg = 'the Object Name field label is missing' ).

    " both object kinds of the SE11 entry screen must be offered
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Database Table / View` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Data Element` ) >= 0 )
        msg = 'the object kind selection does not offer TABL and DTEL' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_hitlist( ).
    mo_cut->mv_objname = `MARA`.
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " F3 / back arrow returns to the calling app (SAP Easy Access)
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'the Back arrow of the system function bar is not wired to leave' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original texts of the
    " Dictionary
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Dictionary Object` ) ( `Edit` ) ( `Goto` )
                                ( `Utilities` ) ( `Environment` ) ( `System` )
                                ( `Help` ) ( `Display` ) ( `Activate` )
                                ( `Database Utility` ) ( `Activation Log` )
                                ( `Other Dictionary Objects...` ) )
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
    " opens the wrong object
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the field list is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `NAME` )
        msg = 'the drill down does not carry the object of the row' ).
  ENDMETHOD.

  METHOD list_unavailable_shown.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled SE11 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD list_status_bar.
    " the SAP GUI status bar shows system, client and user
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0 )
        msg = 'the status bar does not show the system id' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0 )
        msg = 'the status bar does not show the client' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show the user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    " on_init renders before any search has run - the empty screen still has
    " to be a valid view, otherwise the app dies on startup
    CLEAR mo_cut->mt_objects.
    mo_cut->view_display( ).

    assert_shell_sane( `SE11 initial screen without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    " an error from the system API has to become visible on the screen
    mo_cut->mv_message = `Object MARZ does not exist.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Object MARZ does not exist.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== display screens =====================

  METHOD detail_table_is_sane.
    given_table_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SE11 table display` ).

    " the field list is the payload of the table display
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{FIELDNAME}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{ROLLNAME}` ) >= 0 )
        msg = 'the field list columns are not bound to the field structure' ).
  ENDMETHOD.

  METHOD detail_table_title.
    given_table_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Dictionary: Display Table MARA` ) >= 0 )
        msg = 'the table display does not carry the original SE11 title' ).
  ENDMETHOD.

  METHOD detail_dtel_is_sane.
    " data elements use the generic property/value list instead of a field list
    mo_cut->mv_kind    = `DTEL`.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `MATNR`.
    mo_cut->mt_detail  = VALUE #( ( label = `Short Description` value = `Material Number` )
                                  ( label = `Domain`            value = `MATNR` ) ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SE11 data element display` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Dictionary: Display Data Element MATNR` ) >= 0 )
        msg = 'the data element display does not carry the original SE11 title' ).
  ENDMETHOD.

  METHOD detail_object_named.
    " the display screen has to name the object it shows - the field list
    " alone says nothing about where it comes from
    given_table_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Database table` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `MARA` ) >= 0 )
        msg = 'the display screen does not name the table it shows' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    " from the display screen F3 must return to the initial screen, not leave
    " the app - otherwise the user loses the hit list
    given_table_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the display screen has no back navigation to the initial screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the display screen leaves the app instead of returning to the list' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `sap-icon://nav-back` ) >= 0 )
        msg = 'the Back button is missing in the application function bar' ).
  ENDMETHOD.

  METHOD detail_f3_stays_inside.
    " F3 on a screen INSIDE the transaction has to go back one screen, not
    " leave SE11 - the frame is told the screen event for that
    given_table_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
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
  ENDMETHOD.

  METHOD detail_has_gui_frame.
    given_table_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `Dictionary Object` ) ( `Edit` ) ( `Goto` )
                                ( `Utilities` ) ( `Environment` ) ( `Back` )
                                ( `Activate` ) ( `Where-Used List` )
                                ( `Object Directory Entry` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
