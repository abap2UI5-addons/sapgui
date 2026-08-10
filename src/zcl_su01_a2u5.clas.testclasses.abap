CLASS ltcl_su01_a2u5 DEFINITION DEFERRED.
CLASS zcl_su01_a2u5 DEFINITION LOCAL FRIENDS ltcl_su01_a2u5.

CLASS ltcl_su01_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_su01_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_userlist.
    METHODS given_role_list.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane          FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_selection_screen FOR TESTING.
    METHODS list_lock_state       FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS list_status_bar       FOR TESTING.
    METHODS list_has_gui_frame    FOR TESTING.
    METHODS list_keys_registered  FOR TESTING.
    METHODS list_command_field    FOR TESTING.
    METHODS list_drilldown_wired  FOR TESTING.
    METHODS list_unavailable_shown FOR TESTING.
    METHODS list_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.

    METHODS roles_is_sane         FOR TESTING.
    METHODS roles_title           FOR TESTING.
    METHODS roles_validity        FOR TESTING.
    METHODS roles_without_roles   FOR TESTING.
    METHODS roles_back_to_list    FOR TESTING.
    METHODS roles_f3_stays_inside FOR TESTING.
    METHODS roles_has_gui_frame   FOR TESTING.
ENDCLASS.


CLASS ltcl_su01_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_userlist.
    mo_cut->mv_pattern = `*`.
    mo_cut->mt_users = VALUE #(
        ( bname = `DEVELOPER` fullname = `Dev Eloper` ustyp = `A`
          ustyptxt = `Dialog` lockstate = `` validfrom = `01.01.2020`
          validto = `31.12.9999` lastlogon = `01.01.2024` createdby = `SAP*` )
        ( bname = `LOCKEDUSER` fullname = `Locked User` ustyp = `A`
          ustyptxt = `Dialog` lockstate = `Locked` validfrom = `01.01.2020`
          validto = `31.12.9999` lastlogon = `` createdby = `SAP*` ) ).
  ENDMETHOD.

  METHOD given_role_list.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `DEVELOPER`.
    mo_cut->mt_roles   = VALUE #(
        ( agr_name = `SAP_ALL_DISPLAY` from_dat = `01.01.2020` to_dat = `31.12.9999` )
        ( agr_name = `Z_DEVELOPER`     from_dat = `01.01.2024` to_dat = `31.12.2024` ) ).
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

  " ===================== user list =====================

  METHOD list_is_sane.
    given_userlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SU01 initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `User Maintenance: Initial Screen` ) >= 0 )
        msg = 'the original SU01 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    " the initial screen of SU01 asks for one thing: the user name. The field
    " now lives in the work area of the frame, not in a subHeader.
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idUserName` ) >= 0 )
        msg = 'the User input field is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `User` ) >= 0 )
        msg = 'the User field label is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `EXECUTE` )
        msg = 'the selection is not wired to the EXECUTE event' ).
  ENDMETHOD.

  METHOD list_lock_state.
    " a locked user must be recognisable in the list - this is the single most
    " important field when an admin looks a user up
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{LOCKSTATE}` ) >= 0 )
        msg = 'the lock status is not bound' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Lock Status` ) >= 0 )
        msg = 'the Lock Status column header is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{USTYPTXT}` ) >= 0 )
        msg = 'the user type is shown as a raw code instead of its text' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_userlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original texts of
    " SAPLSUID_MAINTENANCE
    given_userlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `User` ) ( `Edit` ) ( `Goto` ) ( `Information` )
                                ( `Environment` ) ( `System` ) ( `Help` )
                                ( `Display` ) ( `Create User` ) ( `Change Password` )
                                ( `Mass Changes` ) ( `Information System` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_keys_registered.
    " the shortcut registry lives in the frontend and survives a transaction
    " switch, so every screen has to state its own binding for every key
    given_userlist( ).
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
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD list_drilldown_wired.
    " the user name has to carry the row key, otherwise the drill down into
    " the roles opens the wrong user
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the role assignment is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `BNAME` )
        msg = 'the drill down does not carry the user of the row' ).
  ENDMETHOD.

  METHOD list_unavailable_shown.
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled SU01 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_userlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_users.
    mo_cut->view_display( ).

    assert_shell_sane( `SU01 initial screen without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `User ZUNKNOWN does not exist.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `User ZUNKNOWN does not exist.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== role assignment =====================

  METHOD roles_is_sane.
    given_role_list( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SU01 role list` ).
  ENDMETHOD.

  METHOD roles_title.
    " the original title of the SU01 display screen is "Display Users"
    " (RSMPTEXTS, SAPLSUID_MAINTENANCE / MAIND) - the user and the tab are
    " named next to it in the title bar
    given_role_list( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Display Users` ) >= 0 )
        msg = 'the original SU01 display screen title is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `User DEVELOPER - Roles` ) >= 0 )
        msg = 'the role list does not name the user in the title bar' ).
  ENDMETHOD.

  METHOD roles_validity.
    " a role assignment without its validity period is worthless - an expired
    " role must be distinguishable from an active one
    given_role_list( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{AGR_NAME}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{FROM_DAT}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{TO_DAT}` ) >= 0 )
        msg = 'the role list does not bind role name and validity' ).
  ENDMETHOD.

  METHOD roles_without_roles.
    " a user without any role assignment still has to render a valid screen
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `NOROLES`.
    CLEAR mo_cut->mt_roles.
    mo_cut->view_detail( ).

    assert_shell_sane( `SU01 role list without roles` ).
  ENDMETHOD.

  METHOD roles_back_to_list.
    given_role_list( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the role list has no back navigation to the initial screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the role list leaves the app instead of returning to the user list' ).
  ENDMETHOD.

  METHOD roles_f3_stays_inside.
    " F3 on a screen INSIDE the transaction has to go back one screen, not
    " leave SU01 - the frame is told the screen event for that
    given_role_list( ).
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

  METHOD roles_has_gui_frame.
    given_role_list( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `User` ) ( `Edit` ) ( `Goto` ) ( `Information` )
                                ( `Environment` ) ( `Back` ) ( `Details` )
                                ( `References` ) ( `System-Dependent Data` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
