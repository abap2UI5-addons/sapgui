CLASS ltcl_launcher DEFINITION DEFERRED.
CLASS zcl_sapgui_start DEFINITION LOCAL FRIENDS ltcl_launcher.

CLASS ltcl_launcher DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_start.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.

    " --- command field ---
    METHODS cmd_plain            FOR TESTING.
    METHODS cmd_slash_prefixes   FOR TESTING.
    METHODS cmd_spaces_and_case  FOR TESTING.

    " --- starting transactions ---
    METHODS every_menu_app_starts FOR TESTING.
    METHODS favorites_are_startable FOR TESTING.
    METHODS unknown_tcode         FOR TESTING.
    METHODS listed_but_no_app     FOR TESTING.
    METHODS core_tcodes_implemented FOR TESTING.

    " --- view ---
    METHODS view_wellformed      FOR TESTING.
    METHODS view_shows_status    FOR TESTING.

    " --- returning from a transaction (F3 there) ---
    METHODS navigated_renders_entry FOR TESTING.
ENDCLASS.


CLASS ltcl_launcher IMPLEMENTATION.

  METHOD navigated_renders_entry.

    " F3 in a transaction hands control back to the entry screen. The
    " framework supplies NO event and check_on_init is already false, so only
    " check_on_navigated is set. Without that branch nothing is rendered, the
    " response carries no view and the browser keeps showing the transaction
    " that was just left - the Back arrow looks dead.
    mo_dbl->mv_on_init      = abap_false.
    mo_dbl->mv_on_event     = abap_false.
    mo_dbl->mv_on_navigated = abap_true.

    mo_cut->z2ui5_if_app~main( mo_dbl ).

    cl_abap_unit_assert=>assert_not_initial(
        act = mo_dbl->mv_view
        msg = `navigating back must render the entry screen again` ).
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = `the entry screen after navigation is not well formed` ).

  ENDMETHOD.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
    mo_cut->init_menu( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  " ===================== command field =====================

  METHOD cmd_plain.
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = mo_cut->normalize_command( `SE80` ) ).
  ENDMETHOD.

  METHOD cmd_slash_prefixes.
    " SAP GUI command field syntax
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = mo_cut->normalize_command( `/nSE80` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = mo_cut->normalize_command( `/oSE80` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = mo_cut->normalize_command( `/SE80` ) ).
  ENDMETHOD.

  METHOD cmd_spaces_and_case.
    cl_abap_unit_assert=>assert_equals(
        exp = `SE16N` act = mo_cut->normalize_command( `  se16n  ` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE16N` act = mo_cut->normalize_command( `/n se16n` ) ).
  ENDMETHOD.

  " ===================== starting transactions =====================

  METHOD every_menu_app_starts.
    " Each menu entry that names a class must really be instantiable and must
    " navigate to exactly that app - a typo in the class name would only show
    " up at runtime otherwise.
    LOOP AT mo_cut->mt_all_tcodes INTO DATA(ls_tc) WHERE class IS NOT INITIAL.
      mo_dbl->reset( ).

      cl_abap_unit_assert=>assert_equals(
          exp = abap_true
          act = mo_cut->start_transaction( ls_tc-tcode )
          msg = |transaction { ls_tc-tcode } does not start| ).

      cl_abap_unit_assert=>assert_equals(
          exp = to_upper( ls_tc-class )
          act = mo_dbl->mv_nav_call
          msg = |transaction { ls_tc-tcode } navigates to the wrong app| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD favorites_are_startable.
    " every favorite must also exist in the SAP menu and carry an app
    LOOP AT mo_cut->mt_favorites INTO DATA(ls_fav).
      cl_abap_unit_assert=>assert_not_initial(
          act = ls_fav-class
          msg = |favorite { ls_fav-tcode } has no app assigned| ).

      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( mo_cut->mt_all_tcodes[ tcode = ls_fav-tcode ] ) )
          msg = |favorite { ls_fav-tcode } is missing in the SAP menu| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD unknown_tcode.
    cl_abap_unit_assert=>assert_equals(
        exp = abap_false
        act = mo_cut->start_transaction( `ZZUNKNOWN` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `Error` act = mo_cut->mv_msgtype ).
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->mv_nav_call
        msg = 'an unknown transaction must not navigate anywhere' ).
  ENDMETHOD.

  METHOD listed_but_no_app.
    " A transaction the menu lists without an app behind it must say so
    " instead of doing nothing. WHICH transaction that is changes with
    " every app that gets built, so the examples are taken from the list
    " itself - a hardcoded code silently stops testing the moment it gets
    " its app. That is exactly what happened to SE93 here.
    LOOP AT mo_cut->mt_all_tcodes INTO DATA(ls_tc) WHERE class IS INITIAL.
      mo_dbl->reset( ).

      cl_abap_unit_assert=>assert_equals(
          exp = abap_false
          act = mo_cut->start_transaction( ls_tc-tcode )
          msg = |listed transaction { ls_tc-tcode } must not start| ).
      cl_abap_unit_assert=>assert_equals(
          exp = `Warning`
          act = mo_cut->mv_msgtype
          msg = |listed transaction { ls_tc-tcode } must be answered with a warning| ).
      cl_abap_unit_assert=>assert_initial(
          act = mo_dbl->mv_nav_call
          msg = |listed transaction { ls_tc-tcode } must not navigate| ).
    ENDLOOP.

    " The same answer is owed for a transaction that does exist in the
    " system but is no part of this environment at all. This half of the
    " test keeps working even when every listed transaction has its app.
    DATA(lt_outside) = VALUE string_table(
        ( `SM36` ) ( `SM35` ) ( `SU56` ) ( `SM13` ) ).

    LOOP AT lt_outside INTO DATA(lv_tcode).
      IF line_exists( mo_cut->mt_all_tcodes[ tcode = lv_tcode ] )
         OR zcl_sapgui_sys_api=>transaction_exists( lv_tcode ) = abap_false.
        CONTINUE.
      ENDIF.

      mo_dbl->reset( ).

      cl_abap_unit_assert=>assert_equals(
          exp = abap_false
          act = mo_cut->start_transaction( lv_tcode )
          msg = |{ lv_tcode } is not part of this environment and must not start| ).
      cl_abap_unit_assert=>assert_equals(
          exp = `Warning`
          act = mo_cut->mv_msgtype
          msg = |{ lv_tcode } exists in the system - that is a warning, not an error| ).
      cl_abap_unit_assert=>assert_initial(
          act = mo_dbl->mv_nav_call
          msg = |{ lv_tcode } must not navigate anywhere| ).
      EXIT.
    ENDLOOP.
  ENDMETHOD.

  METHOD core_tcodes_implemented.
    " Regression guard: these classic transactions must stay wired up,
    " otherwise the SAP menu silently loses an app.
    DATA(lt_expected) = VALUE string_table(
      ( `SE80` ) ( `SE38` ) ( `SE11` ) ( `SE24` ) ( `SE37` ) ( `SE16N` )
      ( `SM21` ) ( `SM37` ) ( `SM50` ) ( `SM12` ) ( `ST22` ) ( `ST02` )
      ( `ST05` ) ( `SU01` ) ( `SCC4` ) ( `RZ11` ) ( `STMS` ) ).

    LOOP AT lt_expected INTO DATA(lv_tcode).
      READ TABLE mo_cut->mt_all_tcodes INTO DATA(ls_tc)
           WITH KEY tcode = lv_tcode.
      cl_abap_unit_assert=>assert_subrc(
          exp = 0
          msg = |transaction { lv_tcode } is missing from the SAP menu| ).
      cl_abap_unit_assert=>assert_not_initial(
          act = ls_tc-class
          msg = |transaction { lv_tcode } has no implementing app| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== view =====================

  METHOD view_wellformed.
    mo_cut->view_display( ).
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = 'the SAP Easy Access view is not well formed XML' ).
  ENDMETHOD.

  METHOD view_shows_status.
    " the status bar shows system / client / user - it used to be dead code
    mo_cut->mv_sysid    = `S4H`.
    mo_cut->mv_client   = `100`.
    mo_cut->mv_username = `TESTUSER`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `S4H` ) >= 0 )
        msg = 'the status bar does not show the system id' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `TESTUSER` ) >= 0 )
        msg = 'the status bar does not show the user name' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `100` ) >= 0 )
        msg = 'the status bar does not show the client' ).
  ENDMETHOD.

ENDCLASS.
