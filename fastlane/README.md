fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios stamp_build

```sh
[bundle exec] fastlane ios stamp_build
```

Solo pone el número de build por marca de tiempo (sin archive)

### ios reference

```sh
[bundle exec] fastlane ios reference
```

Lista comandos útiles (referencia / CI; no abre menú)

### ios menu

```sh
[bundle exec] fastlane ios menu
```

Menú: IPA local o pipelines de subida a TestFlight

### ios ipa_pruebas

```sh
[bundle exec] fastlane ios ipa_pruebas
```

Archive + IPA Ad Hoc

### ios ipa_app_store

```sh
[bundle exec] fastlane ios ipa_app_store
```

Archive + IPA App Store (sin subir)

### ios release_app_store_connect

```sh
[bundle exec] fastlane ios release_app_store_connect
```

Archive + subida a ASC/TestFlight (equivalente a App Store Connect en Organizer)

### ios release_testflight_internal

```sh
[bundle exec] fastlane ios release_testflight_internal
```

Archive + subida con enfoque solo testers internos (equivalente a TestFlight internal en Organizer)

### ios upload_testflight

```sh
[bundle exec] fastlane ios upload_testflight
```

Sube el último IPA app-store ya generado (requiere API Key en .env)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
