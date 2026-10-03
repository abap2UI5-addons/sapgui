CLASS ltcl_sm59 DEFINITION DEFERRED.
CLASS zcl_sapgui_sm59 DEFINITION LOCAL FRIENDS ltcl_sm59.

CLASS ltcl_sm59 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_sm59.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_list.

    METHODS view_is_wellformed    FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_all_columns      FOR TESTING.
    METHODS view_search_wired     FOR TESTING.
    METHODS view_no_logon_data    FOR TESTING.
    METHODS view_read_only_stated FOR TESTING.
    METHODS types_have_texts      FOR TESTING.
    METHODS option_parser         FOR TESTING.
    METHODS option_never_user     FOR TESTING.
    METHODS api_finds_none        FOR TESTING.
ENDCLASS.


CLASS ltcl_sm59 IMPLEMENTATION.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_list.
    mo_cut->init_types( ).
    mo_cut->mt_dest = VALUE #(
        ( rfcdest = `S4HCLNT100` rfctype = `3` typetext = `ABAP Connection`
          target = `s4h.example` sysnr = `00` descr = `Own system` ) ).
  ENDMETHOD.

  METHOD view_is_wellformed.
    given_list( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD view_original_title.
    given_list( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Configuration of RFC Connections*` ).
  ENDMETHOD.

  METHOD view_all_columns.
    given_list( ).
    mo_cut->view_display( ).
    LOOP AT VALUE string_table( ( `{RFCDEST}` ) ( `{RFCTYPE}` ) ( `{TYPETEXT}` )
                                ( `{TARGET}` ) ( `{SYSNR}` ) ( `{DESCR}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_search_wired.
    given_list( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `EXECUTE` ) ).
  ENDMETHOD.

  METHOD view_no_logon_data.
    " the result structure has no field for user, client or password -
    " so nothing of the logon data can ever reach the view
    DATA ls TYPE zcl_sapgui_sys_api=>ty_s_rfcdest.
    DATA(lo_struct) = CAST cl_abap_structdescr( cl_abap_typedescr=>describe_by_data( ls ) ).
    LOOP AT lo_struct->get_components( ) INTO DATA(ls_comp).
      cl_abap_unit_assert=>assert_false(
          act = xsdbool( ls_comp-name CP '*USER*' OR ls_comp-name CP '*PASS*'
                      OR ls_comp-name CP '*CLIENT*' OR ls_comp-name CP '*PWD*' )
          msg = |{ ls_comp-name } looks like logon data| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_read_only_stated.
    given_list( ).
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*logon data is never shown*` ).
  ENDMETHOD.

  METHOD types_have_texts.
    mo_cut->init_types( ).
    cl_abap_unit_assert=>assert_equals( exp = 8 act = lines( mo_cut->mt_types ) ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_types[ 1 ]-key ).
  ENDMETHOD.

  METHOD option_parser.
    cl_abap_unit_assert=>assert_equals(
        exp = `host.example`
        act = zcl_sapgui_sys_api=>rfc_option( iv_options = `H=host.example,S=00,M=100,`
                                             iv_key     = `H` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `00`
        act = zcl_sapgui_sys_api=>rfc_option( iv_options = `H=host.example,S=00,M=100,`
                                             iv_key     = `s` ) ).
    cl_abap_unit_assert=>assert_initial(
        zcl_sapgui_sys_api=>rfc_option( iv_options = `H=host.example` iv_key = `S` ) ).
  ENDMETHOD.

  METHOD option_never_user.
    " a key is only matched as a whole - "U" never returns the value of an
    " option that merely starts with U, and only what is asked for is returned
    cl_abap_unit_assert=>assert_equals(
        exp = `host`
        act = zcl_sapgui_sys_api=>rfc_option( iv_options = `U=SECRET,H=host`
                                             iv_key     = `H` ) ).
  ENDMETHOD.

  METHOD api_finds_none.
    cl_abap_unit_assert=>assert_initial(
        zcl_sapgui_sys_api=>get_rfc_destinations( iv_pattern = `ZZLK05_NO_SUCH_DEST` ) ).
  ENDMETHOD.

ENDCLASS.
