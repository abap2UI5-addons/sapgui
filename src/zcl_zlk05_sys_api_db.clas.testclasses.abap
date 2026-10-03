" Reads against the database of the system the tests run on - the
" integration side of ZIF_ZLK05_SYS_API. They run on a system only;
" the transpiled unit tests leave the database layer out.

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
    METHODS rz11_api_delivers_parameters FOR TESTING.
    METHODS rz11_api_detail_is_original  FOR TESTING.
    METHODS rz11_api_unknown_is_reported FOR TESTING.
    METHODS stms_api_domain_is_read      FOR TESTING.
    METHODS stms_api_systems_are_read    FOR TESTING.
    METHODS sm04_api_delivers_self       FOR TESTING.
    METHODS sm30_kind_of_objects         FOR TESTING.
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
        act = zcl_zlk05_api_adm=>get_param_value( `rdisp/myname` )
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

  METHOD rz11_api_delivers_parameters.
    " TPFYPROPTY is empty on this system. The app must not show an empty
    " list that pretends there are no profile parameters - the values are
    " read from the kernel metadata instead.
    DATA(lt_par) = zcl_zlk05_sys_api=>search_parameters( iv_pattern = `rdisp/*` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lines( lt_par ) > 0 )
        msg = 'the parameter list is empty - the kernel metadata is not read' ).

    LOOP AT lt_par INTO DATA(ls_par) WHERE paraname CS `wp_no_dia`.
      cl_abap_unit_assert=>assert_not_initial(
          act = ls_par-value
          msg = 'the parameter value was not read from the kernel' ).
      cl_abap_unit_assert=>assert_not_initial(
          act = ls_par-ptype
          msg = 'the parameter type was not translated' ).
    ENDLOOP.
  ENDMETHOD.

  METHOD rz11_api_detail_is_original.
    " the attribute labels are the text elements of RSPFLDOC
    DATA(lt_kv) = zcl_zlk05_sys_api=>get_parameter_detail( `rdisp/wp_no_dia` ).

    LOOP AT VALUE string_table( ( `Name` ) ( `Value` ) ( `Resulting Source` )
                                ( `Type` ) ( `Parameter Group` )
                                ( `Parameter Description` ) ( `CSN Component` )
                                ( `System-Wide Parameter` ) ( `Dynamic Parameter` ) )
         INTO DATA(lv_label).
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( line_exists( lt_kv[ label = lv_label ] ) )
          msg = |the original RZ11 attribute "{ lv_label }" is missing| ).
    ENDLOOP.

    cl_abap_unit_assert=>assert_not_initial(
        act = lt_kv[ label = `Resulting Source` ]-value
        msg = 'the resulting source of the value is not determined' ).
  ENDMETHOD.

  METHOD rz11_api_unknown_is_reported.
    " an unknown parameter has to say so instead of showing nothing
    DATA(lt_kv) = zcl_zlk05_sys_api=>get_parameter_detail( `zzz/does_not_exist` ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lines( lt_kv ) > 0 )
        msg = 'an unknown parameter returns nothing at all' ).
    cl_abap_unit_assert=>assert_true(
        act = xsdbool( find( val = lt_kv[ label = `Value` ]-value
                             sub = `not known` ) >= 0 )
        msg = 'an unknown parameter is not reported as unknown' ).
  ENDMETHOD.

  METHOD stms_api_domain_is_read.
    zcl_zlk05_sys_api=>get_tms_domain(
      IMPORTING ev_domain  = DATA(lv_dom)
                ev_system  = DATA(lv_sys)
                ev_message = DATA(lv_msg) ).

    IF lv_msg IS INITIAL.
      cl_abap_unit_assert=>assert_not_initial(
          act = lv_dom
          msg = 'the transport domain of this system was not determined' ).
      cl_abap_unit_assert=>assert_equals(
          exp = CONV string( sy-sysid )
          act = lv_sys
          msg = 'the own system name does not match SY-SYSID' ).
    ELSE.
      " a system outside a transport domain is a valid state - but then it
      " has to be reported
      cl_abap_unit_assert=>assert_true(
          act = xsdbool( find( val = lv_msg sub = `transport domain` ) >= 0 )
          msg = 'a missing transport domain is not reported' ).
    ENDIF.
  ENDMETHOD.

  METHOD stms_api_systems_are_read.
    DATA(lt_sys) = zcl_zlk05_sys_api=>get_tms_systems( ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( lines( lt_sys ) > 0 )
        msg = 'no systems were read from TMSCSYS' ).

    cl_abap_unit_assert=>assert_true(
        act = xsdbool( line_exists( lt_sys[ sysnam = CONV string( sy-sysid ) ] ) )
        msg = 'the own system is missing in the system overview' ).
  ENDMETHOD.

  METHOD sm04_api_delivers_self.
    " the user running the test is logged on - the list is never empty,
    " unless the kernel refuses to deliver it, which must be reported
    zcl_zlk05_sys_api=>get_user_sessions( IMPORTING et_sessions = DATA(lt)
                                                    ev_message  = DATA(lv_msg) ).
    IF lv_msg IS NOT INITIAL.
      RETURN.
    ENDIF.
    cl_abap_unit_assert=>assert_not_initial( lt ).
  ENDMETHOD.

  METHOD sm30_kind_of_objects.
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-table
                                        act = zcl_zlk05_sys_api=>get_table_kind( `T000` ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-structure
                                        act = zcl_zlk05_sys_api=>get_table_kind( `BAPIRET2` ) ).
    cl_abap_unit_assert=>assert_equals( exp = zcl_zlk05_sys_api=>c_table_kind-none
                                        act = zcl_zlk05_sys_api=>get_table_kind( `ZZLK05_NONE` ) ).
  ENDMETHOD.

ENDCLASS.
