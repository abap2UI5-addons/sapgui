*"* use this source file for your ABAP unit test classes

CLASS ltcl_router DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.

    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.

    " ----- command field syntax -----
    METHODS cmd_plain            FOR TESTING.
    METHODS cmd_slash_prefixes   FOR TESTING.
    METHODS cmd_case_and_spaces  FOR TESTING.

    " ----- registry -----
    METHODS registry_keys_unique FOR TESTING.
    METHODS favorites_are_known  FOR TESTING.
    METHODS every_app_class_runs FOR TESTING.

    " ----- dispatching -----
    METHODS run_starts_app       FOR TESTING.
    METHODS run_empty_command    FOR TESTING.
    METHODS run_unknown_tcode    FOR TESTING.
    METHODS run_listed_no_app    FOR TESTING.
    METHODS run_session_command  FOR TESTING.
    METHODS run_without_client   FOR TESTING.

ENDCLASS.


CLASS ltcl_router IMPLEMENTATION.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_dbl = NEW #( ).
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD cmd_plain.
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = zcl_sapgui_router=>normalize_command( `SE80` ) ).
  ENDMETHOD.

  METHOD cmd_slash_prefixes.
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = zcl_sapgui_router=>normalize_command( `/nSE80` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = zcl_sapgui_router=>normalize_command( `/oSE80` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE80` act = zcl_sapgui_router=>normalize_command( `/SE80` ) ).
  ENDMETHOD.

  METHOD cmd_case_and_spaces.
    cl_abap_unit_assert=>assert_equals(
        exp = `SE16N` act = zcl_sapgui_router=>normalize_command( `  se16n  ` ) ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SE16N` act = zcl_sapgui_router=>normalize_command( `/n se16n` ) ).
  ENDMETHOD.

  METHOD registry_keys_unique.

    DATA(lt_apps) = zcl_sapgui_router=>get_apps( ).
    DATA lt_seen TYPE string_table.

    LOOP AT lt_apps INTO DATA(ls_app).
      cl_abap_unit_assert=>assert_false(
          act = xsdbool( line_exists( lt_seen[ table_line = ls_app-tcode ] ) )
          msg = |transaction { ls_app-tcode } is listed twice| ).
      APPEND ls_app-tcode TO lt_seen.

      cl_abap_unit_assert=>assert_not_initial(
          act = ls_app-text msg = |transaction { ls_app-tcode } has no text| ).
    ENDLOOP.

  ENDMETHOD.

  METHOD favorites_are_known.

    DATA(lt_apps) = zcl_sapgui_router=>get_apps( ).

    LOOP AT zcl_sapgui_router=>get_favorites( ) INTO DATA(ls_fav).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( lt_apps[ tcode = ls_fav-tcode ] ) )
          msg = |favorite { ls_fav-tcode } is not in the transaction list| ).
    ENDLOOP.

  ENDMETHOD.

  METHOD every_app_class_runs.

    " every implementing class must exist and be an abap2UI5 app
    LOOP AT zcl_sapgui_router=>get_apps( ) INTO DATA(ls_app)
         WHERE class IS NOT INITIAL.

      mo_dbl->reset( ).
      DATA(ls_run) = zcl_sapgui_router=>run(
          iv_command = ls_app-tcode
          io_client  = mo_dbl ).

      cl_abap_unit_assert=>assert_equals(
          exp = zcl_sapgui_router=>c_nav
          act = ls_run-outcome
          msg = |transaction { ls_app-tcode } does not start { ls_app-class }| ).

      cl_abap_unit_assert=>assert_equals(
          exp = ls_app-class
          act = mo_dbl->mv_nav_call
          msg = |transaction { ls_app-tcode } started the wrong app| ).
    ENDLOOP.

  ENDMETHOD.

  METHOD run_starts_app.

    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = `/nse38`
        io_client  = mo_dbl ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_sapgui_router=>c_nav
                                        act = ls_run-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SAPGUI_SE38`
                                        act = mo_dbl->mv_nav_call ).
    cl_abap_unit_assert=>assert_initial( ls_run-message ).

  ENDMETHOD.

  METHOD run_empty_command.

    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = ``
        io_client  = mo_dbl ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_sapgui_router=>c_msg
                                        act = ls_run-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = ls_run-msg_type ).
    cl_abap_unit_assert=>assert_not_initial( ls_run-message ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).

  ENDMETHOD.

  METHOD run_unknown_tcode.

    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = `ZZ_NO_SUCH_TCODE`
        io_client  = mo_dbl ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_sapgui_router=>c_msg
                                        act = ls_run-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = ls_run-msg_type ).
    cl_abap_unit_assert=>assert_char_cp( act = ls_run-message exp = `*does not exist*` ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).

  ENDMETHOD.

  METHOD run_listed_no_app.

    " A transaction that is listed but has no app must be answered, not
    " silently ignored. The examples come from the list itself: a fixed
    " transaction code stops testing the day it gets its app, and nobody
    " notices because the test still turns green.
    DATA(lt_apps) = zcl_sapgui_router=>get_apps( ).

    LOOP AT lt_apps INTO DATA(ls_app) WHERE class IS INITIAL.
      mo_dbl->reset( ).

      DATA(ls_run) = zcl_sapgui_router=>run(
          iv_command = ls_app-tcode
          io_client  = mo_dbl ).

      cl_abap_unit_assert=>assert_equals(
          exp = zcl_sapgui_router=>c_msg
          act = ls_run-outcome
          msg = |{ ls_app-tcode } is listed without an app and must answer| ).
      cl_abap_unit_assert=>assert_equals(
          exp = `Warning`
          act = ls_run-msg_type
          msg = |{ ls_app-tcode } must be answered with a warning| ).
      cl_abap_unit_assert=>assert_char_cp(
          act = ls_run-message
          exp = `*not available*`
          msg = |{ ls_app-tcode } must say that it is not available here| ).
      cl_abap_unit_assert=>assert_initial(
          act = mo_dbl->mv_nav_call
          msg = |{ ls_app-tcode } must not navigate anywhere| ).
    ENDLOOP.

  ENDMETHOD.

  METHOD run_session_command.

    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = `/o`
        io_client  = mo_dbl ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_sapgui_router=>c_msg
                                        act = ls_run-outcome ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = ls_run-msg_type ).
    cl_abap_unit_assert=>assert_char_cp( act = ls_run-message exp = `*session*` ).
    cl_abap_unit_assert=>assert_initial( mo_dbl->mv_nav_call ).

  ENDMETHOD.

  METHOD run_without_client.

    DATA(ls_run) = zcl_sapgui_router=>run(
        iv_command = `SE38`
        io_client  = VALUE #( ) ).

    cl_abap_unit_assert=>assert_equals( exp = zcl_sapgui_router=>c_none
                                        act = ls_run-outcome ).

  ENDMETHOD.

ENDCLASS.
