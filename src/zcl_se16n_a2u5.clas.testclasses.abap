CLASS ltcl_se16n DEFINITION DEFERRED.
CLASS zcl_se16n_a2u5 DEFINITION LOCAL FRIENDS ltcl_se16n.

CLASS ltcl_se16n DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
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
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_two_columns.
    mo_cut->mv_table_name = `MARA`.
    mo_cut->mt_fields = VALUE #(
      ( fname = `MATNR` label = `Material` ftype = `CHAR` col_id = `C01` visible = abap_true )
      ( fname = `MTART` label = `Type`     ftype = `CHAR` col_id = `C02` visible = abap_true ) ).
    mo_cut->mt_crit = VALUE #(
      ( key = `1` fname = `MATNR` sign = `I` opt = `EQ` low = `4711` ) ).
  ENDMETHOD.

  METHOD assert_wellformed.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_step } does not render well formed XML| ).
  ENDMETHOD.

  " ===================== build_condition =====================

  METHOD cond_eq.
    cl_abap_unit_assert=>assert_equals(
        exp = `MATNR = '4711'`
        act = mo_cut->build_condition( VALUE #( fname = `MATNR` opt = `EQ` low = `4711` ) ) ).
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
        exp = `MATNR LIKE 'A%B_'`
        act = mo_cut->build_condition( VALUE #( fname = `MATNR` opt = `CP` low = `A*B+` ) ) ).
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
    " two include lines on the SAME field are OR-combined
    mo_cut->mt_crit = VALUE #(
      ( fname = `MATNR` sign = `I` opt = `EQ` low = `1` )
      ( fname = `MATNR` sign = `I` opt = `EQ` low = `2` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MATNR = '1' OR MATNR = '2' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_exclude_not.
    " sign = E must negate the condition - it was silently ignored before
    mo_cut->mt_crit = VALUE #(
      ( fname = `MTART` sign = `E` opt = `EQ` low = `FERT` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `NOT ( MTART = 'FERT' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_two_fields_and.
    " different fields are AND-combined, exclude stays negated
    mo_cut->mt_crit = VALUE #(
      ( fname = `MATNR` sign = `I` opt = `EQ` low = `1` )
      ( fname = `MTART` sign = `E` opt = `EQ` low = `FERT` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MATNR = '1' ) AND NOT ( MTART = 'FERT' )`
        act = mo_cut->build_where( ) ).
  ENDMETHOD.

  METHOD where_skips_empty.
    " empty lines and lines without a field name are ignored
    mo_cut->mt_crit = VALUE #(
      ( fname = `MATNR` sign = `I` opt = `EQ` low = `` high = `` )
      ( fname = ``      sign = `I` opt = `EQ` low = `X` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1 = 1` act = mo_cut->build_where( ) ).
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
    mo_cut->mt_fields[ fname = `MATNR` ]-opt = `EQ`.
    mo_cut->mt_fields[ fname = `MATNR` ]-low = `4711`.

    mo_cut->crit_from_fields( ).

    cl_abap_unit_assert=>assert_equals(
        exp = 1
        act = lines( mo_cut->mt_crit )
        msg = 'one selection line was expected' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `( MATNR = '4711' )`
        act = mo_cut->build_where( )
        msg = 'the value of the field line does not reach the WHERE clause' ).
  ENDMETHOD.

  METHOD crit_default_operator.
    " a value without an operator is read as Equal To
    given_two_columns( ).
    CLEAR mo_cut->mt_crit.
    mo_cut->mt_fields[ fname = `MTART` ]-low = `FERT`.

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
                             sub = `MARA: Display of Entries Found` ) >= 0 )
        msg = 'the result screen does not show the original screen title' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Table Entry` ) >= 0 )
        msg = 'the result screen does not show the menu bar' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Number of Hits` ) >= 0 )
        msg = 'the result screen does not show the number of hits' ).
  ENDMETHOD.

ENDCLASS.
