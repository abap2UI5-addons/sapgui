CLASS ltcl_helpers DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS pattern_appends_wildcard  FOR TESTING.
    METHODS pattern_translates_star   FOR TESTING.
    METHODS pattern_translates_plus   FOR TESTING.
    METHODS pattern_empty_is_all      FOR TESTING.
    METHODS pattern_upcases           FOR TESTING.
    METHODS date_is_formatted         FOR TESTING.
    METHODS date_initial_stays_empty  FOR TESTING.
    METHODS time_is_formatted         FOR TESTING.
    METHODS flist_is_decoded          FOR TESTING.
    METHODS flist_garbage_is_survived FOR TESTING.
ENDCLASS.


CLASS ltcl_helpers IMPLEMENTATION.

  METHOD pattern_appends_wildcard.
    " A plain name must still match "starts with", like the SAP GUI does
    cl_abap_unit_assert=>assert_equals(
        exp = `MARA%`
        act = zcl_zlk05_sys_api=>to_like_pattern( `MARA` ) ).
  ENDMETHOD.

  METHOD pattern_translates_star.
    cl_abap_unit_assert=>assert_equals(
        exp = `MAR%`
        act = zcl_zlk05_sys_api=>to_like_pattern( `MAR*` ) ).
  ENDMETHOD.

  METHOD pattern_translates_plus.
    " + is the single character wildcard in the SAP GUI
    cl_abap_unit_assert=>assert_equals(
        exp = `MAR_`
        act = zcl_zlk05_sys_api=>to_like_pattern( `MAR+` ) ).
  ENDMETHOD.

  METHOD pattern_empty_is_all.
    cl_abap_unit_assert=>assert_equals(
        exp = `%`
        act = zcl_zlk05_sys_api=>to_like_pattern( `` ) ).
  ENDMETHOD.

  METHOD pattern_upcases.
    cl_abap_unit_assert=>assert_equals(
        exp = `MARA%`
        act = zcl_zlk05_sys_api=>to_like_pattern( `  mara ` ) ).
  ENDMETHOD.

  METHOD date_is_formatted.
    cl_abap_unit_assert=>assert_equals(
        exp = `30.07.2026`
        act = zcl_zlk05_sys_api=>format_date( '20260730' ) ).
  ENDMETHOD.

  METHOD date_initial_stays_empty.
    " An empty date must not be rendered as 00.00.0000
    cl_abap_unit_assert=>assert_initial(
        act = zcl_zlk05_sys_api=>format_date( '00000000' ) ).
  ENDMETHOD.

  METHOD time_is_formatted.
    cl_abap_unit_assert=>assert_equals(
        exp = `14:30:05`
        act = zcl_zlk05_sys_api=>format_time( '143005' ) ).
  ENDMETHOD.

  METHOD flist_is_decoded.
    " SNAP-FLIST is encoded as 2 char tag + 3 digit length + value
    DATA(lt_tags) = zcl_zlk05_sys_api=>parse_flist(
        `FC016LOAD_COMMON_PARTAP008SAPLROMUAL003878` ).

    cl_abap_unit_assert=>assert_equals(
        exp = `LOAD_COMMON_PART`
        act = VALUE #( lt_tags[ label = `FC` ]-value OPTIONAL )
        msg = 'the runtime error name was not decoded' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `SAPLROMU`
        act = VALUE #( lt_tags[ label = `AP` ]-value OPTIONAL )
        msg = 'the program name was not decoded' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `878`
        act = VALUE #( lt_tags[ label = `AL` ]-value OPTIONAL )
        msg = 'the source line was not decoded' ).
  ENDMETHOD.

  METHOD flist_garbage_is_survived.
    " A malformed length must stop the parser instead of looping or dumping
    zcl_zlk05_sys_api=>parse_flist( `FCXYZgarbage` ).
    zcl_zlk05_sys_api=>parse_flist( `FC999short` ).
    zcl_zlk05_sys_api=>parse_flist( `AB` ).
    cl_abap_unit_assert=>assert_true( abap_true ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_system_reads DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS clients_contain_own_client FOR TESTING.
    METHODS ddic_search_finds_table    FOR TESTING.
    METHODS table_fields_have_key      FOR TESTING.
    METHODS class_search_finds_itself  FOR TESTING.
    METHODS function_search_finds_fm   FOR TESTING.
    METHODS parameter_has_live_value   FOR TESTING.
    METHODS dtel_detail_is_filled      FOR TESTING.
ENDCLASS.


CLASS ltcl_system_reads IMPLEMENTATION.

  METHOD clients_contain_own_client.
    DATA(lt_clients) = zcl_zlk05_sys_api=>get_clients( ).

    cl_abap_unit_assert=>assert_not_initial(
        act = lt_clients
        msg = 'T000 must at least contain the current client' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_clients[ mandt = CONV string( sy-mandt ) ] ) )
        msg = 'the logon client is missing from the client list' ).
  ENDMETHOD.

  METHOD ddic_search_finds_table.
    DATA(lt_obj) = zcl_zlk05_sys_api=>search_ddic( iv_pattern = `MARA`
                                                   iv_kind    = `TABL` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_obj[ name = `MARA` ] ) )
        msg = 'MARA was not found by the dictionary search' ).
  ENDMETHOD.

  METHOD table_fields_have_key.
    DATA(lt_fields) = zcl_zlk05_sys_api=>get_table_fields( `MARA` ).

    cl_abap_unit_assert=>assert_not_initial(
        act = lt_fields
        msg = 'MARA must have a field list' ).

    READ TABLE lt_fields INTO DATA(ls_matnr) WITH KEY fieldname = `MATNR`.
    cl_abap_unit_assert=>assert_subrc(
        exp = 0
        msg = 'MATNR is missing from the MARA field list' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `X`
        act = ls_matnr-keyflag
        msg = 'MATNR must be flagged as a key field' ).
    " The .INCLUDE placeholders of DD03L must never reach the UI
    cl_abap_unit_assert=>assert_false(
        act = xsdbool( line_exists( lt_fields[ fieldname = `.INCLUDE` ] ) )
        msg = 'the .INCLUDE placeholder leaked into the field list' ).
  ENDMETHOD.

  METHOD class_search_finds_itself.
    DATA(lt_cls) = zcl_zlk05_sys_api=>search_classes( `ZCL_ZLK05_SYS_API` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_cls[ clsname = `ZCL_ZLK05_SYS_API` ] ) )
        msg = 'the class search does not find this very class' ).
  ENDMETHOD.

  METHOD function_search_finds_fm.
    DATA(lt_fm) = zcl_zlk05_sys_api=>search_functions( `TH_WPINFO` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_fm[ funcname = `TH_WPINFO` ] ) )
        msg = 'TH_WPINFO was not found by the function search' ).
  ENDMETHOD.

  METHOD parameter_has_live_value.
    " rdisp/myname is always set on a running instance - proves that the
    " value really comes from the kernel and not only from TPFYPROPTY
    cl_abap_unit_assert=>assert_not_initial(
        act = zcl_zlk05_sys_api=>get_param_value( `rdisp/myname` )
        msg = 'no live value was read for rdisp/myname' ).
  ENDMETHOD.

  METHOD dtel_detail_is_filled.
    DATA(lt_kv) = zcl_zlk05_sys_api=>get_dtel_detail( `MATNR` ).

    cl_abap_unit_assert=>assert_not_initial(
        act = lt_kv
        msg = 'no attributes were read for data element MATNR' ).
    cl_abap_unit_assert=>assert_equals(
        exp = `MATNR`
        act = VALUE #( lt_kv[ label = `Data Element` ]-value OPTIONAL ) ).
  ENDMETHOD.

ENDCLASS.


CLASS ltcl_app_views DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    " Every app of the package must render one well formed view on start-up.
    METHODS every_app_renders_valid_xml FOR TESTING.
    METHODS every_app_has_single_root   FOR TESTING.
    METHODS no_app_has_empty_container  FOR TESTING.

    METHODS app_classes
      RETURNING VALUE(result) TYPE string_table.

    METHODS render
      IMPORTING iv_class      TYPE string
      RETURNING VALUE(result) TYPE REF TO zcl_zlk05_client_dbl.
ENDCLASS.


CLASS ltcl_app_views IMPLEMENTATION.

  METHOD app_classes.
    result = VALUE #(
      ( `ZCL_SE11_A2U5` ) ( `ZCL_SE24_A2U5` ) ( `ZCL_SE37_A2U5` )
      ( `ZCL_SE38_A2U5` ) ( `ZCL_SM37_A2U5` ) ( `ZCL_ST22_A2U5` )
      ( `ZCL_SU01_A2U5` ) ( `ZCL_SM12_A2U5` ) ( `ZCL_SCC4_A2U5` )
      ( `ZCL_RZ11_A2U5` ) ( `ZCL_SM50_A2U5` ) ( `ZCL_ST02_A2U5` )
      ( `ZCL_STMS_A2U5` ) ( `ZCL_SM21_A2U5` ) ( `ZCL_ST05_A2U5` ) ).
  ENDMETHOD.

  METHOD render.
    result = NEW zcl_zlk05_client_dbl( ).
    result->mv_on_init = abap_true.

    DATA lo_app TYPE REF TO z2ui5_if_app.
    CREATE OBJECT lo_app TYPE (iv_class).
    lo_app->main( result ).
  ENDMETHOD.

  METHOD every_app_renders_valid_xml.
    LOOP AT app_classes( ) INTO DATA(lv_class).
      DATA(lo_dbl) = render( lv_class ).

      cl_abap_unit_assert=>assert_not_initial(
          act = lo_dbl->mv_view
          msg = |{ lv_class } did not render a view at all| ).
      cl_abap_unit_assert=>assert_initial(
          act = lo_dbl->get_xml_errors( )
          msg = |{ lv_class } renders XML that is not well formed| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD every_app_has_single_root.
    " More than one root element was a real defect in this package before
    LOOP AT app_classes( ) INTO DATA(lv_class).
      DATA(lo_dbl) = render( lv_class ).

      cl_abap_unit_assert=>assert_true(
          act = xsdbool( lo_dbl->get_root_name( ) CS `View` )
          msg = |{ lv_class } must have exactly one View root element| ).
    ENDLOOP.
  ENDMETHOD.

  METHOD no_app_has_empty_container.
    " An empty toolbar/columns/cells container is the fingerprint of a
    " dropped open( ) return value - the children ended up as siblings.
    LOOP AT app_classes( ) INTO DATA(lv_class).
      DATA(lo_dbl) = render( lv_class ).

      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = lo_dbl->count_empty_elements( `OverflowToolbar` )
          msg = |{ lv_class } renders an empty OverflowToolbar| ).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = lo_dbl->count_empty_elements( `columns` )
          msg = |{ lv_class } renders an empty columns aggregation| ).
      cl_abap_unit_assert=>assert_equals(
          exp = 0
          act = lo_dbl->count_empty_elements( `cells` )
          msg = |{ lv_class } renders an empty cells aggregation| ).
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
