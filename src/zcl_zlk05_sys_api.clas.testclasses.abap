CLASS ltcl_helpers DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    METHODS pattern_escapes_underscore FOR TESTING.
    METHODS date_formats_parsed        FOR TESTING.
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
        zcl_zlk05_sys_api=>format_date( '00000000' ) ).
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

  METHOD pattern_escapes_underscore.
    " SAP_BC* must not find SAPXBC... - _ is a character of the name
    cl_abap_unit_assert=>assert_equals( exp = `SAP#_BC%`
                                        act = zcl_zlk05_sys_api=>to_like_pattern( `sap_bc*` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Z#_X%`
                                        act = zcl_zlk05_sys_api=>to_like_pattern( `Z_X` ) ).
    cl_abap_unit_assert=>assert_equals( exp = `A#%B_%`
                                        act = zcl_zlk05_sys_api=>to_like_pattern( `A%B+*` ) ).
  ENDMETHOD.

  METHOD date_formats_parsed.
    DATA(lv_def) = CONV d( '19990101' ).
    LOOP AT VALUE string_table( ( `20260201` ) ( `2026-02-01` ) ( `2026.02.01` ) ( `01.02.2026` ) )
         INTO DATA(lv_in).
      cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260201' )
                                          act = zcl_zlk05_sys_api=>parse_date( iv_in = lv_in iv_default = lv_def )
                                          msg = |{ lv_in } is not understood| ).
    ENDLOOP.
    LOOP AT VALUE string_table( ( `` ) ( `x` ) ( `20261399` ) ( `20260230` ) ( `2026020` ) )
         INTO lv_in.
      cl_abap_unit_assert=>assert_equals( exp = lv_def
                                          act = zcl_zlk05_sys_api=>parse_date( iv_in = lv_in iv_default = lv_def )
                                          msg = |{ lv_in } must fall back| ).
    ENDLOOP.
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
    METHODS method_include_found       FOR TESTING.
    METHODS method_include_unknown     FOR TESTING.
    METHODS function_include_found     FOR TESTING.
    METHODS auth_failures_own_user     FOR TESTING.
    METHODS auth_failures_unknown_user FOR TESTING.
    METHODS spool_status_like_sp01     FOR TESTING.
    METHODS spool_time_is_converted    FOR TESTING.
    METHODS spool_content_guarded      FOR TESTING.
    METHODS idoc_light_from_custom     FOR TESTING.
    METHODS idoc_detail_is_complete    FOR TESTING.
    METHODS idoc_detail_guarded        FOR TESTING.
    METHODS role_unknown_reported      FOR TESTING.
    METHODS role_search_is_filtered    FOR TESTING.
    METHODS messages_of_own_class      FOR TESTING.
    METHODS message_longtext_read      FOR TESTING.
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

  METHOD method_include_found.
    DATA(lv_incl) = zcl_zlk05_sys_api=>get_method_include( iv_class  = `zcl_zlk05_auth`
                                                          iv_method = `check_tcode` ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_incl exp = `ZCL_ZLK05_AUTH*CM*` ).
  ENDMETHOD.

  METHOD method_include_unknown.
    cl_abap_unit_assert=>assert_initial( zcl_zlk05_sys_api=>get_method_include(
        iv_class = `ZCL_ZLK05_AUTH` iv_method = `NO_SUCH_METHOD_X` ) ).
    cl_abap_unit_assert=>assert_initial( zcl_zlk05_sys_api=>get_method_include(
        iv_class = `` iv_method = `X` ) ).
  ENDMETHOD.

  METHOD function_include_found.
    " FUNCTION_EXISTS lives in group SUNI - include LSUNIUnn
    cl_abap_unit_assert=>assert_char_cp(
        act = zcl_zlk05_sys_api=>get_function_include( `function_exists` )
        exp = `L*U*` ).
    cl_abap_unit_assert=>assert_initial(
        zcl_zlk05_sys_api=>get_function_include( `Z_NO_SUCH_FUNCTION_X` ) ).
  ENDMETHOD.

  METHOD auth_failures_own_user.
    " the own checks are always readable: a list or 'No failed ...'
    zcl_zlk05_sys_api=>get_auth_failures( EXPORTING iv_bname   = ``
                                          IMPORTING et_fails   = DATA(lt_fails)
                                                    ev_message = DATA(lv_msg) ).
    IF lt_fails IS INITIAL.
      cl_abap_unit_assert=>assert_char_cp( act = lv_msg exp = `No failed*` ).
    ELSE.
      cl_abap_unit_assert=>assert_not_initial( lt_fails[ 1 ]-objct ).
    ENDIF.
  ENDMETHOD.

  METHOD auth_failures_unknown_user.
    zcl_zlk05_sys_api=>get_auth_failures( EXPORTING iv_bname   = `ZZ_NO_SUCH_USER_X`
                                          IMPORTING et_fails   = DATA(lt_fails)
                                                    ev_message = DATA(lv_msg) ).
    cl_abap_unit_assert=>assert_initial( lt_fails ).
    cl_abap_unit_assert=>assert_not_initial( lv_msg ).
  ENDMETHOD.

  METHOD spool_status_like_sp01.
    " the status column of SP01 (RSPO_RSTATUS_FOR_SPOOLREQ)
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( )
                                     IMPORTING ev_text = DATA(lv_text) ev_state = DATA(lv_state) ).
    cl_abap_unit_assert=>assert_equals( exp = `-` act = lv_text ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( rqwriter = 1 )
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `+` act = lv_text ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( rqpjreq = 1 rqpjdone = 1 )
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `Compl.`  act = lv_text ).
    cl_abap_unit_assert=>assert_equals( exp = `Success` act = lv_state ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( rqpjreq = 1 rqpjdone = 1 rqpjherr = 1 )
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = lv_text ).
    cl_abap_unit_assert=>assert_equals( exp = `Error` act = lv_state ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( rqpjreq = 2 rqpjdone = 2 rqpjserr = 2 )
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `Problem` act = lv_text ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01    = VALUE #( rqpjreq = 1 rqpjdone = 0 )
                                               iv_pjstatus = '3'
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `Waiting` act = lv_text ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01    = VALUE #( rqpjreq = 1 rqpjdone = 0 )
                                               iv_pjstatus = '7'
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `Printing` act = lv_text ).
    zcl_zlk05_api_ops=>spool_status( EXPORTING is_tsp01 = VALUE #( rqpjreq = 3 rqpjdone = 0 )
                                     IMPORTING ev_text = lv_text ev_state = lv_state ).
    cl_abap_unit_assert=>assert_equals( exp = `<F5>` act = lv_text ).
  ENDMETHOD.

  METHOD spool_time_is_converted.
    zcl_zlk05_api_ops=>spool_time_to_local( EXPORTING iv_stamp = '2026060112000000'
                                            IMPORTING ev_date  = DATA(lv_date)
                                                      ev_time  = DATA(lv_time) ).
    " UTC noon is still 1 June in every time zone between UTC-12 and UTC+11
    cl_abap_unit_assert=>assert_equals( exp = CONV d( '20260601' ) act = lv_date ).
    cl_abap_unit_assert=>assert_not_initial( lv_time ).
    zcl_zlk05_api_ops=>spool_time_to_local( EXPORTING iv_stamp = ''
                                            IMPORTING ev_date  = lv_date
                                                      ev_time  = lv_time ).
    cl_abap_unit_assert=>assert_initial( lv_date ).
  ENDMETHOD.

  METHOD spool_content_guarded.
    zcl_zlk05_sys_api=>get_spool_content( EXPORTING iv_rqident = `1;DROP`
                                          IMPORTING et_lines   = DATA(lt_lines)
                                                    ev_message = DATA(lv_msg) ).
    cl_abap_unit_assert=>assert_initial( lt_lines ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_msg exp = `*valid spool request*` ).
  ENDMETHOD.

  METHOD idoc_light_from_custom.
    " STACUST / STALIGHT of the system: 53 posted green, 51 error red,
    " 64 ready yellow - the traffic lights of WE02
    cl_abap_unit_assert=>assert_equals( exp = `Success` act = zcl_zlk05_api_ops=>idoc_status_state( '53' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Error`   act = zcl_zlk05_api_ops=>idoc_status_state( '51' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `Warning` act = zcl_zlk05_api_ops=>idoc_status_state( '64' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `None`    act = zcl_zlk05_api_ops=>idoc_status_state( 'XX' ) ).
    cl_abap_unit_assert=>assert_not_initial( zcl_zlk05_api_ops=>idoc_status_text( '53' ) ).
  ENDMETHOD.

  METHOD idoc_detail_is_complete.
    zcl_zlk05_sys_api=>get_idoc_detail( EXPORTING iv_docnum   = `56036`
                                        IMPORTING es_idoc     = DATA(ls_idoc)
                                                  et_control  = DATA(lt_control)
                                                  et_status   = DATA(lt_status)
                                                  et_segments = DATA(lt_segments)
                                                  ev_message  = DATA(lv_msg) ).
    IF lv_msg IS NOT INITIAL.
      " the user may not see this IDoc - that has to be said, not hidden
      cl_abap_unit_assert=>assert_char_cp( act = lv_msg exp = `*IDoc*` ).
      RETURN.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `56036` act = ls_idoc-docnum ).
    cl_abap_unit_assert=>assert_not_initial( lt_control ).
    cl_abap_unit_assert=>assert_not_initial( lt_status ).
    cl_abap_unit_assert=>assert_not_initial( lt_segments ).
    " newest status record first, it carries the current status
    cl_abap_unit_assert=>assert_equals( exp = ls_idoc-status act = lt_status[ 1 ]-status ).
  ENDMETHOD.

  METHOD idoc_detail_guarded.
    zcl_zlk05_sys_api=>get_idoc_detail( EXPORTING iv_docnum  = `12' OR '1`
                                        IMPORTING ev_message = DATA(lv_msg) ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_msg exp = `*valid IDoc number*` ).
  ENDMETHOD.

  METHOD role_unknown_reported.
    zcl_zlk05_sys_api=>get_role_detail( EXPORTING iv_role    = `ZZ_NO_SUCH_ROLE_X`
                                        IMPORTING ev_message = DATA(lv_msg) ).
    cl_abap_unit_assert=>assert_char_cp( act = lv_msg exp = `*does not exist*` ).
  ENDMETHOD.

  METHOD role_search_is_filtered.
    " whatever the search returns, it matches the pattern and has a type
    DATA(lt_roles) = zcl_zlk05_sys_api=>search_roles( iv_pattern = `SAP_BC_*` iv_max = 20 ).
    LOOP AT lt_roles INTO DATA(ls_role).
      cl_abap_unit_assert=>assert_char_cp( act = ls_role-agr_name exp = `SAP_BC_*` ).
      cl_abap_unit_assert=>assert_not_initial( ls_role-composite ).
    ENDLOOP.
  ENDMETHOD.

  METHOD messages_of_own_class.
    zcl_zlk05_sys_api=>get_messages( EXPORTING iv_arbgb   = `zlk05`
                                     IMPORTING et_head    = DATA(lt_head)
                                               et_msgs    = DATA(lt_msgs)
                                               ev_message = DATA(lv_msg) ).
    IF lv_msg IS NOT INITIAL.
      RETURN.
    ENDIF.
    cl_abap_unit_assert=>assert_equals( exp = `$ZLK_05`
                                        act = lt_head[ label = `Package` ]-value ).
    cl_abap_unit_assert=>assert_char_cp( act = lt_msgs[ msgnr = `028` ]-text exp = `*spool request*` ).
  ENDMETHOD.

  METHOD message_longtext_read.
    " 00 311 has an English long text in every system
    DATA(lt_lines) = zcl_zlk05_sys_api=>get_message_longtext( iv_arbgb = `00` iv_msgnr = `311` ).
    IF lt_lines IS INITIAL.
      " no S_DEVELOP for message class 00 - nothing may be shown then
      cl_abap_unit_assert=>assert_false(
          zcl_zlk05_auth=>check_message_class( `00` )-allowed ).
      RETURN.
    ENDIF.
    LOOP AT lt_lines INTO DATA(lv_line).
      cl_abap_unit_assert=>assert_equals( exp = -1 act = find( val = lv_line sub = `<(>` ) ).
    ENDLOOP.
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
