INTERFACE zif_sapgui_auth_sys PUBLIC.

* ---------------------------------------------------------------------
*  The system side of the authorization checks of ZCL_SAPGUI_AUTH: the
*  AUTHORITY-CHECK statements themselves, the customer BAdI and the
*  function module the originals call, and the three facts a check
*  needs from the repository. Every check answers sy-subrc - 0 means
*  allowed. ZCL_SAPGUI_AUTH keeps everything else: which transaction asks
*  for what, the order of the checks and the messages.
*
*    ZCL_SAPGUI_AUTH_SYS      on a system
*    ZCL_SAPGUI_AUTH_SYS_DBL  in the unit tests - every check passes until
*                            the test denies it, no database at all
*
*  "_any" checks the activity with DUMMY for every other field - the
*  "may use the transaction at all" check of the original.
* ---------------------------------------------------------------------

  "! S_TCODE for one transaction code
  METHODS s_tcode
    IMPORTING iv_tcode      TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_ADMI_FCD for one system administration function (SM21, ...)
  METHODS s_admi_fcd
    IMPORTING iv_function   TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_RZL_ADM display
  METHODS s_rzl_adm
    RETURNING VALUE(result) TYPE i.

  "! S_USER_GRP display, any user group
  METHODS s_user_grp_any
    RETURNING VALUE(result) TYPE i.

  "! S_USER_GRP display for one user group
  METHODS s_user_grp
    IMPORTING iv_group      TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_TRANSPRT display, any request type
  METHODS s_transprt_any
    RETURNING VALUE(result) TYPE i.

  "! S_APPL_LOG display, any log object
  METHODS s_appl_log_any
    RETURNING VALUE(result) TYPE i.

  "! S_APPL_LOG display for one log object and subobject
  METHODS s_appl_log
    IMPORTING iv_object     TYPE string
              iv_subobject  TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_RFC_ADM display, any destination
  METHODS s_rfc_adm_any
    RETURNING VALUE(result) TYPE i.

  "! S_RFC_ADM display for one destination
  METHODS s_rfc_adm
    IMPORTING iv_rfctype    TYPE string
              iv_rfcdest    TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_USER_AGR display, any role
  METHODS s_user_agr_any
    RETURNING VALUE(result) TYPE i.

  "! S_USER_AGR display for one role
  METHODS s_user_agr
    IMPORTING iv_role       TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_IDOCMONI display for WE02, or else for the older WE05, any IDoc
  METHODS s_idocmoni_any
    RETURNING VALUE(result) TYPE i.

  "! S_IDOCMONI display for one IDoc and its partner, then the customer
  "! BAdI IDOC_AUTHORITY_RESTRICTION - exactly the check of RSEIDOC2
  METHODS s_idocmoni
    IMPORTING is_edidc        TYPE edidc
              iv_partner_num  TYPE string
              iv_partner_type TYPE string
    RETURNING VALUE(result)   TYPE i.

  "! S_TABU_DIS display for one table authorization group
  METHODS s_tabu_dis
    IMPORTING iv_group      TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_TABU_NAM display for one table
  METHODS s_tabu_nam
    IMPORTING iv_table      TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_DEVELOP for one activity, any object
  METHODS s_develop_any
    IMPORTING iv_actvt      TYPE string
    RETURNING VALUE(result) TYPE i.

  "! S_DEVELOP for one activity on one object in its package
  METHODS s_develop
    IMPORTING iv_actvt      TYPE string
              iv_package    TYPE string
              iv_objtype    TYPE string
              iv_objname    TYPE string
    RETURNING VALUE(result) TYPE i.

  "! The job log of another user: S_BTCH_JOB JOBACTION PROT, or else
  "! S_BTCH_ADM BTCADMIN Y - as SM37
  METHODS s_btch_job_prot
    RETURNING VALUE(result) TYPE i.

  "! RSPO_CHECK_JOB_PERMISSION, the check of SP01 with its customer exit:
  "! iv_access BASE = see the request, DISP = display its content
  METHODS spool_permission
    IMPORTING is_tsp01      TYPE tsp01
              iv_access     TYPE string
    RETURNING VALUE(result) TYPE i.

  "! Authorization group of a table (TDDAT-CCLASS), initial when it has none
  METHODS table_auth_group
    IMPORTING iv_table      TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Package of a repository object (TADIR, R3TR), initial when unknown
  METHODS object_package
    IMPORTING iv_object     TYPE string
              iv_obj_name   TYPE string
    RETURNING VALUE(result) TYPE string.

  "! Does the repository object exist (TADIR, R3TR)?
  METHODS object_exists
    IMPORTING iv_object     TYPE string
              iv_obj_name   TYPE string
    RETURNING VALUE(result) TYPE abap_bool.

  "! User group of a user (USR02-CLASS), initial when the user has none
  METHODS user_group
    IMPORTING iv_bname      TYPE string
    RETURNING VALUE(result) TYPE string.

ENDINTERFACE.
