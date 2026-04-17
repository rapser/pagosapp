# 📋 TECHNICAL AUDIT REPORT
## pagosApp — iOS Swift Application
### Principal iOS Solutions Architect Review

---

| Campo              | Detalle                                |
|--------------------|----------------------------------------|
| **App**            | pagosApp (Gestión de Pagos Personales) |
| **Plataforma**     | iOS 18.5+ / Swift 6                    |
| **Arquitectura**   | Clean Architecture + MVVM              |
| **Fecha auditoría**| 11 de abril de 2026                    |
| **Última revisión**| 16 de abril de 2026                    |
| **Tipo**           | Auditoría completa (inicial estática; revisión contrastada con repo) |
| **Alcance**        | 311 archivos Swift (~308 app + 3 tests) / ~22,200 LOC (tracked, abr. 2026) |

---

## 📊 RESUMEN EJECUTIVO

```
┌─────────────────────────────────────────────────┐
│         PUNTUACIÓN GENERAL DE SALUD             │
├─────────────────────────────────────────────────┤
│ Arquitectura & Diseño         ██████████░ 94%   │
│ Seguridad (OWASP MASVS)       █████████░ 90%   │
│ Calidad de Código             █████████░ 88%   │
│ Concurrencia & Thread Safety  ██████████░ 92%   │
│ Testing                       ██░░░░░░░░░ 20%   │
│ Performance                   █████████░░ 82%   │
│ CI/CD & DevOps                █████░░░░░░ 48%   │
│ Escalabilidad                 ████████░░░ 82%   │
│ Internacionalización          ██████████░ 99%   │
├─────────────────────────────────────────────────┤
│ PUNTUACIÓN GLOBAL             █████████░ 87%   │
│ GRADO: A (Bueno; foco: ampliar tests + CI con   │
│         tests en runner y release automation)   │
└─────────────────────────────────────────────────┘
```

**Veredicto (pendientes)**: El proyecto **subió de madurez** respecto a la auditoría inicial; los huecos principales pasan a ser **amplitud de tests**, **CI más completo** (tests en GitHub Actions con simulador acordado, cobertura, distribución) y **hardening opcional** (Realtime, políticas servidor).

- **P0 (alto impacto, aún abiertos)**:
  - **Testing**: existe suite mínima (validators + smoke); falta cobertura amplia (use cases, sync, UI).
  - **CI/CD**: hay workflow de **build + SwiftLint**; falta gate de **tests** estable en CI y pipeline de release/TestFlight.
- **P1 (mayor)**:
  - **SwiftLint**: reglas activas en repo; endurecer reglas / corregir warnings acumulados con el tiempo.
- **P2 (menor)**:
  - **Feature toggles**: no existe `FeatureFlagService` / flags remotos.
  - **Runtime validation**: ejecutar checklist TSan/Instruments (`docs/engineering/CONCURRENCY_VALIDATION.md`).

**Nota de revisión (16-abr-2026)**: Métricas de alcance (archivos Swift, LOC, `Task {`, `@MainActor`) **recontrastadas** con el árbol git rastreado y búsqueda estática en código. ADRs en `docs/adr/`, runbooks SSL en `docs/runbooks/`, contrato de sync y checklist de concurrencia en `docs/engineering/`, lockout de login en cliente (`LoginAttemptTracking`), **internacionalización ampliada**: notificaciones locales (`L10n.LocalNotifications`, `notifications.*`), **flujos de auth en UI** (registro, login por email/contraseña, biométrica, restablecer contraseña), **perfil** (género con `gender.*`, fecha de nacimiento, filas de solo lectura), **errores de calendario** en `CalendarViewModel`, **errores de red genéricos** en `BaseViewModel` (`general.network.*`), **pantallas de depuración** (`L10n.Debug.*`: notificaciones, sesión, ajustes de notificación), placeholder de recordatorios, títulos por defecto de alertas/estado de error; claves repartidas en `es` / `en` / `pt` / `Base`. También `.swiftlint.yml` y `.github/workflows/ci.yml`.

---

## 🧭 2. ARQUITECTURA Y ESTRUCTURA

### 2.1 Patrón Arquitectónico

**Clean Architecture** con MVVM en la capa de Presentación.

```
┌────────────────────────────────────────────────────┐
│                  PRESENTATION                       │
│  Views (SwiftUI) ← ViewModels (@Observable/MVVM)   │
│  Coordinators (Sync/Session)                        │
├────────────────────────────────────────────────────┤
│                    DOMAIN                           │
│  Use Cases  │  Entities  │  Repository Protocols   │
│  Validators │  Events    │  Domain Errors           │
├────────────────────────────────────────────────────┤
│                     DATA                            │
│  Repository Impl  │  DTOs  │  Mappers              │
│  Local (SwiftData) │ Remote (Supabase)              │
├────────────────────────────────────────────────────┤
│                  PLATFORM / DI                      │
│  DependencyContainers │ NotificationService        │
│  CalendarService      │ KeychainService            │
└────────────────────────────────────────────────────┘
```

**Cumplimiento de reglas de dependencia**: ✅ La dirección siempre apunta hacia el interior (Domain ← Data ← Presentation). No se encontraron violaciones.

### 2.2 Módulos y Feature Containers

| Módulo | DI Container | Use Cases | ViewModels | Estado |
|--------|-------------|-----------|------------|--------|
| Auth | `AuthDependencyContainer` | 15 | 4 | ✅ |
| Payments | `PaymentDependencyContainer` | 11 | 3 | ✅ |
| Reminders | `ReminderDependencyContainer` | ~8 | 3 | ✅ |
| Calendar | `CalendarDependencyContainer` | 3 | 1 | ✅ |
| Statistics | `StatisticsDependencyContainer` | ~2 | 1 | ✅ |
| History | `HistoryDependencyContainer` | ~2 | 1 | ✅ |
| Settings | `SettingsDependencyContainer` | 4 | 2 | ✅ |
| UserProfile | `UserProfileDependencyContainer` | ~3 | ~2 | ✅ |

### 2.3 Navegación

- **Patrón**: Tab-based con `NavigationStack` por módulo
- **Tabs**: Payments · Reminders · Calendar · Settings
- **Deep Links**: `pagosapp://` scheme manejado en `DeepLinkHandler.swift`
- **Auth Flow**: `ContentView` actúa como router condicional basado en `SessionCoordinator.isAuthenticated`

### 2.4 Dependencias SPM

| Librería | Propósito | Versión | Riesgo |
|----------|-----------|---------|--------|
| `supabase-swift` | BaaS (Auth + DB) | N/D | Bajo |
| SwiftUI (native) | UI Framework | iOS 18+ | Ninguno |
| SwiftData (native) | ORM Local | iOS 17+ | Bajo |
| OSLog (native) | Logging Estructurado | iOS 14+ | Ninguno |
| LocalAuthentication (native) | Biometría | iOS 8+ | Ninguno |
| EventKit (native) | Calendario | iOS 6+ | Ninguno |
| UserNotifications (native) | Notificaciones | iOS 10+ | Ninguno |

**Evaluación**: Dependencias mínimas y mayormente nativas — excelente para mantenimiento a largo plazo.

**Documentación de arquitectura**: ADRs mínimos en [`docs/adr/`](docs/adr/) (capas, sync, notificaciones, DI, roadmap SPM opcional).

### 2.5 Inventario UI (Views)

- **Shared Components**: `GenericEmptyStateView`, `LoadingView`, `LoadingStateView`, `StyledTextField`, `ErrorStateView`, `PrimaryActionButton`, `AlertButton`
- **Auth**: `LoginView`, `RegistrationView`, `ForgotPasswordView`, `ResetPasswordView` + 4 components
- **Payments**: `PaymentsListView`, `AddPaymentView`, `EditPaymentView`, `PaymentRowView`, `PaymentGroupRowView` + 4 components
- **Reminders**: `RemindersListView`, `AddReminderView`, `EditReminderView`, `ReminderRowView` + components
- **Calendar**: `CalendarPaymentsView`, `CustomCalendarView` + 6 components
- **Statistics**: `StatisticsView` + 5 chart components
- **Settings**: `SettingsView` + 8 section components + 2 debug views

---

## 🌐 3. NETWORKING (DEEP DIVE)

### 3.1 Arquitectura de Red

- **Cliente HTTP**: Supabase Swift SDK (abstrae URLSession internamente)
- **Autenticación**: Token JWT vía Bearer — manejado automáticamente por Supabase SDK
- **Persistencia de sesión**: Tokens almacenados en Keychain (seguro ✅)

### 3.2 Patrones de Sincronización

La app implementa un modelo **Offline-First** con sincronización diferida:

```
App Launch → Carga local SwiftData → Muestra UI inmediatamente
           → Background: Sube cambios pendientes → Descarga remotos
```

**Componentes**:
- `PaymentSyncCoordinator` — coordina upload + download de pagos
- `ReminderSyncCoordinator` — coordina upload + download de recordatorios
- `AppSyncManager` — fachada que agrega estado de ambos coordinadores
- `AppLifecycleHandler` — dispara sync en foreground

### 3.3 Tabla de Hallazgos de Red

| Área | Problema | Severidad | Recomendación |
|------|----------|-----------|---------------|
| Timeouts / logging / retry / rate limit | (Sin pendientes detectadas en este punto) | — | Mantener revisión periódica y validar en runtime (latencias reales, errores 4xx/5xx) |

### 3.4 Manejo de Errores de Red

```swift
// ✅ BIEN: Error mapping tipado
enum PaymentSyncError: Error {
    case uploadFailed(Error)
    case downloadFailed(Error)
    case networkUnavailable
}

// ✅ ACTUAL: Logout sin fallos silenciosos
// - Si el signOut remoto falla, el error se registra y se retorna a capa superior.
// - El logout local (offline-first) se completa limpiando tokens localmente.
```

---

## 🔐 4. SEGURIDAD (OWASP MASVS)

### 4.1 M1 — Almacenamiento Inseguro de Credenciales

**Estado**: ✅ CORRECTO

- Tokens de acceso/refresh → Keychain con `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Credenciales biométricas → Keychain con `SecAccessControlCreateWithFlags(.biometryCurrentSet)`
- Sincronización iCloud de Keychain deshabilitada (`kSecAttrSynchronizable: false`)
- Datos no sensibles (fechas de sync, preferencias) → UserDefaults ✅

### 4.2 M2 — Secretos Expuestos

**Estado**: ✅ CORRECTO con nota

```
Config/Secrets.template.xcconfig  ← Sí en git (solo template)
pagosApp/Config/Secrets.xcconfig  ← EN .gitignore ✅
```

**Template estructura**:
```xcconfig
SUPABASE_URL = 
SUPABASE_ANON_KEY = 
```

**Riesgo Residual**: La `SUPABASE_ANON_KEY` por diseño de Supabase es pública y las políticas RLS protegen los datos. Sin embargo, si en el futuro se añaden keys con mayor privilegio, el mecanismo xcconfig es correcto.

### 4.3 M3 — SSL Pinning

**Pendiente**:
- Validar en **runtime** cobertura efectiva para canales **Realtime/WebSocket** frente al estado documentado en [`docs/runbooks/ssl-pinning-coverage-matrix.md`](docs/runbooks/ssl-pinning-coverage-matrix.md).

**Referencia**: runbook de rotación en [`docs/runbooks/ssl-pinning-rotation.md`](docs/runbooks/ssl-pinning-rotation.md).

### 4.4 M4 — Autenticación Débil

**Pendiente**:
- (Opcional) Alinear lockout **cliente** con políticas/rate-limit del **proveedor** (Supabase) si el producto exige límites centralizados además del guard local.

### 4.5 M5 — Criptografía Débil

**Estado**: ✅ NO SE ENCONTRÓ criptografía casera

- No se utiliza MD5, SHA1 o AES manual
- Toda la criptografía delegada a Keychain (hardware-backed), TLS y Supabase

### 4.6 M6 — Race Condition en Keychain

**Pendiente**:
- (Sin pendientes detectadas en este punto)

### 4.7 Force Unwraps de URLs (Riesgo Bajo)

**Pendiente**:
- (Sin pendientes detectadas en este punto)

### 4.8 fatalError en Código de Producción

| Archivo | Línea | Contexto | Riesgo |
|---------|-------|----------|--------|
| `AppDependencies.swift` | L133 | Mock container | 🟢 Bajo — solo en mocks |
| `AppDependencies.swift` | L137 | Mock Supabase URL | 🟢 Bajo — solo en mocks |
| `SupabaseClientFactory.swift` | — | Cliente demo (URL constante conocida) | 🟢 Bajo — sin `fatalError`; queda `!` sobre literal fijo |

**Pendiente**:
- (Sin pendientes críticas en rutas no-mock para el fallback demo.)

---

## 🧪 5. TESTING

### 5.1 Estado Actual

- **Swift Testing** en `pagosAppTests/`: `EmailValidatorTests`, `PasswordValidatorTests`, smoke `bundleLoads` en `pagosAppTests.swift`.
- Ejecución local verificada con destino simulador concreto (p. ej. iPhone 17).

**Cobertura estimada**: ~5–8% del código de producto (base mínima; prioridad sigue siendo ampliar).

### 5.2 Análisis de Gaps de Testing

| Capa | Componentes sin Test | Prioridad |
|------|---------------------|-----------|
| Validators | `PaymentValidator` (Email/Password cubiertos) | 🟡 P1 |
| Domain Use Cases | ~50 use cases sin test | 🔴 P0 |
| Data Mappers | `PaymentMapper`, `ReminderMapper`, DTOs mappers | 🔴 P0 |
| Repository Logic | Sync logic, error handling | 🔴 P0 |
| ViewModels | Business logic en ViewModels | 🟡 P1 |
| Integration | Sync coordinators | 🟡 P1 |
| UI Tests | Critical flows (login, add payment) | 🟡 P1 |
| Snapshot Tests | UI components | 🟢 P2 |

### 5.3 Arquitectura de Tests Recomendada

```
pagosAppTests/
├── Unit/
│   ├── Auth/
│   │   ├── EmailValidatorTests.swift
│   │   ├── PasswordValidatorTests.swift
│   │   └── LoginUseCaseTests.swift
│   ├── Payments/
│   │   ├── PaymentValidatorTests.swift
│   │   ├── PaymentMapperTests.swift
│   │   └── CreatePaymentUseCaseTests.swift
│   └── Shared/
│       └── EventBusTests.swift
├── Integration/
│   ├── PaymentSyncCoordinatorTests.swift
│   └── ReminderSyncCoordinatorTests.swift
└── UI/
    └── LoginFlowUITests.swift
```

### 5.4 Tests implementados (referencia)

Los casos de la tabla anterior para **email/password** están en el repo (`EmailValidatorTests.swift`, `PasswordValidatorTests.swift`). Siguen pendientes `LoginUseCaseTests`, mappers, sync y UI según §5.3.

---

## 🧠 6. MEMORY & CRASHES

### 6.1 Retain Cycles

**Búsqueda**: **85** líneas con `Task {` en el target principal (reconteo abr. 2026; ver §10.3).

**Resultado**: ✅ **Sin ciclos evidentes** en la revisión estática; donde `self` se captura en el mismo closure suele aparecer `[weak self]` (19 líneas) o el tipo ya vive en `@MainActor`. Siguen siendo recomendables revisiones puntuales en los `Task {` sin `weak` explícito y validación con Instruments/TSan.

Patrón recomendado cuando el closure retiene el coordinador/VM:
```swift
// ✅ Patrón seguro cuando hay riesgo de retención
Task { @MainActor [weak self] in
    guard let self else { return }
    await self.fetchPayments()
}
```

### 6.2 Force Unwraps

**Pendiente**: (Sin pendientes detectadas en este punto)

### 6.3 Gestión de SwiftData

**Pendiente**:
- Validación manual de degradación/recuperación de store corrupto en dispositivos reales (UX y mensajes).

### 6.4 Delegates y Observación

- ✅ `UNUserNotificationCenterDelegate` — implementado con `nonisolated` correctamente
- ✅ `@Observable` en lugar de `ObservableObject` — sin `AnyCancellable` leaks
- ✅ `AsyncStream` en EventBus — cleanup automático en terminación

---

## ⚙️ 7. PERFORMANCE

### 7.1 Launch Time

**Pendiente**:
- Medir y validar con **Instruments** el tiempo real de inicialización de SwiftData/Supabase en dispositivos (escenarios con DB grande).

**Riesgo**: `ModelContainerFactory.create()` realiza I/O síncrono en el main thread durante el launch. Con bases de datos grandes puede incrementar TTI (Time To Interactive).

**Acción aplicada**: Inicialización diferida con vista de arranque (loading) y creación de `ModelContainer`/Supabase/DI en `task`.

### 7.2 Main Thread Blocking

**DispatchQueue**: 0 usos ✅ — Toda la concurrencia via async/await  
**Operaciones síncronas en @MainActor**: Solo las necesarias por SwiftData  
**UI Operations**: Todas en `@MainActor` correctamente

### 7.3 Scrolling Performance

`PaymentsListViewModel`: el agrupamiento se recalcula vía `scheduleGroupedPaymentsRecompute()` (debounce ~150 ms) ante cambios en `payments` o en el filtro, lo que reduce trabajo repetido frente a un `didSet` directo.

**Pendiente**:
- Validar rendimiento real con 1000+ pagos en dispositivos (scroll + CPU) y afinar el debounce si hiciera falta.

### 7.4 Imágenes

- No se detectó uso de imágenes de red
- Assets locales via `xcassets` — óptimo ✅

### 7.5 Paginación

**Estado actual**: la descarga de pagos desde Supabase usa **páginas** (`fetchPage` con `limit`/`offset` y acumulación hasta completar el dataset) en [`PaymentSupabaseDataSource.swift`](pagosApp/Features/Payments/Data/DataSources/PaymentSupabaseDataSource.swift).

**Pendiente**:
- Si el volumen de **recordatorios** u otras tablas remotas crece mucho, valorar el mismo patrón de paginación allí.

---

## 📈 8. ESCALABILIDAD

### 8.1 Modularización

**Pendiente**:
- Si se planea escalar a múltiples targets/frameworks o equipos grandes, definir roadmap de modularización (SPM) y fronteras de módulos.

### 8.2 Feature Toggles

**Estado**: ❌ NO IMPLEMENTADO

No existe mecanismo de feature flags. Recomendación: implementar un `FeatureFlagService` simple que lea desde Supabase Remote Config o un archivo de configuración local.

### 8.3 Offline-First

**Estado**: ✅ IMPLEMENTADO correctamente

- SwiftData actúa como source of truth para la UI
- Sync opera en background sin bloquear la UI
- `SyncStatus` en entidades Payment (`local`, `synced`, `pendingDelete`)

**Pendiente**:
- Opcional: documentar para onboarding la política de merge en download (**server-wins** salvo estados locales pendientes; referencia en código: `DownloadRemoteChangesUseCase`, `DownloadReminderChangesUseCase`).

### 8.4 Internacionalización

| Idioma | Código | Cobertura | Estado |
|--------|--------|-----------|--------|
| Español | `es` | ~99% | ✅ Base |
| Inglés | `en` | ~95% | ✅ (pulido de copy UX según producto) |
| Portugués | `pt` | ~99% | ✅ (pulido de copy UX opcional) |
| Plurales | `stringsdict` | Casos clave | ✅ (extender a más textos dinámicos si aparecen nuevos) |
| Notificaciones locales (UN) | `L10n.LocalNotifications` | Pagos + recordatorios | ✅ Builders + `NumberFormatter` / `Locale.current` |
| Presentación (auth, perfil, calendario, errores) | `L10n` + `Localizable` | Formularios, validaciones en VM, `ProfileFieldRow`, `GenderPickerRow`, `DatePickerRow` | ✅ |
| Errores de red genéricos | `general.network.*` | `BaseViewModel.handleNetworkError` | ✅ |
| Pantallas debug (opcional) | `L10n.Debug.*` | Notificaciones, sesión, ajustes de notificación | ✅ |

**Hallazgo**: El sistema **L10n** en `L10n.swift` concentra la mayor parte del texto visible al usuario (incluidos flujos de **Auth** en pantalla, **perfil**, **calendario**, **UNUserNotificationCenter** y **debug**). Los errores de dominio de auth siguen mapeándose con `AuthErrorMessageMapper` / claves `auth.error.*`. **Residual esperado**: mensajes derivados de `Error.localizedDescription`, strings en **logs** (`L10n.Log` ya orientado a consola), **previews** o **datos de prueba** en pantallas debug (p. ej. título por defecto de notificación de prueba); revisión puntual si el equipo exige cero literales.

---

## 🧹 9. CODE QUALITY

### 9.1 SwiftLint

**Estado**: `.swiftlint.yml` en la raíz del repo; job **SwiftLint** en [`.github/workflows/ci.yml`](.github/workflows/ci.yml) (instalación vía Homebrew en el runner).

**Recomendación** (evolución): ir endureciendo reglas y reducir exclusiones (hoy `L10n.swift` está excluido por tamaño/anidación).

### 9.2 Métricas de Complejidad

| Archivo | Líneas (wc -l, abr. 2026) | Complejidad | Estado |
|---------|---------------------------|-------------|--------|
| `SessionCoordinator.swift` | 389 | Alta | ⚠️ 6 dependencias, múltiples estados |
| `PaymentsListViewModel.swift` | 278 | Media-Alta | ✅ Bien organizado |
| `PaymentDependencyContainer.swift` | 267 | Media | ✅ Factory methods bien estructurados |
| `AppDependencies.swift` | 164 | Media | ✅ God object controlado |
| `NotificationDataSource.swift` | 157 | Media | ✅ Scheduler + `LocalNotificationIdentifiers` (prefijos `payment-`/`reminder-`) |

### 9.3 Code Smells Detectados

| Smell | Archivo | Detalle | Severidad |
|-------|---------|---------|-----------|
| Strings literales residuales | Logs, previews, `localizedDescription` de APIs, datos de prueba en debug | Fuera del camino crítico de UI | 🟢 Baja |
| God object (controlado) | `AppDependencies.swift` | 8 feature containers | 🟢 Baja |
| Magic numbers | `VerifyRemoteSessionUseCase` | Centralizado en `SessionVerificationTiming` | 🟢 Baja |
| Duplicación residual | Listas pagos/reminders | Unificada en `ListNotificationBootstrap` | 🟢 Baja |

**Pendiente** (opcional):
- Regla o búsqueda periódica para nuevos literales en **Presentation**; revisión nativa de **copy** en `en` / `pt`.

### 9.4 Patrones Positivos Destacados

- ✅ `BaseViewModel` elimina boilerplate en todos los ViewModels
- ✅ `GenericNotificationScheduler` elimina duplicación de scheduling; `LocalNotificationIdentifiers` centraliza IDs y cancelación
- ✅ Contenido de notificaciones locales internacionalizado (`L10n.LocalNotifications` + `notifications.payment.*` / `notifications.reminder.*`)
- ✅ Auth en UI (registro, login, biométrica, reset), perfil (género/fecha), calendario (errores de carga), errores de red y pantallas **Debug** bajo `L10n.Debug.*`; alertas/estado de error unifican título con `L10n.General.error`
- ✅ `LoadingState` protocol para operaciones async
- ✅ `MapperProtocol` para consistencia en transformaciones
- ✅ Cero uso de `print()` — todo vía `OSLog` ✅
- ✅ Cero uso de `DispatchQueue` — todo vía `async/await` ✅

---

## ⚡ 10. CONCURRENCIA

### 10.1 Swift 6 Strict Concurrency

**Estado**: ✅ COMPLIANT

El proyecto fue construido con Swift 6 strict concurrency desde el inicio, lo que garantiza:
- Isolation correcta con `@MainActor`
- Tipos `Sendable` en cruces de actor boundaries
- Sin data races detectables estáticamente

### 10.2 Distribución de @MainActor

**Medición textual** (líneas que contienen `@MainActor` en `pagosApp/**/*.swift`): **~126** ocurrencias (grep, abr. 2026). Con el tamaño actual del código, este número sirve sobre todo como **indicador de uso intensivo de aislamiento al hilo principal**; un inventario exacto tipos vs miembros requeriría análisis AST (Xcode / swift-syntax).

### 10.3 Análisis de Task Creations

**Total**: **85** líneas que contienen `Task {` en el target principal (búsqueda línea a línea; abr. 2026).

| Patrón (misma línea de apertura) | Conteo | Estado |
|----------------------------------|--------|--------|
| `Task {` + `[weak self]` | 19 | ✅ |
|   de ellas con `@MainActor` | 14 | ✅ |
| `Task {` + `@MainActor` sin `[weak self]` en la misma línea | 13 | ✅ Revisar cancelación / prioridad donde aplique |
| `Task {` sin `@MainActor` ni `[weak self]` en la misma línea | 53 | ⚠️ Revisión puntual (muchas vistas/VM ya están en MainActor por tipo) |

**Resultado**: No se detectaron patrones obvios de retain cycle en la muestra revisada; conviene seguir aplicando el checklist de [`CONCURRENCY_VALIDATION.md`](docs/engineering/CONCURRENCY_VALIDATION.md) ante nuevos `Task {`.

### 10.4 Potenciales Race Conditions

| Área | Descripción | Severidad |
|------|-------------|-----------|
| Keychain | (Sin pendientes detectadas en este punto) | — |
| `hasRescheduledNotifications` | Flag en memoria — se resetea en cada launch (intencional) | 🟢 Baja |
| Sync concurrent prevention | Guards implementados en coordinadores | ✅ |

**Documentación**: [`docs/engineering/SYNC_COORDINATOR_CONTRACT.md`](docs/engineering/SYNC_COORDINATOR_CONTRACT.md) y checklist TSan/Instruments en [`docs/engineering/CONCURRENCY_VALIDATION.md`](docs/engineering/CONCURRENCY_VALIDATION.md).

### 10.5 Patrón EventBus

```swift
// ✅ EXCELENTE: Type-safe, Sendable, AsyncStream-based
protocol EventBus: Sendable {
    func publish<T: DomainEvent>(_ event: T)
    func subscribe<T: DomainEvent>(to type: T.Type) -> AsyncStream<T>
}
```

El patrón elimina el acoplamiento entre módulos de forma segura para concurrencia.

---

## ⚠️ 12. DEUDA TÉCNICA

### P0 — Crítico (Resolver antes de siguiente release)

| ID | Problema | Archivo(s) | Esfuerzo | Impacto |
|----|----------|-----------|---------|---------|
| TD-01 | **Cobertura de tests insuficiente** (base mínima existente) | `pagosAppTests/` | 40-80h | 🔴 Muy Alto |
| TD-02 | **CI incompleto** (build + lint sí; falta test gate estable + release) | `.github/workflows/` | 8-24h | 🔴 Alto |

### P1 — Mayor (Resolver en próximo sprint)

| ID | Problema | Archivo(s) | Esfuerzo | Impacto |
|----|----------|-----------|---------|---------|
| TD-09 | Endurecer SwiftLint y reducir exclusiones | `.swiftlint.yml` | 2-8h | 🟡 Medio |

### P2 — Menor (Backlog planificado)

| ID | Problema | Archivo(s) | Esfuerzo | Impacto |
|----|----------|-----------|---------|---------|
| TD-12 | Sin feature flags | Global | 8h | 🟢 Bajo |

### P3 — Mejoras (Roadmap futuro)

| ID | Mejora | Detalle |
|----|--------|---------|
| TD-15 | Modularización SPM | Separar features en Swift Packages |
| TD-16 | Analytics | Integrar Supabase Analytics o Mixpanel |
| TD-17 | A/B Testing | Feature flags con targeting |
| TD-18 | Account deletion | Server-side Edge Function en Supabase |
| TD-19 | Más idiomas | Añadir `fr`, `de` |

---

## 📦 13. CI/CD

### 13.1 Estado Actual

**Estado**: ⚠️ **Parcial — en marcha**

Presente en el repo:
- [`.github/workflows/ci.yml`](.github/workflows/ci.yml): **build** (`xcodebuild` simulador genérico) + **SwiftLint** (`brew install swiftlint`).
- Sin Fastlane/Match/TestFlight automatizado aún; tests unitarios se ejecutan de forma fiable en **Xcode con simulador concreto** (el runner de GitHub requiere alinear `destination` con los simuladores disponibles para añadir `xcodebuild test` al workflow).

**Pendiente**:
- Añadir job de **tests** en CI con destino simulador fijado por el equipo.
- Opcional: Fastlane, subida de cobertura, archivo IPA/TestFlight.

### 13.2 Pipeline Recomendado

```yaml
# .github/workflows/ci.yml (RECOMENDADO)
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4
      - name: Run Tests
        run: xcodebuild test -scheme pagosApp
                             -destination 'platform=iOS Simulator,name=iPhone 16'
                             -resultBundlePath TestResults.xcresult
      - name: Upload Coverage
        uses: codecov/codecov-action@v4

  build:
    needs: test
    runs-on: macos-15
    steps:
      - name: Archive App
        run: xcodebuild archive -scheme pagosApp
                                -archivePath pagosApp.xcarchive
      - name: Export IPA
        run: xcodebuild -exportArchive ...
      - name: Upload to TestFlight
        run: xcrun altool --upload-app ...
```

### 13.3 Fastlane Setup Recomendado

```ruby
# Fastfile
lane :test do
  run_tests(scheme: "pagosApp")
end

lane :beta do
  increment_build_number
  build_app(scheme: "pagosApp")
  upload_to_testflight
end

lane :release do
  increment_version_number
  build_app(scheme: "pagosApp")
  upload_to_app_store
end
```

---

## 🔑 14. SECRETOS

### 14.1 Inventario de Credenciales

| Secreto | Almacenamiento | Estado | Riesgo |
|---------|----------------|--------|--------|
| `SUPABASE_URL` | xcconfig → Info.plist | ✅ .gitignore | Bajo |
| `SUPABASE_ANON_KEY` | xcconfig → Info.plist | ✅ .gitignore | Bajo* |
| Access Token JWT | Keychain | ✅ Seguro | Ninguno |
| Refresh Token | Keychain | ✅ Seguro | Ninguno |
| Email (biométrico) | Keychain accessible | ✅ Seguro | Ninguno |
| Password (biométrico) | Keychain + biometry | ✅ Muy Seguro | Ninguno |

*La SUPABASE_ANON_KEY es pública por diseño de Supabase — las políticas RLS son la capa de seguridad.

### 14.2 .gitignore Verificado

```gitignore
# ✅ Correctamente excluidos
pagosApp/Config/Secrets.xcconfig
*.p12
*.mobileprovision
DerivedData/
*.xcarchive
fastlane/report.xml
```

### 14.3 GitHub Actions Secrets (Para cuando se implemente CI/CD)

```
APPLE_ID               → App Store Connect login
APP_SPECIFIC_PASSWORD  → 2FA bypass para altool
TEAM_ID                → Apple Developer Team
MATCH_PASSWORD         → Fastlane Match encryption
SUPABASE_URL_PROD      → Producción URL
SUPABASE_ANON_KEY_PROD → Producción Key
```

---

## 📄 15. ENTREGABLE — RESUMEN DE HALLAZGOS

### Fortalezas Clave

| # | Fortaleza | Impacto |
|---|-----------|---------|
| 1 | Clean Architecture al 100% — dependencias correctamente dirigidas | Muy Alto |
| 2 | Swift 6 strict concurrency compliance — cero data races estáticos | Alto |
| 3 | Credenciales en Keychain con biometric access control | Alto |
| 4 | Offline-first con SwiftData + Supabase sync | Alto |
| 5 | EventBus type-safe elimina acoplamiento entre módulos | Medio |
| 6 | Cero `DispatchQueue` — 100% async/await moderno | Medio |
| 7 | Cero `print()` — todo vía `OSLog` estructurado | Medio |
| 8 | GenericNotificationScheduler + identificadores locales unificados | Medio |
| 9 | 3 idiomas con L10n type-safe: producto + notificaciones UN + pantallas debug | Medio |
| 10 | RLS en Supabase — aislamiento de datos por usuario | Alto |
| 11 | ADRs y runbooks en `docs/` (arquitectura, SSL, concurrencia) | Medio |
| 12 | GitHub Actions: build + SwiftLint | Medio |
| 13 | Lockout de login cliente + errores Auth vía `L10n` | Medio |

### Hallazgos Críticos a Resolver

| # | Hallazgo | Severidad | TD-ID |
|---|----------|-----------|-------|
| 1 | Cobertura de tests aún baja frente al tamaño del proyecto | 🔴 Alto | TD-01 |
| 2 | CI sin `xcodebuild test` en runner (solo build + lint) | 🔴 Alto | TD-02 |

### Roadmap de Correcciones

```
SEMANA 1-2: P0 (Estabilidad)
├── Ampliar tests (use cases core, mappers, sync)
├── Añadir job de tests en CI con simulador acordado por el equipo
└── Publicar resultados/cobertura en PR

SEMANA 3: P1 (Calidad / seguridad operativa)
├── Endurecer SwiftLint y retirar exclusiones innecesarias
└── Ejecutar checklist TSan/Instruments (docs/engineering)

SEMANA 4+: P2-P3 (Mejoras)
├── Feature flags
├── Account deletion via Supabase Edge Function
└── Cobertura de tests hacia 40-60% según prioridad de negocio
```

---

## ⚠️ LIMITACIONES DE LA AUDITORÍA

- La auditoría inicial fue **estática**; las revisiones posteriores contrastan con el **estado del repo** y documentación añadida (`docs/`), pero no sustituyen una revisión de seguridad de terceros.
- Conteos de **LOC**, archivos Swift y patrones `Task {` / `@MainActor` son **heurísticos** (archivos rastreados por git + grep / recorrido por líneas); pueden diferir ligeramente de métricas IDE o AST.
- No se evaluó comportamiento real de red (latencias, edge cases de Supabase SDK) en esta actualización.
- No se evaluó uso real de memoria en dispositivos físicos (Instruments) más allá del checklist propuesto en `docs/engineering/CONCURRENCY_VALIDATION.md`.
- El schema de Supabase solo fue analizado para los archivos `.sql` disponibles.
- Thread Sanitizer / Instruments: **pendiente de ejecución** por el equipo según el checklist citado.

---

*Technical Audit Report — auditoría inicial 11 de abril de 2026; actualización i18n (notificaciones locales + presentación y debug) 16 de abril de 2026; reconteo de alcance, complejidad y concurrencia 16 de abril de 2026*  
*Principal iOS Solutions Architect · Análisis estático + contrastación con estado del repositorio*
