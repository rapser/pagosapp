# PagosApp 💰

> **Aplicación iOS moderna para gestión de pagos recurrentes con Clean Architecture, autenticación segura y sincronización en la nube.**

[![iOS](https://img.shields.io/badge/iOS-18.5%2B-blue.svg)](https://www.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-16.4%2B-blue.svg)](https://developer.apple.com/xcode/)
[![Architecture](https://img.shields.io/badge/Architecture-Clean-green.svg)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Version](https://img.shields.io/badge/Version-1.0.0(15)-blue.svg)](CHANGELOG.md)

---

## 📱 Descripción del Proyecto

**PagosApp** es una aplicación iOS moderna y profesional para la gestión integral de pagos recurrentes. Diseñada con **Clean Architecture 100%**, ofrece una experiencia offline-first con sincronización en la nube, autenticación segura mediante biometría, y sincronización automática con el calendario de iOS.

### 🎯 ¿Qué hace la App?

- **Gestión de Pagos Recurrentes**: Crea, edita y organiza todos tus pagos mensuales (Netflix, tarjetas de crédito, servicios, etc.)
- **Recordatorios**: Gestiona eventos que no son pagos (renovación de tarjeta, membresías, cobros, impuestos, ahorro, etc.) con título, descripción y fecha; notificaciones desde 5 días antes
- **Sincronización con Calendario iOS**: Pagos y recordatorios se muestran en el calendario nativo
- **Notificaciones**: Recordatorios para pagos (2 días antes + mismo día) y para recordatorios (desde 5 días antes)
- **Multi-moneda**: Soporte para PEN (Soles) y USD (Dólares) con conversión automática
- **Estadísticas e Historial**: Gráficos de gastos por categoría, tendencias mensuales e historial; accesibles desde Ajustes
- **Offline-First**: Funciona sin internet; sincronización manual (pagos + recordatorios) desde Ajustes
- **Autenticación Segura**: Face ID/Touch ID + Email/Password
- **Internacionalización**: Español (por defecto), inglés y portugués

---

## ✨ Features Principales

### 🔐 Autenticación & Seguridad
- ✅ Registro e inicio de sesión con Supabase (Email/Password)
- ✅ Face ID / Touch ID para acceso rápido y seguro
- ✅ Recuperación de contraseña por email
- ✅ Almacenamiento seguro de credenciales en Keychain
- ✅ Row Level Security (RLS) en base de datos
- ✅ Sesiones persistentes con renovación automática

### 💰 Gestión de Pagos
- ✅ CRUD completo de pagos (Crear, Leer, Actualizar, Eliminar)
- ✅ Categorización flexible (Entretenimiento, Tarjetas, Servicios, etc.)
- ✅ Soporte multi-moneda (PEN/USD)
- ✅ **Pagos Agrupados**: Tarjetas de crédito bimoneda (PEN + USD) agrupadas automáticamente
- ✅ **Edición de Pagos Agrupados**: Edita ambos montos (PEN y USD) desde un solo formulario
- ✅ Estados de pago (Pendiente/Completado)
- ✅ Edición en tiempo real con validación
- ✅ Búsqueda y filtros avanzados
- ✅ Duplicación de pagos recurrentes

### 📅 Integración con Calendario iOS
- ✅ **Sincronización Automática**: Los eventos se crean/actualizan/eliminan automáticamente
- ✅ Cada pago genera un evento en el calendario nativo
- ✅ Actualización automática al modificar pagos
- ✅ Eliminación sincronizada de eventos
- ✅ **Pagos Agrupados**: Un solo evento compartido para pagos PEN + USD (evita duplicados)
- ✅ Selección de calendario destino
- ✅ Soporte para calendarios compartidos

### 🔔 Notificaciones
- ✅ **Pagos**: Notificaciones 2 días antes, 1 día antes y el mismo día (9:00 y 14:00)
- ✅ **Recordatorios**: Notificaciones desde 5 días antes hasta el mismo día (9:00 y 14:00)
- ✅ Restauración automática al iniciar sesión; cancelación al marcar completado o eliminar
- ✅ Alertas de errores con sugerencias de recuperación

### 📊 Estadísticas y Visualización
- ✅ Dashboard con métricas en tiempo real
- ✅ Gráficos de gastos por categoría (Pie Charts)
- ✅ Tendencias mensuales (Line Charts)
- ✅ Total gastado por mes y categoría
- ✅ Proyección de gastos futuros
- ✅ Comparativas mes a mes

### 📌 Recordatorios (no son pagos)
- ✅ Tipos: renovación tarjeta, membresía, suscripción, cobro, ahorro, documentos, impuestos, otro
- ✅ Título, descripción opcional y fecha; sin monto
- ✅ Marcar como completado/cancelado (checkbox en lista)
- ✅ Sincronización con Supabase (tabla `reminders`); mismo flujo offline-first que pagos
- ✅ Un botón **Sincronizar** en Ajustes sube/baja pagos y recordatorios

### ☁️ Sincronización Cloud
- ✅ Sincronización con Supabase (pagos + recordatorios)
- ✅ Un solo botón en Ajustes sincroniza ambos
- ✅ Offline-first: todo funciona sin internet; sync manual cuando quieras
- ✅ Multi-dispositivo: mismo usuario, múltiples dispositivos

### 👤 Perfil y Ajustes
- ✅ Gestión de perfil personal y moneda preferida
- ✅ **Desde Ajustes**: Historial de pagos, Estadísticas, Sincronización, reparar base de datos, cerrar sesión
- ✅ Activación/desactivación de Face ID y desvincular dispositivo
- ✅ Cierre de sesión seguro

### 🌐 Internacionalización (i18n)
- ✅ Español por defecto (fallback)
- ✅ Inglés y portugués
- ✅ Textos de UI y mensajes de error centralizados en `Localizable.strings`

---

## 🏗 Arquitectura

### Clean Architecture al 100%

PagosApp implementa **Clean Architecture** de forma estricta, siguiendo los principios de Uncle Bob Martin. Esta arquitectura garantiza:

- **Independencia de Frameworks**: La lógica de negocio no depende de SwiftUI, SwiftData o Supabase
- **Testabilidad**: Cada capa se puede testear independientemente
- **Independencia de UI**: La UI es un detalle, puede cambiar sin afectar el negocio
- **Independencia de Base de Datos**: Puedes cambiar de SwiftData a CoreData sin afectar el Domain
- **Mantenibilidad**: Código organizado y fácil de entender

### ¿Por qué Clean Architecture?

**Problema típico en apps iOS**: El código se mezcla (lógica de negocio en Views, llamadas a API en ViewModels, validaciones dispersas). Esto genera:
- ❌ Código difícil de testear
- ❌ Cambios en UI rompen lógica de negocio
- ❌ Duplicación de código
- ❌ Acoplamiento alto entre componentes

**Solución con Clean Architecture**:
- ✅ **Separación de Responsabilidades**: Cada capa tiene un propósito claro
- ✅ **Dependency Rule**: Las dependencias apuntan hacia adentro (Domain nunca depende de Data o Presentation)
- ✅ **Inversión de Dependencias**: Domain define interfaces (protocols), Data las implementa
- ✅ **Testing Simplificado**: Mocks e inyección de dependencias en todas las capas

### Estructura de Capas

```
┌─────────────────────────────────────────────────────────┐
│                   PRESENTATION LAYER                     │
│  ┌────────────┬────────────────┬─────────────────────┐  │
│  │   Views    │   ViewModels   │   UI Models (UI)    │  │
│  │  (SwiftUI) │  (@Observable) │   (PaymentUI, etc)  │  │
│  └────────────┴────────────────┴─────────────────────┘  │
│         ▲                   │        ▲                   │
│         │                   ▼        │                   │
│         │            Use Cases       │                   │
│         │                   │        │ EventBus          │
│         │                   │        │ Subscribe         │
└─────────┼───────────────────┼────────┼───────────────────┘
          │                   │        │
          │                   ▼        │
┌─────────┼───────────────────────────┼───────────────────┐
│         │             DOMAIN LAYER  │                    │
│  ┌──────┴──────┬─────────────┬──────┴──────┬──────────┐ │
│  │  Entities   │  Use Cases  │  EventBus   │  Events  │ │
│  │  (Payment,  │ (Business   │  (Protocol) │ (Domain  │ │
│  │   User)     │   Logic)    │             │  Events) │ │
│  └─────────────┴─────┬───────┴─────────────┴──────────┘ │
│                      │ Publish                            │
│                      │                                    │
│  ┌───────────────────┴────┬────────────┬───────────┐     │
│  │  Repositories          │  Errors    │ Validators│     │
│  │  (Protocols)           │ (Payment   │           │     │
│  │                        │  Error)    │           │     │
│  └───────────────────▲────┴────────────┴───────────┘     │
│                      │                                    │
└──────────────────────┼────────────────────────────────────┘
                       │
                       │  Repository implementations
                       │
┌──────────────────────┼────────────────────────────────────┐
│                      │       DATA LAYER                    │
│  ┌───────────────────┴────┬────────────┬───────────┐      │
│  │   Repository Impl      │  Mappers   │    DTOs   │      │
│  │(PaymentRepositoryImpl) │(DTO↔Domain)│(Local/    │      │
│  └────────┬───────────────┴────────────┴──Remote)─┘      │
│           │                                                │
│           ▼                                                │
│  ┌────────────────────┬────────────────────────────────┐  │
│  │   Data Sources     │      Data Sources              │  │
│  │   (Local)          │      (Remote)                  │  │
│  │  SwiftData DTOs    │   Supabase DTOs                │  │
│  └────────────────────┴────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────┐
│                 INFRASTRUCTURE LAYER                     │
│  ┌──────────────────────────────────────────────────┐   │
│  │           InMemoryEventBus                        │   │
│  │  (EventBus Implementation - AsyncStream based)   │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘

Flujo de Comunicación con EventBus:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
1. User Action → View → ViewModel → Use Case
2. Use Case → Repository → Save Data
3. Use Case → EventBus.publish(Event) ← TIPO SEGURO
4. EventBus → All Subscribed ViewModels ← ASYNC STREAMS
5. ViewModels → Refresh Data → UI Updates
```

### Capas Detalladas

#### 1. **Domain Layer** (Corazón del negocio)

**Entities** - Modelos de negocio puros:
```swift
struct Payment {
    let id: UUID
    let name: String
    let amount: Decimal        // ✅ Decimal para precisión financiera
    let currency: Currency
    let dueDate: Date
    let isPaid: Bool
    let category: PaymentCategory
    let syncStatus: SyncStatus
}
```

**Use Cases** - Lógica de negocio encapsulada:
- `CreatePaymentUseCase`: Valida y crea pagos + sincroniza calendario + programa notificaciones
- `UpdatePaymentUseCase`: Actualiza pagos + pagos hermanos (grupos) + sincroniza calendario + reprograma notificaciones
- `DeletePaymentUseCase`: Elimina pagos y eventos asociados + cancela notificaciones
- `GetAllPaymentsUseCase`: Recupera todos los pagos
- `CalculateMonthlyStatsUseCase`: Calcula estadísticas mensuales
- `SyncPaymentsUseCase`: Sincroniza local ↔ remoto
- `SyncPaymentWithCalendarUseCase`: Sincroniza pagos con calendario iOS (crear/actualizar/eliminar eventos)
- `SchedulePaymentNotificationsUseCase`: Programa y cancela notificaciones locales
- `TogglePaymentStatusUseCase`: Cambia estado de pago + actualiza notificaciones

**Repository Protocols** - Contratos que Data debe cumplir:
```swift
protocol PaymentRepositoryProtocol {
    func getAllLocalPayments() async throws -> [Payment]
    func savePayment(_ payment: Payment) async throws
    func deleteLocalPayment(id: UUID) async throws
    func syncWithRemote(userId: UUID) async throws
}
```

**¿Por qué Use Cases?**
- ✅ Encapsulan lógica de negocio compleja (ej: al actualizar un pago, también actualizar su evento de calendario)
- ✅ Reutilizables desde múltiples ViewModels
- ✅ Fáciles de testear con mocks
- ✅ Cambios en la lógica de negocio no afectan Views

#### 2. **Data Layer** (Acceso a datos)

**Repository Implementations**:
```swift
final class PaymentRepositoryImpl: PaymentRepositoryProtocol {
    private let localDataSource: PaymentLocalDataSource
    private let remoteDataSource: PaymentRemoteDataSource
    private let mapper: PaymentMapper

    func getAllLocalPayments() async throws -> [Payment] {
        let dtos = try await localDataSource.fetchAll()
        return dtos.map { mapper.toDomain($0) }
    }
}
```

**Data Sources**:
- `PaymentSwiftDataDataSource`: Persistencia local con SwiftData
- `PaymentSupabaseDataSource`: API remota con Supabase
- `KeychainAuthDataSource`: Credenciales seguras

**Mappers** - Conversiones entre capas:
- `PaymentMapper`: `PaymentLocalDTO` ↔ `Payment` ↔ `PaymentRemoteDTO`
- `PaymentUIMapper`: `Payment` ↔ `PaymentUI`
- `UserProfileMapper`: Similar para perfiles

**DTOs (Data Transfer Objects)**:
```swift
// SwiftData DTO (Local)
@Model
final class PaymentLocalDTO {
    var id: UUID
    var name: String
    var amount: Double         // ✅ Double para SwiftData
    var currency: String
    var dueDate: Date
    var isPaid: Bool
    // ...
}

// Supabase DTO (Remote)
struct PaymentRemoteDTO: Codable {
    let id: UUID
    let userId: UUID
    let name: String
    let amount: Double        // ✅ Double para JSON
    let currency: String
    let dueDate: Date
    let isPaid: Bool
    // ...
}
```

**¿Por qué DTOs separados?**
- ✅ SwiftData requiere `@Model` classes con `Double`
- ✅ Supabase necesita `Codable` structs con snake_case
- ✅ Domain usa `Decimal` para precisión financiera
- ✅ Cambios en API no rompen el Domain
- ✅ Cambios en persistencia local no afectan Domain

#### 3. **Presentation Layer** (UI)

**Views** - SwiftUI puro sin lógica:
```swift
struct PaymentsListView: View {
    @State private var viewModel: PaymentsListViewModel

    var body: some View {
        List(viewModel.payments) { payment in
            PaymentRowView(payment: payment)
        }
        .task { await viewModel.fetchPayments() }
    }
}
```

**ViewModels** - Estado UI + coordinación:
```swift
@MainActor
@Observable
final class PaymentsListViewModel {
    var payments: [PaymentUI] = []
    var isLoading = false
    var errorMessage: String?

    private let getAllPaymentsUseCase: GetAllPaymentsUseCase
    private let mapper: PaymentUIMapping

    func fetchPayments() async {
        isLoading = true
        let result = await getAllPaymentsUseCase.execute()
        switch result {
        case .success(let domainPayments):
            payments = mapper.toUI(domainPayments)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
```

**UI Models** - Modelos optimizados para presentación:
```swift
struct PaymentUI: Identifiable {
    let id: UUID
    let name: String
    let amount: Double          // ✅ Double para SwiftUI bindings
    let currency: Currency
    let dueDate: Date
    let isPaid: Bool

    // ✅ Computed properties para UI (lógica de presentación)
    var formattedAmount: String {
        "\(currency.symbol) \(String(format: "%.2f", amount))"
    }

    var statusColor: Color {
        isPaid ? .green : .gray
    }

    var isOverdue: Bool {
        !isPaid && dueDate < Date()
    }

    var displayOpacity: Double {
        isPaid ? 0.7 : 1.0
    }
}
```

**¿Por qué PaymentUI separado de Payment?**
- ✅ Views NO deben tener lógica inline (`Text(isPaid ? "Pagado" : "Pendiente")`)
- ✅ Lógica de presentación centralizada y reutilizable
- ✅ Domain `Payment` usa `Decimal`, UI usa `Double` (bindings SwiftUI)
- ✅ Computed properties testables independientemente
- ✅ Cambios en formateo no afectan Domain

---

### Dependency Injection

**Factory Pattern con Containers por Feature**:

```swift
@MainActor
final class PaymentDependencyContainer {
    private let modelContext: ModelContext
    private let supabaseClient: SupabaseClient

    // Data Sources
    private func makeLocalDataSource() -> PaymentLocalDataSource {
        PaymentSwiftDataDataSource(modelContext: modelContext)
    }

    private func makeRemoteDataSource() -> PaymentRemoteDataSource {
        PaymentSupabaseDataSource(client: supabaseClient)
    }

    // Repository
    private func makeRepository() -> PaymentRepositoryProtocol {
        PaymentRepositoryImpl(
            localDataSource: makeLocalDataSource(),
            remoteDataSource: makeRemoteDataSource(),
            mapper: PaymentMapper()
        )
    }

    // Use Cases
    func makeGetAllPaymentsUseCase() -> GetAllPaymentsUseCase {
        GetAllPaymentsUseCase(repository: makeRepository())
    }

    func makeCreatePaymentUseCase() -> CreatePaymentUseCase {
        CreatePaymentUseCase(
            repository: makeRepository(),
            validator: PaymentValidator()
        )
    }

    // ViewModels
    func makePaymentsListViewModel() -> PaymentsListViewModel {
        PaymentsListViewModel(
            getAllPaymentsUseCase: makeGetAllPaymentsUseCase(),
            mapper: PaymentUIMapper()
        )
    }
}
```

**Beneficios**:
- ✅ Testeo fácil: inyecta mocks en lugar de dependencias reales
- ✅ Desacoplamiento: componentes no crean sus dependencias
- ✅ Configuración centralizada por feature
- ✅ Facilita cambios (cambiar SwiftData por CoreData solo toca el container)

---

### Offline-First Architecture

**Principio**: SwiftData es la única fuente de verdad. Supabase es un backup remoto.

**Flujo de Lectura**:
```
User taps "Mis Pagos"
  → View calls ViewModel.fetchPayments()
    → ViewModel calls GetAllPaymentsUseCase.execute()
      → Use Case calls Repository.getAllLocalPayments()
        → Repository calls SwiftDataDataSource.fetchAll()
          → SwiftData returns [PaymentLocalDTO]
        ← Repository converts DTOs → [Payment] (Domain)
      ← Use Case returns [Payment]
    ← ViewModel converts [Payment] → [PaymentUI]
  ← View displays [PaymentUI]
```

**Flujo de Escritura + Notificación**:
```
User creates/updates/deletes payment
  → View calls ViewModel.createPayment()
    → ViewModel calls CreatePaymentUseCase.execute(payment)
      → Use Case validates payment
      → Use Case calls Repository.savePayment(payment)
        → Repository converts Payment → PaymentLocalDTO
        → Repository saves to SwiftData
        ← SwiftData persists successfully
      ← Use Case sends NotificationCenter "PaymentsDidSync"
    ← ViewModel receives success
  ← View shows success

  [Simultaneously]
  All ViewModels observing "PaymentsDidSync"
    → Auto-refresh their data from SwiftData
    ← UI updates automatically
```

**Flujo de Sincronización**:
```
User logs in
  → SessionCoordinator.startSession()
    → Calls PaymentSyncCoordinator.performSync()
      ┌─ Upload: SwiftData → Supabase (local changes)
      └─ Download: Supabase → SwiftData (remote changes)
    ← Sync complete, sends notification "PaymentsDidSync"
  ← All ViewModels auto-refresh
  ← UI shows latest data
```

**¿Por qué Offline-First?**
- ✅ App funciona 100% sin internet
- ✅ Performance: lectura local instantánea
- ✅ Mejor UX: sin spinners esperando red
- ✅ Eventual consistency: sincroniza cuando hay conexión

**EventBus - Sistema de Eventos Reactivo**

**Migración completa de NotificationCenter a EventBus Type-Safe**

La aplicación usa un **EventBus** personalizado basado en `AsyncStream` para la comunicación entre capas, reemplazando completamente `NotificationCenter`:

**¿Por qué EventBus sobre NotificationCenter?**
- ✅ **Type-Safe**: Eventos tipados (no `Any?`)
- ✅ **Clean Architecture**: EventBus es Domain, NotificationCenter es Infrastructure
- ✅ **Moderno**: AsyncStream + Swift Concurrency
- ✅ **Testeable**: Fácil de mockear
- ✅ **Thread-Safe**: @MainActor isolation automático
- ✅ **Sendable**: Cumple Swift 6 strict concurrency

**Arquitectura del EventBus**:

```swift
// 1. Protocol en Domain Layer
@MainActor
protocol EventBus: Sendable {
    func publish<T: DomainEvent>(_ event: T)
    func subscribe<T: DomainEvent>(to eventType: T.Type) -> AsyncStream<T>
}

// 2. Eventos de Dominio Type-Safe
protocol DomainEvent: Sendable {
    var timestamp: Date { get }
    var eventId: UUID { get }
}

struct PaymentCreatedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID
}

struct PaymentUpdatedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID
}

struct PaymentDeletedEvent: DomainEvent {
    let timestamp: Date
    let paymentId: UUID
}

struct PaymentsSyncedEvent: DomainEvent {
    let timestamp: Date
    let syncedCount: Int
}

// 3. Implementación en Infrastructure Layer
@MainActor
final class InMemoryEventBus: EventBus {
    private var continuations: [String: [any Continuation]] = [:]

    func publish<T: DomainEvent>(_ event: T) {
        let typeName = String(describing: T.self)
        continuations[typeName]?.forEach { $0.yield(event) }
    }

    func subscribe<T: DomainEvent>(to eventType: T.Type) -> AsyncStream<T> {
        // Returns AsyncStream with automatic cleanup
    }
}
```

**Uso en Use Cases** (Publicadores):

```swift
final class CreatePaymentUseCase {
    private let eventBus: EventBus

    func execute(_ payment: Payment) async -> Result<Payment, PaymentError> {
        // Save payment
        try await repository.savePayment(payment)

        // Publish type-safe event
        eventBus.publish(PaymentCreatedEvent(paymentId: payment.id))

        return .success(payment)
    }
}
```

**Uso en ViewModels** (Suscriptores):

```swift
@MainActor
@Observable
final class PaymentsListViewModel {
    private let eventBus: EventBus

    init(eventBus: EventBus, ...) {
        self.eventBus = eventBus
        setupEventListeners()
    }

    private func setupEventListeners() {
        // Listen to PaymentCreatedEvent
        Task { @MainActor in
            for await event in eventBus.subscribe(to: PaymentCreatedEvent.self) {
                await fetchPayments(showLoading: false)
            }
        }

        // Listen to PaymentUpdatedEvent
        Task { @MainActor in
            for await event in eventBus.subscribe(to: PaymentUpdatedEvent.self) {
                await fetchPayments(showLoading: false)
            }
        }
    }
}
```

**Beneficios sobre NotificationCenter**:
1. **Type Safety**: Imposible enviar datos incorrectos
2. **Clean Architecture**: Domain no depende de Foundation
3. **Mejor Testing**: Mocks fáciles de crear
4. **Async Native**: Integración natural con async/await
5. **Auto-cleanup**: AsyncStream maneja cleanup automáticamente
6. **Swift 6 Compliant**: Sendable + @MainActor isolation

**Alternativa moderna considerada**:
- `@Query` directo en vistas (reactividad automática con SwiftData)
- Decisión: Mantener Clean Architecture 100% (lógica fuera de Views) + EventBus type-safe fue prioritario

---

### Swift 6 & Concurrency

**Actor Isolation Optimizado**:

```swift
// ✅ @MainActor SOLO en ViewModels y UI Managers
@MainActor
@Observable
final class PaymentsListViewModel { /* UI state */ }

// ✅ @MainActor en Repositories que usan SwiftData (requiere main thread)
@MainActor
protocol UserProfileRepositoryProtocol {
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError>
}

// ✅ Sin @MainActor en Services (operaciones I/O puras)
final class PaymentSyncService {
    func syncPayments() async throws {
        // Can be called from any actor
    }
}
```

**Sendable Types**:
```swift
// ✅ Domain entities son Sendable (immutable value types)
struct Payment: Sendable {
    let id: UUID
    // All properties are immutable and Sendable
}

// ✅ DTOs conform Sendable cuando es posible
struct PaymentRemoteDTO: Codable, Sendable { /* ... */ }
```

**¿Por qué este diseño de concurrencia?**
- ✅ @MainActor solo donde realmente necesitas UI updates o SwiftData access
- ✅ Swift 6 strict concurrency compliance
- ✅ Menos context switches = mejor performance
- ✅ Type-safe concurrency sin data races

---

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
- **Logging**: Solo logs de error esenciales; consola limpia (sin logs informativos/debug en producción)

---

## 📋 Requisitos

- **iOS**: 18.5 o superior
- **Xcode**: 16.4 o superior
- **Swift**: 6.0
- **macOS**: Sequoia 15.0+ (desarrollo)
- **Cuenta Supabase**: [Crear gratis](https://supabase.com)

---

## 🚀 Instalación y Configuración

### 1️⃣ Clonar Repositorio

```bash
git clone <url-del-repositorio>
cd pagosApp
```

### 2️⃣ Configurar Supabase

```bash
# Copiar template de configuración
cp Config/Secrets.template.xcconfig Config/Secrets.xcconfig

# Editar con tus credenciales (usa tu editor favorito)
nano Config/Secrets.xcconfig
```

Reemplaza con tus credenciales reales:
```xcconfig
SUPABASE_URL = https://tu-proyecto.supabase.co
SUPABASE_KEY = tu_anon_key_aqui
```

> 🔒 **Seguridad**: `Secrets.xcconfig` está en `.gitignore` - Tus credenciales nunca se commitean.

### 3️⃣ Abrir en Xcode

```bash
open pagosApp.xcodeproj
```

**Xcode instalará automáticamente**:
- ✅ Supabase Swift SDK (v2.5.1+)
- ✅ Todas las dependencias necesarias

### 4️⃣ Configurar Build Settings

1. **Project Navigator** → Selecciona proyecto `pagosApp`
2. **Info Tab** → **Configurations**
3. Asigna `Secrets.xcconfig` a **Debug** y **Release**

### 5️⃣ Build & Run

```
⌘ + R
```

✅ La app está lista para usar en simulador o dispositivo físico.

---

## 📁 Estructura del Proyecto

```
pagosApp/
├── App/
│   └── pagosAppApp.swift                    # Entry point + DI setup
│
├── Features/                                # ✅ Organización por feature
│   ├── Auth/
│   │   ├── Domain/
│   │   │   ├── Entities/                    # User, AuthSession
│   │   │   ├── Repositories/               # AuthRepositoryProtocol
│   │   │   ├── UseCases/                   # LoginUseCase, RegisterUseCase, etc.
│   │   │   └── Errors/                     # AuthError
│   │   ├── Data/
│   │   │   ├── DTOs/
│   │   │   │   ├── Remote/                 # SupabaseAuthDTO
│   │   │   │   └── Local/                  # KeychainAuthDTO
│   │   │   ├── Mappers/                    # AuthMapper
│   │   │   ├── Repositories/               # AuthRepositoryImpl
│   │   │   └── DataSources/
│   │   │       ├── Remote/                 # SupabaseAuthDataSource
│   │   │       └── Local/                  # KeychainAuthDataSource
│   │   └── Presentation/
│   │       ├── ViewModels/                 # LoginViewModel, RegisterViewModel
│   │       ├── Views/                      # LoginView, RegisterView
│   │       ├── Coordinators/               # SessionCoordinator
│   │       └── DI/                         # AuthDependencyContainer
│   │
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
│   ├── Reminders/                          # Feature: Recordatorios (tipos, título, descripción, fecha; sync Supabase)
│   ├── Calendar/                           # Feature: Calendar (pagos + recordatorios)
│   ├── Statistics/                         # Feature: Stats & charts (acceso desde Ajustes)
│   ├── History/                            # Feature: Payment history (acceso desde Ajustes)
│   ├── Settings/                           # Feature: Ajustes, sync, Historial, Estadísticas
│   └── UserProfile/                        # Feature: User profile
│
├── Shared/                                 # Código compartido entre features
│   ├── Models/                             # Currency, SyncStatus, etc.
│   ├── Extensions/                         # String+, Date+, etc.
│   ├── Managers/                           # ErrorHandler, NotificationManager
│   └── Utils/                              # Validators, Formatters
│
├── Config/
│   ├── Secrets.xcconfig                    # ❌ NO commitear (gitignored)
│   ├── Secrets.template.xcconfig           # ✅ Template público
│   └── README.md                           # Instrucciones de configuración
│
└── Database/
    ├── payments.sql                        # Tabla payments (Supabase)
    ├── reminders.sql                       # Tabla reminders (Supabase)
    ├── user_profiles.sql                   # Tabla user_profiles (Supabase)
    └── README.md                            # Orden de ejecución y uso

Tests/
└── pagosAppTests/
    ├── Domain/
    │   └── UseCases/                       # Tests de Use Cases
    ├── Data/
    │   ├── Repositories/                   # Tests de Repositories
    │   └── Mappers/                        # Tests de Mappers
    └── Presentation/
        └── ViewModels/                     # Tests de ViewModels
```

---

## 🧪 Testing

```bash
# Ejecutar todos los tests
⌘ + U

# O desde terminal
xcodebuild test -scheme pagosApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

**Cobertura Actual**: ~50-60%

**Tests Implementados**:
- ✅ Use Cases: Lógica de negocio
- ✅ Mappers: Conversiones DTO ↔ Domain ↔ UI
- ✅ Validators: Email, Payment, UserProfile
- ✅ ViewModels: Estados y flujos UI
- ✅ Repositories (mocks): Inyección de dependencias

---

## 📚 Documentación Adicional

- **[CHANGELOG.md](CHANGELOG.md)**: Historial completo de cambios (versión 1.0.0 build 15)
- **[Config/README.md](Config/README.md)**: Setup de credenciales
- **[Database/README.md](Database/README.md)**: Scripts SQL (payments, reminders, user_profiles) y orden de ejecución

---

## 🔒 Seguridad

### Implementaciones de Seguridad

- 🔐 **Keychain**: Tokens y credenciales almacenados de forma segura
- 🚫 **Secrets.xcconfig**: Credenciales nunca en código
- 🛡 **RLS (Row Level Security)**: Cada usuario solo ve sus datos
- 👤 **Session Management**: Sesiones seguras con renovación automática
- 📱 **Biometrics**: Face ID/Touch ID opcional
- 🔑 **Build-time Injection**: Credenciales inyectadas en compilación

---

## 🤝 Contribución

### Workflow

1. **Fork** el proyecto
2. **Crea branch** (`git checkout -b feature/AmazingFeature`)
3. **Commit** cambios (`git commit -m 'Add AmazingFeature'`)
4. **Push** a branch (`git push origin feature/AmazingFeature`)
5. **Abre Pull Request**

### Estándares de Código

- ✅ Swift 6 strict concurrency
- ✅ Clean Architecture (Domain/Data/Presentation)
- ✅ @Observable para state management
- ✅ async/await (no Combine)
- ✅ Tests para nueva funcionalidad
- ✅ Documentación inline

---

## 📝 Changelog

Ver [CHANGELOG.md](CHANGELOG.md) para historial completo de cambios.

### Highlights

- **2026-03 (v1.0.0 build 15)**: Recordatorios (módulo completo, sync Supabase, notificaciones 5 días antes), i18n (ES/EN/PT), Calendario con pagos + recordatorios, Historial/Estadísticas desde Ajustes, limpieza de logs
- **2026-01 (v1.0.0 build 14)**: EventBus type-safe + Migración completa de NotificationCenter + Clean Architecture 100%
- **2026-01 (v1.0.0 build 11)**: Edición de pagos agrupados + Sincronización con calendario + Notificaciones locales restauradas
- **2026-01 (v1.0.0 build 10)**: Clean Architecture completa + Entity renaming + Swift 6 concurrency
- **2025-01**: Modernización completa iOS 18.5 + Swift 6
- **2024-11**: Módulo de autenticación con patrones de diseño
- **2024-10**: Release inicial v1.0

---

## 📄 Licencia

MIT License - Ver archivo LICENSE para detalles.

---

## 👤 Autor

**rapser**
- GitHub: [@rapser](https://github.com/rapser)

---

## 🙏 Agradecimientos

- [Supabase](https://supabase.com) - Backend as a Service
- [Swift Community](https://swift.org) - Amazing language
- Apple Developer Team - iOS SDK y frameworks
- Uncle Bob Martin - Clean Architecture principles

---

**Made with ❤️, Swift 6, and Clean Architecture**
