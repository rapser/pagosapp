# Changelog

El contenido de este fichero describe la **versión publicada** y el **alcance** de PagosApp (qué ofrece el producto y con qué stack se construye). El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [1.0.0] – Build 20 – 2026-04-26

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

- **iOS 18.0+**, **Swift 6.0** (comprobaciones estrictas de concurrencia en el target de la app), **SwiftUI** y **@Observable** en presentación.
- **SwiftData** (persistencia local), **Supabase** (auth + PostgreSQL + RLS) con **Supabase Swift** (versión fijada en `Package.resolved`).
- **Clean Architecture** por features (Domain / Data / Presentation), casos de uso, repositorios, inyección por contenedores, mapeos y DTOs.
- **EventBus** con eventos de dominio tipados y `AsyncStream`; **EventKit**, **UserNotifications**, **LocalAuthentication**, **Keychain**, **OSLog**.
- **CI** (GitHub Actions: build, SwiftLint), **Fastlane** y opción **SwiftLint** local; documentación bajo `docs/`.

Autor: [@rapser](https://github.com/rapser). Licencia: MIT (ver `LICENSE` si está presente en el repositorio).
