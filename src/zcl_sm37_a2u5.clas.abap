CLASS zcl_sm37_a2u5 DEFINITION PUBLIC.

* ---------------------------------------------------------------------
*  SM37 - Job Overview
*
*  Screen titles, menu bar and function texts are the original ones of
*  function group BTCH / program SAPLBTCH (RSMPTEXTS):
*
*    T  JOV_TITLE   Job Overview
*       JSL         Simple Job Selection
*       STEP_TITLE  Step List Overview
*       SHJ         Display Job &
*    M              Job  Edit  Goto  Extras  Settings
*    F  JREL Release        JPRO Job log      SPOO Spool list
*       JDTL Job details    JCHK Check status JABO Cancel active job
*       JCPY Copy           JMOV Move        JDRP Repeat scheduling
*       JDRL Released -> Scheduled           JGRP Capture: active job
*       JSTA Job Statistics JTRE Compare jobs JDOC Job documentation
*       JDEF Define Job     JSSC Correct status
*
*  The app selects jobs and shows their step list. Everything that
*  would change a job is present but disabled - this app never
*  releases, cancels or deletes a job.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    CONSTANTS c_na TYPE string VALUE `not available in this environment`.

    DATA mv_jobname  TYPE string.
    DATA mv_user     TYPE string.
    DATA mv_status   TYPE string.
    DATA mv_command   TYPE string.
    DATA mt_jobs     TYPE zcl_zlk05_sys_api=>ty_t_job.
    DATA mt_steps    TYPE zcl_zlk05_sys_api=>ty_t_jobstep.
    DATA mt_joblog   TYPE zcl_zlk05_sys_api=>ty_t_joblog.

  PROTECTED SECTION.
    DATA mv_cur_jobcount TYPE string.
    DATA mv_mode     TYPE string.
    DATA mv_current  TYPE string.
    DATA mv_message   TYPE string.
    DATA mv_msgtype  TYPE string.

    DATA client TYPE REF TO z2ui5_if_client.

    METHODS view_display.
    METHODS view_detail.
    METHODS on_event.
    "! Renders the screen the app is currently standing on. Needed twice:
    "! after an event that only changed the mode, and - most importantly -
    "! when the transaction is navigated back to from another one, where the
    "! framework supplies no event at all.
    METHODS render.
    METHODS do_search.
    METHODS do_open
      IMPORTING iv_jobname  TYPE string
                iv_jobcount TYPE string.
    METHODS do_joblog.
    METHODS view_joblog.

  PRIVATE SECTION.
ENDCLASS.


CLASS zcl_sm37_a2u5 IMPLEMENTATION.

  METHOD z2ui5_if_app~main.

    " S_TCODE + basic authorization of the transaction - on EVERY roundtrip,
    " so the app is protected even when it is started directly by URL
    IF zcl_zlk05_auth=>guard_app( io_client = client io_app = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      mv_mode = `LIST`.
      mv_user = CONV string( sy-uname ).
      do_search( ).
      view_display( ).
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 / the Back arrow and handed
      " control back to this one. The framework supplies an EMPTY event here
      " and check_on_init is already false, so without this branch nothing
      " would be rendered: the response would carry no view and the browser
      " would keep showing the screen of the transaction that was just left.
      " That is what made Back look dead and F3 only work on the second try.
      render( ).
    ELSEIF client->check_on_event( ).
      on_event( ).
    ENDIF.

  ENDMETHOD.


  METHOD on_event.

    DATA(lv_event) = client->get_event( ).
    DATA(lt_arg)   = client->get( )-t_event_arg.
    CLEAR: mv_message, mv_msgtype.

    " the command field and Back belong to the frame - they work the
    " same way on every screen of every transaction
    DATA(ls_frame) = zcl_zlk05_gui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = lv_event
        iv_command = mv_command ).
    mv_message = ls_frame-message.
    mv_msgtype = ls_frame-msg_type.
    IF ls_frame-outcome = zcl_zlk05_gui_frame=>c_navigated.
      RETURN.
    ENDIF.

    CASE lv_event.
      WHEN 'EXECUTE'.
        do_search( ).
      WHEN 'DISPLAY'.
        " the cell click of the grid delivers job name and count in one
        " argument, separated by a pipe
        IF lines( lt_arg ) >= 1.
          SPLIT lt_arg[ 1 ] AT `|` INTO DATA(lv_jobname) DATA(lv_jobcount).
          do_open( iv_jobname  = lv_jobname
                   iv_jobcount = lv_jobcount ).
        ENDIF.
      WHEN 'BACK_TO_LIST'.
        mv_mode = `LIST`.
      WHEN 'JOBLOG'.
        do_joblog( ).
      WHEN 'BACK_TO_STEPS'.
        mv_mode = `DETAIL`.
      WHEN OTHERS.
    ENDCASE.

    render( ).

  ENDMETHOD.

  METHOD render.

    IF mv_mode = `DETAIL`.
      view_detail( ).
    ELSEIF mv_mode = `LOG`.
      view_joblog( ).
    ELSE.
      view_display( ).
    ENDIF.

  ENDMETHOD.


  METHOD do_search.

    CLEAR mt_jobs.
    mt_jobs = zcl_zlk05_sys_api=>get_jobs( iv_jobname = mv_jobname
                                           iv_user    = mv_user
                                           iv_status  = mv_status ).
    mv_mode = `LIST`.

    IF lines( mt_jobs ) = 0.
      mv_message = `No jobs found for the selection criteria.`.
      mv_msgtype = `Warning`.
    ELSE.
      mv_message = |{ lines( mt_jobs ) } job(s) selected.|.
      mv_msgtype = `Success`.
    ENDIF.

  ENDMETHOD.


  METHOD do_joblog.

    zcl_zlk05_sys_api=>get_job_log(
      EXPORTING iv_jobname  = mv_current
                iv_jobcount = mv_cur_jobcount
      IMPORTING et_log      = mt_joblog
                ev_message  = DATA(lv_msg) ).

    IF lv_msg IS NOT INITIAL.
      mv_message = lv_msg.
      mv_msgtype = `Warning`.
      RETURN.
    ENDIF.

    mv_mode    = `LOG`.
    mv_message = |{ lines( mt_joblog ) } line(s) in the job log.|.
    mv_msgtype = `Information`.

  ENDMETHOD.


  METHOD view_joblog.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Job log` ) ( `Edit` ) ( `Goto` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_STEPS` ) ).

    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = |Job Log Entries for { mv_current } / { mv_cur_jobcount }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Step List` icon = `sap-icon://nav-back`
              tooltip = `Back to the step list (F3)`
              press = client->_event( `BACK_TO_STEPS` ) )
            ( sep = abap_true )
            ( icon = `sap-icon://message-information` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Long Text - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_joblog )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the columns of the original job log list
    DATA(lt_col) = VALUE string_table(
        ( `Date|ENTERDATE|7rem` )
        ( `Time|ENTERTIME|6rem` )
        ( `Message Text|TEXT|50rem` )
        ( `Message Class|MSGID|9rem` )
        ( `No.|MSGNO|4rem` )
        ( `Type|MSGTYPE|4rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   v = lv_fld
          )->a( n = `filterProperty` v = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table` ).
      IF lv_fld = `MSGTYPE`.
        col->tag( `ObjectStatus`
            )->a( n = `text`  v = `{MSGTYPE}`
            )->a( n = `state` v = `{STATE}` ).
      ELSE.
        col->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_STEPS` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.



  METHOD do_open.

    CLEAR mt_steps.
    mv_current      = iv_jobname.
    mv_cur_jobcount = iv_jobcount.
    mt_steps   = zcl_zlk05_sys_api=>get_job_steps( iv_jobname  = iv_jobname
                                                   iv_jobcount = iv_jobcount ).

    IF lines( mt_steps ) = 0.
      mv_message = |Job { iv_jobname } has no steps.|.
      mv_msgtype = `Warning`.
      RETURN.
    ENDIF.

    mv_mode = `DETAIL`.

  ENDMETHOD.


  METHOD view_display.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Job` ) ( `Edit` ) ( `Goto` ) ( `Extras` )
                              ( `Settings` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event_nav_app_leave( ) ).

    " T JOV_TITLE - Job Overview
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Job Overview` ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Execute` icon = `sap-icon://begin`
              tooltip = `Select the jobs (F8)`
              press = client->_event( `EXECUTE` ) )
            ( text = `Job details` icon = `sap-icon://detail-view`
              tooltip = `Step list of the selected job - or click a row`
              press = client->_event( `DISPLAY` ) )
            ( sep = abap_true )
            ( text = `Release` icon = `sap-icon://begin`
              tooltip = |Release - { c_na }| )
            ( text = `Job log` icon = `sap-icon://text-align-justified`
              tooltip = |Job log - { c_na }| )
            ( text = `Spool list` icon = `sap-icon://print`
              tooltip = |Spool list - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://check-availability` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Check status - { c_na }| )
            ( icon = `sap-icon://stop` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Cancel active job - { c_na }| )
            ( icon = `sap-icon://copy` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Copy - { c_na }| )
            ( icon = `sap-icon://journey-change` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Move - { c_na }| )
            ( icon = `sap-icon://repost` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Repeat scheduling - { c_na }| )
            ( icon = `sap-icon://undo` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Released -> Scheduled - { c_na }| )
            ( icon = `sap-icon://record` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Capture: active job - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://bar-chart` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Job Statistics - { c_na }| )
            ( icon = `sap-icon://compare` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Compare jobs - { c_na }| )
            ( icon = `sap-icon://document-text` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Job documentation - { c_na }| )
            ( icon = `sap-icon://add-activity` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Define Job - { c_na }| )
            ( icon = `sap-icon://wrench` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Correct status - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    " ----- T JSL - Simple Job Selection -----
    work->tag( `Title`
        )->a( n = `text`  v = `Simple Job Selection`
        )->a( n = `level` v = `H4` ).

    DATA(row) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `Job Name` ).
    row->tag( `Input`
        )->a( n = `id`          v = `idJobName`
        )->a( n = `value`       v = client->_bind( mv_jobname )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `14rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row iv_text = `User Name` ).
    row->tag( `Input`
        )->a( n = `value`       v = client->_bind( mv_user )
        )->a( n = `placeholder` v = `* for all`
        )->a( n = `width`       v = `11rem`
        )->a( n = `submit`      v = client->_event( `EXECUTE` ) ).
    row->end( ).

    DATA(row2) = work->ele( `HBox`
        )->a( n = `alignItems` v = `Center`
        )->a( n = `class`      v = `sapUiTinyMarginTop` ).
    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `Job Status` ).

    DATA(st) = row2->ele( `Select`
        )->a( n = `selectedKey` v = client->_bind( mv_status )
        )->a( n = `width`       v = `14rem` ).
    DATA(sti) = st->ele( `items` ).
    sti->tag( n = `Item` ns = `core`
        )->a( n = `key`  v = ``
        )->a( n = `text` v = `All statuses`
        )->tag( n = `Item` ns = `core` )->a( n = `key` v = `P` )->a( n = `text` v = `Scheduled`
        )->tag( n = `Item` ns = `core` )->a( n = `key` v = `S` )->a( n = `text` v = `Released`
        )->tag( n = `Item` ns = `core` )->a( n = `key` v = `R` )->a( n = `text` v = `Active`
        )->tag( n = `Item` ns = `core` )->a( n = `key` v = `F` )->a( n = `text` v = `Finished`
        )->tag( n = `Item` ns = `core` )->a( n = `key` v = `A` )->a( n = `text` v = `Cancelled` ).
    st->end( ).

    zcl_zlk05_gui_frame=>add_label( io_parent = row2 iv_text = `Job Start Condition` ).
    row2->tag( `Input`
        )->a( n = `value`   v = `All`
        )->a( n = `enabled` v = `false`
        )->a( n = `width`   v = `10rem`
        )->a( n = `tooltip` t = |Extended Job Selection - { c_na }| ).
    row2->end( ).

    client->follow_up_action(
        val   = client->cs_event-set_focus
        t_arg = VALUE #( ( `idJobName` ) ) ).

    " ----- the job list -----
    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_jobs )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10`
        )->a( n = `cellClick`           v = client->_event(
                  val = `DISPLAY`
                  arg = `${JOBNAME}|${JOBCOUNT}` ) ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    " the column sequence of the original job overview list
    DATA(lt_col) = VALUE string_table(
        ( `Job Name|JOBNAME|24rem` )
        ( `Status|STATUSTXT|8rem` )
        ( `Scheduled Date|SDLDATE|8rem` )
        ( `Start Time|STRTTIME|7rem` )
        ( `Duration (sec.)|DURATION|8rem` )
        ( `Created By|OWNER|9rem` )
        ( `Period|PERIODIC|6rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   v = lv_fld
          )->a( n = `filterProperty` v = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table` ).
      IF lv_fld = `STATUSTXT`.
        col->tag( `ObjectStatus`
            )->a( n = `text`  v = |\{{ lv_fld }\}|
            )->a( n = `state` v = `{STATE}` ).
      ELSE.
        col->tag( `Text`
            )->a( n = `text`     v = |\{{ lv_fld }\}|
            )->a( n = `wrapping` v = `false` ).
      ENDIF.
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  v = `Display only - no job is released, cancelled or deleted here`
        )->a( n = `class` v = `sapUiTinyMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = zcl_zlk05_gui_frame=>c_ev_back
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.


  METHOD view_detail.

    DATA(view) = z2ui5_cl_ui5_view_builder=>factory( ).
    DATA(page) = zcl_zlk05_gui_frame=>open_window( view ).

    zcl_zlk05_gui_frame=>build_status_bar( io_parent   = page
                                          iv_message  = mv_message
                                          iv_msg_type = mv_msgtype ).

    zcl_zlk05_gui_frame=>build_menu_bar( io_client = client
        io_parent  = page
        it_entries = VALUE #( ( `Job` ) ( `Edit` ) ( `Goto` ) ( `Extras` )
                              ( `Settings` ) ( `System` ) ( `Help` ) ) ).

    zcl_zlk05_gui_frame=>build_system_bar( io_client = client
        io_parent     = page
        iv_cmd_value  = client->_bind( mv_command )
        iv_cmd_event  = client->_event( zcl_zlk05_gui_frame=>c_ev_command )
        iv_back_event = client->_event( `BACK_TO_LIST` ) ).

    " T STEP_TITLE - Step List Overview
    zcl_zlk05_gui_frame=>build_title_bar( io_client = client
        io_parent = page
        iv_title  = `Step List Overview`
        iv_hint   = |Job { mv_current }| ).

    zcl_zlk05_gui_frame=>build_app_bar(
        io_parent  = page
        it_buttons = VALUE #(
            ( text = `Job Overview` icon = `sap-icon://nav-back`
              tooltip = `Back to the job overview (F3)`
              press = client->_event( `BACK_TO_LIST` ) )
            ( sep = abap_true )
            ( text = `Job log` icon = `sap-icon://text-align-justified`
              tooltip = `Display the job log`
              press = client->_event( `JOBLOG` ) )
            ( text = `Spool list` icon = `sap-icon://print`
              tooltip = |Spool list - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://edit` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Change Step - { c_na }| )
            ( icon = `sap-icon://add` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Create Step - { c_na }| )
            ( icon = `sap-icon://delete` color = zcl_zlk05_gui_frame=>c_red
              tooltip = |Delete Step - { c_na }| )
            ( sep = abap_true )
            ( icon = `sap-icon://inspect` color = zcl_zlk05_gui_frame=>c_grey
              tooltip = |Debug Job (Simulation) - { c_na }| ) ) ).

    DATA(work) = page->ele( `ScrollContainer`
        )->a( n = `height`     v = zcl_zlk05_gui_frame=>c_work_height
        )->a( n = `vertical`   v = `true`
        )->a( n = `horizontal` v = `true`
        )->ele( `VBox`
        )->a( n = `class` v = `sapUiSmallMargin` ).

    DATA(grid) = work->ele( n = `Table` ns = `table`
        )->a( n = `rows`                v = client->_bind( mt_steps )
        )->a( n = `visibleRowCountMode` v = `Auto`
        )->a( n = `selectionMode`       v = `Single`
        )->a( n = `rowHeight`           v = `26`
        )->a( n = `minAutoRowCount`     v = `10` ).

    DATA(cols) = grid->ele( n = `columns` ns = `table` ).

    DATA(lt_col) = VALUE string_table(
        ( `Step|STEPCOUNT|5rem` )
        ( `Program|PROGNAME|22rem` )
        ( `Variant|VARIANT|14rem` )
        ( `Authorization User|AUTHCKNAM|14rem` )
        ( `Lang.|LANGUAGE|5rem` )
        ( `Status|STATUS|8rem` ) ).

    LOOP AT lt_col INTO DATA(lv_col).
      SPLIT lv_col AT `|` INTO DATA(lv_head) DATA(lv_fld) DATA(lv_wid).
      DATA(col) = cols->ele( n = `Column` ns = `table`
          )->a( n = `width` t = lv_wid
          )->a( n = `sortProperty`   v = lv_fld
          )->a( n = `filterProperty` v = lv_fld ).
      col->ele( n = `label` ns = `table`
          )->tag( `Label` )->a( n = `text` t = lv_head )->end( )->end( ).
      col->ele( n = `template` ns = `table`
          )->tag( `Text`
              )->a( n = `text`     v = |\{{ lv_fld }\}|
              )->a( n = `wrapping` v = `false` ).
      col->end( ).
    ENDLOOP.

    work->tag( `Text`
        )->a( n = `text`  t = |{ lines( mt_steps ) } step(s) of job { mv_current }|
        )->a( n = `class` v = `sapUiTinyMarginTop` ).

    " function keys of the SAP GUI - F3 / Shift+F3 / F12 and F8
    zcl_zlk05_gui_frame=>register_keys(
        io_client    = client
        iv_back_name = `BACK_TO_LIST`
        iv_exec_name = `EXECUTE` ).

    client->view_display( view->stringify( ) ).

  ENDMETHOD.

ENDCLASS.
