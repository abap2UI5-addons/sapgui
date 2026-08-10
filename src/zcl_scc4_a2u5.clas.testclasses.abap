CLASS ltcl_scc4_a2u5 DEFINITION DEFERRED.
CLASS zcl_scc4_a2u5 DEFINITION LOCAL FRIENDS ltcl_scc4_a2u5.

CLASS ltcl_scc4_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_scc4_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_clientlist.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS view_is_sane          FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_title_is_escaped FOR TESTING.
    METHODS view_read_only_stated FOR TESTING.
    METHODS view_client_columns   FOR TESTING.
    METHODS view_texts_not_codes  FOR TESTING.
    METHODS view_current_client   FOR TESTING.
    METHODS view_back_nav_wired   FOR TESTING.
    METHODS view_has_gui_frame    FOR TESTING.
    METHODS view_keys_registered  FOR TESTING.
    METHODS view_command_field    FOR TESTING.
    METHODS view_unavailable_shown FOR TESTING.
    METHODS view_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
ENDCLASS.


CLASS ltcl_scc4_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_clientlist.
    mo_cut->mt_clients = VALUE #(
        ( mandt = `000` mtext = `SAP AG` ort01 = `Walldorf` mwaer = `EUR`
          category = `P` cattxt = `Production` cccoractiv = `2`
          coracttxt = `No changes to Repository and cross-client Customizing objects`
          ccnocliind = `1` ccnocascad = `` changeuser = `SAP` changedate = `01.01.2020`
          logsys = `S4HCLNT000` )
        ( mandt = `100` mtext = `Sandbox` ort01 = `Walldorf` mwaer = `EUR`
          category = `C` cattxt = `Customizing` cccoractiv = `1`
          coracttxt = `Changes to Repository and cross-client Customizing allowed`
          ccnocliind = `` ccnocascad = `` changeuser = `DEVELOPER`
          changedate = `01.01.2024` logsys = `S4HCLNT100` ) ).
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
                                ( `footer` ) ( `subHeader` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== client overview =====================

  METHOD view_is_sane.
    given_clientlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SCC4 client overview` ).
  ENDMETHOD.

  METHOD view_original_title.
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Display View` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Overview` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Clients` ) >= 0 )
        msg = 'the original SCC4 screen title is missing' ).
  ENDMETHOD.

  METHOD view_title_is_escaped.
    " the SCC4 title contains double quotes: Display View "Clients": Overview
    " If they are not escaped the attribute terminates early and UI5 cannot
    " parse the view at all.
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = 'the double quotes of the SCC4 title break the view XML' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `&quot;Clients&quot;` ) >= 0 )
        msg = 'the double quotes in the title are not XML escaped' ).
  ENDMETHOD.

  METHOD view_read_only_stated.
    " SCC4 changes client settings - this app must never suggest it can
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Client maintenance - display only` ) >= 0 )
        msg = 'the read-only restriction of the app is not stated on screen' ).
  ENDMETHOD.

  METHOD view_client_columns.
    " the two protection settings are the reason to look at SCC4 at all
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{MANDT}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{CATTXT}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{CORACTTXT}` ) >= 0 )
        msg = 'the client list does not bind client, role and transport setting' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Changes and Transports` ) >= 0 )
        msg = 'the Changes and Transports column header is missing' ).
  ENDMETHOD.

  METHOD view_texts_not_codes.
    " T000 stores the client role and the change option as single characters.
    " Showing the raw code would be useless - the resolved text has to be bound.
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `{CATEGORY}` )
        msg = 'the raw client role code is bound instead of its text' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `{CCCORACTIV}` )
        msg = 'the raw change option code is bound instead of its text' ).
  ENDMETHOD.

  METHOD view_current_client.
    " the status bar tells the user which client he is looking from - important
    " because SCC4 lists all clients of the system, not just the current one
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = |System { sy-sysid } - Client { sy-mandt }| ) >= 0 )
        msg = 'the status bar does not state the current client and system' ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    given_clientlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD view_has_gui_frame.
    " menu bar and application function bar carry the original texts of the
    " generated view maintenance SAPLSVIM
    given_clientlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Table View` ) ( `Edit` ) ( `Goto` ) ( `Selection` )
                                ( `Utilities` ) ( `System` ) ( `Help` )
                                ( `Details` ) ( `New Entries` ) ( `Copy As...` )
                                ( `Display -&gt; Change` ) ( `Position Cursor...` )
                                ( `Configuration Help` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_keys_registered.
    " the shortcut registry lives in the frontend and survives a transaction
    " switch, so every screen has to state its own binding for every key
    given_clientlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } is not registered for Back| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD view_command_field.
    " the command field has to be active on every screen, exactly like in the
    " SAP GUI - it is the only way to reach another transaction
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD view_unavailable_shown.
    " everything that would change a client stays visible but has to explain
    " itself - a dead button without a reason looks like a defect
    given_clientlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled SCC4 functions do not explain themselves' ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    CLEAR mo_cut->mt_clients.
    mo_cut->view_display( ).

    assert_shell_sane( `SCC4 client overview without clients` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `Client table could not be read.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Client table could not be read.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

ENDCLASS.
