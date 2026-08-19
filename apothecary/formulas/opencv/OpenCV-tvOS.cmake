# Stock OpenCV ships cmake/platforms/OpenCV-iOS.cmake (empty) but nothing
# for CMAKE_SYSTEM_NAME=tvOS. ios-cmake 4.6 sets that name, so without this
# file OpenCV treats tvOS as generic APPLE and compiles macosx_conversions.mm
# (AppKit), which does not exist on tvOS.
message(STATUS "OpenCV: tvOS target (no AppKit, no iOS camera)")
set(WITH_CAP_IOS OFF)
set(WITH_AVFOUNDATION OFF)
