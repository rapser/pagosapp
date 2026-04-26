# Estructura del proyecto

## 📁 Estructura del Proyecto

```
pagosApp/
├── App/
│   ├── pagosAppApp.swift                    # @main → `PagosAppApp` (punto de entrada)
│   ├── Main/                                # AppBootstrapView, ContentView, ciclo de vida, deep links
│   ├── Configuration/                       # SupabaseClientFactory, SSL pinning, ModelContainer, AppConfiguration
│   └── DI/                                  # AppDependencies y contenedores por feature
│
├── Auth/                                    # Autenticación (Clean Architecture; no está bajo `Features/`)
│   ├── Domain/                              # Entidades, UseCases, repositorio protocolo, errores
│   ├── Data/                                # DTOs, mappers, repositorio impl, data sources (Keychain, Supabase)
│   ├── Presentation/                        # Views, ViewModels, SessionCoordinator
│   └── DI/                                  # AuthDependencyContainer
│
├── Core/                                    # EventBus, dominio compartido (eventos, logging, sync ports)
│
├── Features/                                # Resto de features
│   ├── Payments/
│   │   ├── Domain/
│   │   │   ├── Entities/                   # Payment, Currency, Category
│   │   │   ├── Repositories/               # PaymentRepositoryProtocol
│   │   │   ├── UseCases/                   # CreatePaymentUseCase, UpdatePaymentUseCase,
│   │   │   │                                 # SyncPaymentWithCalendarUseCase,
│   │   │   │                                 # SchedulePaymentNotificationsUseCase, etc.
│   │   │   └── Errors/                     # PaymentError
│   │   ├── Data/
│   │   │   ├── DTOs/
│   │   │   │   ├── Local/                  # PaymentLocalDTO (@Model)
│   │   │   │   └── Remote/                 # PaymentRemoteDTO (Codable)
│   │   │   ├── Mappers/                    # PaymentMapper
│   │   │   ├── Repositories/               # PaymentRepositoryImpl
│   │   │   └── DataSources/
│   │   │       ├── Local/                  # PaymentSwiftDataDataSource
│   │   │       └── Remote/                 # PaymentSupabaseDataSource
│   │   └── Presentation/
│   │       ├── ViewModels/                 # PaymentsListViewModel, EditPaymentViewModel
│   │       ├── Views/                      # PaymentsListView, AddPaymentView, etc.
│   │       ├── Models/                     # PaymentUI (presentation model)
│   │       ├── Coordinators/               # PaymentSyncCoordinator
│   │       └── DI/                         # PaymentDependencyContainer
│   │
│   ├── Reminders/                          # Recordatorios (sync Supabase)
│   ├── Calendar/                           # Calendario (pagos + recordatorios)
│   ├── Statistics/                         # Estadísticas (desde Ajustes)
│   ├── History/                            # Historial de pagos (desde Ajustes)
│   ├── Settings/                           # Ajustes, sync, depuración opcional
│   └── UserProfile/                        # Perfil de usuario
│
└── Shared/                                 # Código compartido (L10n, UI, infra, notificaciones…)
│   ├── Models/                             # Currency, SyncStatus, etc.
│   ├── Extensions/                         # String+, Date+, etc.
│   ├── Managers/                           # ErrorHandler, AlertManager, …
│   └── …                                   # Ver repo para módulos completos
```

En la **raíz del repositorio** (junto a la carpeta `pagosApp/`): `Config/` (secrets y template), `Database/` (SQL Supabase), [`.github/workflows/`](../.github/workflows/ci.yml) (CI: build + SwiftLint), **`fastlane/`** + `Gemfile` (IPA; [fastlane/SETUP.md](../fastlane/SETUP.md), [fastlane/README.md](../fastlane/README.md)) y el target de tests **`pagosAppTests/`**.

---
