# ============================================================================
# CompileIOSLaunchScreen.cmake
# Compiles the iOS launch screen .xib into a .nib Xcode's "Copy Bundle
# Resources" build phase would normally compile automatically — which never
# runs under the Ninja Multi-Config generator this project uses to build iOS.
# A raw, uncompiled .xib left in the bundle does not satisfy
# UILaunchStoryboardName and can abort UIKit's app launch preparation.
# ============================================================================
#
# Required Variables (passed from Install.cmake):
#   QGC_STAGING_BUNDLE_PATH  => Full path to MyApp.app bundle
#   QGC_IOS_LAUNCH_SCREEN_SRC => Path to the source .xib (may be empty)
#

if(NOT QGC_IOS_LAUNCH_SCREEN_SRC)
    message(STATUS "QGC: no iOS launch screen configured, skipping compile")
    return()
endif()

find_program(_qgc_ibtool NAMES ibtool
    PATHS "/Applications/Xcode.app/Contents/Developer/usr/bin"
    NO_CACHE
)
if(NOT _qgc_ibtool)
    execute_process(
        COMMAND xcrun --find ibtool
        OUTPUT_VARIABLE _qgc_ibtool
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
endif()
if(NOT _qgc_ibtool)
    message(WARNING "QGC: ibtool not found; iOS launch screen will not be compiled "
        "(raw .xib left in bundle — UIKit may fail to launch the app)")
    return()
endif()

cmake_path(GET QGC_IOS_LAUNCH_SCREEN_SRC STEM QGC_LAUNCH_SCREEN_NAME)
set(_qgc_ios_nib_out "${QGC_STAGING_BUNDLE_PATH}/${QGC_LAUNCH_SCREEN_NAME}.nib")

message(STATUS "QGC: compiling iOS launch screen ${QGC_LAUNCH_SCREEN_NAME}.xib -> .nib")
execute_process(
    COMMAND "${_qgc_ibtool}" --compile "${_qgc_ios_nib_out}" "${QGC_IOS_LAUNCH_SCREEN_SRC}"
    COMMAND_ERROR_IS_FATAL ANY
)

# Qt's deploy step copies the raw .xib into the bundle root; remove it now that
# the compiled .nib (what iOS actually resolves) is in place.
file(REMOVE "${QGC_STAGING_BUNDLE_PATH}/${QGC_LAUNCH_SCREEN_NAME}.xib")
