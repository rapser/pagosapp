# Stack tecnológico

## 📋 Stack Tecnológico

### Core Technologies
- **Swift 6.0**: `SWIFT_VERSION` en el target de la app (Xcode); comprobación estricta de concurrencia; async/await
- **iOS 18.0+**: Deployment mínimo del target `pagosApp` (ajustar en Build Settings si cambia)
- **SwiftUI**: UI declarativa con @Observable
- **SwiftData**: persistencia local (sustituye a Core Data para los modelos de la app)
- **Async/Await**: concurrencia moderna (sin Combine en la lógica de negocio principal)

### Frameworks iOS
- **EventKit**: Sincronización con Calendar.app
- **UserNotifications**: Notificaciones locales
- **LocalAuthentication**: Face ID / Touch ID
- **Security (Keychain)**: Almacenamiento seguro de credenciales
- **OSLog**: Logging estructurado

### Backend & Cloud
- **Supabase**: Backend as a Service
  - PostgreSQL database
  - Row Level Security (RLS)
  - Authentication & User Management
- **Supabase Swift SDK**: Cliente oficial (versión fijada en `Package.resolved`; p. ej. 2.31.x)

### Arquitectura & Patrones
- **Clean Architecture**: Domain / Data / Presentation
- **MVVM**: ViewModels con @Observable
- **Repository Pattern**: Abstracción de datos
- **Use Cases Pattern**: Business logic encapsulation
- **Dependency Injection**: Factory pattern con containers
- **Mapper Pattern**: Conversiones entre capas
- **DTO Pattern**: Separación de modelos por capa

### Observability & Reactive Systems
- **EventBus**: Sistema reactivo type-safe con AsyncStream (reemplaza NotificationCenter)
- **DomainEvent**: Eventos de dominio (PaymentCreated, PaymentUpdated, PaymentDeleted, PaymentsSynced, etc.)
- **Logging**: **OSLog** en puntos críticos; trazas muy verbosas de arranque/auth/red se mantienen al mínimo para una consola Xcode más limpia (errores y advertencias relevantes se conservan)

### CI y calidad
- **GitHub Actions** ([`.github/workflows/ci.yml`](../.github/workflows/ci.yml)): **build** con `xcodebuild` (simulador iOS genérico) + **SwiftLint** en cada push/PR a `main`, `master` o `develop` (runner `macos-15`).
- **TestFlight en CI** ([`.github/workflows/testflight-develop.yml`](../.github/workflows/testflight-develop.yml)): solo en **`push` a `develop`** (tras merge del PR); no en `main`. Secretos y firma: [`.github/GITHUB_ACTIONS_TESTFLIGHT.md`](../.github/GITHUB_ACTIONS_TESTFLIGHT.md).
- **Fastlane**: menú `bundle exec fastlane menu`; guía replicable en [fastlane/SETUP.md](../fastlane/SETUP.md); resumen en [fastlane/README.md](../fastlane/README.md).
- **SwiftLint**: configuración en [`.swiftlint.yml`](../.swiftlint.yml) en la raíz del repo.
- **Documentación adicional bajo `docs/`**: [ADR](adr/), [ingeniería](engineering/), [runbooks](runbooks/) *(carpetas opcionales; créalas si las necesitas)*.

---
