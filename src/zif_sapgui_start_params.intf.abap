INTERFACE zif_sapgui_start_params PUBLIC.

* ---------------------------------------------------------------------
*  Start values of a transaction, like the parameters a SAP GUI
*  transaction receives from a jump (CALL TRANSACTION ... with SPA/GPA).
*
*  An app that implements this interface can be started by the router
*  with values - e.g. ST22 "Go to Affected Program" starts SE38 with
*  PROGRAM = <program of the dump>. The router calls set_start_params
*  BEFORE the app's first roundtrip, and only after the authorization
*  check of the transaction has passed.
*
*  The values are input from another screen: the app has to check them
*  (existence, object authorization) exactly like typed-in values.
* ---------------------------------------------------------------------

  TYPES:
    BEGIN OF ty_s_param,
      name  TYPE string,
      value TYPE string,
    END OF ty_s_param.
  TYPES ty_t_param TYPE STANDARD TABLE OF ty_s_param WITH EMPTY KEY.

  "! Name of the start value that carries a program name (SE38)
  CONSTANTS c_program TYPE string VALUE `PROGRAM`.
  "! Name of the start value that carries a table or view name (SE16N)
  CONSTANTS c_table TYPE string VALUE `TABLE`.
  "! Name of the start value that carries a user name (SU01)
  CONSTANTS c_user TYPE string VALUE `USER`.
  "! Name of the start value that carries a date YYYYMMDD (ST22)
  CONSTANTS c_date TYPE string VALUE `DATE`.
  "! Name of the start value that carries a role name (PFCG)
  CONSTANTS c_role TYPE string VALUE `ROLE`.
  "! Name of the start value that carries a message class (SE91)
  CONSTANTS c_msgclass TYPE string VALUE `MSGCLASS`.

  METHODS set_start_params
    IMPORTING it_params TYPE ty_t_param.

ENDINTERFACE.
