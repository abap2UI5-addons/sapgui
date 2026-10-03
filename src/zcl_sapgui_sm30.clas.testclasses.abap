CLASS ltcl_sm30 DEFINITION DEFERRED.
CLASS zcl_sapgui_sm30 DEFINITION LOCAL FRIENDS ltcl_sm30.

CLASS ltcl_sm30 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_sapgui_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_sm30.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS view_is_wellformed   FOR TESTING.
    METHODS view_original_title  FOR TESTING.
    METHODS view_display_wired   FOR TESTING.
    METHODS empty_name_warns     FOR TESTING.
    METHODS unknown_table        FOR TESTING.
    METHODS structure_refused    FOR TESTING.
    METHODS table_goes_to_se16n  FOR TESTING.
ENDCLASS.


CLASS ltcl_sm30 IMPLEMENTATION.

  METHOD setup.
    mo_api = zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
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
    mo_api->answer( iv_method = `GET_TABLE_KIND` iv_key = `BAPIRET2`
                    iv_value  = zcl_sapgui_sys_api=>c_table_kind-structure ).
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
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE16N` act = mo_dbl->mv_nav_call ).
      cl_abap_unit_assert=>assert_initial( mo_cut->mv_msgtype ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
