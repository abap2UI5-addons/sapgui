*"* use this source file for your ABAP unit test classes

CLASS ltcl_se80_api DEFINITION DEFERRED.
CLASS zcl_se80_api DEFINITION LOCAL FRIENDS ltcl_se80_api.

" The Object Navigator API is the only class of $ZLK_05 that can change the
" repository. These tests pin the write protection: while c_write_enabled is
" off, NO changing method may do anything - and they must say why.
" All tests are read-only against the system: the names used for create /
" copy / rename do not exist and are checked to still not exist afterwards.

CLASS ltcl_se80_api DEFINITION FINAL FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.

    CONSTANTS c_no_obj TYPE sobj_name VALUE 'ZZLK05_NEVER_CREATED'.

    DATA mo_cut TYPE REF TO zcl_se80_api.

    METHODS setup.
    METHODS assert_refused
      IMPORTING is_result TYPE zcl_se80_api=>ty_s_result
                iv_what   TYPE string.
    METHODS assert_not_in_tadir
      IMPORTING iv_name TYPE sobj_name.

    " ----- write protection -----
    METHODS write_switch_is_off      FOR TESTING.
    METHODS save_refused             FOR TESTING.
    METHODS activate_refused         FOR TESTING.
    METHODS delete_refused           FOR TESTING.
    METHODS create_program_refused   FOR TESTING.
    METHODS create_class_refused     FOR TESTING.
    METHODS create_interface_refused FOR TESTING.
    METHODS copy_refused             FOR TESTING.
    METHODS rename_refused           FOR TESTING.
    METHODS transport_refused        FOR TESTING.

    " ----- S_DEVELOP key -----
    METHODS develop_key_of_class     FOR TESTING.
    METHODS develop_key_unknown      FOR TESTING.

    " ----- reading -----
    METHODS load_own_class           FOR TESTING.
    METHODS table_content_limited    FOR TESTING.

    " ----- pure helpers -----
    METHODS replace_counts           FOR TESTING.
    METHODS replace_empty_search     FOR TESTING.
    METHODS statistics_lines         FOR TESTING.
    METHODS statistics_empty         FOR TESTING.
    METHODS icon_known_and_default   FOR TESTING.

ENDCLASS.


CLASS ltcl_se80_api IMPLEMENTATION.

  METHOD setup.
    mo_cut = NEW #( ).
  ENDMETHOD.

  METHOD assert_refused.
    cl_abap_unit_assert=>assert_false(
        act = is_result-success
        msg = |{ iv_what } must be refused while the API is read-only| ).
    cl_abap_unit_assert=>assert_char_cp(
        act = is_result-message
        exp = `*read-only*`
        msg = |{ iv_what } must tell the user that the API is read-only| ).
  ENDMETHOD.

  METHOD assert_not_in_tadir.
    SELECT SINGLE @abap_true FROM tadir
      WHERE pgmid = 'R3TR' AND obj_name = @iv_name
      INTO @DATA(lv_found).
    cl_abap_unit_assert=>assert_false(
        act = lv_found
        msg = |{ iv_name } must not have been created| ).
  ENDMETHOD.

  METHOD write_switch_is_off.
    " Switching the Object Navigator to change mode is a deliberate decision.
    " When it is made, this test has to be changed together with it.
    cl_abap_unit_assert=>assert_false( zcl_se80_api=>c_write_enabled ).
  ENDMETHOD.

  METHOD save_refused.
    assert_refused(
        is_result = mo_cut->save_source( iv_name   = 'ZCL_SE80_API'
                                         iv_type   = 'CLAS'
                                         iv_source = `CLASS x DEFINITION. ENDCLASS.` )
        iv_what   = `save_source` ).
  ENDMETHOD.

  METHOD activate_refused.
    assert_refused(
        is_result = mo_cut->activate_object( iv_name = 'ZCL_SE80_API' iv_type = 'CLAS' )
        iv_what   = `activate_object` ).
  ENDMETHOD.

  METHOD delete_refused.
    assert_refused(
        is_result = mo_cut->delete_object( iv_name = c_no_obj iv_type = 'PROG' )
        iv_what   = `delete_object` ).
  ENDMETHOD.

  METHOD create_program_refused.
    assert_refused(
        is_result = mo_cut->create_program( iv_name = c_no_obj iv_package = '$ZLK_05' )
        iv_what   = `create_program` ).
    assert_not_in_tadir( c_no_obj ).
  ENDMETHOD.

  METHOD create_class_refused.
    assert_refused(
        is_result = mo_cut->create_class( iv_name = c_no_obj iv_package = '$ZLK_05' )
        iv_what   = `create_class` ).
    assert_not_in_tadir( c_no_obj ).
  ENDMETHOD.

  METHOD create_interface_refused.
    assert_refused(
        is_result = mo_cut->create_interface( iv_name = c_no_obj iv_package = '$ZLK_05' )
        iv_what   = `create_interface` ).
    assert_not_in_tadir( c_no_obj ).
  ENDMETHOD.

  METHOD copy_refused.
    assert_refused(
        is_result = mo_cut->copy_object( iv_source_name = 'ZCL_SE80_API'
                                         iv_source_type = 'CLAS'
                                         iv_target_name = c_no_obj
                                         iv_package     = '$ZLK_05' )
        iv_what   = `copy_object` ).
    assert_not_in_tadir( c_no_obj ).
  ENDMETHOD.

  METHOD rename_refused.
    assert_refused(
        is_result = mo_cut->rename_object( iv_old_name = 'ZCL_SE80_API'
                                           iv_new_name = c_no_obj
                                           iv_type     = 'CLAS' )
        iv_what   = `rename_object` ).
    assert_not_in_tadir( c_no_obj ).
  ENDMETHOD.

  METHOD transport_refused.
    assert_refused(
        is_result = mo_cut->lock_in_transport( iv_name      = 'ZCL_SE80_API'
                                               iv_type      = 'CLAS'
                                               iv_transport = 'S4HK900000' )
        iv_what   = `lock_in_transport` ).
  ENDMETHOD.

  METHOD develop_key_of_class.
    mo_cut->develop_key( EXPORTING iv_name    = 'zcl_se80_api'
                                   iv_type    = 'clas'
                         IMPORTING ev_package = DATA(lv_package)
                                   ev_objtype = DATA(lv_objtype)
                                   ev_objname = DATA(lv_objname) ).
    cl_abap_unit_assert=>assert_equals( exp = `$ZLK_05`      act = lv_package ).
    cl_abap_unit_assert=>assert_equals( exp = `CLAS`         act = lv_objtype ).
    cl_abap_unit_assert=>assert_equals( exp = `ZCL_SE80_API` act = lv_objname ).
  ENDMETHOD.

  METHOD develop_key_unknown.
    mo_cut->develop_key( EXPORTING iv_name    = c_no_obj
                                   iv_type    = 'PROG'
                         IMPORTING ev_package = DATA(lv_package) ).
    cl_abap_unit_assert=>assert_initial( lv_package ).
  ENDMETHOD.

  METHOD load_own_class.
    " the developer running the tests has S_DEVELOP display for the package
    " the class lives in - otherwise he could not have written it
    DATA(ls) = mo_cut->load_source( iv_name = 'ZCL_SE80_API' iv_type = 'CLAS' ).
    cl_abap_unit_assert=>assert_char_cp( act = ls-source exp = `*c_write_enabled*` ).
  ENDMETHOD.

  METHOD table_content_limited.
    " T000 always has at least one client - the preview must respect maxrows
    DATA(lv) = mo_cut->get_table_content( iv_name = 'T000' iv_maxrows = 1 ).
    cl_abap_unit_assert=>assert_not_initial( lv ).
    IF lv CP `*not authorized*`.
      RETURN.
    ENDIF.
    cl_abap_unit_assert=>assert_char_cp( act = lv exp = `*1 rows (max 1)*` ).
  ENDMETHOD.

  METHOD replace_counts.
    mo_cut->search_replace_source( EXPORTING iv_source  = `a b a c a`
                                             iv_search  = `a`
                                             iv_replace = `x`
                                   IMPORTING ev_source  = DATA(lv_src)
                                             ev_count   = DATA(lv_cnt) ).
    cl_abap_unit_assert=>assert_equals( exp = `x b x c x` act = lv_src ).
    cl_abap_unit_assert=>assert_equals( exp = 3 act = lv_cnt ).
  ENDMETHOD.

  METHOD replace_empty_search.
    mo_cut->search_replace_source( EXPORTING iv_source  = `abc`
                                             iv_search  = ``
                                             iv_replace = `x`
                                   IMPORTING ev_source  = DATA(lv_src)
                                             ev_count   = DATA(lv_cnt) ).
    cl_abap_unit_assert=>assert_equals( exp = `abc` act = lv_src ).
    cl_abap_unit_assert=>assert_equals( exp = 0 act = lv_cnt ).
  ENDMETHOD.

  METHOD statistics_lines.
    DATA(nl) = cl_abap_char_utilities=>newline.
    DATA(lt) = mo_cut->get_source_statistics(
        |REPORT z.{ nl }* comment{ nl }{ nl }  " also comment{ nl }WRITE 1.| ).
    cl_abap_unit_assert=>assert_equals( exp = `5` act = condense( lt[ name = `Total Lines` ]-type ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2` act = condense( lt[ name = `Code Lines` ]-type ) ).
    cl_abap_unit_assert=>assert_equals( exp = `2` act = condense( lt[ name = `Comments` ]-type ) ).
    cl_abap_unit_assert=>assert_equals( exp = `1` act = condense( lt[ name = `Blank Lines` ]-type ) ).
  ENDMETHOD.

  METHOD statistics_empty.
    cl_abap_unit_assert=>assert_initial( mo_cut->get_source_statistics( `` ) ).
  ENDMETHOD.

  METHOD icon_known_and_default.
    cl_abap_unit_assert=>assert_equals( exp = `sap-icon://course-book`
                                        act = mo_cut->get_object_icon( 'CLAS' ) ).
    cl_abap_unit_assert=>assert_equals( exp = `sap-icon://document`
                                        act = mo_cut->get_object_icon( 'XXXX' ) ).
  ENDMETHOD.

ENDCLASS.
