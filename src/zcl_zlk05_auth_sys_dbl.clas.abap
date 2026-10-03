CLASS zcl_zlk05_auth_sys_dbl DEFINITION PUBLIC FINAL FOR TESTING CREATE PRIVATE.

* ---------------------------------------------------------------------
*  ZIF_ZLK05_AUTH_SYS without a system, for the unit tests.
*
*  install( ) puts a new double in front of ZCL_ZLK05_AUTH (whose
*  global friend this class is), uninstall( ) takes it away again - call
*  them in setup( ) and teardown( ). Every check passes (sy-subrc 0)
*  until deny( ) names it, the repository reads answer what answer( )
*  stored and an initial value otherwise:
*
*    DATA(lo_auth) = zcl_zlk05_auth_sys_dbl=>install( ).
*    lo_auth->deny( `S_TCODE` ).
*    lo_auth->answer( iv_method = `TABLE_AUTH_GROUP` iv_value = `SC` ).
*
*  So the app tests no longer depend on the roles of the user who runs
*  them. FOR TESTING: only a test class can use it.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_zlk05_auth_sys.

    "! Checks asked so far, upper case, in order
    DATA mt_calls TYPE string_table READ-ONLY.

    "! A new double, installed for every authorization check
    CLASS-METHODS install
      RETURNING VALUE(result) TYPE REF TO zcl_zlk05_auth_sys_dbl.

    "! Back to the checks of the system
    CLASS-METHODS uninstall.

    "! The check iv_check (a method of ZIF_ZLK05_AUTH_SYS) fails from now on
    METHODS deny
      IMPORTING iv_check TYPE string
                iv_subrc TYPE i DEFAULT 4.

    "! What a repository read (TABLE_AUTH_GROUP, OBJECT_PACKAGE,
    "! OBJECT_EXISTS, USER_GROUP) answers from now on
    METHODS answer
      IMPORTING iv_method TYPE string
                iv_value  TYPE string.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_value,
        name  TYPE string,
        subrc TYPE i,
        value TYPE string,
      END OF ty_s_value.

    DATA mt_values TYPE HASHED TABLE OF ty_s_value WITH UNIQUE KEY name.

    METHODS reply
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE ty_s_value.

ENDCLASS.



CLASS zcl_zlk05_auth_sys_dbl IMPLEMENTATION.


  METHOD install.
    result = NEW #( ).
    zcl_zlk05_auth=>go_sys = result.
  ENDMETHOD.


  METHOD uninstall.
    CLEAR zcl_zlk05_auth=>go_sys.
  ENDMETHOD.


  METHOD deny.
    DATA(lv_name) = to_upper( iv_check ).
    DELETE TABLE mt_values WITH TABLE KEY name = lv_name.
    INSERT VALUE #( name = lv_name subrc = iv_subrc ) INTO TABLE mt_values.
  ENDMETHOD.


  METHOD answer.
    DATA(lv_name) = to_upper( iv_method ).
    DELETE TABLE mt_values WITH TABLE KEY name = lv_name.
    INSERT VALUE #( name = lv_name value = iv_value ) INTO TABLE mt_values.
  ENDMETHOD.


  METHOD reply.
    APPEND iv_name TO mt_calls.
    READ TABLE mt_values INTO result WITH TABLE KEY name = iv_name.
    IF sy-subrc <> 0.
      CLEAR result.
    ENDIF.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_tcode.
    result = reply( `S_TCODE` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_admi_fcd.
    result = reply( `S_ADMI_FCD` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_rzl_adm.
    result = reply( `S_RZL_ADM` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_user_grp_any.
    result = reply( `S_USER_GRP_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_user_grp.
    result = reply( `S_USER_GRP` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_transprt_any.
    result = reply( `S_TRANSPRT_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_appl_log_any.
    result = reply( `S_APPL_LOG_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_appl_log.
    result = reply( `S_APPL_LOG` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_rfc_adm_any.
    result = reply( `S_RFC_ADM_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_rfc_adm.
    result = reply( `S_RFC_ADM` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_user_agr_any.
    result = reply( `S_USER_AGR_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_user_agr.
    result = reply( `S_USER_AGR` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_idocmoni_any.
    result = reply( `S_IDOCMONI_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_idocmoni.
    result = reply( `S_IDOCMONI` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_tabu_dis.
    result = reply( `S_TABU_DIS` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_tabu_nam.
    result = reply( `S_TABU_NAM` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_develop_any.
    result = reply( `S_DEVELOP_ANY` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_develop.
    result = reply( `S_DEVELOP` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~s_btch_job_prot.
    result = reply( `S_BTCH_JOB_PROT` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~spool_permission.
    result = reply( `SPOOL_PERMISSION` )-subrc.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~table_auth_group.
    result = reply( `TABLE_AUTH_GROUP` )-value.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~object_package.
    result = reply( `OBJECT_PACKAGE` )-value.
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~object_exists.
    result = xsdbool( reply( `OBJECT_EXISTS` )-value IS NOT INITIAL ).
  ENDMETHOD.


  METHOD zif_zlk05_auth_sys~user_group.
    result = reply( `USER_GROUP` )-value.
  ENDMETHOD.

ENDCLASS.
