# Contrato de coordinadores de sync (invariantes)

## PaymentSyncCoordinator

- `performSync()` es **reentrancia-segura**: si `isSyncing` es verdadero, la segunda llamada retorna de inmediato.
- **Throttle**: `shouldThrottleSyncTrigger()` evita disparar sync más de una vez por `minimumSyncTriggerInterval`.
- **Reintentos**: hasta `maxRetryAttempts` con backoff exponencial + jitter para errores recuperables; no reintenta `notAuthenticated`, `sessionExpired`, `conflictError`.
- Tras éxito: actualiza `lastSyncDate`, limpia `syncError`, actualiza contador pendiente y publica `PaymentsSyncedEvent`.

## ReminderSyncCoordinator

- Misma idea de `isSyncing`, throttle y reintentos con política análoga de `shouldRetry`.
- Tras sync exitoso: reprograma notificaciones locales de recordatorios vía `rescheduleAllReminderNotifications()`.

## Download (merge)

- Ver ADR 002 y comentarios en `DownloadRemoteChangesUseCase` / `DownloadReminderChangesUseCase`: server-wins salvo estados locales pendientes de subida.
