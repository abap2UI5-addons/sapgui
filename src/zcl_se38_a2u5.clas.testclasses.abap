CLASS ltcl_se38_a2u5 DEFINITION DEFERRED.
CLASS zcl_se38_a2u5 DEFINITION LOCAL FRIENDS ltcl_se38_a2u5.

CLASS ltcl_se38_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_se38_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_hitlist.
    METHODS given_source_loaded.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS list_is_sane           FOR TESTING.
    METHODS list_original_title    FOR TESTING.
    METHODS list_selection_screen  FOR TESTING.
    METHODS list_has_gui_frame     FOR TESTING.
    METHODS list_subobjects_honest FOR TESTING.
    METHODS list_back_nav_wired    FOR TESTING.
    METHODS list_status_bar        FOR TESTING.
    METHODS list_empty_is_sane     FOR TESTING.
    METHODS message_reaches_view   FOR TESTING.

    METHODS source_is_sane         FOR TESTING.
    METHODS source_title           FOR TESTING.
    METHODS source_code_editor     FOR TESTING.
    METHODS source_is_read_only    FOR TESTING.
    METHODS source_back_to_list    FOR TESTING.
    METHODS source_has_gui_frame   FOR TESTING.
    METHODS source_repo_browser    FOR TESTING.

    METHODS start_opens_program    FOR TESTING.
    METHODS start_back_leaves      FOR TESTING.
    METHODS start_unknown_param    FOR TESTING.
ENDCLASS.


CLASS ltcl_se38_a2u5 IMPLEMENTATION.

  METHOD start_opens_program.
    " a jump from another transaction opens the program directly
    DATA(lv_pool) = CONV string( cl_oo_classname_service=>get_classpool_name( 'ZCL_SE38_A2U5' ) ).
    CAST zif_zlk05_start_params( mo_cut )->set_start_params(
        VALUE #( ( name = zif_zlk05_start_params=>c_program value = to_lower( lv_pool ) ) ) ).
    mo_dbl->mv_on_init = abap_true.
    CAST z2ui5_if_app( mo_cut )->main( mo_dbl ).

    IF mo_dbl->mv_view CS `No Authorization`.
      RETURN.   " the tester may not use SE38 at all - guarded, nothing opened
    ENDIF.
    IF mo_cut->mv_msgtype = `Error`.
      " the tester has no S_DEVELOP for the package - then the program must
      " NOT have been opened, which is the other half of the contract
      cl_abap_unit_assert=>assert_initial( mo_cut->mv_source ).
      RETURN.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `SOURCE` act = mo_cut->mv_mode ).
    cl_abap_unit_assert=>assert_true( mo_cut->mv_called ).
    cl_abap_unit_assert=>assert_equals( exp = lv_pool act = mo_cut->mv_current ).
  ENDMETHOD.

  METHOD start_back_leaves.
    " Back returns to the calling transaction, not to the SE38 list
    mo_cut->mv_called = abap_true.
    mo_cut->mv_mode   = `SOURCE`.
    mo_dbl->mv_on_event  = abap_true.
    mo_dbl->ms_get-event = `BACK_TO_LIST`.
    mo_cut->on_event( ).
    cl_abap_unit_assert=>assert_true( mo_dbl->mv_nav_leave ).
  ENDMETHOD.

  METHOD start_unknown_param.
    CAST zif_zlk05_start_params( mo_cut )->set_start_params(
        VALUE #( ( name = `SOMETHING_ELSE` value = `X` ) ) ).
    cl_abap_unit_assert=>assert_initial( mo_cut->mv_start_program ).
  ENDMETHOD.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD given_hitlist.
    mo_cut->mv_progname = `Z*`.
    mo_cut->mt_programs = VALUE #(
        ( name = `ZDEMO_REPORT` subc = `1` kind = `Executable Program`
          author = `DEVELOPER` chdate = `01.01.2024` package = `$ZLK_05` )
        ( name = `ZDEMO_INCLUDE` subc = `I` kind = `Include`
          author = `DEVELOPER` chdate = `01.01.2024` package = `$ZLK_05` ) ).
  ENDMETHOD.

  METHOD given_source_loaded.
    mo_cut->mv_mode    = `SOURCE`.
    mo_cut->mv_current = `ZDEMO_REPORT`.
    mo_cut->mv_source  = |REPORT zdemo_report.\n| &&
                         |WRITE / 'Hello'.\n|.
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
                                ( `footer` ) ( `OverflowToolbar` ) )
         INTO DATA(lv_container).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = mo_dbl->count_empty_elements( lv_container )
          msg = |{ iv_ctx }: <{ lv_container }> rendered without any child| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== initial screen =====================

  METHOD list_is_sane.
    given_hitlist( ).
    mo_cut->view_display( ).

    assert_shell_sane( `SE38 initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `ABAP Editor: Initial Screen` ) >= 0 )
        msg = 'the original SE38 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Program` ) >= 0 )
        msg = 'the Program field label is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idProgName` ) >= 0 )
        msg = 'the program input field is missing' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " the initial screen has to carry the six bands of the SAP GUI window:
    " menu bar, system bar with command field, title bar, application bar
    given_hitlist( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table(
        ( `Program` ) ( `Utilities` ) ( `Environment` )   " menu bar
        ( `ABAP Editor: Initial Screen` )                 " title bar
        ( `Debugging` ) ( `With Variant` ) ( `Variants` ) " application bar
        ( `Subobjects` ) ( `Source Code` )                " work area
        ( `Display` ) ( `Change` ) ( `Create` ) ) INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the initial screen does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_subobjects_honest.
    " only the source code can be read here. The other subobjects are shown
    " the SAP GUI way - present but disabled - never silently dropped.
    mo_cut->view_display( ).

    LOOP AT VALUE string_table(
        ( `Variants` ) ( `Attributes` ) ( `Text elements` ) ( `Documentation` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |subobject "{ lv_text }" was dropped instead of being disabled| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `enabled="false"` ) >= 0 )
        msg = 'nothing is disabled although the app cannot change the repository' ).
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_hitlist( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_hitlist( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0
                   AND find( val = mo_dbl->mv_view sub = |User { sy-uname }| ) >= 0 )
        msg = 'the status bar does not show system, client and user' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    CLEAR mo_cut->mt_programs.
    mo_cut->view_display( ).

    assert_shell_sane( `SE38 initial screen without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `Program ZUNKNOWN does not exist.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    " the classic status bar shows the message with a type icon, it has no
    " MessageStrip - that is a Fiori control the SAP GUI does not know
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Program ZUNKNOWN does not exist.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `sap-icon://error` ) >= 0 )
        msg = 'the error message is shown without the error icon' ).
  ENDMETHOD.

  " ===================== source display =====================

  METHOD source_is_sane.
    given_source_loaded( ).
    mo_cut->view_source( ).

    assert_shell_sane( `SE38 source display` ).
  ENDMETHOD.

  METHOD source_title.
    given_source_loaded( ).
    mo_cut->view_source( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `ABAP Editor: Display Report ZDEMO_REPORT` ) >= 0 )
        msg = 'the source display does not carry the original SE38 title' ).
  ENDMETHOD.

  METHOD source_code_editor.
    " the source has to render in the ABAP code editor with line numbers,
    " which is what makes it look like the SE38 editor
    given_source_loaded( ).
    mo_cut->view_source( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `CodeEditor` ) >= 0 )
        msg = 'the source is not rendered in a CodeEditor' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `sap.ui.codeeditor` ) >= 0 )
        msg = 'the sap.ui.codeeditor namespace is not declared - the view cannot load' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `lineNumbers` ) >= 0 )
        msg = 'line numbers are switched off' ).
  ENDMETHOD.

  METHOD source_is_read_only.
    " this app has no write path into the repository - the editor must stay
    " read-only and say so, instead of pretending the source can be changed
    given_source_loaded( ).
    mo_cut->view_source( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `editable="false"` ) >= 0 )
        msg = 'the code editor is editable although the app cannot save' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Display mode - source is read-only` ) >= 0 )
        msg = 'the read-only restriction is not stated in the status bar' ).
  ENDMETHOD.

  METHOD source_back_to_list.
    given_source_loaded( ).
    mo_cut->view_source( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the source display has no back navigation' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the source display leaves the app instead of returning to the list' ).
  ENDMETHOD.

  METHOD source_has_gui_frame.
    given_source_loaded( ).
    mo_cut->view_source( ).

    LOOP AT VALUE string_table(
        ( `Program` ) ( `Utilities` )                  " menu bar
        ( `ABAP Editor: Display Report` )               " title bar
        ( `Pattern` ) ( `Insert` ) ( `Replace` )
        ( `Undo` ) ( `Text Elements` )                  " application bar
        ( `Report` ) ( `Active` ) ( `Scope:` ) ) INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the source display does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD source_repo_browser.
    " the repository browser on the left navigates between the programs that
    " were found - it must be filled from the hit list, not invented
    given_hitlist( ).
    given_source_loaded( ).
    mo_cut->view_source( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Repository Browser` ) >= 0 )
        msg = 'the repository browser is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Object Name` ) >= 0 )
        msg = 'the repository browser has no object list' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{NAME}` ) >= 0 )
        msg = 'the object list is not bound to the programs that were found' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `NAME` )
        msg = 'clicking a program in the browser does not open it' ).
  ENDMETHOD.

ENDCLASS.
