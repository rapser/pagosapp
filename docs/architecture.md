# Arquitectura

> **Versión de toolchain:** el target de la app usa **Swift 5** en Xcode. Donde el texto menciona compatibilidad con *Swift 6* o *strict concurrency*, se refiere al **diseño** (p. ej. `Sendable`, `@MainActor`) o a notas históricas, no a que el proyecto esté fijado a Swift 6 en `SWIFT_VERSION`.

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
