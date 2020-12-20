##
#
# For test we use standard CMLIB test/TEST.cmake macros
#

IF(NOT EXISTS "${CMLIB_DIR}")
	MESSAGE(FATAL_ERROR "Cannot find CMLIB_DIR '${CMLIB_DIR}'")
ENDIF()

INCLUDE("${CMLIB_DIR}/test/TEST.cmake")
