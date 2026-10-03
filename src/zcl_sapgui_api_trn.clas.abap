CLASS zcl_sapgui_api_trn DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - Transport (STMS/SE09)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_SAPGUI_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    "! Transport domain and the own system, read from TMSCSYS
    CLASS-METHODS get_tms_domain
      EXPORTING ev_domain  TYPE string
                ev_system  TYPE string
                ev_message TYPE string.

    "! All systems of the transport domain (TMSCSYS)
    CLASS-METHODS get_tms_systems
      RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tms_system.

    "! Import queue of every system of the domain (TMSBUFFER)
    CLASS-METHODS get_tms_queue
      IMPORTING iv_max        TYPE i DEFAULT 5000
      RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tms_queue.

    CLASS-METHODS get_transports
      IMPORTING iv_user       TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_transport.

    CLASS-METHODS get_transport_objects
      IMPORTING iv_trkorr     TYPE string
                iv_max        TYPE i DEFAULT 5000
      RETURNING VALUE(result) TYPE zcl_sapgui_sys_api=>ty_t_tr_object.

  PROTECTED SECTION.
  PRIVATE SECTION.


ENDCLASS.



CLASS zcl_sapgui_api_trn IMPLEMENTATION.



  METHOD get_tms_domain.

    CLEAR: ev_domain, ev_system, ev_message.

*   The own system is the one TMSCSYS marks as real system (SYSTYP R)
*   and that carries the RFC destination of the domain controller.
    SELECT SINGLE domnam, sysnam
      FROM tmscsys
      WHERE sysnam = @sy-sysid
      INTO ( @DATA(lv_dom), @DATA(lv_sys) ).

    IF sy-subrc <> 0.
      ev_message = |System { sy-sysid } is not included in a transport domain.|.
      RETURN.
    ENDIF.

    ev_domain = lv_dom.
    ev_system = lv_sys.

  ENDMETHOD.

  METHOD get_tms_systems.

    SELECT sysnam, systxt, systyp, comsys, tmscfg, desadm, moddat, modusr
      FROM tmscsys
      ORDER BY sysnam
      INTO TABLE @DATA(lt_sys).

    LOOP AT lt_sys ASSIGNING FIELD-SYMBOL(<s>).
      APPEND VALUE #(
        sysnam = <s>-sysnam
        systxt = <s>-systxt
*       fixed values of domain TMSSYSTYP
        systyp = SWITCH string( <s>-systyp
                   WHEN 'R' THEN `Real system`
                   WHEN 'V' THEN `Virtual system`
                   WHEN 'E' THEN `External system`
                   WHEN 'I' THEN `Imported from other domain`
                   WHEN 'C' THEN `System cluster`
                   WHEN 'N' THEN `Non-ABAP system`
                   ELSE CONV string( <s>-systyp ) )
        comsys = <s>-comsys
*       fixed values of domain TMSCFGSTAT
        cfgstat = SWITCH string( <s>-tmscfg
                    WHEN 'A' THEN `System is active`
                    WHEN 'I' THEN `TMS is not active for this system`
                    WHEN 'L' THEN `System locked`
                    WHEN 'D' THEN `System was deleted from transport domain`
                    WHEN 'F' THEN `Communication system deleted`
                    WHEN 'C' THEN `Communication system is locked`
                    WHEN 'W' THEN `System is waiting for inclusion in transport domain`
                    WHEN 'R' THEN `System was not included in domain`
                    ELSE CONV string( <s>-tmscfg ) )
        desadm = <s>-desadm
        moddat = COND string( WHEN <s>-moddat IS NOT INITIAL
                              THEN zcl_sapgui_sys_api=>format_date( <s>-moddat ) )
        modusr = <s>-modusr ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_tms_queue.

    SELECT sysnam, bufpos, trkorr, owner, tarcli, maxrc, text
      FROM tmsbuffer
      ORDER BY sysnam, bufpos
      INTO TABLE @DATA(lt_buf)
      UP TO @iv_max ROWS.

    LOOP AT lt_buf ASSIGNING FIELD-SYMBOL(<b>).
      APPEND VALUE #(
        sysnam = <b>-sysnam
        bufpos = <b>-bufpos
        trkorr = <b>-trkorr
        owner  = <b>-owner
        tarcli = <b>-tarcli
        maxrc  = <b>-maxrc
        text   = <b>-text ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_transports.

    DATA(lv_user) = zcl_sapgui_sys_api=>to_like_pattern( iv_user ).
    DATA(lv_stat) = CONV trstatus( to_upper( condense( iv_status ) ) ).

    SELECT FROM e070 AS h
      LEFT OUTER JOIN e07t AS t
        ON  t~trkorr = h~trkorr
        AND t~langu  = @sy-langu
      FIELDS h~trkorr, h~trfunction, h~trstatus, h~tarsystem,
             h~as4user, h~as4date, h~as4time, h~strkorr, t~as4text
      WHERE h~as4user LIKE @lv_user ESCAPE '#'
        AND ( h~trstatus = @lv_stat OR @lv_stat = '' )
      ORDER BY h~as4date DESCENDING, h~as4time DESCENDING
      INTO TABLE @DATA(lt_tr)
      UP TO @iv_max ROWS.

    LOOP AT lt_tr ASSIGNING FIELD-SYMBOL(<t>).
      APPEND VALUE #(
        trkorr     = <t>-trkorr
        trfunction = <t>-trfunction
        functxt    = SWITCH string( <t>-trfunction
                       WHEN 'K' THEN `Workbench Request`
                       WHEN 'W' THEN `Customizing Request`
                       WHEN 'T' THEN `Transport of Copies`
                       WHEN 'S' THEN `Development/Correction`
                       WHEN 'R' THEN `Repair`
                       WHEN 'X' THEN `Unclassified Task`
                       WHEN 'Q' THEN `Customizing Task`
                       ELSE CONV string( <t>-trfunction ) )
        trstatus   = <t>-trstatus
        statustxt  = SWITCH string( <t>-trstatus
                       WHEN 'D' THEN `Modifiable`
                       WHEN 'L' THEN `Modifiable, locked`
                       WHEN 'O' THEN `Release started`
                       WHEN 'R' THEN `Released`
                       WHEN 'N' THEN `Released (import protection)`
                       ELSE CONV string( <t>-trstatus ) )
        as4user    = <t>-as4user
        as4date    = zcl_sapgui_sys_api=>format_date( <t>-as4date )
        as4time    = zcl_sapgui_sys_api=>format_time( <t>-as4time )
        tarsystem  = <t>-tarsystem
        as4text    = <t>-as4text
        strkorr    = <t>-strkorr ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_transport_objects.

    DATA(lv_tr) = CONV trkorr( to_upper( condense( iv_trkorr ) ) ).

    SELECT pgmid, object, obj_name, objfunc
      FROM e071
      WHERE trkorr = @lv_tr
      ORDER BY pgmid, object, obj_name
      INTO TABLE @DATA(lt_obj)
      UP TO @iv_max ROWS.

    LOOP AT lt_obj ASSIGNING FIELD-SYMBOL(<o>).
      APPEND VALUE #( pgmid    = <o>-pgmid
                      object   = <o>-object
                      obj_name = <o>-obj_name
                      objfunc  = <o>-objfunc ) TO result.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
