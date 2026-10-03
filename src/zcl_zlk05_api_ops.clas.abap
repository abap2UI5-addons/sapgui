CLASS zcl_zlk05_api_ops DEFINITION PUBLIC FINAL CREATE PUBLIC.

* ---------------------------------------------------------------------
*  System API - Output and Interfaces (SP01 / WE02)
*
*  Part of the system API of package $ZLK_05. The apps do not call this
*  class directly - ZCL_ZLK05_SYS_API is the facade they use, it keeps
*  all types and delegates here. Every method is READ-ONLY.
* ---------------------------------------------------------------------

  PUBLIC SECTION.

    CLASS-METHODS get_spool_requests
      IMPORTING iv_owner      TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 200
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_spool.

    CLASS-METHODS get_spool_content
      IMPORTING iv_rqident   TYPE string
                iv_max_lines TYPE i DEFAULT 5000
      EXPORTING et_lines     TYPE string_table
                ev_message   TYPE string.

    "! The status column of SP01, the logic of RSPO_RSTATUS_FOR_SPOOLREQ:
    "! iv_pjstatus / iv_pjinfo are those of the last output request
    "! (TSP02) when exactly one output request is still open
    CLASS-METHODS spool_status
      IMPORTING is_tsp01    TYPE tsp01
                iv_pjstatus TYPE tsp02-pjstatus OPTIONAL
                iv_pjinfo   TYPE tsp02-pjinfo OPTIONAL
      EXPORTING ev_text     TYPE string
                ev_state    TYPE string.

    "! Spool time stamps are stored in UTC - SP01 shows them in the time
    "! zone of the user (RSPOTIME, form MAP_TO_LOCAL_TIME)
    CLASS-METHODS spool_time_to_local
      IMPORTING iv_stamp TYPE rspocrtime
      EXPORTING ev_date  TYPE d
                ev_time  TYPE t.

    CLASS-METHODS get_idocs
      IMPORTING iv_docnum     TYPE string OPTIONAL
                iv_mestyp     TYPE string OPTIONAL
                iv_status     TYPE string OPTIONAL
                iv_direct     TYPE string OPTIONAL
                iv_date_from  TYPE d OPTIONAL
                iv_date_to    TYPE d OPTIONAL
                iv_max        TYPE i DEFAULT 500
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_t_idoc.

    CLASS-METHODS get_idoc_detail
      IMPORTING iv_docnum   TYPE string
      EXPORTING es_idoc     TYPE zcl_zlk05_sys_api=>ty_s_idoc
                et_control  TYPE zcl_zlk05_sys_api=>ty_t_kv
                et_status   TYPE zcl_zlk05_sys_api=>ty_t_idoc_status
                et_segments TYPE zcl_zlk05_sys_api=>ty_t_idoc_seg
                ev_message  TYPE string.

    "! Traffic light of an IDoc status as UI5 value state, from the
    "! customizing WE02 uses: STACUST (status -> group) and STALIGHT
    "! (group -> light 1 yellow / 2 green / 3 red)
    CLASS-METHODS idoc_status_state
      IMPORTING iv_status     TYPE edi_status
      RETURNING VALUE(result) TYPE string.

    "! Text of an IDoc status (TEDS2, logon language, English fallback)
    CLASS-METHODS idoc_status_text
      IMPORTING iv_status     TYPE edi_status
      RETURNING VALUE(result) TYPE string.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_light,
        status TYPE edi_status,
        light  TYPE stalight-stalight,
      END OF ty_s_light.
    TYPES:
      BEGIN OF ty_s_stext,
        status TYPE edi_status,
        text   TYPE string,
      END OF ty_s_stext.

    CLASS-DATA mt_light     TYPE HASHED TABLE OF ty_s_light WITH UNIQUE KEY status.
    CLASS-DATA mt_stext     TYPE HASHED TABLE OF ty_s_stext WITH UNIQUE KEY status.
    CLASS-DATA mv_idoc_init TYPE abap_bool.

    CLASS-METHODS load_idoc_customizing.

    CLASS-METHODS map_idoc
      IMPORTING is_edidc      TYPE edidc
      RETURNING VALUE(result) TYPE zcl_zlk05_sys_api=>ty_s_idoc.

    CLASS-METHODS to_docnum
      IMPORTING iv_docnum TYPE string
      EXPORTING ev_docnum TYPE edi_docnum
                ev_ok     TYPE abap_bool.

ENDCLASS.



CLASS zcl_zlk05_api_ops IMPLEMENTATION.



  METHOD get_spool_requests.

    TYPES:
      BEGIN OF ty_s_pj,
        pjident  TYPE tsp02-pjident,
        pjnummer TYPE tsp02-pjnummer,
        pjstatus TYPE tsp02-pjstatus,
        pjinfo   TYPE tsp02-pjinfo,
      END OF ty_s_pj.

    DATA lr_owner TYPE RANGE OF tsp01-rqowner.
    DATA lt_req   TYPE STANDARD TABLE OF tsp01 WITH EMPTY KEY.
    DATA lt_open  TYPE STANDARD TABLE OF tsp01 WITH EMPTY KEY.
    DATA lt_pj    TYPE SORTED TABLE OF ty_s_pj WITH NON-UNIQUE KEY pjident pjnummer.
    DATA lv_from  TYPE rspocrtime.
    DATA lv_date  TYPE d.
    DATA lv_time  TYPE t.

    " the selection screen of SP01: own spool requests unless a user or
    " a pattern (* +) is entered
    DATA(lv_owner) = to_upper( condense( iv_owner ) ).
    IF lv_owner IS INITIAL.
      lv_owner = sy-uname.
    ENDIF.
    IF lv_owner CA '*+'.
      lr_owner = VALUE #( ( sign = 'I' option = 'CP' low = lv_owner ) ).
    ELSE.
      lr_owner = VALUE #( ( sign = 'I' option = 'EQ' low = lv_owner ) ).
    ENDIF.

    IF iv_date_from IS NOT INITIAL.
      lv_from = |{ iv_date_from }000000|.
    ENDIF.

    SELECT * FROM tsp01
      WHERE rqclient  =  @sy-mandt
        AND rqowner   IN @lr_owner
        AND rqcretime >= @lv_from
      ORDER BY rqident DESCENDING
      INTO TABLE @lt_req
      UP TO @iv_max ROWS.

    " the state of the last output request is needed only while exactly
    " one of them is still open
    LOOP AT lt_req INTO DATA(ls_open) WHERE rqpjreq > 0.
      IF ls_open-rqpjreq > ls_open-rqpjdone.
        APPEND ls_open TO lt_open.
      ENDIF.
    ENDLOOP.
    IF lt_open IS NOT INITIAL.
      SELECT pjident, pjnummer, pjstatus, pjinfo FROM tsp02
        FOR ALL ENTRIES IN @lt_open
        WHERE pjident = @lt_open-rqident
        INTO TABLE @lt_pj.
    ENDIF.

    LOOP AT lt_req ASSIGNING FIELD-SYMBOL(<r>).

      IF zcl_zlk05_auth=>check_spool( is_tsp01 = <r> iv_access = `BASE` )-allowed = abap_false.
        CONTINUE.
      ENDIF.

      DATA(ls_pj) = VALUE ty_s_pj( ).
      LOOP AT lt_pj INTO DATA(ls_cand) WHERE pjident = <r>-rqident.
        IF ls_cand-pjnummer = <r>-rqpjreq.
          ls_pj = ls_cand.
        ENDIF.
      ENDLOOP.

      spool_status( EXPORTING is_tsp01    = <r>
                              iv_pjstatus = ls_pj-pjstatus
                              iv_pjinfo   = ls_pj-pjinfo
                    IMPORTING ev_text     = DATA(lv_status)
                              ev_state    = DATA(lv_state) ).

      spool_time_to_local( EXPORTING iv_stamp = <r>-rqcretime
                           IMPORTING ev_date  = lv_date
                                     ev_time  = lv_time ).

      " the title of the list, or the spool request name like SP01
      DATA(lv_title) = condense( CONV string( <r>-rqtitle ) ).
      IF lv_title IS INITIAL.
        lv_title = condense( |{ <r>-rq0name } { <r>-rq1name } { <r>-rq2name }| ).
      ENDIF.

      APPEND VALUE #(
        rqident = condense( CONV string( <r>-rqident ) )
        doctype = <r>-rqdoctype
        date    = zcl_zlk05_sys_api=>format_date( lv_date )
        time    = zcl_zlk05_sys_api=>format_time( lv_time )
        status  = lv_status
        state   = lv_state
        pages   = |{ <r>-rqapprule }|
        title   = lv_title
        owner   = <r>-rqowner
        dest    = <r>-rqdest ) TO result.

    ENDLOOP.

  ENDMETHOD.


  METHOD spool_status.

    DATA lv_req  TYPE i.
    DATA lv_done TYPE i.
    DATA lv_serr TYPE i.
    DATA lv_herr TYPE i.

    ev_state = `None`.
    lv_req   = is_tsp01-rqpjreq.
    lv_done  = is_tsp01-rqpjdone.
    lv_serr  = is_tsp01-rqpjserr.
    lv_herr  = is_tsp01-rqpjherr.

    " no output request yet: + while the request is still being written
    IF lv_req = 0.
      ev_text = COND #( WHEN is_tsp01-rqwriter > 0 THEN `+` ELSE `-` ).
      RETURN.
    ENDIF.

    IF lv_req > lv_done.
      IF lv_req - lv_done <> 1.
        ev_text = `<F5>`.
      ELSEIF is_tsp01-rqarchstat = '2'.
        ev_text = `Archive`.
      ELSE.
        CASE iv_pjstatus.
          WHEN '1'.
            ev_text = `Time`.
          WHEN '2'.
            ev_text = COND #( WHEN iv_pjinfo > 255 THEN `Processing` ELSE `Waiting` ).
          WHEN '3'.
            ev_text  = `Waiting`.
            ev_state = `Warning`.
          WHEN '4' OR '5'.
            ev_text = `Processing`.
          WHEN '6'.
            ev_text  = `Problem`.
            ev_state = `Warning`.
          WHEN '7'.
            ev_text  = `Printing`.
            ev_state = `Success`.
          WHEN OTHERS.
            ev_text = `<F5>`.
        ENDCASE.
      ENDIF.
      RETURN.
    ENDIF.

    " all output requests are done
    lv_serr = nmin( val1 = lv_serr val2 = lv_req ).
    lv_herr = nmin( val1 = lv_herr val2 = lv_req ).
    IF lv_serr = 0 AND lv_herr = 0.
      ev_text  = `Compl.`.
      ev_state = `Success`.
    ELSEIF lv_req = lv_serr.
      ev_text  = `Problem`.
      ev_state = `Warning`.
    ELSEIF lv_req = lv_herr.
      ev_text  = `Error`.
      ev_state = `Error`.
    ELSE.
      ev_text  = `<F5>`.
      ev_state = COND #( WHEN lv_herr > 0 THEN `Warning` ELSE `None` ).
    ENDIF.

  ENDMETHOD.


  METHOD spool_time_to_local.

    DATA lv_ts  TYPE timestamp.
    DATA lv_utc TYPE tznzone VALUE 'UTC'.

    CLEAR: ev_date, ev_time.
    IF iv_stamp IS INITIAL OR iv_stamp(8) CN '0123456789'.
      RETURN.
    ENDIF.

    ev_date = iv_stamp(8).
    ev_time = iv_stamp+8(6).
    CONVERT DATE ev_date TIME ev_time INTO TIME STAMP lv_ts TIME ZONE lv_utc.
    IF sy-subrc = 0 AND sy-zonlo IS NOT INITIAL.
      CONVERT TIME STAMP lv_ts TIME ZONE sy-zonlo INTO DATE ev_date TIME ev_time.
    ENDIF.

  ENDMETHOD.


  METHOD get_spool_content.

    TYPES ty_line TYPE c LENGTH 1024.
    DATA lt_buf TYPE STANDARD TABLE OF ty_line WITH EMPTY KEY.
    DATA lv_id  TYPE tsp01-rqident.

    CLEAR: et_lines, ev_message.

    DATA(lv_in) = condense( iv_rqident ).
    IF lv_in IS INITIAL OR lv_in CN '0123456789'.
      ev_message = |Enter a valid spool request number|.
      RETURN.
    ENDIF.
    lv_id = lv_in.

    SELECT SINGLE * FROM tsp01 WHERE rqident = @lv_id INTO @DATA(ls_req).
    IF sy-subrc <> 0 OR ls_req-rqclient <> sy-mandt.
      ev_message = |Spool request { lv_in } does not exist|.
      RETURN.
    ENDIF.

    DATA(ls_auth) = zcl_zlk05_auth=>check_spool( is_tsp01 = ls_req iv_access = `DISP` ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    IF ls_req-rqdoctype <> 'LIST'.
      ev_message = |Spool request { lv_in } is of type { ls_req-rqdoctype } - only ABAP lists can be displayed as text here|.
      RETURN.
    ENDIF.

    CALL FUNCTION 'RSPO_RETURN_ABAP_SPOOLJOB'
      EXPORTING
        rqident              = lv_id
        first_line           = 1
        last_line            = iv_max_lines
      TABLES
        buffer               = lt_buf
      EXCEPTIONS
        no_such_job          = 1
        not_abap_list        = 2
        job_contains_no_data = 3
        selection_empty      = 4
        no_permission        = 5
        can_not_access       = 6
        read_error           = 7
        OTHERS               = 8.
    CASE sy-subrc.
      WHEN 0.
      WHEN 3 OR 4.
        ev_message = |Spool request { lv_in } contains no data|.
        RETURN.
      WHEN 5.
        MESSAGE e028(zlk05) WITH lv_in INTO ev_message.
        RETURN.
      WHEN OTHERS.
        ev_message = |Spool request { lv_in } cannot be read (RSPO_RETURN_ABAP_SPOOLJOB { sy-subrc })|.
        RETURN.
    ENDCASE.

    LOOP AT lt_buf INTO DATA(lv_line).
      APPEND CONV string( lv_line ) TO et_lines.
    ENDLOOP.

  ENDMETHOD.



  METHOD load_idoc_customizing.

    IF mv_idoc_init = abap_true.
      RETURN.
    ENDIF.
    mv_idoc_init = abap_true.

    SELECT c~status, l~stalight AS light
      FROM stacust AS c
      INNER JOIN stalight AS l ON l~statva = c~statva
      INTO TABLE @mt_light.

    SELECT status, langua, descrp FROM teds2
      WHERE langua = @sy-langu OR langua = 'E'
      INTO TABLE @DATA(lt_text).
    " logon language first, English where it is missing
    LOOP AT lt_text INTO DATA(ls_text) WHERE langua = sy-langu.
      INSERT VALUE #( status = ls_text-status text = ls_text-descrp ) INTO TABLE mt_stext.
    ENDLOOP.
    LOOP AT lt_text INTO ls_text WHERE langua = 'E'.
      INSERT VALUE #( status = ls_text-status text = ls_text-descrp ) INTO TABLE mt_stext.
    ENDLOOP.

  ENDMETHOD.


  METHOD idoc_status_state.

    load_idoc_customizing( ).
    READ TABLE mt_light INTO DATA(ls_light) WITH TABLE KEY status = iv_status.
    IF sy-subrc <> 0.
      result = `None`.
      RETURN.
    ENDIF.
    result = SWITCH #( ls_light-light
                       WHEN '1' THEN `Warning`
                       WHEN '2' THEN `Success`
                       WHEN '3' THEN `Error`
                       ELSE `None` ).

  ENDMETHOD.


  METHOD idoc_status_text.

    load_idoc_customizing( ).
    result = VALUE #( mt_stext[ status = iv_status ]-text OPTIONAL ).

  ENDMETHOD.


  METHOD to_docnum.

    CLEAR: ev_docnum, ev_ok.
    DATA(lv_in) = condense( iv_docnum ).
    IF lv_in IS INITIAL OR lv_in CN '0123456789' OR strlen( lv_in ) > 16.
      RETURN.
    ENDIF.
    ev_docnum = lv_in.
    ev_ok     = abap_true.

  ENDMETHOD.


  METHOD map_idoc.

    DATA(lv_partner) = COND string(
        WHEN is_edidc-direct = '1' THEN |{ is_edidc-rcvprt } { is_edidc-rcvprn ALPHA = OUT }|
        ELSE |{ is_edidc-sndprt } { is_edidc-sndprn ALPHA = OUT }| ).

    result = VALUE #(
      docnum   = |{ shift_left( val = CONV string( is_edidc-docnum ) sub = `0` ) }|
      status   = is_edidc-status
      stattext = idoc_status_text( is_edidc-status )
      state    = idoc_status_state( is_edidc-status )
      direct   = SWITCH #( is_edidc-direct WHEN '1' THEN `Outbound`
                                           WHEN '2' THEN `Inbound`
                                           ELSE is_edidc-direct )
      mestyp   = is_edidc-mestyp
      idoctp   = is_edidc-idoctp
      partner  = condense( lv_partner )
      credat   = zcl_zlk05_sys_api=>format_date( is_edidc-credat )
      cretim   = zcl_zlk05_sys_api=>format_time( is_edidc-cretim )
      upddat   = zcl_zlk05_sys_api=>format_date( is_edidc-upddat )
      updtim   = zcl_zlk05_sys_api=>format_time( is_edidc-updtim ) ).

  ENDMETHOD.


  METHOD get_idocs.

    DATA lr_docnum TYPE RANGE OF edidc-docnum.
    DATA lr_mestyp TYPE RANGE OF edidc-mestyp.
    DATA lr_status TYPE RANGE OF edidc-status.
    DATA lr_direct TYPE RANGE OF edidc-direct.
    DATA lr_credat TYPE RANGE OF edidc-credat.
    DATA lt_edidc  TYPE STANDARD TABLE OF edidc WITH EMPTY KEY.

    IF iv_docnum IS NOT INITIAL.
      to_docnum( EXPORTING iv_docnum = iv_docnum
                 IMPORTING ev_docnum = DATA(lv_docnum)
                           ev_ok     = DATA(lv_ok) ).
      IF lv_ok = abap_false.
        RETURN.
      ENDIF.
      lr_docnum = VALUE #( ( sign = 'I' option = 'EQ' low = lv_docnum ) ).
    ENDIF.

    DATA(lv_mestyp) = to_upper( condense( iv_mestyp ) ).
    IF lv_mestyp IS NOT INITIAL.
      lr_mestyp = VALUE #( ( sign = 'I' option = COND #( WHEN lv_mestyp CA '*+' THEN 'CP' ELSE 'EQ' )
                             low = lv_mestyp ) ).
    ENDIF.

    DATA(lv_status) = condense( iv_status ).
    IF lv_status IS NOT INITIAL.
      lr_status = VALUE #( ( sign = 'I' option = 'EQ' low = lv_status ) ).
    ENDIF.

    IF iv_direct = '1' OR iv_direct = '2'.
      lr_direct = VALUE #( ( sign = 'I' option = 'EQ' low = iv_direct ) ).
    ENDIF.

    IF iv_date_from IS NOT INITIAL OR iv_date_to IS NOT INITIAL.
      lr_credat = VALUE #( ( sign   = 'I' option = 'BT'
                             low    = iv_date_from
                             high   = COND #( WHEN iv_date_to IS INITIAL THEN '99991231'
                                              ELSE iv_date_to ) ) ).
    ENDIF.

    SELECT * FROM edidc
      WHERE docnum IN @lr_docnum
        AND mestyp IN @lr_mestyp
        AND status IN @lr_status
        AND direct IN @lr_direct
        AND credat IN @lr_credat
      ORDER BY docnum DESCENDING
      INTO TABLE @lt_edidc
      UP TO @iv_max ROWS.

    LOOP AT lt_edidc INTO DATA(ls_edidc).
      " RSEIDOC2 lists only the IDocs the user may see
      IF zcl_zlk05_auth=>check_idoc( ls_edidc )-allowed = abap_false.
        CONTINUE.
      ENDIF.
      APPEND map_idoc( ls_edidc ) TO result.
    ENDLOOP.

  ENDMETHOD.


  METHOD get_idoc_detail.

    DATA ls_edidc TYPE edidc.
    DATA lt_edids TYPE STANDARD TABLE OF edids WITH EMPTY KEY.
    DATA lt_edidd TYPE STANDARD TABLE OF edidd WITH EMPTY KEY.
    DATA lv_msg   TYPE string.
    DATA lv_level TYPE i.

    CLEAR: es_idoc, et_control, et_status, et_segments, ev_message.

    to_docnum( EXPORTING iv_docnum = iv_docnum
               IMPORTING ev_docnum = DATA(lv_docnum)
                         ev_ok     = DATA(lv_ok) ).
    IF lv_ok = abap_false.
      ev_message = `Enter a valid IDoc number`.
      RETURN.
    ENDIF.

    SELECT SINGLE * FROM edidc WHERE docnum = @lv_docnum INTO @ls_edidc.
    IF sy-subrc <> 0.
      ev_message = |IDoc { shift_left( val = CONV string( lv_docnum ) sub = `0` ) } does not exist|.
      RETURN.
    ENDIF.

    DATA(ls_auth) = zcl_zlk05_auth=>check_idoc( ls_edidc ).
    IF ls_auth-allowed = abap_false.
      ev_message = ls_auth-message.
      RETURN.
    ENDIF.

    CALL FUNCTION 'IDOC_READ_COMPLETELY'
      EXPORTING
        document_number         = lv_docnum
      IMPORTING
        idoc_control            = ls_edidc
      TABLES
        int_edids               = lt_edids
        int_edidd               = lt_edidd
      EXCEPTIONS
        document_not_exist      = 1
        document_number_invalid = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      ev_message = |IDoc { shift_left( val = CONV string( lv_docnum ) sub = `0` ) } cannot be read (IDOC_READ_COMPLETELY { sy-subrc })|.
      RETURN.
    ENDIF.

    es_idoc = map_idoc( ls_edidc ).

    " the control record as WE02 shows it on the right side
    et_control = VALUE #(
      ( label = `IDoc number`       value = es_idoc-docnum )
      ( label = `Current status`    value = |{ ls_edidc-status } { es_idoc-stattext }| )
      ( label = `Direction`         value = |{ ls_edidc-direct } { es_idoc-direct }| )
      ( label = `Basic type`        value = ls_edidc-idoctp )
      ( label = `Extension`         value = ls_edidc-cimtyp )
      ( label = `Message type`      value = ls_edidc-mestyp )
      ( label = `Message code`      value = ls_edidc-mescod )
      ( label = `Message function`  value = ls_edidc-mesfct )
      ( label = `Sender port`       value = ls_edidc-sndpor )
      ( label = `Sender partner`    value = condense( |{ ls_edidc-sndprt } { ls_edidc-sndprn ALPHA = OUT } { ls_edidc-sndpfc }| ) )
      ( label = `Receiver port`     value = ls_edidc-rcvpor )
      ( label = `Receiver partner`  value = condense( |{ ls_edidc-rcvprt } { ls_edidc-rcvprn ALPHA = OUT } { ls_edidc-rcvpfc }| ) )
      ( label = `Created on`        value = |{ es_idoc-credat } { es_idoc-cretim }| )
      ( label = `Last changed on`   value = |{ es_idoc-upddat } { es_idoc-updtim }| )
      ( label = `Test flag`         value = COND #( WHEN ls_edidc-test IS INITIAL THEN `No` ELSE `Yes` ) )
      ( label = `Data records`      value = |{ lines( lt_edidd ) }| ) ).

    " status records, newest first - with the message text they were
    " written with (message class / number or the plain status text)
    SORT lt_edids BY countr DESCENDING.
    LOOP AT lt_edids INTO DATA(ls_s).
      IF ls_s-stamid IS NOT INITIAL AND ls_s-stamno CO '0123456789'.
        MESSAGE ID ls_s-stamid TYPE 'I' NUMBER ls_s-stamno
          WITH ls_s-stapa1 ls_s-stapa2 ls_s-stapa3 ls_s-stapa4 INTO lv_msg.
      ELSE.
        lv_msg = ls_s-statxt.
        REPLACE FIRST OCCURRENCE OF '&' IN lv_msg WITH ls_s-stapa1.
        REPLACE FIRST OCCURRENCE OF '&' IN lv_msg WITH ls_s-stapa2.
        REPLACE FIRST OCCURRENCE OF '&' IN lv_msg WITH ls_s-stapa3.
        REPLACE FIRST OCCURRENCE OF '&' IN lv_msg WITH ls_s-stapa4.
      ENDIF.
      APPEND VALUE #(
        counter  = |{ shift_left( val = CONV string( ls_s-countr ) sub = `0` ) }|
        status   = ls_s-status
        state    = idoc_status_state( ls_s-status )
        stattext = idoc_status_text( ls_s-status )
        message  = condense( lv_msg )
        date     = zcl_zlk05_sys_api=>format_date( ls_s-logdat )
        time     = zcl_zlk05_sys_api=>format_time( ls_s-logtim )
        user     = ls_s-uname
        program  = ls_s-repid ) TO et_status.
    ENDLOOP.

    " data records in their hierarchy
    LOOP AT lt_edidd INTO DATA(ls_d).
      lv_level = 1.
      IF ls_d-hlevel CO '0123456789' AND ls_d-hlevel IS NOT INITIAL.
        lv_level = ls_d-hlevel.
      ENDIF.
      APPEND VALUE #(
        segnum = |{ shift_left( val = CONV string( ls_d-segnum ) sub = `0` ) }|
        segnam = ls_d-segnam
        hlevel = |{ lv_level }|
        tree   = |{ repeat( val = `. ` occ = nmax( val1 = lv_level - 1 val2 = 0 ) ) }{ ls_d-segnam }|
        sdata  = CONV string( ls_d-sdata ) ) TO et_segments.
    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
