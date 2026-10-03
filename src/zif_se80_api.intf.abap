INTERFACE zif_se80_api PUBLIC.

* ---------------------------------------------------------------------
*  The repository API of the Object Navigator (SE80), as an interface.
*
*  ZCL_SE80_UI works against this interface only. On a system it gets
*  ZCL_SE80_API, created by name - so that the screen does not depend on
*  the class that reads and writes the repository, and its unit tests
*  run transpiled without it (a test sets its own instance).
* ---------------------------------------------------------------------


  " ===== Types =====
  "! An object type of the repository (TROBJTYPE, R3TR ...)
  TYPES ty_objtype TYPE c LENGTH 4.

  TYPES:
    "! A repository object found by name
    BEGIN OF ty_s_object,
      object   TYPE ty_objtype,
      obj_name TYPE string,
    END OF ty_s_object.

  TYPES:
    BEGIN OF ty_s_source_result,
      source       TYPE string,
      source_local TYPE string,
      source_test  TYPE string,
      syntax_mode  TYPE string,
      lines        TYPE i,
      success      TYPE abap_bool,
      message      TYPE string,
    END OF ty_s_source_result.

  TYPES:
    BEGIN OF ty_s_method,
      cmpname  TYPE string,
      exposure TYPE string,
      mtdtype  TYPE string,
    END OF ty_s_method.
  TYPES ty_t_method TYPE STANDARD TABLE OF ty_s_method WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_field,
      name    TYPE string,
      keyflag TYPE string,
      typtype TYPE string,
      type    TYPE string,
    END OF ty_s_field.
  TYPES ty_t_field TYPE STANDARD TABLE OF ty_s_field WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_prop,
      label TYPE string,
      value TYPE string,
    END OF ty_s_prop.
  TYPES ty_t_prop TYPE STANDARD TABLE OF ty_s_prop WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_usage,
      object   TYPE string,
      obj_name TYPE string,
    END OF ty_s_usage.
  TYPES ty_t_usage TYPE STANDARD TABLE OF ty_s_usage WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_tree_leaf,
      text  TYPE string,
      icon  TYPE string,
      key   TYPE string,
      otype TYPE string,
    END OF ty_s_tree_leaf.
  TYPES:
    BEGIN OF ty_s_tree_child,
      text  TYPE string,
      icon  TYPE string,
      key   TYPE string,
      otype TYPE string,
      nodes TYPE STANDARD TABLE OF ty_s_tree_leaf WITH EMPTY KEY,
    END OF ty_s_tree_child.
  TYPES:
    BEGIN OF ty_s_tree_node,
      text  TYPE string,
      icon  TYPE string,
      key   TYPE string,
      otype TYPE string,
      nodes TYPE STANDARD TABLE OF ty_s_tree_child WITH EMPTY KEY,
    END OF ty_s_tree_node.
  TYPES ty_t_tree TYPE STANDARD TABLE OF ty_s_tree_node WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_check_msg,
      type    TYPE string,
      line    TYPE i,
      col     TYPE i,
      message TYPE string,
    END OF ty_s_check_msg.
  TYPES ty_t_check_msg TYPE STANDARD TABLE OF ty_s_check_msg WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_s_result,
      success TYPE abap_bool,
      message TYPE string,
    END OF ty_s_result.

  " ===== Write protection =====
  " The Object Navigator of this environment is READ-ONLY. All methods
  " that change the repository (save, activate, create, delete, rename,
  " copy, transport) refuse to run while this constant is abap_false.
  " Switching it on is a deliberate code change - and even then every
  " change still needs S_DEVELOP for the concrete package and object.
  CONSTANTS c_write_enabled TYPE abap_bool VALUE abap_false.

  " ===== Navigation =====
  METHODS get_package_tree
    IMPORTING iv_package    TYPE devclass
    RETURNING VALUE(result) TYPE ty_t_tree.

  METHODS search_objects
    IMPORTING iv_pattern    TYPE string
              iv_type       TYPE ty_objtype OPTIONAL
    RETURNING VALUE(result) TYPE ty_t_tree.

  " ===== Source Reading =====
  METHODS load_source
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE ty_s_source_result.

  " ===== Source Writing =====
  METHODS save_source
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
              iv_source     TYPE string
    RETURNING VALUE(result) TYPE ty_s_result.

  " ===== Activation =====
  METHODS activate_object
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE ty_s_result.

  " ===== Syntax Check =====
  METHODS check_syntax
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
              iv_source     TYPE string
    RETURNING VALUE(result) TYPE ty_t_check_msg.

  " ===== Pretty Printer =====
  METHODS pretty_print
    IMPORTING iv_source     TYPE string
    RETURNING VALUE(result) TYPE string.

  " ===== Metadata =====
  METHODS get_metadata
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    EXPORTING et_methods    TYPE ty_t_method
              et_fields     TYPE ty_t_field.

  " ===== Properties =====
  METHODS get_properties
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
              iv_source     TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE ty_t_prop.

  " ===== Where-Used =====
  METHODS get_where_used
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_usage.

  " ===== Utilities =====
  METHODS get_object_icon
    IMPORTING iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS get_text_elements
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS get_documentation
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS get_includes
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_object_status
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS delete_object
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS lock_in_transport
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
              iv_transport  TYPE trkorr
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS create_program
    IMPORTING iv_name       TYPE sobj_name
              iv_package    TYPE devclass
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS create_class
    IMPORTING iv_name       TYPE sobj_name
              iv_package    TYPE devclass
              iv_superclass TYPE string OPTIONAL
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS create_interface
    IMPORTING iv_name       TYPE sobj_name
              iv_package    TYPE devclass
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS get_subclasses
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_usage.

  METHODS get_implementations
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_usage.

  METHODS get_method_signature
    IMPORTING iv_classname  TYPE sobj_name
              iv_methodname TYPE string
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_class_events
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_source_statistics
    IMPORTING iv_source     TYPE string
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_variants
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_table_content
    IMPORTING iv_name       TYPE sobj_name
              iv_maxrows    TYPE i DEFAULT 10
    RETURNING VALUE(result) TYPE string.

  METHODS get_class_types
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS rename_object
    IMPORTING iv_old_name   TYPE sobj_name
              iv_new_name   TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE ty_s_result.

  METHODS get_fm_exceptions
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_class_constants
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_table_foreign_keys
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_package_info
    IMPORTING iv_package    TYPE devclass
    RETURNING VALUE(result) TYPE ty_t_prop.

  METHODS get_table_append_structures
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_class_friends
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_redefined_methods
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_lock_info
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS get_package_path
    IMPORTING iv_package    TYPE devclass
    RETURNING VALUE(result) TYPE string.

  METHODS copy_object
    IMPORTING iv_source_name TYPE sobj_name
              iv_source_type TYPE ty_objtype
              iv_target_name TYPE sobj_name
              iv_package     TYPE devclass
    RETURNING VALUE(result)  TYPE ty_s_result.

  METHODS get_table_tech_settings
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS compare_versions
    IMPORTING iv_name       TYPE sobj_name
              iv_type       TYPE ty_objtype
    RETURNING VALUE(result) TYPE string.

  METHODS get_program_attributes
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_field.

  METHODS get_object_dependencies
    IMPORTING iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE ty_t_usage.

  METHODS search_replace_source
    IMPORTING iv_source     TYPE string
              iv_search     TYPE string
              iv_replace    TYPE string
    EXPORTING ev_source     TYPE string
              ev_count      TYPE i.

  METHODS get_object_description
    IMPORTING iv_type       TYPE ty_objtype
              iv_name       TYPE sobj_name
    RETURNING VALUE(result) TYPE string.

  "! Superpackage of a package, initial for a package at the top
  METHODS get_parent_package
    IMPORTING iv_package    TYPE string
    RETURNING VALUE(result) TYPE string.

  "! The repository object (R3TR) of that name, initial when none
  METHODS find_object
    IMPORTING iv_name       TYPE string
    RETURNING VALUE(result) TYPE ty_s_object.

ENDINTERFACE.
