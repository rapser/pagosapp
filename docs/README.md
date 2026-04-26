# Documentación del proyecto

Índice de la documentación detallada de **PagosApp**. El [README principal](../README.md) en la raíz resume el proyecto y enlaza aquí.

| Documento | Contenido |
|-----------|-----------|
| [Visión y funcionalidades](product-overview.md) | Descripción del producto y listado de features |
| [Arquitectura](architecture.md) | Clean Architecture, capas, DI, offline-first, EventBus, concurrencia |
| [Stack tecnológico](tech-stack.md) | Swift, SwiftUI, Supabase, CI, Fastlane, herramientas |
| [Requisitos e instalación](setup.md) | Requisitos, Supabase, Xcode, SwiftLint, Fastlane |
| [Estructura del repositorio](project-structure.md) | Árbol de carpetas `pagosApp/` y raíz |
| [Testing](testing.md) | Cómo ejecutar tests, CI, Definition of Done en PRs |
| [Inventario de prioridad de tests](test-priority-inventory.md) | Qué cubrir primero (riesgo vs esfuerzo) |
| [Build autogenerado (Xcode + Fastlane)](build-number-xcode-fastlane.md) | `CFBundleVersion` `YYYYMM.DD.HHmm`, fase Plist, `SKIP_XCODE_STAMP` |
| [Recursos adicionales](additional-resources.md) | Changelog, ADRs, SQL, Config |
| [Seguridad, contribución y metadatos](security-contributing-meta.md) | Seguridad, flujo de contribución, enlace a versión/changelog, licencia, autor |

Las carpetas `docs/adr/`, `docs/engineering/` y `docs/runbooks/` son enlaces lógicos para material de arquitectura y operación; créalas o restáuralas en el repo si aplica.
