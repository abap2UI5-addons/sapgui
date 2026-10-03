CLASS zcl_sapgui_screen DEFINITION PUBLIC ABSTRACT CREATE PUBLIC.

* ---------------------------------------------------------------------
*  One screen of the SAP GUI: what every app of this repository does the
*  same way, so that an app only says what is its own.
*
*  main( ) runs on every roundtrip:
*    1  ZCL_SAPGUI_AUTH=>guard_app( ) - S_TCODE and the basic check of the
*       transaction, also for an app started directly by URL
*    2  first start            -> on_init( )
*       navigated back to it    -> render( ), the screen it stands on
*       an event               -> on_frame_event( ), and when the frame
*                                 did not take the roundtrip over,
*                                 on_event( )
*
*  An app inherits from this class and implements on_init( ), render( )
*  and on_event( ). The window frame - menu bar, system bar with the
*  command field, title bar, toolbar and status bar - is built by
*  ZCL_SAPGUI_FRAME; the command field is bound to mv_command and
*  the status bar shows mv_message / mv_msgtype.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES z2ui5_if_app.

    "! Content of the command field of the system function bar
    DATA mv_command TYPE string.

  PROTECTED SECTION.
    DATA client TYPE REF TO z2ui5_if_client.

    "! The message of the status bar and its type (Success, Warning, ...)
    DATA mv_message TYPE string.
    DATA mv_msgtype TYPE string.

    "! What the frame made of the last event (outcome, message)
    DATA ms_frame TYPE zcl_sapgui_frame=>ty_s_frame_result.

    "! First roundtrip: the start values, and the first screen on display
    METHODS on_init ABSTRACT.

    "! Puts the screen the app stands on on display again - after an event
    "! that only changed the mode, and when the app is navigated back to,
    "! where the framework supplies no event at all
    METHODS render ABSTRACT.

    "! An event of the app itself - the frame has not taken it over
    METHODS on_event ABSTRACT.

    "! The functions of the window frame: the command field, Back, the
    "! System and Help menus. Clears the status bar first and shows the
    "! frame's message. abap_true when the frame took the roundtrip over
    "! (it navigated or rendered), so the app must not do anything else.
    METHODS on_frame_event
      RETURNING VALUE(result) TYPE abap_bool.

ENDCLASS.



CLASS zcl_sapgui_screen IMPLEMENTATION.


  METHOD z2ui5_if_app~main.

    IF zcl_sapgui_auth=>guard_app( io_client = client
                                  io_app    = me ) = abap_false.
      RETURN.
    ENDIF.

    me->client = client.

    IF client->check_on_init( ).
      on_init( ).
      " render( ) of the app calls view_display( ) - the linter reads this
      " class on its own and cannot see that
      " abap2ui5lint-disable-next-line missing-view-display-on-navigated
    ELSEIF client->check_on_navigated( ).
      " Another transaction was left with F3 / the Back arrow and handed
      " control back to this one. The framework supplies an EMPTY event
      " here and check_on_init is already false, so without this branch
      " nothing would be rendered and the browser would keep showing the
      " screen of the transaction that was just left.
      render( ).
    ELSEIF client->check_on_event( ).
      IF on_frame_event( ) = abap_false.
        on_event( ).
      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD on_frame_event.

    CLEAR: mv_message, mv_msgtype.

    ms_frame = zcl_sapgui_frame=>handle_frame_event(
        io_client  = client
        iv_event   = client->get_event( )
        iv_command = mv_command ).
    mv_message = ms_frame-message.
    mv_msgtype = ms_frame-msg_type.
    result = xsdbool( ms_frame-outcome = zcl_sapgui_frame=>c_navigated ).

  ENDMETHOD.

ENDCLASS.
