# ADR 002: Política de merge en sincronización (download)

## Estado

Aceptado.

## Decisión

En la descarga remota de pagos y recordatorios se aplica **server-wins por defecto**: si existe una fila local con el mismo `id` que la remota, se sustituye por la versión remota **salvo** que el estado de sync local indique cambios pendientes de subir (lista explícita `keepLocalWhenPendingSyncStatuses` en los use cases de download).

## Referencia en código

- `DownloadRemoteChangesUseCase`
- `DownloadReminderChangesUseCase`

## Consecuencias

- Los conflictos de dos ediciones offline simultáneas no se resuelven con CRDT; se prioriza lo que ya llegó al servidor en el último download.
- Documentar en onboarding cualquier excepción futura por campo.
