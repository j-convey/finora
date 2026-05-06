# Backend Requirements for Reports Feature

## Overview
The Reports page displays financial insights based on transaction data. The page aggregates transactions into categories and shows spending/income trends, cash flow analysis, and transaction summaries.

**Frontend Implementation:** The frontend handles all report aggregation and calculations on the client side using the transactions data from the backend. No new backend endpoints are required, but existing transaction data must meet specific requirements.

## Required Backend Endpoints

### GET /api/transactions (EXISTING - Must Support)
Provides all transactions for the user, which are then aggregated into reports.

**Request Parameters:**
```
Query Parameters (Optional):
  - limit: integer (optional, default: 1000)
    Number of transactions to return
  - offset: integer (optional, default: 0)
    Pagination offset
  - start_date: ISO 8601 date (optional)
    Filter transactions from this date onwards
  - end_date: ISO 8601 date (optional)
    Filter transactions up to this date
  - type: string (optional)
    Values: "income", "expense", "transfer"
```

**Response Format:**
```json
[
  {
    "id": "string",
    "title": "string",
    "amount": number,
    "type": "income|expense|transfer",
    "category": "string",
    "date": "ISO 8601 date",
    "account_id": "string (optional)",
    "notes": "string (optional)",
    "original_description": "string (optional)",
    "merchant_name": "string (optional)",
    "provider_transaction_id": "string (optional)",
    "pending": boolean,
    "created_at": "ISO 8601 timestamp (optional)",
    "updated_at": "ISO 8601 timestamp (optional)"
  }
]
```

**Required Response Properties:**
- `id` (string, UUID): Unique transaction identifier
- `title` (string): Human-readable transaction title
- `amount` (number): Transaction amount in the base currency (e.g., USD)
- `type` (string): One of "income", "expense", or "transfer"
- `category` (string): Spending/income category (see Categories section below)
- `date` (ISO 8601 date): Transaction date
- `pending` (boolean): Whether transaction is pending settlement

**Optional but Recommended:**
- `account_id`: Link transaction to an account
- `merchant_name`: Original merchant name from provider
- `original_description`: Original transaction description from provider
- `notes`: User-provided notes on the transaction
- `created_at`, `updated_at`: Timestamps for audit trails

## Transaction Categories

The reports feature requires transactions to be properly categorized. The following categories are supported by the frontend:

### Expense Categories (Spending Tab)
```
Mortgage
Home Improvement
Insurance
Phone
Internet & Cable
Pets
Gas & Electric
Electronics
Garbage
Loan Repayment
Groceries
Entertainment
Dining
Utilities
Shopping
Travel
Health
Rent
Subscriptions
(and any other custom categories)
```

### Income Categories (Income Tab)
```
Salary
Bonus
Freelance
Investment Income
Rental Income
Refunds
Other Income
```

### Special Categories
```
Transfer (for internal transfers between accounts)
```

**Categorization Requirements:**
1. Each transaction MUST have a category assigned
2. Categories should be consistent (e.g., "Groceries", not "groceries" or "GROCERIES")
3. If auto-categorization is used, maintain a mapping of merchant names to categories
4. Users should be able to recategorize transactions (handled on frontend, but backend must persist)

## Database Requirements

### Transactions Table Schema
Ensure your transactions table includes:

```sql
CREATE TABLE transactions (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  title VARCHAR(255) NOT NULL,
  amount NUMERIC(15, 2) NOT NULL,
  type VARCHAR(20) NOT NULL CHECK (type IN ('income', 'expense', 'transfer')),
  category VARCHAR(100) NOT NULL,
  date DATE NOT NULL,
  pending BOOLEAN DEFAULT false,
  merchant_name VARCHAR(255),
  original_description TEXT,
  provider_transaction_id VARCHAR(255) UNIQUE,
  notes TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, provider_transaction_id) -- Prevents duplicate imports
);

-- Essential Indexes for Report Performance
CREATE INDEX idx_user_date ON transactions(user_id, date DESC);
CREATE INDEX idx_user_category ON transactions(user_id, category);
CREATE INDEX idx_user_type ON transactions(user_id, type);
CREATE INDEX idx_user_type_date ON transactions(user_id, type, date DESC);
CREATE INDEX idx_user_pending ON transactions(user_id, pending);
```

### Field Descriptions
- `id`: Unique transaction identifier
- `user_id`: Foreign key to users table (for multi-tenancy)
- `account_id`: Link to accounts table (optional)
- `title`: Display name for the transaction
- `amount`: Transaction amount (always positive, type indicates direction)
- `type`: Transaction classification (income, expense, or transfer)
- `category`: Category bucket for aggregation in reports
- `date`: Date of transaction (for date-based filtering and report grouping)
- `pending`: Boolean flag for uncleared/pending transactions
- `merchant_name`: Original merchant from data provider
- `original_description`: Original description from provider
- `provider_transaction_id`: External ID for deduplication
- `notes`: User-provided notes
- `created_at`, `updated_at`: Audit timestamps

## Data Consistency Requirements

### Amount Handling
- **All amounts should be stored as positive numbers**
- **Transaction type determines sign:** Expense amounts represent outflows, income amounts represent inflows
- **For reporting:** `netCashFlow = totalIncome - totalExpenses`

### Category Consistency
- All transactions must have a category
- Categories should be consistent across the system
- Support for custom user-defined categories
- Category names should be title-cased for consistency

### Date Handling
- Store transaction dates in UTC
- Date filtering in reports should use: `start_date <= transaction_date <= end_date`
- Include both income and expense transactions when calculating monthly flow

### Pending Transactions
- Transactions with `pending = true` are excluded from report calculations
- Only settled (`pending = false`) transactions are aggregated
- Use case: Credit card charges that haven't cleared yet

## Performance Optimization

### Query Optimization
For efficient report generation, optimize these queries:

```sql
-- Monthly aggregation (for Cash Flow tab)
SELECT 
  DATE_TRUNC('month', date) as month,
  SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
  SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expenses
FROM transactions
WHERE user_id = $1 AND date >= $2 AND NOT pending
GROUP BY DATE_TRUNC('month', date)
ORDER BY month DESC;

-- Category breakdown (for Spending/Income tabs)
SELECT 
  category,
  SUM(amount) as total,
  COUNT(*) as count
FROM transactions
WHERE user_id = $1 
  AND type = $2 
  AND date >= $3 
  AND NOT pending
GROUP BY category
ORDER BY total DESC;

-- Recent transactions (for transaction lists)
SELECT * FROM transactions
WHERE user_id = $1 
  AND type = $2 
  AND NOT pending
ORDER BY date DESC
LIMIT 5;
```

### Indexes
Essential indexes for performance (see schema above):
- `idx_user_date`: For date-range filtering
- `idx_user_category`: For category aggregation
- `idx_user_type`: For income vs expense filtering
- `idx_user_type_date`: Combined for fastest filtering
- `idx_user_pending`: For excluding pending transactions

## Data Validation

### Backend Validation Rules
1. **Amount:** Must be positive (> 0)
2. **Type:** Must be one of: "income", "expense", "transfer"
3. **Category:** Must not be empty
4. **Date:** Must not be in the future (unless explicitly allowed for scheduled transactions)
5. **User ID:** Must match authenticated user
6. **Pending:** Must be boolean

### Error Responses
```json
{
  "error": "Invalid transaction data",
  "details": {
    "amount": "Amount must be greater than 0",
    "category": "Category is required"
  }
}
```

## Reports Calculations

### Frontend Calculations (client-side aggregation)
The frontend performs these calculations:

1. **Total Income:** Sum of all transactions where `type = 'income'` and `pending = false`
2. **Total Expenses:** Sum of all transactions where `type = 'expense'` and `pending = false`
3. **Net Cash Flow:** `totalIncome - totalExpenses`
4. **Savings Rate:** `netCashFlow / totalIncome` (when `totalIncome > 0`)
5. **Spending by Category:** Group expenses by category, calculate percentages
6. **Income by Category:** Group income by category, calculate percentages
7. **Monthly Flow:** Group by month, calculate income and expenses per month

### Example Calculation (Frontend)
```
Period: Dec 1, 2024 - Dec 31, 2024
Filtered transactions: All transactions with date in range and pending = false

Spending Categories:
- Mortgage: $1,385.00 (39.3%)
- Loan Repayment: $500.23 (14.2%)
- Home Improvement: $208.00 (5.9%)
- Insurance: $201.45 (5.7%)
- Phone: $140.00 (4.0%)
- Internet & Cable: $115.00 (3.3%)
- Gas & Electric: $108.00 (3.1%)
- Electronics: $100.00 (2.8%)
- Groceries: $110.00 (3.1%)
- Everything else: $190.22 (5.4%)

Total Expenses: $3,528.37
Total Income: ~$5,000 (example)
Net Cash Flow: ~$1,471.63
```

## Testing Checklist

### Data Tests
- [ ] Transactions table has required fields
- [ ] All transactions have a category
- [ ] Amount field is numeric and positive
- [ ] Type field is validated to be income/expense/transfer
- [ ] Pending flag is boolean and defaults to false
- [ ] Date filtering works correctly

### API Tests
- [ ] GET /api/transactions returns valid JSON
- [ ] All required fields are present in response
- [ ] Date range filtering works (start_date, end_date)
- [ ] Type filtering works (income, expense, transfer)
- [ ] Limit and offset pagination works
- [ ] Unauthenticated requests return 401
- [ ] Users only see their own transactions

### Performance Tests
- [ ] /api/transactions response time < 500ms
- [ ] Category aggregation completes in frontend < 100ms
- [ ] Monthly flow calculation completes in frontend < 100ms
- [ ] Can handle 10,000+ transactions

### Data Consistency Tests
- [ ] Sum of expenses matches displayed total
- [ ] Sum of income matches displayed total
- [ ] Monthly totals sum to period totals
- [ ] No transactions counted twice
- [ ] Pending transactions excluded from calculations
- [ ] Category names are consistent

## Example Transaction Data

### Sample Expense Transaction
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "account_id": "550e8400-e29b-41d4-a716-446655440002",
  "title": "Mortgage Payment",
  "amount": 1385.00,
  "type": "expense",
  "category": "Mortgage",
  "date": "2024-12-06",
  "pending": false,
  "merchant_name": "Chase Bank",
  "notes": "Monthly mortgage payment",
  "created_at": "2024-12-06T15:30:00Z",
  "updated_at": "2024-12-06T15:30:00Z"
}
```

### Sample Income Transaction
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440003",
  "user_id": "550e8400-e29b-41d4-a716-446655440001",
  "account_id": "550e8400-e29b-41d4-a716-446655440002",
  "title": "Salary Deposit",
  "amount": 5000.00,
  "type": "income",
  "category": "Salary",
  "date": "2024-12-01",
  "pending": false,
  "merchant_name": "Employer Inc",
  "notes": "Monthly salary",
  "created_at": "2024-12-01T08:00:00Z",
  "updated_at": "2024-12-01T08:00:00Z"
}
```

## Migration Plan

**Phase 1: Ensure Data Quality**
- Add missing indexes to transactions table
- Migrate any transactions without categories
- Validate all transaction types

**Phase 2: API Compliance**
- Ensure /api/transactions endpoint returns all required fields
- Implement date range filtering
- Implement type filtering

**Phase 3: Testing**
- Run all data consistency tests
- Performance testing with realistic data volumes
- User acceptance testing

## Future Enhancements

1. **Aggregated Report Endpoints** - Backend could provide pre-aggregated data:
   - `GET /api/reports/summary?start_date=X&end_date=Y&period=month`
   - Reduces client-side processing for large datasets
   - Improves performance for users with 50,000+ transactions

2. **Budget Comparison** - Compare actual spending against budgets
   - Requires linking transactions to budget categories

3. **Trend Analysis** - Year-over-year comparisons
   - Requires historical data archives

4. **Export Functionality** - CSV/PDF export with period selection
   - Backend could generate and stream files

5. **Scheduled Reports** - Email reports at regular intervals
   - Backend job to generate and email reports
