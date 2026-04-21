# PagosApp

> Aplicación iOS para **pagos recurrentes** y **recordatorios**, con Clean Architecture, Supabase, SwiftData y sincronización offline-first.

[![iOS](https://img.shields.io/badge/iOS-18.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16.4%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-green.svg)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Version](https://img.shields.io/badge/Version-1.0.0(20)-blue.svg)](CHANGELOG.md)

## Inicio rápido

1. Clona el repositorio y entra en la raíz (debes ver `pagosApp/`, `Config/`, `pagosApp.xcodeproj`).
2. Copia credenciales: `cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig` y edita con tu URL y anon key de Supabase.
3. Abre el proyecto: `open pagosApp.xcodeproj`.
4. En Xcode, asigna `Secrets.xcconfig` a las configuraciones **Debug** y **Release** (proyecto → Info → Configurations).
5. **⌘R** para compilar y ejecutar.

**Opcional:** `brew install swiftlint` y `swiftlint lint` (misma regla que en CI).

## Documentación

La guía larga (producto, arquitectura, stack, instalación, estructura, tests, seguridad y contribución) está en **[`docs/README.md`](docs/README.md)** con enlaces a cada sección.

## CI, Fastlane y secretos

| Recurso | Ubicación |
|---------|-----------|
| CI (build + SwiftLint en PR a `develop`) | [`.github/workflows/ci.yml`](.github/workflows/ci.yml) |
| TestFlight en push a `develop` | [`.github/workflows/testflight-develop.yml`](.github/workflows/testflight-develop.yml) |
| Secretos y firma en GitHub Actions | [`.github/GITHUB_ACTIONS_TESTFLIGHT.md`](.github/GITHUB_ACTIONS_TESTFLIGHT.md) |
| Fastlane (menú, lanes, variables) | [`fastlane/README.md`](fastlane/README.md), [`fastlane/SETUP.md`](fastlane/SETUP.md) |
| Plantilla de variables Fastlane | [`fastlane/.env.example`](fastlane/.env.example) |
| Configuración de credenciales locales | [`Config/README.md`](Config/README.md) |

## Changelog

Historial de versiones: [`CHANGELOG.md`](CHANGELOG.md).

## Licencia y autor

MIT (detalle en el repositorio si existe el archivo `LICENSE`). Autor: **[@rapser](https://github.com/rapser)**.
