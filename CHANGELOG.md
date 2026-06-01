# Changelog

El contenido de este fichero describe la **versión publicada** y el **alcance** de PagosApp (qué ofrece el producto y con qué stack se construye). El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [Unreleased]

### Added

- **Edición de TC bimoneda**: al editar un pago de tarjeta de crédito registrado con una sola moneda (solo soles o solo dólares), ahora se muestra la sección `DualCurrencyAmountSection` con ambos campos. Si el usuario ingresa un monto en la moneda faltante y guarda, el sistema crea automáticamente el registro hermano y vincula ambos pagos con un `groupId` compartido — sin necesidad de crear un segundo pago manualmente.
- **Hint contextual en edición TC**: el texto de ayuda bajo los campos de monto cambia dinámicamente según la moneda que está vacía ("Puedes agregar un monto en dólares" / "...en soles") cuando se edita un pago TC con una sola moneda registrada.

### Fixed

- **TestFlight / GitHub Actions**: el workflow ya no empaqueta placeholders de Supabase como si fueran una URL válida; `AppConfiguration` exige `https`, host y clave configurables, y el cliente demo solo se usa cuando la configuración real no es válida. El workflow `testflight-develop.yml` genera `pagosApp/Config/Secrets.xcconfig` desde los secretos del repositorio `SUPABASE_URL` y `SUPABASE_ANON_KEY` (con escape `://` → `:/$()/` para `.xcconfig`).
- **Login**: `LoginView` usa `@Environment(AppDependencies.self)` como el resto de la app, alineado con la inyección del bootstrap.

## [1.0.0] – Build 20

### Producto

- **Pagos recurrentes**: CRUD, categorías, multi-moneda (PEN/USD), búsqueda y filtros, duplicación, pagos agrupados bimoneda con un solo evento de calendario.
- **Recordatorios** (independientes de pagos): tipos, título, descripción, fecha, completado, notificaciones configurables, sincronización con Supabase.
- **Calendario**: vista unificada de pagos y recordatorios; integración con Calendario de iOS (EventKit) y sincronización automática de eventos con los pagos.
- **Notificaciones locales**: avisos para pagos y recordatorios; restauración al iniciar sesión.
- **Estadísticas e historial**: gráficos por categoría y mes, totales; accesibles desde Ajustes.
- **Cuenta y datos**: registro e inicio de sesión (Supabase), biometría, perfil de usuario, cierre de sesión.
- **Offline-first y nube**: SwiftData en dispositivo, sincronización manual desde Ajustes (pagos y recordatorios) con Supabase.
- **Internacionalización**: español (por defecto), inglés y portugués.

### Plataforma y stack

- **iOS 26.0+** (deployment mínimo alineado entre app y target de tests), **Swift 6.0** con comprobación estricta de concurrencia, **SwiftUI** y **@Observable** en presentación.
- **SwiftData** (persistencia local), **Supabase** (auth + PostgreSQL + RLS) con **Supabase Swift** (versión fijada en `Package.resolved`).
- **Clean Architecture** por features (Domain / Data / Presentation), casos de uso, repositorios, inyección por contenedores, mapeos y DTOs.
- **EventBus** con eventos de dominio tipados y `AsyncStream`; **EventKit**, **UserNotifications**, **LocalAuthentication**, **Keychain**, **OSLog**.
- **Apariencia global UIKit** (`AppGlobalAppearance`): barra de navegación con fondo al estilo del sistema; títulos y tinte de barra con color **AppPrimary**; en iOS 26 se usa `prominentButtonAppearance` (sustituye el API deprecado de “Done” en `UINavigationBarAppearance`).

### Calidad, CI y documentación

- **Tests unitarios** (Swift Testing): validadores (email, contraseña), mappers de pagos y recordatorios, cobertura de mensajes de error de dominio (pagos y auth); ajuste de deployment del target de tests al mismo mínimo iOS que la app.
- **CI** (GitHub Actions en PRs a `develop`): **build** en simulador, **`xcodebuild test`**, **SwiftLint** (límites de línea/archivo reforzados de forma progresiva).
- **TestFlight** (otro workflow): subida con Fastlane y secretos de App Store Connect; no forma parte del job de CI de calidad.
- **Documentación de pruebas**: [`docs/testing.md`](docs/testing.md) (cómo ejecutar tests, CI, Definition of Done en PRs) y [`docs/test-priority-inventory.md`](docs/test-priority-inventory.md) (prioridad sugerida por capas).

Autor: [@rapser](https://github.com/rapser). Licencia: MIT (ver `LICENSE` si está presente en el repositorio).
