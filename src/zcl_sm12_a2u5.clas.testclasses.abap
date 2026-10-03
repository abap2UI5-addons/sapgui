CLASS ltcl_sm12_a2u5 DEFINITION DEFERRED.
CLASS zcl_sm12_a2u5 DEFINITION LOCAL FRIENDS ltcl_sm12_a2u5.

CLASS ltcl_sm12_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sm12_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_locklist.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane          FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_selection_screen FOR TESTING.
    METHODS list_lock_columns     FOR TESTING.
    METHODS list_original_title_2 FOR TESTING.
    METHODS sel_has_gui_frame     FOR TESTING.
    METHODS list_read_only_stated FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS list_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
    METHODS list_click_opens_user FOR TESTING.
    METHODS click_jumps_to_su01   FOR TESTING.
ENDCLASS.


CLASS ltcl_sm12_a2u5 IMPLEMENTATION.

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

  METHOD given_locklist.
    mo_cut->mt_locks = VALUE #(
        ( guname = `DEVELOPER` gclient = `100` gname = `MARA`
          garg = `100000000000001234` gmode = `E` gusecnt = `1`
          gbcktype = `` gtdate = `01.01.2024` gttime = `12:00:00` gthost = `s4h` )
        ( guname = `BATCHUSER` gclient = `100` gname = `EQUI`
          garg = `100000000000009999` gmode = `S` gusecnt = `3`
          gbcktype = `` gtdate = `01.01.2024` gttime = `12:05:00` gthost = `s4h` ) ).
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

  " ===================== lock entry list =====================

  METHOD list_is_sane.
    given_locklist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SM12 lock entry list` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_locklist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Select Lock Entries` ) >= 0 )
        msg = 'the original SM12 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    given_locklist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idLockTab` ) >= 0 )
        msg = 'the selection screen has no input field in the work area' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Table Name` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `User Name` ) >= 0 )
        msg = 'the SM12 selection fields (table / user) are missing' ).
  ENDMETHOD.

  METHOD list_lock_columns.
    " lock argument and mode are what identifies the blocking entry -
    " without them the list cannot be used to resolve a lock situation
    given_locklist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{GARG}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{GMODE}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{GUNAME}` ) >= 0 )
        msg = 'the lock list does not bind argument, mode and owner' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Lock Argument` ) >= 0 )
        msg = 'the Lock Argument column header is missing' ).
  ENDMETHOD.

  METHOD list_read_only_stated.
    " the real SM12 can delete lock entries - this app deliberately cannot.
    " The restriction has to be visible instead of silently missing.
    given_locklist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `Display only - lock entries are not deleted here` ) >= 0 )
        msg = 'the read-only restriction of the app is not stated on screen' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `this app never writes` ) >= 0 )
        msg = 'the disabled Delete button does not explain itself' ).
  ENDMETHOD.

  METHOD list_original_title_2.
    " the list screen of the original SM12 has its own title
    given_locklist( ).
    mo_cut->view_list( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Lock Entry List` ) >= 0 )
        msg = 'the original title of the SM12 list screen is missing' ).
  ENDMETHOD.

  METHOD sel_has_gui_frame.
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `List` ) ( `Edit` ) ( `Goto` ) ( `Settings` )
                                ( `System` ) ( `Help` ) ( `Lock argument` )
                                ( `Client` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_locklist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    " no lock entries at all is the normal case on an idle system
    CLEAR mo_cut->mt_locks.
    mo_cut->view_list( ).

    assert_shell_sane( `SM12 lock entry list without locks` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    " ENQUEUE_READ reports its own failures - they must not be swallowed
    mo_cut->mv_message = `Lock table overflow.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Lock table overflow.` ) >= 0 )
        msg = 'the message from the enqueue server never reaches the status bar' ).
  ENDMETHOD.

  METHOD list_click_opens_user.
    given_locklist( ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY_USER|${GUNAME}` ] ) )
        msg = 'a click on a lock entry must open its user' ).
  ENDMETHOD.

  METHOD click_jumps_to_su01.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `DISPLAY_USER`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( CONV string( sy-uname ) ) ).
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SU01_A2U5` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
