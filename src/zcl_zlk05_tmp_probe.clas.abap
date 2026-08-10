CLASS zcl_zlk05_tmp_probe DEFINITION PUBLIC FINAL CREATE PUBLIC.
  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.
  PRIVATE SECTION.
    DATA mo_out TYPE REF TO if_oo_adt_classrun_out.
    "! Menu bar and application toolbar of one GUI status, read from the CUA
    METHODS dump_status
      IMPORTING iv_program TYPE string
                iv_status  TYPE string.
    "! Renders SAP Easy Access through the client double and reports which
    "! transactions of this environment really appear in the tree.
    METHODS dump_entry_tree.
ENDCLASS.


CLASS zcl_zlk05_tmp_probe IMPLEMENTATION.

  METHOD if_oo_adt_classrun~main.

    " Scratch class of package $ZLK_05. It renders the entry screen without
    " a browser and checks that every transaction of this environment is
    " really in the tree. dump_status is kept for the next transaction:
    " it reads the CUA of a program to get menu and toolbar texts.

    mo_out = out.
    dump_entry_tree( ).

  ENDMETHOD.


  METHOD dump_entry_tree.

    DATA(lo_app) = NEW zcl_sapgui_a2ui5( ).
    DATA(lo_dbl) = NEW zcl_zlk05_client_dbl( ).

    lo_dbl->mv_on_init = abap_true.
    lo_app->z2ui5_if_app~main( lo_dbl ).

    DATA(lv_view) = lo_dbl->mv_view.
    DATA(lt_fav)  = zcl_zlk05_tcode_router=>get_favorites( ).
    DATA(lt_apps) = zcl_zlk05_tcode_router=>get_apps( ).

    mo_out->write( |SAP Easy Access rendered: { strlen( lv_view ) } characters| ).
    mo_out->write( |transactions in the registry: { lines( lt_apps ) }, | &&
                   |with an app behind them: { lines( lt_fav ) }| ).
    mo_out->write( `` ).

    DATA lv_missing TYPE i.

    LOOP AT lt_fav INTO DATA(ls_fav).
      DATA(lv_row) = |{ ls_fav-tcode } - { ls_fav-text }|.
      IF lv_view CS lv_row.
        mo_out->write( |  in tree : { lv_row }| ).
      ELSE.
        lv_missing = lv_missing + 1.
        mo_out->write( |  MISSING : { lv_row }| ).
      ENDIF.
    ENDLOOP.

    mo_out->write( `` ).

    " the ones that are only listed must NOT pretend to be available
    LOOP AT lt_apps INTO DATA(ls_app) WHERE class IS INITIAL.
      mo_out->write( |  listed only, not in the favorites: { ls_app-tcode } | &&
                     |- { ls_app-text }| ).
    ENDLOOP.

    mo_out->write( `` ).
    mo_out->write( COND string( WHEN lv_missing = 0
                                THEN `RESULT: every available transaction is in the tree`
                                ELSE |RESULT: { lv_missing } transaction(s) missing in the tree| ) ).

  ENDMETHOD.


  METHOD dump_status.

    DATA ls_adm TYPE rsmpe_adm.
    DATA lt_sta TYPE TABLE OF rsmpe_stat.
    DATA lt_fun TYPE TABLE OF rsmpe_funt.
    DATA lt_men TYPE TABLE OF rsmpe_men.
    DATA lt_mtx TYPE TABLE OF rsmpe_mnlt.
    DATA lt_act TYPE TABLE OF rsmpe_act.
    DATA lt_but TYPE TABLE OF rsmpe_but.
    DATA lt_pfk TYPE TABLE OF rsmpe_pfk.
    DATA lt_set TYPE TABLE OF rsmpe_staf.
    DATA lt_doc TYPE TABLE OF rsmpe_atrt.
    DATA lt_tit TYPE TABLE OF rsmpe_titt.
    DATA lt_biv TYPE TABLE OF rsmpe_buts.

    DATA(lv_prog) = CONV progname( iv_program ).

    CALL FUNCTION 'RS_CUA_INTERNAL_FETCH'
      EXPORTING  program   = lv_prog
                 language  = 'E'
                 state     = 'A'
      IMPORTING  adm       = ls_adm
      TABLES     sta       = lt_sta
                 fun       = lt_fun
                 men       = lt_men
                 mtx       = lt_mtx
                 act       = lt_act
                 but       = lt_but
                 pfk       = lt_pfk
                 set       = lt_set
                 doc       = lt_doc
                 tit       = lt_tit
                 biv       = lt_biv
      EXCEPTIONS not_found = 1
                 OTHERS    = 99.

    IF sy-subrc <> 0.
      mo_out->write( |{ iv_program }: CUA not read, sy-subrc = { sy-subrc }| ).
      RETURN.
    ENDIF.

    DATA(lv_code) = CONV rsmpe_stat-code( iv_status ).
    READ TABLE lt_sta INTO DATA(ls_sta) WITH KEY code = lv_code.
    IF sy-subrc <> 0.
      mo_out->write( |{ iv_program } { iv_status }: status not found| ).
      RETURN.
    ENDIF.

    mo_out->write( |=== { iv_program } status { iv_status } | &&
                   |menu [{ ls_sta-actcode }] toolbar [{ ls_sta-butcode }] ===| ).

    LOOP AT lt_act INTO DATA(ls_act) WHERE code = ls_sta-actcode.
      DATA(ls_mtx) = VALUE rsmpe_mnlt(
          lt_mtx[ code = ls_act-menucode ] OPTIONAL ).
      mo_out->write( |  menu { ls_act-no } { ls_act-menucode } | &&
                     |= [{ ls_mtx-text }] | &&
                     |inc={ ls_mtx-inc_prog }/{ ls_mtx-inc_status }| ).
    ENDLOOP.

    LOOP AT lt_but INTO DATA(ls_but) WHERE pfk_code = ls_sta-butcode.
      READ TABLE lt_pfk INTO DATA(ls_pfk)
           WITH KEY code = ls_but-code pfno = ls_but-pfno.
      IF sy-subrc <> 0.
        mo_out->write( |  tb   { ls_but-no } -- separator --| ).
        CONTINUE.
      ENDIF.
      READ TABLE lt_fun INTO DATA(ls_fun) WITH KEY code = ls_pfk-funcode.
      mo_out->write( |  tb   { ls_but-no } { ls_pfk-funcode } | &&
                     |icon={ ls_fun-icon_id } | &&
                     |fun=[{ ls_fun-fun_text }] | &&
                     |icontext=[{ ls_fun-icon_text }] | &&
                     |info=[{ ls_fun-info_text }]| ).
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
