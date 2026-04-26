#!/bin/sh
# En Xcode, el build number con marca de hora se aplica vía
# Config/SharedApp.xcconfig + fase "Stamp build number" (BuildStamp.xcconfig en Derived).
# Para tocar el número en el .pbxproj (p. ej. como parte de un flujo Fastlane) usa:
#   bundle exec fastlane stamp_build
echo "Para estampar el build: usa un Archive/Release en Xcode, o: bundle exec fastlane stamp_build" >&2
exit 0
