CLASS ltcl_se03 DEFINITION DEFERRED.
CLASS zcl_sapgui_se03 DEFINITION LOCAL FRIENDS ltcl_se03.

CLASS ltcl_se03 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_sapgui_se03.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.
    DATA mo_api TYPE REF TO zcl_sapgui_sys_api_dbl.

    METHODS setup.
    METHODS teardown.
    METHODS start.
    METHODS hits
      RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_object_request.

    METHODS start_is_wellformed   FOR TESTING.
    METHODS start_original_title  FOR TESTING.
    METHODS start_has_selection   FOR TESTING.
    METHODS search_needs_a_name   FOR TESTING.
    METHODS search_lists_hits     FOR TESTING.
    METHODS search_without_hits   FOR TESTING.
    METHODS list_links_requests   FOR TESTING.
    METHODS display_opens_se09    FOR TESTING.
    METHODS display_refused       FOR TESTING.
    METHODS se01_and_se03_routed  FOR TESTING.
ENDCLASS.


CLASS ltcl_se03 IMPLEMENTATION.

  METHOD setup.
    mo_api = zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD start.
    mo_dbl->mv_on_init = abap_true.
    CAST z2ui5_if_app( mo_cut )->main( mo_dbl ).
    mo_dbl->mv_on_init = abap_false.
  ENDMETHOD.

  METHOD hits.
    result = VALUE #(
        ( trkorr = `A4HK900123` strkorr = `A4HK900122` functxt = `Development/Correction`
          statustxt = `Modifiable` as4user = `DEVELOPER` as4date = `03.10.2026`
          as4text = `SAP GUI apps` pgmid = `R3TR` object = `CLAS` obj_name = `ZCL_SAPGUI_SE03` )
        ( trkorr = `A4HK900122` functxt = `Workbench Request`
          statustxt = `Modifiable` as4user = `DEVELOPER` as4date = `03.10.2026`
          as4text = `SAP GUI apps` pgmid = `R3TR` object = `CLAS` obj_name = `ZCL_SAPGUI_SE03` ) ).
  ENDMETHOD.

  METHOD start_is_wellformed.
    start( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->get_root_name( ) exp = `*View` ).
  ENDMETHOD.

  METHOD start_original_title.
    start( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Search for Objects in Requests/Tasks*` ).
  ENDMETHOD.

  METHOD start_has_selection.
    start( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idSe03Object*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idSe03ObjName*` ).
  ENDMETHOD.

  METHOD search_needs_a_name.
    start( ).
    mo_cut->mv_obj_name = `  `.
    mo_cut->do_search( ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
    cl_abap_unit_assert=>assert_false( mo_api->was_called( `SEARCH_OBJECT_IN_REQUESTS` ) ).
  ENDMETHOD.

  METHOD search_lists_hits.
    mo_api->answer( iv_method = `SEARCH_OBJECT_IN_REQUESTS` iv_value = hits( ) ).
    start( ).
    mo_cut->mv_object   = `CLAS`.
    mo_cut->mv_obj_name = `ZCL_SAPGUI_SE03`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `EXECUTE`.
    CAST z2ui5_if_app( mo_cut )->main( mo_dbl ).

    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( mo_cut->mt_hits ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Information` act = mo_cut->mv_msgtype ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*2 entry/entries found*` ).
  ENDMETHOD.

  METHOD search_without_hits.
    start( ).
    mo_cut->mv_obj_name = `ZZ_NOTHING*`.
    mo_cut->do_search( ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mt_hits ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD list_links_requests.
    mo_cut->mt_hits = hits( ).
    start( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*<Link text="{TRKORR}"*` ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${TRKORR}` ] ) ) ).
  ENDMETHOD.

  METHOD display_opens_se09.
    start( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `DISPLAY`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `A4HK900123` ) ).
    CAST z2ui5_if_app( mo_cut )->main( mo_dbl ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE09` act = mo_dbl->mv_nav_call ).
  ENDMETHOD.

  METHOD display_refused.
    " without S_TCODE for SE09 the jump stays here, with the reason
    zcl_sapgui_auth_sys_dbl=>install( )->deny( `S_TCODE` ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `DISPLAY`.
    mo_dbl->ms_get-t_event_arg = VALUE #( ( `A4HK900123` ) ).
    mo_cut->client = mo_dbl.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
  ENDMETHOD.

  METHOD se01_and_se03_routed.
    DATA(lt_apps) = zcl_sapgui_router=>get_apps( ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE03`
                                        act = lt_apps[ tcode = `SE03` ]-class ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE09`
                                        act = lt_apps[ tcode = `SE01` ]-class ).
  ENDMETHOD.

ENDCLASS.
