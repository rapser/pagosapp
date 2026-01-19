# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [1.0.0] - Build 11 - 2026-01-18

### 🎯 Resumen Ejecutivo

**EDICIÓN DE PAGOS AGRUPADOS + SINCRONIZACIÓN AUTOMÁTICA CON CALENDARIO + NOTIFICACIONES RESTAURADAS** - Implementación completa de edición de pagos agrupados (PEN + USD), sincronización automática con calendario iOS, restauración de notificaciones locales, y correcciones de threading para Swift 6.

### ✨ Nuevas Funcionalidades

#### 1. Edición de Pagos Agrupados (PEN + USD)
**Problema**: Al crear un pago agrupado (tarjeta de crédito con soles y dólares), solo se podía editar el pago en soles, no el de dólares.

**Solución Implementada**:
- ✅ `EditPaymentViewModel` ahora detecta pagos agrupados y carga ambos pagos (PEN y USD)
- ✅ `EditPaymentView` muestra formulario de doble moneda cuando es un pago agrupado
- ✅ Al guardar, actualiza ambos pagos simultáneamente
- ✅ Validación mejorada para pagos agrupados

**Archivos Modificados**:
- `EditPaymentViewModel.swift` - Soporte para pagos agrupados
- `EditPaymentView.swift` - Detección y carga de pagos agrupados
- `PaymentDependencyContainer.swift` - Método actualizado para aceptar pagos agrupados

**Beneficio**: Ahora puedes editar completamente los pagos agrupados, igual que cuando los creas.

#### 2. Sincronización Automática con Calendario iOS
**Problema**: Los eventos del calendario no se creaban/actualizaban automáticamente al crear o modificar pagos.

**Solución Implementada**:
- ✅ Creado `SyncPaymentWithCalendarUseCase` para manejar sincronización con calendario
- ✅ Integrado en `CreatePaymentUseCase`: crea eventos automáticamente
- ✅ Integrado en `UpdatePaymentUseCase`: actualiza eventos automáticamente
- ✅ Integrado en `DeletePaymentUseCase`: elimina eventos automáticamente
- ✅ **Pagos Agrupados**: Un solo evento compartido para evitar duplicados

**Archivos Creados**:
- `SyncPaymentWithCalendarUseCase.swift` - Use case para sincronización con calendario

**Archivos Modificados**:
- `CreatePaymentUseCase.swift` - Integración de sincronización con calendario
- `UpdatePaymentUseCase.swift` - Integración de sincronización con calendario
- `DeletePaymentUseCase.swift` - Integración de eliminación de eventos
- `PaymentDependencyContainer.swift` - Factory methods actualizados

**Beneficio**: Los eventos del calendario se sincronizan automáticamente sin intervención manual.

#### 3. Restauración de Notificaciones Locales
**Problema**: Las notificaciones locales se perdieron durante actualizaciones de la app y no se restauraban automáticamente.

**Solución Implementada**:
- ✅ Creado `SchedulePaymentNotificationsUseCase` para programar notificaciones
- ✅ Integrado en `CreatePaymentUseCase`: programa notificaciones al crear
- ✅ Integrado en `UpdatePaymentUseCase`: reprograma notificaciones al actualizar
- ✅ Integrado en `DeletePaymentUseCase`: cancela notificaciones al eliminar
- ✅ Integrado en `TogglePaymentStatusUseCase`: actualiza notificaciones al cambiar estado
- ✅ **Restauración Automática**: Reprograma todas las notificaciones al iniciar sesión

**Archivos Creados**:
- `SchedulePaymentNotificationsUseCase.swift` - Use case para programar notificaciones

**Archivos Modificados**:
- `CreatePaymentUseCase.swift` - Integración de notificaciones
- `UpdatePaymentUseCase.swift` - Integración de notificaciones
- `DeletePaymentUseCase.swift` - Integración de cancelación de notificaciones
- `TogglePaymentStatusUseCase.swift` - Integración de actualización de notificaciones
- `PaymentsListViewModel.swift` - Restauración automática en primera carga
- `PaymentDependencyContainer.swift` - Factory methods actualizados

**Notificaciones Programadas**:
- 2 días antes del vencimiento a las 9:00 AM
- 1 día antes del vencimiento a las 9:00 AM
- El mismo día del vencimiento a las 9:00 AM

**Beneficio**: Las notificaciones funcionan correctamente y se restauran automáticamente al iniciar sesión.

### 🐛 Bug Fixes

#### 1. Corrección de Threading en Use Cases (Swift 6)
**Problema**: Warnings de Swift 6 sobre publicación de cambios desde hilos en segundo plano.

**Solución**: Envuelto todas las notificaciones `NotificationCenter` en `MainActor.run`:
- ✅ `CreatePaymentUseCase.swift` - Notificaciones en main thread
- ✅ `UpdatePaymentUseCase.swift` - Notificaciones en main thread
- ✅ `DeletePaymentUseCase.swift` - Notificaciones en main thread
- ✅ `TogglePaymentStatusUseCase.swift` - Notificaciones en main thread

**Beneficio**: 0 warnings de threading, cumplimiento total con Swift 6 strict concurrency.

#### 2. Corrección de Captura de Variables en Código Concurrente
**Problema**: Error "Reference to captured var 'updatedPayment' in concurrently-executing code" en `UpdatePaymentUseCase`.

**Solución**: Cambiado `var updatedPayment` a `let updatedPayment` con asignación condicional.

**Beneficio**: Código thread-safe y sin errores de compilación.

#### 3. Corrección de Campo de Contraseña en Login
**Problema**: El campo de contraseña mostraba el texto por defecto en lugar de estar oculto.

**Solución**:
- ✅ `LoginViewModel.swift` - `showPassword` inicializado en `true` (oculto por defecto)
- ✅ `SecureTextFieldWithToggle.swift` - Corregida lógica del ícono del ojo

**Beneficio**: La contraseña inicia oculta (solo puntos) con ícono de ojo cerrado/bloqueado.

### 📊 Métricas

| Componente | Antes | Después | Mejora |
|-----------|--------|---------|--------|
| Edición pagos agrupados | ❌ No disponible | ✅ Completa | ✅ 100% |
| Sincronización calendario | ⚠️ Manual | ✅ Automática | ✅ 100% |
| Notificaciones locales | ❌ Perdidas | ✅ Restauradas | ✅ 100% |
| Warnings threading | 2 | 0 | ✅ 100% |
| Errores Swift 6 | 1 | 0 | ✅ 100% |

---

## [1.0.0] - Build 10 - 2026-01-11

### 🎯 Resumen Ejecutivo

**CLEAN ARCHITECTURE COMPLETA + REFACTORIZACIÓN DOMAIN ENTITIES** - Finalización de la implementación de Clean Architecture al 100% con renombrado de entidades (eliminación de sufijo "Entity"), actualización de todos los Use Cases, Repositories y Mappers, y resolución completa de warnings de Swift 6 concurrency.

### 🏗️ Clean Architecture - Phase 7: Entity Renaming & Consolidation

#### Renombrado de Entidades Domain
- ✅ `MonthlyStatsEntity` → `MonthlyStats`
- ✅ `CategoryStatsEntity` → `CategoryStats`
- ✅ `UserProfileEntity` → `UserProfile`

**Rationale**: Las entidades de dominio no necesitan sufijo "Entity". En Clean Architecture, si está en la carpeta `Domain/Entities/`, es obvio que es una entidad.

#### Archivos Actualizados (12+)

**Use Cases**:
- ✅ `CalculateMonthlyStatsUseCase.swift` - Actualizado a `MonthlyStats`
- ✅ `CalculateCategoryStatsUseCase.swift` - Actualizado a `CategoryStats`
- ✅ `FetchUserProfileUseCase.swift` - Actualizado a `UserProfile`
- ✅ `GetLocalProfileUseCase.swift` - Actualizado a `UserProfile`
- ✅ `UpdateUserProfileUseCase.swift` - Actualizado a `UserProfile`

**Repositories**:
- ✅ `UserProfileRepositoryProtocol.swift` - Actualizado signatures a `UserProfile`
- ✅ `UserProfileRepositoryImpl.swift` - Agregado `@MainActor`

**Validators**:
- ✅ `UserProfileValidator.swift` - Actualizado a `UserProfile`

**Mappers**:
- ✅ `PaymentMapper.swift` - Actualizado método `toLocalDTO` y `toRemoteDTO`
- ✅ `UserProfileMapper.swift` - Reescrito completamente con nuevas conversiones:
  - `toDomain(from: UserProfileLocalDTO) -> UserProfile`
  - `toLocalDTO(from: UserProfile) -> UserProfileLocalDTO`
  - `toDomain(from: UserProfileRemoteDTO) -> UserProfile`
  - `toRemoteDTO(from: UserProfile) -> UserProfileRemoteDTO`

**Presentation Models**:
- ✅ `CategorySpending.swift` - Actualizado a `CategoryStats` + conversión Decimal→Double
- ✅ `MonthlySpending.swift` - Actualizado a `MonthlyStats` + conversión Decimal→Double
- ✅ `UserProfileUI.swift` - Agregados mocks estáticos para previews

**ViewModels**:
- ✅ `CalendarViewModel.swift` - Agregada dependencia `PaymentUIMapping`
- ✅ `PaymentHistoryViewModel.swift` - Agregada dependencia `PaymentUIMapping`

**DI Containers**:
- ✅ `CalendarDependencyContainer.swift` - Inyección de `PaymentUIMapper()`
- ✅ `HistoryDependencyContainer.swift` - Inyección de `PaymentUIMapper()`

**Views**:
- ✅ `UserProfileView.swift` - Agregada conversión `UserProfileUI` → `UserProfile` para componentes
- ✅ `PaymentDetailsSection.swift` - Agregado `id: \.self` a `ForEach` para `PaymentCategory`

**Data Sources**:
- ✅ `PaymentSwiftDataDataSource.swift` - Actualizado a usar `PaymentLocalDTO` en lugar de entidades domain
- ✅ `UserProfileLocalDataSource.swift` - Agregado `@MainActor` al protocol

**App Configuration**:
- ✅ `AppDependencies.swift` - Método `mock()` actualizado para usar DTOs
- ✅ `PaymentDTO.swift` - Agregado memberwise initializer

**Sync**:
- ✅ `PaymentSyncRepositoryImpl.swift` - Actualizado a usar `toRemoteDTO` en lugar de `toDTO`

---

### 🐛 Bug Fixes

#### 1. Actualización de UI no Reactiva (CRÍTICO)
**Problema**: Al editar un pago (cambiar fecha), el pago se guardaba correctamente en SwiftData pero la UI no se actualizaba. El usuario veía datos obsoletos.

**Causa Raíz**: Los Use Cases (Create, Update, Delete, ToggleStatus) guardaban en SwiftData pero NO enviaban notificaciones para que los ViewModels refrescaran.

**Solución**: Agregadas notificaciones `PaymentsDidSync` en todos los Use Cases que modifican datos:

```swift
// ✅ CreatePaymentUseCase.swift
try await paymentRepository.savePayment(newPayment)
NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

// ✅ UpdatePaymentUseCase.swift
try await paymentRepository.savePayment(updatedPayment)
NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

// ✅ DeletePaymentUseCase.swift
try await paymentRepository.deleteLocalPayment(id: paymentId)
NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)

// ✅ TogglePaymentStatusUseCase.swift
try await paymentRepository.savePayment(updatedPayment)
NotificationCenter.default.post(name: NSNotification.Name("PaymentsDidSync"), object: nil)
```

**Archivos Modificados**:
- `CreatePaymentUseCase.swift`
- `UpdatePaymentUseCase.swift`
- `DeletePaymentUseCase.swift`
- `TogglePaymentStatusUseCase.swift`

**Beneficio**: Ahora cualquier cambio CRUD (crear, actualizar, eliminar, toggle status) notifica automáticamente a todas las pantallas que observan datos, actualizando la UI inmediatamente.

#### 2. Errores de Compilación - Entity Names
**Problema**: 27 errores de compilación por nombres de entidades incorrectos en Use Cases
**Fix**: Actualización sistemática de todos los Use Cases para usar nombres correctos

#### 3. ForEach Identifiable Error
**Problema**: `ForEach` requería que `PaymentCategory` conformara `Identifiable`
**Fix**: Agregado `id: \.self` explícito en `PaymentDetailsSection.swift:94`

#### 4. Mapper Method Errors
**Problema**: ViewModels llamaban métodos obsoletos `.toUI()` en arrays
**Fix**: Inyección de `PaymentUIMapping` en ViewModels + uso de `mapper.toUI(payments)`

#### 5. Type Conversion UserProfileUI → UserProfile
**Problema**: Componentes esperaban `UserProfile` pero recibían `UserProfileUI`
**Fix**: Conversión explícita usando `UserProfileUIMapper().toDomain(profileUI)` en `UserProfileView`

#### 6. Decimal/Double Mismatches
**Problema**: Domain usa `Decimal`, UI necesita `Double`
**Fix**: Conversiones usando `Double(truncating: NSDecimalNumber(decimal: amount))`

---

### ⚡ Swift 6 Concurrency Compliance

#### Warning 1: UserProfileLocalDataSource Sendable
**Problema**: Protocol retornaba `[UserProfileLocalDTO]` desde contexto `@MainActor` isolated
**Fix**: Agregado `@MainActor` al protocol `UserProfileLocalDataSource`

```swift
@MainActor
protocol UserProfileLocalDataSource {
    func fetchAll() async throws -> [UserProfileLocalDTO]
    func save(_ profileDTO: UserProfileLocalDTO) async throws
    func deleteAll(_ profileDTOs: [UserProfileLocalDTO]) async throws
    func clear() async throws
}
```

#### Warning 2: UserProfileRepositoryImpl Sendable
**Problema**: Repository llamaba método `@MainActor` desde contexto no-aislado, retornando tipos non-Sendable
**Fix**: Agregado `@MainActor` a:
- `UserProfileRepositoryProtocol` (protocol)
- `UserProfileRepositoryImpl` (implementation)

```swift
@MainActor
protocol UserProfileRepositoryProtocol {
    func fetchProfile(userId: UUID) async -> Result<UserProfile, UserProfileError>
    func getLocalProfile() async -> Result<UserProfile?, UserProfileError>
    // ...
}

@MainActor
final class UserProfileRepositoryImpl: UserProfileRepositoryProtocol {
    // Implementation now properly isolated to MainActor
}
```

**Rationale**: SwiftData `ModelContext` requiere `@MainActor`. Repositories que usan SwiftData deben estar `@MainActor` isolated para cumplir Swift 6 strict concurrency.

**Estado Final**: ✅ **0 errores, 0 warnings** - Proyecto 100% Swift 6 compliant

---

### 📊 Métricas

| Componente | Antes | Después | Mejora |
|-----------|--------|---------|--------|
| Errores compilación | 27+ | 0 | ✅ 100% |
| Warnings Swift 6 | 2 | 0 | ✅ 100% |
| Entity naming | Mixed | Consistent | ✅ 100% |
| Mapper consistency | Inconsistent | Clean | ✅ 100% |
| UI reactivity | Broken | Real-time | ✅ 100% |
| Concurrency compliance | Partial | Full | ✅ 100% |

---

### 🎨 Arquitectura Final

#### Flujo de Datos Completo

```
┌─────────────────────────────────────────────────────────┐
│                    PRESENTATION                          │
│  Views → ViewModels (@Observable) → UI Models           │
│         (Observable)    ↓           (PaymentUI)         │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ↓ Use Cases
┌─────────────────────────────────────────────────────────┐
│                       DOMAIN                             │
│  Entities (Payment, MonthlyStats, CategoryStats)        │
│  Use Cases (Create, Update, Delete, Calculate)          │
│  Repositories (Protocols)                                │
│  Errors (PaymentError, UserProfileError)                │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ↓ Repository Implementations
┌─────────────────────────────────────────────────────────┐
│                        DATA                              │
│  Repositories Impl → Mappers → DTOs                     │
│  ↓                    ↓         (Local/Remote)           │
│  DataSources:         Conversions:                       │
│  - SwiftData (Local)  - DTO ↔ Domain                    │
│  - Supabase (Remote)  - Domain ↔ UI                     │
└─────────────────────────────────────────────────────────┘
```

#### Tipos por Capa

| Capa | Tipo de Datos | Razón |
|------|--------------|-------|
| **Domain** | `Decimal` | Precisión financiera |
| **Data (Local)** | `Double` | SwiftData requiere `Double` |
| **Data (Remote)** | `Double` | JSON estándar |
| **Presentation** | `Double` | SwiftUI bindings |

**Conversiones**:
- Domain → DTO: `Decimal` → `Double` (en Mappers)
- DTO → Domain: `Double` → `Decimal` (en Mappers)
- Domain → UI: `Decimal` → `Double` (en UI Mappers)

---

### 🔄 Reactividad

#### NotificationCenter Strategy

**¿Por qué NotificationCenter?**
- ✅ Broadcasting eficiente (un evento → múltiples observadores)
- ✅ Desacoplamiento total (ViewModels no se conocen entre sí)
- ✅ Simple y confiable
- ✅ Mantiene Clean Architecture (lógica fuera de Views)

**Flujo Completo**:
```
User edits payment
  ↓
EditPaymentViewModel.saveChanges()
  ↓
UpdatePaymentUseCase.execute()
  ↓
Repository.savePayment() → SwiftData
  ↓
Use Case posts "PaymentsDidSync" notification
  ↓
All observing ViewModels:
  - PaymentHistoryViewModel
  - CalendarViewModel
  - PaymentsListViewModel
  - DashboardViewModel
  ↓
Auto-refresh from SwiftData
  ↓
UI updates immediately
```

**Alternativa Considerada**: `@Query` directo en vistas
**Decisión**: Mantener Clean Architecture 100% (lógica en ViewModels) fue prioritario

---

### ✅ Quality Checklist

#### Arquitectura
- [x] Clean Architecture Domain/Data/Presentation estricta
- [x] Use Cases para toda la lógica de negocio
- [x] Repository Pattern con protocols
- [x] Dependency Injection con containers por feature
- [x] Mappers para todas las conversiones de capa
- [x] DTOs separados para Local/Remote

#### Swift 6 Compliance
- [x] 0 errores de compilación
- [x] 0 warnings de concurrency
- [x] `@MainActor` solo donde necesario (ViewModels + SwiftData repos)
- [x] `Sendable` types en Domain
- [x] Actor isolation correcto

#### Reactividad
- [x] NotificationCenter para broadcasting
- [x] Todos los Use Cases notifican cambios
- [x] ViewModels observan notificaciones
- [x] UI se actualiza automáticamente

#### Naming & Consistency
- [x] Entidades sin sufijo "Entity"
- [x] Nombres consistentes en toda la app
- [x] Mappers con nombres explícitos (toDomain, toLocalDTO, toRemoteDTO, toUI)

---

### 📁 Archivos Cambiados

**Total**: 30+ archivos modificados

**Categorías**:
- Domain Entities: 3 archivos renombrados
- Use Cases: 5 archivos actualizados
- Repositories: 2 protocols + 2 implementations actualizados
- Mappers: 2 archivos reescritos
- ViewModels: 2 archivos actualizados
- Views: 2 archivos actualizados
- Data Sources: 2 archivos actualizados
- DI Containers: 2 archivos actualizados
- Presentation Models: 3 archivos actualizados
- DTOs: 1 archivo actualizado
- Sync: 1 archivo actualizado

---

## [Versiones Anteriores]

### Build 9 - Clean Architecture Complete + PaymentUI Migration
Ver sección "Build 10 - Clean Architecture Complete" en archivo original para detalles de la fase 6.

### Build 8 - 100% Modernización iOS 18.5 + Swift 6
Ver sección "Changelog - 100% Modernización iOS 18.5 + Swift 6" en archivo original para detalles de migración a @Observable.

### Build 1-7 - Fase 1: Fixes Críticos
Ver sección "Changelog - Fase 1: Fixes Críticos" en archivo original para detalles de implementaciones iniciales.

---

## 🚀 Roadmap

### Próximas Mejoras (v1.1.0)

**Performance**:
- [ ] Optimización de sincronización (sync solo diferencias)
- [ ] Cache de imágenes de perfil
- [ ] Lazy loading en listas largas

**Features**:
- [ ] Compartir pagos entre usuarios (familia)
- [ ] Exportar datos a CSV/PDF
- [ ] Widget de iOS para dashboard
- [ ] Apple Watch companion app
- [ ] Modo oscuro personalizable

**Testing**:
- [ ] Aumentar cobertura a 70%+
- [ ] Integration tests para sync
- [ ] UI tests con XCTest

**Arquitectura**:
- [ ] Considerar migración a `@Query` para vistas simples
- [ ] Evaluar AsyncStream vs NotificationCenter
- [ ] Implementar paginación en listados grandes

---

## 📞 Soporte

¿Encontraste un bug? ¿Tienes una sugerencia?

1. 📖 Revisa este CHANGELOG
2. 📄 Lee el [README.md](README.md)
3. 🐛 [Abre un issue](../../issues)

---

---

**Versión**: 1.0.0 (Build 11)
**Fecha**: 2026-01-18
**Estado**: ✅ Production Ready (TestFlight)
**Swift**: 6.0
**iOS**: 18.5+

---

## [1.0.0] - Build 10 - 2026-01-11
