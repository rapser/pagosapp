# Runbook: rotación de certificados (SSL pinning)

## Alcance

La app puede usar un `URLSession` delegado con pinning de certificado público (`.cer` en el bundle) para tráfico REST del cliente Supabase cuando hay certificados empaquetados. Ver `SSLPinningURLSessionDelegate` y `SupabaseClientFactory`.

## Cadencia sugerida

- Revisar caducidad de los certificados empaquetados **al menos 30 días antes** de la fecha `notAfter` del certificado activo.
- Mantener en el repositorio al menos **dos** versiones de `.cer` durante la rotación si el servidor sirve cadena intermedia que cambia.

## Responsables

- Definir rol **owner** (ej. lead iOS + DevOps) y suplente.
- Registrar cada rotación en el changelog de release.

## Procedimiento

1. Obtener el nuevo certificado público (PEM/DER) del endpoint de producción (mismo host que `SUPABASE_URL`).
2. Convertir a `.cer` si hace falta; añadir al target de Xcode y validar build local.
3. Subir PR con el nuevo `.cer`; probar login + sync en **staging** con build de TestFlight.
4. Publicar release a producción; monitorizar errores de TLS / pinning en logs (OSLog categoría SupabaseFactory / red).
5. Tras una ventana de soporte (ej. 2 releases), retirar el `.cer` antiguo del bundle si ya no es necesario para compatibilidad.

## Rollback

- Revertir el commit que añade el `.cer` defectuoso y publicar hotfix, **o**
- Distribuir build anterior vía TestFlight/App Store expedited si el pinning bloquea a todos los usuarios.

## Limitaciones

- El pinning actual aplica al `URLSession` configurado para el SDK; canales adicionales (p. ej. Realtime vía WebSocket) pueden requerir estrategia distinta: documentar en la matriz de cobertura.
