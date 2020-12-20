
# Just register no storage
SET(STORAGE_LIST TESTLIB)

# Define URI for TESTLIB storage. We can use CMLIB ENV variables
SET(STORAGE_LIST_TESTLIB "${CMLIB_REQUIRED_ENV_REMOTE_URL}/cmakelib-test.git")
