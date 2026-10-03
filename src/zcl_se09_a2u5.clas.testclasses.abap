CLASS ltcl_se09_a2u5 DEFINITION DEFERRED.
CLASS zcl_se09_a2u5 DEFINITION LOCAL FRIENDS ltcl_se09_a2u5.

CLASS ltcl_se09_a2u5 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA mo_cut TYPE REF TO zcl_se09_a2u5.
    DATA mo_dbl TYPE REF TO zcl_zlk05_client_dbl.

    METHODS setup.
    METHODS given_requests.
    METHODS given_detail.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    " --- selection screen / request list ---
    METHODS list_is_sane           FOR TESTING.
    METHODS list_original_title    FOR TESTING.
    METHODS list_selection_screen  FOR TESTING.
    METHODS list_status_group      FOR TESTING.
    METHODS list_type_group        FOR TESTING.
    METHODS list_back_nav_wired    FOR TESTING.
    METHODS list_status_bar        FOR TESTING.
    METHODS list_has_gui_frame     FOR TESTING.
    METHODS list_keys_registered   FOR TESTING.
    METHODS list_command_field     FOR TESTING.
    METHODS list_drilldown_wired   FOR TESTING.
    METHODS list_columns_bound     FOR TESTING.
    METHODS list_unavailable_shown FOR TESTING.
    METHODS list_empty_is_sane     FOR TESTING.
    METHODS message_reaches_view   FOR TESTING.

    " --- Display Request/Task ---
    METHODS detail_is_sane         FOR TESTING.
    METHODS detail_original_title  FOR TESTING.
    METHODS detail_header_fields   FOR TESTING.
    METHODS detail_object_list     FOR TESTING.
    METHODS detail_parent_request  FOR TESTING.
    METHODS detail_back_to_list    FOR TESTING.
    METHODS detail_f3_stays_inside FOR TESTING.
    METHODS detail_has_gui_frame   FOR TESTING.

    " --- selection logic, free of any system access ---
    METHODS status_only_modifiable FOR TESTING.
    METHODS status_only_released   FOR TESTING.
    METHODS status_both_no_filter  FOR TESTING.
    METHODS type_workbench_only    FOR TESTING.
    METHODS type_customizing_only  FOR TESTING.
    METHODS type_copies_and_moves  FOR TESTING.
ENDCLASS.


CLASS ltcl_se09_a2u5 IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
    mo_cut->mv_user     = `DEVELOPER`.
    mo_cut->mv_mod      = abap_true.
    mo_cut->mv_typ_wb   = abap_true.
    mo_cut->mv_typ_cust = abap_true.
  ENDMETHOD.

  METHOD given_requests.
    mo_cut->mv_mode = `LIST`.
    mo_cut->mt_requests = VALUE #(
        ( trkorr = `S4HK900123` trfunction = `K` functxt = `Workbench Request`
          trstatus = `D` statustxt = `Modifiable` as4user = `DEVELOPER`
          as4date = `01.08.2026` as4time = `10:15:00` tarsystem = `S4P`
          as4text = `Transport Organizer app` )
        ( trkorr = `S4HK900124` trfunction = `S` functxt = `Development/Correction`
          trstatus = `D` statustxt = `Modifiable` as4user = `DEVELOPER`
          as4date = `01.08.2026` as4time = `10:16:00`
          as4text = `Task of the request` strkorr = `S4HK900123` ) ).
  ENDMETHOD.

  METHOD given_detail.
    given_requests( ).
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `S4HK900123`.
    mo_cut->mt_objects = VALUE #(
        ( pgmid = `R3TR` object = `CLAS` obj_name = `ZCL_SE09_A2U5` objfunc = `` )
        ( pgmid = `R3TR` object = `CLAS` obj_name = `ZCL_ZLK05_GUI_FRAME` objfunc = `` ) ).
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

  " ===================== selection screen / request list =====================

  METHOD list_is_sane.
    given_requests( ).
    mo_cut->view_display( ).

    assert_shell_sane( `Transport Organizer initial screen` ).
  ENDMETHOD.

  METHOD list_original_title.
    " RDDM0001 title INITIAL_SCREEN
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Transport Organizer` ) >= 0 )
        msg = 'the original SE09 screen title is missing' ).
  ENDMETHOD.

  METHOD list_selection_screen.
    " D021T 0220: the User field of the Transport Organizer
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `idUser` ) >= 0 )
        msg = 'the User input field is missing' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `User` ) >= 0 )
        msg = 'the User field label is missing' ).
  ENDMETHOD.

  METHOD list_status_group.
    " D021T 0220 %_AUTOTEXT045 plus the TRSTATUS texts of the two checkboxes
    given_requests( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Request Status` ) ( `Modifiable` )
                                ( `Released` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the Request Status group does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_type_group.
    " D021T 0220 %_AUTOTEXT052 plus the four data element texts REQ_WB,
    " REQ_CUST, REQ_COP and REQ_MOVE
    given_requests( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Request Type` ) ( `Workbench Requests` )
                                ( `Customizing Requests` )
                                ( `Transport of Copies` ) ( `Relocations` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the Request Type group does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_back_nav_wired.
    given_requests( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " F3 / back arrow returns to the calling app (SAP Easy Access)
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'the Back arrow of the system function bar is not wired to leave' ).
  ENDMETHOD.

  METHOD list_has_gui_frame.
    " menu bar and application function bar carry the original texts of the
    " Transport Organizer (RDDM0001)
    given_requests( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `Request` ) ( `Edit` ) ( `Goto` )
                                ( `Settings` ) ( `Environment` ) ( `System` )
                                ( `Help` ) ( `Display` )
                                ( `Display Selection` ) ( `Create...` )
                                ( `Find Requests` )
                                ( `Refresh Global Information` )
                                ( `Transport Organizer (Extended View)` )
                                ( `Further Settings...` )
                                ( `Get Standard Settings` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_keys_registered.
    given_requests( ).
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

  METHOD list_command_field.
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( zcl_zlk05_gui_frame=>c_ev_command )
        msg = 'the command field is not wired to the frame command event' ).
  ENDMETHOD.

  METHOD list_drilldown_wired.
    " the request number has to carry the row key, otherwise the drill down
    " opens the object list of the wrong request
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `DISPLAY` )
        msg = 'the drill down into the object list is not wired' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event_arg( `TRKORR` )
        msg = 'the drill down does not carry the request of the row' ).
  ENDMETHOD.

  METHOD list_columns_bound.
    " the hit list of the Transport Organizer shows request, type, status,
    " owner and short description - all bound to the API structure
    given_requests( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `{TRKORR}` ) ( `{FUNCTXT}` )
                                ( `{STATUSTXT}` ) ( `{AS4USER}` )
                                ( `{AS4TEXT}` ) )
         INTO DATA(lv_bind).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_bind ) >= 0 )
          msg = |the hit list column { lv_bind } is not bound| ).
    ENDLOOP.

    LOOP AT VALUE string_table( ( `Request/Task` ) ( `Type` ) ( `Status` )
                                ( `Owner` ) ( `Short Description` ) )
         INTO DATA(lv_head).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_head ) >= 0 )
          msg = |the column header "{ lv_head }" is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD list_unavailable_shown.
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'the disabled Transport Organizer functions do not explain themselves' ).
  ENDMETHOD.

  METHOD list_status_bar.
    given_requests( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |System { sy-sysid }| ) >= 0 )
        msg = 'the status bar does not show the system id' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = |Client { sy-mandt }| ) >= 0 )
        msg = 'the status bar does not show the client' ).
  ENDMETHOD.

  METHOD list_empty_is_sane.
    " on_init renders before any selection has run - the empty screen still
    " has to be a valid view, otherwise the app dies on startup
    CLEAR mo_cut->mt_requests.
    mo_cut->view_display( ).

    assert_shell_sane( `Transport Organizer without hits` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `No requests/tasks found for the selection.`.
    mo_cut->mv_msgtype = `Warning`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `No requests/tasks found for the selection.` ) >= 0 )
        msg = 'the message text never reaches the status bar' ).
  ENDMETHOD.

  " ===================== Display Request/Task =====================

  METHOD detail_is_sane.
    given_detail( ).
    mo_cut->view_detail( ).

    assert_shell_sane( `Display Request/Task` ).
  ENDMETHOD.

  METHOD detail_original_title.
    " SAPLSTR6 title 100 - the original carries no placeholder
    given_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Display Request/Task` ) >= 0 )
        msg = 'the display screen does not carry the original SAPLSTR6 title' ).
  ENDMETHOD.

  METHOD detail_header_fields.
    " D021T SAPLSTR6 0100 - the field texts of the original screen
    given_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `Request/task` ) ( `Request type` )
                                ( `Status` ) ( `Owner` ) ( `Last changed` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the header field "{ lv_text }" is missing| ).
    ENDLOOP.

    " and the values of the request that was chosen
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `S4HK900123` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `Workbench Request` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `DEVELOPER` ) >= 0 )
        msg = 'the header does not show the data of the chosen request' ).
  ENDMETHOD.

  METHOD detail_object_list.
    given_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `{PGMID}` ) ( `{OBJECT}` )
                                ( `{OBJ_NAME}` ) ( `{OBJFUNC}` ) )
         INTO DATA(lv_bind).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_bind ) >= 0 )
          msg = |the object list column { lv_bind } is not bound| ).
    ENDLOOP.

    " D021T SAPLSTR6 0200 plus the DDIC texts of E071
    LOOP AT VALUE string_table( ( `Object List` ) ( `Object Type` )
                                ( `Object Name` ) )
         INTO DATA(lv_head).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_head ) >= 0 )
          msg = |the object list header "{ lv_head }" is missing| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD detail_parent_request.
    " a task shows the request it belongs to - the original has the field
    " Parent Request for exactly that
    given_requests( ).
    mo_cut->mv_mode    = `DETAIL`.
    mo_cut->mv_current = `S4HK900124`.
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Parent Request` ) >= 0 )
        msg = 'a task does not show its parent request' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `S4HK900123` ) >= 0 )
        msg = 'the parent request number is missing' ).
  ENDMETHOD.

  METHOD detail_back_to_list.
    given_detail( ).
    mo_cut->view_detail( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `BACK_TO_LIST` )
        msg = 'the display screen has no back navigation to the selection' ).
    cl_abap_unit_assert=>assert_equals(
        exp = -1
        act = find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` )
        msg = 'the display screen leaves the app instead of returning to the list' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `sap-icon://nav-back` ) >= 0 )
        msg = 'the Back button is missing in the application function bar' ).
  ENDMETHOD.

  METHOD detail_f3_stays_inside.
    " F3 on a screen INSIDE the transaction has to go back one screen, not
    " leave the Transport Organizer
    given_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `F3` ) ( `F12` ) )
         INTO DATA(lv_key).
      cl_abap_unit_assert=>assert_true(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = `BACK_TO_LIST` )
          msg = |{ lv_key } does not return to the request list| ).
      cl_abap_unit_assert=>assert_false(
          act = mo_dbl->has_shortcut( iv_keys  = lv_key
                                      iv_event = zcl_zlk05_gui_frame=>c_ev_back )
          msg = |{ lv_key } leaves the transaction instead of the screen| ).
    ENDLOOP.
    " Shift+F3 is Exit in the SAP GUI - it leaves the transaction from
    " every one of its screens, not only one screen back
    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_shortcut( iv_keys  = `Shift+F3`
                                    iv_event = zcl_zlk05_gui_frame=>c_ev_exit )
        msg = 'Shift+F3 must leave the transaction' ).
  ENDMETHOD.

  METHOD detail_has_gui_frame.
    given_detail( ).
    mo_cut->view_detail( ).

    LOOP AT VALUE string_table( ( `Request` ) ( `Edit` ) ( `Goto` )
                                ( `Settings` ) ( `Environment` ) ( `Back` )
                                ( `Display Object` ) ( `Object Attributes` )
                                ( `Lock Overview` ) ( `Documentation` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the SAP GUI frame does not show "{ lv_text }"| ).
    ENDLOOP.
  ENDMETHOD.

  " ===================== selection logic =====================

  METHOD status_only_modifiable.
    mo_cut->mv_mod = abap_true.
    mo_cut->mv_rel = abap_false.

    cl_abap_unit_assert=>assert_equals(
        exp = `D`
        act = mo_cut->status_filter( )
        msg = 'Modifiable alone has to select TRSTATUS D' ).
  ENDMETHOD.

  METHOD status_only_released.
    mo_cut->mv_mod = abap_false.
    mo_cut->mv_rel = abap_true.

    cl_abap_unit_assert=>assert_equals(
        exp = `R`
        act = mo_cut->status_filter( )
        msg = 'Released alone has to select TRSTATUS R' ).
  ENDMETHOD.

  METHOD status_both_no_filter.
    " both checked - the original lists both groups, so no status filter
    mo_cut->mv_mod = abap_true.
    mo_cut->mv_rel = abap_true.

    cl_abap_unit_assert=>assert_initial(
        act = mo_cut->status_filter( )
        msg = 'both statuses checked must not filter on status' ).

    CLEAR: mo_cut->mv_mod, mo_cut->mv_rel.
    cl_abap_unit_assert=>assert_initial(
        act = mo_cut->status_filter( )
        msg = 'no status checked must not filter on status either' ).
  ENDMETHOD.

  METHOD type_workbench_only.
    mo_cut->mv_typ_wb   = abap_true.
    mo_cut->mv_typ_cust = abap_false.
    mo_cut->mv_typ_cop  = abap_false.
    mo_cut->mv_typ_move = abap_false.

    " K workbench request, S development/correction, R repair
    LOOP AT VALUE string_table( ( `K` ) ( `S` ) ( `R` ) ) INTO DATA(lv_fn).
      cl_abap_unit_assert=>assert_true(
          act = mo_cut->type_selected( lv_fn )
          msg = |TRFUNCTION { lv_fn } belongs to the workbench requests| ).
    ENDLOOP.

    " W customizing request, T transport of copies, O relocation
    LOOP AT VALUE string_table( ( `W` ) ( `Q` ) ( `T` ) ( `O` ) ) INTO lv_fn.
      cl_abap_unit_assert=>assert_false(
          act = mo_cut->type_selected( lv_fn )
          msg = |TRFUNCTION { lv_fn } must not pass the workbench filter| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD type_customizing_only.
    mo_cut->mv_typ_wb   = abap_false.
    mo_cut->mv_typ_cust = abap_true.
    mo_cut->mv_typ_cop  = abap_false.
    mo_cut->mv_typ_move = abap_false.

    cl_abap_unit_assert=>assert_true(
        act = mo_cut->type_selected( `W` )
        msg = 'a customizing request has to pass the customizing filter' ).
    cl_abap_unit_assert=>assert_true(
        act = mo_cut->type_selected( `Q` )
        msg = 'a customizing task has to pass the customizing filter' ).
    cl_abap_unit_assert=>assert_false(
        act = mo_cut->type_selected( `K` )
        msg = 'a workbench request must not pass the customizing filter' ).
  ENDMETHOD.

  METHOD type_copies_and_moves.
    mo_cut->mv_typ_wb   = abap_false.
    mo_cut->mv_typ_cust = abap_false.
    mo_cut->mv_typ_cop  = abap_true.
    mo_cut->mv_typ_move = abap_true.

    cl_abap_unit_assert=>assert_true(
        act = mo_cut->type_selected( `T` )
        msg = 'a transport of copies has to pass its own filter' ).
    LOOP AT VALUE string_table( ( `C` ) ( `E` ) ( `O` ) ) INTO DATA(lv_fn).
      cl_abap_unit_assert=>assert_true(
          act = mo_cut->type_selected( lv_fn )
          msg = |TRFUNCTION { lv_fn } is a relocation and has to pass| ).
    ENDLOOP.
    cl_abap_unit_assert=>assert_false(
        act = mo_cut->type_selected( `K` )
        msg = 'a workbench request must not pass here' ).
  ENDMETHOD.

ENDCLASS.
