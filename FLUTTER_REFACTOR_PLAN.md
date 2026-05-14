# Finora Flutter – Clean Architecture Refactor Plan
**Version:** 1.2  
**Last updated:** 2026-05-13

---

## Guiding Principles

- Incremental and always-green: one small, working change per phase.
- Only add layers where there is actual business logic to isolate.
- No new dependencies unless they solve a real problem.
- `lib/shared/widgets/` stays at root level — it is used across features, not owned by one.
- Reports and transactions are the highest-value features for domain logic.

---

## Current Structure (post-Phase 1)

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── providers/        # global providers (demo mode, hide amounts, notifications)
│   ├── services/
│   └── utils/
│
├── features/
│   ├── accounts/
│   │   ├── data/models/
│   │   └── presentation/{pages,providers,widgets}
│   ├── auth/
│   │   ├── data/{datasources,models}   ← renamed from services/
│   │   └── presentation/{pages,providers}
│   ├── budgets/
│   │   ├── data/models/
│   │   └── presentation/{pages,providers}
│   ├── dashboard/
│   │   └── presentation/pages/
│   ├── reports/
│   │   ├── data/models/                ← now empty (entities promoted)
│   │   ├── domain/
│   │   │   ├── entities/               ← report_period.dart, report_summary.dart
│   │   │   └── usecases/               ← build_report_summary_usecase.dart
│   │   └── presentation/{pages,providers,widgets}
│   ├── settings/
│   │   └── presentation/{pages,providers}
│   ├── subscriptions/
│   │   ├── data/models/
│   │   └── presentation/{pages,providers}
│   └── transactions/
│       ├── data/{datasources,models}   ← renamed from services/
│       └── presentation/{pages,providers}
│
├── shared/
│   └── widgets/
│
└── main.dart
```

---

## Phase Roadmap

| Phase | Focus | Status |
|-------|-------|--------|
| 1 | Reports domain extraction + `services/` → `datasources/` rename | ✅ Complete |
| 2 | Transactions domain layer (when client-side logic warrants it) | ⏳ Deferred |
| 3 | `data/repositories/` interfaces where they earn their keep | 🔲 Not started |
| 4 | Provider scattering cleanup | 🔲 Not started |

---

## Phase 1 – Complete ✅

**What was done:**

1. **Renamed `data/services/` → `data/datasources/`** in `auth/` and `transactions/`.  
   Updated imports in `auth_provider.dart`, `reimbursement_provider.dart`, `transactions_provider.dart`.

2. **Promoted pure business models to `domain/entities/`** in `reports/`.  
   `ReportPeriod`, `ReportCategory`, `MonthlyFlow`, and `ReportSummary` were all defined in `data/models/report_summary.dart` and `data/models/report_period.dart` (not separate files per entity). Both files moved to `domain/entities/`. Updated imports in all 5 widgets, the page, and the provider. `data/models/` is now empty.

3. **Created `domain/usecases/build_report_summary_usecase.dart`.**  
   Pure Dart class — zero Riverpod, zero Dio, zero Flutter widget dependencies. Takes `List<TransactionModel>` and `ReportPeriod`, returns a fully populated `ReportSummary`. Contains all aggregation logic: period filtering, transfer exclusion, category bucketing, monthly cash flow bars, savings rate, largest transaction identification.

4. **Slimmed `reportSummaryProvider` from 162 lines to 19 lines.**  
   Now reads transactions + period state, calls the use case, returns the result. No business logic remaining in the provider.

**Corrections to the original Phase 1 plan:**

- The plan referenced `data/models/report_category.dart` and `data/models/monthly_flow.dart` as separate files. They do not exist — `ReportCategory` and `MonthlyFlow` were defined inside `report_summary.dart` and moved together.
- The plan's provider example used `FutureProvider.autoDispose`. Not appropriate here — `reportSummaryProvider` is a synchronous derived `Provider<ReportSummary>` (it computes from already-loaded transaction state, not an async source). Changing it would add unnecessary loading states to a page that never had them.
- No `buildReportSummaryUseCaseProvider` Riverpod wrapper was needed. The use case is a stateless value object (`const BuildReportSummaryUseCase()`), so instantiating it inline is correct and simpler.

---

## Phase 2 – Transactions Domain Layer (Deferred) ⏳

**Trigger:** Add `domain/` to `transactions/` only when client-side business logic actually accumulates there.

**Current reality:** The two service files (`reimbursement_service.dart`, `split_transaction_service.dart`) are thin HTTP clients. Validation (over-reimbursement caps, split sum rules) lives on the server and is communicated via 422 responses. Creating `domain/entities/` now would produce near-duplicate models with no extractable logic.

**When to act:** If the app takes on client-side split validation, offline reimbursement queuing, or local matching rules, extract that logic into `domain/usecases/` at that point — following the same pattern established in Phase 1.

---

## Phase 3 – `data/repositories/` Interfaces (Not Started) 🔲

**When it makes sense:** Once a feature has both a remote datasource and local storage (e.g., caching transactions offline, storing report snapshots), a repository interface lets the domain layer stay ignorant of the storage mechanism.

**Currently:** No feature has this split yet. `reports/` derives everything from in-memory transaction state. Adding repository interfaces now would be an empty abstraction.

**When to act:** When `transactions/` or `accounts/` gets a local cache layer.

---

## Phase 4 – Provider Scattering Cleanup (Not Started) 🔲

Three places currently hold providers:

| Location | What lives there |
|----------|-----------------|
| `core/providers/` | `demoModeProvider`, `hideAmountsProvider`, `notificationPreferencesProvider` |
| `app/providers/` | `shellIndexProvider`, `sidebarProvider`, `themeProvider` |
| Feature `presentation/providers/` | Feature-specific state |

**Rule to enforce:** `core/providers/` = truly global cross-feature state. `app/providers/` = app shell / navigation state. Feature providers = everything else. No action needed until this causes a real discovery or dependency problem.

---

## What Stays Unchanged

- `lib/shared/widgets/` stays at root level (not moved inside `features/`).
- No `core/di/` folder — Riverpod is the DI mechanism.
- No `freezed` or `build_runner` added unless a specific problem justifies it.
- Simple features with no business logic (`dashboard/`, `settings/`, `budgets/`) do not get a `domain/` layer.
