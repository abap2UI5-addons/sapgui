CLASS zcl_sapgui_se80_api_dbl DEFINITION PUBLIC FINAL FOR TESTING CREATE PUBLIC.

* ---------------------------------------------------------------------
*  ZIF_SAPGUI_SE80_API without a repository, for the unit tests of ZCL_SAPGUI_SE80.
*
*  A test sets it as the API of the screen (mo_cut->mo_api = NEW #( ))
*  and says with answer( ) what a method returns - its result, or an
*  EXPORTING parameter, for its first IMPORTING parameter (iv_key) or
*  for every call. Everything else answers an initial value; mt_calls
*  lists the methods called. FOR TESTING: only a test class can use it.
* ---------------------------------------------------------------------

  PUBLIC SECTION.
    INTERFACES zif_sapgui_se80_api.

    "! Methods of ZIF_SAPGUI_SYS_API called so far, upper case, in order
    DATA mt_calls TYPE string_table READ-ONLY.

    "! What iv_method answers from now on: its result, or the EXPORTING
    "! parameter iv_param - when called with iv_key as its first IMPORTING
    "! parameter, or for any call when iv_key is not given
    METHODS answer
      IMPORTING iv_method TYPE string
                iv_param  TYPE string DEFAULT `RESULT`
                iv_key    TYPE string OPTIONAL
                iv_value  TYPE any.

    "! Was iv_method called at least once?
    METHODS was_called
      IMPORTING iv_method     TYPE string
      RETURNING VALUE(result) TYPE abap_bool.

  PRIVATE SECTION.

    TYPES:
      BEGIN OF ty_s_answer,
        method TYPE string,
        param  TYPE string,
        arg    TYPE string,
        value  TYPE REF TO data,
      END OF ty_s_answer.

    DATA mt_answers TYPE HASHED TABLE OF ty_s_answer WITH UNIQUE KEY method param arg.

    METHODS reply
      IMPORTING iv_method TYPE string
                iv_param  TYPE string DEFAULT `RESULT`
                iv_key    TYPE string OPTIONAL
      CHANGING  cv_value  TYPE any.

ENDCLASS.



CLASS zcl_sapgui_se80_api_dbl IMPLEMENTATION.


  METHOD answer.
    DATA ls_answer TYPE ty_s_answer.
    FIELD-SYMBOLS <lv_value> TYPE any.

    ls_answer-method = to_upper( iv_method ).
    ls_answer-param  = to_upper( iv_param ).
    ls_answer-arg    = iv_key.
    CREATE DATA ls_answer-value LIKE iv_value.
    ASSIGN ls_answer-value->* TO <lv_value>.
    <lv_value> = iv_value.
    " WHERE, not WITH TABLE KEY: the transpiler compares only the first
    " component of a multi-component key there (@abaplint/transpiler 2.13)
    DELETE mt_answers WHERE method = ls_answer-method AND param = ls_answer-param AND arg = ls_answer-arg.
    INSERT ls_answer INTO TABLE mt_answers.
  ENDMETHOD.


  METHOD was_called.
    result = xsdbool( line_exists( mt_calls[ table_line = to_upper( iv_method ) ] ) ).
  ENDMETHOD.


  METHOD reply.
    FIELD-SYMBOLS <lv_value> TYPE any.

    IF iv_param = `RESULT`.
      APPEND iv_method TO mt_calls.
    ENDIF.
    CLEAR cv_value.
    READ TABLE mt_answers INTO DATA(ls_answer)
         WITH TABLE KEY method = iv_method param = iv_param arg = iv_key.
    IF sy-subrc <> 0 AND iv_key IS NOT INITIAL.
      READ TABLE mt_answers INTO ls_answer
           WITH TABLE KEY method = iv_method param = iv_param arg = ``.
    ENDIF.
    IF sy-subrc = 0.
      ASSIGN ls_answer-value->* TO <lv_value>.
      cv_value = <lv_value>.
    ENDIF.
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_package_tree.
    reply( EXPORTING iv_method = `GET_PACKAGE_TREE` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~search_objects.
    reply( EXPORTING iv_method = `SEARCH_OBJECTS` iv_key = |{ iv_pattern }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~load_source.
    reply( EXPORTING iv_method = `LOAD_SOURCE` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~save_source.
    reply( EXPORTING iv_method = `SAVE_SOURCE` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~activate_object.
    reply( EXPORTING iv_method = `ACTIVATE_OBJECT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~check_syntax.
    reply( EXPORTING iv_method = `CHECK_SYNTAX` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~pretty_print.
    reply( EXPORTING iv_method = `PRETTY_PRINT` iv_key = |{ iv_source }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_metadata.
    APPEND `GET_METADATA` TO mt_calls.
    reply( EXPORTING iv_method = `GET_METADATA` iv_param = `ET_METHODS` CHANGING cv_value = et_methods ).
    reply( EXPORTING iv_method = `GET_METADATA` iv_param = `ET_FIELDS` CHANGING cv_value = et_fields ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_properties.
    reply( EXPORTING iv_method = `GET_PROPERTIES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_where_used.
    reply( EXPORTING iv_method = `GET_WHERE_USED` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_object_icon.
    reply( EXPORTING iv_method = `GET_OBJECT_ICON` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_text_elements.
    reply( EXPORTING iv_method = `GET_TEXT_ELEMENTS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_documentation.
    reply( EXPORTING iv_method = `GET_DOCUMENTATION` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_includes.
    reply( EXPORTING iv_method = `GET_INCLUDES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_object_status.
    reply( EXPORTING iv_method = `GET_OBJECT_STATUS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~delete_object.
    reply( EXPORTING iv_method = `DELETE_OBJECT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~lock_in_transport.
    reply( EXPORTING iv_method = `LOCK_IN_TRANSPORT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~create_program.
    reply( EXPORTING iv_method = `CREATE_PROGRAM` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~create_class.
    reply( EXPORTING iv_method = `CREATE_CLASS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~create_interface.
    reply( EXPORTING iv_method = `CREATE_INTERFACE` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_subclasses.
    reply( EXPORTING iv_method = `GET_SUBCLASSES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_implementations.
    reply( EXPORTING iv_method = `GET_IMPLEMENTATIONS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_method_signature.
    reply( EXPORTING iv_method = `GET_METHOD_SIGNATURE` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_class_events.
    reply( EXPORTING iv_method = `GET_CLASS_EVENTS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_source_statistics.
    reply( EXPORTING iv_method = `GET_SOURCE_STATISTICS` iv_key = |{ iv_source }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_variants.
    reply( EXPORTING iv_method = `GET_VARIANTS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_table_content.
    reply( EXPORTING iv_method = `GET_TABLE_CONTENT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_class_types.
    reply( EXPORTING iv_method = `GET_CLASS_TYPES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~rename_object.
    reply( EXPORTING iv_method = `RENAME_OBJECT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_fm_exceptions.
    reply( EXPORTING iv_method = `GET_FM_EXCEPTIONS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_class_constants.
    reply( EXPORTING iv_method = `GET_CLASS_CONSTANTS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_table_foreign_keys.
    reply( EXPORTING iv_method = `GET_TABLE_FOREIGN_KEYS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_package_info.
    reply( EXPORTING iv_method = `GET_PACKAGE_INFO` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_table_append_structures.
    reply( EXPORTING iv_method = `GET_TABLE_APPEND_STRUCTURES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_class_friends.
    reply( EXPORTING iv_method = `GET_CLASS_FRIENDS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_redefined_methods.
    reply( EXPORTING iv_method = `GET_REDEFINED_METHODS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_lock_info.
    reply( EXPORTING iv_method = `GET_LOCK_INFO` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_package_path.
    reply( EXPORTING iv_method = `GET_PACKAGE_PATH` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~copy_object.
    reply( EXPORTING iv_method = `COPY_OBJECT` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_table_tech_settings.
    reply( EXPORTING iv_method = `GET_TABLE_TECH_SETTINGS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~compare_versions.
    reply( EXPORTING iv_method = `COMPARE_VERSIONS` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_program_attributes.
    reply( EXPORTING iv_method = `GET_PROGRAM_ATTRIBUTES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_object_dependencies.
    reply( EXPORTING iv_method = `GET_OBJECT_DEPENDENCIES` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~search_replace_source.
    APPEND `SEARCH_REPLACE_SOURCE` TO mt_calls.
    reply( EXPORTING iv_method = `SEARCH_REPLACE_SOURCE` iv_param = `EV_SOURCE` iv_key = |{ iv_source }| CHANGING cv_value = ev_source ).
    reply( EXPORTING iv_method = `SEARCH_REPLACE_SOURCE` iv_param = `EV_COUNT` iv_key = |{ iv_source }| CHANGING cv_value = ev_count ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_object_description.
    reply( EXPORTING iv_method = `GET_OBJECT_DESCRIPTION` CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~get_parent_package.
    reply( EXPORTING iv_method = `GET_PARENT_PACKAGE` iv_key = |{ iv_package }| CHANGING cv_value = result ).
  ENDMETHOD.


  METHOD zif_sapgui_se80_api~find_object.
    reply( EXPORTING iv_method = `FIND_OBJECT` iv_key = |{ iv_name }| CHANGING cv_value = result ).
  ENDMETHOD.

ENDCLASS.
