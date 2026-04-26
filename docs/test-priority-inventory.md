# Test priority inventory (PagosApp)

This document lists areas where automated tests yield the most risk reduction, ordered roughly by **impact** and **feasibility** (pure logic first; integration last).

## Tier 1 — High value, low setup (mappers, pure domain)

| Area | Rationale | Examples |
|------|-----------|----------|
| Payment DTO ⟷ domain | Regressions affect sync, list UI, and remote merge | [`PaymentMapper`](../pagosApp/Features/Payments/Data/Mappers/PaymentMapper.swift) |
| Reminder DTO ⟷ domain | Same as above for the reminders feature | [`ReminderDomainMapper`](../pagosApp/Features/Reminders/Data/Mappers/ReminderDomainMapper.swift) |
| Error → string mapping | Wrong copy or missing cases break UX in forms and alerts | [`PaymentErrorMessageMapper`](../pagosApp/Features/Payments/Presentation/ErrorMapping/PaymentErrorMessageMapper.swift), [`AuthErrorMessageMapper`](../pagosApp/Auth/Presentation/ErrorMapping/AuthErrorMessageMapper.swift) |
| Validators | Already covered; extend for edge cases as needed | `EmailValidator`, `PasswordValidator` |

## Tier 2 — Use cases with mocked protocols

| Area | Rationale | Notes |
|------|-----------|--------|
| Create / update / delete payment | Core revenue path | Inject `PaymentRepositoryProtocol` mock |
| Sync orchestration | Subtle ordering and error handling | `SyncPaymentsUseCase`, `CoordinateSyncUseCase` with fakes |
| Reminder CRUD and sync | Parallel feature to payments | Same pattern as payments |

## Tier 3 — Integration / E2E (higher cost)

| Area | Rationale |
|------|-----------|
| SwiftData + repository | Catches schema/migration issues; use in-memory `ModelContainer` |
| Supabase (sandbox) | Optional; use only with test project and credentials |
| XCUITest | Login + one tab; run nightly or on release branches |

## Out of scope for first batches

- Full EventKit / UserNotifications in unit tests (use wrappers or UI tests)
- Screenshot / snapshot across OS versions (optional product QA)

This inventory should be revisited when a feature adds new domain rules or a second implementation of the same pattern (e.g. duplicate sync code).
