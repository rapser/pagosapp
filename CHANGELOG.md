# Changelog

El contenido de este fichero describe la **versión publicada** y el **alcance** de PagosApp (qué ofrece el producto y con qué stack se construye). El formato se inspira en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/).

---

## [Unreleased]

### Added

- **Tarjetas de crédito (nuevo tab)**: registro de tarjetas (banco, número, PIN, vencimiento — nunca CVV) en un grid de 2 columnas que muestra solo marca, últimos 4 dígitos y banco. El número completo y el PIN están protegidos con Face ID/Touch ID y se guardan solo en Keychain (`.biometryCurrentSet`); la metadata no sensible vive en SwiftData. Totalmente local, sin sincronización remota.
- **Editar y eliminar tarjetas**: el menú contextual de una tarjeta ahora permite "Editar" (pide Face ID para revelar y precargar el número/PIN actuales en el formulario) y "Eliminar" (a la confirmación por alert existente se suma una segunda confirmación con Face ID/Touch ID antes de borrar).
- **Celda de tarjeta**: se muestra la fecha de vencimiento (`MM/YY`) junto al banco, y los bancos reconocibles (BCP, BBVA, Interbank, Scotiabank, Falabella, Ripley) usan su color de marca real en vez del gradiente genérico por marca de tarjeta.
- **Auto-ocultado del PIN revelado**: el bottom sheet de ver tarjeta ahora muestra el número y PIN completos de inmediato (ya no hace falta un ojito, el Face ID de entrada ya es el gate) y se cierra solo a los 3 minutos, con un banner inferior que muestra la cuenta regresiva.
- **Ajustes → Sincronización agrupada**: la sección de sync (pendientes, última sincronización, sincronizar ahora, reintentar, reparar BD) se movió a su propia subpantalla; en Ajustes queda una sola fila con un badge del número de pendientes.
- **Edición de TC bimoneda**: al editar un pago de tarjeta de crédito registrado con una sola moneda (solo soles o solo dólares), ahora se muestra la sección `DualCurrencyAmountSection` con ambos campos. Si el usuario ingresa un monto en la moneda faltante y guarda, el sistema crea automáticamente el registro hermano y vincula ambos pagos con un `groupId` compartido — sin necesidad de crear un segundo pago manualmente.
- **Hint contextual en edición TC**: el texto de ayuda bajo los campos de monto cambia dinámicamente según la moneda que está vacía ("Puedes agregar un monto en dólares" / "...en soles") cuando se edita un pago TC con una sola moneda registrada.
- **Entrada de montos estilo banca** (`CurrencyTextField`): los campos de monto en pagos de TC (soles y dólares) y en pagos de moneda única usan una entrada shift-derecha similar a apps bancarias — se escribe solo dígitos y el punto decimal se posiciona automáticamente: `5` → `0.05`, `50` → `0.50`, `500` → `5.00`. El campo muestra `0.00` en gris mientras está vacío y cambia al color normal al escribir el primer dígito.
- **Confirmación antes de eliminar**: el swipe-to-delete muestra un alert de confirmación antes de borrar ("¿Eliminar este pago?" / "Se borrarán los montos en S/ y $."), evitando eliminaciones accidentales. Localizado en español, inglés y portugués.
- **Observación compartida de eventos de pagos**: se añadió `PaymentChangeObserver` como helper interno para centralizar la reacción a `PaymentCreatedEvent`, `PaymentUpdatedEvent`, `PaymentDeletedEvent` y `PaymentStatusToggledEvent` sin cambiar la API pública de `EventBus`.
- **Base compartida para sync coordinators**: se añadió `BaseSyncCoordinator` con patrón `Template Method` para encapsular `isSyncing`, `lastSyncDate`, `pendingSyncCount`, persistencia del último sync, retries y limpieza de estado.

### Fixed

- **El formulario de tarjeta perdía cambios sin avisar**: el sheet de crear/editar tarjeta se cerraba aunque el guardado fallara (p. ej. error de Keychain), sin mostrar ningún error. Ahora solo se cierra si el guardado fue exitoso.
- **Face ID pedía autenticación 3 veces al ver el PIN de una tarjeta**: la lectura del número y del PIN en Keychain evaluaban biometría cada una por su cuenta, sumadas al gate explícito de la app. Ahora se reutiliza el mismo `LAContext` ya autenticado para ambas lecturas — queda en una sola solicitud de Face ID/Touch ID.
- **Eliminación sincronizada con Supabase**: `DeletePaymentUseCase` ahora comprueba el `syncStatus` antes de borrar. Si el pago es `.synced` o `.modified` elimina primero de Supabase y luego de SwiftData; si es `.local` solo limpia el almacenamiento local. Si Supabase no está disponible el borrado local procede igualmente (offline-first).
- **groupId no se persistía al actualizar un pago**: `PaymentSwiftDataDataSource.save()` y `saveAll()` no incluían `groupId` en los campos actualizables. Al agregar la segunda moneda a un pago TC single-currency, el pago original nunca recibía el nuevo `groupId` en disco, lo que hacía que ambos aparecieran como entradas separadas en la lista.
- **TestFlight / GitHub Actions**: el workflow ya no empaqueta placeholders de Supabase como si fueran una URL válida; `AppConfiguration` exige `https`, host y clave configurables, y el cliente demo solo se usa cuando la configuración real no es válida. El workflow `testflight-develop.yml` genera `pagosApp/Config/Secrets.xcconfig` desde los secretos del repositorio `SUPABASE_URL` y `SUPABASE_ANON_KEY` (con escape `://` → `:/$()/` para `.xcconfig`).
- **Login**: `LoginView` usa `@Environment(AppDependencies.self)` como el resto de la app, alineado con la inyección del bootstrap.

### Changed

- **Calendario fuera del tab bar**: reemplazado por el nuevo tab Tarjetas; ahora se accede desde un botón en la barra de Inicio y desde una fila en Ajustes → General.
- **Ajustes reorganizado**: Seguridad, Legal, Acerca de y Datos se agruparon bajo una fila "General" para descongestionar la lista principal.
- **Recordatorios**: se quitó la opción de aviso "1 mes antes"; quedan alertas de 1 y 2 semanas, desactivadas por defecto en todos los tipos (las notificaciones estándar de 3/2/1/0 días no cambian).
- **Refactor clean de ViewModels**: `PaymentsListViewModel`, `PaymentHistoryViewModel` y `SettingsViewModel` eliminaron sus suscripciones repetidas al `EventBus` y ahora comparten una sola entrada reusable para refrescos disparados por eventos de pagos.
- **Refactor clean de coordinación de sync**: `PaymentSyncCoordinator` y `ReminderSyncCoordinator` quedaron como especializaciones sobre una base interna común. Se mantiene el comportamiento observable existente: pagos sigue publicando `PaymentsSyncedEvent` y recordatorios sigue reprogramando notificaciones tras sync exitoso.
- **Rendimiento en estadísticas**: `StatisticsViewModel` ahora usa `async let` para cargar categorías, meses, totales y disponibilidad de moneda en paralelo cuando las operaciones son independientes, manteniendo el mismo contrato observable y el mismo resultado funcional.

### Tests

- Nuevos casos en `DeletePaymentUseCaseTests`: `syncedPayment_deletesFromSupabaseAndLocal`, `modifiedPayment_deletesFromSupabaseAndLocal`, `localPayment_deletesOnlyFromLocal`, `supabaseFailure_stillDeletesLocally`. `MockPaymentRepository` expone `remoteDeletedIds` y `shouldThrowOnRemoteDelete`.
- Nuevas suites y dobles para cubrir el refactor de arquitectura: `PaymentHistoryViewModelTests`, `SettingsViewModelTests`, `StatisticsViewModelTests` y `SyncCoordinatorTests`. `SpyEventBus` pasó a ser un bus asíncrono en memoria capaz de verificar refrescos disparados por eventos reales.
- `PaymentViewModelTests` añade cobertura de refresco silencioso por evento en `PaymentsListViewModel`.
- La suite de pruebas queda en **156 tests** y la regresión completa (`xcodebuild test -project pagosApp.xcodeproj -scheme pagosApp -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.2'`) pasa en esta rama.

**Cobertura ampliada — rama `feature/use-case-coverage` (~140 tests total, +32 nuevos):**

- **Nuevos mocks de plataforma** (`PlatformMocks.swift`): `MockCalendarEventDataSource` (trackea `addedEvents`, `updatedEvents`, `removedEventIds`) y `MockNotificationDataSource` (trackea `scheduledPaymentIds`, `scheduledReminderIds`, `cancelledPaymentIds`). `MockPaymentSyncRepository` añade `remotePaymentsToReturn` y `shouldThrowOnDownload`. `PaymentUI.make(...)` factory extension para tests de ViewModel.

- **Gaps de use cases cubiertos**:
  - `GetAllPaymentsUseCaseTests` (3 tests): repo vacío, múltiples pagos.
  - `GetPaymentUseCaseTests` (3 tests): encontrado, no encontrado, repo vacío.
  - `DownloadRemoteChangesUseCaseTests` (8 tests): nuevo remoto guardado, synced actualizado desde remoto, `.local` / `.modified` / `.error` preservados (server-wins con protección de pendientes), auth failure, download failure, múltiples remotos.
  - `DeleteReminderUseCaseTests` (3 tests), `GetAllRemindersUseCaseTests` (2 tests), `GetPendingReminderSyncCountUseCaseTests` (3 tests).

- **Orquestadores de sync** (`SyncUseCaseTests.swift`):
  - `SyncPaymentsUseCaseTests` (5 tests): ambos succeed, upload falla sin ejecutar download, download falla, sin pendientes aún descarga, upload + download en secuencia.
  - `SyncRemindersUseCaseTests` (4 tests): success, upload falla sin ejecutar download, descarga remoto, reminder `.modified` no sobreescrito tras sync.

- **Primera cobertura de capa de ViewModel** (`ViewModels/`):
  - `PaymentsListViewModelTests` (6 tests): carga lista, repo vacío, delete optimista, revert en fallo con error, toggle isPaid en repo y en UI.
  - `AddPaymentViewModelTests` (8 tests): validaciones (nombre vacío, TC sin monto, TC solo PEN), save single, save dual genera groupId compartido en ambos pagos, clearForm tras éxito, error de repo.
  - `EditPaymentViewModelTests` (8 tests): TC single vs grouped (isDualCurrency / isGrouped), detección de cambios por nombre, detección al agregar segunda moneda, sin cambios hasChanges=false, resetChanges restaura valores, save single llama update, upgrade a grouped crea dos pagos con groupId compartido.
  - `RemindersListViewModelTests` (5 tests): carga lista, repo vacío, deleteReminder, toggleCompletion a true y a false.

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
