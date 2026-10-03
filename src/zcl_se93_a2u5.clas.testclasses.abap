CLASS ltcl_se93_a2u5 DEFINITION DEFERRED.
CLASS zcl_se93_a2u5 DEFINITION LOCAL FRIENDS ltcl_se93_a2u5.

CLASS ltcl_se93_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_se93_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_list.
    METHODS given_detail
      IMPORTING is_detail TYPE zcl_zlk05_sys_api=>ty_s_tcode_detail.
    METHODS detail_dialog
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_s_tcode_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.
    METHODS assert_shows
      IMPORTING it_text TYPE string_table
                iv_ctx  TYPE string.

    " --- entry screen ---
    METHODS entry_is_sane          FOR TESTING.
    METHODS entry_original_title   FOR TESTING.
    METHODS entry_dynpro_0390      FOR TESTING.
    METHODS entry_menu_capital_c   FOR TESTING.
    METHODS entry_no_app_toolbar   FOR TESTING.
    METHODS entry_list_columns     FOR TESTING.
    METHODS entry_columns_bound    FOR TESTING.
    METHODS entry_drilldown_wired  FOR TESTING.
    METHODS entry_keys_registered  FOR TESTING.
    METHODS entry_command_field    FOR TESTING.
    METHODS entry_back_leaves      FOR TESTING.
    METHODS entry_status_bar       FOR TESTING.
    METHODS entry_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view   FOR TESTING.

    " --- display screen, common part ---
    METHODS detail_is_sane         FOR TESTING.
    METHODS detail_title_has_type  FOR TESTING.
    METHODS detail_menu_small_c    FOR TESTING.
    METHODS detail_common_rows     FOR TESTING.
    METHODS detail_start_options   FOR TESTING.
    METHODS report_no_trans_var    FOR TESTING.
    METHODS param_no_start_options FOR TESTING.
    METHODS detail_classification  FOR TESTING.
    METHODS detail_toolbar_texts   FOR TESTING.
    METHODS detail_back_to_entry   FOR TESTING.
    METHODS detail_f3_stays_inside FOR TESTING.
    METHODS detail_auth_block      FOR TESTING.
    METHODS detail_no_auth_no_box  FOR TESTING.

    " --- display screen, one block per transaction type ---
    METHODS type_dialog_block      FOR TESTING.
    METHODS type_report_block      FOR TESTING.
    METHODS type_object_block      FOR TESTING.
    METHODS type_object_upd_mode   FOR TESTING.
    METHODS type_variant_block     FOR TESTING.
    METHODS type_param_tcode_block FOR TESTING.
    METHODS type_param_prog_block  FOR TESTING.
    METHODS type_unknown_is_dialog FOR TESTING.

    " --- update mode, free of any system access ---
    METHODS upd_mode_synchronous   FOR TESTING.
    METHODS upd_mode_asynchronous  FOR TESTING.
    METHODS upd_mode_local         FOR TESTING.
    METHODS upd_mode_empty         FOR TESTING.

    " --- Test and Display Program ---
    METHODS detail_test_wired        FOR TESTING.
    METHODS detail_goto_wired        FOR TESTING.
    METHODS detail_test_jumps        FOR TESTING.
    METHODS detail_goto_no_program   FOR TESTING.

ENDCLASS.


CLASS ltcl_se93_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_list.
    mo_cut->mv_mode  = `LIST`.
    mo_cut->mv_tcode = `SE9*`.
    mo_cut->mt_tcodes = VALUE #(
        ( tcode = `SE93` ttext = `Maintain Transaction Codes`
          pgmna = `SAPLSEUK` dypno = `0390` tc_type = `Dialog Transaction` )
        ( tcode = `SE95` ttext = `Modification Browser`
          pgmna = `RSMODBRW` dypno = `1000` tc_type = `Report Transaction` ) ).
  ENDMETHOD.

  METHOD given_detail.
    mo_cut->mv_mode   = `DETAIL`.
    mo_cut->ms_detail = is_detail.
  ENDMETHOD.

  METHOD detail_dialog.
    " SE93 itself, as ZCL_ZLK05_SYS_API returns it
    result = VALUE #( found       = abap_true
                      tcode       = `SE93`
                      ttext       = `Maintain Transaction Codes`
                      tc_type     = `Dialog Transaction`
                      pgmna       = `SAPLSEUK`
                      dypno       = `0390`
                      trans_var   = abap_true
                      profi_tran  = abap_true
                      s_platin    = abap_true ).
  ENDMETHOD.

  " Structural invariants shared by every SAP GUI look-alike view:
  " parsable XML, exactly one root element, and no container that lost its
  " children because the return value of open( ) was dropped.
  METHOD assert_shell_sane.
    cl_abap_unit_assert=>assert_initial(
        act = mo_dbl->get_xml_errors( )
        msg = |{ iv_ctx }: view is not well formed XML| ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->get_root_name( ) sub = `ROOT ELEMENT` )
        msg = |{ iv_ctx }: expected exactly one root, got { mo_dbl->get_root_name( ) }| ).

    LOOP AT VALUE string_table( ( `columns` ) ( `items` ) ( `cells` )
                                ( `footer` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD assert_shows.
    LOOP AT it_text INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |{ iv_ctx }: the original text "{ lv_text }" is missing| ).
    ENDLOOP.
  ENDMETHOD.

  " ========================== entry screen ==========================

  METHOD entry_is_sane.
    given_list( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SE93 entry screen` ).
  ENDMETHOD.

  METHOD entry_original_title.
    " RSMPTEXTS SAPLSEUK title 390
    given_list( ).
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( `Maintain Transaction` ) )
                  iv_ctx  = `entry screen` ).
  ENDMETHOD.

  METHOD entry_dynpro_0390.
    " D021T 0390: @10@ Display, @0Z@ Change, @0Y@ Create, and the field
    " label of TSTC-TCODE
    given_list( ).
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( `Transaction Code` ) ( `Display` )
                                     ( `Change` ) ( `Create` ) )
                  iv_ctx  = `dynpro 0390` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idTcode` ) >= 0 )
        msg = 'the transaction code input field is missing' ).
  ENDMETHOD.

  METHOD entry_menu_capital_c.
    " CUA menu bar 000028 of status 390_SELE spells it with a capital C,
    " menu bar 0007 of the display screens with a small one. The frame puts
    " every menu title into a tooltip as well, so that is what tells the two
    " apart - and the small spelling must not appear anywhere on this screen.
    given_list( ).
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( `Transaction Code - the menu bar` )
                                     ( `Edit` ) ( `Goto` ) ( `Utilities` )
                                     ( `Environment` ) )
                  iv_ctx  = `entry menu bar` ).
    " the negative check has to stay on the menu bar - the short text of
    " SE93 itself is 'Maintain Transaction Codes' and would match a plain
    " search for either spelling
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view
                    sub = `Transaction code - the menu bar` )
        msg = 'the entry screen shows the menu title of the display screens' ).
  ENDMETHOD.

  METHOD entry_no_app_toolbar.
    " GUI status 390_SELE carries no application toolbar at all. The three
    " functions are pushbuttons of the dynpro, so no greyed out toolbar
    " entry of the display screens may show up here.
    given_list( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Previous object` ) ( `Next object` )
                                ( `Other object...` ) ( `Where-used list` )
                                ( `Display object list` ) ( `Full Screen` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_equals(
          exp = -1
          act = find( val = mo_dbl->mv_view sub = lv_text )
          msg = |the entry screen must not carry the toolbar entry "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD entry_list_columns.
    given_list( ).
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( `Transaction Code` ) ( `Text` )
                                     ( `Program` ) ( `Screen` ) ( `Type` ) )
                  iv_ctx  = `hit list header` ).
  ENDMETHOD.

  METHOD entry_columns_bound.
    given_list( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `{TCODE}` ) ( `{TTEXT}` ) ( `{PGMNA}` )
                                ( `{DYPNO}` ) ( `{TC_TYPE}` ) )
         INTO DATA(lv_bind).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_bind ) >= 0 )
          msg = |the column { lv_bind } is not bound| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD entry_drilldown_wired.
    " the transaction code has to carry the row key, otherwise the drill
    " down opens the wrong transaction
    given_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the transaction is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `TCODE` )
        msg = 'the drill down does not carry the transaction of the row' ).
  ENDMETHOD.

  METHOD entry_keys_registered.
    given_list( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `Shift+F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } is not registered for Back| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F8`
                                    iv_event = `EXECUTE` )
        msg = 'F8 is not registered for the Display function' ).
  ENDMETHOD.

  METHOD entry_command_field.
    given_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD entry_back_leaves.
    " on the entry screen Back leaves the transaction
    mo_dbl->mv_prev_stack = abap_true.
    given_list( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'Back on the entry screen does not leave the transaction' ).
  ENDMETHOD.

  METHOD entry_status_bar.
    given_list( ).
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( |System { sy-sysid }| )
                                     ( |Client { sy-mandt }| ) )
                  iv_ctx  = `status bar` ).
  ENDMETHOD.

  METHOD entry_empty_is_sane.
    " no hit list yet - the screen still has to render
    mo_cut->mv_mode = `LIST`.
    mo_cut->view_display( ).

    assert_shell_sane( `SE93 entry screen without a hit list` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    given_list( ).
    mo_cut->mv_message = `42 transaction(s) displayed.`.
    mo_cut->mv_msgtype = `Success`.
    mo_cut->view_display( ).

    assert_shows( it_text = VALUE #( ( `42 transaction(s) displayed.` ) )
                  iv_ctx  = `status bar message` ).
  ENDMETHOD.

  " ===================== display screen, common =====================

  METHOD detail_is_sane.
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shell_sane( `SE93 display screen` ).
  ENDMETHOD.

  METHOD detail_title_has_type.
    " title TSH is 'Display $' and the original fills the placeholder with
    " RSSTCD-TC_TYPE
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Display Dialog Transaction` ) )
                  iv_ctx  = `display title` ).
  ENDMETHOD.

  METHOD detail_menu_small_c.
    " CUA menu bar 0007 of SHW_TCOD spells it with a small c, and the
    " capital spelling of the entry screen must not appear here
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Transaction code - the menu bar` ) )
                  iv_ctx  = `display menu bar` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view
                    sub = `Transaction Code - the menu bar` )
        msg = 'the display screen shows the menu title of the entry screen' ).
  ENDMETHOD.

  METHOD detail_common_rows.
    " D021T 0310: every display dynpro starts with these two
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Transaction code` )
                                     ( `Transaction text` )
                                     ( `SE93` )
                                     ( `Maintain Transaction Codes` ) )
                  iv_ctx  = `display header` ).
  ENDMETHOD.

  METHOD detail_start_options.
    " D021T 0310: the frame and its two checkboxes
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #(
        ( `Start Options` )
        ( `Transaction is locked (in transaction SM01 DEF)` )
        ( `Editing of standard transaction variant allowed` ) )
        iv_ctx = `start options` ).
  ENDMETHOD.

  METHOD report_no_trans_var.
    " D021T has RSSTCD-TRANS_VAR on dynpro 0310 only, so a report
    " transaction must not offer the standard transaction variant
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found     = abap_true
        tcode     = `SE16N`
        tc_type   = `Report Transaction`
        pgmna     = `RK_SE16N`
        dypno     = `1000`
        trans_var = abap_true ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #(
        ( `Start Options` )
        ( `Transaction is locked (in transaction SM01 DEF)` ) )
        iv_ctx = `report start options` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view
                    sub = `Editing of standard transaction variant allowed` )
        msg = 'a report transaction must not offer the transaction variant' ).
  ENDMETHOD.

  METHOD param_no_start_options.
    " dynpro 0330 frames its Default Values, not the start options, but it
    " does carry the SM01 lock flag
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found       = abap_true
        tc_type     = `Parameter Transaction`
        call_tcode  = `SM30`
        start_tcode = abap_true ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #(
        ( `Default Values` )
        ( `Transaction is locked (in transaction SM01 DEF)` ) )
        iv_ctx = `parameter start options` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `Start Options` )
        msg = 'dynpro 0330 has no Start Options frame' ).
  ENDMETHOD.

  METHOD detail_classification.
    " D021T 0370
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Classification` )
                                     ( `Transaction classification` )
                                     ( `Professional User Transaction` )
                                     ( `Easy Web Transaction` )
                                     ( `GUI support` )
                                     ( `SAP GUI for Windows` )
                                     ( `SAP GUI for Java` )
                                     ( `SAP GUI for HTML` ) )
                  iv_ctx  = `classification` ).
  ENDMETHOD.

  METHOD detail_toolbar_texts.
    " toolbar 0047 of SHW_TCOD, read from the CUA of SAPLSEUK
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Previous object` ) ( `Next object` )
                                     ( `Display &lt;-&gt; Change` )
                                     ( `Other object...` ) ( `Check` )
                                     ( `Where-used list` )
                                     ( `Display object list` )
                                     ( `Display navigation window` )
                                     ( `Full Screen` ) ( `Online manual` ) )
                  iv_ctx  = `display toolbar` ).
  ENDMETHOD.

  METHOD detail_back_to_entry.
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the display screen has no way back to the entry screen' ).
  ENDMETHOD.

  METHOD detail_f3_stays_inside.
    " F3 has to go back one screen, not leave the transaction
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `F3`
                                    iv_event = `BACK_TO_LIST` )
        msg = 'F3 leaves the transaction instead of going back one screen' ).
  ENDMETHOD.

  METHOD detail_auth_block.
    " title CHV 'Values of Check Object' with the DDIC labels of TSTCA
    DATA(ls) = detail_dialog( ).
    ls-auth_objct = `S_DEVELOP`.
    ls-auth = VALUE #( ( objct = `S_DEVELOP` field = `ACTVT` value = `03` )
                       ( objct = `S_DEVELOP` field = `OBJTYPE` value = `PROG` ) ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Values of Check Object` )
                                     ( `Authorization Object` )
                                     ( `S_DEVELOP` )
                                     ( `Field name` ) ( `Value` ) )
                  iv_ctx  = `check object` ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{FIELD}` ) >= 0 )
        msg = 'the check value columns are not bound' ).
  ENDMETHOD.

  METHOD detail_no_auth_no_box.
    " a transaction without a check object must not show an empty frame
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `Values of Check Object` )
        msg = 'the check object frame shows up without a check object' ).
  ENDMETHOD.

  " ================= display screen, one block per type =================

  METHOD type_dialog_block.
    " dynpro 0310
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Program` ) ( `Screen number` )
                                     ( `SAPLSEUK` ) ( `0390` ) )
                  iv_ctx  = `dialog block` ).
  ENDMETHOD.

  METHOD type_report_block.
    " dynpro 0320
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found     = abap_true
        tcode     = `/CFG/TRANS_HIST`
        tc_type   = `Report Transaction`
        pgmna     = `/CFG/BCLM_PROCESSOR_HISTORY`
        dypno     = `1000`
        repo_vari = `SAP&TRANS_HIST` ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Display Report Transaction` )
                                     ( `Program` ) ( `Selection screen` )
                                     ( `Start with variant` ) )
                  iv_ctx  = `report block` ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `Screen number` )
        msg = 'a report transaction must not show the dialog screen label' ).
  ENDMETHOD.

  METHOD type_object_block.
    " dynpro 0360
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found     = abap_true
        tcode     = `/CEEPS/CZDM03`
        tc_type   = `Object Transaction`
        pgmna     = `/CEEPS/CZDM_RECORDS`
        classname = `LCL_APPLICATION`
        method    = `RUN`
        s_local   = abap_true ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Display Object Transaction` )
                                     ( `Class` ) ( `Method` )
                                     ( `Local in program` )
                                     ( `LCL_APPLICATION` ) ( `RUN` ) )
                  iv_ctx  = `object block` ).
  ENDMETHOD.

  METHOD type_object_upd_mode.
    " dynpro 0360 shows the update mode only for the framework flavour
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found     = abap_true
        tc_type   = `Object Transaction`
        classname = `/ACCGO/CL_ADDON_BRF_CATALOG`
        method    = `LAUNCH_BRF_CATALOG`
        s_trframe = abap_true
        upd_mode  = `S` ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Update Mode` )
                                     ( `Synchronous update` ) )
                  iv_ctx  = `update mode` ).
  ENDMETHOD.

  METHOD type_variant_block.
    " dynpro 0331
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found      = abap_true
        tcode      = `/BOBF/LOG`
        tc_type    = `Variant Transaction`
        call_tcode = `SLG1`
        variant    = `/BOBF/LOG`
        s_ind_vari = abap_true ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Display Variant Transaction` )
                                     ( `Transaction variant` )
                                     ( `Cross-client` ) ( `SLG1` ) )
                  iv_ctx  = `variant block` ).
  ENDMETHOD.

  METHOD type_param_tcode_block.
    " dynpro 0330, the flavour that starts another transaction
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found       = abap_true
        tcode       = `/ACCGO/ABD_TYPE_SCEN`
        tc_type     = `Parameter Transaction`
        call_tcode  = `SM30`
        start_tcode = abap_true
        skip_first  = abap_true
        params      = VALUE #( ( field = `VIEWNAME` value = `/ACCGO/V_ABDTYPE` )
                               ( field = `UPDATE`   value = `X` ) ) ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `Display Parameter Transaction` )
                                     ( `Transaction` )
                                     ( `Skip initial screen` )
                                     ( `Default Values` )
                                     ( `Name of screen field` )
                                     ( `SM30` ) )
                  iv_ctx  = `parameter block` ).
  ENDMETHOD.

  METHOD type_param_prog_block.
    " dynpro 0330, the flavour that starts a program and screen
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found       = abap_true
        tc_type     = `Parameter Transaction`
        pgmna       = `SAPLSVIM`
        dypno       = `0100`
        start_tcode = abap_false ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shows( it_text = VALUE #( ( `From module pool` ) ( `Screen` )
                                     ( `SAPLSVIM` ) )
                  iv_ctx  = `parameter block on a program` ).
  ENDMETHOD.

  METHOD type_unknown_is_dialog.
    " an area menu carries no type at all in the original, and the display
    " then follows dynpro 0310
    DATA(ls) = VALUE zcl_zlk05_sys_api=>ty_s_tcode_detail(
        found   = abap_true
        tcode   = `SPRO`
        tc_type = ``
        pgmna   = `SAPLSPRO`
        dypno   = `0100` ).
    given_detail( ls ).
    mo_cut->view_detail( ).

    assert_shell_sane( `display screen without a transaction type` ).
    assert_shows( it_text = VALUE #( ( `Program` ) ( `Screen number` ) )
                  iv_ctx  = `fallback block` ).
  ENDMETHOD.

  " ====================== update mode mapping ======================

  METHOD upd_mode_synchronous.
    mo_cut->ms_detail-upd_mode = `S`.
    cl_abap_unit_assert=>assert_equals(
        exp = `Synchronous update`
        act = mo_cut->upd_mode_text( ) ).
  ENDMETHOD.

  METHOD upd_mode_asynchronous.
    mo_cut->ms_detail-upd_mode = `U`.
    cl_abap_unit_assert=>assert_equals(
        exp = `Asynchronous update`
        act = mo_cut->upd_mode_text( ) ).
  ENDMETHOD.

  METHOD upd_mode_local.
    mo_cut->ms_detail-upd_mode = `L`.
    cl_abap_unit_assert=>assert_equals(
        exp = `Local Update`
        act = mo_cut->upd_mode_text( ) ).
  ENDMETHOD.

  METHOD upd_mode_empty.
    " a transaction that is not an OO one carries no update mode
    CLEAR mo_cut->ms_detail-upd_mode.
    cl_abap_unit_assert=>assert_initial( mo_cut->upd_mode_text( ) ).
  ENDMETHOD.


  METHOD detail_test_wired.
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `TEST_TCODE` ) ).
  ENDMETHOD.

  METHOD detail_goto_wired.
    given_detail( detail_dialog( ) ).
    mo_cut->view_detail( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->has_event( `GOTO_PROGRAM` ) ).
  ENDMETHOD.

  METHOD detail_test_jumps.
    " SE93 is one of the transactions of this environment: Test starts it
    given_detail( detail_dialog( ) ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `TEST_TCODE`.
    mo_cut->on_event( ).
    IF mo_dbl->mv_nav_call IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial( mo_cut->mv_message ).
    ELSE.
      cl_abap_unit_assert=>assert_equals( exp = `ZCL_SE93_A2U5` act = mo_dbl->mv_nav_call ).
    ENDIF.
  ENDMETHOD.

  METHOD detail_goto_no_program.
    DATA(ls_detail) = detail_dialog( ).
    CLEAR ls_detail-pgmna.
    given_detail( ls_detail ).
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `GOTO_PROGRAM`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).
  ENDMETHOD.

ENDCLASS.
