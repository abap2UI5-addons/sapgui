CLASS ltcl_st02 DEFINITION DEFERRED.
CLASS zcl_sapgui_st02 DEFINITION LOCAL FRIENDS ltcl_st02.

CLASS ltcl_st02 DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS teardown.
    DATA mo_cut TYPE REF TO zcl_sapgui_st02.
    DATA mo_dbl TYPE REF TO zcl_sapgui_client_dbl.

    METHODS setup.
    METHODS given_statistics.
    METHODS assert_shell_sane
      IMPORTING iv_ctx TYPE string.

    METHODS view_is_sane          FOR TESTING.
    METHODS view_original_title   FOR TESTING.
    METHODS view_instance_stated  FOR TESTING.
    METHODS view_refresh_wired    FOR TESTING.
    METHODS view_buffer_columns   FOR TESTING.
    METHODS view_memory_section   FOR TESTING.
    METHODS view_source_stated    FOR TESTING.
    METHODS view_back_nav_wired   FOR TESTING.
    METHODS view_empty_is_sane    FOR TESTING.
    METHODS message_reaches_view  FOR TESTING.
    METHODS view_has_gui_frame    FOR TESTING.
ENDCLASS.


CLASS ltcl_st02 IMPLEMENTATION.

  METHOD setup.
    zcl_sapgui_sys_api_dbl=>install( ).
    zcl_sapgui_auth_sys_dbl=>install( ).
    mo_cut = NEW #( ).
    mo_dbl = NEW #( ).
    mo_cut->client = mo_dbl.
  ENDMETHOD.

  METHOD teardown.
    zcl_sapgui_sys_api_dbl=>uninstall( ).
    zcl_sapgui_auth_sys_dbl=>uninstall( ).
  ENDMETHOD.

  METHOD given_statistics.
    mo_cut->mt_buffer = VALUE #(
        ( name = `Program` hitratio = `99,8` alloc_size = `450000`
          free_space = `120000` dir_used = `37000` dir_free = `13000`
          swaps = `0` db_access = `120000` )
        ( name = `Generic Key` hitratio = `92,1` alloc_size = `29000`
          free_space = `4000` dir_used = `3700` dir_free = `1300`
          swaps = `142` db_access = `88000` ) ).
    mo_cut->mt_memory = VALUE #(
        ( label = `Extended Memory Total`     value = `4096 MB` )
        ( label = `Extended Memory Available` value = `3120 MB` ) ).
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

  " ===================== tune summary =====================

  METHOD view_is_sane.
    given_statistics( ).
    mo_cut->view_display( ).

    assert_shell_sane( `ST02 tune summary` ).
  ENDMETHOD.

  METHOD view_original_title.
    given_statistics( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Tune Summary` ) >= 0 )
        msg = 'the original ST02 screen title is missing' ).
  ENDMETHOD.

  METHOD view_instance_stated.
    " buffer statistics are instance local
    given_statistics( ).
    mo_cut->view_display( ).

    " the instance is part of the original title - Tune Summary (&)
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = |Tune Summary ({ sy-host })| ) >= 0 )
        msg = 'the app does not state which instance the statistics belong to' ).
  ENDMETHOD.

  METHOD view_refresh_wired.
    given_statistics( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = mo_dbl->has_event( `REFRESH` )
        msg = 'the Refresh button is not wired to the REFRESH event' ).
  ENDMETHOD.

  METHOD view_buffer_columns.
    " hit ratio and swaps are the two numbers an administrator reads ST02 for
    given_statistics( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{HITRATIO}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{SWAPS}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{DB_ACCESS}` ) >= 0 )
        msg = 'the buffer table does not bind hit ratio, swaps and db accesses' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `HitRatio %` ) >= 0 )
        msg = 'the HitRatio column header is missing' ).
  ENDMETHOD.

  METHOD view_memory_section.
    " ST02 shows buffers AND memory - both tables have to render
    given_statistics( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `Key Figure` ) >= 0 )
        msg = 'the memory key figure table is missing' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `{LABEL}` ) >= 0
                   AND find( val = mo_dbl->mv_view sub = `{VALUE}` ) >= 0 )
        msg = 'the memory table is not bound to the key figure structure' ).
  ENDMETHOD.

  METHOD view_source_stated.
    " naming the function module makes the numbers verifiable
    given_statistics( ).
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `SAPTUNE_GET_SUMMARY_STATISTIC` ) >= 0 )
        msg = 'the data source of the statistics is not stated' ).
  ENDMETHOD.

  METHOD view_back_nav_wired.
    given_statistics( ).
    mo_dbl->mv_prev_stack = abap_true.
    mo_cut->view_display( ).

    " the yellow Back arrow of the system function bar carries the event
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view sub = `MOCK_NAV_LEAVE` ) >= 0 )
        msg = 'F3 back navigation to the calling app is not wired' ).
  ENDMETHOD.

  METHOD view_empty_is_sane.
    CLEAR: mo_cut->mt_buffer, mo_cut->mt_memory.
    mo_cut->view_display( ).

    assert_shell_sane( `ST02 tune summary without statistics` ).
  ENDMETHOD.

  METHOD message_reaches_view.
    mo_cut->mv_message = `Buffer statistics could not be read.`.
    mo_cut->mv_msgtype = `Error`.
    mo_cut->view_display( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `Buffer statistics could not be read.` ) >= 0 )
        msg = 'the message from the kernel call never reaches the status bar' ).
  ENDMETHOD.

  METHOD view_has_gui_frame.
    " menu bar and application function bar carry the original ST02 texts
    " of RSTUNE50 (RSMPTEXTS)
    given_statistics( ).
    mo_cut->view_display( ).

    LOOP AT VALUE string_table( ( `List` ) ( `Edit` ) ( `Goto` )
                                ( `Environment` ) ( `System` ) ( `Help` )
                                ( `Refresh` ) ( `Detail analysis` )
                                ( `Current parameters` ) )
         INTO DATA(lv_text).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = mo_dbl->mv_view sub = lv_text ) >= 0 )
          msg = |the original ST02 text '{ lv_text }' is missing| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = mo_dbl->mv_view
                             sub = `not available in this environment` ) >= 0 )
        msg = 'disabled original functions carry no explaining tooltip' ).
  ENDMETHOD.

ENDCLASS.
