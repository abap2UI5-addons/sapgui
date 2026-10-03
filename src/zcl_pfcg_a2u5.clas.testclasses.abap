CLASS ltcl_pfcg_a2u5 DEFINITION DEFERRED.
CLASS zcl_pfcg_a2u5 DEFINITION LOCAL FRIENDS ltcl_pfcg_a2u5.

CLASS ltcl_pfcg_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_pfcg_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_detail.

    METHODS list_is_wellformed    FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_role_link        FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS detail_is_wellformed  FOR TESTING.
    METHODS detail_original_tabs  FOR TESTING.
    METHODS detail_roles_only_composite FOR TESTING.
    METHODS detail_jumps_wired    FOR TESTING.
    METHODS detail_back_to_list   FOR TESTING.
    METHODS called_back_leaves    FOR TESTING.
    METHODS start_param_role      FOR TESTING.
    METHODS open_unknown_role     FOR TESTING.
    METHODS user_jumps_to_su01    FOR TESTING.
    METHODS tcode_jump_is_routed  FOR TESTING.

ENDCLASS.


CLASS ltcl_pfcg_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_api = zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_detail.
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `Z_DEMO_ROLE`.
    mo_cut->mv_tab     = `DESCR`.
    mo_cut->mt_head    = VALUE #( ( label = `Role` value = `Z_DEMO_ROLE` ) ).
    mo_cut->mv_descr   = `Role for <demo> & {tests}`.
    mo_cut->mt_tcodes  = VALUE #( ( tcode = `SU01` text = `User Maintenance` ) ).
    mo_cut->mt_auth    = VALUE #( ( object = `S_TCODE` auth = `T-0001` field = `TCD` low = `SU01` ) ).
    mo_cut->mt_users   = VALUE #( ( uname = `DEVELOPER` from_dat = `01.01.2026` to_dat = `31.12.9999`
                                    validity = `Valid` state = `Success` ) ).
  ENDMETHOD.

  METHOD list_is_wellformed.
    mo_cut->mt_roles = VALUE #( ( agr_name = `SAP_BC_BASIS_ADMIN` text = `Basis <Admin>` composite = `Single` ) ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD list_original_title.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Role Maintenance*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idRoleName*` ).
  ENDMETHOD.

  METHOD list_role_link.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${AGR_NAME}` ] ) )
        msg = 'a role of the hit list must open the role' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD detail_is_wellformed.
    given_detail( ).
    mo_cut->render( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Display Roles*` ).
  ENDMETHOD.

  METHOD detail_original_tabs.
    given_detail( ).
    mo_cut->view_detail( ).
    LOOP AT VALUE string_table( ( `"Description"` ) ( `"Menu"` ) ( `"Authorizations"` ) ( `"User"` ) )
         INTO DATA(lv_tab).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_tab ) >= 0 )
          msg = |tab { lv_tab } of PFCG is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_roles_only_composite.
    given_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_equals( exp = -1 act = find( val = mo_dbl->mv_view sub = `"ROLES"` ) ).
    mo_cut->mt_single = VALUE #( ( agr_name = `Z_SINGLE` text = `Single` ) ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*"ROLES"*` ).
  ENDMETHOD.

  METHOD detail_jumps_wired.
    given_detail( ).
    mo_cut->view_detail( ).
    LOOP AT VALUE string_table( ( `DISPLAY_USER|${UNAME}` ) ( `START_TCODE|${TCODE}` ) )
         INTO DATA(lv_ev).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = lv_ev ] ) )
          msg = |event { lv_ev } is not wired| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_LIST`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_false( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD called_back_leaves.
    " started from SU01: Back returns to the user
    given_detail( ).
    mo_cut->mv_called    = abap_true.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_LIST`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD start_param_role.
    mo_cut->zif_zlk05_start_params~set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_role value = ` sap_bc_basis_admin ` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `SAP_BC_BASIS_ADMIN` act = mo_cut->mv_start_role ).
  ENDMETHOD.

  METHOD open_unknown_role.
    mo_api->answer( iv_method = `GET_ROLE_DETAIL` iv_param = `EV_MESSAGE` iv_key = `ZZ_NO_SUCH_ROLE_X`
                    iv_value  = `Role ZZ_NO_SUCH_ROLE_X does not exist` ).
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `ZZ_NO_SUCH_ROLE_X` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST`  act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD user_jumps_to_su01.
    given_detail( ).
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

  METHOD tcode_jump_is_routed.
    " a transaction of the menu that this environment does not have is
    " answered with a message - nothing is started
    given_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `START_TCODE`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `SM36` ) ).
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    cl_abap_unit_assert=>assert_equals( exp = `DETAIL` act = mo_cut->mv_mode ).
  ENDMETHOD.

ENDCLASS.
