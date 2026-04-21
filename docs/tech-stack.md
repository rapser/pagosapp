# Stack tecnológico

## 📋 Stack Tecnológico

### Core Technologies
- **Swift 6.0**: Strict concurrency, modern syntax
- **iOS 18.5+**: Latest features
- **SwiftUI**: 100% declarative UI con @Observable
- **SwiftData**: Local persistence (reemplaza CoreData)
- **Async/Await**: Modern concurrency (sin Combine)

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
- **Supabase Swift SDK** (v2.5.1+): Cliente oficial

### Arquitectura & Patrones
- **Clean Architecture**: Domain/Data/Presentation (100%)
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
- **Documentación técnica**: [TECHNICAL_AUDIT.md](../TECHNICAL_AUDIT.md) *(si existe)*, [ADR](adr/), [ingeniería](engineering/), [runbooks](runbooks/) bajo `docs/`.

---
