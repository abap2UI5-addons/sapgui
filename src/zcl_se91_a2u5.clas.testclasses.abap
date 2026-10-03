CLASS ltcl_se91_a2u5 DEFINITION DEFERRED.
CLASS zcl_se91_a2u5 DEFINITION LOCAL FRIENDS ltcl_se91_a2u5.

CLASS ltcl_se91_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_se91_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_detail.

    METHODS list_is_wellformed    FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_class_link       FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS detail_is_wellformed  FOR TESTING.
    METHODS detail_tabs           FOR TESTING.
    METHODS detail_longtext_link  FOR TESTING.
    METHODS longtext_is_wellformed FOR TESTING.
    METHODS longtext_back_to_detail FOR TESTING.
    METHODS execute_opens_class   FOR TESTING.
    METHODS execute_unknown_class FOR TESTING.
    METHODS longtext_missing      FOR TESTING.
    METHODS start_param_class     FOR TESTING.

ENDCLASS.


CLASS ltcl_se91_a2u5 IMPLEMENTATION.

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
    mo_cut->mv_current = `ZLK05`.
    mo_cut->mv_tab     = `MSGS`.
    mo_cut->mt_head    = VALUE #( ( label = `Message class` value = `ZLK05` ) ).
    mo_cut->mt_msgs    = VALUE #( ( msgnr = `001` text = `No authorization for transaction &1 <x> {y}` )
                                  ( msgnr = `002` text = `Second` longtext = `Yes` ) ).
  ENDMETHOD.

  METHOD list_is_wellformed.
    mo_cut->mt_classes = VALUE #( ( arbgb = `ZLK05` stext = `SAP GUI <look-alike>` devclass = `$ZLK_05` ) ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD list_original_title.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view
                                         exp = `*Message Maintenance: Initial Screen*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*idMsgClass*` ).
  ENDMETHOD.

  METHOD list_class_link.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${ARBGB}` ] ) ) ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD detail_is_wellformed.
    given_detail( ).
    mo_cut->render( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Display Message Class*` ).
  ENDMETHOD.

  METHOD detail_tabs.
    given_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*"Attributes"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*"Messages"*` ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*{SELFDEF}*` ).
  ENDMETHOD.

  METHOD detail_longtext_link.
    given_detail( ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true(
        xsdbool( line_exists( mo_dbl->mt_events[ table_line = `LONGTEXT|${MSGNR}` ] ) ) ).
  ENDMETHOD.

  METHOD longtext_is_wellformed.
    mo_cut->mv_mode     = `LONGTEXT`.
    mo_cut->mv_current  = `00`.
    mo_cut->mv_msgnr    = `311`.
    mo_cut->mv_longtext = `Diagnosis <x> & {y}`.
    mo_cut->render( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*Long Text of Message 00 311*` ).
  ENDMETHOD.

  METHOD longtext_back_to_detail.
    mo_cut->mv_mode      = `LONGTEXT`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_DETAIL`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `DETAIL` act = mo_cut->mv_mode ).
  ENDMETHOD.

  METHOD execute_opens_class.
    " a full name opens the class directly - if the user may see it
    mo_api->answer( iv_method = `GET_MESSAGES` iv_param = `ET_MSGS` iv_key = `ZLK05`
                    iv_value  = VALUE zcl_zlk05_sys_api=>ty_t_msg( ( msgnr = `001` text = `You are not authorized to use transaction &1` ) ) ).
    mo_cut->mv_pattern   = `zlk05`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `EXECUTE`.
    mo_cut->on_event( ).
    IF mo_cut->mv_mode = `DETAIL`.
      cl_abap_unit_assert=>assert_equals( exp = `ZLK05` act = mo_cut->mv_current ).
      cl_abap_unit_assert=>assert_true( xsdbool( line_exists( mo_cut->mt_msgs[ msgnr = `001` ] ) ) ).
    ELSE.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ENDIF.
  ENDMETHOD.

  METHOD execute_unknown_class.
    mo_api->answer( iv_method = `GET_MESSAGES` iv_param = `EV_MESSAGE` iv_key = `ZZ_NO_CLASS_X`
                    iv_value  = `Message class ZZ_NO_CLASS_X does not exist` ).
    mo_cut->mv_pattern   = `ZZ_NO_CLASS_X`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `EXECUTE`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*does not exist*` ).
  ENDMETHOD.

  METHOD longtext_missing.
    given_detail( ).
    mo_cut->mv_current = `ZLK05`.
    mo_cut->do_longtext( `001` ).
    cl_abap_unit_assert=>assert_equals( exp = `DETAIL` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*no long text*` ).
  ENDMETHOD.

  METHOD start_param_class.
    mo_cut->zif_zlk05_start_params~set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_msgclass value = ` zlk05 ` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `ZLK05` act = mo_cut->mv_start_class ).
  ENDMETHOD.

ENDCLASS.
