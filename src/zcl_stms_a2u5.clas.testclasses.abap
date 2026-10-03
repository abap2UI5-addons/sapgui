CLASS ltcl_stms_a2u5 DEFINITION DEFERRED.
CLASS zcl_stms_a2u5 DEFINITION LOCAL FRIENDS ltcl_stms_a2u5.

CLASS ltcl_stms_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_stms_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_domain.
    METHODS given_systems.
    METHODS given_queue.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS start_is_sane           FOR TESTING.
    METHODS start_original_title    FOR TESTING.
    METHODS start_has_gui_frame     FOR TESTING.
    METHODS start_domain_fields     FOR TESTING.
    METHODS start_entries_wired     FOR TESTING.
    METHODS start_unavailable_shown FOR TESTING.
    METHODS start_back_nav_wired    FOR TESTING.

    METHODS systems_is_sane         FOR TESTING.
    METHODS systems_original_title  FOR TESTING.
    METHODS systems_columns         FOR TESTING.
    METHODS systems_source_stated   FOR TESTING.
    METHODS systems_back_to_start   FOR TESTING.
    METHODS systems_empty_is_sane   FOR TESTING.

    METHODS imports_is_sane         FOR TESTING.
    METHODS imports_original_title  FOR TESTING.
    METHODS imports_counts_requests FOR TESTING.
    METHODS imports_source_stated   FOR TESTING.

    METHODS empty_queue_is_reported FOR TESTING.
    METHODS message_reaches_view    FOR TESTING.

    METHODS api_texts_are_resolved  FOR TESTING.
ENDCLASS.


CLASS ltcl_stms_a2u5 IMPLEMENTATION.

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

  METHOD given_domain.
    mo_cut->mv_domain = `DOMAIN_S4H`.
    mo_cut->mv_system = `S4H`.
  ENDMETHOD.

  METHOD given_systems.
    given_domain( ).
    mo_cut->mt_systems = VALUE #(
        ( sysnam = `S4H` systxt = `System S4H` systyp = `Real system`
          comsys = `` cfgstat = `System is active`
          desadm = `TMSADM@S4H.DOMAIN_S4H` moddat = `11.11.2025` modusr = `MARCELLO` )
        ( sysnam = `EME` systxt = `EMEA system` systyp = `Virtual system`
          comsys = `S4H` cfgstat = `System is active`
          desadm = `` moddat = `12.01.2026` modusr = `MARCELLO` ) ).
  ENDMETHOD.

  METHOD given_queue.
    given_systems( ).
    mo_cut->mt_queue = VALUE #(
        ( sysnam = `EME` bufpos = `1` trkorr = `S4HK900123` owner = `DEVELOPER`
          tarcli = `100` maxrc = `0` text = `Demo request` ) ).
    mo_cut->build_overview( ).
  ENDMETHOD.

  METHOD assert_shell_sane.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_ctx }: view is not well formed XML| ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( ) sub = `ROOT ELEMENT` )
        msg = |{ iv_ctx }: expected exactly one root, got { mo_dbl->get_root_name( ) }| ).

    LOOP AT VALUE string_table( ( `columns` ) ( `items` ) ( `cells` )
                                ( `footer` ) ( `content` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== start screen =====================

  METHOD start_is_sane.
    given_domain( ).
    mo_cut->view_start( ).

    assert_shell_sane( `STMS start screen` ).
  ENDMETHOD.

  METHOD start_original_title.
    " title bar text of SAPLTMSU dynpro 100
    given_domain( ).
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Transport Management System` ) >= 0 )
        msg = 'the original STMS screen title is missing' ).
  ENDMETHOD.

  METHOD start_has_gui_frame.
    given_domain( ).
    mo_cut->view_start( ).

    LOOP AT VALUE string_table( ( `Overview` ) ( `Extras` ) ( `Environment` )
                                ( `System` ) ( `Help` )
                                ( `Imports` ) ( `Systems` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD start_domain_fields.
    " the two fields of dynpro 0100 with their original labels
    given_domain( ).
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Transp. Domain` ) >= 0 )
        msg = 'the Transp. Domain field label of dynpro 0100 is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `DOMAIN_S4H` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `S4H` ) >= 0 )
        msg = 'the start screen does not name domain and system' ).
  ENDMETHOD.

  METHOD start_entries_wired.
    given_domain( ).
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `IMPO` )
        msg = 'the Imports entry is not wired to the IMPO event' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `SYSO` )
        msg = 'the Systems entry is not wired to the SYSO event' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `REFRESH` )
        msg = 'the Refresh button is not wired' ).
  ENDMETHOD.

  METHOD start_unavailable_shown.
    " importing and configuring stay visible but disabled
    given_domain( ).
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Transport Routes` ) >= 0
                   AND find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the missing STMS functions do not explain themselves' ).
  ENDMETHOD.

  METHOD start_back_nav_wired.
    given_domain( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  " ===================== system overview =====================

  METHOD systems_is_sane.
    given_systems( ).
    mo_cut->view_systems( ).

    assert_shell_sane( `STMS system overview` ).
  ENDMETHOD.

  METHOD systems_original_title.
    " title SYS of SAPLTMSU - System Overview: Domain &
    given_systems( ).
    mo_cut->view_systems( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `System Overview: Domain DOMAIN_S4H` ) >= 0 )
        msg = 'the original system overview title is missing' ).
  ENDMETHOD.

  METHOD systems_columns.
    given_systems( ).
    mo_cut->view_systems( ).

    LOOP AT VALUE string_table( ( `{SYSNAM}` ) ( `{SYSTXT}` ) ( `{SYSTYP}` )
                                ( `{COMSYS}` ) ( `{CFGSTAT}` ) ( `{DESADM}` )
                                ( `{MODDAT}` ) ( `{MODUSR}` ) )
         INTO DATA(lv_field).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_field ) >= 0 )
          msg = |the system overview column { lv_field } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD systems_source_stated.
    " the original STMS asks the domain controller by RFC - this app does not
    " and has to say so, otherwise the list looks domain wide
    given_systems( ).
    mo_cut->view_systems( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `TMSCSYS` ) >= 0
                   AND find( val = mo_dbl->mv_view
                             sub = `domain controller is not called` ) >= 0 )
        msg = 'the data source of the system list is not stated' ).
  ENDMETHOD.

  METHOD systems_back_to_start.
    given_systems( ).
    mo_cut->view_systems( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_START` )
        msg = 'the system overview has no way back to the start screen' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the system overview leaves the app instead of returning to the start screen' ).
  ENDMETHOD.

  METHOD systems_empty_is_sane.
    given_domain( ).
    CLEAR mo_cut->mt_systems.
    mo_cut->view_systems( ).

    assert_shell_sane( `STMS system overview without systems` ).
  ENDMETHOD.

  " ===================== import overview =====================

  METHOD imports_is_sane.
    given_queue( ).
    mo_cut->view_imports( ).

    assert_shell_sane( `STMS import overview` ).
  ENDMETHOD.

  METHOD imports_original_title.
    " title IMP of SAPLTMSU - Import Overview: Domain &
    given_queue( ).
    mo_cut->view_imports( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Import Overview: Domain DOMAIN_S4H` ) >= 0 )
        msg = 'the original import overview title is missing' ).
  ENDMETHOD.

  METHOD imports_counts_requests.
    " every system of the domain gets a line, the request count has to match
    " the buffer entries of that system
    given_queue( ).

    cl_abap_unit_assert=>assert_equals(
        exp = 2
        act = lines( mo_cut->mt_overview )
        msg = 'the import overview does not show one line per system' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `1`
        act = mo_cut->mt_overview[ sysnam = `EME` ]-reqs
        msg = 'the waiting request of system EME is not counted' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `0`
        act = mo_cut->mt_overview[ sysnam = `S4H` ]-reqs
        msg = 'a system without requests must show zero, not the total' ).
  ENDMETHOD.

  METHOD imports_source_stated.
    given_queue( ).
    mo_cut->view_imports( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `TMSBUFFER` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `no RFC call` ) >= 0 )
        msg = 'the data source of the import queue is not stated' ).
  ENDMETHOD.

  " ===================== states =====================

  METHOD empty_queue_is_reported.
    " an empty import queue must be stated, not shown as an empty list
    given_systems( ).
    CLEAR mo_cut->mt_queue.
    mo_cut->do_read_queue( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_cut->mv_message
                             sub = `No transport requests are waiting` ) >= 0 )
        msg = 'an empty import queue is not reported as such' ).
  ENDMETHOD.

  METHOD message_reaches_view.
    given_domain( ).
    mo_cut->mv_message = `System XYZ is not included in a transport domain.`.
    mo_cut->mv_msgtype = `Warning`.
    mo_cut->view_start( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                    sub = `System XYZ is not included in a transport domain.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== data source =====================

  METHOD api_texts_are_resolved.
    " the coded system type and configuration status must be translated into
    " the fixed value texts of domains TMSSYSTYP / TMSCFGSTAT
    DATA(lt_sys) = zcl_zlk05_sys_api=>get_tms_systems( ).

    LOOP AT lt_sys INTO DATA(ls_sys).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( strlen( ls_sys-systyp ) > 1 )
          msg = |system type of { ls_sys-sysnam } is still the raw code| ).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( strlen( ls_sys-cfgstat ) > 1 )
          msg = |configuration status of { ls_sys-sysnam } is still the raw code| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
