*"* use this source file for your ABAP unit test classes

" Every AUTHORITY-CHECK of ZCL_ZLK05_AUTH asks fake_subrc( ) first. The
" tests decide the sy-subrc of the check with fake( ), so they do not
" depend on the roles of the user who runs them.

CLASS ltcl_auth DEFINITION DEFERRED.
CLASS zcl_zlk05_auth DEFINITION LOCAL FRIENDS ltcl_auth.

CLASS ltcl_auth DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS teardown.

    "! The check iv_seam answers iv_subrc instead of asking the system
    METHODS fake
      IMPORTING iv_seam  TYPE string
                iv_subrc TYPE i.

    " ----- S_TCODE -----
    METHODS tcode_allowed          FOR TESTING.
    METHODS tcode_denied           FOR TESTING.
    METHODS tcode_empty_denied     FOR TESTING.

    " ----- basic checks -----
    METHODS workbench_needs_develop FOR TESTING.
    METHODS sm21_needs_admi_fcd     FOR TESTING.
    METHODS tcode_denied_skips_base FOR TESTING.

    " ----- app level -----
    METHODS app_entry_always_ok     FOR TESTING.
    METHODS app_unknown_denied      FOR TESTING.
    METHODS app_maps_to_tcodes      FOR TESTING.
    METHODS every_app_is_mapped     FOR TESTING.

    " ----- table level -----
    METHODS table_by_group          FOR TESTING.
    METHODS table_by_name           FOR TESTING.
    METHODS table_denied            FOR TESTING.

    " ----- guard -----
    METHODS guard_allows            FOR TESTING.
    METHODS guard_renders_denied    FOR TESTING.
    METHODS guard_back_leaves       FOR TESTING.

    METHODS class_name_strips_prefix FOR TESTING.
    METHODS user_group_denied        FOR TESTING.
    METHODS appl_log_denied          FOR TESTING.
    METHODS rfc_dest_denied          FOR TESTING.
    METHODS new_tcodes_need_base     FOR TESTING.
    METHODS program_of_class_pool    FOR TESTING.
    METHODS program_of_function_grp  FOR TESTING.
    METHODS program_plain            FOR TESTING.
    METHODS job_log_own_always       FOR TESTING.
    METHODS job_log_foreign_denied   FOR TESTING.
    METHODS pfcg_idoc_need_base      FOR TESTING.
    METHODS se91_needs_develop       FOR TESTING.
    METHODS role_denied              FOR TESTING.
    METHODS idoc_denied              FOR TESTING.
    METHODS spool_denied             FOR TESTING.
    METHODS message_class_denied     FOR TESTING.

ENDCLASS.


CLASS ltcl_auth IMPLEMENTATION.

  METHOD setup.
    mo_dbl = NEW #( ).
    CLEAR zcl_zlk05_auth=>gt_fake.
  ENDMETHOD.

  METHOD teardown.
    CLEAR zcl_zlk05_auth=>gt_fake.
  ENDMETHOD.

  METHOD fake.
    INSERT VALUE #( seam = iv_seam subrc = iv_subrc ) INTO TABLE zcl_zlk05_auth=>gt_fake.
  ENDMETHOD.

  METHOD tcode_allowed.
    fake( iv_seam = `auth_tcode` iv_subrc = 0 ).

    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_tcode( `SE38` )-allowed ).
  ENDMETHOD.

  METHOD tcode_denied.
    fake( iv_seam = `auth_tcode` iv_subrc = 12 ).

    DATA(ls) = zcl_zlk05_auth=>check_tcode( `se38` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*SE38*` ).
  ENDMETHOD.

  METHOD tcode_empty_denied.
    cl_abap_unit_assert=>assert_false(
        zcl_zlk05_auth=>check_tcode( `  ` )-allowed ).
  ENDMETHOD.

  METHOD workbench_needs_develop.
    fake( iv_seam = `auth_develop_generic` iv_subrc = 4 ).

    LOOP AT VALUE string_table( ( `SE80` ) ( `SE38` ) ( `SE11` ) ( `SE24` ) ( `SE37` ) ( `SE93` ) )
         INTO DATA(lv_tcode).
      DATA(ls) = zcl_zlk05_auth=>check_tcode_base( lv_tcode ).
      cl_abap_unit_assert=>assert_false( act = ls-allowed
                                         msg = |{ lv_tcode } must ask for S_DEVELOP| ).
      cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*S_DEVELOP*` ).
    ENDLOOP.
  ENDMETHOD.

  METHOD sm21_needs_admi_fcd.
    fake( iv_seam = `auth_base_sm21` iv_subrc = 4 ).

    DATA(ls) = zcl_zlk05_auth=>check_tcode_base( `SM21` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*S_ADMI_FCD*` ).
  ENDMETHOD.

  METHOD tcode_denied_skips_base.
    fake( iv_seam = `auth_tcode` iv_subrc = 4 ).
    fake( iv_seam = `auth_develop_generic` iv_subrc = 0 ).

    DATA(ls) = zcl_zlk05_auth=>check_transaction( `SE38` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*transaction SE38*` ).
  ENDMETHOD.

  METHOD app_entry_always_ok.
    fake( iv_seam = `auth_tcode` iv_subrc = 4 ).

    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_app( zcl_zlk05_auth=>c_entry_class )-allowed ).
  ENDMETHOD.

  METHOD app_unknown_denied.
    fake( iv_seam = `auth_tcode` iv_subrc = 0 ).

    DATA(ls) = zcl_zlk05_auth=>check_app( `ZCL_NOT_AN_APP_OF_ZLK05` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*not registered*` ).
  ENDMETHOD.

  METHOD app_maps_to_tcodes.
    " SE09 and SE10 both run ZCL_SE09_A2U5
    DATA(lt) = zcl_zlk05_auth=>get_tcodes_of_class( `zcl_se09_a2u5` ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt[ table_line = `SE09` ] ) ) ).
    cl_abap_unit_assert=>assert_true( xsdbool( line_exists( lt[ table_line = `SE10` ] ) ) ).
  ENDMETHOD.

  METHOD every_app_is_mapped.
    " every app the router can start must be reachable through check_app,
    " otherwise its own guard would lock everybody out
    fake( iv_seam = `auth_tcode` iv_subrc = 0 ).
    fake( iv_seam = `auth_develop_generic` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_sm21` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_rzl` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_user` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_transport` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_slg1` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_sm59` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_pfcg` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_idoc` iv_subrc = 0 ).

    LOOP AT zcl_zlk05_tcode_router=>get_apps( ) INTO DATA(ls_app) WHERE class IS NOT INITIAL.
      cl_abap_unit_assert=>assert_true(
          act = zcl_zlk05_auth=>check_app( ls_app-class )-allowed
          msg = |{ ls_app-class } is refused although all checks pass| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD table_by_group.
    fake( iv_seam = `auth_tabu_dis` iv_subrc = 0 ).
    fake( iv_seam = `auth_tabu_nam` iv_subrc = 4 ).

    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_table_display( `T000` )-allowed ).
  ENDMETHOD.

  METHOD table_by_name.
    fake( iv_seam = `auth_tabu_dis` iv_subrc = 4 ).
    fake( iv_seam = `auth_tabu_nam` iv_subrc = 0 ).

    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_table_display( `T000` )-allowed ).
  ENDMETHOD.

  METHOD table_denied.
    fake( iv_seam = `auth_tabu_dis` iv_subrc = 4 ).
    fake( iv_seam = `auth_tabu_nam` iv_subrc = 4 ).

    DATA(ls) = zcl_zlk05_auth=>check_table_display( `usr02` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*USR02*` ).
  ENDMETHOD.

  METHOD guard_allows.
    fake( iv_seam = `auth_tcode` iv_subrc = 0 ).
    fake( iv_seam = `auth_base_sm21` iv_subrc = 0 ).

    mo_dbl->mv_on_init = abap_true.
    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>guard_app( io_client = mo_dbl io_app = NEW zcl_sm21_a2u5( ) ) ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_view ).
  ENDMETHOD.

  METHOD guard_renders_denied.
    fake( iv_seam = `auth_tcode` iv_subrc = 4 ).

    mo_dbl->mv_on_init = abap_true.
    cl_abap_unit_assert=>assert_false(
        zcl_zlk05_auth=>guard_app( io_client = mo_dbl io_app = NEW zcl_sm21_a2u5( ) ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*No Authorization*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*SM21*` ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( mo_dbl->mv_view ) ).
    cl_abap_unit_assert=>assert_false( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD guard_back_leaves.
    fake( iv_seam = `auth_tcode` iv_subrc = 4 ).

    mo_dbl->mv_on_init  = abap_false.
    mo_dbl->mv_on_event = abap_true.
    mo_dbl->ms_get-event = zcl_zlk05_gui_frame=>c_ev_back.
    cl_abap_unit_assert=>assert_false(
        zcl_zlk05_auth=>guard_app( io_client = mo_dbl io_app = NEW zcl_sm21_a2u5( ) ) ).
    cl_abap_unit_assert=>assert_true( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD user_group_denied.
    fake( iv_seam = `auth_user_group` iv_subrc = 4 ).

    DATA(ls) = zcl_zlk05_auth=>check_user_group( `super` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*SUPER*` ).
  ENDMETHOD.

  METHOD appl_log_denied.
    fake( iv_seam = `auth_appl_log` iv_subrc = 4 ).

    DATA(ls) = zcl_zlk05_auth=>check_appl_log( iv_object = `bc_test` iv_subobject = `sub` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*BC_TEST*` ).
  ENDMETHOD.

  METHOD rfc_dest_denied.
    fake( iv_seam = `auth_rfc_dest` iv_subrc = 4 ).

    DATA(ls) = zcl_zlk05_auth=>check_rfc_dest( iv_rfctype = `3` iv_rfcdest = `none` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*NONE*` ).
  ENDMETHOD.

  METHOD new_tcodes_need_base.
    " SLG1 / SM59 / SM04 ask for the objects of their originals
    fake( iv_seam = `auth_base_slg1` iv_subrc = 4 ).
    fake( iv_seam = `auth_base_sm59` iv_subrc = 4 ).
    fake( iv_seam = `auth_base_rzl` iv_subrc = 4 ).

    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_tcode_base( `SLG1` )-message exp = `*S_APPL_LOG*` ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_tcode_base( `SM59` )-message exp = `*S_RFC_ADM*` ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_tcode_base( `SM04` )-message exp = `*S_RZL_ADM*` ).
  ENDMETHOD.

  METHOD program_of_class_pool.
    " a class pool is checked as the class it belongs to
    fake( iv_seam = `auth_develop_object` iv_subrc = 4 ).
    DATA(lv_pool) = CONV string( cl_oo_classname_service=>get_classpool_name( 'ZCL_ZLK05_AUTH' ) ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_program_display( lv_pool )-message
        exp = `*CLAS ZCL_ZLK05_AUTH*` ).
  ENDMETHOD.

  METHOD program_of_function_grp.
    fake( iv_seam = `auth_develop_object` iv_subrc = 4 ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_program_display( `SAPLTHFB` )-message
        exp = `*FUGR THFB*` ).
  ENDMETHOD.

  METHOD program_plain.
    fake( iv_seam = `auth_develop_object` iv_subrc = 0 ).
    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_program_display( `RSPARAM` )-allowed ).
    cl_abap_unit_assert=>assert_false(
        zcl_zlk05_auth=>check_program_display( `` )-allowed ).
  ENDMETHOD.

  METHOD job_log_own_always.
    fake( iv_seam = `auth_job_prot` iv_subrc = 4 ).
    cl_abap_unit_assert=>assert_true(
        zcl_zlk05_auth=>check_job_log( CONV string( sy-uname ) )-allowed ).
  ENDMETHOD.

  METHOD job_log_foreign_denied.
    fake( iv_seam = `auth_job_prot` iv_subrc = 4 ).
    DATA(ls) = zcl_zlk05_auth=>check_job_log( `ZZLK05_SOMEBODY` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*ZZLK05_SOMEBODY*` ).
  ENDMETHOD.

  METHOD class_name_strips_prefix.
    cl_abap_unit_assert=>assert_equals(
        exp = `ZCL_SM21_A2U5`
        act = zcl_zlk05_auth=>class_name_of( NEW zcl_sm21_a2u5( ) ) ).
  ENDMETHOD.

  METHOD pfcg_idoc_need_base.
    fake( iv_seam = `auth_base_pfcg` iv_subrc = 4 ).
    fake( iv_seam = `auth_base_idoc` iv_subrc = 4 ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_tcode_base( `PFCG` )-message exp = `*S_USER_AGR*` ).
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_auth=>check_tcode_base( `WE02` )-message exp = `*S_IDOCMONI*` ).
    cl_abap_unit_assert=>assert_false( zcl_zlk05_auth=>check_tcode_base( `WE05` )-allowed ).
  ENDMETHOD.

  METHOD se91_needs_develop.
    fake( iv_seam = `auth_develop_generic` iv_subrc = 4 ).
    cl_abap_unit_assert=>assert_false( zcl_zlk05_auth=>check_tcode_base( `SE91` )-allowed ).
  ENDMETHOD.

  METHOD role_denied.
    fake( iv_seam = `auth_role` iv_subrc = 4 ).
    DATA(ls) = zcl_zlk05_auth=>check_role( ` sap_all ` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*SAP_ALL*` ).
  ENDMETHOD.

  METHOD idoc_denied.
    fake( iv_seam = `auth_idoc` iv_subrc = 4 ).
    DATA(ls) = zcl_zlk05_auth=>check_idoc( VALUE #( docnum = '0000000000056036' direct = '2'
                                                    mestyp = 'SEQJIT' sndprt = 'KU' sndprn = '0017154801' ) ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*SEQJIT*` ).
  ENDMETHOD.

  METHOD spool_denied.
    fake( iv_seam = `auth_spool` iv_subrc = 1 ).
    DATA(ls) = zcl_zlk05_auth=>check_spool( is_tsp01  = VALUE #( rqident = 4711 rqowner = 'SOMEONE' rqclient = sy-mandt )
                                            iv_access = `DISP` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*4711*` ).
  ENDMETHOD.

  METHOD message_class_denied.
    fake( iv_seam = `auth_develop_object` iv_subrc = 4 ).
    DATA(ls) = zcl_zlk05_auth=>check_message_class( `zlk05` ).
    cl_abap_unit_assert=>assert_false( ls-allowed ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-message exp = `*MSAG*` ).
  ENDMETHOD.

ENDCLASS.
