CLASS zcl_sapgui_auth_sys DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  ZIF_SAPGUI_AUTH_SYS on a real system: the AUTHORITY-CHECK statements
*  of ZCL_SAPGUI_AUTH, field for field as the originals make them.
*  Created by ZCL_SAPGUI_AUTH=>sys( ) - by name, so that the checks do
*  not depend on this class and the unit tests run without it.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_sapgui_auth_sys.

  PRIVATE SECTION.
    CONSTANTS c_display TYPE activ_auth VALUE '03'.

ENDCLASS.



CLASS zcl_sapgui_auth_sys IMPLEMENTATION.


  METHOD zif_sapgui_auth_sys~s_tcode.
    DATA lv_tcode TYPE tcode.
    lv_tcode = iv_tcode.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD lv_tcode.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_admi_fcd.
    DATA lv_fcd TYPE c LENGTH 4.
    lv_fcd = iv_function.
    AUTHORITY-CHECK OBJECT 'S_ADMI_FCD' ID 'S_ADMI_FCD' FIELD lv_fcd.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_rzl_adm.
    AUTHORITY-CHECK OBJECT 'S_RZL_ADM' ID 'ACTVT' FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_user_grp_any.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP'
      ID 'CLASS' DUMMY
      ID 'ACTVT' FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_user_grp.
    DATA lv_group TYPE xuclass.
    lv_group = iv_group.
    AUTHORITY-CHECK OBJECT 'S_USER_GRP'
      ID 'CLASS' FIELD lv_group
      ID 'ACTVT' FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_transprt_any.
    AUTHORITY-CHECK OBJECT 'S_TRANSPRT'
      ID 'TTYPE' DUMMY
      ID 'ACTVT' FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_appl_log_any.
    AUTHORITY-CHECK OBJECT 'S_APPL_LOG'
      ID 'ALG_OBJECT' DUMMY
      ID 'ALG_SUBOBJ' DUMMY
      ID 'ACTVT'      FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_appl_log.
    DATA lv_object TYPE balobj_d.
    DATA lv_subobj TYPE balsubobj.
    lv_object = iv_object.
    lv_subobj = iv_subobject.
    AUTHORITY-CHECK OBJECT 'S_APPL_LOG'
      ID 'ALG_OBJECT' FIELD lv_object
      ID 'ALG_SUBOBJ' FIELD lv_subobj
      ID 'ACTVT'      FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_rfc_adm_any.
    AUTHORITY-CHECK OBJECT 'S_RFC_ADM'
      ID 'ACTVT'     FIELD c_display
      ID 'RFCTYPE'   DUMMY
      ID 'RFCDEST'   DUMMY
      ID 'ICF_VALUE' DUMMY.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_rfc_adm.
    DATA lv_type TYPE rfctype_d.
    DATA lv_dest TYPE rfcdest.
    lv_type = iv_rfctype.
    lv_dest = iv_rfcdest.
    AUTHORITY-CHECK OBJECT 'S_RFC_ADM'
      ID 'ACTVT'     FIELD c_display
      ID 'RFCTYPE'   FIELD lv_type
      ID 'RFCDEST'   FIELD lv_dest
      ID 'ICF_VALUE' DUMMY.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_user_agr_any.
    AUTHORITY-CHECK OBJECT 'S_USER_AGR'
      ID 'ACT_GROUP' DUMMY
      ID 'ACTVT'     FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_user_agr.
    DATA lv_role TYPE agr_name.
    lv_role = iv_role.
    AUTHORITY-CHECK OBJECT 'S_USER_AGR'
      ID 'ACT_GROUP' FIELD lv_role
      ID 'ACTVT'     FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_idocmoni_any.
    " RSEIDOC2, form AUTHORITY_CHECK_RSEIDOC2_DISP: WE02, or the older
    " WE05 authorization
    AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
      ID 'EDI_TCD' FIELD 'WE02'
      ID 'ACTVT'   FIELD c_display
      ID 'EDI_DIR' DUMMY
      ID 'EDI_MES' DUMMY
      ID 'EDI_PRN' DUMMY
      ID 'EDI_PRT' DUMMY.
    IF sy-subrc <> 0.
      AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
        ID 'EDI_TCD' FIELD 'WE05'
        ID 'ACTVT'   FIELD c_display
        ID 'EDI_DIR' DUMMY
        ID 'EDI_MES' DUMMY
        ID 'EDI_PRN' DUMMY
        ID 'EDI_PRT' DUMMY.
    ENDIF.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_idocmoni.
    DATA lv_prn  TYPE edi_rcvprn.
    DATA lv_prt  TYPE edi_rcvprt.
    DATA lo_badi TYPE REF TO idoc_authority_restriction.
    DATA lv_ok   TYPE flag.

    lv_prn = iv_partner_num.
    lv_prt = iv_partner_type.
    AUTHORITY-CHECK OBJECT 'S_IDOCMONI'
      ID 'EDI_TCD' FIELD 'WE02'
      ID 'ACTVT'   FIELD c_display
      ID 'EDI_DIR' FIELD is_edidc-direct
      ID 'EDI_MES' FIELD is_edidc-mestyp
      ID 'EDI_PRN' FIELD lv_prn
      ID 'EDI_PRT' FIELD lv_prt.
    result = sy-subrc.
    IF result <> 0.
      RETURN.
    ENDIF.

    " the customer check of RSEIDOC2 on top of the authorization
    lv_ok = abap_true.
    TRY.
        GET BADI lo_badi FILTERS mestyp = is_edidc-mestyp.
        CALL BADI lo_badi->is_idoc_access_allowed
          EXPORTING if_docnum       = is_edidc-docnum
                    if_edidc        = is_edidc
          CHANGING  if_authority_ok = lv_ok.
      CATCH cx_badi ##NO_HANDLER.
        " no implementation - nothing restricts the access
    ENDTRY.
    IF lv_ok = abap_false.
      result = 4.
    ENDIF.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_tabu_dis.
    DATA lv_group TYPE tddat-cclass.
    lv_group = iv_group.
    AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
      ID 'DICBERCLS' FIELD lv_group
      ID 'ACTVT'     FIELD c_display.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_tabu_nam.
    DATA lv_table TYPE tabname.
    lv_table = iv_table.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
      ID 'ACTVT' FIELD c_display
      ID 'TABLE' FIELD lv_table.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_develop_any.
    DATA lv_actvt TYPE activ_auth.
    lv_actvt = iv_actvt.
    AUTHORITY-CHECK OBJECT 'S_DEVELOP'
      ID 'DEVCLASS' DUMMY
      ID 'OBJTYPE'  DUMMY
      ID 'OBJNAME'  DUMMY
      ID 'P_GROUP'  DUMMY
      ID 'ACTVT'    FIELD lv_actvt.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_develop.
    DATA lv_actvt   TYPE activ_auth.
    DATA lv_package TYPE devclass.
    DATA lv_objtype TYPE trobjtype.
    DATA lv_objname TYPE sobj_name.
    lv_actvt   = iv_actvt.
    lv_package = iv_package.
    lv_objtype = iv_objtype.
    lv_objname = iv_objname.
    AUTHORITY-CHECK OBJECT 'S_DEVELOP'
      ID 'DEVCLASS' FIELD lv_package
      ID 'OBJTYPE'  FIELD lv_objtype
      ID 'OBJNAME'  FIELD lv_objname
      ID 'P_GROUP'  DUMMY
      ID 'ACTVT'    FIELD lv_actvt.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~s_btch_job_prot.
    AUTHORITY-CHECK OBJECT 'S_BTCH_JOB'
      ID 'JOBGROUP'  DUMMY
      ID 'JOBACTION' FIELD 'PROT'.
    IF sy-subrc <> 0.
      AUTHORITY-CHECK OBJECT 'S_BTCH_ADM' ID 'BTCADMIN' FIELD 'Y'.
    ENDIF.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~spool_permission.
    DATA lv_access TYPE authb-spoaction.
    lv_access = iv_access.
    CALL FUNCTION 'RSPO_CHECK_JOB_PERMISSION'
      EXPORTING
        access        = lv_access
        spoolreq      = is_tsp01
      EXCEPTIONS
        no_permission = 1
        OTHERS        = 2.
    result = sy-subrc.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~table_auth_group.
    DATA lv_table TYPE tabname.
    lv_table = iv_table.
    SELECT SINGLE cclass FROM tddat WHERE tabname = @lv_table INTO @DATA(lv_cclass).
    IF sy-subrc = 0.
      result = lv_cclass.
    ENDIF.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~object_package.
    DATA lv_object TYPE trobjtype.
    DATA lv_name   TYPE sobj_name.
    lv_object = iv_object.
    lv_name   = iv_obj_name.
    SELECT SINGLE devclass FROM tadir
      WHERE pgmid = 'R3TR' AND object = @lv_object AND obj_name = @lv_name
      INTO @DATA(lv_devclass).
    IF sy-subrc = 0.
      result = lv_devclass.
    ENDIF.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~object_exists.
    DATA lv_object TYPE trobjtype.
    DATA lv_name   TYPE sobj_name.
    lv_object = iv_object.
    lv_name   = iv_obj_name.
    SELECT SINGLE @abap_true FROM tadir
      WHERE pgmid = 'R3TR' AND object = @lv_object AND obj_name = @lv_name
      INTO @result ##SUBRC_OK.
  ENDMETHOD.


  METHOD zif_sapgui_auth_sys~user_group.
    DATA lv_user TYPE xubname.
    lv_user = iv_bname.
    SELECT SINGLE class FROM usr02 WHERE bname = @lv_user INTO @DATA(lv_group).
    IF sy-subrc = 0.
      result = lv_group.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
