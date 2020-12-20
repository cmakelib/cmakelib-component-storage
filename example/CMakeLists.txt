CMAKE_MINIMUM_REQUIRED(VERSION 3.16)
PROJECT(CMLIB_ENV_TEST)

#
# For CMLIB installation guide look att cmakelib repository readme
#
FIND_PACKAGE(CMLIB COMPONENTS STORAGE)

IF(MY_STORAGE_VARIABLE STREQUAL "StorageVariable")
	MESSAGE(STATUS "---> STORAGE sucessfully inicialized! Yup!")
ELSE()
	MESSAGE(FATAL_ERROR "There is a problem with storage init!")
ENDIF()
