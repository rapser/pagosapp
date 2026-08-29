# PagosApp

> App iOS para **pagos recurrentes**, **recordatorios** y **tarjetas de crédito**, con Clean Architecture, Supabase, SwiftData y enfoque offline-first.

[![iOS](https://img.shields.io/badge/iOS-26.0%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-26%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-green.svg)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Version](https://img.shields.io/badge/Version-1.0.0(20)-blue.svg)](CHANGELOG.md)

## Qué hace

- **Pagos**: recurrentes, multi-moneda (PEN/USD), pagos agrupados de tarjeta bimoneda, notificaciones y sincronización con el calendario del sistema.
- **Recordatorios**: eventos no monetarios (renovaciones, impuestos, etc.) con notificaciones propias.
- **Tarjetas**: crea, edita y elimina tarjetas de crédito; número completo y PIN protegidos con Face ID/Touch ID, solo en Keychain.
- **Calendario, historial y estadísticas**: vista unificada, accesibles desde Inicio y Ajustes.
- **Cuenta**: login con Supabase, biometría, sincronización manual desde Ajustes.

Detalle completo de funcionalidades: [`docs/product-overview.md`](docs/product-overview.md).

## Empezar

1. Clona el repo y entra en la raíz (debes ver `pagosApp/`, `Config/`, `pagosApp.xcodeproj`).
2. Copia credenciales: `cp Config/Secrets.template.xcconfig pagosApp/Config/Secrets.xcconfig` y agrega tu URL y anon key de Supabase (en `.xcconfig` usa `https:/$()/tu-proyecto.supabase.co` para escapar el `//`).
3. `open pagosApp.xcodeproj` y **⌘R**.

Requisitos, SwiftLint y detalle de instalación: [`docs/setup.md`](docs/setup.md).

## Documentación

Arquitectura, stack, estructura del repo, testing, CI y seguridad están indexados en **[`docs/README.md`](docs/README.md)**.

| Necesito... | Dónde |
|---|---|
| Subir una build a TestFlight | `bundle exec fastlane menu` desde la raíz — guía completa en [`fastlane/SETUP.md`](fastlane/SETUP.md) |
| Entender la arquitectura | [`docs/architecture.md`](docs/architecture.md) |
| Correr los tests | [`docs/testing.md`](docs/testing.md) |
| Ver qué cambió | [`CHANGELOG.md`](CHANGELOG.md) |

## Licencia y autor

MIT (ver `LICENSE` si está en el repositorio). Autor: [@rapser](https://github.com/rapser).
