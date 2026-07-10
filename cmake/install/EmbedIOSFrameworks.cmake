# ============================================================================
# EmbedIOSFrameworks.cmake
# Copies dynamically-linked frameworks into the iOS app bundle and adds the
# runtime search path, replicating Xcode's "Embed Frameworks" build phase —
# which never runs under the Ninja Multi-Config generator this project uses
# to build iOS. Without this, the app fails to launch (dyld: Library not
# loaded, no LC_RPATH's found).
# ============================================================================
#
# Required Variables (passed from Install.cmake):
#   QGC_STAGING_BUNDLE_PATH  => Full path to MyApp.app bundle
#   QGC_IOS_EMBED_FRAMEWORKS => List of .framework paths to embed (may be empty)
#

if(NOT QGC_IOS_EMBED_FRAMEWORKS)
    message(STATUS "QGC: no additional iOS frameworks to embed")
else()
    set(_qgc_ios_frameworks_dir "${QGC_STAGING_BUNDLE_PATH}/Frameworks")
    file(MAKE_DIRECTORY "${_qgc_ios_frameworks_dir}")

    foreach(_fw IN LISTS QGC_IOS_EMBED_FRAMEWORKS)
        if(NOT EXISTS "${_fw}")
            message(WARNING "QGC: iOS framework to embed not found, skipping: ${_fw}")
            continue()
        endif()

        set(_fw_source "${_fw}")
        if(_fw MATCHES "\\.xcframework$")
            # An .xcframework bundles one .framework per platform/arch slice
            # (ios-arm64, ios-x86_64-simulator, ...). The binary's LC_LOAD_DYLIB
            # references the flat @rpath/<name>.framework/<name> form, so pick the
            # physical-device slice and embed only its inner .framework — same
            # slice-selection convention as cmake/GStreamer/platform/IOS.cmake.
            file(GLOB _qgc_ios_slice_dirs LIST_DIRECTORIES true "${_fw}/ios-*")
            list(FILTER _qgc_ios_slice_dirs EXCLUDE REGEX "-(simulator|maccatalyst)$")
            if(NOT _qgc_ios_slice_dirs)
                message(WARNING "QGC: no device slice found in ${_fw}, skipping")
                continue()
            endif()
            list(GET _qgc_ios_slice_dirs 0 _qgc_ios_slice_dir)
            file(GLOB _qgc_ios_inner_fw LIST_DIRECTORIES true "${_qgc_ios_slice_dir}/*.framework")
            if(NOT _qgc_ios_inner_fw)
                message(WARNING "QGC: no .framework found in slice ${_qgc_ios_slice_dir}, skipping")
                continue()
            endif()
            list(GET _qgc_ios_inner_fw 0 _fw_source)
        endif()

        cmake_path(GET _fw_source FILENAME _fw_name)
        message(STATUS "QGC: embedding iOS framework ${_fw_name}")
        file(REMOVE_RECURSE "${_qgc_ios_frameworks_dir}/${_fw_name}")
        file(COPY "${_fw_source}" DESTINATION "${_qgc_ios_frameworks_dir}")
    endforeach()
endif()

cmake_path(GET QGC_STAGING_BUNDLE_PATH STEM QGC_TARGET_APP_NAME)
set(_qgc_ios_main_binary "${QGC_STAGING_BUNDLE_PATH}/${QGC_TARGET_APP_NAME}")

message(STATUS "QGC: adding @executable_path/Frameworks rpath to ${QGC_TARGET_APP_NAME}")
execute_process(
    COMMAND install_name_tool -add_rpath "@executable_path/Frameworks" "${_qgc_ios_main_binary}"
    RESULT_VARIABLE _qgc_ios_rpath_rc
    ERROR_VARIABLE _qgc_ios_rpath_err
)
# install_name_tool exits non-zero if the rpath is already present (re-running
# cmake --install on an existing build tree) — that case is harmless, not fatal.
if(NOT _qgc_ios_rpath_rc EQUAL 0 AND NOT _qgc_ios_rpath_err MATCHES "same path")
    message(FATAL_ERROR "QGC: failed to add rpath to ${_qgc_ios_main_binary}: ${_qgc_ios_rpath_err}")
endif()
