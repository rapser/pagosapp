#!/bin/sh
# Mismo criterio YYYYMM.DD.HHmm. Con solo Xcode, el build estampado va en el Info.plist
# (fase al final). Para fijar el número en el .pbxproj: bundle exec fastlane stamp_build
echo "Solo pbx: bundle exec fastlane stamp_build" >&2
echo "Solo plists .app: Archive/Release con la fase Set CFBundleVersion en Xcode" >&2
exit 0
