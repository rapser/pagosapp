# ADR 005: Roadmap de modularización (SPM)

## Estado

Propuesto / opcional.

## Contexto

Hoy todo el código vive en el target `pagosApp` con grupos por carpetas. Eso es adecuado para un equipo pequeño y una app nueva.

## Decisión (roadmap)

1. **Fase 0 (actual)**: módulos lógicos por carpeta + DI por contenedor.
2. **Fase 1**: extraer `Shared/` (L10n, utilidades red, componentes UI genéricos) a un paquete SPM `PagosCore` consumido por el target de la app.
3. **Fase 2**: paquetes por dominio vertical (`AuthKit`, `PaymentsKit`, `RemindersKit`) con dependencias unidireccionales Domain → Data.
4. **Fase 3**: previews y tests por paquete con esquemas Xcode dedicados.

## Consecuencias

- Coste inicial de configuración de paquetes y tiempos de CI; beneficio: límites de compilación claros y reutilización.
