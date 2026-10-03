CLASS ltcl_sm30_a2u5 DEFINITION DEFERRED.
CLASS zcl_sm30_a2u5 DEFINITION LOCAL FRIENDS ltcl_sm30_a2u5.

CLASS ltcl_sm30_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sm30_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS view_is_wellformed   FOR TESTING.
    METHODS view_original_title  FOR TESTING.
    METHODS view_display_wired   FOR TESTING.
    METHODS empty_name_warns     FOR TESTING.
    METHODS unknown_table        FOR TESTING.
    METHODS structure_refused    FOR TESTING.
    METHODS table_goes_to_se16n  FOR TESTING.
    METHODS kind_of_objects      FOR TESTING.
ENDCLASS.


CLASS ltcl_sm30_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD view_is_wellformed.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD view_original_title.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Maintain Table Views: Initial Screen*` ).
  ENDMETHOD.

  METHOD view_display_wired.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `DISPLAY` ) ).
  ENDMETHOD.

  METHOD empty_name_warns.
    mo_cut->do_display( ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
  ENDMETHOD.

  METHOD unknown_table.
    mo_cut->mv_table = `ZZLK05_NO_SUCH_TABLE`.
    mo_cut->do_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*does not exist*` ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
  ENDMETHOD.

  METHOD structure_refused.
    mo_cut->mv_table = `BAPIRET2`.
    mo_cut->do_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*structure*` ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
  ENDMETHOD.

  METHOD table_goes_to_se16n.
    " T000 is a table: the Data Browser takes over - or, without the
    " authorization for SE16N, the router's message is shown
    mo_cut->mv_table = `t000`.
    mo_cut->do_display( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SE16N_A2U5` act = mo_dbl->mv_nav_call ).
      cl_abap_unit_assert=>assert_initial( mo_cut->mv_msgtype ).
    ENDIF.
  ENDMETHOD.

  METHOD kind_of_objects.
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-table
                                        act = zcl_zlk05_sys_api=>get_table_kind( `T000` ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-structure
                                        act = zcl_zlk05_sys_api=>get_table_kind( `BAPIRET2` ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-none
                                        act = zcl_zlk05_sys_api=>get_table_kind( `ZZLK05_NONE` ) ).
  ENDMETHOD.

ENDCLASS.
