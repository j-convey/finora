# Backend Server Changes for Finora Accounts Page Redesign

## Overview
The redesigned accounts page requires backend API changes to provide net worth history data and ensure proper tracking of account changes over time.

## Required API Endpoints

### 1. **GET /api/accounts/net-worth-history** (NEW)
Provides net worth history data for the past month (or configurable period).

**Purpose:** Display the net worth performance line chart and calculate percentage changes.

**Request Parameters:**
```
Query Parameters:
  - period: string (optional, default: "1month")
    Values: "1week", "1month", "3months", "6months", "1year"
  - start_date: ISO 8601 date (optional)
  - end_date: ISO 8601 date (optional)
```

**Response Format:**
```json
[
  {
    "date": "2026-11-07",
    "net_worth": 663401.45
  },
  {
    "date": "2026-11-08",
    "net_worth": 664150.33
  },
  ...
  {
    "date": "2026-12-07",
    "net_worth": 686401.45
  }
]
```

**Response Properties:**
- `date` (string, ISO 8601): Date for the data point
- `net_worth` (number): Total net worth on that date (sum of all account balances)

**Calculation Logic:**
- Net Worth = Sum of all account balances (positive and negative)
- Daily snapshots should be generated at a consistent time (e.g., midnight UTC or end of business day)
- If no transactions on a day, use previous day's balances

**Response Headers:**
```
HTTP/1.1 200 OK
Content-Type: application/json
X-Total-Count: 31 (number of entries)
```

### 2. **Existing GET /api/accounts endpoint**
The existing endpoint should continue to return account data with the current structure. No changes required for basic functionality, but ensure:

**Response includes:**
```json
[
  {
    "id": "string",
    "name": "string",
    "type": "checking|savings|credit_card|investment|cash",
    "balance": number,
    "available_balance": number (optional, for checking/savings),
    "institution_name": string (optional),
    "color": "#hexcolor" (optional),
    "updated_at": "ISO 8601 timestamp"
  }
]
```

## Database Changes

### 1. **Account Snapshots Table** (NEW)
Required to track net worth history.

**Table Name:** `account_snapshots`

**Schema:**
```sql
CREATE TABLE account_snapshots (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  net_worth NUMERIC(15, 2) NOT NULL,
  total_assets NUMERIC(15, 2) NOT NULL,
  total_liabilities NUMERIC(15, 2) NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, snapshot_date),
  INDEX idx_user_id_date (user_id, snapshot_date)
);
```

**Data Columns:**
- `id`: Unique identifier
- `user_id`: Foreign key to users table
- `snapshot_date`: The date of the snapshot
- `net_worth`: Total net worth (assets - liabilities)
- `total_assets`: Sum of positive balances
- `total_liabilities`: Sum of absolute negative balances
- `created_at`: When the record was created

### 2. **Daily Snapshot Job** (NEW)
Implement a scheduled job to create daily account snapshots.

**Frequency:** Daily (recommended: 23:55 UTC or after 5 PM local time)

**Logic:**
```pseudocode
FUNCTION generate_daily_snapshots():
  FOR EACH user IN active_users:
    accounts = GET user's accounts
    net_worth = SUM(account.balance for all accounts)
    total_assets = SUM(account.balance where balance > 0)
    total_liabilities = SUM(ABS(account.balance) where balance < 0)
    
    INSERT INTO account_snapshots (
      user_id, snapshot_date, net_worth, total_assets, total_liabilities
    ) VALUES (user.id, TODAY(), net_worth, total_assets, total_liabilities)
    ON CONFLICT (user_id, snapshot_date) DO UPDATE SET
      net_worth = EXCLUDED.net_worth,
      total_assets = EXCLUDED.total_assets,
      total_liabilities = EXCLUDED.total_liabilities
```

**Implementation Options:**
- Cron job (Linux/Unix servers)
- AWS Lambda + CloudWatch Events
- Google Cloud Scheduler
- Third-party service (e.g., Vercel Cron)
- Application scheduler (e.g., APScheduler, node-schedule, flutter_background)

## Algorithm Details

### Net Worth History Query
```pseudocode
FUNCTION get_net_worth_history(user_id, period = "1month"):
  start_date = NOW() - INTERVAL(period)
  end_date = NOW()
  
  results = SELECT date, net_worth FROM account_snapshots
    WHERE user_id = user_id
      AND snapshot_date BETWEEN start_date AND end_date
    ORDER BY snapshot_date ASC
  
  RETURN results
```

### Percentage Change Calculation (Frontend)
```
currentNetWorth = entries.last.net_worth
previousNetWorth = entries.first.net_worth
netWorthChange = currentNetWorth - previousNetWorth
percentageChange = (netWorthChange / ABS(previousNetWorth)) * 100
```

## Testing Checklist

**Endpoint Tests:**
- [ ] GET /api/accounts/net-worth-history returns valid data
- [ ] Different period parameters work correctly
- [ ] Date range parameters work correctly
- [ ] Empty history returns empty array (not error)
- [ ] Unauthenticated requests return 401
- [ ] User only sees their own history (no data leakage)

**Database Tests:**
- [ ] Daily snapshot job runs successfully
- [ ] Snapshots are calculated correctly
- [ ] No duplicate entries for same date/user
- [ ] Snapshots persist across service restarts

**Data Integrity Tests:**
- [ ] Net worth = assets - liabilities
- [ ] Assets never include negative balances
- [ ] Liabilities never include positive balances

## Migration Plan

1. **Phase 1:** Create `account_snapshots` table
2. **Phase 2:** Backfill snapshots for past 30 days (use existing account history if available)
3. **Phase 3:** Deploy daily snapshot job
4. **Phase 4:** Deploy `/api/accounts/net-worth-history` endpoint
5. **Phase 5:** Deploy updated Flutter frontend

## Performance Considerations

**Indexes:**
- `account_snapshots(user_id, snapshot_date)` - Critical for query performance
- Consider archiving old snapshots (>1 year) to a separate table

**Query Optimization:**
- Limit history data to needed period (default: 30 days)
- Use database-level aggregation rather than post-processing

**Caching:**
- Consider caching today's snapshot for 1 hour (unless real-time updates are critical)
- Cache 7-day and 30-day summaries

## Error Handling

**API Responses:**
```json
// 400 Bad Request - Invalid period
{
  "error": "Invalid period parameter. Valid values: 1week, 1month, 3months, 6months, 1year"
}

// 401 Unauthorized
{
  "error": "Authentication required"
}

// 500 Internal Server Error
{
  "error": "Failed to fetch net worth history"
}
```

## Dependencies & Compatibility

**No new external dependencies required** for backend.

The frontend Flutter app now requires:
- `fl_chart: ^0.68.0` - For line chart visualization (already added)

## Timeline Estimate

- **Database setup:** 1-2 hours
- **Snapshot job implementation:** 2-3 hours  
- **API endpoint:** 1-2 hours
- **Testing & debugging:** 2-3 hours
- **Total:** ~6-10 hours

## Future Enhancements

1. **Account-level history:** Track individual account balances over time
2. **Custom date ranges:** Allow users to select any date range
3. **Export functionality:** CSV/PDF export with full history
4. **Alerts:** Notify users of significant net worth changes
5. **Budget tracking:** Compare net worth trends with budget targets
