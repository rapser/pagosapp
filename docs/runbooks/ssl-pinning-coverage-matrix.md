# Matriz de cobertura: pinning TLS

| Canal | Biblioteca / capa | Pinning actual | Notas |
|-------|---------------------|----------------|--------|
| REST Supabase (auth, postgrest) | `supabase-swift` + `URLSession` custom en `SupabaseClientFactory` | Sí, si hay `.cer` en bundle | Sin certs: sesión sin delegate de pinning |
| Realtime / WebSocket | Depende del SDK y configuración interna | No verificado en este documento | Revisar release notes de `supabase-swift`; puede requerir API adicional o aceptar riesgo residual |
| Otras URLs (App Store, Safari) | N/A | N/A | Fuera del alcance de la app |

**Acción**: cuando el SDK exponga hook estable para WebSocket, repetir evaluación y actualizar esta tabla.
