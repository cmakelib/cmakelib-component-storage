## Main
#
# CMLIB module which track storage repository.
#
# CMLIB Shared storage is storage in which global links are gathered.
# 
# List of functions
# - CMLIB_STORAGE_TEMPLATE_INSTANCE
# 
#

SET(CMLIB_STORAGE_FOUND 1)
SET(CMLIB_STORAGE_DIR "${CMAKE_CURRENT_LIST_DIR}")

IF(COMMAND _CMLIB_STORAGE_INIT)
	_CMLIB_LIBRARY_DEBUG_MESSAGE("STORAGE already included, calling init")
	_CMLIB_STORAGE_INIT()
	RETURN()
ENDIF()

FIND_PACKAGE(CMLIB)

SET(CMLIB_STORAGE_REPOSITORY_DEFAULT_URI "${CMLIB_REQUIRED_ENV_REMOTE_URL}/cmakelib-test.git"
	CACHE STRING
	"Default URL which is used if no CONFIG_FILENAME is found"
)

SET(_CMLIB_STORAGE_CONFIG_FILENAME "CMLibStorage.cmake"
	CACHE INTERNAL
	"Filename if the STORAGE config located in GIT root"
)



##
#
# Function which apply set of key-value sets to
# given template string.
#
# [Definitions]
#
# Under S we suggest S(ASCII). S = S(ASCII)
#
# Let the non-empty string from S is called Key.
# Let the string from S is called Pattern.
# Let the string from S is called Template.
#
# Let the KeySet is finite set of all Keys.
# Let the TemplateSet is finite set of all Templates.
# Let the PatternSet is finite set of all Patterns.
#
# Function KeyToPattern: KeySet --> PatternSet is defined as
# KeyToPattern(key) = '<' + key + '>'. (it'a bijection!)
#
# We say that Template is divisible by pattern p from PatternSet if there are
# string a,b from S: Template = a + p + b
#
# We say that Template contains Pattern if is divisible by Pattern.
#
# We say that Template is immutable against given Pattern if the Template
# is not divisible by Pattern.
#
# The base of this function is apply Pattern on given Template
# If we want to "replace" Pattern we need value which will replace pattern.
#
# Let the string from S is called Value.
# Let the ValueSet is finite set of all Values.
#
# Define function KeyToValue: KeySet --> ValueSet which for each k from KeySet
# assign one v from ValueSet.
#
# Lets define function Apply(t, k, KeyToValue): TemplateSet x KeySet --> TemplateSet
#    t in TemplateSet, k in KeySet;
#    Lets define p from PatternSet as p = KeyToPattern(k);
#    The division of 't' against 'p' must exist, t = a + p + b (where a, b from S)
#    Then x = Apply(t, k) = Apply(a, k) + KeyToValue(k) + Apply(b, k) ==> x is immutable against p = KeyToPattern(k).
#
# Example:
# t = "MyNiceBread_<keya>Jupik<keyb><keya>Supik", k = "keya", KeyToValue(k) = "TEST"
# Apply(t, k) = "MyNiceBread_TESTJupik<keyb>TESTSupik"
#
# [Function arguments]
#
# <function>(
#		<output_var>
#		<template>
#		[<key_1> <value_1> ... <key_x> <value_x>] // KeyToValue mapping
# )
#
FUNCTION(CMLIB_STORAGE_TEMPLATE_INSTANCE output_var)
	LIST(GET ARGN 0 template_name)
	IF(NOT (DEFINED ${template_name}))
		MESSAGE(FATAL_ERROR "Template var '${template_name}' is not defined in current context")
	ENDIF()

	_CMLIB_LIBRARY_DEBUG_MESSAGE("CMLIB_STORAGE_TEMPLATE: Lower arguments in template ${template_name}")

	STRING(REGEX MATCHALL "<([^>]+)>" template_arguments "${${template_name}}")
	SET(template_arguments_lower)
	FOREACH(T IN LISTS template_arguments)
		STRING(TOLOWER "${T}" T_lower)
		_CMLIB_LIBRARY_DEBUG_MESSAGE("CMLIB_STORAGE_TEMPLATE: template arguments - key: '${T}' key_lower: '${T_lower}'")
		LIST(APPEND template_arguments_lower ${T_lower})
	ENDFOREACH()

	LIST(LENGTH ARGN argn_length)
	MATH(EXPR arguments_length "${argn_length} - 1")

	MATH(EXPR is_divisible_be_two "(${arguments_length} % 2)")
	IF(NOT is_divisible_be_two EQUAL 0)
		MESSAGE(FATAL_ERROR "Invalid number of template arguments! Not all are key-value pairs")
	ENDIF()

	SET(template_expanded "${${template_name}}")
	IF(NOT arguments_length LESS 2)
		LIST(SUBLIST ARGN 1 ${arguments_length} arguments)
		MATH(EXPR arguments_list_index "${arguments_length} - 1")
		FOREACH(i RANGE 0 ${arguments_list_index} 2)
			MATH(EXPR value_index "${i} + 1")
			LIST(GET arguments ${i} key)
			LIST(GET arguments ${value_index} value)
			STRING(TOLOWER "${key}" key_lower)

			_CMLIB_LIBRARY_DEBUG_MESSAGE("CMLIB_STORAGE_TEMPLATE: key: ${key}, key_lower: ${key_lower}, value: ${value}")

			LIST(FIND template_arguments_lower "<${key_lower}>" found_index)
			IF(found_index EQUAL -1)
				MESSAGE(FATAL_ERROR "Could not find '${key}' in template '${template_name}'")
			ENDIF()

			LIST(GET template_arguments ${found_index} _arg)
			STRING(REPLACE "${_arg}" "${value}" template_expanded "${template_expanded}")
			_CMLIB_LIBRARY_DEBUG_MESSAGE("CMLIB_STORAGE_TEMPLATE: replaced value '${template_expanded}'")
		ENDFOREACH()
	ENDIF()
	SET(${output_var} ${template_expanded} PARENT_SCOPE)
ENDFUNCTION()



##
#
# Initialize CMLIB_STORAGE module.
#
# Track module under { CMLIB STORAGE <storage_name> } keywords
# and include STORAGE.cmake file.
#
# <function>(
# )
#
MACRO(_CMLIB_STORAGE_INIT)
	_CMLIB_STORAGE_LOAD_REMOTES(storage_uri_list)
	WHILE(storage_uri_list)
		LIST(POP_FRONT storage_uri_list storage_name storage_uri storage_revision)
		_CMLIB_LIBRARY_DEBUG_MESSAGE("Storage name: ${storage_name}")
		_CMLIB_LIBRARY_DEBUG_MESSAGE("Storage uri: ${storage_uri}")
		_CMLIB_LIBRARY_DEBUG_MESSAGE("Storage revision: ${storage_revision}")
		CMLIB_DEPENDENCY(
			KEYWORDS CMLIB STORAGE ${storage_name}
			TYPE DIRECTORY
			URI "${storage_uri}"
			URI_TYPE GIT
			GIT_REVISION "${storage_revision}"
			OUTPUT_PATH_VAR storage_path
		)	
		SET(module_entry "${storage_path}/STORAGE.cmake")
		IF(NOT EXISTS "${module_entry}")
			MESSAGE(FATAL_ERROR "Invalid STORAGE repository. STORAGE.cmake missing!")
		ENDIF()
		INCLUDE(${module_entry})
	ENDWHILE()
	UNSET(storage_uri_list)
ENDMACRO()



## Helper
#
# Determine STORAGE URI from which the STORAGE GIT repository
# will be donwloaded.
#
# Config file must define variable 'CMLIB_STORAGE_LIST' as a list
# in which names of the remote storages will be filled.
#
# For each 'item' in 'STORAGE_LIST' must be defined variable in form
#   let 'item_upper' uppercase version of 'item' then STORAGE_LIST_<item_upper>
#   must be defined and the value of this variable must be strig value in form '<uri>'
#   where 'uri' is valid git URI
#
# <output_var_list> represents list in form
#   [
#	  <storage_uppercase_name_1>, <uri_1>, <revision_1>
#	  <storage_uppercase_name_2>, <uri_2>, <revision_2>
#     ...
#   ]
#
# <function> (
#		<output_var_list>
# )
#
FUNCTION(_CMLIB_STORAGE_LOAD_REMOTES output_var_list)
	FILE(TO_CMAKE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${_CMLIB_STORAGE_CONFIG_FILENAME}" config_file)
	_CMLIB_LIBRARY_DEBUG_MESSAGE(${config_file})
	IF(NOT EXISTS "${config_file}")
		MESSAGE(WARNING "No '${_CMLIB_STORAGE_CONFIG_FILENAME}' file found for CMLIB_STORAGE functionality. Define one or disable storage. "
			"Test URI used - ${CMLIB_STORAGE_REPOSITORY_DEFAULT_URI}")
		SET(${output_var_list} CMLIBTESTSTORAGE "${CMLIB_STORAGE_REPOSITORY_DEFAULT_URI}" PARENT_SCOPE)
		RETURN()
	ENDIF()

	UNSET(STORAGE_LIST)
	INCLUDE(${config_file})
	IF(NOT DEFINED STORAGE_LIST)
		MESSAGE(FATAL_ERROR "STORAGE_LIST variable missing in '${config_file}'")
	ENDIF()

	SET(storage_uri_list)
	FOREACH(storage_name IN LISTS STORAGE_LIST)
		STRING(TOUPPER "${storage_name}" storage_name_upper)
		SET(entry_var          STORAGE_LIST_${storage_name_upper})
		SET(entry_var_revision STORAGE_LIST_${storage_name_upper}_REVISION)
		IF(NOT DEFINED ${entry_var})
			MESSAGE(FATAL_ERROR "Storage list entry '${entry_var}' for '${storage_name}' is not defined")
		ENDIF()
		SET(default_revision)
		IF(NOT DEFINED ${entry_var_revision})
			SET(default_revision master)
		ELSE()
			SET(default_revision ${${entry_var_revision}})
		ENDIF()
		LIST(APPEND storage_uri_list ${storage_name_upper} ${${entry_var}} ${default_revision})
	ENDFOREACH()
	SET(${output_var_list} ${storage_uri_list} PARENT_SCOPE)
ENDFUNCTION()



##
#
# Initialize
#
_CMLIB_STORAGE_INIT()
