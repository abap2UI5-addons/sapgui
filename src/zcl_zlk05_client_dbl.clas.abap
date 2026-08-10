CLASS zcl_zlk05_client_dbl DEFINITION
  PUBLIC
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES z2ui5_if_client.

    " Captured output of the app under test
    DATA mv_view          TYPE string.
    DATA mv_popup         TYPE string.
    DATA mv_popover       TYPE string.
    DATA mv_nav_call      TYPE string.
    DATA mv_nav_leave     TYPE abap_bool.
    DATA mv_model_updates TYPE i.
    DATA mt_follow_up     TYPE string_table.

    " Every follow-up action with its arguments, as `ACTION:arg1,arg2`.
    " The key registrations of the frame travel this way, so a test can
    " check that F3 really reached the frontend.
    DATA mt_follow_up_arg TYPE string_table.

    " Every backend event the app registered while building the view, in the
    " form `EVENT_NAME|arg1|arg2|...`. The view XML itself only carries the
    " opaque handler expression, so this is the only way a test can check
    " WHICH event was wired and which arguments travel with it.
    DATA mt_events         TYPE string_table.

    " Behaviour that the test can steer
    DATA mv_prev_stack    TYPE abap_bool VALUE abap_true.
    DATA mv_on_init       TYPE abap_bool.
    DATA mv_on_event      TYPE abap_bool.
    "! Set by the framework when the app is reached through nav_app_call or
    "! nav_app_leave. On a leave the event is EMPTY and check_on_init is
    "! already false, so an app that does not evaluate this flag renders
    "! nothing at all and the screen of the transaction just left stays on
    "! the browser. Steerable here so a test can cover that path.
    DATA mv_on_navigated  TYPE abap_bool.
    DATA ms_get           TYPE z2ui5_if_types=>ty_s_get.

    METHODS reset.

    " True when that key combination was registered for that event.
    METHODS has_shortcut
      IMPORTING iv_keys       TYPE string
                iv_event      TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    " True when the app registered an event with exactly this name.
    METHODS has_event
      IMPORTING iv_name       TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    " True when any registered event carries an argument containing iv_sub.
    METHODS has_event_arg
      IMPORTING iv_sub        TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

    " Parses the captured view (or the supplied XML) and returns the parser
    " errors. An initial result means: the XML is well formed.
    METHODS get_xml_errors
      IMPORTING iv_xml        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

    " Number of child ELEMENTS of the first element carrying iv_name.
    " -1 when no such element exists at all.
    METHODS count_children
      IMPORTING iv_name       TYPE string
                iv_xml        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE i.

    " Number of elements named iv_name that carry NO child element at all.
    " A container that stayed empty is the fingerprint of the "return value of
    " open( ) ignored" bug, which pushed the children next to the container.
    METHODS count_empty_elements
      IMPORTING iv_name       TYPE string
                iv_xml        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE i.

    " Name of the single root element, or an explicit complaint when the XML
    " carries none or more than one root.
    METHODS get_root_name
      IMPORTING iv_xml        TYPE string OPTIONAL
      RETURNING VALUE(result) TYPE string.

  PROTECTED SECTION.
  PRIVATE SECTION.
    METHODS parse
      IMPORTING iv_xml        TYPE string
      RETURNING VALUE(result) TYPE REF TO if_ixml_parser.
    DATA mo_doc TYPE REF TO if_ixml_document.
ENDCLASS.


CLASS zcl_zlk05_client_dbl IMPLEMENTATION.

  METHOD reset.
    CLEAR: mv_view, mv_popup, mv_popover, mv_nav_call, mv_nav_leave,
           mv_model_updates, mt_follow_up, mt_follow_up_arg, mt_events.
  ENDMETHOD.

  METHOD has_shortcut.
    result = xsdbool( line_exists( mt_follow_up_arg[
        table_line = |KEYBOARD_SHORTCUT:{ iv_keys },{ iv_event }| ] ) ).
  ENDMETHOD.

  METHOD has_event.
    LOOP AT mt_events INTO DATA(lv_entry).
      SPLIT lv_entry AT `|` INTO DATA(lv_name) DATA(lv_args).
      IF lv_name = iv_name.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD has_event_arg.
    LOOP AT mt_events INTO DATA(lv_entry).
      SPLIT lv_entry AT `|` INTO DATA(lv_name) DATA(lv_args).
      IF lv_args IS NOT INITIAL AND find( val = lv_args sub = iv_sub ) >= 0.
        result = abap_true.
        RETURN.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD parse.
    DATA(lo_ixml) = cl_ixml=>create( ).
    mo_doc = lo_ixml->create_document( ).
    DATA(lo_sf) = lo_ixml->create_stream_factory( ).
    result = lo_ixml->create_parser( stream_factory = lo_sf
                                     istream        = lo_sf->create_istream_string( iv_xml )
                                     document       = mo_doc ).
    result->parse( ).
  ENDMETHOD.

  METHOD get_xml_errors.
    DATA(lv_xml) = COND string( WHEN iv_xml IS SUPPLIED THEN iv_xml ELSE mv_view ).
    IF lv_xml IS INITIAL.
      result = `no XML was rendered at all`.
      RETURN.
    ENDIF.

    DATA(lo_parser) = parse( lv_xml ).
    DATA(lv_num) = lo_parser->num_errors( ).
    DO lv_num TIMES.
      DATA(lo_err) = lo_parser->get_error( index = sy-index - 1 ).
      result = |{ result }{ lo_err->get_reason( ) }; |.
    ENDDO.
  ENDMETHOD.

  METHOD count_empty_elements.
    DATA(lv_xml) = COND string( WHEN iv_xml IS SUPPLIED THEN iv_xml ELSE mv_view ).
    parse( lv_xml ).

    DATA(lo_nodes) = mo_doc->get_elements_by_tag_name( name = iv_name ).
    DATA(lo_iter)  = lo_nodes->create_iterator( ).

    DO.
      DATA(lo_node) = lo_iter->get_next( ).
      IF lo_node IS NOT BOUND.
        EXIT.
      ENDIF.

      DATA(lv_kids)     = 0.
      DATA(lo_children) = lo_node->get_children( ).
      DO lo_children->get_length( ) TIMES.
        IF lo_children->get_item( sy-index - 1 )->get_type( ) = if_ixml_node=>co_node_element.
          lv_kids = lv_kids + 1.
        ENDIF.
      ENDDO.

      IF lv_kids = 0.
        result = result + 1.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  METHOD get_root_name.
    DATA(lv_xml) = COND string( WHEN iv_xml IS SUPPLIED THEN iv_xml ELSE mv_view ).
    parse( lv_xml ).

    DATA(lo_children) = mo_doc->get_children( ).
    DATA lt_roots TYPE string_table.
    DO lo_children->get_length( ) TIMES.
      DATA(lo_child) = lo_children->get_item( sy-index - 1 ).
      IF lo_child->get_type( ) = if_ixml_node=>co_node_element.
        APPEND lo_child->get_name( ) TO lt_roots.
      ENDIF.
    ENDDO.

    CASE lines( lt_roots ).
      WHEN 0.
        result = `NO ROOT ELEMENT`.
      WHEN 1.
        result = lt_roots[ 1 ].
      WHEN OTHERS.
        result = |{ lines( lt_roots ) } ROOT ELEMENTS: { concat_lines_of( table = lt_roots sep = `, ` ) }|.
    ENDCASE.
  ENDMETHOD.

  METHOD count_children.
    DATA(lv_xml) = COND string( WHEN iv_xml IS SUPPLIED THEN iv_xml ELSE mv_view ).
    parse( lv_xml ).

    DATA(lo_node) = mo_doc->find_from_name( name = iv_name ).
    IF lo_node IS NOT BOUND.
      result = -1.
      RETURN.
    ENDIF.

    DATA(lo_children) = lo_node->get_children( ).
    DO lo_children->get_length( ) TIMES.
      DATA(lo_child) = lo_children->get_item( sy-index - 1 ).
      IF lo_child->get_type( ) = if_ixml_node=>co_node_element.
        result = result + 1.
      ENDIF.
    ENDDO.
  ENDMETHOD.

  " ---------- captured ----------

  METHOD z2ui5_if_client~view_display.
    mv_view = val.
  ENDMETHOD.

  METHOD z2ui5_if_client~popup_display.
    mv_popup = val.
  ENDMETHOD.

  METHOD z2ui5_if_client~popover_display.
    mv_popover = xml.
  ENDMETHOD.

  METHOD z2ui5_if_client~view_model_update.
    mv_model_updates = mv_model_updates + 1.
  ENDMETHOD.

  METHOD z2ui5_if_client~follow_up_action.
    APPEND val TO mt_follow_up.
    APPEND |{ val }:{ concat_lines_of( table = t_arg sep = `,` ) }| TO mt_follow_up_arg.
  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_call.
    DATA(lo_descr) = cl_abap_typedescr=>describe_by_object_ref( app ).
    mv_nav_call = lo_descr->get_relative_name( ).
  ENDMETHOD.

  METHOD z2ui5_if_client~nav_app_leave.
    mv_nav_leave = abap_true.
  ENDMETHOD.

  " ---------- steerable ----------

  METHOD z2ui5_if_client~check_on_init.
    result = mv_on_init.
  ENDMETHOD.

  METHOD z2ui5_if_client~check_on_event.
    result = mv_on_event.
  ENDMETHOD.

  METHOD z2ui5_if_client~check_app_prev_stack.
    result = mv_prev_stack.
  ENDMETHOD.

  METHOD z2ui5_if_client~get.
    result = ms_get.
  ENDMETHOD.

  " ---------- binding / events ----------

  METHOD z2ui5_if_client~_bind.
    result = `{/MOCK}`.
  ENDMETHOD.

  METHOD z2ui5_if_client~_bind_edit.
    result = `{/MOCK}`.
  ENDMETHOD.

  METHOD z2ui5_if_client~_event.
    DATA(lv_entry) = CONV string( val ).
    LOOP AT t_arg INTO DATA(lv_arg).
      lv_entry = lv_entry && `|` && lv_arg.
    ENDLOOP.
    APPEND lv_entry TO mt_events.

    result = `MOCK_EVENT`.
  ENDMETHOD.

  METHOD z2ui5_if_client~_event_client.
    result = `MOCK_EVENT_CLIENT`.
  ENDMETHOD.

  METHOD z2ui5_if_client~_event_nav_app_leave.
    result = `MOCK_NAV_LEAVE`.
  ENDMETHOD.

  " ---------- not relevant for view tests ----------

  METHOD z2ui5_if_client~check_on_navigated.
    result = mv_on_navigated.
  ENDMETHOD.

  METHOD z2ui5_if_client~get_app.
  ENDMETHOD.

  METHOD z2ui5_if_client~get_app_prev.
  ENDMETHOD.

  METHOD z2ui5_if_client~get_event_arg.
  ENDMETHOD.

  METHOD z2ui5_if_client~message_box_display.
  ENDMETHOD.

  METHOD z2ui5_if_client~message_toast_display.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest_view_display.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest_view_destroy.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest_view_model_update.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest2_view_display.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest2_view_destroy.
  ENDMETHOD.

  METHOD z2ui5_if_client~nest2_view_model_update.
  ENDMETHOD.

  METHOD z2ui5_if_client~popup_model_update.
  ENDMETHOD.

  METHOD z2ui5_if_client~popup_destroy.
  ENDMETHOD.

  METHOD z2ui5_if_client~popover_model_update.
  ENDMETHOD.

  METHOD z2ui5_if_client~popover_destroy.
  ENDMETHOD.

  METHOD z2ui5_if_client~set_app_state_active.
  ENDMETHOD.

  METHOD z2ui5_if_client~set_nav_back.
  ENDMETHOD.

  METHOD z2ui5_if_client~set_nav_routing.
  ENDMETHOD.

  METHOD z2ui5_if_client~set_push_state.
  ENDMETHOD.

  METHOD z2ui5_if_client~set_session_stateful.
  ENDMETHOD.

  METHOD z2ui5_if_client~view_destroy.
  ENDMETHOD.

ENDCLASS.
