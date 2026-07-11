# ============================================================================
# CreateIOSIPA.cmake
# Packages the iOS .app bundle into a .ipa for distribution
# ============================================================================
#
# Required Variables (passed from Install.cmake):
#   QGC_STAGING_BUNDLE_PATH => Full path to MyApp.app bundle
#

message(STATUS "QGC: Creating iOS IPA package...")

# ============================================================================
# Prepare Payload Directory
# ============================================================================

set(QGC_IPA_PACKAGE_DIR "${CMAKE_BINARY_DIR}/package")
set(QGC_IPA_PAYLOAD_DIR "${QGC_IPA_PACKAGE_DIR}/Payload")

file(REMOVE_RECURSE "${QGC_IPA_PACKAGE_DIR}")
file(MAKE_DIRECTORY "${QGC_IPA_PAYLOAD_DIR}")

file(COPY "${QGC_STAGING_BUNDLE_PATH}" DESTINATION "${QGC_IPA_PAYLOAD_DIR}")

# ============================================================================
# Create IPA
# ============================================================================

cmake_path(GET QGC_STAGING_BUNDLE_PATH STEM QGC_TARGET_APP_NAME)
set(QGC_IPA_NAME "${QGC_TARGET_APP_NAME}.ipa")
set(QGC_IPA_OUTPUT_PATH "${CMAKE_BINARY_DIR}/${QGC_IPA_NAME}")

message(STATUS "QGC: Building ${QGC_IPA_NAME}...")

# ditto (rather than zip) preserves resource forks/extended attributes, matching
# how Xcode itself produces .ipa archives.
execute_process(
    COMMAND ditto -c -k --sequesterRsrc --keepParent Payload "${QGC_IPA_OUTPUT_PATH}"
    WORKING_DIRECTORY "${QGC_IPA_PACKAGE_DIR}"
    COMMAND_ECHO STDOUT
    COMMAND_ERROR_IS_FATAL ANY
)

message(STATUS "QGC: IPA created successfully: ${QGC_IPA_OUTPUT_PATH}")
