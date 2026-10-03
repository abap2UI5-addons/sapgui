CLASS ltcl_we02_a2u5 DEFINITION DEFERRED.
CLASS zcl_we02_a2u5 DEFINITION LOCAL FRIENDS ltcl_we02_a2u5.

CLASS ltcl_we02_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_api TYPE REF TO zcl_zlk05_sys_api_dbl.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_we02_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_list.
    METHODS given_detail.

    METHODS list_is_wellformed    FOR TESTING.
    METHODS list_original_title   FOR TESTING.
    METHODS list_all_columns      FOR TESTING.
    METHODS list_selection_fields FOR TESTING.
    METHODS list_display_wired    FOR TESTING.
    METHODS list_back_nav_wired   FOR TESTING.
    METHODS list_empty_is_sane    FOR TESTING.
    METHODS detail_is_wellformed  FOR TESTING.
    METHODS detail_three_tabs     FOR TESTING.
    METHODS detail_back_to_list   FOR TESTING.
    METHODS open_invalid_number   FOR TESTING.
    METHODS open_unknown_idoc     FOR TESTING.
    METHODS search_by_number      FOR TESTING.

ENDCLASS.


CLASS ltcl_we02_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_api = zcl_zlk05_sys_api_dbl=>install( ).
    zcl_zlk05_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
    mo_cut->mt_directions = VALUE #( ( key = `` text = `Both` ) ( key = `1` text = `Outbound` ) ).
  ENDMETHOD.

  METHOD teardown.
    zcl_zlk05_sys_api_dbl=>uninstall( ).
    zcl_zlk05_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_list.
    mo_cut->mt_idocs = VALUE #(
        ( docnum = `56036` status = `53` stattext = `Application document posted` state = `Success`
          direct = `Inbound` mestyp = `SEQJIT` idoctp = `SEQJIT03` partner = `KU 17154801`
          credat = `21.05.2026` cretim = `19:45:49` upddat = `21.05.2026` updtim = `19:45:50` )
        ( docnum = `56032` status = `51` stattext = `Application document not posted` state = `Error`
          direct = `Inbound` mestyp = `SEQJIT` idoctp = `SEQJIT03` partner = `KU 17154801`
          credat = `21.05.2026` cretim = `19:35:41` upddat = `21.05.2026` updtim = `19:35:42` ) ).
  ENDMETHOD.

  METHOD given_detail.
    mo_cut->mv_mode = `DETAIL`.
    mo_cut->mv_tab  = `STATUS`.
    mo_cut->ms_idoc = VALUE #( docnum = `56032` mestyp = `SEQJIT` status = `51` ).
    mo_cut->mt_control = VALUE #( ( label = `IDoc number` value = `56032` ) ).
    mo_cut->mt_status = VALUE #(
        ( counter = `3` status = `51` state = `Error` stattext = `Application document not posted`
          message = `Sequence <4711> & item {1} not found` date = `21.05.2026` time = `19:35:42`
          user = `BATCHUSER` program = `SAPLJIT` ) ).
    mo_cut->mt_segments = VALUE #(
        ( segnum = `1` segnam = `E1JITH` hlevel = `1` tree = `E1JITH` sdata = `0017154801 A&B <x>` )
        ( segnum = `2` segnam = `E1JITI` hlevel = `2` tree = `. E1JITI` sdata = `000010` ) ).
  ENDMETHOD.

  METHOD list_is_wellformed.
    given_list( ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD list_original_title.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*IDoc List*` ).
  ENDMETHOD.

  METHOD list_all_columns.
    given_list( ).
    mo_cut->view_list( ).
    LOOP AT VALUE string_table( ( `{DOCNUM}` ) ( `{STATUS}` ) ( `{STATTEXT}` ) ( `{STATE}` )
                                ( `{DIRECT}` ) ( `{MESTYP}` ) ( `{IDOCTP}` ) ( `{PARTNER}` )
                                ( `{CREDAT}` ) ( `{CRETIM}` ) ( `{UPDDAT}` ) ( `{UPDTIM}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_selection_fields.
    mo_cut->view_list( ).
    LOOP AT VALUE string_table( ( `idIdocFrom` ) ( `idIdocTo` ) ( `idIdocNumber` )
                                ( `idIdocStatus` ) ( `idIdocMestyp` ) )
         INTO DATA(lv_id).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_id ) >= 0 )
          msg = |selection field { lv_id } is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_display_wired.
    given_list( ).
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( mo_dbl->mt_events[ table_line = `DISPLAY|${DOCNUM}` ] ) )
        msg = 'the IDoc number must open the IDoc' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*MOCK_NAV_LEAVE*` ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    mo_cut->view_list( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
  ENDMETHOD.

  METHOD detail_is_wellformed.
    " status texts and segment data carry < & { - they must not break the view
    given_detail( ).
    mo_cut->render( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->get_xml_errors( ) ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_dbl->mv_view exp = `*IDoc 56032*` ).
  ENDMETHOD.

  METHOD detail_three_tabs.
    given_detail( ).
    mo_cut->view_detail( ).
    LOOP AT VALUE string_table( ( `Status Records` ) ( `Data Records` ) ( `Control Record` )
                                ( `{MESSAGE}` ) ( `{TREE}` ) ( `{SDATA}` ) ( `{LABEL}` ) )
         INTO DATA(lv_part).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_part ) >= 0 )
          msg = |{ lv_part } is missing in the IDoc display| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_detail( ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_LIST`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
  ENDMETHOD.

  METHOD open_invalid_number.
    mo_api->answer( iv_method = `GET_IDOC_DETAIL` iv_param = `EV_MESSAGE` iv_key = `abc`
                    iv_value  = `Enter a valid IDoc number` ).
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `abc` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST`  act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = mo_cut->mv_msgtype ).
  ENDMETHOD.

  METHOD open_unknown_idoc.
    mo_api->answer( iv_method = `GET_IDOC_DETAIL` iv_param = `EV_MESSAGE` iv_key = `9999999999999999`
                    iv_value  = `IDoc 9999999999999999 does not exist` ).
    mo_cut->mv_mode = `LIST`.
    mo_cut->do_open( `9999999999999999` ).
    cl_abap_unit_assert=>assert_equals( exp = `LIST` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_char_cp( act = mo_cut->mv_message exp = `*does not exist*` ).
  ENDMETHOD.

  METHOD search_by_number.
    " an IDoc number wins over the date - the IDoc of 2026-05-21 is found
    " although the date proposal is today (if the user may see it at all)
    mo_cut->mv_docnum    = `56036`.
    mo_cut->mv_date_from = |{ sy-datum }|.
    mo_cut->mv_date_to   = |{ sy-datum }|.
    mo_cut->do_search( ).
    IF mo_cut->mt_idocs IS INITIAL.
      cl_abap_unit_assert=>assert_equals( exp = `Warning` act = mo_cut->mv_msgtype ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = 1 act = lines( mo_cut->mt_idocs ) ).
      cl_abap_unit_assert=>assert_equals( exp = `56036` act = mo_cut->mt_idocs[ 1 ]-docnum ).
    ENDIF.
  ENDMETHOD.

ENDCLASS.
