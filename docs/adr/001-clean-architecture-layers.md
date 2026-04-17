# ADR 001: Capas Clean Architecture

## Estado

Aceptado (alineado con el código actual de pagosApp).

## Contexto

La app gestiona pagos, recordatorios, perfil y auth con datos locales (SwiftData) y remoto (Supabase).

## Decisión

- **Domain**: entidades, errores de dominio, validators, protocolos de repositorio y casos de uso sin dependencias de UI ni frameworks.
- **Data**: implementaciones de repositorios, DTOs, mappers, datasources (Supabase, SwiftData, Keychain).
- **Presentation**: SwiftUI, ViewModels (`@Observable`), coordinadores de sesión/sync que solo orquestan y delegan en use cases.

## Consecuencias

- Los tests unitarios deben poder ejecutarse contra Domain + mocks de repositorio sin UI.
- Nuevas features deben seguir el mismo sentido de dependencias (hacia dentro).
