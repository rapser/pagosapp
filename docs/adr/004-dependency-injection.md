# ADR 004: Inyección de dependencias

## Estado

Aceptado.

## Decisión

- Contenedor raíz **`AppDependencies`** compone contenedores por feature (`AuthDependencyContainer`, `PaymentDependencyContainer`, etc.).
- Cada feature expone factories `make*` para use cases y ViewModels.
- El cliente Supabase y el `ModelContainer` se construyen en el arranque de la app (bootstrap) y se inyectan hacia abajo.

## Consecuencias

- Tests y previews pueden sustituir implementaciones vía contenedores o inicializadores de ViewModel que acepten protocolos.
- Un crecimiento fuerte del equipo puede motivar trocear en paquetes SPM (ver ADR 005).
