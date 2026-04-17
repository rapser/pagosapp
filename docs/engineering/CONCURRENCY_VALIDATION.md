# Validación de concurrencia (manual)

## Objetivo

Complementar el cumplimiento estático de Swift 6 con evidencia en runtime (Thread Sanitizer, Instruments).

## Pasos recomendados (cada release mayor o trimestral)

1. **Thread Sanitizer (TSan)**  
   - Esquema Xcode: Edit Scheme → Run → Diagnostics → habilitar Thread Sanitizer.  
   - Flujos: login email/contraseña, login biométrico, lista de pagos (scroll), sync manual o al volver a foreground, crear/editar pago y recordatorio.

2. **Instruments — SwiftUI**  
   - Grabar 2–3 minutos de navegación por tabs; revisar tiempo en main thread y actualizaciones de vista excesivas.

3. **Instruments — Time Profiler**  
   - Durante sync con muchos registros; confirmar que la UI no bloquea en operaciones pesadas no previstas.

4. **Regresión de Tasks**  
   - Tras cambios en coordinadores o ViewModels con `Task { }`, repetir TSan en los mismos flujos.

## Entregable

- Anotar fecha, build y resultado (OK / issue + enlace a ticket) en el registro de release del equipo.
