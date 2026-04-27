# Testing

## Running tests

```bash
# In Xcode: ⌘U

# Or from the terminal (pick a simulator you have installed, e.g. iPhone 17)
xcodebuild test -scheme pagosApp -project pagosApp.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -configuration Debug
```

`pagosApp` and `pagosAppTests` must use the same **iOS deployment target** as the app (see Xcode target build settings), or `@testable import pagosApp` will fail to link.

## What is covered today

- **Validators**: email and password rules (`EmailValidator`, `PasswordValidator`).
- **Mappers and error mapping (Tier 1)**: `PaymentMapper`, `ReminderDomainMapper`, `PaymentErrorMessageMapper`, `AuthErrorMessageMapper`.
- **Smoke**: bundle identifier check in `pagosAppTests`.

Deeper use-case and repository tests (with mocks) are the next step; see [test-priority-inventory.md](test-priority-inventory.md) for a prioritized list.

## CI

Pull requests to `develop` run **build**, **unit tests** (`xcodebuild test` on the iOS Simulator), and **SwiftLint** — see [`.github/workflows/ci.yml`](../.github/workflows/ci.yml).

## Definition of Done (PRs)

| Change type | Expectation |
|-------------|------------|
| **Domain** (new/changed use case, entity rules, mappers) | Add or update **unit tests** in `pagosAppTests` for the new behavior. |
| **Data** (repositories, DTO mapping, non-trivial mapper changes) | Prefer **unit tests** on the mapper or repository with a fake / in-memory implementation when practical. |
| **UI only** (SwiftUI layout, copy) | Tests optional unless logic moved into testable helpers. |
| **Bug fix** in domain/data | **Regression test** if feasible in one hour of work. |

If a case is too heavy for the current timebox (e.g. full Supabase integration), add a short **note in the PR** and, when possible, a follow-up issue.

## Related docs

- [test-priority-inventory.md](test-priority-inventory.md) — what to test first for the best return on effort.

---
