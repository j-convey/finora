# finora

Personal finance management app built with Flutter. Track accounts, transactions, budgets, subscriptions, and net worth across multiple financial institutions via SimpleFIN integration.

**Status:** Currently in beta. Will be available on iOS, Android, Web, macOS, Windows, and Linux.

## Features

- **Multi-account tracking** — Connect and sync accounts from any SimpleFIN-compatible institution
- **Transaction management** — Categorize, split, and annotate transactions
- **Budgets** — Set spending limits per category with real-time tracking
- **Subscriptions** — Monitor recurring charges and predict annual spend
- **Net worth** — Track assets and liabilities over time
- **Reimbursement engine** — Link income transactions to expenses to record paybacks (full or partial)
- **Dashboard** — Overview of spending, income, and net worth
- **Demo mode** — Test all features with sample CSV data without a backend

## Tech Stack

- **Frontend:** Flutter (Dart) with Riverpod for state management
- **API Client:** Dio with auto-refresh JWT tokens
- **Demo Mode:** In-memory CSV interceptor for offline testing
- **Architecture:** Clean separation of data layer (services), state layer (providers), and UI layer

## Prerequisites

- Flutter 3.0 or later
- Dart 3.0 or later
- A backend instance running the Finora API (or use demo mode)

For backend setup instructions, see [finora-server](https://github.com/j-convey/finora-server).

## Getting Started

### 1. Clone and Install Dependencies

```bash
git clone https://github.com/your-org/finora.git
cd finora
flutter pub get
```

### 2. Configure Backend URL

Edit `lib/features/auth/presentation/providers/auth_provider.dart` and set your backend server URL:

```dart
const String defaultServerUrl = 'http://localhost:8000'; // or your production URL
```

### 3. Run in Demo Mode (No Backend Required)

Demo mode loads CSV sample data from `assets/demo/` and intercepts all API calls:

```bash
flutter run --dart-define=DEMO_MODE=true
```

This enables you to:
- View sample transactions, accounts, budgets, subscriptions
- Test all UI flows (create, edit, split, link reimbursements)
- No persistence across requests (by design)

To modify demo data, edit the CSV files in `assets/demo/` and rebuild.

### 4. Run Against a Real Backend

```bash
flutter run
```

The app will attempt to connect to the configured backend URL. Log in with your credentials.

For backend setup and deployment, see [finora-server](https://github.com/j-convey/finora-server).

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app/                         # App-wide configuration
├── core/                        # Shared services
│   ├── network/
│   │   ├── api_client.dart     # Dio + JWT interceptor
│   │   └── demo_interceptor.dart
│   ├── providers/              # App-level providers
│   ├── services/               # Shared services
│   └── utils/                  # Formatters, helpers
├── features/                    # Feature modules
│   ├── accounts/
│   ├── auth/
│   ├── budgets/
│   ├── dashboard/
│   ├── reports/
│   ├── settings/
│   ├── subscriptions/
│   └── transactions/            # Includes reimbursement engine
├── shared/                      # Shared UI widgets
│   └── widgets/
│       ├── reimbursement_sheet.dart
│       ├── split_transaction_sheet.dart
│       ├── transaction_card.dart
│       └── ...

assets/demo/
├── accounts.csv
├── transactions.csv
├── budgets.csv
├── subscriptions.csv
├── net_worth_history.csv
└── categories.csv
```

## Core Features

### Transaction Management

- View all transactions grouped by date
- Categorize and add notes
- Split a transaction into multiple line items
- Link reimbursements (income ↔ expense)

### Reimbursement Engine

Link an income transaction to an expense to record that the expense was paid back (full or partial). Example: colleague paid you back for a shared meal.

See [REIMBURSEMENT_ENGINE.md](REIMBURSEMENT_ENGINE.md) for detailed API and flow documentation.

### Split Transactions

Break down a large transaction (e.g., a $100 grocery run) into individual items with per-item categories.

### Budgets

Set category-based spending limits. The dashboard shows current spending vs. budget and warns when you're over.

### Subscriptions

Track recurring charges. The app matches new transactions to subscriptions and alerts you to changes in amount or timing.

## Demo CSV Format

### transactions.csv

```
id,title,amount,type,category,date,account_id
demo-txn-001,Paycheck Deposit,5200.00,income,Paychecks,2026-03-01,demo-acc-1
demo-txn-002,Whole Foods Market,145.32,expense,Groceries,2026-03-02,demo-acc-3
demo-txn-003,Starbucks,5.45,expense,Coffee Shops,2026-03-02,demo-acc-3
```

**Columns:**
- `id` — Unique identifier
- `title` — Display name
- `amount` — Positive decimal (direction determined by `type`)
- `type` — `income`, `expense`, or `transfer`
- `category` — Spending category
- `date` — ISO 8601 date
- `account_id` — Foreign key to accounts.csv

### Other CSVs

- `accounts.csv` — Account name, institution, balance (as of last sync)
- `budgets.csv` — Category, allocated amount, color
- `subscriptions.csv` — Name, merchant, category, amount, recurrence
- `net_worth_history.csv` — Date, total assets, total liabilities
- `categories.csv` — Available spending categories

## Running Tests

(Unit and widget tests coming soon)

## Troubleshooting

### "Failed to load reimbursements"

If you see this error when opening the reimbursements sheet, ensure the backend endpoint `/api/transactions/{id}/reimbursements` is implemented and returning the correct response shape.

In demo mode, this is auto-handled. If using a real backend, verify:
1. Backend is running and accessible
2. Access token is valid (check `Bearer <token>` header)
3. Response includes `transaction_amount`, `allocated_amount`, `remaining_amount`, `reimbursements[]`

### "SimpleFIN status: not connected"

SimpleFIN integration is optional. You can manage transactions manually or skip it entirely. If you want to auto-sync accounts, configure SimpleFIN credentials in Settings.

### Demo mode doesn't persist data

This is intentional. Demo mode loads CSV data and intercepts API calls but doesn't persist state across requests. To test persistence, use a real backend.

## Backend API Reference

For complete backend implementation details and setup instructions, see [finora-server](https://github.com/j-convey/finora-server).

The app expects a REST API with the following endpoints (JWT Bearer token required):

- `GET /api/accounts` — List accounts
- `GET /api/transactions` — List transactions
- `POST /api/transactions/reimbursements` — Create reimbursement link
- `GET /api/transactions/{id}/reimbursements` — List reimbursements for a transaction
- `PUT /api/transactions/reimbursements/{id}` — Update reimbursement
- `DELETE /api/transactions/reimbursements/{id}` — Delete reimbursement
- `GET /api/budgets` — List budgets
- `GET /api/subscriptions` — List subscriptions
- `GET /api/categories` — List spending categories
- `POST /api/auth/login` — Login
- `POST /api/auth/refresh` — Refresh access token

See [REIMBURSEMENT_ENGINE.md](REIMBURSEMENT_ENGINE.md) for detailed reimbursement endpoint documentation.

## Development

### Adding a New Feature

1. Create a new folder under `lib/features/{feature_name}/`
2. Organize into `data/` (models, services) and `presentation/` (pages, providers)
3. Use Riverpod `AsyncNotifierProvider` for state management
4. Follow the existing SRP (Single Responsibility Principle) patterns

### Debugging

- Enable debug output: Set breakpoints in VS Code or Android Studio
- Check network requests: Flutter DevTools → Network tab (with a real backend)
- View provider state: Riverpod DevTools extension

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE) file for details.

## Questions?

Refer to the [Flutter documentation](https://docs.flutter.dev/) or check existing features for examples.
