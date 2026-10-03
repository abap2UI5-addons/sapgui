CLASS ltcl_se16n DEFINITION DEFERRED.
CLASS zcl_se16n_a2u5 DEFINITION LOCAL FRIENDS ltcl_se16n.

CLASS ltcl_se16n DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_se16n_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_two_columns.
    METHODS assert_wellformed
      IMPORTING iv_step TYPE string.

    " --- selection condition / WHERE clause ---
    METHODS cond_eq              FOR TESTING.
    METHODS cond_operators       FOR TESTING.
    METHODS cond_quote_escaped   FOR TESTING.
    METHODS cond_cp_wildcards    FOR TESTING.
    METHODS cond_between         FOR TESTING.
    METHODS where_no_criteria    FOR TESTING.
    METHODS where_include_or     FOR TESTING.
    METHODS where_exclude_not    FOR TESTING.
    METHODS where_two_fields_and FOR TESTING.
    METHODS where_skips_empty    FOR TESTING.
    METHODS where_rejects_unknown_field FOR TESTING.

    " --- rendered views ---
    METHODS view_1_wellformed    FOR TESTING.
    METHODS view_2_wellformed    FOR TESTING.
    METHODS view_3_wellformed    FOR TESTING.
    METHODS view_2_shows_message FOR TESTING.
    METHODS view_3_row_count     FOR TESTING.

    " --- selection values entered in the field lines ---
    METHODS crit_from_field_lines FOR TESTING.
    METHODS crit_default_operator FOR TESTING.
    METHODS crit_skips_empty      FOR TESTING.

    " --- the classic SAP GUI window frame ---
    METHODS view_1_has_gui_frame  FOR TESTING.
    METHODS view_3_has_gui_frame  FOR TESTING.

    " --- returning from another transaction (F3 there) ---
    METHODS navigated_renders_step_1 FOR TESTING.
    METHODS navigated_renders_step_3 FOR TESTING.

    " --- started from another transaction (SE11 Contents, SM30) ---
    METHODS start_table_loads        FOR TESTING.
    METHODS start_back_leaves        FOR TESTING.

ENDCLASS.


CLASS ltcl_se16n IMPLEMENTATION.

  " ===================== navigated back to =====================
  " A transaction that is returned to gets NO event and check_on_init is
  " already false - only check_on_navigated is set. An app that ignores that
  " flag renders nothing, the response carries no view and the browser keeps
  " showing the screen of the transaction that was just left. These two tests
  " pin the branch that prevents it.

  METHOD navigated_renders_step_1.

    mo_dbl->mv_on_init      = abap_false.
    mo_dbl->mv_on_event     = abap_false.
    mo_dbl->mv_on_navigated = abap_true.

    mo_cut->z2ui5_if_app~main( mo_dbl ).

    cl_abap_unit_assert=>assert_not_initial(
        act = mo_dbl->mv_view
        msg = `navigating back must render the initial screen again` ).
    assert_wellformed( `step 1 after navigation` ).

  ENDMETHOD.

  METHOD navigated_renders_step_3.

    " the step the transaction was standing on has to come back, not step 1
    given_two_columns( ).
    mo_cut->mv_step  = 3.
    mo_cut->mt_rows  = VALUE #( ( c01 = `4711` c02 = `FERT` ) ).
    mo_cut->mv_total_rows = 1.

    mo_dbl->mv_on_init      = abap_false.
    mo_dbl->mv_on_event     = abap_false.
    mo_dbl->mv_on_navigated = abap_true.

    mo_cut->z2ui5_if_app~main( mo_dbl ).

    assert_wellformed( `step 3 after navigation` ).
    " the result list carries the table name in its title bar, the initial
    " screen does not - that tells the two screens apart
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Display of Entries Found` ) >= 0 )
        msg = `navigating back must return to the result list, not to step 1` ).

  ENDMETHOD.

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

  METHOD given_two_columns.
    mo_cut->mv_table_name = `T100`.
    mo_cut->mt_fields = VALUE #(
      ( fname = `MSGNR` label = `Material` ftype = `CHAR` col_id = `C01` visible = abap_true )
      ( fname = `ARBGB` label = `Type`     ftype = `CHAR` col_id = `C02` visible = abap_true ) ).
    mo_cut->mt_crit = VALUE #(
      ( key = `1` fname = `MSGNR` sign = `I` opt = `EQ` low = `4711` ) ).
  ENDMETHOD.

  METHOD assert_wellformed.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_step } does not render well formed XML| ).
  ENDMETHOD.

  " ===================== build_condition =====================

  METHOD cond_eq.
    cl_abap_unit_assert=>assert_equals(
        exp = `MSGNR = '4711'`
        act = mo_cut->build_condition( VALUE #( fname = `MSGNR` opt = `EQ` low = `4711` ) ) ).
  ENDMETHOD.

  METHOD cond_operators.
    cl_abap_unit_assert=>assert_equals(
        exp = `F <> '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `NE` low = `1` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `F > '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `GT` low = `1` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `F >= '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `GE` low = `1` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `F < '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `LT` low = `1` ) ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `F <= '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `LE` low = `1` ) ) ).
    " unknown operator falls back to equality
    cl_abap_unit_assert=>assert_equals(
        exp = `F = '1'`
        act = mo_cut->build_condition( VALUE #( fname = `F` opt = `??` low = `1` ) ) ).
  ENDMETHOD.

  METHOD cond_quote_escaped.
    " a single quote in the value must be doubled, otherwise the generated
    " SQL breaks (and would be injectable)
    cl_abap_unit_assert=>assert_equals(
        exp = `NAME1 = 'O''Brien'`
        act = mo_cut->build_condition( VALUE #( fname = `NAME1` opt = `EQ` low = `O'Brien` ) ) ).
  ENDMETHOD.

  METHOD cond_cp_wildcards.
    " SAP GUI wildcards * and + become SQL % and _
    cl_abap_unit_assert=>assert_equals(
        exp = `MSGNR LIKE 'A%B_'`
        act = mo_cut->build_condition( VALUE #( fname = `MSGNR` opt = `CP` low = `A*B+` ) ) ).
  ENDMETHOD.

  METHOD cond_between.
    cl_abap_unit_assert=>assert_equals(
        exp = `ERDAT BETWEEN '20260101' AND '20261231'`
        act = mo_cut->build_condition( VALUE #( fname = `ERDAT` opt = `BT`
                                               low = `20260101` high = `20261231` ) ) ).
  ENDMETHOD.

  " ===================== build_where =====================

  METHOD where_no_criteria.
    cl_abap_unit_assert=>assert_equals( exp = `1 = 1` act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_include_or.
    mo_cut->mv_table_name = `T100`.
    " two include lines on the SAME field are OR-combined
    mo_cut->mt_crit = VALUE #(
      ( fname = `MSGNR` sign = `I` opt = `EQ` low = `1` )
      ( fname = `MSGNR` sign = `I` opt = `EQ` low = `2` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MSGNR = '1' OR MSGNR = '2' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_exclude_not.
    mo_cut->mv_table_name = `T100`.
    " sign = E must negate the condition - it was silently ignored before
    mo_cut->mt_crit = VALUE #(
      ( fname = `ARBGB` sign = `E` opt = `EQ` low = `FERT` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `NOT ( ARBGB = 'FERT' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_two_fields_and.
    mo_cut->mv_table_name = `T100`.
    " different fields are AND-combined, exclude stays negated
    mo_cut->mt_crit = VALUE #(
      ( fname = `MSGNR` sign = `I` opt = `EQ` low = `1` )
      ( fname = `ARBGB` sign = `E` opt = `EQ` low = `FERT` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MSGNR = '1' ) AND NOT ( ARBGB = 'FERT' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_skips_empty.
    " empty lines and lines without a field name are ignored
    mo_cut->mt_crit = VALUE #(
      ( fname = `MSGNR` sign = `I` opt = `EQ` low = `` high = `` )
      ( fname = ``      sign = `I` opt = `EQ` low = `X` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1 = 1` act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_rejects_unknown_field.
    " field names come back from the browser - a name that is not a field
    " of the table (or an attempt to smuggle SQL in) must never reach the
    " dynamic WHERE clause
    mo_cut->mv_table_name = `T100`.
    mo_cut->mt_crit = VALUE #(
      ( fname = `NO_SUCH_FIELD` sign = `I` opt = `EQ` low = `1` )
      ( fname = `MSGNR = MSGNR OR MSGNR` sign = `I` opt = `EQ` low = `1` )
      ( fname = `ARBGB` sign = `I` opt = `EQ` low = `FERT` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( ARBGB = 'FERT' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  " ===================== rendered views =====================

  METHOD view_1_wellformed.
    mo_cut->view_step_1( ).
    assert_wellformed( `Step 1 (table name)` ).
  ENDMETHOD.

  METHOD view_2_wellformed.
    given_two_columns( ).
    mo_cut->view_step_2( ).
    assert_wellformed( `Step 2 (selection screen)` ).
  ENDMETHOD.

  METHOD view_3_wellformed.
    given_two_columns( ).
    mo_cut->mt_rows = VALUE #( ( c01 = `4711` c02 = `FERT` )
                               ( c01 = `4712` c02 = `HALB` ) ).
    mo_cut->mv_total_rows = 2.
    mo_cut->view_step_3( ).
    assert_wellformed( `Step 3 (result list)` ).
  ENDMETHOD.

  METHOD view_2_shows_message.
    " the error of a failed SELECT has to reach the rendered view
    given_two_columns( ).
    mo_cut->mv_message      = `Table ZZZ does not exist`.
    mo_cut->mv_message_type = `Error`.
    mo_cut->view_step_2( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Table ZZZ does not exist` ) >= 0 )
        msg = 'the status message is not rendered into the selection screen' ).
  ENDMETHOD.

  METHOD view_3_row_count.
    given_two_columns( ).
    mo_cut->mt_rows = VALUE #( ( c01 = `4711` ) ).
    mo_cut->view_step_3( ).

    " visibleRowCountMode=Auto must not be combined with a fixed visibleRowCount
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `visibleRowCountMode` ) >= 0 )
        msg = 'grid table should size itself (visibleRowCountMode)' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `visibleRowCount=` )
        msg = 'visibleRowCount must not be supplied next to visibleRowCountMode' ).
  ENDMETHOD.

  " ============ selection values in the field lines ============

  METHOD crit_from_field_lines.
    " SE16N takes the selection values from the line of the field itself
    given_two_columns( ).
    CLEAR mo_cut->mt_crit.
    mo_cut->mt_fields[ fname = `MSGNR` ]-opt = `EQ`.
    mo_cut->mt_fields[ fname = `MSGNR` ]-low = `4711`.

    mo_cut->crit_from_fields( ).

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = lines( mo_cut->mt_crit )
        msg = 'one selection line was expected' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MSGNR = '4711' )`
        act = mo_cut->build_where( )
        msg = 'the value of the field line does not reach the WHERE clause' ).
  ENDMETHOD.

  METHOD crit_default_operator.
    " a value without an operator is read as Equal To
    given_two_columns( ).
    CLEAR mo_cut->mt_crit.
    mo_cut->mt_fields[ fname = `ARBGB` ]-low = `FERT`.

    mo_cut->crit_from_fields( ).

    cl_abap_unit_assert=>assert_equals(
        exp = `EQ`
        act = mo_cut->mt_crit[ 1 ]-opt
        msg = 'an empty operator has to default to EQ' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `I`
        act = mo_cut->mt_crit[ 1 ]-sign
        msg = 'a value in the field line is an include' ).
  ENDMETHOD.

  METHOD crit_skips_empty.
    " fields without a value must not reach the WHERE clause
    given_two_columns( ).
    CLEAR mo_cut->mt_crit.

    mo_cut->crit_from_fields( ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_cut->mt_crit
        msg = 'fields without a value must not become selection criteria' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `1 = 1`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  " ============ classic SAP GUI window frame ============

  METHOD view_1_has_gui_frame.
    mo_cut->view_step_1( ).

    " menu bar, title bar and the columns of the selection criteria
    LOOP AT VALUE string_table(
        ( `Table Display` )
        ( `General Table Display` )
        ( `Selection Criteria` )
        ( `Frm-Val.` )
        ( `To-Value` )
        ( `Technical Name` )
        ( `Max. Number of Hits` ) ) INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the selection screen does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_3_has_gui_frame.
    given_two_columns( ).
    mo_cut->mt_rows = VALUE #( ( c01 = `4711` ) ).
    mo_cut->view_step_3( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `T100: Display of Entries Found` ) >= 0 )
        msg = 'the result screen does not show the original screen title' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Table Entry` ) >= 0 )
        msg = 'the result screen does not show the menu bar' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Number of Hits` ) >= 0 )
        msg = 'the result screen does not show the number of hits' ).
  ENDMETHOD.


  METHOD start_table_loads.
    CAST zif_zlk05_start_params( mo_cut )->set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_table value = ` t000 ` ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = `T000` act = mo_cut->mv_start_table ).
    mo_dbl->mv_on_init = abap_true.
    CAST z2ui5_if_app( mo_cut )->main( mo_dbl ).
    IF mo_dbl->mv_view CS `No Authorization`.
      RETURN.
    ENDIF.
    " the selection screen of the table is shown at once, not step 1
    cl_abap_unit_assert=>assert_true( mo_cut->mv_called ).
    cl_abap_unit_assert=>assert_equals( exp = 2 act = mo_cut->mv_step ).
    cl_abap_unit_assert=>assert_not_initial( mo_cut->mt_fields ).
  ENDMETHOD.

  METHOD start_back_leaves.
    mo_cut->mv_called = abap_true.
    mo_cut->mv_step   = 2.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_INPUT`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

ENDCLASS.
